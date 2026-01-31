$tcp = New-Object System.Net.Sockets.TcpClient('127.0.0.1', 55555)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)
$writer.AutoFlush = $true

Start-Sleep -Milliseconds 500
# Drain welcome
while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }

# Check CPU state - is it running or halted?
$writer.WriteLine('info status')
Start-Sleep -Milliseconds 500
while ($stream.DataAvailable) { Write-Host $reader.ReadLine() }

# Check registers
$writer.WriteLine('info registers')
Start-Sleep -Milliseconds 500
$lines = @()
while ($stream.DataAvailable) { $lines += $reader.ReadLine() }
Write-Host "=== REGISTERS ==="
$lines | Select-Object -First 5 | ForEach-Object { Write-Host $_ }

# Send a key
$writer.WriteLine('sendkey a')
Start-Sleep -Seconds 1

# Check again
$writer.WriteLine('info registers')
Start-Sleep -Milliseconds 500
$lines2 = @()
while ($stream.DataAvailable) { $lines2 += $reader.ReadLine() }
Write-Host "=== REGISTERS AFTER KEY ==="
$lines2 | Select-Object -First 5 | ForEach-Object { Write-Host $_ }

$tcp.Close()
