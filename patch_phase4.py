#!/usr/bin/env python3
"""Phase 4: Polish & UX Improvements
4.1 Blinking terminal cursor
4.2 Taskbar clock (RTC)
4.3 TERMINATE command
4.4 EXIT command
4.5 Delete key support in terminal
"""

kernel_path = r"C:\Users\Acer\Desktop\ToaruOS-Arnold\kernel\kernel_v2.arnoldc"
asm_path = r"C:\Users\Acer\Desktop\ToaruOS-Arnold\boot\multiboot_simple.asm"

# ============================================================
# PART A: Add RTC functions to bootloader ASM
# ============================================================
with open(asm_path, 'r') as f:
    asm = f.read()

# Add read_rtc_hours, read_rtc_minutes, read_rtc_seconds, halt_system
rtc_asm = """
; ============================================================================
; RTC (Real-Time Clock) FUNCTIONS
; ============================================================================
global read_rtc_hours
global read_rtc_minutes
global read_rtc_seconds
global halt_system

; Read RTC hours (BCD) from CMOS register 0x04
read_rtc_hours:
    mov al, 0x04
    out 0x70, al
    in al, 0x71
    ; Convert BCD to binary: high_nibble*10 + low_nibble
    mov ah, al
    and al, 0x0F        ; low nibble
    shr ah, 4           ; high nibble
    mov cl, 10
    imul ah, cl
    add al, ah
    movzx eax, al
    ret

; Read RTC minutes (BCD) from CMOS register 0x02
read_rtc_minutes:
    mov al, 0x02
    out 0x70, al
    in al, 0x71
    mov ah, al
    and al, 0x0F
    shr ah, 4
    mov cl, 10
    imul ah, cl
    add al, ah
    movzx eax, al
    ret

; Read RTC seconds (BCD) from CMOS register 0x00
read_rtc_seconds:
    mov al, 0x00
    out 0x70, al
    in al, 0x71
    mov ah, al
    and al, 0x0F
    shr ah, 4
    mov cl, 10
    imul ah, cl
    add al, ah
    movzx eax, al
    ret

; Halt the system (cli + hlt loop)
halt_system:
    cli
.halt_loop:
    hlt
    jmp .halt_loop
"""

# Insert before the final "HASTA LA VISTA, BABY" comment
asm = asm.replace(
    '; ============================================================================\n; "HASTA LA VISTA, BABY"',
    rtc_asm + '; ============================================================================\n; "HASTA LA VISTA, BABY"'
)

with open(asm_path, 'w') as f:
    f.write(asm)
print("Added RTC functions and halt_system to bootloader ASM")

# ============================================================
# PART B: Add Phase 4 features to kernel
# ============================================================
with open(kernel_path, 'r') as f:
    lines = f.readlines()

content = ''.join(lines)

# --- B1: Add EXIT command string definition ---
# Add after cmdTerminate definition
exit_cmd = """
TALK TO YOURSELF "Command: EXIT"
HEY CHRISTMAS TREE cmdExit
LINE THEM UP
THIS IS A TINY WARRIOR
HOW MANY 4
PUT THEM IN LINE
0x45 0x58 0x49 0x54

"""
content = content.replace(
    'TALK TO YOURSELF "Help text lines"',
    exit_cmd + 'TALK TO YOURSELF "Help text lines"'
)

# --- B2: Add cursor blink + clock variables ---
# Add after pendingRedraw
cursor_vars = """
TALK TO YOURSELF "=== CURSOR BLINK STATE ==="
HEY CHRISTMAS TREE cursorBlinkTimer
THIS IS A WARRIOR
YOU SET US UP 0

HEY CHRISTMAS TREE cursorVisible
THIS IS A WARRIOR
YOU SET US UP 1

HEY CHRISTMAS TREE lastTickCount
THIS IS A WARRIOR
YOU SET US UP 0

TALK TO YOURSELF "=== CLOCK STATE ==="
HEY CHRISTMAS TREE clockHours
THIS IS A WARRIOR
YOU SET US UP 0

HEY CHRISTMAS TREE clockMinutes
THIS IS A WARRIOR
YOU SET US UP 0

HEY CHRISTMAS TREE clockUpdateTimer
THIS IS A WARRIOR
YOU SET US UP 0

"""
content = content.replace(
    'HEY CHRISTMAS TREE settingsSelected',
    cursor_vars + 'HEY CHRISTMAS TREE settingsSelected'
)

