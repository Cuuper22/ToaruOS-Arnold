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
$LD = "C:\Users\Acer\i686-elf-tools\bin\i686-elf-ld.exe"
$OBJCOPY = "C:\Users\Acer\i686-elf-tools\bin\i686-elf-objcopy.exe"
$JAVA = "java"
$ARNOLDC_JAR = "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar"
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

# Build modular kernel using merge_modules.ps1
Write-Host "[ARN ] Building modular kernel - I'LL BE BACK"

# Source files in merge order (kernel core + libraries + games)
# kernel_v3 must be LAST since it has the main function
$sourceFiles = @(
    "$ProjectRoot\kernel\kernel_v3.arnoldc",
    "$ProjectRoot\kernel\lib\random.arnoldc",
    "$ProjectRoot\kernel\lib\timer.arnoldc",
    "$ProjectRoot\kernel\lib\speaker.arnoldc",
    "$ProjectRoot\kernel\games\snake.arnoldc",
    "$ProjectRoot\kernel\games\pong.arnoldc",
    "$ProjectRoot\kernel\games\breakout.arnoldc",
    "$ProjectRoot\kernel\games\chopper.arnoldc",
    "$ProjectRoot\kernel\games\memory.arnoldc",
    "$ProjectRoot\kernel\games\skynet.arnoldc",
    "$ProjectRoot\kernel\games\tictactoe.arnoldc",
    "$ProjectRoot\kernel\window_manager.arnoldc",
    "$ProjectRoot\kernel\terminal.arnoldc",
    "$ProjectRoot\kernel\terminal_commands.arnoldc",
    "$ProjectRoot\kernel\apps\calculator.arnoldc",
    "$ProjectRoot\kernel\apps\about.arnoldc",
    "$ProjectRoot\kernel\apps\settings.arnoldc",
    "$ProjectRoot\kernel\apps\text_editor.arnoldc",
    "$ProjectRoot\kernel\apps\file_manager.arnoldc"
)

& powershell -ExecutionPolicy Bypass -File "$ProjectRoot\tools\merge_modules.ps1" `
    -SourceFiles $sourceFiles `
    -OutputFile "$GEN_DIR\kernel.arnoldc"
if ($LASTEXITCODE -ne 0) { throw "Module merge failed!" }

# Compile ArnoldC to ASM (delete stale ASM first to prevent using cached build on failure)
Write-Host "[ARN ] Compiling ArnoldC - IT'S SHOWTIME"
Remove-Item "$GEN_DIR\kernel.asm" -ErrorAction SilentlyContinue
Push-Location $GEN_DIR
try {
    & $JAVA -jar $ARNOLDC_JAR -asm "kernel.arnoldc"
    if (-not (Test-Path "kernel.asm")) {
        throw "ArnoldC compilation failed - no kernel.asm generated!"
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
extern fast_fill_rect
extern fast_memcpy32
extern pci_config_read
extern pci_config_write
extern pci_find_device
extern e1000_init
extern e1000_send_packet
extern e1000_receive_packet
extern e1000_get_mac
extern e1000_is_link_up
extern net_ping_gateway
extern net_get_ip_byte
extern net_get_gateway_byte
extern net_get_mac_byte
extern net_is_available
extern net_tcp_connect
extern net_tcp_send
extern net_tcp_recv
extern net_tcp_close
extern net_http_get
extern net_wget
extern net_wget_get_byte
extern net_wget_get_len

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
