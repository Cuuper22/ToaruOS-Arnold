## Why

I wanted to understand operating systems at the level where there's nothing between you and the hardware. Reading about page tables and interrupt handlers is one thing. Writing them is different.

The ArnoldC part started as a constraint — what if every keyword is an Arnold Schwarzenegger quote? Turns out that constraint became the whole point. When your variable declaration is `HEY CHRISTMAS TREE` and your memory allocator is `I NEED YOUR CLOTHES YOUR BOOTS AND YOUR MEMORY`, you can't hide behind abstractions. Every line forces you to understand what it actually does.

I had to build the compiler first. ArnoldC only compiled to JVM bytecode — I forked it and [added native x86 code generation](https://github.com/Cuuper22/ArnoldC-Native) so it could target bare metal.

22,000+ lines of ArnoldC and x86 assembly later: it boots, draws windows, runs games, handles mouse and keyboard, and fetches webpages over a TCP/IP stack I wrote from the Ethernet frames up. The whole thing compiles to a ~213KB binary.

`EVERYBODY CHILL` disables interrupts. It makes more sense than it should.

# ToaruOS-Arnold

A complete desktop operating system written in ArnoldC — the programming language where every keyword is an Arnold Schwarzenegger movie quote. Boots to a GUI desktop with window manager, terminal, games, apps, and TCP/IP networking. No C. No Rust. Just Arnold on bare metal x86.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Demo

<!-- TODO: Add GIF showing boot → desktop → running an app -->

*To be added — animated GIF of the OS booting to desktop and running an app in QEMU.*

## Screenshots

### Boot → Login → Desktop
![Boot Splash](screenshots/01-boot-splash.png)
![Login Screen](screenshots/02-login-screen.png)
![Desktop](screenshots/03-desktop.png)

### Terminal & Networking
![Neofetch](screenshots/04-terminal-neofetch.png)
![wget over TCP/IP](screenshots/16-wget.png)

### Games (windowed)
![Snake](screenshots/06-snake-windowed.png)
![Chopper](screenshots/07-chopper-windowed.png)
![Skynet Defense](screenshots/08-skynet-windowed.png)

### Desktop Features
![Settings Themes](screenshots/10-settings-themes.png)
![Start Menu](screenshots/12-start-menu.png)
![Shutdown](screenshots/15-shutdown.png)

## What's in it

### Desktop environment
Window manager with drag, z-ordering, and focus. Start menu, right-click context menu, taskbar with live RTC clock. 5 color themes named after Arnold movies (Terminator Red, Predator Green, Total Recall Mars, Conan Gold, Classic Teal) with runtime switching.

### Terminal
35+ commands including `neofetch`, `cowsay`, `matrix`, `fortune`, `wget`, `ifconfig`, `ping`, `shutdown`. Full 80×25 buffer with PS/2 keyboard input and scancode mapping.

### Games
5 playable games — Snake, Pong, Breakout, Chopper, Skynet Defense — all rendering inside floating windows with the desktop visible behind them.

### Apps
Calculator (4×4 button grid), text editor (80×32 with cursor blink), file manager (virtual filesystem navigation), settings, about dialog with T-800 pixel art.

### Networking
Full TCP/IP stack written from scratch: E1000 NIC driver (PCI MMIO), ARP, IPv4, ICMP ping, TCP with 3-way handshake and sequence tracking, HTTP/1.0 client. The `wget` command fetches real webpages.

### Easter eggs
DVD screensaver ("I'LL BE BACK" bouncing off walls, cycling Arnold movie colors on each hit), `cowsay` with ASCII art Arnold, `matrix` rain effect, dramatic shutdown sequence with "HASTA LA VISTA, BABY" in giant red text.

## The hard parts

Writing an OS in ArnoldC meant solving problems that don't exist in any other language:

**No early return.** `I'LL BE BACK` sets a return value but doesn't exit the function. Every function uses flag-based control flow patterns instead.

**Calculator arithmetic.** ArnoldC evaluates left-to-right: `a * b + c * d` becomes `((a*b)+c)*d`. Every expression needs restructuring.

**No string operations.** Every text string is drawn character-by-character with raw ASCII codes. The boot splash is hundreds of `DO IT NOW putChar` calls.

**No negative numbers.** Unsigned 32-bit only. Bouncing animations use clamp-before-subtract and direction flags.

**Performance.** The original `fillRect` called `putPixel` per pixel — 786K calls for a full-screen fill. Fixed with native `rep stosd` assembly for ~100x speedup, plus dirty-rect rendering.

**Comparison operator confusion.** `LET OFF SOME STEAM BENNET` means `>` (not `<`). `YOU ARE NOT ME` means `!=` (not `>`). Many hours lost to this.

**Network byte order.** x86 is little-endian, network is big-endian. Every protocol field needs manual byte swapping, and ArnoldC only has 32-bit integers — so byte-level packet construction lives in assembly.

**The worst bug:** `mov dx, 0x3F8` (serial port debug output) was silently corrupting `edx` — which held the TCP header size. x86 partial register writes. The most insidious bug in the project.

## Building

<details>
<summary>Prerequisites</summary>

1. **NASM** — [nasm.us](https://www.nasm.us/pub/nasm/releasebuilds/) or `scoop install nasm`
2. **i686-elf cross-compiler** — `i686-elf-ld` and `i686-elf-objcopy` from [i686-elf-tools](https://github.com/lordmilko/i686-elf-tools/releases)
3. **ArnoldC-Native** — [github.com/Cuuper22/ArnoldC-Native](https://github.com/Cuuper22/ArnoldC-Native). Clone, `sbt assembly`, set `$env:ARNOLDC_JAR`
4. **Java 17+** — [adoptium.net](https://adoptium.net/) or `scoop install temurin-lts-jdk`
5. **QEMU** (optional) — [qemu.org](https://www.qemu.org/download/#windows) or `scoop install qemu`

</details>

### Build & run

```powershell
# Build everything
.\build_v3.ps1

# Run in QEMU
qemu-system-i386 -m 128M -vga std -kernel build\toaruos-arnold.elf

# With networking (for wget/ping)
qemu-system-i386 -m 128M -vga std -kernel build\toaruos-arnold.elf `
  -netdev user,id=n1 -device e1000,netdev=n1
```

### Build pipeline

```
.arnoldc source files → merge_modules.ps1 → single kernel.arnoldc
    → ArnoldC-Native compiler → kernel.asm (x86 NASM)
    → NASM assembler → kernel.o (ELF object)
    → i686-elf-ld → toaruos-arnold.elf (~213KB bootable kernel)
```

## Architecture

```
boot/
  multiboot.asm          — Multiboot bootloader, VBE 1024×768×32, IRQs, mouse,
                           PIT, E1000 NIC driver, ARP/IP/ICMP/TCP/HTTP stack
kernel/
  kernel_v3.arnoldc      — Main kernel: desktop, input loop, rendering, font
  window_manager.arnoldc — Window system: create/close/drag/z-order/taskbar
  terminal.arnoldc       — Terminal emulator: 80×25 buffer, scancode mapping
  terminal_commands.arnoldc — 35+ commands
  gui/                   — GUI components
  shell/                 — Shell components
  special/               — Special features
  lib/
    random.arnoldc       — PRNG (timer-seeded)
    timer.arnoldc        — PIT timer access
    speaker.arnoldc      — PC speaker
  games/                 — Snake, Pong, Breakout, Chopper, Skynet Defense
  apps/                  — Calculator, Settings, Text Editor, File Manager, About
screenshots/             — 16 QEMU captures
tools/
  merge_modules.ps1      — Module merger with dedup
  test_*.ps1             — Automated QEMU test scripts
```

## Technical details

- **Language:** ArnoldC (compiled to x86 assembly via [ArnoldC-Native](https://github.com/Cuuper22/ArnoldC-Native)) + hand-written x86 assembly for networking
- **Graphics:** Bochs VBE, 1024×768, 32-bit color, linear framebuffer
- **Input:** PS/2 keyboard (IRQ1) + PS/2 mouse (IRQ12)
- **Networking:** E1000 NIC (PCI MMIO), ARP, IPv4, ICMP, TCP, HTTP/1.0
- **Font:** Custom 8×8 bitmap, full ASCII 32-126
- **Source:** 22,000+ lines across 22 modules
- **Binary:** ~213KB ELF

## Keyboard controls

| Key | Action |
|-----|--------|
| 1-6 | Launch Terminal, Snake, Pong, Breakout, Chopper, Skynet |
| 7-9, 0 | Calculator, About, Settings, Text Editor |
| F | File Manager |
| Tab | Toggle start menu |
| ESC | Return to desktop |

## ArnoldC syntax

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
STICK AROUND condition                     ; while
DO IT NOW funcName arg1 arg2               ; call function
I'LL BE BACK value                         ; return
YOU HAVE BEEN TERMINATED                   ; end main
```

## Credits

- **ArnoldC Language** — Created by [Lauri Hartikka](https://github.com/lhartikk)
- **ArnoldC-Native Compiler** — [Cuuper22/ArnoldC-Native](https://github.com/Cuuper22/ArnoldC-Native)
- **Inspired by** — [ToaruOS](https://github.com/klange/toaruos), Windows 95, and every Arnold movie ever made

## License

MIT
