$BUILD_DIR = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

# Kill old
Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Start QEMU with telnet monitor
$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD_DIR\toaruos-arnold.elf",
    "-serial", "file:$BUILD_DIR\serial.log",
    "-monitor", "telnet:127.0.0.1:55555,server,nowait",
    "-display", "none"
) -PassThru

Write-Host "QEMU PID: $($proc.Id)"
Start-Sleep -Seconds 4

function Send-QemuMonitor($cmd) {
    try {
        $client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55555)
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true
        Start-Sleep -Milliseconds 300
        while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }
        $writer.WriteLine($cmd)
        Start-Sleep -Milliseconds 500
        while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }
        $client.Close()
    } catch {
        Write-Host "Monitor error: $_"
    }
}

function Send-Keys($text) {
    foreach ($ch in $text.ToCharArray()) {
        $key = $ch.ToString()
        if ($key -eq ' ') { $key = 'spc' }
        Send-QemuMonitor "sendkey $key"
        Start-Sleep -Milliseconds 100
    }
}

# Wait for desktop to load, then open terminal
Start-Sleep -Seconds 2
Write-Host "Clicking terminal icon..."
Send-QemuMonitor "mouse_move 512 400"
Start-Sleep -Milliseconds 200
# Terminal is typically at bottom of taskbar or we type from desktop
# The OS boots to desktop - click on the terminal icon area
Send-QemuMonitor "mouse_move 42 748"
Start-Sleep -Milliseconds 200
Send-QemuMonitor "mouse_button 1"
Start-Sleep -Milliseconds 100
Send-QemuMonitor "mouse_button 0"
Start-Sleep -Seconds 2

# Type "banner" command
Write-Host "Typing 'banner'..."
Send-Keys "banner"
Start-Sleep -Milliseconds 200
Send-QemuMonitor "sendkey ret"
Start-Sleep -Seconds 2

# Take screenshot 1 - banner
Remove-Item "$BUILD_DIR\screenshot_banner.ppm" -ErrorAction SilentlyContinue
Send-QemuMonitor "screendump $BUILD_DIR\screenshot_banner.ppm"
Start-Sleep -Seconds 1

if (Test-Path "$BUILD_DIR\screenshot_banner.ppm") {
    $sz = (Get-Item "$BUILD_DIR\screenshot_banner.ppm").Length
    Write-Host "Banner screenshot: $sz bytes"
    $magick = Get-Command magick -ErrorAction SilentlyContinue
    if ($magick) {
        & magick "$BUILD_DIR\screenshot_banner.ppm" "$BUILD_DIR\screenshot_banner.png"
        Write-Host "Converted banner to PNG"
    }
} else {
    Write-Host "No banner screenshot"
}

# Type "logo" command
Write-Host "Typing 'logo'..."
Send-Keys "logo"
Start-Sleep -Milliseconds 200
Send-QemuMonitor "sendkey ret"
Start-Sleep -Seconds 2

# Take screenshot 2 - logo  
Remove-Item "$BUILD_DIR\screenshot_logo.ppm" -ErrorAction SilentlyContinue
Send-QemuMonitor "screendump $BUILD_DIR\screenshot_logo.ppm"
Start-Sleep -Seconds 1

if (Test-Path "$BUILD_DIR\screenshot_logo.ppm") {
    $sz = (Get-Item "$BUILD_DIR\screenshot_logo.ppm").Length
    Write-Host "Logo screenshot: $sz bytes"
    $magick = Get-Command magick -ErrorAction SilentlyContinue
    if ($magick) {
        & magick "$BUILD_DIR\screenshot_logo.ppm" "$BUILD_DIR\screenshot_logo.png"
        Write-Host "Converted logo to PNG"
    }
} else {
    Write-Host "No logo screenshot"
}

# Cleanup
if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
