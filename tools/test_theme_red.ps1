# Test Terminator Red theme (press 9 for settings, then 2 for red, then ESC)
$BUILD = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

# Kill old QEMU, start fresh
Get-Process -Name "qemu-system-i386" -EA SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

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

# Settings -> 2 (Terminator Red) -> ESC
QCmd "sendkey 9"
Start-Sleep -Seconds 3
QCmd "sendkey 2"
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\red_settings.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\red_settings.ppm" -frames:v 1 -update 1 "$BUILD\red_settings.png" 2>$null

QCmd "sendkey esc"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\red_desk.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\red_desk.ppm" -frames:v 1 -update 1 "$BUILD\red_desk.png" 2>$null
Write-Host "Red desk: $((Get-Item "$BUILD\red_desk.png" -EA SilentlyContinue).Length) bytes"

# Now try Conan Gold: 9 -> 5 -> ESC
QCmd "sendkey 9"
Start-Sleep -Seconds 3
QCmd "sendkey 5"
Start-Sleep -Seconds 2
QCmd "sendkey esc"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\gold_desk.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\gold_desk.ppm" -frames:v 1 -update 1 "$BUILD\gold_desk.png" 2>$null
Write-Host "Gold desk: $((Get-Item "$BUILD\gold_desk.png" -EA SilentlyContinue).Length) bytes"

if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "DONE"
