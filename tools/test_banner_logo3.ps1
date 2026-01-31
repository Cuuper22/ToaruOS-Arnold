$BUILD = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD\toaruos-arnold.elf",
    "-serial", "file:$BUILD\serial.log",
    "-monitor", "telnet:127.0.0.1:55555,server,nowait",
    "-display", "none"
) -PassThru

Write-Host "QEMU PID: $($proc.Id)"
Start-Sleep -Seconds 3

function QCmd($cmd) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55555)
        $s = $c.GetStream()
        $w = New-Object System.IO.StreamWriter($s)
        $w.AutoFlush = $true
        Start-Sleep -Milliseconds 200
        while ($s.DataAvailable) { $s.ReadByte() | Out-Null }
        $w.WriteLine($cmd)
        Start-Sleep -Milliseconds 300
        $c.Close()
    } catch { Write-Host "ERR: $_" }
}

# Press 1 to launch terminal from desktop
QCmd "sendkey 1"
Start-Sleep -Seconds 2

# Type "banner" and press enter
foreach ($k in @("b","a","n","n","e","r")) {
    QCmd "sendkey $k"
    Start-Sleep -Milliseconds 300
}
QCmd "sendkey ret"
Start-Sleep -Seconds 2

# Screenshot banner
Remove-Item "$BUILD\screenshot_banner.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\screenshot_banner.ppm"
Start-Sleep -Seconds 1

if (Test-Path "$BUILD\screenshot_banner.ppm") {
    Write-Host "Banner: $((Get-Item "$BUILD\screenshot_banner.ppm").Length) bytes"
} else {
    Write-Host "Banner: MISSING"
}

# Type "logo" and press enter  
foreach ($k in @("l","o","g","o")) {
    QCmd "sendkey $k"
    Start-Sleep -Milliseconds 300
}
QCmd "sendkey ret"
Start-Sleep -Seconds 2

# Screenshot logo
Remove-Item "$BUILD\screenshot_logo.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\screenshot_logo.ppm"
Start-Sleep -Seconds 1

if (Test-Path "$BUILD\screenshot_logo.ppm") {
    Write-Host "Logo: $((Get-Item "$BUILD\screenshot_logo.ppm").Length) bytes"
} else {
    Write-Host "Logo: MISSING"
}

if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
