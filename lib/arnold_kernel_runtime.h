/*
 * ============================================================================
 * ARNOLD KERNEL RUNTIME
 * "GET TO THE CHOPPER" - Bare-metal support for ArnoldC kernels
 * ============================================================================
 * 
 * This runtime provides the necessary functions for ArnoldC code to run
 * directly on hardware without any operating system support.
 * 
 * "I'LL BE BACK" - And so will your kernel after every reboot
 * ============================================================================
 */

#ifndef ARNOLD_KERNEL_RUNTIME_H
#define ARNOLD_KERNEL_RUNTIME_H

/* ============================================================================
 * TYPE DEFINITIONS - "THIS IS WHAT I AM"
 * ============================================================================ */

typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

typedef signed char        int8_t;
typedef signed short       int16_t;
typedef signed int         int32_t;
typedef signed long long   int64_t;

typedef uint32_t           size_t;
typedef int32_t            ssize_t;
typedef uint32_t           uintptr_t;

#define NULL ((void*)0)

#define true  1
#define false 0
typedef int bool;

/* ============================================================================
 * MULTIBOOT STRUCTURES - "LISTEN TO ME VERY CAREFULLY, GRUB"
 * ============================================================================ */

typedef struct {
    uint32_t flags;
    uint32_t mem_lower;
    uint32_t mem_upper;
    uint32_t boot_device;
    uint32_t cmdline;
    uint32_t mods_count;
    uint32_t mods_addr;
    uint32_t syms[4];
    uint32_t mmap_length;
    uint32_t mmap_addr;
    uint32_t drives_length;
    uint32_t drives_addr;
    uint32_t config_table;
    uint32_t boot_loader_name;
    uint32_t apm_table;
    uint32_t vbe_control_info;
    uint32_t vbe_mode_info;
    uint16_t vbe_mode;
    uint16_t vbe_interface_seg;
    uint16_t vbe_interface_off;
    uint16_t vbe_interface_len;
    uint64_t framebuffer_addr;
    uint32_t framebuffer_pitch;
    uint32_t framebuffer_width;
    uint32_t framebuffer_height;
    uint8_t  framebuffer_bpp;
    uint8_t  framebuffer_type;
    uint8_t  color_info[6];
} __attribute__((packed)) multiboot_info_t;

#define MULTIBOOT_FLAG_FRAMEBUFFER (1 << 12)

/* ============================================================================
 * FRAMEBUFFER STRUCTURES - "SEE YOU AT THE PARTY"
 * ============================================================================ */

typedef struct {
    uint32_t address;
    uint32_t pitch;
    uint32_t width;
    uint32_t height;
    uint32_t bpp;
    uint32_t bytesPerPixel;
} FramebufferInfo;

/* ============================================================================
 * PORT I/O - "TALK TO THE PORT" / "LISTEN TO THE PORT"
 * Defined in assembly (multiboot.asm)
 * ============================================================================ */

extern void outb(uint16_t port, uint8_t value);
extern uint8_t inb(uint16_t port);
extern void outw(uint16_t port, uint16_t value);
extern uint16_t inw(uint16_t port);
extern void outl(uint16_t port, uint32_t value);
extern uint32_t inl(uint16_t port);

/* ============================================================================
 * I/O WAIT - "WAIT A MOMENT"
 * ============================================================================ */

static inline void io_wait(void) {
    outb(0x80, 0);
}

/* ============================================================================
 * MEMORY OPERATIONS - "I NEED YOUR MEMORY"
 * ============================================================================ */

static inline void* arnold_memset(void* dest, int val, size_t count) {
    uint8_t* d = (uint8_t*)dest;
    while (count--) {
        *d++ = (uint8_t)val;
    }
    return dest;
}

static inline void* arnold_memcpy(void* dest, const void* src, size_t count) {
    uint8_t* d = (uint8_t*)dest;
    const uint8_t* s = (const uint8_t*)src;
    while (count--) {
        *d++ = *s++;
    }
    return dest;
}

