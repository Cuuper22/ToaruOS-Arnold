$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)
$writer.AutoFlush = $true

Start-Sleep -Milliseconds 500
while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }

# Enable I/O port logging temporarily
$writer.WriteLine('log ioport')
Start-Sleep -Milliseconds 200
while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }

# Send a key
$writer.WriteLine('sendkey a')
Start-Sleep -Seconds 2

# Disable logging
$writer.WriteLine('log none')
Start-Sleep -Milliseconds 200
while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }

# Take screenshot
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_io.ppm')
Start-Sleep -Seconds 1

$tcp.Close()
Write-Host "Done"
