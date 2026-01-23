# Record comprehensive demo of ToaruOS-Arnold kernel
# Shows boot sequence and all keyboard interactions

$frameDir = "C:\Users\Acer\Desktop\ToaruOS-Arnold\demo_frames"
New-Item -ItemType Directory -Force -Path $frameDir | Out-Null

# Clean old frames
Get-ChildItem $frameDir -Filter "*.ppm" | Remove-Item -ErrorAction SilentlyContinue

Write-Host "Starting QEMU..."

# Start QEMU with monitor
$qemuProcess = Start-Process -FilePath "C:\Program Files\qemu\qemu-system-i386.exe" -ArgumentList "-accel tcg,tb-size=64 -m 32M -vga std -kernel build/toaruos-arnold.elf -monitor tcp:127.0.0.1:4444,server,nowait" -WorkingDirectory "C:\Users\Acer\Desktop\ToaruOS-Arnold" -PassThru

# Wait for boot
Start-Sleep -Seconds 2

$client = New-Object System.Net.Sockets.TcpClient
$frameNum = 0

function Capture-Frames($count, $delayMs) {
    for ($i = 0; $i -lt $count; $i++) {
        $script:frameNum++
        $filename = "C:/Users/Acer/Desktop/ToaruOS-Arnold/demo_frames/frame_{0:D4}.ppm" -f $script:frameNum
        $writer.WriteLine("screendump $filename")
        Start-Sleep -Milliseconds $delayMs
    }
}

try {
    $client.Connect("127.0.0.1", 4444)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    
    Write-Host "Recording boot sequence..."
    # Boot sequence - show initial UI (2 seconds at 10fps = 20 frames)
    Capture-Frames 20 100
    
    Write-Host "Demonstrating keyboard: A key (GREEN indicator)..."
    # Press 'a' - green indicator
    $writer.WriteLine("sendkey a")
    Start-Sleep -Milliseconds 300
    Capture-Frames 15 100
    
    Write-Host "Demonstrating keyboard: B key (RED indicator)..."
    # Press 'b' - red indicator  
    $writer.WriteLine("sendkey b")
    Start-Sleep -Milliseconds 300
    Capture-Frames 15 100
    
    Write-Host "Demonstrating keyboard: C key (BLUE indicator)..."
    # Press 'c' - blue indicator
    $writer.WriteLine("sendkey c")
    Start-Sleep -Milliseconds 300
    Capture-Frames 15 100
    
    Write-Host "Demonstrating keyboard: ESC key (WHITE indicator)..."
    # Press 'esc' - white indicator
    $writer.WriteLine("sendkey esc")
    Start-Sleep -Milliseconds 300
    Capture-Frames 15 100
    
    Write-Host "Demonstrating keyboard: Other keys (SILVER indicator)..."
    # Press other keys - silver indicator
    $writer.WriteLine("sendkey d")
    Start-Sleep -Milliseconds 300
    Capture-Frames 10 100
    
    $writer.WriteLine("sendkey e")
    Start-Sleep -Milliseconds 300
    Capture-Frames 10 100
    
    Write-Host "Cycling through colors..."
    # Cycle through colors again to show responsiveness
    $writer.WriteLine("sendkey a")
    Start-Sleep -Milliseconds 200
    Capture-Frames 8 100
    
    $writer.WriteLine("sendkey b")
    Start-Sleep -Milliseconds 200
    Capture-Frames 8 100
    
    $writer.WriteLine("sendkey c")
    Start-Sleep -Milliseconds 200
    Capture-Frames 8 100
    
    $writer.WriteLine("sendkey a")
    Start-Sleep -Milliseconds 200
    Capture-Frames 8 100
    
    Write-Host "Final hold on green..."
    # Hold on green for ending
    Capture-Frames 20 100
    
    Write-Host "Stopping QEMU..."
    # Quit QEMU
    $writer.WriteLine("quit")
    $writer.Close()
    $client.Close()
} catch {
    Write-Host "Error: $_"
}

Write-Host "Total frames captured: $frameNum"
Write-Host "Creating video..."

# Wait for QEMU to exit
Start-Sleep -Seconds 2
