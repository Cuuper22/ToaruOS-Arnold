Start-Sleep -Seconds 6
$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_before.ppm')
Start-Sleep -Seconds 1

$writer.WriteLine('sendkey down')
Start-Sleep -Milliseconds 500
$writer.WriteLine('sendkey down')
Start-Sleep -Milliseconds 500
$writer.WriteLine('sendkey down')
Start-Sleep -Seconds 2

$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_after.ppm')
Start-Sleep -Seconds 1
$tcp.Close()
