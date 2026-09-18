/*
 * GBA Startup and Header Assembly for FFXI Advance
 * Target: ARM7TDMI (armv4t)
 */
    .arm
    .section .header, "ax"
    .global _header
_header:
    /* 0x00: Branch to entry point */
    b       _start

    /* 0x04 - 0x9F: Nintendo Logo (156 bytes required for GBA BIOS verification) */
    .byte   0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21, 0x3D, 0x84, 0x82, 0x0A, 0x84, 0xE4, 0x09, 0xAD
    .byte   0x11, 0x24, 0x8B, 0x98, 0xC0, 0x81, 0x7F, 0x21, 0xA3, 0x52, 0xBE, 0x19, 0x93, 0x09, 0xCE, 0x22
    .byte   0x41, 0xE2, 0xF8, 0x14, 0xA5, 0x34, 0x01, 0xE3, 0x4B, 0x0C, 0x5B, 0xAA, 0x2B, 0xB0, 0xDD, 0x51
    .byte   0xD5, 0x6F, 0x38, 0xE4, 0xE9, 0x0C, 0x01, 0xEA, 0x86, 0x00, 0x67, 0x40, 0xC9, 0x0F, 0x86, 0x11
    .byte   0x61, 0x98, 0xBE, 0x71, 0x1D, 0x29, 0xE2, 0x49, 0x85, 0x41, 0x70, 0x18, 0xCA, 0x34, 0x09, 0x92
    .byte   0x17, 0x49, 0x7E, 0x59, 0x2D, 0x7D, 0xC8, 0x8D, 0x34, 0xD4, 0xD4, 0x00, 0x00, 0x52, 0x0F, 0xB1
    .byte   0x54, 0x9E, 0x1A, 0x66, 0x49, 0x42, 0x0E, 0x15, 0x1B, 0x2F, 0x70, 0x29, 0x25, 0x7F, 0x7E, 0x04
    .byte   0x53, 0x6E, 0x38, 0xA2, 0xF7, 0x39, 0x4F, 0x73, 0xFB, 0x73, 0x80, 0xF4, 0xDC, 0xB5, 0x62, 0x4E
    .byte   0x90, 0xFF, 0x7D, 0x64, 0xC7, 0x20, 0x42, 0x35, 0x54, 0xB6, 0x1E, 0x41, 0x7D, 0xC7, 0xC9, 0xC0
    .byte   0xA1, 0x7E, 0x55, 0x2D, 0x46, 0x4F, 0x94, 0x86, 0xD0, 0x48, 0x4D, 0x39

    /* 0xA0 - 0xAB: Title (12 bytes) */
    .ascii  "FFXI ADVANCE"

    /* 0xAC - 0xAF: Game Code (4 bytes) */
    .ascii  "BFFE"

    /* 0xB0 - 0xB1: Maker Code (2 bytes) */
    .ascii  "01"

    /* 0xB2: Fixed value */
    .byte   0x96

    /* 0xB3: Main unit code */
    .byte   0x00

    /* 0xB4: Device type */
    .byte   0x00

    /* 0xB5 - 0xBB: Reserved (7 bytes) */
    .byte   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

    /* 0xBC: Software version */
    .byte   0x00

    /* 0xBD: Checksum complement */
    .byte   0x9E

    /* 0xBE - 0xBF: Reserved (2 bytes) */
    .byte   0x00, 0x00

/* ========================================================================= */
    .section .text.entry, "ax"
    .global _start
    .type   _start, %function
_start:
    /* Switch to System / User mode with IRQs disabled (CPSR = 0xDF) */
    msr     cpsr_c, #0xDF
    ldr     sp, =__sp_usr

    /* Switch to IRQ mode to initialize IRQ stack (CPSR = 0xD2) */
    msr     cpsr_c, #0xD2
    ldr     sp, =__sp_irq

    /* Return to System mode (CPSR = 0x1F) with interrupts enabled later */
    msr     cpsr_c, #0xDF

    /* Copy .data segment from ROM to EWRAM */
    ldr     r0, =__data_start
    ldr     r1, =__data_end
    ldr     r2, =__data_load
.copy_data_loop:
    cmp     r0, r1
    bhs     .copy_data_done
    ldr     r3, [r2], #4
    str     r3, [r0], #4
    b       .copy_data_loop
.copy_data_done:

    /* Zero out .bss segment in EWRAM */
    ldr     r0, =__bss_start
    ldr     r1, =__bss_end
    mov     r2, #0
.zero_bss_loop:
    cmp     r0, r1
    bhs     .zero_bss_done
    str     r2, [r0], #4
    b       .zero_bss_loop
.zero_bss_done:

    /* Branch to main() in C */
    ldr     r3, =main
    mov     lr, pc
    bx      r3

    /* Infinite halt loop if main ever returns */
.halt_loop:
    b       .halt_loop
    .size   _start, . - _start

/* =========================================================================
 * Bare-metal C runtime memory helpers
 * ========================================================================= */
    .global memcpy
    .global __aeabi_memcpy
    .global __aeabi_memcpy4
    .global __aeabi_memcpy8
    .type   memcpy, %function
    .type   __aeabi_memcpy, %function
    .type   __aeabi_memcpy4, %function
    .type   __aeabi_memcpy8, %function
memcpy:
__aeabi_memcpy:
__aeabi_memcpy4:
__aeabi_memcpy8:
    push    {r4, lr}
    mov     r3, r0          /* preserve dest */
.Lmemcpy_loop:
    cmp     r2, #0
    beq     .Lmemcpy_done
    ldrb    r4, [r1], #1
    strb    r4, [r3], #1
    sub     r2, r2, #1
    b       .Lmemcpy_loop
.Lmemcpy_done:
    pop     {r4, pc}

    .global memset
    .global __aeabi_memset
    .global __aeabi_memclr
    .global __aeabi_memclr4
    .global __aeabi_memclr8
    .type   memset, %function
    .type   __aeabi_memset, %function
    .type   __aeabi_memclr, %function
    .type   __aeabi_memclr4, %function
    .type   __aeabi_memclr8, %function
memset:
    push    {lr}
    mov     r3, r0
.Lmemset_loop:
    cmp     r2, #0
    beq     .Lmemset_done
    strb    r1, [r3], #1
    sub     r2, r2, #1
    b       .Lmemset_loop
.Lmemset_done:
    pop     {pc}

__aeabi_memset:
    /* __aeabi_memset(void *dest, size_t n, int c) -> note arg order is (r0=dest, r1=n, r2=c) */
    push    {lr}
    mov     r3, r1      /* r3 = n */
    mov     r1, r2      /* r1 = c */
    mov     r2, r3      /* r2 = n */
    bl      memset
    pop     {pc}

__aeabi_memclr:
__aeabi_memclr4:
__aeabi_memclr8:
    push    {lr}
    mov     r2, r1      /* r2 = n */
    mov     r1, #0      /* r1 = 0 */
    bl      memset
    pop     {pc}

