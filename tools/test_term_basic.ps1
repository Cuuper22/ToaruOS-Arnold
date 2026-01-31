# Test terminal with long waits for slow ArnoldC rendering
$root = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$BUILD = "$root\build"
$GEN = "$BUILD\gen"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$files = @(
    "$root\kernel\kernel_v3.arnoldc",
    "$root\kernel\lib\random.arnoldc",
    "$root\kernel\lib\timer.arnoldc",
    "$root\kernel\lib\speaker.arnoldc",
    "$root\kernel\games\snake.arnoldc",
    "$root\kernel\games\pong.arnoldc",
    "$root\kernel\games\breakout.arnoldc",
    "$root\kernel\games\chopper.arnoldc",
    "$root\kernel\games\memory.arnoldc",
    "$root\kernel\games\skynet.arnoldc",
    "$root\kernel\games\tictactoe.arnoldc",
    "$root\kernel\window_manager.arnoldc",
    "$root\kernel\terminal.arnoldc",
    "$root\kernel\terminal_commands.arnoldc",
    "$root\kernel\apps\calculator.arnoldc",
    "$root\kernel\apps\about.arnoldc"
)
& "$root\tools\merge_modules.ps1" -SourceFiles $files -OutputFile "$GEN\kernel.arnoldc"

Push-Location $GEN
java -jar "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar" -asm "kernel.arnoldc" 2>$null
Pop-Location

$asm = Get-Content "$GEN\kernel.asm" -Raw
$externs = "`nextern get_fb_addr`nextern get_fb_pitch`nextern get_fb_width`nextern get_fb_height`nextern get_timer_ticks`nextern sleep_ticks`nextern get_mouse_x`nextern get_mouse_y`nextern get_mouse_buttons`nextern speaker_on`nextern speaker_off`nextern speaker_set_frequency`nextern get_last_scancode`nextern read_rtc_hours`nextern read_rtc_minutes`nextern read_rtc_seconds`nextern halt_system`nextern outb`nextern inb`nextern outw`nextern inw`nextern outl`nextern inl`n"
$asm = $asm -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN\kernel.asm" $asm -NoNewline

nasm -f elf32 -o "$BUILD\multiboot.o" "$root\boot\multiboot.asm" 2>$null
nasm -f elf32 -o "$BUILD\kernel.o" "$GEN\kernel.asm" 2>$null
& "C:\Users\Acer\i686-elf-tools\bin\i686-elf-ld.exe" -m elf_i386 -T "$root\linker.ld" -nostdlib -o "$BUILD\toaruos-arnold.elf" "$BUILD\multiboot.o" "$BUILD\kernel.o" 2>$null

Write-Host "ELF: $((Get-Item "$BUILD\toaruos-arnold.elf").Length) bytes"

Remove-Item "$BUILD\serial.log" -ErrorAction SilentlyContinue
$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD\toaruos-arnold.elf",
    "-serial", "file:$BUILD\serial.log",
    "-monitor", "telnet:127.0.0.1:55555,server,nowait",
    "-display", "none"
) -PassThru

Start-Sleep -Seconds 5

function QCmd($cmd) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55555)
        $s = $c.GetStream()
        $w = New-Object System.IO.StreamWriter($s)
        $w.AutoFlush = $true
        Start-Sleep -Milliseconds 200
        while ($s.DataAvailable) { $s.ReadByte() | Out-Null }
        $w.WriteLine($cmd)
        Start-Sleep -Milliseconds 300
        $c.Close()
    } catch { Write-Host "ERR: $_" }
}

# Desktop screenshot
QCmd "screendump $BUILD\test_desk.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\test_desk.ppm" -frames:v 1 -update 1 "$BUILD\test_desk.png" 2>$null
Write-Host "Desktop: $((Get-Item "$BUILD\test_desk.png" -EA SilentlyContinue).Length) bytes"

# Press 1 for terminal
QCmd "sendkey 1"
Write-Host "Pressed 1 - waiting 20s for terminal render..."
Start-Sleep -Seconds 20

QCmd "screendump $BUILD\test_term20.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\test_term20.ppm" -frames:v 1 -update 1 "$BUILD\test_term20.png" 2>$null
Write-Host "Term(20s): $((Get-Item "$BUILD\test_term20.png" -EA SilentlyContinue).Length) bytes"

Write-Host "SERIAL: $(Get-Content "$BUILD\serial.log" -Raw -EA SilentlyContinue)"
if (-not $proc.HasExited) { $proc.Kill(); Write-Host "RUNNING" } else { Write-Host "EXITED: $($proc.ExitCode)" }
