.p816
.smart

.macpack generic

.include "functions.inc"
.include "proc.inc"
.include "dev.inc"
.include "w65c265s.inc"
.include "isr.inc"

.bss

init_driver:
        .tag    CharDriver

.rodata

init_name:
        .asciiz "init"
init_o65:
        .incbin "../../../init/init.o65"

.code

.constructor dev_init_init
.proc dev_init_init
        enter
        rep     #$30

        ; Load driver struct address to X
        ldx     #init_driver

        ; Write read function pointer to driver struct
        lda     #dev_init_read
        sta     a:CharDriver::read,x

        ; Register driver with kernel
        pea     DEV_TYPE_CHAR
        pea     init_name
        pea     init_driver
        jsr     register_driver
        rep     #$30
        ply
        ply
        ply

        leave
        rts
.endproc

; ssize_t dev_init_read(struct CharDriver *device, void *buf, size_t nbytes, off_t offset)
.proc dev_init_read
        enter
        rep     #$10
        sep     #$20

        ldx     z:arg 2 ; buf
        ldy     #0

loop:
        cpy     z:arg 4 ; nbytes
        beq     done_loop

        lda     a:init_o65,y

        ; Store received byte in output buffer
        sta     a:0,x

        ; Increment buffer pointer and decrement number of bytes
        inx
        iny

        bra     loop

done_loop:

        rep     #$30
        lda     z:arg 4 ; nbytes

        leave
        rts
.endproc
