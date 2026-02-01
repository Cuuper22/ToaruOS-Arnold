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
; NOTE: MULTIBOOT_VIDEO_MODE removed — QEMU multiboot loader doesn't support VBE
; The bootloader sets up Bochs VBE directly via DISPI interface as fallback
MULTIBOOT_FLAGS         equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO
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

    ; === EARLY SERIAL DEBUG (COM1 @ 0x3F8) ===
    ; Initialize COM1: 9600 baud, 8N1
    mov dx, 0x3F9    ; Interrupt Enable Register
    mov al, 0x00
    out dx, al
    mov dx, 0x3FB    ; Line Control Register - DLAB on
    mov al, 0x80
    out dx, al
    mov dx, 0x3F8    ; Divisor low byte (9600 = 12)
    mov al, 0x0C
    out dx, al
    mov dx, 0x3F9    ; Divisor high byte
    mov al, 0x00
    out dx, al
    mov dx, 0x3FB    ; 8 bits, no parity, 1 stop bit
    mov al, 0x03
    out dx, al
    mov dx, 0x3FA    ; FIFO control
    mov al, 0xC7
    out dx, al
    ; Print "BOOT" to serial
    mov dx, 0x3F8
    mov al, 'B'
    out dx, al
    mov al, 'O'
    out dx, al
    mov al, 'O'
    out dx, al
    mov al, 'T'
    out dx, al
    mov al, 10       ; newline
    out dx, al
    ; Also write "BOOT" to VGA text buffer at 0xB8000
    mov dword [0xB8000], 0x0F420F42   ; "BB" white on black
    mov dword [0xB8004], 0x0F4F0F4F   ; "OO"
    mov dword [0xB8008], 0x0F540F54   ; "TT" (close enough)

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
    ; Serial: report Bochs VBE set up
    mov dx, 0x3F8
    mov al, 'V'
    out dx, al
    mov al, 'B'
    out dx, al
    mov al, 'E'
    out dx, al
    mov al, 10
    out dx, al
    
.fb_ok:
    ; Serial: report fb_ok
    mov dx, 0x3F8
    mov al, 'F'
    out dx, al
    mov al, 'B'
    out dx, al
    mov al, 10
    out dx, al

    ; Initialize timer ticks
    mov dword [timer_ticks], 0
    
    ; Initialize mouse state
    mov dword [mouse_x], 512            ; Center of 1024
    mov dword [mouse_y], 384            ; Center of 768
    mov dword [mouse_buttons], 0
    mov dword [mouse_packet_index], 0

    ; Serial: '1' = about to remap PIC
    mov dx, 0x3F8
    mov al, '1'
    out dx, al

    ; "REPROGRAM THE PIC" - Remap IRQs to avoid conflicts
    call remap_pic
    
    ; Serial: '2' = PIC done, about to setup IDT
    mov dx, 0x3F8
    mov al, '2'
    out dx, al

    ; "SET UP THE IDT" - Install interrupt handlers
    call setup_idt
    
    ; Serial: '3' = IDT done, about to setup PIT
    mov dx, 0x3F8
    mov al, '3'
    out dx, al

    ; "START THE TIMER" - Configure PIT for 100Hz
    call setup_pit
    
    ; Serial: '4' = PIT done, about to setup mouse
    mov dx, 0x3F8
    mov al, '4'
    out dx, al

    ; "ENABLE THE MOUSE" - Initialize PS/2 mouse
    call setup_mouse
    
    ; Serial: '5' = mouse done, loading IDT
    mov dx, 0x3F8
    mov al, '5'
    out dx, al

    ; Load the IDT
    lidt [idt_descriptor]
    
    ; Serial: '6' = IDT loaded, enabling interrupts
    mov dx, 0x3F8
    mov al, '6'
    out dx, al

    ; "LET'S PARTY" - Enable interrupts
    sti

    ; Serial: '7' = interrupts enabled
    mov dx, 0x3F8
    mov al, '7'
    out dx, al

    ; Push multiboot info for arnold_main
    push dword [multiboot_info_ptr]     ; multiboot_info_t*
    push dword [multiboot_magic_value]  ; magic number

    ; Serial: 'GO' = about to call ArnoldC kernel
    mov dx, 0x3F8
    mov al, 'G'
    out dx, al
    mov al, 'O'
    out dx, al
    mov al, 10
    out dx, al

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

; Keyboard ISR (IRQ1 -> INT 33) - Store scancode for kernel polling
isr_keyboard:
    pushad
    
    ; Read scancode from keyboard
    in al, PS2_DATA
    
    ; Only store press scancodes (not release)
    test al, 0x80
    jnz .kb_release
    movzx eax, al
    mov [last_scancode], eax
.kb_release:
    
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
; KEYBOARD - "GET LAST SCANCODE" (atomic read-and-clear)
; ============================================================================
; The v2 keyboard ISR just reads and discards the scancode.
; We need to store it so the kernel can poll it.
; For now, we add a get_last_scancode stub that polls port 0x60 directly.
; ============================================================================
global get_last_scancode

section .bss
last_scancode: resd 1

section .text

get_last_scancode:
    xor eax, eax
    xchg eax, [last_scancode]
    ret

; ============================================================================
; RTC (Real-Time Clock) FUNCTIONS
; ============================================================================
global read_rtc_hours
global read_rtc_minutes
global read_rtc_seconds
global halt_system

read_rtc_hours:
    mov al, 0x04
    out 0x70, al
    in al, 0x71
    movzx eax, al
    mov edx, eax
    shr edx, 4
    and eax, 0x0F
    imul edx, 10
    add eax, edx
    ret

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

global read_rtc_day
global read_rtc_month
global read_rtc_year

read_rtc_day:
    mov al, 0x07
    out 0x70, al
    in al, 0x71
    movzx eax, al
    mov edx, eax
    shr edx, 4
    and eax, 0x0F
    imul edx, 10
    add eax, edx
    ret

read_rtc_month:
    mov al, 0x08
    out 0x70, al
    in al, 0x71
    movzx eax, al
    mov edx, eax
    shr edx, 4
    and eax, 0x0F
    imul edx, 10
    add eax, edx
    ret

read_rtc_year:
    mov al, 0x09
    out 0x70, al
    in al, 0x71
    movzx eax, al
    mov edx, eax
    shr edx, 4
    and eax, 0x0F
    imul edx, 10
    add eax, edx
    ret

halt_system:
    cli
.halt_loop:
    hlt
    jmp .halt_loop

; ============================================================================
; FAST GRAPHICS FUNCTIONS - "CRUSH THEM ALL"
; Native x86 implementations for performance-critical rendering
; ============================================================================
global fast_fill_rect
global fast_memcpy32
global draw_wallpaper_dots

; draw_wallpaper_dots(fbAddr, pitch, dotColor, bgY, bgH)
; Draws a 2x1 pixel dot grid every 32 pixels across desktop area
; Args: [esp+4]=fbAddr, [esp+8]=pitch, [esp+12]=dotColor, [esp+16]=startY, [esp+20]=height
draw_wallpaper_dots:
    push ebp
    mov ebp, esp
    push edi
    push ebx
    push esi

    mov edi, [ebp+8]      ; fbAddr
    mov esi, [ebp+12]     ; pitch
    mov eax, [ebp+16]     ; dotColor
    mov ecx, [ebp+20]     ; startY
    mov edx, [ebp+24]     ; height (endY = startY + height)
    add edx, ecx          ; edx = endY

.wp_yloop:
    cmp ecx, edx
    jge .wp_done
    ; Calculate row address = fbAddr + y * pitch
    push edx
    push eax
    mov eax, ecx
    imul eax, esi         ; y * pitch
    mov ebx, edi
    add ebx, eax          ; rowAddr = fbAddr + y*pitch
    pop eax
    pop edx

    ; Draw dots across this row at x = 24, 56, 88, ... (every 32 px)
    push ecx
    mov ecx, 24           ; startX
.wp_xloop:
    cmp ecx, 1000
    jge .wp_xdone
    ; Plot 2 pixels at (x, y): rowAddr + x*4
    push edx
    mov edx, ecx
    shl edx, 2            ; x * 4
    mov [ebx + edx], eax  ; pixel at (x,y)
    add edx, 4
    mov [ebx + edx], eax  ; pixel at (x+1,y)
    pop edx
    add ecx, 24           ; next dot
    jmp .wp_xloop
.wp_xdone:
    pop ecx
    add ecx, 24           ; next row with dots
    jmp .wp_yloop
.wp_done:
    pop esi
    pop ebx
    pop edi
    pop ebp
    ret

