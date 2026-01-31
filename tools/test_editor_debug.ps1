# Debug editor key handling
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

# Step 1: Launch editor
QCmd "sendkey 0"
Start-Sleep -Seconds 3

# Step 2: Take empty screenshot
QCmd "screendump $BUILD\dbg1.ppm"
Start-Sleep -Seconds 1

# Step 3: Send just 'a' (scancode 0x1E) - wait longer
QCmd "sendkey a"
Start-Sleep -Seconds 3

# Step 4: Take screenshot after 'a'
QCmd "screendump $BUILD\dbg2.ppm"
Start-Sleep -Seconds 1

# Step 5: Try 'b' 
QCmd "sendkey b"
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\dbg3.ppm"
Start-Sleep -Seconds 1

# Step 6: Try typing in terminal instead (ESC first, then 1 for terminal, then type)
QCmd "sendkey esc"
Start-Sleep -Seconds 2
QCmd "sendkey 1"
Start-Sleep -Seconds 3
QCmd "sendkey h"
Start-Sleep -Seconds 2
QCmd "sendkey e"
Start-Sleep -Seconds 2
QCmd "sendkey l"
Start-Sleep -Seconds 2
QCmd "sendkey p"
Start-Sleep -Seconds 2

QCmd "screendump $BUILD\dbg_term.ppm"
Start-Sleep -Seconds 1

# Convert all
foreach ($f in @("dbg1","dbg2","dbg3","dbg_term")) {
    ffmpeg -y -i "$BUILD\$f.ppm" -frames:v 1 -update 1 "$BUILD\$f.png" 2>$null
    Write-Host "$f : $((Get-Item "$BUILD\$f.png" -EA SilentlyContinue).Length) bytes"
}

if (-not $proc.HasExited) { $proc.Kill(); Write-Host "OK" }
