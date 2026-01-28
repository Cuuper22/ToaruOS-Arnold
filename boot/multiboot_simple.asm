; ============================================================================
; TOARUOS-ARNOLD BOOTLOADER
; "COME WITH ME IF YOU WANT TO BOOT"
; ============================================================================
; Multiboot entry with PIC remap + keyboard ISR for interrupt-driven input
; ============================================================================

BITS 32

; Multiboot constants
MULTIBOOT_MAGIC         equ 0x1BADB002
MULTIBOOT_PAGE_ALIGN    equ 1 << 0
MULTIBOOT_MEMORY_INFO   equ 1 << 1
MULTIBOOT_VIDEO_MODE    equ 1 << 2
MULTIBOOT_FLAGS         equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO | MULTIBOOT_VIDEO_MODE
MULTIBOOT_CHECKSUM      equ -(MULTIBOOT_MAGIC + MULTIBOOT_FLAGS)

VIDEO_MODE_TYPE         equ 0
VIDEO_WIDTH             equ 1024
VIDEO_HEIGHT            equ 768
VIDEO_DEPTH             equ 32

; Bochs VBE
VBE_DISPI_IOPORT_INDEX  equ 0x01CE
VBE_DISPI_IOPORT_DATA   equ 0x01CF
VBE_DISPI_INDEX_XRES    equ 0x1
VBE_DISPI_INDEX_YRES    equ 0x2
VBE_DISPI_INDEX_BPP     equ 0x3
VBE_DISPI_INDEX_ENABLE  equ 0x4
VBE_DISPI_DISABLED      equ 0x00
VBE_DISPI_ENABLED       equ 0x01
VBE_DISPI_LFB_ENABLED   equ 0x40
BOCHS_VGA_LFB_ADDR      equ 0xFD000000

; PIC ports
PIC1_CMD                equ 0x20
PIC1_DATA               equ 0x21
PIC2_CMD                equ 0xA0
PIC2_DATA               equ 0xA1

; PIT ports
PIT_CHANNEL2            equ 0x42
PIT_COMMAND             equ 0x43

; PC Speaker
SPEAKER_PORT            equ 0x61

; ============================================================================
; MULTIBOOT HEADER
; ============================================================================
section .multiboot
align 4
    dd MULTIBOOT_MAGIC
    dd MULTIBOOT_FLAGS
    dd MULTIBOOT_CHECKSUM
    dd 0, 0, 0, 0, 0
    dd VIDEO_MODE_TYPE
    dd VIDEO_WIDTH
    dd VIDEO_HEIGHT
    dd VIDEO_DEPTH

; ============================================================================
; DATA SECTION - IDT descriptor must be in .data (initialized)
; ============================================================================
section .data
align 4
idt_ptr:
    dw 256 * 8 - 1             ; limit: 256 entries * 8 bytes - 1
    dd idt                      ; base address

; ============================================================================
; BSS SECTION
; ============================================================================
section .bss
align 16
stack_bottom:
    resb 16384
stack_top:

global multiboot_magic_value
global multiboot_info_ptr
global fb_addr
global fb_pitch
global fb_width
global fb_height
global fb_bpp

multiboot_magic_value: resd 1
multiboot_info_ptr:    resd 1
fb_addr:               resd 1
fb_pitch:              resd 1
fb_width:              resd 1
fb_height:             resd 1
fb_bpp:                resd 1

; Timer tick counter for game timing
tick_counter:          resd 1

; Keyboard scancode buffer for ISR
last_scancode:         resd 1

; IDT - 256 entries of 8 bytes each
align 16
idt:
    resb 256 * 8

; ============================================================================
; TEXT SECTION
; ============================================================================
section .text
global _start
extern arnold_main

