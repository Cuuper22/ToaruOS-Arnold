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
Start-Sleep -Seconds 6

function QCmd($cmd) {
    for ($i = 0; $i -lt 3; $i++) {
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
            return
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
}

# Screenshot desktop (with wallpaper)
Remove-Item "$BUILD\screenshot_desktop.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\screenshot_desktop.ppm"
Start-Sleep -Seconds 1
if (Test-Path "$BUILD\screenshot_desktop.ppm") {
    Write-Host "Desktop: $((Get-Item "$BUILD\screenshot_desktop.ppm").Length) bytes"
} else { Write-Host "Desktop: MISSING" }

# Press 1 to launch terminal (should show welcome)
QCmd "sendkey 1"
Start-Sleep -Seconds 2

# Screenshot terminal with welcome
Remove-Item "$BUILD\screenshot_welcome.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\screenshot_welcome.ppm"
Start-Sleep -Seconds 1
if (Test-Path "$BUILD\screenshot_welcome.ppm") {
    Write-Host "Welcome: $((Get-Item "$BUILD\screenshot_welcome.ppm").Length) bytes"
} else { Write-Host "Welcome: MISSING" }

if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
