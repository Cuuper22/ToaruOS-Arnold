; ============================================================================
; TOARUOS-ARNOLD BOOTLOADER V2.0
; "COME WITH ME IF YOU WANT TO BOOT"
; ============================================================================
; Multiboot-compliant entry point for the ArnoldC kernel
; Now with IDT, PIC, Timer, Mouse, and Speaker support!
; Because even The Terminator needs a proper interrupt system
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

; PIC ports - "TALK TO THE INTERRUPT CONTROLLER"
PIC1_COMMAND            equ 0x20
PIC1_DATA               equ 0x21
PIC2_COMMAND            equ 0xA0
PIC2_DATA               equ 0xA1
PIC_EOI                 equ 0x20

; PIT (Timer) ports - "TIME IS ON MY SIDE"
PIT_CHANNEL0            equ 0x40
PIT_CHANNEL1            equ 0x41
PIT_CHANNEL2            equ 0x42
PIT_COMMAND             equ 0x43

; PC Speaker port
SPEAKER_PORT            equ 0x61

; PS/2 Controller ports - "THE MOUSE WILL GUIDE YOU"
PS2_DATA                equ 0x60
PS2_STATUS              equ 0x64
PS2_COMMAND             equ 0x64

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
; DATA SECTION - "I NEED YOUR DATA"
; ============================================================================
section .data
align 4

; IDT Descriptor
idt_descriptor:
    dw idt_end - idt_start - 1          ; Limit
    dd idt_start                        ; Base address

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

; Timer tick counter - "TIME FLIES WHEN YOU'RE TERMINATED"
global timer_ticks
timer_ticks:
    resd 1

; Mouse state - "THE MOUSE IS ALIVE"
global mouse_x
global mouse_y
global mouse_buttons
global mouse_packet_index
global mouse_bytes
mouse_x:
    resd 1
mouse_y:
    resd 1
mouse_buttons:
    resd 1
mouse_packet_index:
    resd 1
mouse_bytes:
    resb 4

; Speaker state
global speaker_enabled
speaker_enabled:
    resd 1

; IDT - 256 entries, 8 bytes each
align 16
idt_start:
    resb 256 * 8
idt_end:

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

    ; Initialize timer ticks
    mov dword [timer_ticks], 0
    
    ; Initialize mouse state
    mov dword [mouse_x], 512            ; Center of 1024
    mov dword [mouse_y], 384            ; Center of 768
    mov dword [mouse_buttons], 0
    mov dword [mouse_packet_index], 0

    ; "REPROGRAM THE PIC" - Remap IRQs to avoid conflicts
    call remap_pic
    
    ; "SET UP THE IDT" - Install interrupt handlers
    call setup_idt
    
    ; "START THE TIMER" - Configure PIT for 100Hz
    call setup_pit
    
    ; "ENABLE THE MOUSE" - Initialize PS/2 mouse
    call setup_mouse
    
    ; Load the IDT
    lidt [idt_descriptor]
    
    ; "LET'S PARTY" - Enable interrupts
    sti

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
; remap_pic - "REPROGRAM THE INTERRUPT CONTROLLER"
; Remaps IRQ 0-7 to INT 32-39, IRQ 8-15 to INT 40-47
; ============================================================================
remap_pic:
    ; Save masks
    in al, PIC1_DATA
    push eax
    in al, PIC2_DATA
    push eax
    
    ; Start initialization sequence (ICW1)
    mov al, 0x11                        ; ICW1: init + ICW4 needed
    out PIC1_COMMAND, al
    call io_wait
    out PIC2_COMMAND, al
    call io_wait
    
    ; Set vector offsets (ICW2)
    mov al, 0x20                        ; IRQ 0-7 -> INT 32-39
    out PIC1_DATA, al
    call io_wait
    mov al, 0x28                        ; IRQ 8-15 -> INT 40-47
    out PIC2_DATA, al
    call io_wait
    
    ; Set up cascading (ICW3)
    mov al, 0x04                        ; IRQ2 has slave
    out PIC1_DATA, al
    call io_wait
    mov al, 0x02                        ; Slave is on IRQ2
    out PIC2_DATA, al
    call io_wait
    
    ; Set 8086 mode (ICW4)
    mov al, 0x01
    out PIC1_DATA, al
    call io_wait
    out PIC2_DATA, al
    call io_wait
    
    ; Restore masks (enable timer IRQ0, keyboard IRQ1, mouse IRQ12)
    mov al, 0xF8                        ; Enable IRQ0, IRQ1, IRQ2 (cascade)
    out PIC1_DATA, al
    mov al, 0xEF                        ; Enable IRQ12 (mouse)
    out PIC2_DATA, al
    
    ret

