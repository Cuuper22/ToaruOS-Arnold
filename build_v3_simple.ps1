# Build V3 with simple bootloader

$ErrorActionPreference = "Stop"
$ProjectRoot = "C:\Users\Acer\Desktop\ToaruOS-Arnold"

$NASM = "nasm"
$JAVA = "java"
$ARNOLDC_JAR = "C:\Users\Acer\Desktop\ArnoldC-Native\target\scala-2.13\ArnoldC-Native.jar"
$ELF_LD = "C:\Users\Acer\AppData\Local\i686-elf-tools\bin\i686-elf-ld.exe"

$BUILD_DIR = "$ProjectRoot\build"
$GEN_DIR = "$BUILD_DIR\gen"
$KERNEL_ELF = "$BUILD_DIR\toaruos-arnold.elf"

New-Item -ItemType Directory -Path $GEN_DIR -Force | Out-Null

# Compile V3 kernel
Write-Host "[ARN ] Compiling V3 kernel"
Copy-Item "$ProjectRoot\kernel\kernel_v3.arnoldc" "$GEN_DIR\kernel.arnoldc" -Force

Push-Location $GEN_DIR
& $JAVA -jar $ARNOLDC_JAR -asm "kernel.arnoldc"
Pop-Location

# Add externs (V3 uses more functions, but simple bootloader only provides fb_* functions)
# V3 calls get_mouse_x/y/buttons which won't exist - we need stubs or it will crash
$asmContent = Get-Content "$GEN_DIR\kernel.asm" -Raw
$externs = @"

extern get_fb_addr
extern get_fb_pitch
extern get_fb_width
extern get_fb_height
; Note: Timer and mouse functions don't exist in simple bootloader
; These will be stubbed in the bootloader
extern get_timer_ticks
extern sleep_ticks
extern get_mouse_x
extern get_mouse_y
extern get_mouse_buttons
extern speaker_on
extern speaker_off
extern speaker_set_frequency
"@
$asmContent = $asmContent -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN_DIR\kernel.asm" $asmContent -NoNewline

# Need to add stubs to the bootloader
$bootStubs = @"

; Timer stubs (return 0/do nothing)
global get_timer_ticks
global sleep_ticks
get_timer_ticks:
    xor eax, eax
    ret
sleep_ticks:
    ret

; Mouse stubs (return center of screen / no buttons)
global get_mouse_x
global get_mouse_y
global get_mouse_buttons
get_mouse_x:
    mov eax, 512
    ret
get_mouse_y:
    mov eax, 384
    ret
get_mouse_buttons:
    xor eax, eax
    ret

; Speaker stubs (do nothing)
global speaker_on
global speaker_off
global speaker_set_frequency
speaker_on:
speaker_off:
speaker_set_frequency:
    ret
"@

# Read the simple bootloader and add stubs
$bootContent = Get-Content "$ProjectRoot\boot\multiboot_simple.asm" -Raw
# Add stubs before the final comment
$bootContent = $bootContent -replace "; ============================================================================`r?`n; `"HASTA LA VISTA", "$bootStubs`n`n; ============================================================================`n; `"HASTA LA VISTA"
Set-Content "$BUILD_DIR\multiboot_v3.asm" $bootContent -NoNewline

Write-Host "[ASM ] Assembling with stubbed bootloader"
& $NASM -f elf32 -o "$BUILD_DIR\multiboot.o" "$BUILD_DIR\multiboot_v3.asm"
& $NASM -f elf32 -o "$BUILD_DIR\kernel.o" "$GEN_DIR\kernel.asm"

Write-Host "[LD  ] Linking"
& $ELF_LD -m elf_i386 -T "$ProjectRoot\linker.ld" -nostdlib -o $KERNEL_ELF "$BUILD_DIR\multiboot.o" "$BUILD_DIR\kernel.o"

Write-Host "[DONE] Built $KERNEL_ELF"
