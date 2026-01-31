# ToaruOS-Arnold v4.0

**"COME WITH ME IF YOU WANT TO BOOT"**

A complete desktop operating system written entirely in ArnoldC — the programming language where every keyword is an Arnold Schwarzenegger movie quote. No C. No Rust. Just pure Arnold running on bare metal x86.

## What Is This?

This is a real, bootable operating system kernel that provides:

- 🖥️ **Full desktop GUI** with menu bar, taskbar, and desktop icons
- 🪟 **Window manager** with overlapping windows, drag, z-ordering, and focus
- 🎮 **5 playable games** (Snake, Pong, Breakout, Chopper, Skynet Defense)
- 📟 **Terminal emulator** with keyboard input and command prompt
- 🧮 **Calculator app** with button grid UI
- ℹ️ **About dialog** with T-800 skull icon

All written in ~2000 lines of ArnoldC, compiled to x86 assembly, running directly on hardware (or QEMU).

## Screenshots

### Desktop
The main desktop with teal background, application icons, menu bar, and ARNOLD taskbar button.

### Window Manager
Multiple overlapping windows with blue (active) and gray (inactive) title bars, red close buttons, and numbered taskbar buttons.

### Games
- **Snake** — Classic snake on a navy grid (key: 2)
- **Pong** — Two-paddle pong (key: 3)
- **Breakout** — Rainbow brick rows with paddle and ball (key: 4)
- **Chopper** — "GET TO THE CHOPPER!" jungle obstacle game (key: 5)
- **Skynet Defense** — Turret defense with projectiles (key: 6)

### Terminal
Green-on-black terminal with `ARNOLD-OS>` prompt, full a-z/0-9 keyboard mapping (key: 1)

### Calculator
4×4 button grid: gray number buttons, orange operators, blue equals, green LED display (key: 7)

### About
Dialog with T-800 pixel art skull, version info, "I'll be back." quote (key: 8)

## Building

### Requirements

- **ArnoldC-Native compiler** — Custom fork that generates x86 NASM assembly
- **NASM** — Netwide Assembler
- **i686-elf toolchain** — Cross-compiler linker (`i686-elf-ld`)
- **Java 17+** — For ArnoldC-Native (Scala-based)
- **QEMU** — For testing (`qemu-system-i386`)
- **PowerShell** — Build scripts are Windows PowerShell

### Quick Build (Windows)

```powershell
# Build everything (merge modules → compile → assemble → link)
.\build_v3.ps1

# Run in QEMU
& "C:\Program Files\qemu\qemu-system-i386.exe" -m 128M -vga std -kernel build\toaruos-arnold.elf
```

### Build Pipeline

```
ArnoldC source files (.arnoldc)
    ↓ merge_modules.ps1 (merge + dedup)
Single merged kernel.arnoldc
    ↓ ArnoldC-Native compiler
x86 NASM assembly (kernel.asm)
    ↓ NASM assembler
ELF object (kernel.o)
    ↓ i686-elf-ld linker
Bootable ELF kernel (toaruos-arnold.elf)
```

## Keyboard Controls

| Key | Action |
|-----|--------|
| 1 | Launch Terminal |
| 2 | Launch Snake |
| 3 | Launch Pong |
| 4 | Launch Breakout |
| 5 | Launch Chopper |
| 6 | Launch Skynet Defense |
| 7 | Launch Calculator |
| 8 | About Dialog |
| W | Open new window |
| ESC | Return to desktop |

## Architecture

```
boot/
  multiboot.asm          — Multiboot bootloader, VBE 1024×768×32, IRQs, mouse, PIT
kernel/
  kernel_v3.arnoldc      — Main kernel: desktop, input loop, rendering, font
  window_manager.arnoldc — Window system: create/close/drag/z-order/taskbar
  terminal.arnoldc       — Terminal emulator: 80×25 buffer, scancode mapping
  lib/
    random.arnoldc       — PRNG (timer-seeded)
    timer.arnoldc        — PIT timer access
    speaker.arnoldc      — PC speaker (stub)
  games/
    snake.arnoldc        — Snake game
    pong.arnoldc         — Pong game
    breakout.arnoldc     — Breakout with rainbow bricks
    chopper.arnoldc      — Helicopter obstacle game
    skynet.arnoldc       — Turret defense game
    memory.arnoldc       — Memory card game (WIP)
    tictactoe.arnoldc    — Tic-tac-toe (WIP)
  apps/
    calculator.arnoldc   — Calculator with 4×4 button grid
    about.arnoldc        — About dialog with T-800 icon
linker.ld                — Kernel memory layout
tools/
  merge_modules.ps1      — Module merger with dedup
  test_*.ps1             — Automated QEMU test scripts
```

## Technical Details

- **Language:** 100% ArnoldC (compiled to x86 assembly)
- **Graphics:** Bochs VBE, 1024×768, 32-bit color, linear framebuffer
- **Input:** PS/2 keyboard (IRQ1 + scancode ISR), PS/2 mouse (IRQ12)
- **Font:** Custom 8×8 bitmap, full ASCII 32-126
- **ELF Size:** ~106 KB
- **Functions:** 130
- **Boot time:** < 1 second to desktop

### ArnoldC Challenges

Writing an OS in ArnoldC required creative solutions:

- **No early return** — `I'LL BE BACK` sets a value but doesn't exit. Used flag-based patterns instead.
- **Calculator arithmetic** — ArnoldC evaluates left-to-right like a calculator: `a * b + c * d` becomes `((a*b)+c)*d`. Must restructure expressions.
- **No string operations** — Every text string is drawn character-by-character with ASCII codes.
- **Performance** — `fillRect` calls `putPixel` per pixel. Full-screen redraws at 1024×768 = 786K calls. Used dirty-rect rendering (init once, update diffs).

## ArnoldC Syntax Quick Reference

```arnoldc
IT'S SHOWTIME                              ; main()
HEY CHRISTMAS TREE x                      ; declare variable
YOU SET US UP 42                           ; initialize
GET TO THE CHOPPER x                       ; begin assignment
HERE IS MY INVITATION 10                   ; load 10
GET UP 5                                   ; + 5
ENOUGH TALK                                ; end assignment
BECAUSE I'M GOING TO SAY PLEASE condition  ; if
BULLSHIT                                   ; else
YOU HAVE NO RESPECT FOR LOGIC              ; endif
STICK AROUND condition                     ; while
CHILL                                      ; endwhile
LISTEN TO ME VERY CAREFULLY funcName       ; function
I NEED YOUR CLOTHES YOUR BOOTS AND YOUR MOTORCYCLE param  ; parameter
I'LL BE BACK value                         ; return value
HASTA LA VISTA, BABY                       ; end function
DO IT NOW funcName arg1 arg2               ; call function
YOU HAVE BEEN TERMINATED                   ; end main
```

## Credits

- **ArnoldC Language** — Created by Lauri Hartikka
- **ArnoldC-Native** — Custom compiler generating x86 assembly
- **Inspired by** — ToaruOS, Windows 95, and every Arnold movie ever made

## License

MIT License

---

*"CONSIDER THAT A DIVORCE from boring operating systems!"*

*"TALK TO THE HAND if you think this can't be done in ArnoldC."*

*"I'LL BE BACK... with more features."*