; ============================================================================
; setup_idt - "SET UP THE INTERRUPT DESCRIPTOR TABLE"
; ============================================================================
setup_idt:
    ; Clear IDT first
    mov edi, idt_start
    xor eax, eax
    mov ecx, 256 * 2                    ; 256 entries * 8 bytes / 4
    rep stosd
    
    ; Install timer handler (IRQ0 -> INT 32)
    mov eax, isr_timer
    mov ebx, 32
    call set_idt_entry
    
    ; Install keyboard handler (IRQ1 -> INT 33)
    mov eax, isr_keyboard
    mov ebx, 33
    call set_idt_entry
    
    ; Install mouse handler (IRQ12 -> INT 44)
    mov eax, isr_mouse
    mov ebx, 44
    call set_idt_entry
    
    ret

; set_idt_entry - Set IDT entry
; EAX = handler address, EBX = interrupt number
set_idt_entry:
    push edi
    
    ; Calculate IDT entry address
    mov edi, idt_start
    shl ebx, 3                          ; Multiply by 8
    add edi, ebx
    
    ; Set low 16 bits of handler
    mov word [edi], ax
    
    ; Set selector (code segment = 0x08)
    mov word [edi + 2], 0x08
    
    ; Set zero byte
    mov byte [edi + 4], 0
    
    ; Set type (0x8E = 32-bit interrupt gate, present)
    mov byte [edi + 5], 0x8E
    
    ; Set high 16 bits of handler
    shr eax, 16
    mov word [edi + 6], ax
    
    pop edi
    ret

; ============================================================================
; setup_pit - "TIME IS ON MY SIDE" - Configure PIT for 100Hz
; ============================================================================
setup_pit:
    ; PIT frequency = 1193182 Hz
    ; Divisor for 100Hz = 1193182 / 100 = 11932 = 0x2E9C
    
    ; Channel 0, lobyte/hibyte, rate generator
    mov al, 0x36                        ; 0011 0110
    out PIT_COMMAND, al
    
    ; Set divisor low byte
    mov al, 0x9C                        ; Low byte of 11932
    out PIT_CHANNEL0, al
    
    ; Set divisor high byte
    mov al, 0x2E                        ; High byte of 11932
    out PIT_CHANNEL0, al
    
    ret

; ============================================================================
; setup_mouse - "THE MOUSE WILL GUIDE YOU"
; ============================================================================
setup_mouse:
    ; Enable auxiliary device (mouse) in PS/2 controller
    call ps2_wait_input
    mov al, 0xA8                        ; Enable auxiliary device
    out PS2_COMMAND, al
    
    ; Enable interrupts on controller
    call ps2_wait_input
    mov al, 0x20                        ; Read controller config
    out PS2_COMMAND, al
    call ps2_wait_output
    in al, PS2_DATA
    or al, 0x02                         ; Enable IRQ12
    push eax
    call ps2_wait_input
    mov al, 0x60                        ; Write controller config
    out PS2_COMMAND, al
    call ps2_wait_input
    pop eax
    out PS2_DATA, al
    
    ; Send "enable data reporting" to mouse
    call ps2_wait_input
    mov al, 0xD4                        ; Send to auxiliary device
    out PS2_COMMAND, al
    call ps2_wait_input
    mov al, 0xF4                        ; Enable data reporting
    out PS2_DATA, al
    
    ; Wait for ACK
    call ps2_wait_output
    in al, PS2_DATA
    
    ret

ps2_wait_input:
    in al, PS2_STATUS
    test al, 0x02
    jnz ps2_wait_input
    ret

ps2_wait_output:
    in al, PS2_STATUS
    test al, 0x01
    jz ps2_wait_output
    ret

; ============================================================================
; INTERRUPT SERVICE ROUTINES - "I'LL BE BACK"
; ============================================================================

; Timer ISR (IRQ0 -> INT 32)
isr_timer:
    pushad
    
    ; Increment tick counter
    inc dword [timer_ticks]
    
    ; Send EOI to PIC
    mov al, PIC_EOI
    out PIC1_COMMAND, al
    
    popad
    iret

; Keyboard ISR (IRQ1 -> INT 33) - Just acknowledge, kernel handles it
isr_keyboard:
    pushad
    
    ; Read scancode to clear the keyboard buffer
    in al, PS2_DATA
    
    ; Send EOI to PIC
    mov al, PIC_EOI
    out PIC1_COMMAND, al
    
    popad
    iret

