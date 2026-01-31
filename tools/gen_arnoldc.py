#!/usr/bin/env python3
"""Generate ArnoldC termPutChar calls from ASCII art strings."""

def line_to_arnoldc(text, comment=None):
    lines = []
    if comment:
        lines.append(f'TALK TO YOURSELF "{comment}"')
    for ch in text:
        lines.append(f"DO IT NOW termPutChar {ord(ch)}")
    lines.append("DO IT NOW termPrintNewline")
    return "\n".join(lines)

# ============================================================
# BANNER - Large ASCII art "ARNOLD-OS"
# ============================================================
banner_lines = [
    "  AAA  RRRR  N   N  OOO  L     DDD        OOO   SSS",
    " A   A R   R NN  N O   O L     D  D      O   O S",
    " AAAAA RRRR  N N N O   O L     D  D ---- O   O  SSS",
    " A   A R  R  N  NN O   O L     D  D      O   O     S",
    " A   A R   R N   N  OOO  LLLL  DDD        OOO  SSS",
]

print("TALK TO YOURSELF \"============================================================================\"")
print("TALK TO YOURSELF \"  termPrintBanner - Large ASCII art ARNOLD-OS banner\"")
print("TALK TO YOURSELF \"============================================================================\"")
print("LISTEN TO ME VERY CAREFULLY termPrintBanner")
print()
print("DO IT NOW termPrintNewline")
for i, line in enumerate(banner_lines):
    print(line_to_arnoldc(line, f"Banner line {i+1}"))
    print()
print("DO IT NOW termPrintNewline")
print("HASTA LA VISTA, BABY")
print()

# ============================================================
# LOGO - Larger Terminator skull/face (12+ lines)
# ============================================================
logo_lines = [
    "       ____________",
    "      /            \\",
    "     /  .-.    .-.  \\",
    "    |  ( o )  ( o )  |",
    "    |    '-'    '-'   |",
    "    |       .__       |",
    "    |      (____)     |",
    "     \\   ________   /",
    "      \\_|________|_/",
    "        |  T-800 |",
    "        |________|",
    "    CYBERDYNE  SYSTEMS",
    "   SERIES 800 MODEL 101",
]

print("TALK TO YOURSELF \"============================================================================\"")
print("TALK TO YOURSELF \"  termPrintLogo - Large ASCII Terminator face\"")
print("TALK TO YOURSELF \"============================================================================\"")
print("LISTEN TO ME VERY CAREFULLY termPrintLogo")
print()
print("DO IT NOW termPrintNewline")
for i, line in enumerate(logo_lines):
    print(line_to_arnoldc(line, f"Logo line {i+1}"))
    print()
print("DO IT NOW termPrintNewline")
print("HASTA LA VISTA, BABY")
print()

# ============================================================
# COLORS - Print color test words
# ============================================================
color_lines = [
    "COLOR TEST:",
    " [====] RED",
    " [====] GREEN",
    " [====] BLUE",
    " [====] CYAN",
    " [====] YELLOW",
    " [====] MAGENTA",
    " [====] WHITE",
    " [====] GRAY",
]

print("TALK TO YOURSELF \"============================================================================\"")
print("TALK TO YOURSELF \"  termPrintColors - Color test display\"")
print("TALK TO YOURSELF \"============================================================================\"")
print("LISTEN TO ME VERY CAREFULLY termPrintColors")
print()
for i, line in enumerate(color_lines):
    print(line_to_arnoldc(line, f"Color line {i+1}"))
    print()
print("HASTA LA VISTA, BABY")
