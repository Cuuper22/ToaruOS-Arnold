# Tools & Test Scripts

## Build Tools
- `merge_modules.ps1` — Merges all ArnoldC modules into one file (constants, vars, functions deduplicated)
- `test_fresh.ps1` — Full clean build + link (used by build_v3.ps1)

## Test Scripts
QEMU-based automated tests. Each boots the kernel, sends commands via QEMU monitor, and takes screenshots.

### Core Tests
- `test_login.ps1` — Boot splash → login → desktop sequence
- `test_cursor.ps1` — Mouse cursor rendering
- `test_context_menu.ps1` — Right-click context menu
- `test_shutdown.ps1` — Full shutdown animation

### App Tests
- `test_calc.ps1` — Calculator app
- `test_editor.ps1` — Text editor
- `test_filemgr.ps1` — File manager
- `test_settings.ps1` — Settings/themes
- `test_about.ps1` — About dialog

### Game Tests
- `test_all_games.ps1` — All 5 games
- `test_one_game.ps1` — Single game launch
- `test_snake.ps1` — Snake game

### Terminal Tests
- `test_term_basic.ps1` — Terminal basics
- `test_term_cmds.ps1` — Terminal commands
- `test_term_full.ps1` — Full terminal test
- `test_colors.ps1` — Colors command

### Debug Tools
- `parse_pcap.py` — Parse network packet captures
- `verify_cksum.py` — Verify TCP/IP checksums
- `check_elf.ps1` — ELF binary inspection
- `scan_deps.ps1` — Module dependency scanner
- `count_nesting.ps1` — ArnoldC nesting depth checker
