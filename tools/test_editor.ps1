# Test text editor
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

# Press 0 for editor
Write-Host "=== LAUNCHING EDITOR (key 0) ==="
QCmd "sendkey 0"
Start-Sleep -Seconds 5

QCmd "screendump $BUILD\editor1.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\editor1.ppm" -frames:v 1 -update 1 "$BUILD\editor1.png" 2>$null
Write-Host "Editor empty: $((Get-Item "$BUILD\editor1.png" -EA SilentlyContinue).Length) bytes"

# Type "Hello World!"
Write-Host "=== TYPING 'Hello World!' ==="
$keys = @("shift-h", "e", "l", "l", "o", "space", "shift-w", "o", "r", "l", "d", "shift-1")
foreach ($k in $keys) {
    QCmd "sendkey $k"
    Start-Sleep -Milliseconds 300
}
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\editor2.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\editor2.ppm" -frames:v 1 -update 1 "$BUILD\editor2.png" 2>$null
Write-Host "Editor typed: $((Get-Item "$BUILD\editor2.png" -EA SilentlyContinue).Length) bytes"

# Press Enter, type more
Write-Host "=== NEW LINE + MORE TEXT ==="
QCmd "sendkey ret"
Start-Sleep -Milliseconds 500
$keys2 = @("shift-i", "apostrophe", "l", "l", "space", "b", "e", "space", "b", "a", "c", "k", "dot")
foreach ($k in $keys2) {
    QCmd "sendkey $k"
    Start-Sleep -Milliseconds 300
}
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\editor3.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\editor3.ppm" -frames:v 1 -update 1 "$BUILD\editor3.png" 2>$null
Write-Host "Editor multiline: $((Get-Item "$BUILD\editor3.png" -EA SilentlyContinue).Length) bytes"

Write-Host "DONE"
