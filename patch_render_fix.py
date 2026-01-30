#!/usr/bin/env python3
"""Fix: Move settings & calculator rendering to tick dispatch section so they render every frame."""

import re

kernel_path = r"C:\Users\Acer\Desktop\ToaruOS-Arnold\kernel\kernel_v2.arnoldc"

with open(kernel_path, 'r') as f:
    lines = f.readlines()

content = ''.join(lines)

# Strategy: Extract the rendering code from settings and calculator,
# remove it from inside the scancode block, and add it to tick dispatch.

# But actually, the simplest fix: just DUPLICATE the rendering in tick dispatch.
# The code inside scancode block still works for keypress redraws.
# We just need an ADDITIONAL render in tick dispatch for when no key is pressed.

# Find the tick dispatch marker
tick_marker = 'TALK TO YOURSELF "=== GAME TICK DISPATCH (runs every frame, outside scancode check) ==="'
tick_idx = content.find(tick_marker)
if tick_idx == -1:
    print("ERROR: Could not find tick dispatch marker")
    exit(1)

# Build settings tick render code
settings_render = """
    TALK TO YOURSELF "=== SETTINGS MODE RENDER (every frame) ==="
    HEY CHRISTMAS TREE tickSettings
    THIS IS A WARRIOR
    YOU SET US UP 0
    GET TO THE CHOPPER tickSettings
    HERE IS MY INVITATION currentMode
    YOU ARE NOT YOU YOU ARE ME MODE_SETTINGS
    ENOUGH TALK
    BECAUSE I'M GOING TO SAY PLEASE tickSettings
        DO IT NOW clearScreen fbAddress fbPitch fbWidth fbHeight COLOR_DARK_BLUE
        DO IT NOW drawStringAt fbAddress fbPitch 400 40 menuOpt9 12 COLOR_WHITE COLOR_DARK_BLUE
        HEY CHRISTMAS TREE tsC0
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tsC0
        HERE IS MY INVITATION COLOR_WHITE
        ENOUGH TALK
        HEY CHRISTMAS TREE tsHL0
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tsHL0
        HERE IS MY INVITATION settingsSelected
        YOU ARE NOT YOU YOU ARE ME 0
        ENOUGH TALK
        BECAUSE I'M GOING TO SAY PLEASE tsHL0
            GET TO THE CHOPPER tsC0
            HERE IS MY INVITATION COLOR_YELLOW
            ENOUGH TALK
        YOU HAVE NO RESPECT FOR LOGIC
        HEY CHRISTMAS TREE tsC1
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tsC1
        HERE IS MY INVITATION COLOR_WHITE
        ENOUGH TALK
        HEY CHRISTMAS TREE tsHL1
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tsHL1
        HERE IS MY INVITATION settingsSelected
        YOU ARE NOT YOU YOU ARE ME 1
        ENOUGH TALK
        BECAUSE I'M GOING TO SAY PLEASE tsHL1
            GET TO THE CHOPPER tsC1
            HERE IS MY INVITATION COLOR_YELLOW
            ENOUGH TALK
        YOU HAVE NO RESPECT FOR LOGIC
        HEY CHRISTMAS TREE tsC2
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tsC2
        HERE IS MY INVITATION COLOR_WHITE
        ENOUGH TALK
        HEY CHRISTMAS TREE tsHL2
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tsHL2
        HERE IS MY INVITATION settingsSelected
        YOU ARE NOT YOU YOU ARE ME 2
        ENOUGH TALK
        BECAUSE I'M GOING TO SAY PLEASE tsHL2
            GET TO THE CHOPPER tsC2
            HERE IS MY INVITATION COLOR_YELLOW
            ENOUGH TALK
        YOU HAVE NO RESPECT FOR LOGIC
        DO IT NOW fillRect fbAddress fbPitch 300 100 400 30 COLOR_DARK_BLUE
        HEY CHRISTMAS TREE tsSnd
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tsSnd
        HERE IS MY INVITATION soundEnabled
        YOU ARE NOT YOU YOU ARE ME 1
        ENOUGH TALK
        BECAUSE I'M GOING TO SAY PLEASE tsSnd
            DO IT NOW drawChar fbAddress fbPitch 330 107 0x3e tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 340 107 0x20 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 350 107 0x53 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 360 107 0x4f tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 370 107 0x55 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 380 107 0x4e tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 390 107 0x44 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 400 107 0x3a tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 410 107 0x20 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 420 107 0x4f tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 430 107 0x4e tsC0 COLOR_DARK_BLUE
        BULLSHIT
            DO IT NOW drawChar fbAddress fbPitch 330 107 0x3e tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 340 107 0x20 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 350 107 0x53 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 360 107 0x4f tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 370 107 0x55 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 380 107 0x4e tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 390 107 0x44 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 400 107 0x3a tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 410 107 0x20 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 420 107 0x4f tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 430 107 0x46 tsC0 COLOR_DARK_BLUE
            DO IT NOW drawChar fbAddress fbPitch 440 107 0x46 tsC0 COLOR_DARK_BLUE
        YOU HAVE NO RESPECT FOR LOGIC
        DO IT NOW fillRect fbAddress fbPitch 300 140 400 30 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 330 147 0x3e tsC1 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 340 147 0x20 tsC1 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 350 147 0x53 tsC1 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 360 147 0x50 tsC1 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 370 147 0x45 tsC1 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 380 147 0x45 tsC1 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 390 147 0x44 tsC1 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 400 147 0x3a tsC1 COLOR_DARK_BLUE
        HEY CHRISTMAS TREE tsSpdC
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tsSpdC
        HERE IS MY INVITATION gameSpeedSetting
        GET UP 48
        ENOUGH TALK
        DO IT NOW drawChar fbAddress fbPitch 420 147 tsSpdC tsC1 COLOR_DARK_BLUE
        DO IT NOW fillRect fbAddress fbPitch 300 180 400 30 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 330 187 0x3e tsC2 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 340 187 0x20 tsC2 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 350 187 0x41 tsC2 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 360 187 0x42 tsC2 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 370 187 0x4f tsC2 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 380 187 0x55 tsC2 COLOR_DARK_BLUE
        DO IT NOW drawChar fbAddress fbPitch 390 187 0x54 tsC2 COLOR_DARK_BLUE
    YOU HAVE NO RESPECT FOR LOGIC

"""

