# Merge, build, boot, screenshot
$root = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$BUILD = "$root\build"
$GEN = "$BUILD\gen"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Merge
$files = @(
    "$root\kernel\lib\random.arnoldc",
    "$root\kernel\lib\timer.arnoldc",
    "$root\kernel\lib\speaker.arnoldc",
    "$root\kernel\games\snake.arnoldc",
    "$root\kernel\kernel_v3.arnoldc"
)
& "$root\tools\merge_modules.ps1" -SourceFiles $files -OutputFile "$GEN\kernel.arnoldc"

# Compile
Push-Location $GEN
java -jar "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar" -asm "kernel.arnoldc" 2>$null
Pop-Location

# Add externs
$asm = Get-Content "$GEN\kernel.asm" -Raw
$externs = "`nextern get_fb_addr`nextern get_fb_pitch`nextern get_fb_width`nextern get_fb_height`nextern get_timer_ticks`nextern sleep_ticks`nextern get_mouse_x`nextern get_mouse_y`nextern get_mouse_buttons`nextern speaker_on`nextern speaker_off`nextern speaker_set_frequency`nextern get_last_scancode`nextern read_rtc_hours`nextern read_rtc_minutes`nextern read_rtc_seconds`nextern halt_system`nextern outb`nextern inb`nextern outw`nextern inw`nextern outl`nextern inl`n"
$asm = $asm -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN\kernel.asm" $asm -NoNewline

# Assemble + Link
nasm -f elf32 -o "$BUILD\multiboot.o" "$root\boot\multiboot.asm" 2>$null
nasm -f elf32 -o "$BUILD\kernel.o" "$GEN\kernel.asm" 2>$null
& "C:\Users\Acer\i686-elf-tools\bin\i686-elf-ld.exe" -m elf_i386 -T "$root\linker.ld" -nostdlib -o "$BUILD\toaruos-arnold.elf" "$BUILD\multiboot.o" "$BUILD\kernel.o" 2>$null

$sz = (Get-Item "$BUILD\toaruos-arnold.elf").Length
Write-Host "ELF: $sz bytes"

# Boot QEMU with telnet monitor
Remove-Item "$BUILD\serial.log" -ErrorAction SilentlyContinue
Remove-Item "$BUILD\screenshot.ppm" -ErrorAction SilentlyContinue

$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD\toaruos-arnold.elf",
    "-serial", "file:$BUILD\serial.log",
    "-monitor", "telnet:127.0.0.1:55555,server,nowait",
    "-display", "none"
) -PassThru

Write-Host "QEMU PID: $($proc.Id)"
Start-Sleep -Seconds 4

# Screenshot via telnet
try {
    $client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55555)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    Start-Sleep -Milliseconds 500
    # Drain banner
    while ($stream.DataAvailable) { $stream.ReadByte() | Out-Null }
    $writer.WriteLine("screendump $BUILD\screenshot.ppm")
    Start-Sleep -Seconds 1
    $client.Close()
} catch {
    Write-Host "Monitor: $_"
}

# Check
Write-Host "=== SERIAL ==="
if (Test-Path "$BUILD\serial.log") { Get-Content "$BUILD\serial.log" -Raw }

if (Test-Path "$BUILD\screenshot.ppm") {
    $ssz = (Get-Item "$BUILD\screenshot.ppm").Length
    Write-Host "Screenshot: $ssz bytes"
    ffmpeg -y -i "$BUILD\screenshot.ppm" -frames:v 1 -update 1 "$BUILD\screenshot.png" 2>$null
} else {
    Write-Host "No screenshot"
}

if (-not $proc.HasExited) {
    Write-Host "QEMU still running"
    $proc.Kill()
} else {
    Write-Host "QEMU exited: $($proc.ExitCode)"
}
