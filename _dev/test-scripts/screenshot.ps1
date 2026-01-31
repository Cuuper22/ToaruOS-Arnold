$client = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.WriteLine("screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/build/screen_test.ppm")
$writer.Flush()
Start-Sleep -Milliseconds 500
$client.Close()
Write-Host "Screenshot saved to build/screen_test.ppm"