_start:
    cli
    mov [multiboot_magic_value], eax
    mov [multiboot_info_ptr], ebx
    mov esp, stack_top

    ; Extract framebuffer from multiboot info
    mov eax, [ebx + 88]
    mov [fb_addr], eax
    mov eax, [ebx + 92]
    mov [fb_pitch], eax
    mov eax, [ebx + 96]
    mov [fb_width], eax
    mov eax, [ebx + 100]
    mov [fb_height], eax
    movzx eax, byte [ebx + 104]
    mov [fb_bpp], eax

    ; Bochs VBE fallback
    cmp dword [fb_addr], 0
    jne .fb_ok

    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_ENABLE
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VBE_DISPI_DISABLED
    out dx, ax

    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_XRES
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VIDEO_WIDTH
    out dx, ax

    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_YRES
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VIDEO_HEIGHT
    out dx, ax

    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_BPP
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VIDEO_DEPTH
    out dx, ax

    mov dx, VBE_DISPI_IOPORT_INDEX
    mov ax, VBE_DISPI_INDEX_ENABLE
    out dx, ax
    mov dx, VBE_DISPI_IOPORT_DATA
    mov ax, VBE_DISPI_ENABLED | VBE_DISPI_LFB_ENABLED
    out dx, ax

    mov dword [fb_addr], BOCHS_VGA_LFB_ADDR
    mov dword [fb_pitch], VIDEO_WIDTH * 4
    mov dword [fb_width], VIDEO_WIDTH
    mov dword [fb_height], VIDEO_HEIGHT
    mov dword [fb_bpp], VIDEO_DEPTH

.fb_ok:
    ; Initialize keyboard scancode buffer
    mov dword [last_scancode], 0

    ; ---- Remap PIC ----
    ; ICW1: init + ICW4 needed
    mov al, 0x11
    out PIC1_CMD, al
    out 0x80, al                ; io_wait
    out PIC2_CMD, al
    out 0x80, al

    ; ICW2: PIC1 starts at INT 32, PIC2 at INT 40
    mov al, 32
    out PIC1_DATA, al
    out 0x80, al
    mov al, 40
    out PIC2_DATA, al
    out 0x80, al

    ; ICW3: PIC1 has slave on IRQ2, PIC2 cascade identity 2
    mov al, 4
    out PIC1_DATA, al
    out 0x80, al
    mov al, 2
    out PIC2_DATA, al
    out 0x80, al

    ; ICW4: 8086 mode
    mov al, 1
    out PIC1_DATA, al
    out 0x80, al
    out PIC2_DATA, al
    out 0x80, al

    ; Mask all IRQs except IRQ0 (timer) and IRQ1 (keyboard)
    mov al, 0xFC                ; bit 0,1 clear = IRQ0+IRQ1 enabled
    out PIC1_DATA, al
    mov al, 0xFF                ; mask all on PIC2
    out PIC2_DATA, al

    ; ---- Setup IDT ----
    ; Zero out IDT
    mov edi, idt
    xor eax, eax
    mov ecx, 512                ; 256 * 8 / 4 = 512 dwords
    rep stosd

    ; Install timer ISR at IDT entry 32 (IRQ0 = INT 32)
    mov eax, isr_timer
    mov ebx, idt + 32 * 8
    mov word [ebx], ax
    mov word [ebx + 2], 0x08
    mov byte [ebx + 4], 0
    mov byte [ebx + 5], 0x8E
    shr eax, 16
    mov word [ebx + 6], ax

    ; Install keyboard ISR at IDT entry 33 (IRQ1 = INT 32+1 = 33)
    mov eax, isr_keyboard
    mov ebx, idt + 33 * 8       ; address of IDT entry 33
    mov word [ebx], ax           ; offset low
    mov word [ebx + 2], 0x08    ; code segment selector
    mov byte [ebx + 4], 0       ; reserved
    mov byte [ebx + 5], 0x8E    ; type: 32-bit interrupt gate, present, DPL=0
    shr eax, 16
    mov word [ebx + 6], ax      ; offset high

    ; Install a dummy handler for all other interrupts (to prevent triple fault)
    mov ecx, 0
.install_dummy:
    cmp ecx, 32
    je .skip_32_33
    cmp ecx, 33
    je .skip_32_33               ; skip timer and keyboard entries
    mov eax, isr_dummy
    mov ebx, idt
    lea ebx, [ebx + ecx * 8]
    mov word [ebx], ax
    mov word [ebx + 2], 0x08
    mov byte [ebx + 4], 0
    mov byte [ebx + 5], 0x8E
    shr eax, 16
    mov word [ebx + 6], ax
.skip_32_33:
    inc ecx
    cmp ecx, 256
    jl .install_dummy

    ; Load IDT
    lidt [idt_ptr]

    ; Enable interrupts
    sti

    ; Call kernel
    push dword [multiboot_info_ptr]
    push dword [multiboot_magic_value]
    call arnold_main

