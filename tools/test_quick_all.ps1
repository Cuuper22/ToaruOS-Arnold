# Quick test all games - boot, screenshot each, verify kernel stays running
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
    "$root\kernel\games\tictactoe.arnoldc"
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

Start-Sleep -Seconds 3

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

# Test each game with longer wait (breakout init is slow due to 84 bricks)
$tests = @(
    @{ key="2"; name="snake"; wait=2 },
    @{ key="3"; name="pong"; wait=2 },
    @{ key="4"; name="breakout"; wait=5 },
    @{ key="5"; name="chopper"; wait=3 },
    @{ key="6"; name="skynet"; wait=3 }
)

foreach ($t in $tests) {
    QCmd "sendkey $($t.key)"
    Start-Sleep -Seconds $t.wait
    QCmd "screendump $BUILD\g_$($t.name).ppm"
    Start-Sleep -Milliseconds 300
    QCmd "sendkey esc"
    Start-Sleep -Seconds 1
}

# Convert all
Get-ChildItem "$BUILD\g_*.ppm" | ForEach-Object {
    $png = $_.FullName -replace '\.ppm$', '.png'
    ffmpeg -y -i $_.FullName -frames:v 1 -update 1 $png 2>$null
    Write-Host "$($_.BaseName): $((Get-Item $png -EA SilentlyContinue).Length) bytes"
}

Write-Host "`nSERIAL: $(Get-Content "$BUILD\serial.log" -Raw -EA SilentlyContinue)"
if (-not $proc.HasExited) { $proc.Kill(); Write-Host "RUNNING" } else { Write-Host "EXITED: $($proc.ExitCode)" }
