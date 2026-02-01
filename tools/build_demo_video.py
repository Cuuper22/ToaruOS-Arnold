"""
ToaruOS-Arnold Demo Video Builder
Takes captured QEMU frames and creates a polished demo video with title cards.
"""
import os
import struct
import shutil
import subprocess

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAMES_DIR = os.path.join(PROJECT_ROOT, "build", "demo_frames")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "build", "demo_final")
WIDTH, HEIGHT = 1024, 768
FPS = 5

def create_ppm(filename, pixels):
    """Create a PPM P6 file from pixel data (list of (r,g,b) tuples)."""
    with open(filename, 'wb') as f:
        header = f"P6\n{WIDTH} {HEIGHT}\n255\n".encode()
        f.write(header)
        data = bytearray()
        for r, g, b in pixels:
            data.extend([r, g, b])
        f.write(bytes(data))

def solid_color(r, g, b):
    """Create a solid color frame."""
    return [(r, g, b)] * (WIDTH * HEIGHT)

def draw_char(pixels, x, y, char, r, g, b, scale=1):
    """Draw a character at (x,y) with given color and scale. Simple 5x7 bitmap font."""
    # Minimal bitmap font for uppercase + digits
    FONT = {
        'A': [0x7C,0x12,0x11,0x12,0x7C], 'B': [0x7F,0x49,0x49,0x49,0x36],
        'C': [0x3E,0x41,0x41,0x41,0x22], 'D': [0x7F,0x41,0x41,0x41,0x3E],
        'E': [0x7F,0x49,0x49,0x49,0x41], 'F': [0x7F,0x09,0x09,0x09,0x01],
        'G': [0x3E,0x41,0x49,0x49,0x7A], 'H': [0x7F,0x08,0x08,0x08,0x7F],
        'I': [0x00,0x41,0x7F,0x41,0x00], 'J': [0x20,0x40,0x41,0x3F,0x01],
        'K': [0x7F,0x08,0x14,0x22,0x41], 'L': [0x7F,0x40,0x40,0x40,0x40],
        'M': [0x7F,0x02,0x0C,0x02,0x7F], 'N': [0x7F,0x04,0x08,0x10,0x7F],
        'O': [0x3E,0x41,0x41,0x41,0x3E], 'P': [0x7F,0x09,0x09,0x09,0x06],
        'Q': [0x3E,0x41,0x51,0x21,0x5E], 'R': [0x7F,0x09,0x19,0x29,0x46],
        'S': [0x46,0x49,0x49,0x49,0x31], 'T': [0x01,0x01,0x7F,0x01,0x01],
        'U': [0x3F,0x40,0x40,0x40,0x3F], 'V': [0x1F,0x20,0x40,0x20,0x1F],
        'W': [0x3F,0x40,0x30,0x40,0x3F], 'X': [0x63,0x14,0x08,0x14,0x63],
        'Y': [0x07,0x08,0x70,0x08,0x07], 'Z': [0x61,0x51,0x49,0x45,0x43],
        '0': [0x3E,0x51,0x49,0x45,0x3E], '1': [0x00,0x42,0x7F,0x40,0x00],
        '2': [0x42,0x61,0x51,0x49,0x46], '3': [0x21,0x41,0x45,0x4B,0x31],
        '4': [0x18,0x14,0x12,0x7F,0x10], '5': [0x27,0x45,0x45,0x45,0x39],
        '6': [0x3C,0x4A,0x49,0x49,0x30], '7': [0x01,0x71,0x09,0x05,0x03],
        '8': [0x36,0x49,0x49,0x49,0x36], '9': [0x06,0x49,0x49,0x29,0x1E],
        ' ': [0x00,0x00,0x00,0x00,0x00], '.': [0x00,0x60,0x60,0x00,0x00],
        '-': [0x08,0x08,0x08,0x08,0x08], '+': [0x08,0x08,0x3E,0x08,0x08],
        '/': [0x20,0x10,0x08,0x04,0x02], ':': [0x00,0x36,0x36,0x00,0x00],
        '!': [0x00,0x00,0x5F,0x00,0x00], '?': [0x02,0x01,0x51,0x09,0x06],
        ',': [0x00,0x80,0x60,0x00,0x00], '|': [0x00,0x00,0x7F,0x00,0x00],
        '(': [0x00,0x1C,0x22,0x41,0x00], ')': [0x00,0x41,0x22,0x1C,0x00],
        "'": [0x00,0x00,0x07,0x00,0x00],
    }
    glyph = FONT.get(char.upper(), FONT[' '])
    for col in range(5):
        for row in range(7):
            if glyph[col] & (1 << row):
                for sy in range(scale):
                    for sx in range(scale):
                        px = x + col * scale + sx
                        py = y + row * scale + sy
                        if 0 <= px < WIDTH and 0 <= py < HEIGHT:
                            pixels[py * WIDTH + px] = (r, g, b)