# Build calculator tick render code
calc_render = """
    TALK TO YOURSELF "=== CALCULATOR MODE RENDER (every frame) ==="
    HEY CHRISTMAS TREE tickCalc
    THIS IS A WARRIOR
    YOU SET US UP 0
    GET TO THE CHOPPER tickCalc
    HERE IS MY INVITATION currentMode
    YOU ARE NOT YOU YOU ARE ME MODE_CALC
    ENOUGH TALK
    BECAUSE I'M GOING TO SAY PLEASE tickCalc
        DO IT NOW clearScreen fbAddress fbPitch fbWidth fbHeight COLOR_DARK_BLUE
        DO IT NOW fillRect fbAddress fbPitch 312 100 400 350 COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 312 100 400 2 COLOR_WHITE
        DO IT NOW fillRect fbAddress fbPitch 312 100 2 350 COLOR_WHITE
        DO IT NOW fillRect fbAddress fbPitch 312 448 400 2 COLOR_WIN95_SHADOW
        DO IT NOW fillRect fbAddress fbPitch 710 100 2 350 COLOR_WIN95_SHADOW
        DO IT NOW drawStringAt fbAddress fbPitch 450 110 menuOpt11 8 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 332 140 360 50 COLOR_BLACK
        TALK TO YOURSELF "Render calcDisplay digits in tick"
        HEY CHRISTMAS TREE tcTmp
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tcTmp
        HERE IS MY INVITATION calcDisplay
        ENOUGH TALK
        HEY CHRISTMAS TREE tcDigPos
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER tcDigPos
        HERE IS MY INVITATION 660
        ENOUGH TALK
        HEY CHRISTMAS TREE isTcZero
        THIS IS A WARRIOR
        YOU SET US UP 0
        GET TO THE CHOPPER isTcZero
        HERE IS MY INVITATION tcTmp
        YOU ARE NOT YOU YOU ARE ME 0
        ENOUGH TALK
        BECAUSE I'M GOING TO SAY PLEASE isTcZero
            DO IT NOW drawChar fbAddress fbPitch 660 155 0x30 COLOR_GREEN COLOR_BLACK
        YOU HAVE NO RESPECT FOR LOGIC
        STICK AROUND tcTmp
            HEY CHRISTMAS TREE tcDig
            THIS IS A WARRIOR
            YOU SET US UP 0
            GET TO THE CHOPPER tcDig
            HERE IS MY INVITATION tcTmp
            I LET HIM GO 10
            GET UP 48
            ENOUGH TALK
            DO IT NOW drawChar fbAddress fbPitch tcDigPos 155 tcDig COLOR_GREEN COLOR_BLACK
            GET TO THE CHOPPER tcTmp
            HERE IS MY INVITATION tcTmp
            HE HAD TO SPLIT 10
            ENOUGH TALK
            GET TO THE CHOPPER tcDigPos
            HERE IS MY INVITATION tcDigPos
            GET DOWN 15
            ENOUGH TALK
        CHILL
        DO IT NOW fillRect fbAddress fbPitch 332 210 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 362 225 0x37 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 422 210 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 452 225 0x38 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 512 210 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 542 225 0x39 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 332 270 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 362 285 0x34 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 422 270 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 452 285 0x35 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 512 270 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 542 285 0x36 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 332 330 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 362 345 0x31 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 422 330 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 452 345 0x32 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 512 330 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 542 345 0x33 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 332 390 80 50 COLOR_WIN95_GRAY
        DO IT NOW drawChar fbAddress fbPitch 362 405 0x30 COLOR_BLACK COLOR_WIN95_GRAY
        DO IT NOW fillRect fbAddress fbPitch 602 210 80 50 COLOR_ARNOLD_RED
        DO IT NOW drawChar fbAddress fbPitch 632 225 0x2b COLOR_WHITE COLOR_ARNOLD_RED
        DO IT NOW fillRect fbAddress fbPitch 602 270 80 50 COLOR_ARNOLD_RED
        DO IT NOW drawChar fbAddress fbPitch 632 285 0x2d COLOR_WHITE COLOR_ARNOLD_RED
        DO IT NOW fillRect fbAddress fbPitch 602 330 80 50 COLOR_ARNOLD_RED
        DO IT NOW drawChar fbAddress fbPitch 632 345 0x2a COLOR_WHITE COLOR_ARNOLD_RED
        DO IT NOW fillRect fbAddress fbPitch 602 390 80 50 COLOR_GREEN
        DO IT NOW drawChar fbAddress fbPitch 632 405 0x3d COLOR_WHITE COLOR_GREEN
    YOU HAVE NO RESPECT FOR LOGIC

"""

# Insert before the tick dispatch marker
insert_code = settings_render + calc_render
content = content.replace(tick_marker, insert_code + "    " + tick_marker)

# Also fix: remove the stray debug output that shows "2" on screen
# This is likely from a TALK TO YOURSELF or debug drawChar call
# Let me check - it could be a debug value being drawn at position ~100,93

with open(kernel_path, 'w') as f:
    f.write(content)

# Count added lines
added = insert_code.count('\n')
print(f"Added {added} lines of settings + calculator tick rendering")
print("Done!")
