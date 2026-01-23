# Start QEMU with monitor on TCP port
$qemuProcess = Start-Process -FilePath "C:\Program Files\qemu\qemu-system-i386.exe" -ArgumentList "-accel tcg,tb-size=64 -m 32M -vga std -kernel build/toaruos-arnold.elf -monitor tcp:127.0.0.1:4444,server,nowait" -WorkingDirectory "C:\Users\Acer\Desktop\ToaruOS-Arnold" -PassThru

# Wait for QEMU to start and kernel to boot
Start-Sleep -Seconds 5

# Connect to monitor and take screenshot
$client = New-Object System.Net.Sockets.TcpClient
try {
    $client.Connect("127.0.0.1", 4444)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    
    # Send screendump command
    $writer.WriteLine("screendump C:/Users/Acer/Desktop/ToaruOS-Arnold/screenshot.ppm")
    Start-Sleep -Seconds 1
    
    # Quit QEMU
    $writer.WriteLine("quit")
    $writer.Close()
    $client.Close()
} catch {
    Write-Host "Error: $_"
}

# Wait for QEMU to exit
Start-Sleep -Seconds 2
Write-Host "Screenshot saved to screenshot.ppm"
