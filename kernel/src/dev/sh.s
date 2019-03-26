.p816
.smart

.macpack generic

.include "functions.inc"
.include "proc.inc"
.include "dev.inc"
.include "w65c265s.inc"
.include "isr.inc"

.bss

sh_driver:
        .tag    CharDriver

.rodata

sh_name:
        .asciiz "sh"
sh_o65:
        .incbin "../../../sh/sh.o65"

.code

.constructor dev_sh_init
.proc dev_sh_init
        enter
        rep     #$30

        ; Load driver struct address to X
        ldx     #sh_driver

        ; Write read function pointer to driver struct
        lda     #dev_sh_read
        sta     a:CharDriver::read,x

        ; Register driver with kernel
        pea     DEV_TYPE_CHAR
        pea     sh_name
        pea     sh_driver
        jsr     register_driver
        rep     #$30
        ply
        ply
        ply

        leave
        rts
.endproc

; ssize_t dev_sh_read(struct CharDriver *device, void *buf, size_t nbytes, off_t offset)
.proc dev_sh_read
        enter
        rep     #$10
        sep     #$20

        ldx     z:arg 2 ; buf
        ldy     #0

loop:
        cpy     z:arg 4 ; nbytes
        beq     done_loop

        lda     a:sh_o65,y

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
