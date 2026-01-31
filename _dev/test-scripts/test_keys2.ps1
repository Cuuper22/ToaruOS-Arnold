$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

# Screenshot before any keys
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_before.ppm')
Start-Sleep -Seconds 2

# Send one down arrow
$writer.WriteLine('sendkey down')
Start-Sleep -Seconds 2

# Screenshot after one down
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_after1.ppm')
Start-Sleep -Seconds 1

$tcp.Close()
