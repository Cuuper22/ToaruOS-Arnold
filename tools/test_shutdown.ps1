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
Start-Sleep -Seconds 10

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

# Launch terminal (key 1)
QCmd "sendkey 1"
Start-Sleep -Seconds 2

# Type "shutdown" + enter
# s=0x1f, h=0x23, u=0x16, t=0x14, d=0x20, o=0x18, w=0x11, n=0x31
QCmd "sendkey s"
Start-Sleep -Milliseconds 100
QCmd "sendkey h"
Start-Sleep -Milliseconds 100
QCmd "sendkey u"
Start-Sleep -Milliseconds 100
QCmd "sendkey t"
Start-Sleep -Milliseconds 100
QCmd "sendkey d"
Start-Sleep -Milliseconds 100
QCmd "sendkey o"
Start-Sleep -Milliseconds 100
QCmd "sendkey w"
Start-Sleep -Milliseconds 100
QCmd "sendkey n"
Start-Sleep -Milliseconds 100
QCmd "sendkey ret"
Start-Sleep -Seconds 3

# Screenshot the terminal shutdown text
Remove-Item "$BUILD\ss_shutdown1.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_shutdown1.ppm"
Start-Sleep -Seconds 1
Write-Host "Shutdown text: $((Get-Item "$BUILD\ss_shutdown1.ppm" -ErrorAction SilentlyContinue).Length) bytes"

# Wait for visual shutdown to start
Start-Sleep -Seconds 5

# Screenshot the visual shutdown
Remove-Item "$BUILD\ss_shutdown2.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_shutdown2.ppm"
Start-Sleep -Seconds 1
Write-Host "Shutdown visual: $((Get-Item "$BUILD\ss_shutdown2.ppm" -ErrorAction SilentlyContinue).Length) bytes"

# Wait for "Hasta la vista" screen
Start-Sleep -Seconds 5

Remove-Item "$BUILD\ss_shutdown3.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_shutdown3.ppm"
Start-Sleep -Seconds 1
Write-Host "Hasta la vista: $((Get-Item "$BUILD\ss_shutdown3.ppm" -ErrorAction SilentlyContinue).Length) bytes"

if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
