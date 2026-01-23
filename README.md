# ToaruOS-Arnold

**"COME WITH ME IF YOU WANT TO BOOT"**

A bare-metal OS kernel written entirely in ArnoldC - the most muscular programming language ever created. No C code, just pure Arnold Schwarzenegger movie quotes executing on real hardware.

![ToaruOS-Arnold Screenshot](screenshot.png)

## Features

- **Pure ArnoldC Kernel**: The entire kernel is written in ArnoldC, compiled to x86 assembly
- **1024x768 32-bit Graphics**: Full framebuffer graphics using Bochs VBE
- **Bitmap Font Rendering**: Custom 8x8 pixel font for text display
- **Keyboard Input**: Interactive keyboard handling with visual feedback
- **Terminator-themed UI**: Red "face" with eyes, mouth, and "I'LL BE BACK" message
- **Predator-style Corner Decorations**: Green targeting brackets

## Building

### Requirements

- ArnoldC-Native compiler (companion project)
- NASM assembler
- i686-elf cross-compiler toolchain
- QEMU for testing

### Build Commands

```bash
# Set up PATH
export PATH="/path/to/i686-elf-tools/bin:$PATH"

# Build the kernel
make

# Run in QEMU
make run
```

### Windows (PowerShell)

```powershell
# Run the build script
.\build.ps1
```

## Running

```bash
qemu-system-i386 -accel tcg,tb-size=64 -m 32M -vga std -kernel build/toaruos-arnold.elf
```

## Keyboard Controls

- **A**: Set status indicator to GREEN
- **B**: Set status indicator to RED  
- **C**: Set status indicator to BLUE
- **ESC**: Set status indicator to WHITE
- **Any other key**: Set status indicator to SILVER

## Architecture

```
boot/
  multiboot.asm     - Multiboot bootloader with Bochs VBE setup
kernel/
  kernel.arnoldc    - Main kernel written in ArnoldC
lib/
  arnold_kernel_runtime.h  - (unused, kernel is pure ArnoldC)
linker.ld           - Linker script for kernel layout
```

## ArnoldC Syntax Highlights

```arnoldc
IT'S SHOWTIME                              ; main() function start
TALK TO YOURSELF "Hello World"             ; Comment
HEY CHRISTMAS TREE myVar                   ; Variable declaration
YOU SET US UP 42                           ; Initial value
GET TO THE CHOPPER myVar                   ; Begin assignment
HERE IS MY INVITATION 10                   ; Load value
GET UP 5                                   ; Add
ENOUGH TALK                                ; End assignment
HASTA LA VISTA, BABY                       ; Return
YOU HAVE BEEN TERMINATED                   ; End main
```

## Demo Video

See `demo.mp4` for a demonstration of the kernel running with keyboard interaction.

## Credits

- **ArnoldC Language**: Created by Lauri Hartikka
- **ArnoldC-Native**: Custom compiler fork that generates x86 assembly
- **ToaruOS**: Inspiration for the OS structure

## License

MIT License - "I'LL BE BACK" to add more features!

---

*"CONSIDER THAT A DIVORCE from boring operating systems!"*
