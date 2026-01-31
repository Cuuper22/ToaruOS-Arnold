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
; "HASTA LA VISTA, BABY" - End of bootloader
; ============================================================================
