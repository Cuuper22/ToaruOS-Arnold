# ToaruOS-Arnold Flat Binary Build Script
# Creates a single multiboot-compliant binary without needing ELF linker

param(
    [switch]$Run,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Tool paths
$NASM = "nasm"
$JAVA = "java"
$ARNOLDC_JAR = "$ProjectRoot\..\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar"
$QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"

# Directories
$BUILD_DIR = "$ProjectRoot\build"
$GEN_DIR = "$BUILD_DIR\gen"

# Output
$KERNEL_ELF = "$BUILD_DIR\toaruos-arnold.elf"

if ($Clean) {
    Write-Host "[CLEAN] Removing build artifacts"
    Remove-Item -Path $BUILD_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 0
}

# Create directories
Write-Host "[INIT] Creating directories"
New-Item -ItemType Directory -Path $BUILD_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $GEN_DIR -Force | Out-Null

# Copy and compile ArnoldC kernel
Write-Host "[ARN ] Compiling ArnoldC kernel to assembly"
Copy-Item "$ProjectRoot\kernel\kernel_v3.arnoldc" "$GEN_DIR\kernel.arnoldc" -Force

Push-Location $GEN_DIR
try {
    & $JAVA -jar $ARNOLDC_JAR -asm "kernel.arnoldc"
    if ($LASTEXITCODE -ne 0) {
        throw "ArnoldC compilation failed!"
    }
} finally {
    Pop-Location
}

# Create combined assembly file with multiboot header
Write-Host "[ASM ] Creating combined multiboot assembly"

$multibootAsm = Get-Content "$ProjectRoot\boot\multiboot.asm" -Raw
$kernelAsm = Get-Content "$GEN_DIR\kernel.asm" -Raw

# Modify kernel.asm to:
# 1. Remove its own section declarations (we'll use multiboot.asm's)
# 2. Add extern declarations for bootloader functions

# Add externs after section .text in the kernel
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

# Insert externs into kernel
$kernelAsm = $kernelAsm -replace "(section \.text)", "`$1`n$externs"

# Write back modified kernel.asm
Set-Content "$GEN_DIR\kernel.asm" $kernelAsm -NoNewline

# Assemble both files to ELF objects
Write-Host "[ASM ] Assembling bootloader"
& $NASM -f elf32 -o "$BUILD_DIR\multiboot.o" "$ProjectRoot\boot\multiboot.asm"
if ($LASTEXITCODE -ne 0) { throw "Bootloader assembly failed!" }

Write-Host "[ASM ] Assembling kernel"
& $NASM -f elf32 -o "$BUILD_DIR\kernel.o" "$GEN_DIR\kernel.asm"
if ($LASTEXITCODE -ne 0) { throw "Kernel assembly failed!" }

# Try to use WSL's ld for linking
Write-Host "[LD  ] Attempting to link with WSL"

# Convert Windows paths to WSL paths
$wslBuildDir = $BUILD_DIR -replace '\\', '/' -replace 'C:', '/mnt/c'
$wslProjectRoot = $ProjectRoot -replace '\\', '/' -replace 'C:', '/mnt/c'

# Check if we can install ld in WSL
$wslResult = wsl sh -c "which ld 2>/dev/null || (apk add --no-cache binutils 2>/dev/null && which ld)"
if ($wslResult) {
    Write-Host "[LD  ] Found WSL linker: $wslResult"
    
    # Link using WSL
    wsl sh -c "cd '$wslBuildDir' && ld -m elf_i386 -T '$wslProjectRoot/linker.ld' -nostdlib -o toaruos-arnold.elf multiboot.o kernel.o"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "============================================================================"
        Write-Host "  BUILD COMPLETE - I'LL BE BACK"
        Write-Host "============================================================================"
        Write-Host "  Kernel ELF: $KERNEL_ELF"
        Write-Host ""
        
        if ($Run) {
            Write-Host "[QEMU] Launching"
            & $QEMU -m 128M -vga std -kernel $KERNEL_ELF -monitor telnet:127.0.0.1:55555,server,nowait
        }
        exit 0
    }
}

Write-Host "[WARN] WSL linking failed. Trying alternative..."

# If WSL failed, try downloading i686-elf-ld
$toolsZip = "$env:TEMP\i686-elf-tools.zip"
$toolsDir = "$env:LOCALAPPDATA\i686-elf-tools"

if (-not (Test-Path "$toolsDir\bin\i686-elf-ld.exe")) {
    Write-Host "[INFO] Downloading i686-elf-tools..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri "https://github.com/lordmilko/i686-elf-tools/releases/download/7.1.0/i686-elf-tools-windows.zip" -OutFile $toolsZip -TimeoutSec 120
        Expand-Archive -Path $toolsZip -DestinationPath $toolsDir -Force
        Write-Host "[INFO] i686-elf-tools installed to $toolsDir"
    } catch {
        Write-Host "[ERROR] Failed to download cross-compiler tools: $_"
        Write-Host "[INFO] Manual installation:"
        Write-Host "  1. Download from: https://github.com/lordmilko/i686-elf-tools/releases"
        Write-Host "  2. Extract to: $toolsDir"
        throw "Missing i686-elf-ld"
    }
}

$ELF_LD = "$toolsDir\bin\i686-elf-ld.exe"
$ELF_OBJCOPY = "$toolsDir\bin\i686-elf-objcopy.exe"

if (Test-Path $ELF_LD) {
    Write-Host "[LD  ] Using i686-elf-ld"
    & $ELF_LD -m elf_i386 -T "$ProjectRoot\linker.ld" -nostdlib -o $KERNEL_ELF "$BUILD_DIR\multiboot.o" "$BUILD_DIR\kernel.o"
    if ($LASTEXITCODE -ne 0) { throw "Linking failed!" }
    
    Write-Host ""
    Write-Host "============================================================================"
    Write-Host "  BUILD COMPLETE"
    Write-Host "============================================================================"
    
    if ($Run) {
        & $QEMU -m 128M -vga std -kernel $KERNEL_ELF -monitor telnet:127.0.0.1:55555,server,nowait
    }
} else {
    throw "No suitable linker found. Please install i686-elf-tools or use WSL with binutils."
}
