# Build V2 with simple bootloader

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

# Compile V2 kernel
Write-Host "[ARN ] Compiling V2 kernel"
Copy-Item "$ProjectRoot\kernel\kernel_v2.arnoldc" "$GEN_DIR\kernel.arnoldc" -Force

Push-Location $GEN_DIR
& $JAVA -jar $ARNOLDC_JAR -asm "kernel.arnoldc"
Pop-Location

# Add externs
$asmContent = Get-Content "$GEN_DIR\kernel.asm" -Raw
$externs = @"

extern get_fb_addr
extern get_fb_pitch
extern get_fb_width
extern get_fb_height
"@
$asmContent = $asmContent -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN_DIR\kernel.asm" $asmContent -NoNewline

Write-Host "[ASM ] Assembling with simple bootloader"
& $NASM -f elf32 -o "$BUILD_DIR\multiboot.o" "$ProjectRoot\boot\multiboot_simple.asm"
& $NASM -f elf32 -o "$BUILD_DIR\kernel.o" "$GEN_DIR\kernel.asm"

Write-Host "[LD  ] Linking"
& $ELF_LD -m elf_i386 -T "$ProjectRoot\linker.ld" -nostdlib -o $KERNEL_ELF "$BUILD_DIR\multiboot.o" "$BUILD_DIR\kernel.o"

Write-Host "[DONE] Built $KERNEL_ELF"
