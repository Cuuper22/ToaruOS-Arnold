param([string]$outfile = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build\test_phase3_menu.ppm")
$c = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 4444)
$s = $c.GetStream()
$w = New-Object System.IO.StreamWriter($s)
$w.WriteLine("screendump $outfile")
$w.Flush()
Start-Sleep -Milliseconds 1000
$c.Close()
Write-Host "Screendump saved to $outfile"
