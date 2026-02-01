# ToaruOS-Arnold Demo Video Recorder
# Captures QEMU screenshots at intervals while driving the OS through all features
# Then assembles them into a demo video with ffmpeg

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$KERNEL = "$ProjectRoot\build\toaruos-arnold.elf"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"
$FRAMES_DIR = "$ProjectRoot\build\demo_frames"
$PORT = 55557

# Clean up old frames
if (Test-Path $FRAMES_DIR) { Remove-Item $FRAMES_DIR -Recurse -Force }
New-Item -ItemType Directory -Path $FRAMES_DIR -Force | Out-Null

Write-Host "=== ToaruOS-Arnold Demo Video Recorder ==="
Write-Host "Starting QEMU..."

$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-kernel", "`"$KERNEL`"",
    "-m", "32M",
    "-display", "none",
    "-serial", "file:serial.log",
    "-monitor", "telnet:127.0.0.1:$PORT,server,nowait",
    "-device", "e1000,netdev=net0",
    "-netdev", "user,id=net0"
) -PassThru -NoNewWindow

Start-Sleep -Seconds 8

Write-Host "Connecting to QEMU monitor..."
$tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", $PORT)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true
$reader = New-Object System.IO.StreamReader($stream)
Start-Sleep -Milliseconds 500
while($stream.DataAvailable) { $reader.ReadLine() | Out-Null }

$frameNum = 0

function Capture-Frame {
    param([string]$label)
    $script:frameNum++
    $paddedNum = $script:frameNum.ToString("D4")
    $path = "$FRAMES_DIR/frame_${paddedNum}.ppm"
    $writer.WriteLine("screendump $path")
    Start-Sleep -Milliseconds 300
    Write-Host "  [$paddedNum] $label"
}

function Send-Key {
    param([string]$key)
    $writer.WriteLine("sendkey $key")
}

function Wait-Ms {
    param([int]$ms)
    Start-Sleep -Milliseconds $ms
}

function Type-Text {
    param([string]$text)
    foreach ($char in $text.ToCharArray()) {
        $keyName = switch ($char) {
            ' ' { 'spc' }
            '.' { 'dot' }
            '/' { 'slash' }
            ':' { 'shift-semicolon' }
            '-' { 'minus' }
            default { $char.ToString().ToLower() }
        }
        Send-Key $keyName
        Start-Sleep -Milliseconds 80
    }
}

Write-Host ""
Write-Host "--- SCENE 1: Boot Sequence (wait for splash + login) ---"
# Boot splash takes ~8 seconds, then login screen, then desktop
Start-Sleep -Seconds 4
Capture-Frame "boot-splash-early"
Start-Sleep -Seconds 3
Capture-Frame "boot-splash-late"
Start-Sleep -Seconds 4
Capture-Frame "login-screen"
Start-Sleep -Seconds 3

Write-Host "--- SCENE 2: Desktop ---"
# Desktop should be showing now
for ($i = 0; $i -lt 5; $i++) {
    Capture-Frame "desktop-$i"
    Wait-Ms 400
}

Write-Host "--- SCENE 3: Terminal ---"
Send-Key "1"
Start-Sleep -Seconds 4
Capture-Frame "terminal-open"

# Type some commands
Wait-Ms 500
Type-Text "neofetch"
Send-Key "ret"
Start-Sleep -Seconds 2
Capture-Frame "neofetch"

Wait-Ms 500
Type-Text "ver"
Send-Key "ret"
Start-Sleep -Seconds 1
Capture-Frame "ver"

Wait-Ms 500
Type-Text "cowsay"
Send-Key "ret"
Start-Sleep -Seconds 1
Capture-Frame "cowsay"

Wait-Ms 500
Type-Text "fortune"
Send-Key "ret"
Start-Sleep -Seconds 1
Capture-Frame "fortune"

Wait-Ms 500
Type-Text "date"
Send-Key "ret"
Start-Sleep -Seconds 1
Capture-Frame "date"

Wait-Ms 500
Type-Text "ifconfig"
Send-Key "ret"
Start-Sleep -Seconds 1
Capture-Frame "ifconfig"

Wait-Ms 500
Type-Text "ping"
Send-Key "ret"
Start-Sleep -Seconds 3
Capture-Frame "ping"

# Return to desktop
Send-Key "esc"
Start-Sleep -Seconds 2
Capture-Frame "back-to-desktop"

