$BUILD = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -EA SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD\toaruos-arnold.elf",
    "-serial", "file:$BUILD\serial.log",
    "-monitor", "telnet:127.0.0.1:55555,server,nowait",
    "-display", "none"
) -PassThru

Write-Host "QEMU PID: $($proc.Id)"
Start-Sleep -Seconds 6

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

# 1. Desktop screenshot
QCmd "screendump $BUILD\phase5_desktop.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\phase5_desktop.ppm" -frames:v 1 -update 1 "$BUILD\phase5_desktop.png" 2>$null
Write-Host "Desktop: $((Get-Item "$BUILD\phase5_desktop.png" -EA SilentlyContinue).Length) bytes"

# 2. Press Tab for start menu
QCmd "sendkey tab"
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\phase5_startmenu.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\phase5_startmenu.ppm" -frames:v 1 -update 1 "$BUILD\phase5_startmenu.png" 2>$null
Write-Host "StartMenu: $((Get-Item "$BUILD\phase5_startmenu.png" -EA SilentlyContinue).Length) bytes"

# 3. Press 2 to launch Snake from menu
QCmd "sendkey 2"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\phase5_snake.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\phase5_snake.ppm" -frames:v 1 -update 1 "$BUILD\phase5_snake.png" 2>$null
Write-Host "Snake: $((Get-Item "$BUILD\phase5_snake.png" -EA SilentlyContinue).Length) bytes"

# 4. ESC back to desktop
QCmd "sendkey esc"
Start-Sleep -Seconds 2

# 5. Press 3 (Pong)
QCmd "sendkey 3"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\phase5_pong.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\phase5_pong.ppm" -frames:v 1 -update 1 "$BUILD\phase5_pong.png" 2>$null
Write-Host "Pong: $((Get-Item "$BUILD\phase5_pong.png" -EA SilentlyContinue).Length) bytes"

# 6. ESC back, press 5 (Chopper) 
QCmd "sendkey esc"
Start-Sleep -Seconds 2
QCmd "sendkey 5"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\phase5_chopper.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\phase5_chopper.ppm" -frames:v 1 -update 1 "$BUILD\phase5_chopper.png" 2>$null
Write-Host "Chopper: $((Get-Item "$BUILD\phase5_chopper.png" -EA SilentlyContinue).Length) bytes"

# 7. ESC back, press 6 (Skynet)
QCmd "sendkey esc"
Start-Sleep -Seconds 2
QCmd "sendkey 6"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\phase5_skynet.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\phase5_skynet.ppm" -frames:v 1 -update 1 "$BUILD\phase5_skynet.png" 2>$null
Write-Host "Skynet: $((Get-Item "$BUILD\phase5_skynet.png" -EA SilentlyContinue).Length) bytes"

# 8. ESC back, open menu with Tab, then press 4 (Breakout from menu)
QCmd "sendkey esc"
Start-Sleep -Seconds 2
QCmd "sendkey tab"
Start-Sleep -Seconds 2
QCmd "sendkey 4"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\phase5_breakout.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\phase5_breakout.ppm" -frames:v 1 -update 1 "$BUILD\phase5_breakout.png" 2>$null
Write-Host "Breakout: $((Get-Item "$BUILD\phase5_breakout.png" -EA SilentlyContinue).Length) bytes"

# Cleanup
if (-not $proc.HasExited) { $proc.Kill(); Write-Host "QEMU killed" }