def draw_text(pixels, x, y, text, r, g, b, scale=1):
    """Draw text string."""
    for i, ch in enumerate(text):
        draw_char(pixels, x + i * (6 * scale), y, ch, r, g, b, scale)

def draw_text_centered(pixels, y, text, r, g, b, scale=1):
    """Draw centered text."""
    text_width = len(text) * 6 * scale
    x = (WIDTH - text_width) // 2
    draw_text(pixels, x, y, text, r, g, b, scale)

def create_title_card(title, subtitle="", bg=(16, 16, 32)):
    """Create a title card frame."""
    pixels = [bg] * (WIDTH * HEIGHT)
    
    # Draw horizontal accent line
    line_y = HEIGHT // 2 - 60
    for x in range(200, WIDTH - 200):
        pixels[line_y * WIDTH + x] = (200, 0, 0)
    
    # Title (large, red)
    draw_text_centered(pixels, HEIGHT // 2 - 40, title, 220, 40, 40, 4)
    
    # Subtitle (smaller, gray)
    if subtitle:
        draw_text_centered(pixels, HEIGHT // 2 + 30, subtitle, 160, 160, 160, 2)
    
    # Bottom accent line
    line_y2 = HEIGHT // 2 + 70
    for x in range(200, WIDTH - 200):
        pixels[line_y2 * WIDTH + x] = (200, 0, 0)
    
    return pixels

def create_intro_card():
    """Create the intro/title card."""
    pixels = [(8, 8, 20)] * (WIDTH * HEIGHT)
    
    # Big title
    draw_text_centered(pixels, 200, "TOARUOS-ARNOLD", 220, 30, 30, 6)
    
    # Subtitle
    draw_text_centered(pixels, 320, "A DESKTOP OS WRITTEN IN ARNOLDC", 180, 180, 180, 2)
    
    # Version
    draw_text_centered(pixels, 380, "V4.0  -  213KB ELF  -  185 FUNCTIONS", 120, 120, 120, 2)
    
    # Tagline
    draw_text_centered(pixels, 480, "COME WITH ME IF YOU WANT TO BOOT", 200, 50, 50, 3)
    
    # Bottom credits
    draw_text_centered(pixels, 620, "BUILT BY CUPER Y. ASHRAF", 100, 100, 100, 2)
    draw_text_centered(pixels, 660, "JANUARY 2026", 80, 80, 80, 2)
    
    return pixels

def create_outro_card():
    """Create the outro card."""
    pixels = [(8, 8, 20)] * (WIDTH * HEIGHT)
    
    draw_text_centered(pixels, 250, "I'LL BE BACK.", 220, 30, 30, 6)
    
    draw_text_centered(pixels, 400, "75 COMMITS  |  213KB KERNEL  |  36 COMMANDS", 140, 140, 140, 2)
    draw_text_centered(pixels, 440, "5 GAMES  |  6 APPS  |  TCP/IP NETWORKING", 140, 140, 140, 2)
    draw_text_centered(pixels, 480, "ALL IN ARNOLDC  +  X86 ASSEMBLY", 140, 140, 140, 2)
    
    draw_text_centered(pixels, 560, "GITHUB.COM/CUUPER22/TOARUOS-ARNOLD", 100, 100, 160, 2)
    
    return pixels

def save_frame(pixels, frame_num):
    """Save a frame to the output directory."""
    path = os.path.join(OUTPUT_DIR, f"frame_{frame_num:04d}.ppm")
    create_ppm(path, pixels)
    return frame_num + 1

def copy_frame(src_path, frame_num):
    """Copy an existing frame to the output sequence."""
    dst_path = os.path.join(OUTPUT_DIR, f"frame_{frame_num:04d}.ppm")
    shutil.copy2(src_path, dst_path)
    return frame_num + 1

def add_title(frame_num, title, subtitle="", duration_s=2):
    """Add a title card for given duration."""
    pixels = create_title_card(title, subtitle)
    for _ in range(int(duration_s * FPS)):
        frame_num = save_frame(pixels, frame_num)
    return frame_num

def add_source_frames(frame_num, start, end, hold_each=1):
    """Add source frames with optional holding (repeat each frame)."""
    for i in range(start, end + 1):
        src = os.path.join(FRAMES_DIR, f"frame_{i:04d}.ppm")
        if os.path.exists(src):
            for _ in range(hold_each):
                frame_num = copy_frame(src, frame_num)
    return frame_num

def main():
    # Clean output
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    frame = 1
    
    # === INTRO (3s) ===
    print("Creating intro...")
    intro = create_intro_card()
    for _ in range(3 * FPS):
        frame = save_frame(intro, frame)
    
    # === SCENE 1: Boot Sequence ===
    print("Scene 1: Boot...")
    frame = add_title(frame, "BOOT SEQUENCE", "SPLASH + LOGIN + DESKTOP", 2)
    frame = add_source_frames(frame, 1, 3, hold_each=3)  # boot frames, hold longer
    
    # === SCENE 2: Desktop ===
    frame = add_title(frame, "THE DESKTOP", "ICONS  TASKBAR  CLOCK  WALLPAPER", 2)
    frame = add_source_frames(frame, 4, 8, hold_each=2)
    
    # === SCENE 3: Terminal ===
    print("Scene 3: Terminal...")
    frame = add_title(frame, "TERMINAL", "35 COMMANDS  -  FULL SHELL", 2)
    frame = add_source_frames(frame, 9, 17, hold_each=3)  # terminal commands, hold to read
    
    # === SCENE 4: Snake ===
    print("Scene 4: Snake...")
    frame = add_title(frame, "SNAKE", "WINDOWED GAME", 1.5)
    frame = add_source_frames(frame, 18, 25, hold_each=2)
    
    # === SCENE 5: Pong ===
    print("Scene 5: Pong...")
    frame = add_title(frame, "PONG", "WINDOWED GAME", 1.5)
    frame = add_source_frames(frame, 26, 31, hold_each=2)
    
    # === SCENE 6: Breakout ===
    print("Scene 6: Breakout...")
    frame = add_title(frame, "BREAKOUT", "WINDOWED GAME", 1.5)
    frame = add_source_frames(frame, 32, 37, hold_each=2)
    
    # === SCENE 7: Chopper ===
    print("Scene 7: Chopper...")
    frame = add_title(frame, "CHOPPER", "WINDOWED GAME", 1.5)
    frame = add_source_frames(frame, 38, 43, hold_each=2)
    
    # === SCENE 8: Skynet ===
    print("Scene 8: Skynet...")
    frame = add_title(frame, "SKYNET DEFENSE", "TOWER DEFENSE GAME", 1.5)
    frame = add_source_frames(frame, 44, 49, hold_each=2)
    
    # === SCENE 9: Calculator ===
    print("Scene 9: Calculator...")
    frame = add_title(frame, "DESKTOP APPS", "CALCULATOR  SETTINGS  EDITOR  FILES", 2)
    frame = add_source_frames(frame, 50, 51, hold_each=3)
    
    # === SCENE 10: Settings ===
    print("Scene 10: Settings...")
    frame = add_source_frames(frame, 52, 55, hold_each=3)
    
    # === SCENE 11: Editor ===
    print("Scene 11: Editor...")
    frame = add_source_frames(frame, 56, 57, hold_each=3)
    
    # === SCENE 12: File Manager ===
    print("Scene 12: File Manager...")
    frame = add_source_frames(frame, 58, 58, hold_each=3)
    
    # === SCENE 13: Final Desktop ===
    print("Scene 13: Final Desktop...")
    frame = add_title(frame, "NETWORKING", "TCP/IP  -  HTTP  -  WGET  -  PING", 2)
    # Re-use ifconfig/ping frames from terminal
    frame = add_source_frames(frame, 15, 16, hold_each=4)
    
    # Final desktop
    frame = add_source_frames(frame, 59, 63, hold_each=2)
    
    # === OUTRO (3s) ===
    print("Creating outro...")
    outro = create_outro_card()
    for _ in range(3 * FPS):
        frame = save_frame(outro, frame)
    
    total_frames = frame - 1
    duration = total_frames / FPS
    print(f"\nTotal frames: {total_frames}")
    print(f"Duration: {duration:.1f}s ({duration/60:.1f}min)")
    
    # Assemble video
    print("\nAssembling video with ffmpeg...")
    output_video = os.path.join(PROJECT_ROOT, "build", "demo.mp4")
    cmd = [
        "ffmpeg", "-y",
        "-framerate", str(FPS),
        "-i", os.path.join(OUTPUT_DIR, "frame_%04d.ppm"),
        "-vf", "scale=1024:768:flags=neighbor",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-crf", "18",
        "-preset", "slow",
        output_video
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if os.path.exists(output_video):
        size = os.path.getsize(output_video)
        print(f"\n=== Demo video created ===")
        print(f"  File: {output_video}")
        print(f"  Size: {size // 1024}KB")
        print(f"  Duration: {duration:.1f}s")
        print(f"  Frames: {total_frames}")
    else:
        print("ERROR: Video creation failed!")
        print(result.stderr[-500:] if result.stderr else "No error output")

if __name__ == "__main__":
    main()
