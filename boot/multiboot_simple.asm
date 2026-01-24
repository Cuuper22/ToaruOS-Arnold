; ============================================================================
; TOARUOS-ARNOLD BOOTLOADER
; "COME WITH ME IF YOU WANT TO BOOT"
; ============================================================================
; Multiboot-compliant entry point for the ArnoldC kernel
; Because even The Terminator needs a proper boot sequence
; ============================================================================

BITS 32

; Multiboot constants - "I'LL BE BACK... after GRUB loads me"
MULTIBOOT_MAGIC         equ 0x1BADB002
MULTIBOOT_PAGE_ALIGN    equ 1 << 0
MULTIBOOT_MEMORY_INFO   equ 1 << 1
MULTIBOOT_VIDEO_MODE    equ 1 << 2
MULTIBOOT_FLAGS         equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO | MULTIBOOT_VIDEO_MODE
MULTIBOOT_CHECKSUM      equ -(MULTIBOOT_MAGIC + MULTIBOOT_FLAGS)

; Video mode request - "I NEED YOUR FRAMEBUFFER"
VIDEO_MODE_TYPE         equ 0           ; 0 = linear graphics mode
VIDEO_WIDTH             equ 1024
VIDEO_HEIGHT            equ 768
VIDEO_DEPTH             equ 32

; Bochs VBE DISPI interface ports - "TALK TO THE VGA"
VBE_DISPI_IOPORT_INDEX  equ 0x01CE
VBE_DISPI_IOPORT_DATA   equ 0x01CF

; VBE DISPI index values
VBE_DISPI_INDEX_ID      equ 0x0
VBE_DISPI_INDEX_XRES    equ 0x1
VBE_DISPI_INDEX_YRES    equ 0x2
VBE_DISPI_INDEX_BPP     equ 0x3
VBE_DISPI_INDEX_ENABLE  equ 0x4
VBE_DISPI_INDEX_BANK    equ 0x5
VBE_DISPI_INDEX_VIRT_WIDTH  equ 0x6
VBE_DISPI_INDEX_VIRT_HEIGHT equ 0x7

; VBE DISPI enable flags
VBE_DISPI_DISABLED      equ 0x00
VBE_DISPI_ENABLED       equ 0x01
VBE_DISPI_LFB_ENABLED   equ 0x40

