# Full terminal test: boot → terminal → type help → enter → screenshot
$root = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$BUILD = "$root\build"
$GEN = "$BUILD\gen"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -EA SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

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
    "$root\kernel\apps\calculator.arnoldc", "$root\kernel\apps\about.arnoldc"
)
& "$root\tools\merge_modules.ps1" -SourceFiles $files -OutputFile "$GEN\kernel.arnoldc"

Push-Location $GEN
$out = java -jar "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar" -asm "kernel.arnoldc" 2>&1
Pop-Location

if (-not (Test-Path "$GEN\kernel.asm")) {
    Write-Host "COMPILE FAILED: $out"
    exit 1
}
Write-Host "COMPILE OK"

$asm = Get-Content "$GEN\kernel.asm" -Raw
$externs = "`nextern get_fb_addr`nextern get_fb_pitch`nextern get_fb_width`nextern get_fb_height`nextern get_timer_ticks`nextern sleep_ticks`nextern get_mouse_x`nextern get_mouse_y`nextern get_mouse_buttons`nextern speaker_on`nextern speaker_off`nextern speaker_set_frequency`nextern get_last_scancode`nextern read_rtc_hours`nextern read_rtc_minutes`nextern read_rtc_seconds`nextern halt_system`nextern outb`nextern inb`nextern outw`nextern inw`nextern outl`nextern inl`n"
$asm = $asm -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN\kernel.asm" $asm -NoNewline

nasm -f elf32 -o "$BUILD\multiboot.o" "$root\boot\multiboot.asm" 2>$null
nasm -f elf32 -o "$BUILD\kernel.o" "$GEN\kernel.asm" 2>$null
& "C:\Users\Acer\i686-elf-tools\bin\i686-elf-ld.exe" -m elf_i386 -T "$root\linker.ld" -nostdlib -o "$BUILD\toaruos-arnold.elf" "$BUILD\multiboot.o" "$BUILD\kernel.o" 2>$null

Write-Host "ELF: $((Get-Item "$BUILD\toaruos-arnold.elf").Length) bytes"

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

# Enter terminal
QCmd "sendkey 1"
Start-Sleep -Seconds 5

# Screenshot: terminal with prompt
QCmd "screendump $BUILD\term_prompt.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\term_prompt.ppm" -vf "crop=640:30:0:0,scale=1280:60:flags=neighbor" -frames:v 1 -update 1 "$BUILD\term_prompt_zoom.png" 2>$null
Write-Host "Prompt screenshot saved"

# Type "help"
QCmd "sendkey h"
Start-Sleep -Milliseconds 500
QCmd "sendkey e"
Start-Sleep -Milliseconds 500
QCmd "sendkey l"
Start-Sleep -Milliseconds 500
QCmd "sendkey p"
Start-Sleep -Milliseconds 500

# Screenshot after typing "help"
QCmd "screendump $BUILD\term_typed.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\term_typed.ppm" -vf "crop=640:30:0:0,scale=1280:60:flags=neighbor" -frames:v 1 -update 1 "$BUILD\term_typed_zoom.png" 2>$null
Write-Host "Typed screenshot saved"

# Press Enter
QCmd "sendkey ret"
Start-Sleep -Seconds 5

# Screenshot after help output
QCmd "screendump $BUILD\term_help_out.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\term_help_out.ppm" -frames:v 1 -update 1 "$BUILD\term_help_out.png" 2>$null
# Also a zoom of the help text area
ffmpeg -y -i "$BUILD\term_help_out.ppm" -vf "crop=640:200:0:0,scale=1280:400:flags=neighbor" -frames:v 1 -update 1 "$BUILD\term_help_zoom.png" 2>$null
Write-Host "Help output: $((Get-Item "$BUILD\term_help_out.png" -EA SilentlyContinue).Length) bytes"

if (-not $proc.HasExited) { $proc.Kill(); Write-Host "RUNNING" } else { Write-Host "EXITED: $($proc.ExitCode)" }