.hang:
    cli
    hlt
    jmp .hang

; ============================================================================
; ISR: Timer (IRQ0 -> INT 32)
; ============================================================================
isr_timer:
    pushad
    inc dword [tick_counter]
    ; Send EOI to PIC1
    mov al, 0x20
    out PIC1_CMD, al
    popad
    iret

; ============================================================================
; ISR: Keyboard (IRQ1 -> INT 33)
; ============================================================================
isr_keyboard:
    pushad
    in al, 0x60                 ; read scancode from keyboard
    test al, 0x80               ; release code?
    jnz .release
    movzx eax, al
    mov [last_scancode], eax    ; store press scancode only
.release:
    ; Send EOI to PIC1
    mov al, 0x20
    out PIC1_CMD, al
    popad
    iret

; ============================================================================
; ISR: Dummy (catches all other interrupts)
; ============================================================================
isr_dummy:
    iret

; ============================================================================
; I/O UTILITY FUNCTIONS
; ============================================================================
global outb
global inb
global outw
global inw
global outl
global inl

outb:
    mov dx, [esp + 4]
    mov al, [esp + 8]
    out dx, al
    ret

inb:
    mov dx, [esp + 4]
    xor eax, eax
    in al, dx
    ret

outw:
    mov dx, [esp + 4]
    mov ax, [esp + 8]
    out dx, ax
    ret

inw:
    mov dx, [esp + 4]
    xor eax, eax
    in ax, dx
    ret

outl:
    mov dx, [esp + 4]
    mov eax, [esp + 8]
    out dx, eax
    ret

inl:
    mov dx, [esp + 4]
    in eax, dx
    ret

; ============================================================================
; FRAMEBUFFER GETTERS
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
; get_last_scancode - Return and clear stored scancode from ISR
; ============================================================================
global get_last_scancode
get_last_scancode:
    xor eax, eax
    xchg eax, [last_scancode]   ; atomic read-and-clear
    ret

; ============================================================================
; TIMER FUNCTIONS
; ============================================================================
global get_timer_ticks
global sleep_ticks

get_timer_ticks:
    mov eax, [tick_counter]
    ret

sleep_ticks:
    push ebx
    push ecx
    mov ebx, [esp + 12]
    test ebx, ebx
    jz .done
.outer:
    mov ecx, 50000
.inner:
    nop
    nop
    nop
    nop
    dec ecx
    jnz .inner
    dec ebx
    jnz .outer
.done:
    pop ecx
    pop ebx
    ret

; ============================================================================
; PC SPEAKER FUNCTIONS
; ============================================================================
global speaker_on
global speaker_off
global speaker_set_frequency

speaker_set_frequency:
    push ebx
    push edx
    mov ebx, [esp + 12]
    test ebx, ebx
    jz .skip
    mov eax, 1193182
    xor edx, edx
    div ebx
    push eax
    mov al, 0xB6
    out PIT_COMMAND, al
    pop eax
    out PIT_CHANNEL2, al
    mov al, ah
    out PIT_CHANNEL2, al
.skip:
    pop edx
    pop ebx
    ret

speaker_on:
    in al, SPEAKER_PORT
    or al, 0x03
    out SPEAKER_PORT, al
    ret

speaker_off:
    in al, SPEAKER_PORT
    and al, 0xFC
    out SPEAKER_PORT, al
    ret


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
    movzx eax, al
    mov edx, eax
    shr edx, 4          ; high nibble
    and eax, 0x0F       ; low nibble
    imul edx, 10
    add eax, edx
    ret

; Read RTC minutes (BCD) from CMOS register 0x02
read_rtc_minutes:
    mov al, 0x02
    out 0x70, al
    in al, 0x71
    movzx eax, al
    mov edx, eax
    shr edx, 4
    and eax, 0x0F
    imul edx, 10
    add eax, edx
    ret

; Read RTC seconds (BCD) from CMOS register 0x00
read_rtc_seconds:
    mov al, 0x00
    out 0x70, al
    in al, 0x71
    movzx eax, al
    mov edx, eax
    shr edx, 4
    and eax, 0x0F
    imul edx, 10
    add eax, edx
    ret

; Halt the system (cli + hlt loop)
halt_system:
    cli
.halt_loop:
    hlt
    jmp .halt_loop
; ============================================================================
; "HASTA LA VISTA, BABY"
; ============================================================================
