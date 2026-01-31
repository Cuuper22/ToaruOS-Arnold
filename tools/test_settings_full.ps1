# Full build + settings test
$root = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$BUILD = "$root\build"
$GEN = "$BUILD\gen"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

# Kill any existing QEMU
Get-Process -Name "qemu-system-i386" -EA SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Delete stale ASM
Remove-Item "$GEN\kernel.asm" -EA SilentlyContinue

$files = @(
    "$root\kernel\kernel_v3.arnoldc",
    "$root\kernel\lib\random.arnoldc", "$root\kernel\lib\timer.arnoldc",
    "$root\kernel\lib\speaker.arnoldc",
    "$root\kernel\games\snake.arnoldc", "$root\kernel\games\pong.arnoldc",
    "$root\kernel\games\breakout.arnoldc", "$root\kernel\games\chopper.arnoldc",
    "$root\kernel\games\memory.arnoldc", "$root\kernel\games\skynet.arnoldc",
    "$root\kernel\games\tictactoe.arnoldc",
    "$root\kernel\window_manager.arnoldc",
    "$root\kernel\terminal.arnoldc", "$root\kernel\terminal_commands.arnoldc",
    "$root\kernel\apps\calculator.arnoldc", "$root\kernel\apps\about.arnoldc",
    "$root\kernel\apps\settings.arnoldc"
)
& "$root\tools\merge_modules.ps1" -SourceFiles $files -OutputFile "$GEN\kernel.arnoldc"

Push-Location $GEN
$compileOut = java -jar "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar" -asm "kernel.arnoldc" 2>&1
Pop-Location

if (-not (Test-Path "$GEN\kernel.asm")) {
    Write-Host "COMPILE FAILED!"
    Write-Host $compileOut
    exit 1
}
Write-Host "COMPILE OK: $((Get-Item "$GEN\kernel.asm").Length) bytes"

# Add externs
$asm = Get-Content "$GEN\kernel.asm" -Raw
$externs = "`nextern get_fb_addr`nextern get_fb_pitch`nextern get_fb_width`nextern get_fb_height`nextern get_timer_ticks`nextern sleep_ticks`nextern get_mouse_x`nextern get_mouse_y`nextern get_mouse_buttons`nextern speaker_on`nextern speaker_off`nextern speaker_set_frequency`nextern get_last_scancode`nextern read_rtc_hours`nextern read_rtc_minutes`nextern read_rtc_seconds`nextern halt_system`nextern outb`nextern inb`nextern outw`nextern inw`nextern outl`nextern inl`nextern fast_fill_rect`nextern fast_memcpy32`n"
$asm = $asm -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN\kernel.asm" $asm -NoNewline

nasm -f elf32 -o "$BUILD\multiboot.o" "$root\boot\multiboot.asm" 2>&1
nasm -f elf32 -o "$BUILD\kernel.o" "$GEN\kernel.asm" 2>&1
& "C:\Users\Acer\i686-elf-tools\bin\i686-elf-ld.exe" -m elf_i386 -T "$root\linker.ld" -nostdlib -o "$BUILD\toaruos-arnold.elf" "$BUILD\multiboot.o" "$BUILD\kernel.o" 2>&1

$elfSize = (Get-Item "$BUILD\toaruos-arnold.elf").Length
Write-Host "ELF: $elfSize bytes"
if ($elfSize -lt 1000) { Write-Host "ELF TOO SMALL!"; exit 1 }

# Run QEMU
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

# Desktop screenshot first
QCmd "screendump $BUILD\set_desk.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\set_desk.ppm" -frames:v 1 -update 1 "$BUILD\set_desk.png" 2>$null
Write-Host "Desktop: $((Get-Item "$BUILD\set_desk.png" -EA SilentlyContinue).Length) bytes"

# Press 9 for settings
Write-Host "=== PRESSING 9 FOR SETTINGS ==="
QCmd "sendkey 9"
Start-Sleep -Seconds 5

QCmd "screendump $BUILD\settings.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\settings.ppm" -frames:v 1 -update 1 "$BUILD\settings.png" 2>$null
Write-Host "Settings: $((Get-Item "$BUILD\settings.png" -EA SilentlyContinue).Length) bytes"

# Press 3 to directly select Predator Green
Write-Host "=== SELECTING PREDATOR GREEN (key 3) ==="
QCmd "sendkey 3"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\settings_sel.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\settings_sel.ppm" -frames:v 1 -update 1 "$BUILD\settings_sel.png" 2>$null
Write-Host "Selection: $((Get-Item "$BUILD\settings_sel.png" -EA SilentlyContinue).Length) bytes"

# ESC back to desktop (theme already applied by number key)
Write-Host "=== BACK TO DESKTOP ==="
QCmd "sendkey esc"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\themed_desk.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\themed_desk.ppm" -frames:v 1 -update 1 "$BUILD\themed_desk.png" 2>$null
Write-Host "Themed: $((Get-Item "$BUILD\themed_desk.png" -EA SilentlyContinue).Length) bytes"

if (-not $proc.HasExited) { $proc.Kill(); Write-Host "QEMU KILLED OK" } else { Write-Host "QEMU EXITED: $($proc.ExitCode)" }
