# ToaruOS-Arnold V3 Build Script (Windows Native)
# "DO IT NOW" - The build system

param(
    [switch]$Run,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Tool paths
$NASM = "nasm"
$LD = "ld"
$OBJCOPY = "objcopy"
$JAVA = "java"
$ARNOLDC_JAR = "$ProjectRoot\..\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

# Directories
$BUILD_DIR = "$ProjectRoot\build"
$GEN_DIR = "$BUILD_DIR\gen"

# Source files
$BOOT_ASM = "$ProjectRoot\boot\multiboot.asm"
$KERNEL_SRC = "$ProjectRoot\kernel\kernel_v3.arnoldc"

# Output files
$KERNEL_ELF = "$BUILD_DIR\toaruos-arnold.elf"
$KERNEL_BIN = "$BUILD_DIR\toaruos-arnold.bin"

if ($Clean) {
    Write-Host "[CLEAN] Removing build artifacts - YOU'RE LUGGAGE"
    Remove-Item -Path $BUILD_DIR -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "ERASED FROM EXISTENCE"
    exit 0
}

# Create directories
Write-Host "[INIT] Creating directories - I NEED YOUR MEMORY"
New-Item -ItemType Directory -Path $BUILD_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $GEN_DIR -Force | Out-Null

# Copy kernel source
Write-Host "[ARN ] Copying kernel source - I'LL BE BACK"
Copy-Item $KERNEL_SRC "$GEN_DIR\kernel.arnoldc" -Force

# Compile ArnoldC to ASM
Write-Host "[ARN ] Compiling ArnoldC - IT'S SHOWTIME"
Push-Location $GEN_DIR
try {
    & $JAVA -jar $ARNOLDC_JAR -asm "kernel.arnoldc"
    if ($LASTEXITCODE -ne 0) {
        throw "ArnoldC compilation failed!"
    }
} finally {
    Pop-Location
}

# Add extern declarations for bootloader functions
Write-Host "[ARN ] Adding extern declarations for V3 kernel"
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

"@
# Insert externs after "section .text"
$asmContent = $asmContent -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN_DIR\kernel.asm" $asmContent -NoNewline

# Assemble bootloader
Write-Host "[ASM ] Assembling bootloader - LISTEN TO ME VERY CAREFULLY"
& $NASM -f elf32 -o "$BUILD_DIR\multiboot.o" $BOOT_ASM
if ($LASTEXITCODE -ne 0) {
    throw "Bootloader assembly failed!"
}

# Assemble kernel
Write-Host "[ASM ] Assembling kernel - THE TERMINATOR AWAKENS"
& $NASM -f elf32 -o "$BUILD_DIR\kernel.o" "$GEN_DIR\kernel.asm"
if ($LASTEXITCODE -ne 0) {
    throw "Kernel assembly failed!"
}

# Link
Write-Host "[LD  ] Linking kernel - GET TO THE CHOPPER"
& $LD -m elf_i386 -T "$ProjectRoot\linker.ld" -nostdlib -o $KERNEL_ELF "$BUILD_DIR\multiboot.o" "$BUILD_DIR\kernel.o"
if ($LASTEXITCODE -ne 0) {
    throw "Linking failed!"
}

# Create binary
Write-Host "[BIN ] Creating binary - CONSIDER THAT A DIVORCE from ELF"
& $OBJCOPY -O binary $KERNEL_ELF $KERNEL_BIN
if ($LASTEXITCODE -ne 0) {
    throw "Binary creation failed!"
}

Write-Host ""
Write-Host "============================================================================"
Write-Host "  BUILD COMPLETE - I'LL BE BACK"
Write-Host "============================================================================"
Write-Host "  Kernel ELF: $KERNEL_ELF"
Write-Host "  Kernel BIN: $KERNEL_BIN"
$size = (Get-Item $KERNEL_BIN).Length
Write-Host "  Size: $size bytes"
Write-Host ""

if ($Run) {
    Write-Host "[QEMU] Launching - GET YOUR ASS TO MARS"
    & $QEMU -m 128M -vga std -kernel $KERNEL_ELF -monitor telnet:127.0.0.1:55555,server,nowait
}
