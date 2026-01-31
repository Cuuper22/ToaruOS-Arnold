# Test editor with full typing
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

# Launch editor
QCmd "sendkey 0"
Start-Sleep -Seconds 3

# Type "hello world" 
foreach ($k in @("h","e","l","l","o","space","w","o","r","l","d")) {
    QCmd "sendkey $k"
    Start-Sleep -Milliseconds 800
}
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\editor_hello.ppm"
Start-Sleep -Seconds 1

# Press Enter and type line 2
QCmd "sendkey ret"
Start-Sleep -Seconds 1
foreach ($k in @("i","space","a","m","space","a","r","n","o","l","d")) {
    QCmd "sendkey $k"
    Start-Sleep -Milliseconds 800
}
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\editor_multi.ppm"
Start-Sleep -Seconds 1

# Press backspace a few times
QCmd "sendkey backspace"
Start-Sleep -Seconds 1
QCmd "sendkey backspace"
Start-Sleep -Seconds 1
QCmd "sendkey backspace"
Start-Sleep -Seconds 1

QCmd "screendump $BUILD\editor_bs.ppm"
Start-Sleep -Seconds 1

# Convert
foreach ($f in @("editor_hello","editor_multi","editor_bs")) {
    ffmpeg -y -i "$BUILD\$f.ppm" -frames:v 1 -update 1 "$BUILD\$f.png" 2>$null
    Write-Host "$f : $((Get-Item "$BUILD\$f.png" -EA SilentlyContinue).Length) bytes"
}

if (-not $proc.HasExited) { $proc.Kill(); Write-Host "OK" }
