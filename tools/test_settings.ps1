$BUILD = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build"

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

# Press 9 for settings
Write-Host "Pressing 9 for Settings..."
QCmd "sendkey 9"
Start-Sleep -Seconds 5

# Screenshot settings
QCmd "screendump $BUILD\settings.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\settings.ppm" -frames:v 1 -update 1 "$BUILD\settings.png" 2>$null
Write-Host "Settings: $((Get-Item "$BUILD\settings.png" -EA SilentlyContinue).Length) bytes"

# Press down arrow twice then screenshot
Write-Host "Pressing down arrow..."
QCmd "sendkey down"
Start-Sleep -Seconds 2
QCmd "sendkey down"
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\settings2.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\settings2.ppm" -frames:v 1 -update 1 "$BUILD\settings2.png" 2>$null
Write-Host "Settings2: $((Get-Item "$BUILD\settings2.png" -EA SilentlyContinue).Length) bytes"

# Press enter to apply, then ESC back to desktop
Write-Host "Pressing Enter to apply theme..."
QCmd "sendkey ret"
Start-Sleep -Seconds 2
QCmd "sendkey esc"
Start-Sleep -Seconds 3

# Screenshot themed desktop
QCmd "screendump $BUILD\themed.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\themed.ppm" -frames:v 1 -update 1 "$BUILD\themed.png" 2>$null
Write-Host "Themed desktop: $((Get-Item "$BUILD\themed.png" -EA SilentlyContinue).Length) bytes"

Write-Host "DONE"
