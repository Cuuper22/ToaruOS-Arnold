# Quick build + serial test
$ProjectRoot = "C:\Users\Acer\Desktop\ToaruOS-Arnold"
$BUILD_DIR = "$ProjectRoot\build"
$GEN_DIR = "$BUILD_DIR\gen"
$SERIAL_LOG = "$BUILD_DIR\serial.log"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

# Kill old QEMU
Get-Process -Name "qemu-system-i386" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
Remove-Item $SERIAL_LOG -ErrorAction SilentlyContinue

# Step 1: ArnoldC
Copy-Item "$ProjectRoot\kernel\kernel_v3.arnoldc" "$GEN_DIR\kernel.arnoldc" -Force
Push-Location $GEN_DIR
java -jar "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar" -asm "kernel.arnoldc" 2>$null
Pop-Location

# Step 2: Add externs
$asm = Get-Content "$GEN_DIR\kernel.asm" -Raw
$externs = @"

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
$asm = $asm -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN_DIR\kernel.asm" $asm -NoNewline

# Step 3: Assemble
nasm -f elf32 -o "$BUILD_DIR\multiboot.o" "$ProjectRoot\boot\multiboot.asm" 2>$null
nasm -f elf32 -o "$BUILD_DIR\kernel.o" "$GEN_DIR\kernel.asm" 2>$null

# Step 4: Link
& "C:\Users\Acer\i686-elf-tools\bin\i686-elf-ld.exe" -m elf_i386 -T "$ProjectRoot\linker.ld" -nostdlib -o "$BUILD_DIR\toaruos-arnold.elf" "$BUILD_DIR\multiboot.o" "$BUILD_DIR\kernel.o" 2>$null

$sz = (Get-Item "$BUILD_DIR\toaruos-arnold.elf").Length
Write-Host "ELF: $sz bytes"

# Step 5: QEMU with serial + no display (headless)
$proc = Start-Process -FilePath $QEMU -ArgumentList @(
    "-m", "128M", "-vga", "std",
    "-kernel", "$BUILD_DIR\toaruos-arnold.elf",
    "-serial", "file:$SERIAL_LOG",
    "-display", "none",
    "-no-reboot"
) -PassThru

# Wait for boot
Start-Sleep -Seconds 3

# Read serial
Write-Host "=== SERIAL ==="
if (Test-Path $SERIAL_LOG) {
    Get-Content $SERIAL_LOG -Raw
} else {
    Write-Host "(no log)"
}

# Cleanup
if (-not $proc.HasExited) {
    $proc.Kill()
    Write-Host "QEMU killed (was still running)"
} else {
    Write-Host "QEMU exited: $($proc.ExitCode)"
}