# --- B3: Add TERMINATE and EXIT command handlers ---
# Insert before the "Unknown command" handler
# Find the BULLSHIT before "Unknown command - default response"
terminate_exit_code = """                                    BULLSHIT
                                        TALK TO YOURSELF "Check for TERMINATE command"
                                        HEY CHRISTMAS TREE isTermCmd
                                        THIS IS A WARRIOR
                                        YOU SET US UP 0
                                        GET YOUR ASS TO MARS isTermCmd
                                        DO IT NOW stringEquals cmdBuffer cmdLen cmdTerminate 9

                                        BECAUSE I'M GOING TO SAY PLEASE isTermCmd
                                            TALK TO YOURSELF "HASTA LA VISTA, BABY!"
                                            DO IT NOW clearScreen fbAddress fbPitch fbWidth fbHeight COLOR_BLACK
                                            DO IT NOW drawStringAt fbAddress fbPitch 300 300 helpLine4 31 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 412 340 0x48 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 422 340 0x41 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 432 340 0x53 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 442 340 0x54 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 452 340 0x41 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 462 340 0x20 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 472 340 0x4C COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 482 340 0x41 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 492 340 0x20 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 502 340 0x56 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 512 340 0x49 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 522 340 0x53 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 532 340 0x54 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 542 340 0x41 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 552 340 0x2C COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 562 340 0x20 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 572 340 0x42 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 582 340 0x41 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 592 340 0x42 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 602 340 0x59 COLOR_RED COLOR_BLACK
                                            DO IT NOW drawChar fbAddress fbPitch 612 340 0x21 COLOR_RED COLOR_BLACK
                                            DO IT NOW sleepTicks 36
                                            DO IT NOW halt_system
                                        BULLSHIT
                                            TALK TO YOURSELF "Check for EXIT command"
                                            HEY CHRISTMAS TREE isExitCmd
                                            THIS IS A WARRIOR
                                            YOU SET US UP 0
                                            GET YOUR ASS TO MARS isExitCmd
                                            DO IT NOW stringEquals cmdBuffer cmdLen cmdExit 4

                                            BECAUSE I'M GOING TO SAY PLEASE isExitCmd
                                                TALK TO YOURSELF "EXIT - Return to menu"
                                                GET TO THE CHOPPER currentMode
                                                HERE IS MY INVITATION MODE_MENU
                                                ENOUGH TALK
                                                DO IT NOW clearScreen fbAddress fbPitch fbWidth fbHeight COLOR_DARK_BLUE
                                                DO IT NOW fillRect fbAddress fbPitch 0 0 1024 40 COLOR_PREDATOR_GREEN
                                                DO IT NOW drawStringAt fbAddress fbPitch 16 16 menuTitle 19 COLOR_BLACK COLOR_PREDATOR_GREEN
                                                DO IT NOW drawStringAt fbAddress fbPitch 350 100 menuSubtitle 11 COLOR_YELLOW COLOR_DARK_BLUE
                                                DO IT NOW redrawMenu fbAddress fbPitch
                                            BULLSHIT"""
# Replace the single BULLSHIT before unknown command
content = content.replace(
    """                                    BULLSHIT
                                        TALK TO YOURSELF "Unknown command - default response\"""",
    terminate_exit_code + """
                                                TALK TO YOURSELF "Unknown command - default response\""""
)

