param([string]$cmd)
$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 4444)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true
Start-Sleep -Milliseconds 500
$writer.WriteLine($cmd)
Start-Sleep -Milliseconds 1000
$tcp.Close()
