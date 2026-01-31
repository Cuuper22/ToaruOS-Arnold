Start-Sleep -Seconds 8
$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

# Screenshot menu
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/clean1.ppm')
Start-Sleep -Seconds 1

# Navigate down twice and take screenshot
$writer.WriteLine('sendkey down')
Start-Sleep -Milliseconds 500
$writer.WriteLine('sendkey down')
Start-Sleep -Seconds 2
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/clean2.ppm')
Start-Sleep -Seconds 1
$tcp.Close()
