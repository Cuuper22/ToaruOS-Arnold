$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true

# First press ESC to go to terminal mode
$writer.WriteLine('sendkey esc')
Start-Sleep -Seconds 2

# Type some letters - should appear in terminal
$writer.WriteLine('sendkey h')
Start-Sleep -Milliseconds 500
$writer.WriteLine('sendkey i')
Start-Sleep -Seconds 2

# Screenshot
$writer.WriteLine('screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/test_terminal.ppm')
Start-Sleep -Seconds 1
$tcp.Close()
