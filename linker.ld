/*
 * ============================================================================
 * TOARUOS-ARNOLD LINKER SCRIPT
 * "GET TO THE CHOPPER" - Memory layout for our muscular kernel
 * ============================================================================
 * 
 * This linker script places the kernel at 1MB (0x100000), which is the
 * standard location for multiboot kernels loaded by GRUB.
 * 
 * Memory Layout:
 *   0x00000000 - 0x000FFFFF : Real mode stuff, BIOS, etc.
 *   0x00100000 - onwards    : Our kernel ("I'LL BE BACK")
 * 
 * "COME WITH ME IF YOU WANT TO LINK"
 * ============================================================================
 */

/* Entry point - where the Terminator first appears */
ENTRY(_start)

/* Sections - "THIS IS WHAT I AM" */
SECTIONS
{
    /* Start at 1MB - "GET YOUR ASS TO MARS" (well, 1MB) */
    . = 1M;

    /* Multiboot header must be first - "LISTEN TO ME VERY CAREFULLY, GRUB" */
    .multiboot ALIGN(4K) :
    {
        *(.multiboot)
    }

    /* Text section (code) - "DO IT NOW" */
    .text ALIGN(4K) :
    {
        *(.text)
        *(.text.*)
    }

    /* Read-only data - "YOU SET US UP" */
    .rodata ALIGN(4K) :
    {
        *(.rodata)
        *(.rodata.*)
    }

    /* Initialized data - "HEY CHRISTMAS TREE" */
    .data ALIGN(4K) :
    {
        *(.data)
        *(.data.*)
    }

    /* Uninitialized data (BSS) - "I NEED YOUR MEMORY" */
    .bss ALIGN(4K) :
    {
        *(COMMON)
        *(.bss)
        *(.bss.*)
    }

    /* End of kernel - "YOU HAVE BEEN TERMINATED" */
    _kernel_end = .;
}