# --- B4: Add cursor blink + clock to tick dispatch ---
tick_dispatch_code = """
    TALK TO YOURSELF "=== TERMINAL CURSOR BLINK (runs every frame) ==="
    HEY CHRISTMAS TREE tickTerm
    THIS IS A WARRIOR
    YOU SET US UP 0
    GET TO THE CHOPPER tickTerm
    HERE IS MY INVITATION currentMode
    YOU ARE NOT YOU YOU ARE ME MODE_TERMINAL
    ENOUGH TALK
    BECAUSE I'M GOING TO SAY PLEASE tickTerm
        GET TO THE CHOPPER cursorBlinkTimer
        HERE IS MY INVITATION cursorBlinkTimer
        GET UP 1
        ENOUGH TALK
        HEY CHRISTMAS TREE blinkNow
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER blinkNow
        HERE IS MY INVITATION cursorBlinkTimer
        LET OFF SOME STEAM BENNET 8
        ENOUGH TALK
        BECAUSE I'M GOING TO SAY PLEASE blinkNow
            GET TO THE CHOPPER cursorBlinkTimer
            HERE IS MY INVITATION 0
            ENOUGH TALK
            HEY CHRISTMAS TREE wasVisible
            THIS IS A WARRIOR
            YOU SET US UP 0
            GET TO THE CHOPPER wasVisible
            HERE IS MY INVITATION cursorVisible
            YOU ARE NOT YOU YOU ARE ME 1
            ENOUGH TALK
            BECAUSE I'M GOING TO SAY PLEASE wasVisible
                GET TO THE CHOPPER cursorVisible
                HERE IS MY INVITATION 0
                ENOUGH TALK
                DO IT NOW drawChar fbAddress fbPitch cursorX cursorY 0x20 COLOR_WHITE COLOR_DARK_BLUE
            BULLSHIT
                GET TO THE CHOPPER cursorVisible
                HERE IS MY INVITATION 1
                ENOUGH TALK
                DO IT NOW drawChar fbAddress fbPitch cursorX cursorY 0x5F COLOR_WHITE COLOR_DARK_BLUE
            YOU HAVE NO RESPECT FOR LOGIC
        YOU HAVE NO RESPECT FOR LOGIC
    YOU HAVE NO RESPECT FOR LOGIC

    TALK TO YOURSELF "=== TASKBAR CLOCK UPDATE ==="
    GET TO THE CHOPPER clockUpdateTimer
    HERE IS MY INVITATION clockUpdateTimer
    GET UP 1
    ENOUGH TALK
    HEY CHRISTMAS TREE clockNow
    THIS IS A WARRIOR
    YOU SET US UP 0
    GET TO THE CHOPPER clockNow
    HERE IS MY INVITATION clockUpdateTimer
    LET OFF SOME STEAM BENNET 17
    ENOUGH TALK
    BECAUSE I'M GOING TO SAY PLEASE clockNow
        GET TO THE CHOPPER clockUpdateTimer
        HERE IS MY INVITATION 0
        ENOUGH TALK
        GET YOUR ASS TO MARS clockHours
        DO IT NOW read_rtc_hours
        GET YOUR ASS TO MARS clockMinutes
        DO IT NOW read_rtc_minutes
        TALK TO YOURSELF "Draw clock in title bar"
        DO IT NOW fillRect fbAddress fbPitch 940 8 80 28 COLOR_PREDATOR_GREEN
        HEY CHRISTMAS TREE h10
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER h10
        HERE IS MY INVITATION clockHours
        HE HAD TO SPLIT 10
        GET UP 48
        ENOUGH TALK
        HEY CHRISTMAS TREE h1
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER h1
        HERE IS MY INVITATION clockHours
        I LET HIM GO 10
        GET UP 48
        ENOUGH TALK
        HEY CHRISTMAS TREE m10
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER m10
        HERE IS MY INVITATION clockMinutes
        HE HAD TO SPLIT 10
        GET UP 48
        ENOUGH TALK
        HEY CHRISTMAS TREE m1
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER m1
        HERE IS MY INVITATION clockMinutes
        I LET HIM GO 10
        GET UP 48
        ENOUGH TALK
        DO IT NOW drawChar fbAddress fbPitch 948 16 h10 COLOR_BLACK COLOR_PREDATOR_GREEN
        DO IT NOW drawChar fbAddress fbPitch 958 16 h1 COLOR_BLACK COLOR_PREDATOR_GREEN
        DO IT NOW drawChar fbAddress fbPitch 968 16 0x3A COLOR_BLACK COLOR_PREDATOR_GREEN
        DO IT NOW drawChar fbAddress fbPitch 978 16 m10 COLOR_BLACK COLOR_PREDATOR_GREEN
        DO IT NOW drawChar fbAddress fbPitch 988 16 m1 COLOR_BLACK COLOR_PREDATOR_GREEN
    YOU HAVE NO RESPECT FOR LOGIC

"""

