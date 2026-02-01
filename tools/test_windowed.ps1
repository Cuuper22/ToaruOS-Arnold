# Test windowed games - launch QEMU, press key 2 (snake), take screenshot
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$KERNEL = "$ProjectRoot\build\toaruos-arnold.elf"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Write-Host "Starting QEMU..."
$proc = Start-Process -FilePath $QEMU -ArgumentList "-kernel `"$KERNEL`" -m 32M -display none -serial file:serial.log -monitor telnet:127.0.0.1:55556,server,nowait -device e1000,netdev=net0 -netdev user,id=net0" -PassThru -NoNewWindow
Start-Sleep -Seconds 12

Write-Host "Connecting to QEMU monitor..."
$tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55556)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true
$reader = New-Object System.IO.StreamReader($stream)
Start-Sleep -Milliseconds 500
while($stream.DataAvailable) { $reader.ReadLine() | Out-Null }

# Press key 2 to launch snake
Write-Host "Launching Snake (key 2)..."
$writer.WriteLine("sendkey 2")
Start-Sleep -Seconds 8

# Take screenshot
Write-Host "Taking screenshot..."
$writer.WriteLine("screendump $ProjectRoot/build/ss_snake_windowed.ppm")
Start-Sleep -Seconds 2

# Also test Chopper (key 5) - ESC first to go back to desktop
Write-Host "Returning to desktop (ESC)..."
$writer.WriteLine("sendkey esc")
Start-Sleep -Seconds 3

Write-Host "Launching Chopper (key 5)..."
$writer.WriteLine("sendkey 5")
Start-Sleep -Seconds 8

Write-Host "Taking Chopper screenshot..."
$writer.WriteLine("screendump $ProjectRoot/build/ss_chopper_windowed.ppm")
Start-Sleep -Seconds 2

# Also test Skynet (key 6)
Write-Host "Returning to desktop..."
$writer.WriteLine("sendkey esc")
Start-Sleep -Seconds 3

Write-Host "Launching Skynet (key 6)..."
$writer.WriteLine("sendkey 6")
Start-Sleep -Seconds 8

Write-Host "Taking Skynet screenshot..."
$writer.WriteLine("screendump $ProjectRoot/build/ss_skynet_windowed.ppm")
Start-Sleep -Seconds 2

$writer.WriteLine("quit")
$tcp.Close()
Write-Host "Done! Screenshots at build/ss_*_windowed.ppm"

try { $proc | Wait-Process -Timeout 5 } catch {}
