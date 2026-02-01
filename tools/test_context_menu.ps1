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
Start-Sleep -Seconds 5

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

# Move mouse to center of desktop (relative moves)
# QEMU mouse is relative. Send several moves to position roughly center
QCmd "mouse_move 300 200"
Start-Sleep -Milliseconds 500

# Right-click (QEMU button 4 = PS/2 right button = bit 1)
QCmd "mouse_button 4"
Start-Sleep -Milliseconds 500
QCmd "mouse_button 0"
Start-Sleep -Seconds 1

# Screenshot - should show context menu
Remove-Item "$BUILD\screenshot_ctx.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\screenshot_ctx.ppm"
Start-Sleep -Seconds 1
if (Test-Path "$BUILD\screenshot_ctx.ppm") {
    Write-Host "Context menu screenshot: $((Get-Item "$BUILD\screenshot_ctx.ppm").Length) bytes"
} else { Write-Host "Screenshot MISSING" }

if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