; ================================================================
; draw_arrow_cursor(fbAddr, pitch, x, y)
; Draws a 12x16 arrow cursor with black outline + white fill
; Args: [esp+4]=fbAddr, [esp+8]=pitch, [esp+12]=x, [esp+16]=y
; ================================================================
global draw_arrow_cursor
draw_arrow_cursor:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push ebx

    mov edi, [ebp+8]      ; fbAddr
    mov esi, [ebp+12]     ; pitch
    mov ecx, [ebp+16]     ; x
    mov edx, [ebp+20]     ; y

    ; Cursor bitmap: 16 rows, each encoded as 2 bytes (outline mask, fill mask)
    ; Outline = black (0x00000000), Fill = white (0x00FFFFFF)
    ; Row format: bits from MSB = leftmost pixel
    ; We'll draw up to 12 pixels wide per row

    ; Use stack-based bitmap data (16 rows x 2 words: outline, fill)
    ; Row 0:  X            outline=0x800, fill=0x000
    ; Row 1:  XX           outline=0xC00, fill=0x400
    ; Row 2:  XWX          outline=0xE00, fill=0x400
    ; Row 3:  XWWX         outline=0xF00, fill=0x600
    ; Row 4:  XWWWX        outline=0xF80, fill=0x700
    ; Row 5:  XWWWWX       outline=0xFC0, fill=0x780
    ; Row 6:  XWWWWWX      outline=0xFE0, fill=0x7C0
    ; Row 7:  XWWWWWWX     outline=0xFF0, fill=0x7E0
    ; Row 8:  XWWWWWWWX    outline=0xFF8, fill=0x7F0
    ; Row 9:  XWWWWWWWWX   outline=0xFFC, fill=0x7F8
    ; Row 10: XWWWWWXXXXX  outline=0xFE0, fill=0x7C0  (narrow bottom)
    ; Row 11: XWWXWWX      outline=0xFE0, fill=0x660
    ; Row 12: XWX.XWWX     outline=0xE78, fill=0x430
    ; Row 13: XX..XWWX     outline=0xC78, fill=0x030
    ; Row 14: X....XWWX    outline=0x878, fill=0x030
    ; Row 15:     XX       outline=0x060, fill=0x000

    ; Simpler approach: iterate row by row with hardcoded pixel offsets
    ; Each putPixel = pixel at (x+dx, y+row)

    ; Helper macro concept: for each row, draw black outline then white fill
    ; Use a simple loop with lookup table

    ; Row 0: black at dx=0
    mov eax, 0x00000000    ; black
    call .draw_px          ; (0,0)

    ; Row 1: black at 0,1; white at dx=0 skipped, actually:
    ; Proper arrow: row 1 = black border + white interior
    ; Let me just draw it directly

    ; === Row 0 === (just tip)
    ; black at (0,0)
    ; already drawn above

    ; === Row 1 ===
    push ecx
    push edx
    inc edx                ; y+1
    call .draw_px          ; black (0,1)
    inc ecx                ; x+1
    call .draw_px          ; black (1,1)
    pop edx
    pop ecx

    ; === Row 2 ===
    push ecx
    push edx
    add edx, 2
    call .draw_px          ; black (0,2)
    inc ecx
    mov eax, 0x00FFFFFF    ; white
    call .draw_px          ; white (1,2)
    inc ecx
    mov eax, 0x00000000    ; black
    call .draw_px          ; black (2,2)
    pop edx
    pop ecx

    ; === Row 3 ===
    push ecx
    push edx
    add edx, 3
    call .draw_px          ; black (0,3)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px          ; white (1,3)
    inc ecx
    call .draw_px          ; white (2,3)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (3,3)
    pop edx
    pop ecx

    ; === Row 4 ===
    push ecx
    push edx
    add edx, 4
    call .draw_px          ; black (0,4)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px          ; white (1-3,4)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (4,4)
    pop edx
    pop ecx

    ; === Row 5 ===
    push ecx
    push edx
    add edx, 5
    call .draw_px          ; black (0,5)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px          ; white (1-4,5)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (5,5)
    pop edx
    pop ecx

    ; === Row 6 ===
    push ecx
    push edx
    add edx, 6
    call .draw_px          ; black (0,6)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px          ; white (1-5,6)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (6,6)
    pop edx
    pop ecx

    ; === Row 7 ===
    push ecx
    push edx
    add edx, 7
    call .draw_px          ; black (0,7)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px          ; white (1-6,7)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (7,7)
    pop edx
    pop ecx

    ; === Row 8 ===
    push ecx
    push edx
    add edx, 8
    call .draw_px          ; black (0,8)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px          ; white (1-7,8)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (8,8)
    pop edx
    pop ecx

    ; === Row 9 ===
    push ecx
    push edx
    add edx, 9
    call .draw_px          ; black (0,9)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px          ; white (1-8,9)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (9,9)
    pop edx
    pop ecx

    ; === Row 10 (bottom of arrow body) ===
    push ecx
    push edx
    add edx, 10
    call .draw_px          ; black (0,10)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px          ; white (1-4,10)
    inc ecx
    mov eax, 0x00000000
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px
    inc ecx
    call .draw_px          ; black (5-8,10)
    pop edx
    pop ecx

    ; === Row 11 ===
    push ecx
    push edx
    add edx, 11
    call .draw_px          ; black (0,11)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px          ; white (1-2,11)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (3,11)
    inc ecx
    call .draw_px          ; black (4,11)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px          ; white (5-6,11)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (7,11)
    pop edx
    pop ecx

    ; === Row 12 ===
    push ecx
    push edx
    add edx, 12
    call .draw_px          ; black (0,12)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px          ; white (1,12)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (2,12)
    ; gap at 3,4
    add ecx, 3             ; skip to x+5
    call .draw_px          ; black (5,12)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px          ; white (6-7,12)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (8,12)
    pop edx
    pop ecx

    ; === Row 13 ===
    push ecx
    push edx
    add edx, 13
    call .draw_px          ; black (0,13)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (1,13)
    ; gap at 2,3,4
    add ecx, 4             ; skip to x+5
    call .draw_px          ; black (5,13)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px
    inc ecx
    call .draw_px          ; white (6-7,13)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (8,13)
    pop edx
    pop ecx

    ; === Row 14 ===
    push ecx
    push edx
    add edx, 14
    ; gap at 0-4
    add ecx, 5
    call .draw_px          ; black (5,14)
    inc ecx
    mov eax, 0x00FFFFFF
    call .draw_px          ; white (6,14)
    inc ecx
    mov eax, 0x00000000
    call .draw_px          ; black (7,14)
    pop edx
    pop ecx

    ; === Row 15 ===
    push ecx
    push edx
    add edx, 15
    add ecx, 5
    call .draw_px          ; black (5,15)
    inc ecx
    call .draw_px          ; black (6,15)
    pop edx
    pop ecx

    pop ebx
    pop esi
    pop edi
    pop ebp
    ret

; Helper: draw pixel at (ecx, edx) with color eax
; Uses edi=fbAddr, esi=pitch. Preserves ecx, edx.
.draw_px:
    push ebx
    ; offset = edx * esi + ecx * 4
    mov ebx, edx
    imul ebx, esi          ; y * pitch
    push ecx
    shl ecx, 2             ; x * 4
    add ebx, ecx
    mov [edi + ebx], eax   ; write pixel
    pop ecx
    pop ebx
    ret

; fast_fill_rect(fbAddr, fbPitch, x, y, width, height, color)
; Uses rep stosd for ~100x speedup over putPixel loops
; Args: [esp+4]=fbAddr, [esp+8]=pitch, [esp+12]=x, [esp+16]=y,
;       [esp+20]=width, [esp+24]=height, [esp+28]=color
fast_fill_rect:
    push ebp
    mov ebp, esp
    push edi
    push ebx
    push esi

    ; Args: fbAddr=[ebp+8], pitch=[ebp+12], x=[ebp+16], y=[ebp+20],
    ;       width=[ebp+24], height=[ebp+28], color=[ebp+32]
    mov edi, [ebp+8]     ; fbAddr
    mov eax, [ebp+12]    ; pitch (bytes per row)
    mov ebx, [ebp+20]    ; y
    imul eax, ebx        ; y * pitch
    mov ebx, [ebp+16]    ; x
    shl ebx, 2           ; x * 4 (32bpp)
    add edi, eax         ; fbAddr + y*pitch
    add edi, ebx         ; + x*4 = start address

    mov ecx, [ebp+24]    ; width
    mov edx, [ebp+28]    ; height
    mov eax, [ebp+32]    ; color
    mov esi, [ebp+12]    ; pitch

    ; Calculate stride = pitch - width*4 (bytes to skip to next row)
    mov ebx, ecx
    shl ebx, 2           ; width * 4
    sub esi, ebx         ; stride = pitch - width*4

.fill_row:
    test edx, edx
    jz .fill_done
    push ecx             ; save width for next row
    rep stosd             ; fill ECX dwords with EAX at [EDI]
    add edi, esi          ; skip to next row start
    pop ecx               ; restore width
    dec edx
    jmp .fill_row
.fill_done:
    pop esi
    pop ebx
    pop edi
    pop ebp
    ret

; fast_memcpy32(dst, src, count)
; Fast 32-bit word copy using rep movsd
; Args: [esp+4]=dst, [esp+8]=src, [esp+12]=count (in dwords)
fast_memcpy32:
    push edi
    push esi
    push ecx
    mov edi, [esp+16]     ; dst
    mov esi, [esp+20]     ; src
    mov ecx, [esp+24]     ; count
    rep movsd
    pop ecx
    pop esi
    pop edi
    ret

