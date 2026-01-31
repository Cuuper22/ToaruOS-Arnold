# Send W key to running QEMU and screenshot
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

# Press W multiple times to create windows at different positions
QCmd "sendkey w"
Start-Sleep -Seconds 3
QCmd "screendump $BUILD\wm_window.ppm"
Start-Sleep -Milliseconds 500

ffmpeg -y -i "$BUILD\wm_window.ppm" -frames:v 1 -update 1 "$BUILD\wm_window.png" 2>$null
Write-Host "Window: $((Get-Item "$BUILD\wm_window.png" -EA SilentlyContinue).Length) bytes"
