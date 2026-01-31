# Test Snake game - boot, screenshot desktop, click Snake icon, screenshot game
$root = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$BUILD = "$root\build"
$GEN = "$BUILD\gen"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Merge
$files = @(
    "$root\kernel\kernel_v3.arnoldc",
    "$root\kernel\lib\random.arnoldc",
    "$root\kernel\lib\timer.arnoldc",
    "$root\kernel\lib\speaker.arnoldc",
    "$root\kernel\games\snake.arnoldc"
)
& "$root\tools\merge_modules.ps1" -SourceFiles $files -OutputFile "$GEN\kernel.arnoldc"

# Compile
Push-Location $GEN
java -jar "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar" -asm "kernel.arnoldc" 2>$null
Pop-Location

# Add externs + Assemble + Link
$asm = Get-Content "$GEN\kernel.asm" -Raw
$externs = "`nextern get_fb_addr`nextern get_fb_pitch`nextern get_fb_width`nextern get_fb_height`nextern get_timer_ticks`nextern sleep_ticks`nextern get_mouse_x`nextern get_mouse_y`nextern get_mouse_buttons`nextern speaker_on`nextern speaker_off`nextern speaker_set_frequency`nextern get_last_scancode`nextern read_rtc_hours`nextern read_rtc_minutes`nextern read_rtc_seconds`nextern halt_system`nextern outb`nextern inb`nextern outw`nextern inw`nextern outl`nextern inl`n"
$asm = $asm -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN\kernel.asm" $asm -NoNewline

nasm -f elf32 -o "$BUILD\multiboot.o" "$root\boot\multiboot.asm" 2>$null
nasm -f elf32 -o "$BUILD\kernel.o" "$GEN\kernel.asm" 2>$null
& "C:\Users\Acer\i686-elf-tools\bin\i686-elf-ld.exe" -m elf_i386 -T "$root\linker.ld" -nostdlib -o "$BUILD\toaruos-arnold.elf" "$BUILD\multiboot.o" "$BUILD\kernel.o" 2>$null

Write-Host "ELF: $((Get-Item "$BUILD\toaruos-arnold.elf").Length) bytes"

# Boot with telnet monitor
Remove-Item "$BUILD\serial.log" -ErrorAction SilentlyContinue

$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD\toaruos-arnold.elf",
    "-serial", "file:$BUILD\serial.log",
    "-monitor", "telnet:127.0.0.1:55555,server,nowait",
    "-display", "none"
) -PassThru

Write-Host "QEMU PID: $($proc.Id)"
Start-Sleep -Seconds 3

function Send-QemuCmd($cmd) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55555)
        $s = $c.GetStream()
        $w = New-Object System.IO.StreamWriter($s)
        $w.AutoFlush = $true
        Start-Sleep -Milliseconds 300
        while ($s.DataAvailable) { $s.ReadByte() | Out-Null }
        $w.WriteLine($cmd)
        Start-Sleep -Milliseconds 500
        $c.Close()
    } catch { Write-Host "Monitor error: $_" }
}

# Screenshot 1: Desktop
Send-QemuCmd "screendump $BUILD\desktop.ppm"
Start-Sleep -Milliseconds 500

# Move mouse to Snake icon (should be around x=32, y=170 based on icon layout)
# checkIconClick checks: Terminal at (20,40), Snake at (20,120), Pong at (20,200)
# Icon click area: x=20..68, y varies per icon
Send-QemuCmd "mouse_move 40 150"
Start-Sleep -Milliseconds 200
Send-QemuCmd "mouse_button 1"
Start-Sleep -Milliseconds 200
Send-QemuCmd "mouse_button 0"
Start-Sleep -Seconds 2

# Screenshot 2: Should show Snake game
Send-QemuCmd "screendump $BUILD\snake.ppm"
Start-Sleep -Milliseconds 500

# Convert to PNG
if (Test-Path "$BUILD\desktop.ppm") {
    ffmpeg -y -i "$BUILD\desktop.ppm" -frames:v 1 -update 1 "$BUILD\desktop.png" 2>$null
    Write-Host "Desktop: $((Get-Item "$BUILD\desktop.png").Length) bytes"
}
if (Test-Path "$BUILD\snake.ppm") {
    ffmpeg -y -i "$BUILD\snake.ppm" -frames:v 1 -update 1 "$BUILD\snake.png" 2>$null
    Write-Host "Snake: $((Get-Item "$BUILD\snake.png").Length) bytes"
}

# Serial
Write-Host "=== SERIAL ==="
if (Test-Path "$BUILD\serial.log") { Get-Content "$BUILD\serial.log" -Raw }

# Cleanup
if (-not $proc.HasExited) { $proc.Kill(); Write-Host "QEMU running (good)" } else { Write-Host "QEMU exited: $($proc.ExitCode)" }
