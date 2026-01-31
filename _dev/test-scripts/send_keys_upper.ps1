param(
    [string]$Keys = "HELP"
)

$client = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)

foreach ($char in $Keys.ToCharArray()) {
    $key = $char.ToString().ToLower()
    if ($char -cmatch '[A-Z]') {
        # For uppercase, send shift+key
        $writer.WriteLine("sendkey shift-$key")
    } else {
        $writer.WriteLine("sendkey $key")
    }
    $writer.Flush()
    Start-Sleep -Milliseconds 100
}

$writer.WriteLine("sendkey ret")
$writer.Flush()
Start-Sleep -Milliseconds 500
$client.Close()
Write-Host "Sent: $Keys [Enter]"
