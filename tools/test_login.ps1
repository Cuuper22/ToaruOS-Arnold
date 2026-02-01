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

# Capture boot splash early (~3s in)
Start-Sleep -Seconds 3
Remove-Item "$BUILD\ss_boot.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_boot.ppm"
Start-Sleep -Seconds 1
Write-Host "Boot: $((Get-Item "$BUILD\ss_boot.ppm" -ErrorAction SilentlyContinue).Length) bytes"

# Capture login screen (~6s in, after boot splash loading bar ~5s)
Start-Sleep -Seconds 3
Remove-Item "$BUILD\ss_login.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_login.ppm"
Start-Sleep -Seconds 1
Write-Host "Login: $((Get-Item "$BUILD\ss_login.ppm" -ErrorAction SilentlyContinue).Length) bytes"

# Capture desktop (~12s in)
Start-Sleep -Seconds 5
Remove-Item "$BUILD\ss_desktop.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_desktop.ppm"
Start-Sleep -Seconds 1
Write-Host "Desktop: $((Get-Item "$BUILD\ss_desktop.ppm" -ErrorAction SilentlyContinue).Length) bytes"

if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
