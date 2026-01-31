# Build and test ToaruOS-Arnold V3
# Captures serial output to verify boot stages

$ProjectRoot = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$NASM = "nasm"
$LD = "C:\Users\Acer\i686-elf-tools\bin\i686-elf-ld.exe"
$OBJCOPY = "C:\Users\Acer\i686-elf-tools\bin\i686-elf-objcopy.exe"
$JAVA = "java"
$ARNOLDC_JAR = "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"
$BUILD_DIR = "$ProjectRoot\build"
$GEN_DIR = "$BUILD_DIR\gen"
$SERIAL_LOG = "$BUILD_DIR\serial.log"
$SCREENSHOT = "$BUILD_DIR\screenshot.ppm"

# Kill any existing QEMU
Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force

# Create dirs
New-Item -ItemType Directory -Path $BUILD_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $GEN_DIR -Force | Out-Null

# Clean old artifacts
Remove-Item "$SERIAL_LOG" -ErrorAction SilentlyContinue
Remove-Item "$SCREENSHOT" -ErrorAction SilentlyContinue

Write-Host "=== STEP 1: Compile ArnoldC ==="
Copy-Item "$ProjectRoot\kernel\kernel_v3.arnoldc" "$GEN_DIR\kernel.arnoldc" -Force
Push-Location $GEN_DIR
& $JAVA -jar $ARNOLDC_JAR -asm "kernel.arnoldc" 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: ArnoldC"; Pop-Location; exit 1 }
Pop-Location

Write-Host "=== STEP 2: Add externs ==="
$asmContent = Get-Content "$GEN_DIR\kernel.asm" -Raw
$externs = @"

; External functions from bootloader
extern get_fb_addr
extern get_fb_pitch
extern get_fb_width
extern get_fb_height
extern get_timer_ticks
extern sleep_ticks
extern get_mouse_x
extern get_mouse_y
extern get_mouse_buttons
extern speaker_on
extern speaker_off
extern speaker_set_frequency
extern get_last_scancode
extern read_rtc_hours
extern read_rtc_minutes
extern read_rtc_seconds
extern halt_system
extern outb
extern inb
extern outw
extern inw
extern outl
extern inl

"@
$asmContent = $asmContent -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN_DIR\kernel.asm" $asmContent -NoNewline

Write-Host "=== STEP 3: Assemble bootloader ==="
& $NASM -f elf32 -o "$BUILD_DIR\multiboot.o" "$ProjectRoot\boot\multiboot.asm" 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: bootloader asm"; exit 1 }

Write-Host "=== STEP 4: Assemble kernel ==="
& $NASM -f elf32 -o "$BUILD_DIR\kernel.o" "$GEN_DIR\kernel.asm" 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: kernel asm"; exit 1 }

Write-Host "=== STEP 5: Link ==="
& $LD -m elf_i386 -T "$ProjectRoot\linker.ld" -nostdlib -o "$BUILD_DIR\toaruos-arnold.elf" "$BUILD_DIR\multiboot.o" "$BUILD_DIR\kernel.o" 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: link"; exit 1 }

& $OBJCOPY -O binary "$BUILD_DIR\toaruos-arnold.elf" "$BUILD_DIR\toaruos-arnold.bin" 2>&1 | Out-Host

$elfSize = (Get-Item "$BUILD_DIR\toaruos-arnold.elf").Length
Write-Host "=== BUILD OK: ELF $elfSize bytes ==="

Write-Host "=== STEP 6: Launch QEMU ==="
# Use -serial file to capture serial output, -display none + screendump via monitor
$qemuArgs = @(
    "-m", "128M",
    "-vga", "std",
    "-kernel", "$BUILD_DIR\toaruos-arnold.elf",
    "-serial", "file:$SERIAL_LOG",
    "-monitor", "stdio",
    "-display", "gtk"
)

Write-Host "QEMU args: $($qemuArgs -join ' ')"
Write-Host "Starting QEMU... (will screendump after 3 seconds)"

# Start QEMU as a background job
$proc = Start-Process -FilePath $QEMU -ArgumentList $qemuArgs -PassThru -NoNewWindow
Write-Host "QEMU PID: $($proc.Id)"

# Wait for boot
Start-Sleep -Seconds 4

# Check serial output
Write-Host ""
Write-Host "=== SERIAL OUTPUT ==="
if (Test-Path $SERIAL_LOG) {
    $serial = Get-Content $SERIAL_LOG -Raw
    if ($serial) {
        Write-Host $serial
    } else {
        Write-Host "(empty - kernel may not have booted)"
    }
} else {
    Write-Host "(no serial log file created)"
}

# Try screendump via telnet to monitor
# Actually we used -monitor stdio, so we'll use a separate approach
# Take screenshot via QEMU monitor pipe... skip for now, check serial

Write-Host ""
Write-Host "=== QEMU PROCESS ==="
if (-not $proc.HasExited) {
    Write-Host "QEMU still running (good - kernel didn't crash QEMU)"
} else {
    Write-Host "QEMU exited with code $($proc.ExitCode)"
    if ($proc.ExitCode -ne 0) {
        Write-Host "Check QEMU stderr for errors"
    }
}

Write-Host "Done. Check serial output above for boot markers: BOOT -> VBE -> FB -> GO"
