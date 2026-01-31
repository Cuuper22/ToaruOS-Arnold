Start-Sleep -Seconds 6
$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

# Screenshot - should show green bar and waiting for keys
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/kbtest1.ppm')
Start-Sleep -Seconds 1

# Send 5 keys (a, b, c, d, e) via monitor
$writer.WriteLine('sendkey a')
Start-Sleep -Milliseconds 500
$writer.WriteLine('sendkey b')
Start-Sleep -Milliseconds 500
$writer.WriteLine('sendkey c')
Start-Sleep -Milliseconds 500
$writer.WriteLine('sendkey d')
Start-Sleep -Milliseconds 500
$writer.WriteLine('sendkey e')
Start-Sleep -Seconds 3

# Screenshot after keys
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/kbtest2.ppm')
Start-Sleep -Seconds 1
$tcp.Close()
