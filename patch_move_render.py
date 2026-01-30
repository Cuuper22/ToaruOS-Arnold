#!/usr/bin/env python3
"""Move settings & calc mode blocks outside the scancode check."""

kernel_path = r"C:\Users\Acer\Desktop\ToaruOS-Arnold\kernel\kernel_v2.arnoldc"

with open(kernel_path, 'r') as f:
    lines = f.readlines()

# Verify markers at expected positions (1-indexed in the file)
assert '=== SETTINGS MODE INPUT ===' in lines[3148], f"Expected settings marker at 3149, got: {lines[3148].strip()[:50]}"
assert '=== CALCULATOR MODE INPUT ===' in lines[3391], f"Expected calc marker at 3392, got: {lines[3391].strip()[:50]}"

# Find the TALK TO YOURSELF line before each block
# Settings: line 3149 (idx 3148) through line 3390 (idx 3389)
# But we need from the HEY CHRISTMAS TREE before it
# Let's include from idx 3147 (blank line before settings) to 3389

# Find exact start: look for HEY CHRISTMAS TREE isSettingsMode
sett_start = None
for i in range(3148, 3140, -1):
    if 'HEY CHRISTMAS TREE isSettingsMode' in lines[i]:
        sett_start = i
        break
if sett_start is None:
    # Just start at the TALK TO YOURSELF line
    sett_start = 3148

# Settings block: sett_start to 3389 (inclusive)
# Calc block: find HEY CHRISTMAS TREE isCalcMode
calc_start = None
for i in range(3391, 3385, -1):
    if 'HEY CHRISTMAS TREE isCalcMode' in lines[i]:
        calc_start = i
        break
if calc_start is None:
    calc_start = 3391

print(f"Settings block: lines {sett_start+1} to 3390")
print(f"Calc block: lines {calc_start+1} to 3890")

# Extract blocks
settings_block = lines[sett_start:3390]
calc_block = lines[calc_start:3890]

# Dedent by 12 spaces (from 16-space indent inside scancode to 4-space indent in main loop)
def dedent(block, n=12):
    result = []
    for line in block:
        text = line.rstrip('\n')
        if text.startswith(' ' * n):
            result.append(text[n:] + '\n')
        elif text.strip() == '':
            result.append('\n')
        else:
            result.append(text + '\n')
    return result

settings_dedented = dedent(settings_block)
calc_dedented = dedent(calc_block)

# Remove both blocks from original (calc first since it's later)
new_lines = lines[:sett_start] + lines[3390:calc_start] + lines[3890:]

# Find tick dispatch marker in new_lines
tick_idx = None
for i, l in enumerate(new_lines):
    if '=== GAME TICK DISPATCH' in l:
        tick_idx = i
        break

if tick_idx is None:
    print("ERROR: Could not find tick dispatch marker")
    exit(1)

print(f"Tick dispatch at new line {tick_idx+1}")

# Insert both blocks before tick dispatch
insert = ['\n'] + settings_dedented + ['\n'] + calc_dedented + ['\n']
new_lines = new_lines[:tick_idx] + insert + new_lines[tick_idx:]

with open(kernel_path, 'w') as f:
    f.writelines(new_lines)

print(f"Done! Moved {len(settings_block)} + {len(calc_block)} lines outside scancode block")
print(f"Original: {len(lines)} lines, New: {len(new_lines)} lines")
