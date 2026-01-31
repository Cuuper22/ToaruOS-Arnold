param(
    [string]$Key = "esc"
)

$client = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.WriteLine("sendkey $Key")
$writer.Flush()
Start-Sleep -Milliseconds 300
$client.Close()
Write-Host "Sent key: $Key"
