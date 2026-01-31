$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

Start-Sleep -Seconds 6

# Screenshot before any key
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/debug1.ppm')
Start-Sleep -Seconds 2

# Send ESC key
$writer.WriteLine('sendkey esc')
Start-Sleep -Seconds 2

# Screenshot after ESC
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/debug2.ppm')
Start-Sleep -Seconds 1

$tcp.Close()