; ============================================================================
; PCI BUS ACCESS - "I NEED YOUR BUS, YOUR DEVICE, AND YOUR FUNCTION"
; ============================================================================
; PCI Configuration Space access via I/O ports 0xCF8 (address) and 0xCFC (data)
; Address format: [31]=enable, [23:16]=bus, [15:11]=device, [10:8]=func, [7:2]=reg, [1:0]=00
; ============================================================================

global pci_config_read
global pci_config_write
global pci_find_device

; PCI ports
PCI_CONFIG_ADDR equ 0x0CF8
PCI_CONFIG_DATA equ 0x0CFC

; pci_config_read(bus, slot, func, offset) -> dword value
; Args: [esp+4]=bus, [esp+8]=slot, [esp+12]=func, [esp+16]=offset
pci_config_read:
    push ebx
    ; Build address: 0x80000000 | (bus<<16) | (slot<<11) | (func<<8) | (offset & 0xFC)
    mov eax, 0x80000000
    mov ebx, [esp+8]      ; bus
    shl ebx, 16
    or eax, ebx
    mov ebx, [esp+12]     ; slot
    shl ebx, 11
    or eax, ebx
    mov ebx, [esp+16]     ; func
    shl ebx, 8
    or eax, ebx
    mov ebx, [esp+20]     ; offset
    and ebx, 0xFC         ; align to dword
    or eax, ebx
    ; Write address
    mov dx, PCI_CONFIG_ADDR
    out dx, eax
    ; Read data
    mov dx, PCI_CONFIG_DATA
    in eax, dx
    pop ebx
    ret

; pci_config_write(bus, slot, func, offset, value)
; Args: [esp+4]=bus, [esp+8]=slot, [esp+12]=func, [esp+16]=offset, [esp+20]=value
pci_config_write:
    push ebx
    ; Build address (same as read)
    mov eax, 0x80000000
    mov ebx, [esp+8]      ; bus
    shl ebx, 16
    or eax, ebx
    mov ebx, [esp+12]     ; slot
    shl ebx, 11
    or eax, ebx
    mov ebx, [esp+16]     ; func
    shl ebx, 8
    or eax, ebx
    mov ebx, [esp+20]     ; offset
    and ebx, 0xFC
    or eax, ebx
    ; Write address
    mov dx, PCI_CONFIG_ADDR
    out dx, eax
    ; Write data
    mov eax, [esp+24]     ; value
    mov dx, PCI_CONFIG_DATA
    out dx, eax
    pop ebx
    ret

; pci_find_device(vendor_id, device_id) -> bus<<16|slot<<8|func, or 0xFFFFFFFF if not found
; Scans bus 0, all 32 slots, function 0 only
; Args: [esp+4]=vendor_id, [esp+8]=device_id
pci_find_device:
    push ebx
    push esi
    push edi
    mov esi, [esp+16]     ; vendor_id
    mov edi, [esp+20]     ; device_id
    
    xor ebx, ebx          ; slot = 0
.pci_scan_loop:
    cmp ebx, 32
    jge .pci_not_found
    
    ; pci_config_read(bus=0, slot=ebx, func=0, offset=0) -> vendor|device
    push dword 0           ; offset 0
    push dword 0           ; func 0
    push ebx               ; slot
    push dword 0           ; bus 0
    call pci_config_read
    add esp, 16
    
    ; eax = [device_id:16 | vendor_id:16]
    mov ecx, eax
    and ecx, 0xFFFF        ; vendor_id
    cmp ecx, esi
    jne .pci_next_slot
    
    shr eax, 16            ; device_id
    cmp eax, edi
    jne .pci_next_slot
    
    ; Found! Return bus<<16 | slot<<8 | func
    mov eax, ebx
    shl eax, 8             ; slot << 8
    ; bus=0, func=0, so just slot<<8
    jmp .pci_scan_done
    
.pci_next_slot:
    inc ebx
    jmp .pci_scan_loop
    
.pci_not_found:
    mov eax, 0xFFFFFFFF
    
.pci_scan_done:
    pop edi
    pop esi
    pop ebx
    ret

; ============================================================================
; E1000 NIC DRIVER - "GET TO THE NETWORK!"
; Intel 82540EM (E1000) driver for QEMU
; Vendor: 0x8086 (Intel), Device: 0x100E (82540EM)
; ============================================================================

global e1000_init
global e1000_send_packet
global e1000_receive_packet
global e1000_get_mac
global e1000_is_link_up

; E1000 register offsets (from MMIO base)
E1000_CTRL      equ 0x0000    ; Device Control
E1000_STATUS    equ 0x0008    ; Device Status
E1000_EERD      equ 0x0014    ; EEPROM Read
E1000_ICR       equ 0x00C0    ; Interrupt Cause Read
E1000_IMS       equ 0x00D0    ; Interrupt Mask Set
E1000_IMC       equ 0x00D8    ; Interrupt Mask Clear
E1000_RCTL      equ 0x0100    ; Receive Control
E1000_RDBAL     equ 0x2800    ; RX Descriptor Base Low
E1000_RDBAH     equ 0x2804    ; RX Descriptor Base High
E1000_RDLEN     equ 0x2808    ; RX Descriptor Length
E1000_RDH       equ 0x2810    ; RX Descriptor Head
E1000_RDT       equ 0x2818    ; RX Descriptor Tail
E1000_TCTL      equ 0x0400    ; Transmit Control
E1000_TDBAL     equ 0x3800    ; TX Descriptor Base Low
E1000_TDBAH     equ 0x3804    ; TX Descriptor Base High
E1000_TDLEN     equ 0x3808    ; TX Descriptor Length
E1000_TDH       equ 0x3810    ; TX Descriptor Head
E1000_TDT       equ 0x3818    ; TX Descriptor Tail
E1000_RAL       equ 0x5400    ; Receive Address Low
E1000_RAH       equ 0x5404    ; Receive Address High
E1000_MTA       equ 0x5200    ; Multicast Table Array (128 entries)

; E1000 control bits
E1000_CTRL_SLU  equ (1 << 6)  ; Set Link Up
E1000_CTRL_RST  equ (1 << 26) ; Device Reset

; E1000 receive control bits
E1000_RCTL_EN   equ (1 << 1)  ; Receiver Enable
E1000_RCTL_SBP  equ (1 << 2)  ; Store Bad Packets
E1000_RCTL_UPE  equ (1 << 3)  ; Unicast Promiscuous
E1000_RCTL_MPE  equ (1 << 4)  ; Multicast Promiscuous
E1000_RCTL_BAM  equ (1 << 15) ; Broadcast Accept Mode
E1000_RCTL_BSIZE_2048 equ 0   ; Buffer size 2048 bytes
E1000_RCTL_SECRC equ (1 << 26) ; Strip Ethernet CRC

; E1000 transmit control bits
E1000_TCTL_EN   equ (1 << 1)  ; Transmit Enable
E1000_TCTL_PSP  equ (1 << 3)  ; Pad Short Packets
E1000_TCTL_CT_SHIFT equ 4     ; Collision Threshold
E1000_TCTL_COLD_SHIFT equ 12  ; Collision Distance

; TX descriptor command bits
E1000_TXD_CMD_EOP  equ (1 << 0) ; End of Packet
E1000_TXD_CMD_IFCS equ (1 << 1) ; Insert FCS/CRC
E1000_TXD_CMD_RS   equ (1 << 3) ; Report Status
E1000_TXD_STAT_DD  equ (1 << 0) ; Descriptor Done

; RX descriptor status bits
E1000_RXD_STAT_DD  equ (1 << 0) ; Descriptor Done
E1000_RXD_STAT_EOP equ (1 << 1) ; End of Packet

; Descriptor ring sizes
E1000_NUM_RX_DESC  equ 16
E1000_NUM_TX_DESC  equ 16
E1000_RX_BUF_SIZE  equ 2048
E1000_TX_BUF_SIZE  equ 2048

section .bss
; E1000 state
e1000_mmio_base:  resd 1           ; MMIO base address from BAR0
e1000_mac:        resb 8           ; MAC address (6 bytes + 2 padding)
e1000_found:      resd 1           ; 1 if E1000 detected

; Descriptor rings (16-byte aligned) — 16 descriptors × 16 bytes each = 256 bytes
alignb 16
e1000_rx_descs:   resb (E1000_NUM_RX_DESC * 16)
e1000_tx_descs:   resb (E1000_NUM_TX_DESC * 16)

; Packet buffers: 16 RX + 16 TX × 2048 bytes = 64KB
e1000_rx_buffers: resb (E1000_NUM_RX_DESC * E1000_RX_BUF_SIZE)
e1000_tx_buffers: resb (E1000_NUM_TX_DESC * E1000_TX_BUF_SIZE)

; Current descriptor indices
e1000_rx_cur:     resd 1
e1000_tx_cur:     resd 1

section .text

; Helper: read E1000 MMIO register
; eax = register offset -> eax = value
e1000_read_reg:
    add eax, [e1000_mmio_base]
    mov eax, [eax]
    ret

; Helper: write E1000 MMIO register
; eax = register offset, edx = value
e1000_write_reg:
    add eax, [e1000_mmio_base]
    mov [eax], edx
    ret

