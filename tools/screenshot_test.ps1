# Boot QEMU with telnet monitor, take screenshot
$BUILD_DIR = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"
$SCREENSHOT = "$BUILD_DIR\screenshot.ppm"

# Kill old
Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
Remove-Item $SCREENSHOT -ErrorAction SilentlyContinue

# Start QEMU with telnet monitor on port 55555
$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD_DIR\toaruos-arnold.elf",
    "-serial", "file:$BUILD_DIR\serial.log",
    "-monitor", "telnet:127.0.0.1:55555,server,nowait",
    "-display", "none"
) -PassThru

Write-Host "QEMU PID: $($proc.Id)"
Start-Sleep -Seconds 3

# Connect to monitor and take screenshot
try {
    $client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55555)
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    
    # Read banner
    Start-Sleep -Milliseconds 500
    while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }
    
    # Take screenshot
    $writer.WriteLine("screendump $SCREENSHOT")
    Start-Sleep -Seconds 1
    
    # Read response
    while ($stream.DataAvailable) { 
        $line = $reader.ReadLine()
        Write-Host "Monitor: $line"
    }
    
    $client.Close()
    
    if (Test-Path $SCREENSHOT) {
        $sz = (Get-Item $SCREENSHOT).Length
        Write-Host "Screenshot: $sz bytes"
        
        # Convert PPM to PNG using magick if available
        $magick = Get-Command magick -ErrorAction SilentlyContinue
        if ($magick) {
            & magick $SCREENSHOT "$BUILD_DIR\screenshot.png"
            Write-Host "Converted to PNG: $((Get-Item "$BUILD_DIR\screenshot.png").Length) bytes"
        } else {
            Write-Host "(no ImageMagick - PPM only)"
        }
    } else {
        Write-Host "No screenshot file created"
    }
} catch {
    Write-Host "Monitor error: $_"
}

# Check serial
Write-Host ""
Write-Host "=== SERIAL ==="
if (Test-Path "$BUILD_DIR\serial.log") {
    Get-Content "$BUILD_DIR\serial.log" -Raw
}

# Cleanup
if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
