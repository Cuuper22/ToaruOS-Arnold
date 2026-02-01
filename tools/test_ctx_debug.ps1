$BUILD = "C:\Users\Acer\Desktop\ToaruOS-Arnold\build"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD\toaruos-arnold.elf",
    "-serial", "file:$BUILD\serial_dbg.log",
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

# Step 1: Screenshot before any interaction
Remove-Item "$BUILD\ss_step1.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_step1.ppm"
Start-Sleep -Seconds 1
Write-Host "Step 1 (boot): $((Get-Item "$BUILD\ss_step1.ppm" -ErrorAction SilentlyContinue).Length) bytes"

# Step 2: Move mouse to center
QCmd "mouse_move 400 300"
Start-Sleep -Milliseconds 500

Remove-Item "$BUILD\ss_step2.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_step2.ppm"
Start-Sleep -Seconds 1
Write-Host "Step 2 (after move): $((Get-Item "$BUILD\ss_step2.ppm" -ErrorAction SilentlyContinue).Length) bytes"

# Step 3: Right-click (QEMU button 4 = right)
QCmd "mouse_button 4"
Start-Sleep -Milliseconds 500

Remove-Item "$BUILD\ss_step3.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_step3.ppm"
Start-Sleep -Seconds 1
Write-Host "Step 3 (right-click down): $((Get-Item "$BUILD\ss_step3.ppm" -ErrorAction SilentlyContinue).Length) bytes"

# Step 4: Release
QCmd "mouse_button 0"
Start-Sleep -Milliseconds 500

Remove-Item "$BUILD\ss_step4.ppm" -ErrorAction SilentlyContinue
QCmd "screendump $BUILD\ss_step4.ppm"
Start-Sleep -Seconds 1
Write-Host "Step 4 (release): $((Get-Item "$BUILD\ss_step4.ppm" -ErrorAction SilentlyContinue).Length) bytes"

if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "Done"
