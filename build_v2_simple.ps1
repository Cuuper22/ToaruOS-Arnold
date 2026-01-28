# Build V2 with simple bootloader + game integration

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

# Concatenate kernel + lib + game files
Write-Host "[CAT ] Concatenating kernel with libraries and games"

$kernelContent = Get-Content "$ProjectRoot\kernel\kernel_v2.arnoldc" -Raw

# We need TWO split points:
# 1. Before first function definition - insert declarations (constants + global vars)
# 2. Before main block - insert function definitions

# Find the first function marker - search for the separator line before putPixel
$funcSearchLine = 'TALK TO YOURSELF "  FUNCTION: putPixel"'
$funcLineIndex = $kernelContent.IndexOf($funcSearchLine)

if ($funcLineIndex -lt 0) {
    Write-Error "Could not find first FUNCTION marker (putPixel) in kernel_v2.arnoldc"
    exit 1
}

# Back up to include the separator line above it
$funcIndex = $kernelContent.LastIndexOf("`n", $funcLineIndex)
if ($funcIndex -lt 0) { $funcIndex = 0 } else { $funcIndex += 1 }
# Back up one more line for the "====" separator
$funcIndex2 = $kernelContent.LastIndexOf("`n", $funcIndex - 2)
if ($funcIndex2 -ge 0) { $funcIndex = $funcIndex2 + 1 }

# Find the main function marker
$mainMarker = "TALK TO YOURSELF `"  MAIN FUNCTION - IT'S SHOWTIME`""
$mainIndex = $kernelContent.IndexOf($mainMarker)

if ($mainIndex -lt 0) {
    Write-Error "Could not find MAIN FUNCTION marker in kernel_v2.arnoldc"
    exit 1
}

$kernelDecls = $kernelContent.Substring(0, $funcIndex)
$kernelFuncs = $kernelContent.Substring($funcIndex, $mainIndex - $funcIndex)
$kernelMain  = $kernelContent.Substring($mainIndex)

# Helper: split an arnoldc file into declarations (constants + global vars) and functions
# Declarations = lines that are LET ME TELL YOU SOMETHING, HEY CHRISTMAS TREE, THIS IS A WARRIOR,
#                YOU SET US UP, or TALK TO YOURSELF (comments) BEFORE the first LISTEN TO ME VERY CAREFULLY
# Functions = everything from first LISTEN TO ME VERY CAREFULLY onward
function Split-ArnoldcFile {
    param([string]$content)

    $lines = $content -split "`n"
    $declLines = @()
    $funcLines = @()
    $inFunctions = $false

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if (-not $inFunctions -and $trimmed -match '^LISTEN TO ME VERY CAREFULLY') {
            $inFunctions = $true
            # Include the comment block just before (last few TALK TO YOURSELF lines)
        }

        if ($inFunctions) {
            $funcLines += $line
        } else {
            $declLines += $line
        }
    }

    return @{
        Decls = ($declLines -join "`n")
        Funcs = ($funcLines -join "`n")
    }
}

# Library files to include (order matters: random before games since games use random)
$libFiles = @(
    "$ProjectRoot\kernel\lib\random.arnoldc"
)

# Game files
$gameFiles = @(
    "$ProjectRoot\kernel\games\snake.arnoldc",
    "$ProjectRoot\kernel\games\pong.arnoldc",
    "$ProjectRoot\kernel\games\breakout.arnoldc",
    "$ProjectRoot\kernel\games\memory.arnoldc",
    "$ProjectRoot\kernel\games\tictactoe.arnoldc",
    "$ProjectRoot\kernel\games\chopper.arnoldc",
    "$ProjectRoot\kernel\games\skynet.arnoldc"
)

$allDecls = ""
$allFuncs = ""

$allFiles = $libFiles + $gameFiles
foreach ($file in $allFiles) {
    $name = [System.IO.Path]::GetFileName($file)
    $dir = if ($libFiles -contains $file) { "lib" } else { "games" }
    Write-Host "       + $dir/$name"
    $fileContent = Get-Content $file -Raw
    $parts = Split-ArnoldcFile $fileContent
    $allDecls += "`n" + $parts.Decls + "`n"
    $allFuncs += "`n" + $parts.Funcs + "`n"
}

# Assemble: kernel declarations + lib/game declarations + kernel functions + lib/game functions + main
$combined = $kernelDecls + $allDecls + "`n" + $kernelFuncs + $allFuncs + "`n" + $kernelMain

Set-Content "$GEN_DIR\kernel.arnoldc" $combined -NoNewline

Write-Host "[ARN ] Compiling combined kernel"

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
extern get_timer_ticks
extern sleep_ticks
extern speaker_on
extern speaker_off
extern speaker_set_frequency
extern get_last_scancode
extern inb
extern outb
extern read_rtc_hours
extern read_rtc_minutes
extern read_rtc_seconds
extern halt_system
"@
$asmContent = $asmContent -replace "(section \.text)", "`$1`n$externs"
Set-Content "$GEN_DIR\kernel.asm" $asmContent -NoNewline

Write-Host "[ASM ] Assembling with simple bootloader"
& $NASM -f elf32 -o "$BUILD_DIR\multiboot.o" "$ProjectRoot\boot\multiboot_simple.asm"
& $NASM -f elf32 -o "$BUILD_DIR\kernel.o" "$GEN_DIR\kernel.asm"

Write-Host "[LD  ] Linking"
& $ELF_LD -m elf_i386 -T "$ProjectRoot\linker.ld" -nostdlib -o $KERNEL_ELF "$BUILD_DIR\multiboot.o" "$BUILD_DIR\kernel.o"

Write-Host "[DONE] Built $KERNEL_ELF"
