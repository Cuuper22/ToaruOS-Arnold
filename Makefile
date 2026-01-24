# ============================================================================
# TOARUOS-ARNOLD MAKEFILE
# "GET TO THE CHOPPER" - Build system for the most muscular kernel
# ============================================================================
#
# "I need your compiler, your linker, and your QEMU."
#   - The Makefile
#
# Usage:
#   make          - Build the kernel ("DO IT NOW")
#   make run      - Run in QEMU ("GET YOUR ASS TO MARS")
#   make debug    - Run with GDB support ("I'LL BE BACK... with a debugger")
#   make clean    - Clean build files ("ERASED FROM EXISTENCE")
#   make iso      - Create bootable ISO ("COME WITH ME IF YOU WANT TO BOOT")
#
# ============================================================================

# Cross-compiler prefix - "I NEED YOUR CLOTHES YOUR BOOTS AND YOUR MOTORCYCLE"
CROSS = i686-elf-

# Tools - "THIS IS WHAT I'M MADE OF"
AS = nasm
LD = $(CROSS)ld
OBJCOPY = $(CROSS)objcopy

# Fallback to system tools if cross-compiler not found
ifeq ($(shell which $(LD) 2>/dev/null),)
    LD = ld
    OBJCOPY = objcopy
    $(warning "Cross-linker not found! Using system ld. May not work for bare-metal.")
endif

# Directories - "LINE THEM UP"
BOOT_DIR = boot
KERNEL_DIR = kernel
BUILD_DIR = build
ISO_DIR = isodir
GEN_DIR = $(BUILD_DIR)/gen

# Output - "CONSIDER THAT A DIVORCE from ordinary filenames"
KERNEL_BIN = $(BUILD_DIR)/toaruos-arnold.bin
KERNEL_ELF = $(BUILD_DIR)/toaruos-arnold.elf
ISO_FILE = $(BUILD_DIR)/toaruos-arnold.iso

# Source files - "HEY CHRISTMAS TREE"
# Use KERNEL_VERSION to select kernel (default: v3)
KERNEL_VERSION ?= v3
ASM_SOURCES = $(BOOT_DIR)/multiboot.asm

ifeq ($(KERNEL_VERSION),v3)
    ARNOLD_SRC = $(KERNEL_DIR)/kernel_v3.arnoldc
else ifeq ($(KERNEL_VERSION),v2)
    ARNOLD_SRC = $(KERNEL_DIR)/kernel_v2.arnoldc
else
    ARNOLD_SRC = $(KERNEL_DIR)/kernel.arnoldc
endif

ARNOLD_GEN_SRC = $(GEN_DIR)/kernel.arnoldc
ARNOLD_ASM = $(GEN_DIR)/kernel.asm

# Object files - "GET TO THE CHOPPER"
ASM_OBJECTS = $(BUILD_DIR)/multiboot.o
KERNEL_OBJECT = $(BUILD_DIR)/kernel.o
OBJECTS = $(ASM_OBJECTS) $(KERNEL_OBJECT)

# ArnoldC compiler - "IT'S SHOWTIME"
ARNOLDC ?= arnoldc
ARNOLDC_JAR ?= ../ArnoldC-Native/target/scala-2.13/ArnoldC-Native.jar

ifeq ($(shell which $(ARNOLDC) 2>/dev/null),)
    ARNOLDC = java -jar $(ARNOLDC_JAR)
endif

# Assembler flags - "SPEAK TO THE MACHINE"
ASFLAGS = -f elf32

# Linker flags - "JOIN THEM TOGETHER"
LDFLAGS = -m elf_i386 \
          -T linker.ld \
          -nostdlib

# QEMU flags - "GET YOUR ASS TO MARS"
QEMU = qemu-system-i386
QEMU_FLAGS = -m 128M \
             -serial stdio \
             -vga std

# ============================================================================
# TARGETS - "DO IT NOW"
# ============================================================================

.PHONY: all clean run debug iso directories

