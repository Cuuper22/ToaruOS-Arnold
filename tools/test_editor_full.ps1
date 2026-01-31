# Full build + editor test
$root = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$BUILD = "$root\build"
$GEN = "$BUILD\gen"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

Get-Process -Name "qemu-system-i386" -EA SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Use pre-built ELF (already compiled by test_fresh.ps1)
if (-not (Test-Path "$BUILD\toaruos-arnold.elf") -or (Get-Item "$BUILD\toaruos-arnold.elf").Length -lt 1000) {
    Write-Host "No valid ELF found! Run test_fresh.ps1 first."
    exit 1
}
Write-Host "ELF: $((Get-Item "$BUILD\toaruos-arnold.elf").Length) bytes"

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
        Start-Sleep -Milliseconds 300
        $c.Close()
    } catch { Write-Host "ERR: $_" }
}

# Desktop screenshot
QCmd "screendump $BUILD\ed_desk.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\ed_desk.ppm" -frames:v 1 -update 1 "$BUILD\ed_desk.png" 2>$null
Write-Host "Desktop: $((Get-Item "$BUILD\ed_desk.png" -EA SilentlyContinue).Length) bytes"

# Press 0 for editor
Write-Host "=== LAUNCHING EDITOR ==="
QCmd "sendkey 0"
Start-Sleep -Seconds 5

QCmd "screendump $BUILD\editor_empty.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\editor_empty.ppm" -frames:v 1 -update 1 "$BUILD\editor_empty.png" 2>$null
Write-Host "Editor empty: $((Get-Item "$BUILD\editor_empty.png" -EA SilentlyContinue).Length) bytes"

# Type "Hello World"
Write-Host "=== TYPING ==="
foreach ($k in @("shift-h", "e", "l", "l", "o", "space", "shift-w", "o", "r", "l", "d")) {
    QCmd "sendkey $k"
    Start-Sleep -Milliseconds 400
}
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\editor_typed.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\editor_typed.ppm" -frames:v 1 -update 1 "$BUILD\editor_typed.png" 2>$null
Write-Host "Editor typed: $((Get-Item "$BUILD\editor_typed.png" -EA SilentlyContinue).Length) bytes"

# Press Enter, type line 2
Write-Host "=== ENTER + LINE 2 ==="
QCmd "sendkey ret"
Start-Sleep -Milliseconds 500
foreach ($k in @("shift-a", "r", "n", "o", "l", "d", "shift-c")) {
    QCmd "sendkey $k"
    Start-Sleep -Milliseconds 400
}
Start-Sleep -Seconds 3

QCmd "screendump $BUILD\editor_multi.ppm"
Start-Sleep -Milliseconds 500
ffmpeg -y -i "$BUILD\editor_multi.ppm" -frames:v 1 -update 1 "$BUILD\editor_multi.png" 2>$null
Write-Host "Editor multiline: $((Get-Item "$BUILD\editor_multi.png" -EA SilentlyContinue).Length) bytes"

if (-not $proc.HasExited) { $proc.Kill(); Write-Host "OK" } else { Write-Host "EXITED: $($proc.ExitCode)" }
