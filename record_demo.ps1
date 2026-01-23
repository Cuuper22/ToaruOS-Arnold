# Record demo video of ToaruOS-Arnold kernel
# Captures multiple screenshots while simulating keyboard input

$frameDir = "C:\Users\Acer\Desktop\ToaruOS-Arnold\frames"
New-Item -ItemType Directory -Force -Path $frameDir | Out-Null

# Clean old frames
Get-ChildItem $frameDir -Filter "*.ppm" | Remove-Item

# Start QEMU with monitor
$qemuProcess = Start-Process -FilePath "C:\Program Files\qemu\qemu-system-i386.exe" -ArgumentList "-accel tcg,tb-size=64 -m 32M -vga std -kernel build/toaruos-arnold.elf -monitor tcp:127.0.0.1:4444,server,nowait" -WorkingDirectory "C:\Users\Acer\Desktop\ToaruOS-Arnold" -PassThru

# Wait for boot
Start-Sleep -Seconds 3

$client = New-Object System.Net.Sockets.TcpClient
try {
    $client.Connect("127.0.0.1", 4444)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    
    # Capture initial frames (just the UI)
    for ($i = 0; $i -lt 30; $i++) {
        $filename = "C:/Users/Acer/Desktop/ToaruOS-Arnold/frames/frame_{0:D4}.ppm" -f $i
        $writer.WriteLine("screendump $filename")
        Start-Sleep -Milliseconds 100
    }
    
    # Send 'a' key (scancode 0x1E) - green indicator
    $writer.WriteLine("sendkey a")
    Start-Sleep -Milliseconds 200
    
    for ($i = 30; $i -lt 50; $i++) {
        $filename = "C:/Users/Acer/Desktop/ToaruOS-Arnold/frames/frame_{0:D4}.ppm" -f $i
        $writer.WriteLine("screendump $filename")
        Start-Sleep -Milliseconds 100
    }
    
    # Send 'b' key (scancode 0x30) - red indicator
    $writer.WriteLine("sendkey b")
    Start-Sleep -Milliseconds 200
    
    for ($i = 50; $i -lt 70; $i++) {
        $filename = "C:/Users/Acer/Desktop/ToaruOS-Arnold/frames/frame_{0:D4}.ppm" -f $i
        $writer.WriteLine("screendump $filename")
        Start-Sleep -Milliseconds 100
    }
    
    # Send 'c' key (scancode 0x2E) - blue indicator
    $writer.WriteLine("sendkey c")
    Start-Sleep -Milliseconds 200
    
    for ($i = 70; $i -lt 90; $i++) {
        $filename = "C:/Users/Acer/Desktop/ToaruOS-Arnold/frames/frame_{0:D4}.ppm" -f $i
        $writer.WriteLine("screendump $filename")
        Start-Sleep -Milliseconds 100
    }
    
    # Back to 'a' - green
    $writer.WriteLine("sendkey a")
    Start-Sleep -Milliseconds 200
    
    for ($i = 90; $i -lt 120; $i++) {
        $filename = "C:/Users/Acer/Desktop/ToaruOS-Arnold/frames/frame_{0:D4}.ppm" -f $i
        $writer.WriteLine("screendump $filename")
        Start-Sleep -Milliseconds 100
    }
    
    # Quit QEMU
    $writer.WriteLine("quit")
    $writer.Close()
    $client.Close()
} catch {
    Write-Host "Error: $_"
}

Write-Host "Frames captured. Creating video..."

# Wait for QEMU to exit
Start-Sleep -Seconds 2
