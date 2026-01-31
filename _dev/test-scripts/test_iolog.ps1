Start-Sleep -Seconds 10
$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

$writer.WriteLine('sendkey a')
Start-Sleep -Seconds 2
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/iolog.ppm')
Start-Sleep -Seconds 1
$tcp.Close()
