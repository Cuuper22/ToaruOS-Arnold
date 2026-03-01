# Contributing to ToaruOS-Arnold

Thank you for your interest in contributing to ToaruOS-Arnold! This document provides guidelines for setting up your development environment and contributing to the project.

## Build Prerequisites

### Required Tools

1. **NASM** (Netwide Assembler)
   - Windows: Download from https://www.nasm.us/pub/nasm/releasebuilds/
   - Add to PATH or set `$env:NASM` environment variable

2. **i686-elf cross-compiler toolchain**
   - Required: `i686-elf-ld` (linker) and `i686-elf-objcopy`
   - Windows: Pre-built binaries available at https://github.com/lordmilko/i686-elf-tools/releases
   - Set environment variables (optional):
     - `$env:I686_ELF_LD` - Path to i686-elf-ld.exe
     - `$env:I686_ELF_OBJCOPY` - Path to i686-elf-objcopy.exe

3. **ArnoldC-Native Compiler**
   - Repository: https://github.com/Cuuper22/ArnoldC-Native
   - Clone and build using sbt (Scala Build Tool)
   - Generates x86 NASM assembly from ArnoldC source
   - Set `$env:ARNOLDC_JAR` to path of compiled JAR (e.g., `target/scala-2.13/ArnoldC-Native.jar`)

4. **Java Runtime 17+**
   - Required to run ArnoldC-Native compiler (Scala-based)
   - Windows: Install from https://adoptium.net/
   - Ensure `java.exe` is in PATH

5. **QEMU** (optional, for testing)
   - Required for running the OS in a virtual machine
   - Windows: Download from https://www.qemu.org/download/#windows
   - Install qemu-system-i386.exe
   - Set `$env:QEMU` to installation path (optional)

### Quick Install (Windows with Scoop)

```powershell
# Install package manager
irm get.scoop.sh | iex

# Install tools
scoop install nasm
scoop bucket add java
scoop install temurin-lts-jdk
scoop install qemu

# Download i686-elf-tools manually from GitHub releases
# Clone and build ArnoldC-Native
git clone https://github.com/Cuuper22/ArnoldC-Native.git
cd ArnoldC-Native
sbt assembly
```

## Building the Kernel

### PowerShell Build Script (Recommended)

```powershell
# Build kernel (creates build/toaruos-arnold.elf)
.\build_v3.ps1

# Build and run in QEMU
.\build_v3.ps1 -Run

# Clean build artifacts
.\build_v3.ps1 -Clean
```

### Environment Variables

If tools are not in default locations, set these before building:

```powershell
$env:NASM = "C:\path\to\nasm.exe"
$env:I686_ELF_LD = "C:\path\to\i686-elf-ld.exe"
$env:I686_ELF_OBJCOPY = "C:\path\to\i686-elf-objcopy.exe"
$env:ARNOLDC_JAR = "C:\path\to\ArnoldC-Native.jar"
$env:QEMU = "C:\Program Files\qemu\qemu-system-i386.exe"
```

### Manual Build Steps

```powershell
# 1. Merge ArnoldC modules
.\tools\merge_modules.ps1 -SourceFiles @("kernel\*.arnoldc") -OutputFile build\gen\kernel.arnoldc

# 2. Compile ArnoldC to NASM assembly
cd build\gen
java -jar $env:ARNOLDC_JAR -asm kernel.arnoldc
cd ..\..

# 3. Assemble bootloader
nasm -f elf32 -w-other -o build\multiboot.o boot\multiboot.asm

# 4. Assemble kernel
nasm -f elf32 -o build\kernel.o build\gen\kernel.asm

# 5. Link
i686-elf-ld -m elf_i386 -T linker.ld -nostdlib -o build\toaruos-arnold.elf build\multiboot.o build\kernel.o

# 6. Create binary (optional)
i686-elf-objcopy -O binary build\toaruos-arnold.elf build\toaruos-arnold.bin
```

## Testing

### QEMU (Virtual Machine)

```powershell
# Basic run
& "C:\Program Files\qemu\qemu-system-i386.exe" -m 128M -vga std -kernel build\toaruos-arnold.elf

# With networking (for wget/ping commands)
& "C:\Program Files\qemu\qemu-system-i386.exe" -m 128M -vga std -kernel build\toaruos-arnold.elf `
  -netdev user,id=n1 -device e1000,netdev=n1

# With monitor console (for debugging)
& "C:\Program Files\qemu\qemu-system-i386.exe" -m 128M -vga std -kernel build\toaruos-arnold.elf `
  -monitor telnet:127.0.0.1:55555,server,nowait
```

### Bare Metal (Advanced)

1. Create bootable USB using Grub2
2. Copy `toaruos-arnold.elf` to `/boot/`
3. Add Grub entry:
   ```
   menuentry "ToaruOS-Arnold" {
       multiboot /boot/toaruos-arnold.elf
   }
   ```

## Contributing Code

### ArnoldC Style Guide

- Use descriptive variable names (e.g., `playerX`, `enemySpeed`, not `x`, `s`)
- Add comments for complex logic (standard ArnoldC comments not supported, use assembly comments in boot/)
- Test all code paths before submitting

### Module Organization

```
kernel/
  kernel_v3.arnoldc      - Main kernel (desktop, rendering, input loop)
  window_manager.arnoldc - Window system
  terminal.arnoldc       - Terminal emulator
  terminal_commands.arnoldc - Shell commands
  lib/                   - Shared libraries (random, timer, speaker)
  games/                 - Games (snake, pong, breakout, chopper, skynet, memory, tictactoe)
  apps/                  - Desktop apps (calculator, settings, text editor, etc.)
boot/
  multiboot.asm          - Bootloader, VBE setup, IRQs, network stack (x86 assembly)
```

### Adding a New Game

1. Create `kernel/games/mygame.arnoldc`
2. Add game module to `build_v3.ps1` `$sourceFiles` array
3. Add game launch function to `kernel/terminal_commands.arnoldc` (optional)
4. Test build and gameplay

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes and test thoroughly
4. Commit with descriptive messages
5. Push to your fork and create a Pull Request

## Known Issues & Limitations

- **No early return** - ArnoldC `I'LL BE BACK` doesn't exit functions, use flag-based control flow
- **Calculator arithmetic** - Left-to-right evaluation, not operator precedence
- **No negative numbers** - Unsigned 32-bit only, use clamp-before-subtract for animations
- **No function-local arrays** - Declare all arrays at module scope
- **Comparison operators** - `LET OFF SOME STEAM BENNET` is `>`, `YOU ARE NOT ME` is `!=`

## Resources

- **ArnoldC Language Spec** - https://github.com/lhartikk/ArnoldC/wiki/ArnoldC
- **ArnoldC-Native Compiler** - https://github.com/Cuuper22/ArnoldC-Native
- **Multiboot Specification** - https://www.gnu.org/software/grub/manual/multiboot/multiboot.html
- **OSDev Wiki** - https://wiki.osdev.org/

## Questions?

Open an issue on GitHub or contact the maintainer.

**"I'LL BE BACK"** with more features!