Write-Host "--- SCENE 4: Snake Game (in window!) ---"
Send-Key "2"
Start-Sleep -Seconds 5
for ($i = 0; $i -lt 8; $i++) {
    Capture-Frame "snake-$i"
    # Move snake around
    switch ($i % 4) {
        0 { Send-Key "d" }  # right
        1 { Send-Key "s" }  # down
        2 { Send-Key "a" }  # left
        3 { Send-Key "w" }  # up
    }
    Wait-Ms 600
}
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 5: Pong Game ---"
Send-Key "3"
Start-Sleep -Seconds 5
for ($i = 0; $i -lt 6; $i++) {
    Capture-Frame "pong-$i"
    Send-Key "w"
    Wait-Ms 500
}
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 6: Breakout Game ---"
Send-Key "4"
Start-Sleep -Seconds 5
for ($i = 0; $i -lt 6; $i++) {
    Capture-Frame "breakout-$i"
    Send-Key "d"
    Wait-Ms 500
}
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 7: Chopper Game ---"
Send-Key "5"
Start-Sleep -Seconds 5
for ($i = 0; $i -lt 6; $i++) {
    Capture-Frame "chopper-$i"
    Send-Key "spc"
    Wait-Ms 600
}
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 8: Skynet Defense ---"
Send-Key "6"
Start-Sleep -Seconds 5
for ($i = 0; $i -lt 6; $i++) {
    Capture-Frame "skynet-$i"
    Send-Key "spc"
    Wait-Ms 500
}
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 9: Calculator ---"
Send-Key "7"
Start-Sleep -Seconds 4
Capture-Frame "calculator"
# Type some numbers
Send-Key "5"
Wait-Ms 300
Capture-Frame "calc-5"
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 10: Settings (Theme change) ---"
Send-Key "9"
Start-Sleep -Seconds 4
Capture-Frame "settings-default"
# Switch to theme 2 (press 2)
Send-Key "s"
Wait-Ms 500
Capture-Frame "settings-2"
Send-Key "ret"
Wait-Ms 500
Capture-Frame "settings-applied"
Send-Key "esc"
Start-Sleep -Seconds 2
Capture-Frame "desktop-new-theme"

# Switch back to default
Send-Key "9"
Start-Sleep -Seconds 4
Send-Key "w"
Wait-Ms 500
Send-Key "ret"
Wait-Ms 500
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 11: Text Editor ---"
Send-Key "0"
Start-Sleep -Seconds 4
Capture-Frame "text-editor"
Type-Text "hello world"
Wait-Ms 500
Capture-Frame "editor-typing"
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 12: File Manager ---"
# Press F key (scancode 0x21)
Send-Key "f"
Start-Sleep -Seconds 4
Capture-Frame "file-manager"
Send-Key "esc"
Start-Sleep -Seconds 2

Write-Host "--- SCENE 13: Final Desktop ---"
for ($i = 0; $i -lt 5; $i++) {
    Capture-Frame "final-desktop-$i"
    Wait-Ms 400
}

Write-Host ""
Write-Host "=== Recording complete! $frameNum frames captured ==="

# Quit QEMU
$writer.WriteLine("quit")
$tcp.Close()
try { $proc | Wait-Process -Timeout 5 } catch {}

# Convert PPMs to PNGs and assemble video
Write-Host ""
Write-Host "=== Assembling video with ffmpeg ==="

# First convert all PPMs to PNGs (ffmpeg can read PPM directly but let's be safe)
$outputVideo = "$ProjectRoot\build\demo.mp4"

# Use ffmpeg to create video from PPM frames
# 3 fps for a slideshow-like feel (each frame visible for ~333ms)
& ffmpeg -y -framerate 3 -i "$FRAMES_DIR/frame_%04d.ppm" -vf "scale=1024:768:flags=neighbor" -c:v libx264 -pix_fmt yuv420p -crf 18 $outputVideo 2>&1 | Select-Object -Last 5

if (Test-Path $outputVideo) {
    $size = (Get-Item $outputVideo).Length
    Write-Host ""
    Write-Host "=== Demo video created ==="
    Write-Host "  File: $outputVideo"
    Write-Host "  Size: $([math]::Round($size/1024))KB"
    Write-Host "  Frames: $frameNum"
} else {
    Write-Host "ERROR: Video creation failed!"
}
