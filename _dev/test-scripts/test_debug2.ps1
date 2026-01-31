# Wait for boot
Start-Sleep -Seconds 8

$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

# Screenshot - should show menu with debug pixels
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/dbg_fresh1.ppm')
Start-Sleep -Seconds 2

# Send letter 'a' (not ESC - ESC resets QEMU SDL!)
$writer.WriteLine('sendkey a')
Start-Sleep -Seconds 2

# Screenshot after key
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/dbg_fresh2.ppm')
Start-Sleep -Seconds 1

$tcp.Close()
