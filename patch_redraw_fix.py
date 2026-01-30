#!/usr/bin/env python3
"""
Fix settings/calc rendering by:
1. Moving blocks back inside scancode check
2. Adding a pendingRedraw flag that forces scancode=99 on next frame
"""

kernel_path = r"C:\Users\Acer\Desktop\ToaruOS-Arnold\kernel\kernel_v2.arnoldc"

with open(kernel_path, 'r') as f:
    lines = f.readlines()

# Find the current positions of settings and calc blocks (outside scancode)
sett_start = None
calc_start = None
sett_end = None
calc_end = None

for i, l in enumerate(lines):
    if '=== SETTINGS MODE INPUT ===' in l:
        sett_start = i
    if '=== CALCULATOR MODE INPUT ===' in l:
        calc_start = i
    if '=== GAME TICK DISPATCH' in l:
        tick_line = i

# Find HEY CHRISTMAS TREE before each marker
for i in range(sett_start, max(sett_start-5, 0), -1):
    if 'HEY CHRISTMAS TREE isSettingsMode' in lines[i]:
        sett_start = i
        break

for i in range(calc_start, max(calc_start-5, 0), -1):
    if 'HEY CHRISTMAS TREE isCalcMode' in lines[i]:
        calc_start = i
        break

# Find block ends by counting BECAUSE/LOGIC depth
def find_end(lines, start):
    depth = 0
    for i in range(start, len(lines)):
        s = lines[i].strip()
        if "BECAUSE I'M GOING TO SAY PLEASE" in s:
            depth += 1
        if s == 'YOU HAVE NO RESPECT FOR LOGIC':
            depth -= 1
            if depth == 0:
                return i
    return None

sett_end = find_end(lines, sett_start)
calc_end = find_end(lines, calc_start)

print(f"Settings: lines {sett_start+1}-{sett_end+1}")
print(f"Calc: lines {calc_start+1}-{calc_end+1}")
print(f"Tick dispatch: line {tick_line+1}")

# Extract blocks
settings_block = lines[sett_start:sett_end+1]
calc_block = lines[calc_start:calc_end+1]

# Re-indent them back to 16 spaces (inside scancode block)
def indent_block(block, n=12):
    result = []
    for line in block:
        text = line.rstrip('\n')
        if text.strip() == '':
            result.append('\n')
        else:
            result.append(' ' * n + text + '\n')
    return result

settings_indented = indent_block(settings_block)
calc_indented = indent_block(calc_block)

# Remove both blocks from current position
new_lines = lines[:sett_start] + lines[sett_end+1:calc_start] + lines[calc_end+1:]

# Now find where to INSERT them inside the scancode block
# They should go right before the menu mode check
# Find "Check if we are in menu mode" inside scancode
insert_pos = None
for i, l in enumerate(new_lines):
    if 'Check if we are in menu mode' in l:
        # Go back to find the HEY CHRISTMAS TREE isMenuMode
        for j in range(i, max(i-5, 0), -1):
            if 'HEY CHRISTMAS TREE isMenuMode' in new_lines[j]:
                insert_pos = j
                break
        break

if insert_pos is None:
    # Try finding it another way
    for i, l in enumerate(new_lines):
        if 'isMenuMode' in l and 'HEY CHRISTMAS TREE' in l and i > 2000:
            insert_pos = i
            break

print(f"Insert position (before menu mode check): line {insert_pos+1}")

# Insert settings + calc blocks before menu mode check
insert = ['\n'] + settings_indented + ['\n'] + calc_indented + ['\n']
new_lines = new_lines[:insert_pos] + insert + new_lines[insert_pos:]

# Now add the pendingRedraw mechanism:
# 1. Add global variable: pendingRedraw (init 0)
# 2. Before scancode check, if pendingRedraw==1, set scancode=99, pendingRedraw=0
# 3. In menu handlers for settings/calc/paint, set pendingRedraw=1

