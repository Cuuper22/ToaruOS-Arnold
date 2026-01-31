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
Start-Sleep -Seconds 5

# Single persistent connection
$client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55555)
$stream = $client.GetStream()
$reader = New-Object System.IO.StreamReader($stream)
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true
Start-Sleep -Milliseconds 500
while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }

function Mon($cmd) {
    $writer.WriteLine($cmd)
    Start-Sleep -Milliseconds 200
    while ($stream.DataAvailable) { $reader.ReadLine() | Out-Null }
}

function TypeText($text) {
    foreach ($ch in $text.ToCharArray()) {
        $key = $ch.ToString()
        if ($key -eq ' ') { $key = 'spc' }
        Mon "sendkey $key"
        Start-Sleep -Milliseconds 80
    }
}

# Click terminal icon (bottom of screen, taskbar area)
Write-Host "Opening terminal..."
Mon "mouse_move 42 748"
Mon "mouse_button 1"
Start-Sleep -Milliseconds 100
Mon "mouse_button 0"
Start-Sleep -Seconds 3

# Type "banner" and press Enter
Write-Host "Running 'banner'..."
TypeText "banner"
Start-Sleep -Milliseconds 200
Mon "sendkey ret"
Start-Sleep -Seconds 2

# Screenshot banner
Remove-Item "$BUILD_DIR\screenshot_banner.ppm" -ErrorAction SilentlyContinue
Mon "screendump $BUILD_DIR\screenshot_banner.ppm"
Start-Sleep -Seconds 1
Write-Host "Banner screenshot taken"

# Type "logo" and press Enter
Write-Host "Running 'logo'..."
TypeText "logo"
Start-Sleep -Milliseconds 200
Mon "sendkey ret"
Start-Sleep -Seconds 2

# Screenshot logo
Remove-Item "$BUILD_DIR\screenshot_logo.ppm" -ErrorAction SilentlyContinue
Mon "screendump $BUILD_DIR\screenshot_logo.ppm"
Start-Sleep -Seconds 1
Write-Host "Logo screenshot taken"

$client.Close()

# Check screenshots
foreach ($name in @("screenshot_banner", "screenshot_logo")) {
    $ppm = "$BUILD_DIR\$name.ppm"
    if (Test-Path $ppm) {
        Write-Host "$name : $((Get-Item $ppm).Length) bytes"
    } else {
        Write-Host "$name : MISSING"
    }
}

if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