# Insert before the GAME TICK DISPATCH marker
content = content.replace(
    '    TALK TO YOURSELF "=== GAME TICK DISPATCH (runs every frame, outside scancode check) ==="',
    tick_dispatch_code + '    TALK TO YOURSELF "=== GAME TICK DISPATCH (runs every frame, outside scancode check) ==="'
)

# --- B5: Add Delete key support (scancode 0x53 = 83) ---
# Find the backspace handler and add delete key handler after it
# Delete key: erase char at cursor position without moving cursor back
# Actually for terminal, delete does same as backspace is simpler
# We add it right after the backspace handler ends

# --- B6: Update HELP text to show new commands ---
# Find helpLine4 and see what's there
# Actually let's just add a note about TERMINATE and EXIT to help output
# Find where HELP command outputs text

# Let me add display of TERMINATE and EXIT in the help handler
# Find where help outputs are displayed
help_additions = """                                        DO IT NOW drawStringAt fbAddress fbPitch cursorX cursorY helpLine4 31 COLOR_YELLOW COLOR_DARK_BLUE
                                        GET TO THE CHOPPER cursorY
                                        HERE IS MY INVITATION cursorY
                                        GET UP 10
                                        ENOUGH TALK
                                        TALK TO YOURSELF "Show TERMINATE command"
                                        DO IT NOW drawChar fbAddress fbPitch cursorX cursorY 0x54 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 88 cursorY 0x45 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 96 cursorY 0x52 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 104 cursorY 0x4D COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 112 cursorY 0x49 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 120 cursorY 0x4E COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 128 cursorY 0x41 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 136 cursorY 0x54 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 144 cursorY 0x45 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 160 cursorY 0x2D COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 176 cursorY 0x53 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 184 cursorY 0x68 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 192 cursorY 0x75 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 200 cursorY 0x74 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 208 cursorY 0x64 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 216 cursorY 0x6F COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 224 cursorY 0x77 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 232 cursorY 0x6E COLOR_YELLOW COLOR_DARK_BLUE
                                        GET TO THE CHOPPER cursorY
                                        HERE IS MY INVITATION cursorY
                                        GET UP 10
                                        ENOUGH TALK
                                        TALK TO YOURSELF "Show EXIT command"
                                        DO IT NOW drawChar fbAddress fbPitch cursorX cursorY 0x45 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 88 cursorY 0x58 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 96 cursorY 0x49 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 104 cursorY 0x54 COLOR_WHITE COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 120 cursorY 0x2D COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 136 cursorY 0x42 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 144 cursorY 0x61 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 152 cursorY 0x63 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 160 cursorY 0x6B COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 168 cursorY 0x20 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 176 cursorY 0x74 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 184 cursorY 0x6F COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 192 cursorY 0x20 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 200 cursorY 0x6D COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 208 cursorY 0x65 COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 216 cursorY 0x6E COLOR_YELLOW COLOR_DARK_BLUE
                                        DO IT NOW drawChar fbAddress fbPitch 224 cursorY 0x75 COLOR_YELLOW COLOR_DARK_BLUE"""

# Find where helpLine4 is drawn in HELP handler and what comes after
# We need to find the exact location. The help handler draws helpLine1-4
# We want to add TERMINATE and EXIT lines after helpLine4

# Actually, let me find where help displays are and replace the last one
# to add our new lines after it

# Find the CHOPPER command check that comes after help output
old_help_end = """                                BULLSHIT
                                    TALK TO YOURSELF "Check for CHOPPER command"
                                    HEY CHRISTMAS TREE isChopperCmd"""

# We need to find where helpLine4 is displayed before the CHOPPER check
# Let me search for the right anchor
# The help output ends and then checks CLEAR. Actually the structure is:
# if(HELP) { display help } else { if(CLEAR) ... else { if(ABOUT) ... else { if(CHOPPER) ... else { if(GAMES) ... else { unknown } } } } }

# So after displaying help lines, the HELP block closes and goes to BULLSHIT->CLEAR check
# I need to add the TERMINATE and EXIT lines inside the HELP block, before it closes