; e1000_init() -> 0=success, -1=not found
; Finds E1000 on PCI bus, configures RX/TX, enables link
e1000_init:
    push ebx
    push esi
    push edi
    
    ; Step 1: Find E1000 on PCI bus (vendor=0x8086, device=0x100E)
    push dword 0x100E      ; device_id
    push dword 0x8086      ; vendor_id
    call pci_find_device
    add esp, 8
    
    cmp eax, 0xFFFFFFFF
    je .e1000_init_fail
    
    ; Save BDF for later use
    mov ebx, eax           ; ebx = BDF (bus<<16|slot<<8|func)
    mov dword [e1000_found], 1
    
    ; Step 2: Read BAR0 to get MMIO base address
    ; BAR0 is at PCI config offset 0x10
    mov ecx, ebx
    shr ecx, 8
    and ecx, 0xFF          ; slot
    push dword 0x10        ; offset (BAR0)
    push dword 0           ; func
    push ecx               ; slot
    push dword 0           ; bus
    call pci_config_read
    add esp, 16
    
    and eax, 0xFFFFFFF0    ; Mask lower 4 bits (type/prefetch flags)
    mov [e1000_mmio_base], eax
    
    ; Step 3: Enable PCI bus mastering (command register offset 0x04)
    mov ecx, ebx
    shr ecx, 8
    and ecx, 0xFF          ; slot
    push dword 0x04        ; offset (Command)
    push dword 0           ; func
    push ecx               ; slot
    push dword 0           ; bus
    call pci_config_read
    add esp, 16
    
    or eax, 0x07           ; Enable I/O, Memory, Bus Master
    mov ecx, ebx
    shr ecx, 8
    and ecx, 0xFF
    push eax               ; value
    push dword 0x04        ; offset
    push dword 0           ; func
    push ecx               ; slot
    push dword 0           ; bus
    call pci_config_write
    add esp, 20
    
    ; Step 4: Reset device
    mov eax, E1000_CTRL
    add eax, [e1000_mmio_base]
    mov edx, [eax]
    or edx, E1000_CTRL_RST
    mov [eax], edx
    
    ; Wait for reset to complete (~10ms at 100Hz PIT)
    push dword 2           ; 2 PIT ticks = 20ms at 100Hz
    call sleep_ticks
    add esp, 4
    
    ; Step 5: Set Link Up, disable interrupts initially
    mov eax, E1000_IMC
    add eax, [e1000_mmio_base]
    mov dword [eax], 0xFFFFFFFF   ; Disable all interrupts
    
    mov eax, E1000_CTRL
    add eax, [e1000_mmio_base]
    mov edx, [eax]
    or edx, E1000_CTRL_SLU        ; Set Link Up
    and edx, ~E1000_CTRL_RST      ; Clear reset bit
    mov [eax], edx
    
    ; Step 6: Read MAC address from RAL/RAH registers
    mov eax, E1000_RAL
    add eax, [e1000_mmio_base]
    mov eax, [eax]
    mov [e1000_mac], eax           ; Bytes 0-3
    
    mov eax, E1000_RAH
    add eax, [e1000_mmio_base]
    mov eax, [eax]
    and eax, 0xFFFF                ; Only lower 16 bits are MAC
    mov [e1000_mac + 4], ax        ; Bytes 4-5
    
    ; Step 7: Initialize RX descriptors
    xor ecx, ecx                  ; i = 0
.init_rx_desc:
    cmp ecx, E1000_NUM_RX_DESC
    jge .init_rx_done
    
    ; Each RX descriptor: [0:7]=buffer_addr, [8:9]=length, [10:11]=checksum, [12]=status, [13]=errors, [14:15]=special
    mov eax, ecx
    shl eax, 4                    ; i * 16 (descriptor size)
    lea edi, [e1000_rx_descs + eax]
    
    ; Buffer address = e1000_rx_buffers + i * 2048
    mov eax, ecx
    shl eax, 11                   ; i * 2048
    lea edx, [e1000_rx_buffers + eax]
    mov [edi], edx                 ; buffer addr low
    mov dword [edi + 4], 0         ; buffer addr high (32-bit)
    mov dword [edi + 8], 0         ; length=0, checksum=0
    mov dword [edi + 12], 0        ; status=0, errors=0, special=0
    
    inc ecx
    jmp .init_rx_desc
.init_rx_done:
    
    ; Configure RX descriptor ring
    mov eax, E1000_RDBAL
    add eax, [e1000_mmio_base]
    lea edx, [e1000_rx_descs]
    mov [eax], edx
    
    mov eax, E1000_RDBAH
    add eax, [e1000_mmio_base]
    mov dword [eax], 0             ; High 32 bits = 0
    
    mov eax, E1000_RDLEN
    add eax, [e1000_mmio_base]
    mov dword [eax], E1000_NUM_RX_DESC * 16
    
    mov eax, E1000_RDH
    add eax, [e1000_mmio_base]
    mov dword [eax], 0
    
    mov eax, E1000_RDT
    add eax, [e1000_mmio_base]
    mov dword [eax], E1000_NUM_RX_DESC - 1
    
    ; Enable receiver
    mov eax, E1000_RCTL
    add eax, [e1000_mmio_base]
    mov edx, E1000_RCTL_EN | E1000_RCTL_BAM | E1000_RCTL_BSIZE_2048 | E1000_RCTL_SECRC
    mov [eax], edx
    
    ; Step 8: Initialize TX descriptors
    xor ecx, ecx
.init_tx_desc:
    cmp ecx, E1000_NUM_TX_DESC
    jge .init_tx_done
    
    mov eax, ecx
    shl eax, 4
    lea edi, [e1000_tx_descs + eax]
    
    mov eax, ecx
    shl eax, 11                   ; i * 2048
    lea edx, [e1000_tx_buffers + eax]
    mov [edi], edx
    mov dword [edi + 4], 0
    mov dword [edi + 8], 0
    mov dword [edi + 12], 0
    
    inc ecx
    jmp .init_tx_desc
.init_tx_done:
    
    ; Configure TX descriptor ring
    mov eax, E1000_TDBAL
    add eax, [e1000_mmio_base]
    lea edx, [e1000_tx_descs]
    mov [eax], edx
    
    mov eax, E1000_TDBAH
    add eax, [e1000_mmio_base]
    mov dword [eax], 0
    
    mov eax, E1000_TDLEN
    add eax, [e1000_mmio_base]
    mov dword [eax], E1000_NUM_TX_DESC * 16
    
    mov eax, E1000_TDH
    add eax, [e1000_mmio_base]
    mov dword [eax], 0
    
    mov eax, E1000_TDT
    add eax, [e1000_mmio_base]
    mov dword [eax], 0
    
    ; Enable transmitter
    mov eax, E1000_TCTL
    add eax, [e1000_mmio_base]
    mov edx, E1000_TCTL_EN | E1000_TCTL_PSP | (15 << E1000_TCTL_CT_SHIFT) | (64 << E1000_TCTL_COLD_SHIFT)
    mov [eax], edx
    
    ; Initialize current indices
    mov dword [e1000_rx_cur], 0
    mov dword [e1000_tx_cur], 0
    
    ; Success
    xor eax, eax
    jmp .e1000_init_done

.e1000_init_fail:
    mov dword [e1000_found], 0
    mov eax, -1

.e1000_init_done:
    pop edi
    pop esi
    pop ebx
    ret

; e1000_send_packet(buffer, length) -> 0=success, -1=fail
; Copies data to TX buffer and submits descriptor
; Args: [esp+4]=buffer ptr, [esp+8]=length
e1000_send_packet:
    push ebx
    push esi
    push edi
    
    cmp dword [e1000_found], 0
    je .send_fail
    
    mov esi, [esp+16]      ; source buffer
    mov ecx, [esp+20]      ; length
    
    ; Clamp to max buffer size
    cmp ecx, E1000_TX_BUF_SIZE
    jle .send_size_ok
    mov ecx, E1000_TX_BUF_SIZE
.send_size_ok:
    
    ; Get current TX descriptor index
    mov ebx, [e1000_tx_cur]
    
    ; Copy packet data to TX buffer
    mov eax, ebx
    shl eax, 11             ; index * 2048
    lea edi, [e1000_tx_buffers + eax]
    push ecx
    rep movsb                ; copy bytes
    pop ecx
    
    ; Set up TX descriptor
    mov eax, ebx
    shl eax, 4              ; index * 16
    lea edi, [e1000_tx_descs + eax]
    ; [edi+0:7] = buffer addr (already set in init)
    mov [edi + 8], cx        ; length (lower 16 bits)
    mov byte [edi + 10], 0   ; CSO
    mov byte [edi + 11], (E1000_TXD_CMD_EOP | E1000_TXD_CMD_IFCS | E1000_TXD_CMD_RS) ; cmd
    mov dword [edi + 12], 0  ; status/reserved
    
    ; Advance TX tail
    inc ebx
    and ebx, (E1000_NUM_TX_DESC - 1)  ; wrap
    mov [e1000_tx_cur], ebx
    
    ; Write new tail to TDT register
    mov eax, E1000_TDT
    add eax, [e1000_mmio_base]
    mov [eax], ebx
    
    xor eax, eax            ; success
    jmp .send_done

.send_fail:
    mov eax, -1
.send_done:
    pop edi
    pop esi
    pop ebx
    ret