; Mouse ISR (IRQ12 -> INT 44)
isr_mouse:
    pushad
    
    ; Read mouse byte
    in al, PS2_DATA
    
    ; Get current packet index
    mov ebx, [mouse_packet_index]
    
    ; Store byte in packet buffer
    lea edi, [mouse_bytes]
    mov [edi + ebx], al
    
    ; Increment packet index
    inc ebx
    
    ; Check if we have a complete 3-byte packet
    cmp ebx, 3
    jl .not_complete
    
    ; Process complete packet
    ; Byte 0: buttons and sign bits
    ; Byte 1: X movement
    ; Byte 2: Y movement
    
    ; Get buttons from byte 0
    movzx eax, byte [mouse_bytes]
    and eax, 0x07                       ; Bits 0-2 are buttons
    mov [mouse_buttons], eax
    
    ; Get X movement (signed)
    movsx eax, byte [mouse_bytes + 1]
    add [mouse_x], eax
    
    ; Clamp X to screen bounds
    cmp dword [mouse_x], 0
    jge .x_not_neg
    mov dword [mouse_x], 0
.x_not_neg:
    cmp dword [mouse_x], VIDEO_WIDTH - 1
    jle .x_not_max
    mov dword [mouse_x], VIDEO_WIDTH - 1
.x_not_max:
    
    ; Get Y movement (signed, inverted - mouse Y is opposite screen Y)
    movsx eax, byte [mouse_bytes + 2]
    neg eax
    add [mouse_y], eax
    
    ; Clamp Y to screen bounds
    cmp dword [mouse_y], 0
    jge .y_not_neg
    mov dword [mouse_y], 0
.y_not_neg:
    cmp dword [mouse_y], VIDEO_HEIGHT - 1
    jle .y_not_max
    mov dword [mouse_y], VIDEO_HEIGHT - 1
.y_not_max:
    
    ; Reset packet index
    xor ebx, ebx

.not_complete:
    mov [mouse_packet_index], ebx
    
    ; Send EOI to both PICs (IRQ12 is on slave)
    mov al, PIC_EOI
    out PIC2_COMMAND, al
    out PIC1_COMMAND, al
    
    popad
    iret

; ============================================================================
; io_wait - Small delay for I/O operations
; ============================================================================
io_wait:
    out 0x80, al                        ; Write to unused port
    ret

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
; TIMER FUNCTIONS - "TIME WAITS FOR NO ONE"
; ============================================================================
global get_timer_ticks
global sleep_ticks

get_timer_ticks:
    mov eax, [timer_ticks]
    ret

; sleep_ticks(ticks) - Sleep for specified number of timer ticks
sleep_ticks:
    push ebx
    mov ebx, [esp + 8]                  ; Number of ticks to wait
    mov eax, [timer_ticks]
    add ebx, eax                        ; Target tick count
.wait:
    hlt                                 ; Wait for interrupt
    mov eax, [timer_ticks]
    cmp eax, ebx
    jl .wait
    pop ebx
    ret

; ============================================================================
; MOUSE FUNCTIONS - "THE MOUSE KNOWS ALL"
; ============================================================================
global get_mouse_x
global get_mouse_y
global get_mouse_buttons

get_mouse_x:
    mov eax, [mouse_x]
    ret

get_mouse_y:
    mov eax, [mouse_y]
    ret

get_mouse_buttons:
    mov eax, [mouse_buttons]
    ret

; ============================================================================
; PC SPEAKER FUNCTIONS - "MAKE SOME NOISE"
; ============================================================================
global speaker_on
global speaker_off
global speaker_set_frequency

; speaker_set_frequency(frequency) - Set speaker frequency in Hz
; PIT Channel 2 divisor = 1193182 / frequency
speaker_set_frequency:
    push ebx
    push edx
    
    mov ebx, [esp + 12]                 ; frequency
    
    ; Calculate divisor: 1193182 / frequency
    mov eax, 1193182
    xor edx, edx
    div ebx                             ; EAX = divisor
    
    ; Set up PIT Channel 2 for square wave
    push eax
    mov al, 0xB6                        ; Channel 2, lobyte/hibyte, square wave
    out PIT_COMMAND, al
    pop eax
    
    ; Send divisor
    out PIT_CHANNEL2, al                ; Low byte
    mov al, ah
    out PIT_CHANNEL2, al                ; High byte
    
    pop edx
    pop ebx
    ret

; speaker_on() - Enable the PC speaker
speaker_on:
    in al, SPEAKER_PORT
    or al, 0x03                         ; Enable speaker + PIT gate
    out SPEAKER_PORT, al
    mov dword [speaker_enabled], 1
    ret

; speaker_off() - Disable the PC speaker
speaker_off:
    in al, SPEAKER_PORT
    and al, 0xFC                        ; Disable speaker + PIT gate
    out SPEAKER_PORT, al
    mov dword [speaker_enabled], 0
    ret

; ============================================================================
; "HASTA LA VISTA, BABY" - End of bootloader
; ============================================================================