/* ============================================================================
 * SERIAL PORT DEBUG OUTPUT - "TALK TO THE HAND"
 * Uses COM1 (0x3F8) for debug output
 * ============================================================================ */

#define SERIAL_PORT 0x3F8

static inline int serial_is_transmit_empty(void) {
    return inb(SERIAL_PORT + 5) & 0x20;
}

static inline void serial_putchar(char c) {
    while (!serial_is_transmit_empty());
    outb(SERIAL_PORT, c);
}

static inline void serial_init(void) {
    outb(SERIAL_PORT + 1, 0x00);  /* Disable interrupts */
    outb(SERIAL_PORT + 3, 0x80);  /* Enable DLAB */
    outb(SERIAL_PORT + 0, 0x03);  /* Set divisor to 3 (38400 baud) */
    outb(SERIAL_PORT + 1, 0x00);
    outb(SERIAL_PORT + 3, 0x03);  /* 8 bits, no parity, one stop bit */
    outb(SERIAL_PORT + 2, 0xC7);  /* Enable FIFO */
    outb(SERIAL_PORT + 4, 0x0B);  /* IRQs enabled, RTS/DSR set */
}

static inline void arnold_print(const char* str) {
    while (*str) {
        serial_putchar(*str++);
    }
}

static inline void arnold_print_hex(uint32_t value) {
    const char hex[] = "0123456789ABCDEF";
    arnold_print("0x");
    for (int i = 28; i >= 0; i -= 4) {
        serial_putchar(hex[(value >> i) & 0xF]);
    }
}

static inline void arnold_print_int(int value) {
    if (value < 0) {
        serial_putchar('-');
        value = -value;
    }
    if (value == 0) {
        serial_putchar('0');
        return;
    }
    
    char buf[12];
    int i = 0;
    while (value > 0) {
        buf[i++] = '0' + (value % 10);
        value /= 10;
    }
    while (i > 0) {
        serial_putchar(buf[--i]);
    }
}

/* ============================================================================
 * PANIC - "YOU HAVE BEEN TERMINATED"
 * ============================================================================ */

static inline void arnold_panic(const char* message) {
    arnold_print("\n\n*** KERNEL PANIC - YOU HAVE BEEN TERMINATED ***\n");
    arnold_print("Message: ");
    arnold_print(message);
    arnold_print("\n\nI'LL BE BACK... after you fix this.\n");
    
    /* Halt forever */
    for (;;) {
        __asm__ volatile ("cli; hlt");
    }
}

/* ============================================================================
 * VGA TEXT MODE (fallback) - "TALK TO THE HAND"
 * ============================================================================ */

#define VGA_WIDTH  80
#define VGA_HEIGHT 25
#define VGA_MEMORY 0xB8000

static uint16_t* vga_buffer = (uint16_t*)VGA_MEMORY;
static int vga_row = 0;
static int vga_col = 0;

static inline uint16_t vga_entry(char c, uint8_t color) {
    return (uint16_t)c | ((uint16_t)color << 8);
}

static inline void vga_putchar(char c, uint8_t color) {
    if (c == '\n') {
        vga_col = 0;
        vga_row++;
    } else {
        vga_buffer[vga_row * VGA_WIDTH + vga_col] = vga_entry(c, color);
        vga_col++;
    }
    if (vga_col >= VGA_WIDTH) {
        vga_col = 0;
        vga_row++;
    }
    if (vga_row >= VGA_HEIGHT) {
        vga_row = 0;
    }
}

static inline void vga_print(const char* str, uint8_t color) {
    while (*str) {
        vga_putchar(*str++, color);
    }
}

static inline void vga_clear(uint8_t color) {
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = vga_entry(' ', color);
    }
    vga_row = 0;
    vga_col = 0;
}

/* ============================================================================
 * ENTRY POINT DECLARATION
 * ============================================================================ */

extern void arnold_main(void);

#endif /* ARNOLD_KERNEL_RUNTIME_H */
