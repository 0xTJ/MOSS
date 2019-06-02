.p816
.smart

.macpack generic

.include "dev/ttyS0.inc"
.include "functions.inc"
.include "proc.inc"
.include "dev.inc"
.include "fs/devfs.inc"
.include "uart.inc"

.bss

ttyS0_driver:
        .tag    DeviceDriver

.rodata

ttyS0_name:
        .asciiz "ttyS0"

.code

; void dev_ttyS0_init(void)
.constructor dev_ttyS0_init
.proc dev_ttyS0_init
        enter

        ; Load driver struct address to X
        ldx     #ttyS0_driver

        ; Write read function pointer to driver struct
        lda     #dev_ttyS0_read
        sta     a:DeviceDriver::read,x

        ; Write write function pointer to driver struct
        lda     #dev_ttyS0_write
        sta     a:DeviceDriver::write,x

        ; Register driver with kernel
        pea     ttyS0_name
        pea     0
        pea     1
        jsr     register_devfs_entry
        rep     #$30
        ply
        ply

        leave
        rts
.endproc

; size_t dev_ttyS0_read(struct DeviceDriver *device, void *buf, size_t nbytes, off_t offset)
.proc dev_ttyS0_read
        enter
        sep     #$20

        ldy     z:arg 4 ; nbytes

loop:
        cpy     #0
        beq     done_loop

        phy
        jsr     UART3_getchar
        rep     #$10
        sep     #$20
        ply

        ; Store received byte in output buffer
        sta     (arg 2) ; *buf

        ; Increment buffer pointer and decrement number of bytes
        ldx     z:arg 2 ; buf
        inx
        stx     z:arg 2 ; buf
        dey

        bra     loop

done_loop:

        rep     #$30
        lda     z:arg 4 ; nbytes

        leave
        rts
.endproc

; ssize_t dev_ttyS0_write(struct DeviceDriver *device, const void *buf, size_t nbytes, off_t offset)
.proc dev_ttyS0_write
        enter
        rep     #$10
        sep     #$20

        ldy     z:arg 4 ; nbytes

loop:
        cpy     #0
        beq     done_loop

        ; Load a byte from input buffer
        lda     (arg 2) ; *buf

        phy
        pha
        jsr     UART3_putchar
        rep     #$10
        sep     #$20
        pla
        ply

        ; Increment buffer index and decrement number of bytes
        ldx     z:arg 2 ; buf
        inx
        stx     z:arg 2 ; buf
        dey

        bra     loop

done_loop:

        rep     #$30
        lda     z:arg 4 ; nbytes

        leave
        rts
.endproc