; Bochs VGA framebuffer address (QEMU's std vga uses 0xFD000000)
BOCHS_VGA_LFB_ADDR      equ 0xFD000000

; ============================================================================
; MULTIBOOT HEADER - "LISTEN TO ME VERY CAREFULLY, GRUB"
; ============================================================================
section .multiboot
align 4
multiboot_header:
    dd MULTIBOOT_MAGIC                  ; "IT'S SHOWTIME"
    dd MULTIBOOT_FLAGS                  ; "HERE IS MY INVITATION"
    dd MULTIBOOT_CHECKSUM               ; "YOU SET US UP"
    dd 0                                ; header_addr (unused)
    dd 0                                ; load_addr (unused)
    dd 0                                ; load_end_addr (unused)
    dd 0                                ; bss_end_addr (unused)
    dd 0                                ; entry_addr (unused)
    dd VIDEO_MODE_TYPE                  ; mode_type
    dd VIDEO_WIDTH                      ; width
    dd VIDEO_HEIGHT                     ; height
    dd VIDEO_DEPTH                      ; depth

; ============================================================================
; BSS SECTION - "I NEED YOUR MEMORY"
; ============================================================================
section .bss
align 16
stack_bottom:
    resb 16384                          ; 16 KB stack - "GET TO THE CHOPPER"
stack_top:

; Global variables for multiboot info
global multiboot_magic_value
global multiboot_info_ptr
global fb_addr
global fb_pitch
global fb_width
global fb_height
global fb_bpp

multiboot_magic_value:
    resd 1
multiboot_info_ptr:
    resd 1
fb_addr:
    resd 1
fb_pitch:
    resd 1
fb_width:
    resd 1
fb_height:
    resd 1
fb_bpp:
    resd 1

; ============================================================================
; TEXT SECTION - "DO IT NOW"
; ============================================================================
section .text
global _start
extern arnold_main                      ; The ArnoldC kernel entry point

; ============================================================================
; _start - "IT'S SHOWTIME"
; ============================================================================
_start:
    ; "EVERYBODY CHILL" - Disable interrupts
    cli

    ; Save multiboot info - "REMEMBER THESE"
    mov [multiboot_magic_value], eax    ; Magic number
    mov [multiboot_info_ptr], ebx       ; Multiboot info pointer

    ; "GET TO THE CHOPPER" - Set up the stack
    mov esp, stack_top

    ; Extract framebuffer info from multiboot structure
    ; Framebuffer info starts at offset 88 in multiboot_info_t
    mov eax, [ebx + 88]                 ; fb_addr (lower 32 bits)
    mov [fb_addr], eax
    mov eax, [ebx + 92]                 ; fb_pitch
    mov [fb_pitch], eax
    mov eax, [ebx + 96]                 ; fb_width
    mov [fb_width], eax
    mov eax, [ebx + 100]                ; fb_height
    mov [fb_height], eax
    movzx eax, byte [ebx + 104]         ; fb_bpp
    mov [fb_bpp], eax

    ; Fallback: if fb_addr is 0, QEMU didn't provide framebuffer
    ; Set up Bochs VBE graphics mode directly
    cmp dword [fb_addr], 0
    jne .fb_ok
    
    ; "CONFIGURE THE VGA CARD DIRECTLY" - Bochs VBE DISPI interface
    ; Step 1: Disable VBE first
    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_ENABLE
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VBE_DISPI_DISABLED
    out dx, ax
    
    ; Step 2: Set X resolution to 1024
    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_XRES
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VIDEO_WIDTH
    out dx, ax
    
    ; Step 3: Set Y resolution to 768
    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_YRES
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VIDEO_HEIGHT
    out dx, ax
    
    ; Step 4: Set bits per pixel to 32
    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_BPP
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VIDEO_DEPTH
    out dx, ax
    
    ; Step 5: Enable VBE with LFB
    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_ENABLE
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VBE_DISPI_ENABLED | VBE_DISPI_LFB_ENABLED
    out dx, ax
    
    ; Set framebuffer parameters for our manual setup
    mov dword [fb_addr], BOCHS_VGA_LFB_ADDR
    mov dword [fb_pitch], VIDEO_WIDTH * 4   ; 1024 * 4 bytes per pixel
    mov dword [fb_width], VIDEO_WIDTH
    mov dword [fb_height], VIDEO_HEIGHT
    mov dword [fb_bpp], VIDEO_DEPTH
    
.fb_ok:

    ; Push multiboot info for arnold_main
    push ebx                            ; multiboot_info_t*
    push dword [multiboot_magic_value]  ; magic number

    ; "DO IT NOW" - Call the ArnoldC kernel
    call arnold_main

    ; "YOU HAVE BEEN TERMINATED" - Should never reach here
.hang:
    cli
    hlt
    jmp .hang

; ============================================================================
; UTILITY FUNCTIONS - "I'LL BE BACK"
; ============================================================================
global outb
global inb
global outw
global inw
global outl
global inl

; outb(port, value) - "TALK TO THE PORT"
outb:
    mov dx, [esp + 4]                   ; port
    mov al, [esp + 8]                   ; value
    out dx, al
    ret

; inb(port) -> value - "LISTEN TO THE PORT"
inb:
    mov dx, [esp + 4]                   ; port
    xor eax, eax
    in al, dx
    ret

; outw(port, value) - "TALK BIG TO THE PORT"
outw:
    mov dx, [esp + 4]
    mov ax, [esp + 8]
    out dx, ax
    ret

; inw(port) -> value - "LISTEN BIG TO THE PORT"
inw:
    mov dx, [esp + 4]
    xor eax, eax
    in ax, dx
    ret

; outl(port, value) - "TALK HUGE TO THE PORT"
outl:
    mov dx, [esp + 4]
    mov eax, [esp + 8]
    out dx, eax
    ret

; inl(port) -> value - "LISTEN HUGE TO THE PORT"
inl:
    mov dx, [esp + 4]
    in eax, dx
    ret

; ============================================================================
; FRAMEBUFFER GETTERS - "GIVE ME THE FRAMEBUFFER"
; ============================================================================
global get_fb_addr
global get_fb_pitch
global get_fb_width
global get_fb_height

get_fb_addr:
    mov eax, [fb_addr]
    ret

get_fb_pitch:
    mov eax, [fb_pitch]
    ret

get_fb_width:
    mov eax, [fb_width]
    ret

get_fb_height:
    mov eax, [fb_height]
    ret

; ============================================================================
; "HASTA LA VISTA, BABY" - End of bootloader
; ============================================================================
