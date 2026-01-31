$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)
$writer.AutoFlush = $true

# Read initial prompt
Start-Sleep -Milliseconds 500

# Screenshot before
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_before.ppm')
Start-Sleep -Seconds 1

# Send ESC key (scancode 1 - not extended) to switch to terminal
$writer.WriteLine('sendkey esc')
Start-Sleep -Seconds 2

# Screenshot after ESC
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_esc.ppm')
Start-Sleep -Seconds 1

# Send letter 'a' (scancode 0x1E)
$writer.WriteLine('sendkey a')
Start-Sleep -Seconds 1

# Screenshot after 'a'
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_a.ppm')
Start-Sleep -Seconds 1

$tcp.Close()
