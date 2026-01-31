# ToaruOS-Arnold v4.0

**"COME WITH ME IF YOU WANT TO BOOT"**

A complete desktop operating system written entirely in ArnoldC — the programming language where every keyword is an Arnold Schwarzenegger movie quote. No C. No Rust. Just pure Arnold running on bare metal x86.

## What Is This?

This is a real, bootable operating system kernel that provides:

- 🚀 **Animated boot splash** with 3x scaled title, loading bar, and Arnold quotes
- 🖥️ **Full desktop GUI** with menu bar, taskbar with RTC clock, and 8 clickable icons
- 🪟 **Window manager** with overlapping windows, drag, z-ordering, and focus
- 🎮 **5 playable games** (Snake, Pong, Breakout, Chopper, Skynet Defense)
- 📟 **Terminal emulator** with keyboard input, command prompt, and 10+ commands
- 🧮 **Calculator app** with button grid UI
- 📝 **Text editor** with full keyboard input, enter, backspace, cursor blink
- 🎨 **Settings app** with 5 Arnold movie color themes (runtime theming)
- 📁 **File manager** with virtual filesystem navigation
- ℹ️ **About dialog** with T-800 skull pixel art
- 🎬 **DVD bouncing screensaver** — "I'LL BE BACK" bounces around after 30s idle, cycling through 5 Arnold movie colors on each wall hit
- 🌐 **Full network stack** — E1000 NIC driver, ARP, ICMP ping, TCP, HTTP client
- 🔗 **wget command** — Fetches real webpages over TCP/HTTP and displays them in the terminal
- ⚡ **Native fast rendering** — `rep stosd` assembly for ~100x fillRect speedup

All written in ~5500 lines of ArnoldC + x86 assembly across 19+ modules, compiled and running directly on hardware (or QEMU).

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

### Settings
5 Arnold movie color themes: Classic Teal, Terminator Red, Predator Green, Total Recall Mars, Conan Gold (key: 9)

### Text Editor
80×32 character grid with dark blue theme, full keyboard input, enter/backspace, cursor blink (key: 0)

### File Manager
Virtual filesystem with directory navigation, [D]/[F] indicators, selection highlighting (key: F)

### About
Dialog with T-800 pixel art skull, version info, "I'll be back." quote (key: 8)

### Networking
```
ARNOLD-OS> ifconfig
IP:  10.0.2.15
GW:  10.0.2.2
MAC: 52:54:00:12:34:56
Link: Up

ARNOLD-OS> ping
Pinging gateway 10.0.2.2...
Reply: 1 ticks (10ms)

ARNOLD-OS> wget
Fetching 10.0.2.2:8080...
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.10.11
Content-type: text/html
Content-Length: 137

<html><body><h1>HASTA LA VISTA, BABY!</h1>
<p>This page was fetched by ToaruOS-Arnold v4.0</p></body></html>
```

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

# Run in QEMU (basic)
& "C:\Program Files\qemu\qemu-system-i386.exe" -m 128M -vga std -kernel build\toaruos-arnold.elf

# Run with networking (for wget/ping)
& "C:\Program Files\qemu\qemu-system-i386.exe" -m 128M -vga std -kernel build\toaruos-arnold.elf `
  -netdev user,id=n1 -device e1000,netdev=n1
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
| 9 | Settings (Themes) |
| 0 | Text Editor |
| F | File Manager |
| W | Open new window |
| ESC | Return to desktop |

## Architecture

```
boot/
  multiboot.asm          — Multiboot bootloader, VBE 1024×768×32, IRQs, mouse, PIT,
                           E1000 NIC driver, ARP/IP/ICMP/TCP/HTTP network stack
kernel/
  kernel_v3.arnoldc      — Main kernel: desktop, input loop, rendering, font
  window_manager.arnoldc — Window system: create/close/drag/z-order/taskbar
  terminal.arnoldc       — Terminal emulator: 80×25 buffer, scancode mapping
  terminal_commands.arnoldc — Command handler (help, ver, time, echo, game launchers,
                             ifconfig, ping, wget)
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
    about.arnoldc        — About dialog with T-800 pixel art
    settings.arnoldc     — 5 Arnold movie themes with runtime color switching
    text_editor.arnoldc  — 80×32 text editor with full keyboard input
    file_manager.arnoldc — Virtual filesystem browser with directory navigation
test_www/
  index.html             — Test page for wget ("HASTA LA VISTA, BABY!")
linker.ld                — Kernel memory layout
tools/
  merge_modules.ps1      — Module merger with dedup
  test_*.ps1             — Automated QEMU test scripts (30+ test scripts)
  parse_pcap.py          — Network packet capture analyzer
  verify_cksum.py        — TCP/IP checksum verifier
```

## Technical Details

- **Language:** ArnoldC (compiled to x86 assembly) + hand-written x86 assembly for networking
- **Graphics:** Bochs VBE, 1024×768, 32-bit color, linear framebuffer
- **Input:** PS/2 keyboard (IRQ1 + scancode ISR), PS/2 mouse (IRQ12)
- **Networking:** E1000 NIC (PCI MMIO), ARP, IPv4, ICMP, TCP, HTTP/1.0 client
- **Font:** Custom 8×8 bitmap, full ASCII 32-126
- **ELF Size:** ~159 KB
- **Functions:** 180+ across all source modules
- **Modules:** 19+ ArnoldC source files + 1 assembly (3000+ lines)
- **Commits:** 44+
- **Boot time:** ~4 second splash screen, then desktop

### ArnoldC Challenges

Writing an OS in ArnoldC required creative solutions:

- **No early return** — `I'LL BE BACK` sets a value but doesn't exit. Used flag-based patterns instead.
- **Calculator arithmetic** — ArnoldC evaluates left-to-right like a calculator: `a * b + c * d` becomes `((a*b)+c)*d`. Must restructure expressions.
- **No string operations** — Every text string is drawn character-by-character with ASCII codes.
- **Performance** — Original `fillRect` called `putPixel` per pixel (786K calls for full-screen). Solved with native `rep stosd` assembly (~100x speedup) and dirty-rect rendering.
- **No negative numbers** — Unsigned 32-bit only. Bouncing animations use clamp-before-subtract and direction flags.
- **No function-local arrays** — Compiler silently ignores array declarations inside functions. All data arrays must be at module scope.
- **Comparison operator confusion** — `LET OFF SOME STEAM BENNET` means `>` (not `<`!). `YOU ARE NOT ME` means `!=` (not `>`). Many hours lost to this.
- **Network byte order** — x86 is little-endian, network is big-endian. Every protocol field needs manual byte swapping. ArnoldC only has 32-bit integers, so byte-level packet construction lives in assembly.
- **TCP from scratch** — Full 3-way handshake, sequence tracking, checksum with pseudo-header, FIN teardown. Debugging with PCAP captures and hex serial output.
- **`mov dx` corrupts `edx`** — x86 partial register writes! Serial debug (`mov dx, 0x3F8`) was silently destroying the TCP header size stored in `edx`. The most insidious bug in the project.

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
