# Test file manager
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

Start-Sleep -Seconds 4

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

# Press F to launch file manager
QCmd "sendkey f"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\fm_root.ppm"
Start-Sleep -Seconds 1

# Navigate down (S key)
QCmd "sendkey s"
Start-Sleep -Seconds 2
QCmd "sendkey s"
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\fm_nav.ppm"
Start-Sleep -Seconds 1

# Enter a directory
QCmd "sendkey ret"
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\fm_subdir.ppm"
Start-Sleep -Seconds 1

# Go back (backspace)
QCmd "sendkey backspace"
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\fm_back.ppm"
Start-Sleep -Seconds 1

# Convert
foreach ($f in @("fm_root","fm_nav","fm_subdir","fm_back")) {
    ffmpeg -y -i "$BUILD\$f.ppm" -frames:v 1 -update 1 "$BUILD\$f.png" 2>$null
    Write-Host "$f : $((Get-Item "$BUILD\$f.png" -EA SilentlyContinue).Length) bytes"
}

if (-not $proc.HasExited) { $proc.Kill(); Write-Host "OK" }