# Let me find the exact pattern after helpLine4 display
# From the explore, after helpLine4 display:
# DO IT NOW drawStringAt ... helpLine4 31 COLOR_YELLOW ...
# cursorY += 10
# Then the HELP block closes

# Let me be more surgical. Find "CHOPPER! - System info" to locate the CHOPPER block
# Actually, let me find the exact text near helpLine4

# Let me just search and replace more precisely
# The HELP command handler ends with displaying helpLine4, advancing cursorY, then the closing
# The next thing after the HELP block is: BULLSHIT -> CLEAR check

# I'll replace the anchor text to insert after helpLine4 display
# Looking at the code from the explore:
# Line ~4395: DO IT NOW drawStringAt ... helpLine4 31 COLOR_YELLOW
# Line ~4396-4398: cursorY += 10
# Line ~4399: closing BULLSHIT or YOU HAVE NO RESPECT FOR LOGIC

# Let me search for the exact pattern
import re

# Find where helpLine4 is drawn followed by cursorY increment
# This is unique enough to match
old_help4 = """                                        DO IT NOW drawStringAt fbAddress fbPitch cursorX cursorY helpLine4 31 COLOR_YELLOW COLOR_DARK_BLUE
                                        GET TO THE CHOPPER cursorY
                                        HERE IS MY INVITATION cursorY
                                        GET UP 10
                                        ENOUGH TALK"""

if old_help4 in content:
    # Replace with: original + new TERMINATE and EXIT lines
    new_help4 = help_additions
    content = content.replace(old_help4, new_help4, 1)
    print("Added TERMINATE and EXIT to HELP output")
else:
    print("WARNING: Could not find helpLine4 display pattern")
    # Try to find it with different spacing
    idx = content.find('helpLine4 31 COLOR_YELLOW')
    if idx > 0:
        print(f"  Found helpLine4 reference at offset {idx}")

# --- B7: Erase cursor before drawing typed character ---
# When a character is typed, erase the cursor underscore first
# Find where printable chars are drawn
# This draws the typed character: DO IT NOW drawChar fbAddress fbPitch cursorX cursorY ascii COLOR_WHITE COLOR_DARK_BLUE
# We don't need to explicitly erase - the character draw overwrites the cursor

# --- B8: Reset cursor visible when typing ---
# After printing a character, reset blink so cursor is visible
# Find the character draw in terminal and add cursor reset after it
# The character is drawn, then cursorX is incremented
# After the increment, reset cursor timer

# Find "Track command length" and insert cursor reset before it
track_anchor = '                        TALK TO YOURSELF "Track command length"'
if track_anchor in content:
    cursor_reset = """                        GET TO THE CHOPPER cursorVisible
                        HERE IS MY INVITATION 1
                        ENOUGH TALK
                        GET TO THE CHOPPER cursorBlinkTimer
                        HERE IS MY INVITATION 0
                        ENOUGH TALK
"""
    content = content.replace(track_anchor, cursor_reset + track_anchor, 1)
    print("Added cursor reset after character draw")
else:
    print("WARNING: Could not find Track command length anchor")

# Also reset cursor after Enter (command execution)
# After Enter processes command, cursor moves to new line
# Find where cmdLen is reset to 0 after Enter
enter_anchor = """                    TALK TO YOURSELF "Clear command buffer"
                    GET TO THE CHOPPER cmdLen
                    HERE IS MY INVITATION 0
                    ENOUGH TALK"""

if enter_anchor in content:
    enter_replacement = enter_anchor + """
                    GET TO THE CHOPPER cursorVisible
                    HERE IS MY INVITATION 1
                    ENOUGH TALK
                    GET TO THE CHOPPER cursorBlinkTimer
                    HERE IS MY INVITATION 0
                    ENOUGH TALK"""
    content = content.replace(enter_anchor, enter_replacement, 1)
    print("Added cursor reset after Enter")
else:
    print("WARNING: Could not find Enter cursor reset anchor")

with open(kernel_path, 'w') as f:
    f.write(content)

new_count = content.count('\n')
print(f"\nDone! Phase 4 applied. Total lines: {new_count}")