; e1000_receive_packet(buffer, max_length) -> bytes received, or 0 if none
; Args: [esp+4]=dest buffer, [esp+8]=max_length
e1000_receive_packet:
    push ebx
    push esi
    push edi
    
    cmp dword [e1000_found], 0
    je .recv_none
    
    ; Check current RX descriptor for DD (Descriptor Done)
    mov ebx, [e1000_rx_cur]
    mov eax, ebx
    shl eax, 4
    lea esi, [e1000_rx_descs + eax]
    
    test byte [esi + 12], E1000_RXD_STAT_DD
    jz .recv_none            ; No packet available
    
    ; Packet available! Get length
    movzx ecx, word [esi + 8]  ; actual length
    
    ; Clamp to max_length
    mov edx, [esp+20]       ; max_length
    cmp ecx, edx
    jle .recv_size_ok
    mov ecx, edx
.recv_size_ok:
    
    ; Copy from RX buffer to caller's buffer
    push ecx
    mov edi, [esp+20]       ; dest buffer (esp+16 + 4 for pushed ecx)
    mov eax, ebx
    shl eax, 11             ; index * 2048
    lea esi, [e1000_rx_buffers + eax]
    rep movsb
    pop ecx                  ; ecx = bytes copied
    
    ; Clear descriptor status for reuse
    mov eax, ebx
    shl eax, 4
    lea edi, [e1000_rx_descs + eax]
    mov dword [edi + 8], 0   ; clear length/checksum
    mov dword [edi + 12], 0  ; clear status
    
    ; Advance RX tail
    mov eax, ebx
    inc ebx
    and ebx, (E1000_NUM_RX_DESC - 1)
    mov [e1000_rx_cur], ebx
    
    ; Update RDT (old index becomes new tail)
    push ecx
    mov edx, eax             ; old index
    mov eax, E1000_RDT
    add eax, [e1000_mmio_base]
    mov [eax], edx
    pop ecx
    
    mov eax, ecx             ; return bytes received
    jmp .recv_done

.recv_none:
    xor eax, eax
.recv_done:
    pop edi
    pop esi
    pop ebx
    ret

; e1000_get_mac(buffer) -> copies 6 bytes of MAC to buffer
; Args: [esp+4]=dest buffer (at least 6 bytes)
e1000_get_mac:
    push edi
    push esi
    mov edi, [esp+12]       ; dest
    lea esi, [e1000_mac]
    mov ecx, 6
    rep movsb
    pop esi
    pop edi
    ret

; e1000_is_link_up() -> 1 if link up, 0 if down
e1000_is_link_up:
    cmp dword [e1000_found], 0
    je .link_down
    mov eax, E1000_STATUS
    add eax, [e1000_mmio_base]
    mov eax, [eax]
    test eax, (1 << 1)      ; LU (Link Up) bit
    jz .link_down
    mov eax, 1
    ret
.link_down:
    xor eax, eax
    ret

; ============================================================================
; NETWORK PROTOCOL STACK - "THE NETWORK IS MY DOMAIN"
; Ethernet frames, ARP resolution, IP, ICMP Echo (ping)
; ============================================================================

global net_ping_gateway
global net_get_ip_byte
global net_get_gateway_byte
global net_get_mac_byte
global net_is_available

; --- Network configuration (QEMU user-mode defaults) ---
section .data
net_our_ip:       dd 0x0F02000A    ; 10.0.2.15 (network byte order)
net_gateway_ip:   dd 0x0202000A    ; 10.0.2.2
net_netmask:      dd 0x00FFFFFF    ; 255.255.255.0
net_broadcast_mac: db 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF, 0,0

section .bss
net_tx_buf:       resb 2048        ; Packet assembly scratch
net_rx_buf:       resb 2048        ; Packet receive scratch
net_resolved_mac: resb 8           ; ARP-resolved MAC (6 bytes + 2 pad)
net_ping_seq:     resd 1           ; ICMP sequence counter

section .text

; --- Simple getters for ArnoldC ---

; net_is_available() -> 1 if E1000 found, 0 if not
net_is_available:
    mov eax, [e1000_found]
    ret

; net_get_ip_byte(index) -> byte 0-3 of our IP (10, 0, 2, 15)
net_get_ip_byte:
    mov ecx, [esp+4]
    movzx eax, byte [net_our_ip + ecx]
    ret

; net_get_gateway_byte(index) -> byte 0-3 of gateway IP
net_get_gateway_byte:
    mov ecx, [esp+4]
    movzx eax, byte [net_gateway_ip + ecx]
    ret

; net_get_mac_byte(index) -> byte 0-5 of our MAC
net_get_mac_byte:
    mov ecx, [esp+4]
    movzx eax, byte [e1000_mac + ecx]
    ret

; --- IP header checksum ---
; ip_checksum(buf_ptr, length_bytes) -> 16-bit checksum
ip_checksum:
    push ebx
    push esi
    mov esi, [esp+12]      ; buffer
    mov ecx, [esp+16]      ; length in bytes
    shr ecx, 1             ; convert to 16-bit words
    xor eax, eax           ; sum = 0
.cksum_loop:
    test ecx, ecx
    jz .cksum_fold
    movzx ebx, word [esi]
    add eax, ebx
    add esi, 2
    dec ecx
    jmp .cksum_loop
.cksum_fold:
    mov ebx, eax
    shr ebx, 16
    and eax, 0xFFFF
    add eax, ebx
    mov ebx, eax
    shr ebx, 16
    add eax, ebx
    and eax, 0xFFFF
    not eax
    and eax, 0xFFFF
    pop esi
    pop ebx
    ret

; --- Ethernet + ARP ---

