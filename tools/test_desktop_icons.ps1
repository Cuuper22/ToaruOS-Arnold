# Quick desktop screenshot
$BUILD = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -EA SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD\toaruos-arnold.elf",
    "-serial", "file:$BUILD\serial.log",
    "-monitor", "telnet:127.0.0.1:55555,server,nowait",
    "-display", "none"
) -PassThru

Start-Sleep -Seconds 5

function QCmd($cmd) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 55555)
        $s = $c.GetStream()
        $w = New-Object System.IO.StreamWriter($s)
        $w.AutoFlush = $true
        Start-Sleep -Milliseconds 200
        while ($s.DataAvailable) { $s.ReadByte() | Out-Null }
        $w.WriteLine($cmd)
        Start-Sleep -Milliseconds 500
        $c.Close()
    } catch { Write-Host "ERR: $_" }
}

QCmd "screendump $BUILD\desktop_icons.ppm"
Start-Sleep -Seconds 1
ffmpeg -y -i "$BUILD\desktop_icons.ppm" -frames:v 1 -update 1 "$BUILD\desktop_icons.png" 2>$null
Write-Host "Desktop: $((Get-Item "$BUILD\desktop_icons.png" -EA SilentlyContinue).Length) bytes"

if (-not $proc.HasExited) { $proc.Kill(); Write-Host "OK" }