# Default target - "IT'S SHOWTIME"
all: directories $(KERNEL_BIN)
	@echo ""
	@echo "============================================================================"
	@echo "  BUILD COMPLETE - I'LL BE BACK"
	@echo "============================================================================"
	@echo "  Kernel binary: $(KERNEL_BIN)"
	@echo "  Size: $$(stat -f%z $(KERNEL_BIN) 2>/dev/null || stat -c%s $(KERNEL_BIN)) bytes"
	@echo ""
	@echo "  Run with: make run"
	@echo "  Debug with: make debug"
	@echo "============================================================================"
	@echo ""

# Create directories - "I NEED YOUR MEMORY"
directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(GEN_DIR)
	@mkdir -p $(ISO_DIR)/boot/grub

# Link kernel - "CRUSH THEM TOGETHER into one binary"
$(KERNEL_ELF): $(OBJECTS)
	@echo "[LD  ] Linking kernel - GET TO THE CHOPPER"
	$(LD) $(LDFLAGS) -o $@ $^

# Create flat binary - "MAKE IT A binary"
$(KERNEL_BIN): $(KERNEL_ELF)
	@echo "[BIN ] Creating binary - CONSIDER THAT A DIVORCE from ELF"
	$(OBJCOPY) -O binary $< $@

# Compile assembly - "SPEAK TO THE MACHINE"
$(BUILD_DIR)/multiboot.o: $(BOOT_DIR)/multiboot.asm
	@echo "[ASM ] Assembling bootloader - LISTEN TO ME VERY CAREFULLY"
	$(AS) $(ASFLAGS) -o $@ $<

# Generate ArnoldC source in build dir
$(ARNOLD_GEN_SRC): $(ARNOLD_SRC) | directories
	@echo "[ARN ] Copying ArnoldC source - I'LL BE BACK"
	cp $< $@

# Generate ArnoldC assembly
# External declarations for v3 kernel (includes all new functions)
EXTERNS_V3 = extern get_fb_addr\nextern get_fb_pitch\nextern get_fb_width\nextern get_fb_height\n\
extern get_timer_ticks\nextern sleep_ticks\n\
extern get_mouse_x\nextern get_mouse_y\nextern get_mouse_buttons\n\
extern speaker_on\nextern speaker_off\nextern speaker_set_frequency

# External declarations for v1/v2 kernel
EXTERNS_V2 = extern get_fb_addr\nextern get_fb_pitch\nextern get_fb_width\nextern get_fb_height

$(ARNOLD_ASM): $(ARNOLD_GEN_SRC)
	@echo "[ARN ] Generating kernel ASM - IT'S SHOWTIME ($(KERNEL_VERSION))"
	$(ARNOLDC) -asm $(ARNOLD_GEN_SRC)
	@echo "[ARN ] Adding extern declarations for bootloader functions"
ifeq ($(KERNEL_VERSION),v3)
	@sed -i '5a $(EXTERNS_V3)' $(ARNOLD_ASM)
else
	@sed -i '5a $(EXTERNS_V2)' $(ARNOLD_ASM)
endif

# Assemble ArnoldC kernel
$(BUILD_DIR)/kernel.o: $(ARNOLD_ASM)
	@echo "[ASM ] Assembling ArnoldC kernel - THE TERMINATOR AWAKENS"
	$(AS) $(ASFLAGS) -o $@ $<

# ============================================================================
# RUN TARGETS - "GET YOUR ASS TO MARS"
# ============================================================================

# Run in QEMU - "DO IT NOW"
run: all
	@echo ""
	@echo "============================================================================"
	@echo "  LAUNCHING QEMU - GET YOUR ASS TO MARS"
	@echo "============================================================================"
	@echo ""
	$(QEMU) $(QEMU_FLAGS) -kernel $(KERNEL_ELF)