; net_send_arp_request(target_ip)
; Sends an ARP "Who has <target_ip>? Tell <our_ip>"
net_send_arp_request:
    push ebx
    push esi
    push edi

    mov ebx, [esp+16]     ; target_ip
    lea edi, [net_tx_buf]

    ; === Ethernet header (14 bytes) ===
    ; Dest MAC: broadcast FF:FF:FF:FF:FF:FF
    mov dword [edi+0], 0xFFFFFFFF
    mov word  [edi+4], 0xFFFF
    ; Src MAC: our MAC
    mov eax, [e1000_mac]
    mov [edi+6], eax
    mov ax, [e1000_mac+4]
    mov [edi+10], ax
    ; EtherType: ARP (0x0806 in network order = 0x0608 in memory)
    mov word [edi+12], 0x0608

    ; === ARP header (28 bytes at offset 14) ===
    mov word [edi+14], 0x0100     ; Hardware type: Ethernet
    mov word [edi+16], 0x0008     ; Protocol type: IPv4
    mov byte [edi+18], 6          ; HW addr length
    mov byte [edi+19], 4          ; Proto addr length
    mov word [edi+20], 0x0100     ; Operation: Request

    ; Sender HW addr (our MAC)
    mov eax, [e1000_mac]
    mov [edi+22], eax
    mov ax, [e1000_mac+4]
    mov [edi+26], ax

    ; Sender proto addr (our IP)
    mov eax, [net_our_ip]
    mov [edi+28], eax

    ; Target HW addr (zeros — we're asking)
    mov dword [edi+32], 0
    mov word  [edi+36], 0

    ; Target proto addr
    mov [edi+38], ebx

    ; Send: 14 + 28 = 42 bytes
    push dword 42
    push edi
    call e1000_send_packet
    add esp, 8

    pop edi
    pop esi
    pop ebx
    ret

; net_wait_arp_reply(target_ip, timeout_ticks) -> 0=success (MAC in net_resolved_mac), -1=timeout
net_wait_arp_reply:
    push ebx
    push esi
    push edi

    mov ebx, [esp+16]     ; target_ip
    call get_timer_ticks
    mov esi, eax
    add esi, [esp+20]     ; deadline = now + timeout

.arp_poll:
    call get_timer_ticks
    cmp eax, esi
    jge .arp_timeout

    push dword 2048
    lea eax, [net_rx_buf]
    push eax
    call e1000_receive_packet
    add esp, 8

    test eax, eax
    jz .arp_poll           ; No packet

    ; Check EtherType = ARP (0x0608 in memory)
    lea edi, [net_rx_buf]
    cmp word [edi+12], 0x0608
    jne .arp_poll

    ; Check ARP Operation = Reply (0x0200 in memory)
    cmp word [edi+20], 0x0200
    jne .arp_poll

    ; Check sender protocol addr matches our target
    mov eax, [edi+28]
    cmp eax, ebx
    jne .arp_poll

    ; Extract sender hardware addr → net_resolved_mac
    mov eax, [edi+22]
    mov [net_resolved_mac], eax
    mov ax, [edi+26]
    mov [net_resolved_mac+4], ax

    xor eax, eax          ; success
    jmp .arp_done

.arp_timeout:
    mov eax, -1

.arp_done:
    pop edi
    pop esi
    pop ebx
    ret

; --- ICMP Echo ---

; net_send_icmp_echo(dest_ip, dest_mac_ptr, seq_num)
; Builds and sends an ICMP Echo Request inside IP inside Ethernet
net_send_icmp_echo:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    lea edi, [net_tx_buf]
    mov esi, [ebp+12]     ; dest_mac_ptr

    ; === Ethernet header (14 bytes) ===
    mov eax, [esi]
    mov [edi+0], eax
    mov ax, [esi+4]
    mov [edi+4], ax
    mov eax, [e1000_mac]
    mov [edi+6], eax
    mov ax, [e1000_mac+4]
    mov [edi+10], ax
    mov word [edi+12], 0x0008    ; EtherType: IPv4

    ; === IP header (20 bytes at offset 14) ===
    mov byte  [edi+14], 0x45     ; Version 4, IHL 5
    mov byte  [edi+15], 0        ; TOS
    mov word  [edi+16], 0x1C00   ; Total length: 28 (20 IP + 8 ICMP) big-endian
    mov word  [edi+18], 0x3412   ; Identification (arbitrary)
    mov word  [edi+20], 0x0040   ; Flags: Don't Fragment
    mov byte  [edi+22], 64       ; TTL
    mov byte  [edi+23], 1        ; Protocol: ICMP
    mov word  [edi+24], 0        ; Checksum placeholder
    mov eax, [net_our_ip]
    mov [edi+26], eax            ; Source IP
    mov eax, [ebp+8]             ; dest_ip
    mov [edi+30], eax            ; Destination IP

    ; IP checksum
    lea eax, [edi+14]
    push dword 20
    push eax
    call ip_checksum
    add esp, 8
    mov [edi+24], ax

    ; === ICMP Echo Request (8 bytes at offset 34) ===
    mov byte  [edi+34], 8        ; Type: Echo Request
    mov byte  [edi+35], 0        ; Code: 0
    mov word  [edi+36], 0        ; Checksum placeholder
    mov word  [edi+38], 0x0100   ; Identifier
    mov eax, [ebp+16]            ; seq_num
    xchg al, ah                  ; to network byte order
    mov [edi+40], ax             ; Sequence

    ; ICMP checksum
    lea eax, [edi+34]
    push dword 8
    push eax
    call ip_checksum
    add esp, 8
    mov [edi+36], ax

    ; Send: 14 + 20 + 8 = 42 bytes
    push dword 42
    lea eax, [net_tx_buf]
    push eax
    call e1000_send_packet
    add esp, 8

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

; --- High-level ping ---

; net_ping_gateway() -> RTT in ticks (1 tick = 10ms at 100Hz), or -1 if timeout/fail
net_ping_gateway:
    push ebx
    push esi

    cmp dword [e1000_found], 0
    je .pg_fail

    ; Step 1: ARP resolve gateway MAC
    push dword [net_gateway_ip]
    call net_send_arp_request
    add esp, 4

    push dword 200                ; 2 second timeout
    push dword [net_gateway_ip]
    call net_wait_arp_reply
    add esp, 8

    cmp eax, -1
    je .pg_fail

    ; Step 2: Send ICMP echo
    call get_timer_ticks
    mov ebx, eax                  ; start_tick

    inc dword [net_ping_seq]
    push dword [net_ping_seq]     ; seq
    lea eax, [net_resolved_mac]
    push eax                      ; dest_mac
    push dword [net_gateway_ip]   ; dest_ip
    call net_send_icmp_echo
    add esp, 12

    ; Step 3: Wait for ICMP echo reply
    call get_timer_ticks
    mov esi, eax
    add esi, 200                  ; 2 second deadline

.pg_poll:
    call get_timer_ticks
    cmp eax, esi
    jge .pg_fail

    push dword 2048
    lea eax, [net_rx_buf]
    push eax
    call e1000_receive_packet
    add esp, 8

    test eax, eax
    jz .pg_poll

    ; Validate: EtherType IPv4?
    lea edi, [net_rx_buf]
    cmp word [edi+12], 0x0008
    jne .pg_poll

    ; Protocol ICMP?
    cmp byte [edi+23], 1
    jne .pg_poll

    ; ICMP Type = 0 (Echo Reply)?
    cmp byte [edi+34], 0
    jne .pg_poll

    ; Got reply! RTT = now - start (minimum 1 tick)
    call get_timer_ticks
    sub eax, ebx
    test eax, eax
    jnz .pg_done
    inc eax              ; ensure minimum RTT = 1
    jmp .pg_done

.pg_fail:
    xor eax, eax        ; return 0 = failure/timeout

.pg_done:
    pop esi
    pop ebx
    ret

; ============================================================================
; TCP/HTTP STACK - "I'LL BE BACK... WITH DATA"
; Minimal TCP state machine + HTTP/1.0 GET client
; ============================================================================

global net_tcp_connect
global net_tcp_send
global net_tcp_recv
global net_tcp_close
global net_http_get
global net_wget
global net_wget_get_byte
global net_wget_get_len

; TCP flag constants
TCP_FIN equ 0x01
TCP_SYN equ 0x02
TCP_RST equ 0x04
TCP_PSH equ 0x08
TCP_ACK equ 0x10

section .data
; HTTP GET request template (for 10.0.2.2:8080)
http_get_req: db "GET / HTTP/1.0", 13, 10
              db "Host: 10.0.2.2", 13, 10
              db "Connection: close", 13, 10
              db 13, 10
http_get_req_len equ $ - http_get_req

section .bss
; TCP connection state (single connection at a time)
tcp_state:        resd 1        ; 0=CLOSED, 1=SYN_SENT, 2=ESTABLISHED
tcp_local_port:   resd 1
tcp_remote_ip:    resd 1
tcp_remote_port:  resd 1
tcp_send_seq:     resd 1
tcp_send_ack:     resd 1        ; what we ACK (remote's next expected seq)
tcp_remote_mac:   resb 8        ; resolved dest MAC
tcp_port_ctr:     resd 1        ; ephemeral port counter

; Gateway MAC cache
net_gw_mac:       resb 8
net_gw_resolved:  resd 1

; Protocol scratch buffers
net_pkt_buf:      resb 2048     ; packet assembly
net_rcv_buf:      resb 2048     ; receive scratch

; wget response
wget_response:    resb 4096
wget_resp_len:    resd 1

section .text

; --- Gateway MAC resolver (cached) ---
net_resolve_gw:
    cmp dword [net_gw_resolved], 1
    je .gw_cached

    ; Serial: resolving gateway
    mov dx, 0x3F8
    mov al, 'g'
    out dx, al

    push dword [net_gateway_ip]
    call net_send_arp_request
    add esp, 4

    push dword 200
    push dword [net_gateway_ip]
    call net_wait_arp_reply
    add esp, 8

    cmp eax, -1
    je .gw_fail

    mov eax, [net_resolved_mac]
    mov [net_gw_mac], eax
    mov ax, [net_resolved_mac+4]
    mov [net_gw_mac+4], ax
    mov dword [net_gw_resolved], 1

.gw_cached:
    ; Serial: gateway resolved
    mov dx, 0x3F8
    mov al, 'G'
    out dx, al
    xor eax, eax
    ret
.gw_fail:
    mov eax, -1
    ret

; --- TCP checksum (pseudo-header + segment) ---
; tcp_calc_cksum(src_ip, dst_ip, tcp_ptr, tcp_len) -> 16-bit checksum
tcp_calc_cksum:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    xor eax, eax           ; sum = 0

    ; Pseudo-header: src IP (2 words)
    movzx ebx, word [ebp+8]
    add eax, ebx
    movzx ebx, word [ebp+10]
    add eax, ebx

    ; dst IP (2 words)
    movzx ebx, word [ebp+12]
    add eax, ebx
    movzx ebx, word [ebp+14]
    add eax, ebx

    ; Zero + Protocol(6) = 0x0006
    add eax, 0x0600         ; protocol 6 in network order word

    ; TCP length (host order → network order word)
    mov ebx, [ebp+20]
    xchg bl, bh
    movzx ebx, bx
    add eax, ebx

    ; Sum TCP segment
    mov esi, [ebp+16]
    mov ecx, [ebp+20]
    shr ecx, 1
.tcp_ck_loop:
    test ecx, ecx
    jz .tcp_ck_odd
    movzx ebx, word [esi]
    add eax, ebx
    add esi, 2
    dec ecx
    jmp .tcp_ck_loop
.tcp_ck_odd:
    test dword [ebp+20], 1
    jz .tcp_ck_fold
    movzx ebx, byte [esi]
    ; No shift — we read all words as LE, so odd byte is low byte of padded LE word
    add eax, ebx
.tcp_ck_fold:
    mov ebx, eax
    shr ebx, 16
    and eax, 0xFFFF
    add eax, ebx
    mov ebx, eax
    shr ebx, 16
    add eax, ebx
    and eax, 0xFFFF
    not eax
    and eax, 0xFFFF

    pop esi
    pop ebx
    pop ebp
    ret

; --- Build and send TCP segment ---
; tcp_send_seg(flags, data_ptr, data_len)
; Uses global tcp_* state for connection info
tcp_send_seg:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov ebx, [ebp+16]      ; data_len
    lea edi, [net_pkt_buf]

    ; === Ethernet header (14 bytes) ===
    mov eax, [tcp_remote_mac]
    mov [edi], eax
    mov ax, [tcp_remote_mac+4]
    mov [edi+4], ax
    mov eax, [e1000_mac]
    mov [edi+6], eax
    mov ax, [e1000_mac+4]
    mov [edi+10], ax
    mov word [edi+12], 0x0008  ; IPv4

    ; === IP header (20 bytes at offset 14) ===
    mov byte  [edi+14], 0x45
    mov byte  [edi+15], 0
    ; Total length = 20(IP) + 20(TCP) + data_len
    mov eax, 40
    add eax, ebx
    xchg al, ah
    mov [edi+16], ax
    call get_timer_ticks
    mov [edi+18], ax           ; ID
    mov word  [edi+20], 0x0040 ; Don't Fragment
    mov byte  [edi+22], 64     ; TTL
    mov byte  [edi+23], 6      ; Protocol: TCP
    mov word  [edi+24], 0      ; Checksum placeholder
    mov eax, [net_our_ip]
    mov [edi+26], eax
    mov eax, [tcp_remote_ip]
    mov [edi+30], eax
    ; IP checksum
    lea eax, [edi+14]
    push dword 20
    push eax
    call ip_checksum
    add esp, 8
    mov [edi+24], ax

    ; === TCP header (20 bytes at offset 34) ===
    mov ax, [tcp_local_port]
    xchg al, ah
    mov [edi+34], ax           ; src port
    mov ax, [tcp_remote_port]
    xchg al, ah
    mov [edi+36], ax           ; dst port
    mov eax, [tcp_send_seq]
    bswap eax
    mov [edi+38], eax          ; seq
    mov eax, [tcp_send_ack]
    bswap eax
    mov [edi+42], eax          ; ack
    mov byte  [edi+46], 0x50   ; data offset = 5 (20 bytes)
    mov al, [ebp+8]
    mov [edi+47], al           ; flags
    mov word  [edi+48], 0x0020 ; window = 8192 (NBO)
    mov word  [edi+50], 0      ; checksum placeholder
    mov word  [edi+52], 0      ; urgent ptr

    ; Copy data if any
    test ebx, ebx
    jz .tss_no_data
    push edi
    lea edi, [edi+54]          ; data area
    mov esi, [ebp+12]          ; data_ptr
    mov ecx, ebx
    rep movsb
    pop edi
.tss_no_data:

    ; TCP checksum - precompute pseudo-header sum, then add TCP segment
    ; First, build pseudo-header in a temp area and compute checksum properly
    ; Store pseudo-header right before TCP header at [edi+22] (using IP header space)
    ; Actually, compute incrementally to avoid buffer issues

    ; TCP checksum: use the tcp_calc_cksum function
    mov eax, 20
    add eax, ebx               ; tcp_len = 20 + data_len
    push eax                   ; arg4: tcp_len
    lea eax, [edi+34]
    push eax                   ; arg3: tcp_ptr
    push dword [tcp_remote_ip] ; arg2: dst_ip
    push dword [net_our_ip]    ; arg1: src_ip
    call tcp_calc_cksum
    add esp, 16
    mov [edi+50], ax

    ; Debug: dump TCP header bytes 0-7 and checksum at 16-17 to serial
    push eax
    push ecx
    push esi
    mov dx, 0x3F8
    mov al, '{'
    out dx, al
    lea esi, [edi+34]       ; TCP header
    mov ecx, 8              ; dump first 8 bytes
.tss_dump_loop:
    test ecx, ecx
    jz .tss_dump_done
    movzx eax, byte [esi]
    ; High nibble
    push eax
    shr eax, 4
    cmp al, 10
    jl .tss_dh
    add al, 55
    jmp .tss_dho
.tss_dh: add al, 48
.tss_dho: out dx, al
    pop eax
    ; Low nibble
    and al, 0x0F
    cmp al, 10
    jl .tss_dl
    add al, 55
    jmp .tss_dlo
.tss_dl: add al, 48
.tss_dlo: out dx, al
    inc esi
    dec ecx
    jmp .tss_dump_loop
.tss_dump_done:
    ; Also dump bytes 12-13 (flags) and 16-17 (checksum)
    lea esi, [edi+34+12]    ; TCP flags area
    mov al, '|'
    out dx, al
    ; Byte 12 (data offset)
    movzx eax, byte [esi]
    push eax
    shr eax, 4
    cmp al, 10
    jl .tss_df1
    add al, 55
    jmp .tss_df1o
.tss_df1: add al, 48
.tss_df1o: out dx, al
    pop eax
    and al, 0x0F
    cmp al, 10
    jl .tss_df2
    add al, 55
    jmp .tss_df2o
.tss_df2: add al, 48
.tss_df2o: out dx, al
    ; Byte 13 (flags)
    movzx eax, byte [esi+1]
    push eax
    shr eax, 4
    cmp al, 10
    jl .tss_ff1
    add al, 55
    jmp .tss_ff1o
.tss_ff1: add al, 48
.tss_ff1o: out dx, al
    pop eax
    and al, 0x0F
    cmp al, 10
    jl .tss_ff2
    add al, 55
    jmp .tss_ff2o
.tss_ff2: add al, 48
.tss_ff2o: out dx, al
    ; Bytes 16-17 (checksum)
    mov al, '='
    out dx, al
    movzx eax, byte [esi+4]   ; checksum byte 0
    push eax
    shr eax, 4
    cmp al, 10
    jl .tss_ck1
    add al, 55
    jmp .tss_ck1o
.tss_ck1: add al, 48
.tss_ck1o: out dx, al
    pop eax
    and al, 0x0F
    cmp al, 10
    jl .tss_ck2
    add al, 55
    jmp .tss_ck2o
.tss_ck2: add al, 48
.tss_ck2o: out dx, al
    movzx eax, byte [esi+5]   ; checksum byte 1
    push eax
    shr eax, 4
    cmp al, 10
    jl .tss_ck3
    add al, 55
    jmp .tss_ck3o
.tss_ck3: add al, 48
.tss_ck3o: out dx, al
    pop eax
    and al, 0x0F
    cmp al, 10
    jl .tss_ck4
    add al, 55
    jmp .tss_ck4o
.tss_ck4: add al, 48
.tss_ck4o: out dx, al
    mov al, '}'
    out dx, al
    pop esi
    pop ecx
    pop eax

    ; Send: 14 + 20 + 20 + data_len = 54 + data_len
    mov eax, 54
    add eax, ebx

    ; Debug: print total packet length to serial
    push eax
    mov dx, 0x3F8
    mov al, 'L'
    out dx, al
    pop eax
    push eax
    ; Print low byte as 2 hex digits
    push eax
    shr al, 4
    and al, 0x0F
    cmp al, 10
    jl .tss_lh
    add al, 55
    jmp .tss_lho
.tss_lh: add al, 48
.tss_lho: out dx, al
    pop eax
    and al, 0x0F
    cmp al, 10
    jl .tss_ll
    add al, 55
    jmp .tss_llo
.tss_ll: add al, 48
.tss_llo: out dx, al
    pop eax

    push eax
    push edi
    call e1000_send_packet
    add esp, 8

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

; --- TCP Connect ---
; net_tcp_connect(dest_ip, dest_port) -> 0=success, -1=fail
net_tcp_connect:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    cmp dword [e1000_found], 0
    je .tc_fail

    ; Store remote info
    mov eax, [ebp+8]
    mov [tcp_remote_ip], eax
    mov eax, [ebp+12]
    mov [tcp_remote_port], eax

    ; Resolve gateway MAC
    call net_resolve_gw
    cmp eax, -1
    je .tc_fail

    mov eax, [net_gw_mac]
    mov [tcp_remote_mac], eax
    mov ax, [net_gw_mac+4]
    mov [tcp_remote_mac+4], ax

    ; Ephemeral port
    inc dword [tcp_port_ctr]
    mov eax, [tcp_port_ctr]
    add eax, 49152
    mov [tcp_local_port], eax

    ; Initial sequence number
    call get_timer_ticks
    imul eax, 1103515245
    add eax, 12345
    mov [tcp_send_seq], eax
    mov dword [tcp_send_ack], 0

    ; Serial debug: TCP connect starting
    mov dx, 0x3F8
    mov al, 'T'
    out dx, al

    ; Send SYN
    push dword 0               ; data_len
    push dword 0               ; data_ptr
    push dword TCP_SYN
    call tcp_send_seg
    add esp, 12

    ; Serial debug: SYN sent
    mov dx, 0x3F8
    mov al, 'S'
    out dx, al

    ; Wait for SYN-ACK (2 second timeout)
    call get_timer_ticks
    mov esi, eax
    add esi, 200

.tc_poll:
    call get_timer_ticks
    cmp eax, esi
    jge .tc_fail

    push dword 2048
    lea eax, [net_rcv_buf]
    push eax
    call e1000_receive_packet
    add esp, 8

    test eax, eax
    jz .tc_poll

    ; Serial: received a packet during SYN-ACK wait
    push eax
    mov dx, 0x3F8
    mov al, 'R'
    out dx, al
    pop eax

    lea ebx, [net_rcv_buf]
    ; IPv4 + TCP?
    cmp word [ebx+12], 0x0008
    jne .tc_poll
    cmp byte [ebx+23], 6
    jne .tc_poll

    ; Serial: got IPv4+TCP packet
    mov dx, 0x3F8
    mov al, 'I'
    out dx, al
    ; Our port?
    movzx eax, word [ebx+36]
    xchg al, ah
    cmp eax, [tcp_local_port]
    jne .tc_poll
    ; SYN+ACK?
    mov al, [ebx+47]
    and al, (TCP_SYN | TCP_ACK)
    cmp al, (TCP_SYN | TCP_ACK)
    jne .tc_poll

    ; Serial: SYN-ACK received!
    mov dx, 0x3F8
    mov al, 'A'
    out dx, al

    ; Got SYN-ACK! Extract remote seq
    mov eax, [ebx+38]          ; remote seq (NBO)
    bswap eax
    inc eax                    ; SYN counts as 1
    mov [tcp_send_ack], eax

    ; Advance our seq (SYN counts as 1)
    inc dword [tcp_send_seq]

    ; Send ACK
    push dword 0
    push dword 0
    push dword TCP_ACK
    call tcp_send_seg
    add esp, 12

    mov dword [tcp_state], 2   ; ESTABLISHED

    ; Longer delay to let SLiRP fully process the ACK and establish the real connection
    push dword 20              ; 200ms
    call sleep_ticks
    add esp, 4

    xor eax, eax
    jmp .tc_done

.tc_fail:
    ; Serial: TCP connect FAILED
    mov dx, 0x3F8
    mov al, 'X'
    out dx, al
    mov dword [tcp_state], 0
    mov eax, -1
.tc_done:
    pop esi
    pop ebx
    pop ebp
    ret

; --- TCP Send ---
; net_tcp_send(data_ptr, data_len) -> 0
net_tcp_send:
    push ebp
    mov ebp, esp

    ; Serial: sending data, dump TCP header checksum after send
    mov dx, 0x3F8
    mov al, 'D'
    out dx, al

    push dword [ebp+12]       ; data_len
    push dword [ebp+8]        ; data_ptr
    push dword (TCP_PSH | TCP_ACK)
    call tcp_send_seg
    add esp, 12

    ; Advance send_seq
    mov eax, [ebp+12]
    add [tcp_send_seq], eax

    xor eax, eax
    pop ebp
    ret

; --- TCP Receive (accumulate until FIN or timeout) ---
; net_tcp_recv(buffer, max_len, timeout_ticks) -> total bytes received
net_tcp_recv:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    sub esp, 4                 ; local: total_received

    mov dword [ebp-16], 0     ; total_received = 0
    mov edi, [ebp+8]          ; buffer

    ; Serial: waiting for data
    mov dx, 0x3F8
    mov al, 'W'
    out dx, al

    ; Debug: dump E1000 RDH, RDT, rx_cur
    mov dx, 0x3F8
    mov al, '['
    out dx, al
    ; RDH
    mov eax, E1000_RDH
    add eax, [e1000_mmio_base]
    mov eax, [eax]
    add al, '0'
    out dx, al
    ; RDT
    mov al, ':'
    out dx, al
    mov eax, E1000_RDT
    add eax, [e1000_mmio_base]
    mov eax, [eax]
    add al, '0'
    out dx, al
    ; rx_cur
    mov al, ':'
    out dx, al
    mov eax, [e1000_rx_cur]
    add al, '0'
    out dx, al
    mov al, ']'
    out dx, al

    call get_timer_ticks
    mov esi, eax
    add esi, [ebp+16]         ; deadline

.tr_poll:
    call get_timer_ticks
    cmp eax, esi
    jge .tr_done

    push dword 2048
    lea eax, [net_rcv_buf]
    push eax
    call e1000_receive_packet
    add esp, 8

    test eax, eax
    jz .tr_poll

    ; Serial: got packet in recv loop
    push eax
    mov dx, 0x3F8
    mov al, 'p'
    out dx, al
    pop eax

    lea ebx, [net_rcv_buf]
    ; IPv4?
    cmp word [ebx+12], 0x0008
    jne .tr_poll
    ; TCP?
    cmp byte [ebx+23], 6
    jne .tr_poll

    ; Serial: IPv4+TCP in recv
    push eax
    mov dx, 0x3F8
    mov al, 't'
    out dx, al
    ; Print dest port
    movzx eax, word [ebx+36]
    xchg al, ah
    ; Print low byte as hex
    push eax
    shr eax, 8
    and al, 0x0F
    cmp al, 10
    jl .tr_dbg_ph
    add al, 55
    jmp .tr_dbg_pho
.tr_dbg_ph:
    add al, 48
.tr_dbg_pho:
    out dx, al
    pop eax
    and al, 0x0F
    cmp al, 10
    jl .tr_dbg_pl
    add al, 55
    jmp .tr_dbg_plo
.tr_dbg_pl:
    add al, 48
.tr_dbg_plo:
    out dx, al
    pop eax

    movzx eax, word [ebx+36]
    xchg al, ah
    cmp eax, [tcp_local_port]
    jne .tr_poll

    ; Check for RST
    test byte [ebx+47], TCP_RST
    jnz .tr_done

    ; Get IP total length
    movzx ecx, word [ebx+16]
    xchg cl, ch

    ; TCP data offset
    movzx edx, byte [ebx+46]
    shr edx, 4
    shl edx, 2                ; TCP header size in bytes

    ; Data length = IP_total - 20(IP) - TCP_header
    sub ecx, 20
    sub ecx, edx
    jle .tr_no_data

    ; Note: serial debug here MUST save/restore edx
    ; because 'mov dx, 0x3F8' corrupts TCP header size in edx

    ; Check buffer space
    mov eax, [ebp-16]         ; total so far
    add eax, ecx
    cmp eax, [ebp+12]         ; max_len
    jle .tr_copy
    ; Truncate
    mov ecx, [ebp+12]
    sub ecx, [ebp-16]
    test ecx, ecx
    jle .tr_no_data
.tr_copy:
    ; Copy data: source = ebx + 34 + tcp_hdr_size
    push ecx
    push esi
    lea esi, [ebx+34]
    add esi, edx              ; skip TCP header
    push edi
    add edi, [ebp-16]         ; offset in output buffer
    rep movsb
    pop edi
    pop esi
    pop ecx
    add [ebp-16], ecx

.tr_no_data:
    ; Compute proper ACK value
    mov eax, [ebx+38]         ; remote seq (NBO)
    bswap eax
    add eax, ecx              ; + data_len (may be 0)

    ; If FIN, add 1
    test byte [ebx+47], TCP_FIN
    jz .tr_no_fin
    inc eax
.tr_no_fin:

    ; Update our ACK and send it
    cmp eax, [tcp_send_ack]
    je .tr_no_ack
    mov [tcp_send_ack], eax
    push dword 0
    push dword 0
    push dword TCP_ACK
    call tcp_send_seg
    add esp, 12
.tr_no_ack:

    ; If FIN received, we're done
    test byte [ebx+47], TCP_FIN
    jnz .tr_done

    ; Got data — extend timeout for more
    call get_timer_ticks
    mov esi, eax
    add esi, 100              ; 1s extra wait for next segment

    jmp .tr_poll

.tr_done:
    ; Serial: recv done, total bytes
    mov dx, 0x3F8
    mov al, 'Z'
    out dx, al
    mov eax, [ebp-16]         ; return total bytes
    add esp, 4
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

; --- TCP Close ---
net_tcp_close:
    push dword 0
    push dword 0
    push dword (TCP_FIN | TCP_ACK)
    call tcp_send_seg
    add esp, 12
    inc dword [tcp_send_seq]   ; FIN counts as 1
    mov dword [tcp_state], 0   ; CLOSED
    ret

; --- HTTP GET ---
; net_http_get(response_buf, max_len) -> response length, or -1 on failure
net_http_get:
    push ebp
    mov ebp, esp

    ; Connect to 10.0.2.2:8080
    push dword 8080
    push dword [net_gateway_ip]
    call net_tcp_connect
    add esp, 8

    cmp eax, -1
    je .hg_fail

    ; Send HTTP GET /
    push dword http_get_req_len
    lea eax, [http_get_req]
    push eax
    call net_tcp_send
    add esp, 8

    ; Receive response (5 second timeout)
    push dword 500
    push dword [ebp+12]
    push dword [ebp+8]
    call net_tcp_recv
    add esp, 12
    ; eax = bytes received
    jmp .hg_done

.hg_fail:
    mov eax, -1
.hg_done:
    pop ebp
    ret

; --- wget helper functions for ArnoldC ---

; net_wget() -> response length (data stored in wget_response buffer)
net_wget:
    push ebx
    push dword 4095
    lea eax, [wget_response]
    push eax
    call net_http_get
    add esp, 8

    ; Null-terminate
    cmp eax, -1
    je .wget_fail
    cmp eax, 0
    je .wget_fail
    mov byte [wget_response + eax], 0
    mov [wget_resp_len], eax

    pop ebx
    ret
.wget_fail:
    mov dword [wget_resp_len], 0
    xor eax, eax
    pop ebx
    ret

; net_wget_get_byte(index) -> ASCII byte at position
net_wget_get_byte:
    mov ecx, [esp+4]
    movzx eax, byte [wget_response + ecx]
    ret

; net_wget_get_len() -> response length
net_wget_get_len:
    mov eax, [wget_resp_len]
    ret

; ============================================================================
; "HASTA LA VISTA, BABY" - End of bootloader
; ============================================================================