# Step 1: Add pendingRedraw global variable
# Find where other globals are defined (near settingsSelected)
for i, l in enumerate(new_lines):
    if 'HEY CHRISTMAS TREE settingsSelected' in l:
        # Add pendingRedraw before settingsSelected
        var_insert = [
            'HEY CHRISTMAS TREE pendingRedraw\n',
            'YOU SET US UP 0\n',
            '\n',
        ]
        new_lines = new_lines[:i] + var_insert + new_lines[i:]
        print(f"Added pendingRedraw variable at line {i+1}")
        break

# Step 2: Before scancode check, add pendingRedraw logic
# Find "BECAUSE I'M GOING TO SAY PLEASE scancode"
for i, l in enumerate(new_lines):
    if "BECAUSE I'M GOING TO SAY PLEASE scancode" in l:
        # Insert check before this line
        redraw_check = [
            '    HEY CHRISTMAS TREE needsRedraw\n',
            '    THIS IS A WARRIOR\n',
            '    YOU SET US UP 0\n',
            '    GET TO THE CHOPPER needsRedraw\n',
            '    HERE IS MY INVITATION pendingRedraw\n',
            '    YOU ARE NOT YOU YOU ARE ME 1\n',
            '    ENOUGH TALK\n',
            '    BECAUSE I\'M GOING TO SAY PLEASE needsRedraw\n',
            '        GET TO THE CHOPPER scancode\n',
            '        HERE IS MY INVITATION 99\n',
            '        ENOUGH TALK\n',
            '        GET TO THE CHOPPER pendingRedraw\n',
            '        HERE IS MY INVITATION 0\n',
            '        ENOUGH TALK\n',
            '    YOU HAVE NO RESPECT FOR LOGIC\n',
            '\n',
        ]
        new_lines = new_lines[:i] + redraw_check + new_lines[i:]
        print(f"Added pendingRedraw check at line {i+1}")
        break

# Step 3: Set pendingRedraw=1 in menu handlers for settings, paint, calc
# Find "Settings selected" and add pendingRedraw=1
for i, l in enumerate(new_lines):
    if 'TALK TO YOURSELF "Settings selected"' in l:
        # Add after the clearScreen line (a few lines down)
        # Find the YOU HAVE NO RESPECT FOR LOGIC that closes isOpt8
        for j in range(i, i+20):
            if 'YOU HAVE NO RESPECT FOR LOGIC' in new_lines[j]:
                # Insert before the closing
                pending_set = [
                    '                            GET TO THE CHOPPER pendingRedraw\n',
                    '                            HERE IS MY INVITATION 1\n',
                    '                            ENOUGH TALK\n',
                ]
                new_lines = new_lines[:j] + pending_set + new_lines[j:]
                print(f"Added pendingRedraw=1 for Settings at line {j+1}")
                break
        break

# Find "Paint selected"
for i, l in enumerate(new_lines):
    if 'TALK TO YOURSELF "Paint selected"' in l:
        for j in range(i, i+20):
            if 'YOU HAVE NO RESPECT FOR LOGIC' in new_lines[j]:
                pending_set = [
                    '                            GET TO THE CHOPPER pendingRedraw\n',
                    '                            HERE IS MY INVITATION 1\n',
                    '                            ENOUGH TALK\n',
                ]
                new_lines = new_lines[:j] + pending_set + new_lines[j:]
                print(f"Added pendingRedraw=1 for Paint at line {j+1}")
                break
        break

# Find "Calculator selected"
for i, l in enumerate(new_lines):
    if 'TALK TO YOURSELF "Calculator selected"' in l:
        for j in range(i, i+20):
            if 'YOU HAVE NO RESPECT FOR LOGIC' in new_lines[j]:
                pending_set = [
                    '                            GET TO THE CHOPPER pendingRedraw\n',
                    '                            HERE IS MY INVITATION 1\n',
                    '                            ENOUGH TALK\n',
                ]
                new_lines = new_lines[:j] + pending_set + new_lines[j:]
                print(f"Added pendingRedraw=1 for Calculator at line {j+1}")
                break
        break

with open(kernel_path, 'w') as f:
    f.writelines(new_lines)

print(f"\nDone! Total lines: {len(new_lines)}")