# Run with GDB support - "I'LL BE BACK... with a debugger"
debug: all
	@echo ""
	@echo "============================================================================"
	@echo "  LAUNCHING QEMU WITH GDB - STICK AROUND"
	@echo "============================================================================"
	@echo "  Connect GDB with: target remote localhost:1234"
	@echo ""
	$(QEMU) $(QEMU_FLAGS) -kernel $(KERNEL_ELF) -s -S

# ============================================================================
# ISO TARGET - "COME WITH ME IF YOU WANT TO BOOT"
# ============================================================================

# Create GRUB config
$(ISO_DIR)/boot/grub/grub.cfg: directories
	@echo "[CFG ] Creating GRUB config - LISTEN TO ME VERY CAREFULLY, GRUB"
	@echo 'set timeout=3' > $@
	@echo 'set default=0' >> $@
	@echo '' >> $@
	@echo 'menuentry "ToaruOS-Arnold - COME WITH ME IF YOU WANT TO BOOT" {' >> $@
	@echo '    multiboot /boot/toaruos-arnold.elf' >> $@
	@echo '    boot' >> $@
	@echo '}' >> $@

# Create bootable ISO
iso: all $(ISO_DIR)/boot/grub/grub.cfg
	@echo "[ISO ] Creating bootable ISO - THE TERMINATOR DISC"
	cp $(KERNEL_ELF) $(ISO_DIR)/boot/toaruos-arnold.elf
	grub-mkrescue -o $(ISO_FILE) $(ISO_DIR) 2>/dev/null || \
		grub2-mkrescue -o $(ISO_FILE) $(ISO_DIR) 2>/dev/null || \
		echo "grub-mkrescue not found! Install GRUB tools."
	@echo ""
	@echo "============================================================================"
	@echo "  ISO CREATED - $(ISO_FILE)"
	@echo "============================================================================"
	@echo "  Boot with: qemu-system-i386 -cdrom $(ISO_FILE)"
	@echo "  Or burn to CD/USB and boot real hardware!"
	@echo "============================================================================"

# Run ISO in QEMU
run-iso: iso
	@echo "[QEMU] Booting ISO - I'LL BE BACK"
	$(QEMU) $(QEMU_FLAGS) -cdrom $(ISO_FILE)

# ============================================================================
# CLEAN TARGET - "ERASED FROM EXISTENCE"
# ============================================================================

clean:
	@echo "[CLEAN] Cleaning build files - YOU'RE LUGGAGE"
	rm -rf $(BUILD_DIR)
	rm -rf $(ISO_DIR)
	@echo "ERASED FROM EXISTENCE"

# ============================================================================
# HELP - "TALK TO THE HAND"
# ============================================================================

help:
	@echo ""
	@echo "============================================================================"
	@echo "  TOARUOS-ARNOLD BUILD SYSTEM"
	@echo "  'COME WITH ME IF YOU WANT TO BUILD'"
	@echo "============================================================================"
	@echo ""
	@echo "  make          - Build kernel (IT'S SHOWTIME)"
	@echo "  make run      - Run in QEMU (GET YOUR ASS TO MARS)"
	@echo "  make debug    - Debug with GDB (I'LL BE BACK)"
	@echo "  make iso      - Create bootable ISO (THE TERMINATOR DISC)"
	@echo "  make run-iso  - Boot ISO in QEMU"
	@echo "  make clean    - Clean build (ERASED FROM EXISTENCE)"
	@echo "  make help     - Show this help (TALK TO THE HAND)"
	@echo ""
	@echo "============================================================================"
	@echo "  REQUIREMENTS:"
	@echo "============================================================================"
	@echo "  - ArnoldC-Native compiler (arnoldc or ArnoldC-Native.jar)"
	@echo "  - NASM assembler"
	@echo "  - QEMU for testing"
	@echo "  - GRUB tools for ISO creation"
	@echo ""
	@echo "  \"I'll be back... after you install the dependencies.\""
	@echo ""

# ============================================================================
# "HASTA LA VISTA, BABY" - End of Makefile
# ============================================================================
