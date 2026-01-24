param(
    [string]$OutputFile = "screenshot_current.ppm"
)

$client = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$fullPath = "C:/Users/Acer/Desktop/ToaruOS-Arnold/$OutputFile"
$writer.WriteLine("screendump $fullPath")
$writer.Flush()
Start-Sleep -Milliseconds 500
$client.Close()
Write-Host "Screenshot saved to: $fullPath"
