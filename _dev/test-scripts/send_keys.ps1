param(
    [string]$Keys = "help"
)

$client = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)

foreach ($char in $Keys.ToCharArray()) {
    $writer.WriteLine("sendkey $char")
    $writer.Flush()
    Start-Sleep -Milliseconds 100
}

$writer.WriteLine("sendkey ret")
$writer.Flush()
Start-Sleep -Milliseconds 500
$client.Close()
Write-Host "Sent: $Keys [Enter]"
