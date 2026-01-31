$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)
$writer.AutoFlush = $true

# Read welcome message
Start-Sleep -Milliseconds 500
while ($stream.DataAvailable) {
    $reader.ReadLine() | Out-Null
}

# Send info qtree to check PS/2 device
$writer.WriteLine('info qtree')
Start-Sleep -Seconds 1
$response = ""
while ($stream.DataAvailable) {
    $response += $reader.ReadLine() + "`n"
}
Write-Host "=== QTREE ==="
Write-Host ($response | Select-String -Pattern "i8042|keyboard|ps2|kbd" -AllMatches)

# Send a key and check
$writer.WriteLine('sendkey a')
Start-Sleep -Milliseconds 500

# Try reading the i8042 status via xp command (read memory/port)
$writer.WriteLine('xp /1b 0x64')
Start-Sleep -Milliseconds 500
$response2 = ""
while ($stream.DataAvailable) {
    $response2 += $reader.ReadLine() + "`n"
}
Write-Host "=== PORT 0x64 after sendkey ==="
Write-Host $response2

$tcp.Close()
