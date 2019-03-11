.p816
.smart

.macpack generic

.include "functions.inc"
.include "proc.inc"
.include "dev.inc"
.include "w65c265s.inc"
.include "isr.inc"

.bss

prgload_driver:
        .tag    CharDriver

.rodata

prgload_name:
        .asciiz "prgload"
.export user_o65
user_o65:
        .incbin "../../../user/user.o65"

.code

.constructor dev_prgload_init
.proc dev_prgload_init
        rep     #$30

        ; Load driver struct address to X
        ldx     #prgload_driver

        ; Write read function pointer to driver struct
        lda     #dev_prgload_read
        sta     a:CharDriver::read,x

        ; Register driver with kernel
        pea     DEV_TYPE_CHAR
        pea     prgload_name
        pea     prgload_driver
        jsr     register_driver
        rep     #$30
        ply
        ply
        ply

        rts
.endproc

; ssize_t dev_prgload_read(struct CharDriver *device, void *buf, size_t nbytes, off_t offset)
.proc dev_prgload_read
        enter_nostackvars
        rep     #$10
        sep     #$20

        ldx     5 ; buf
        ldy     #0

loop:
        cpy     z:7 ; nbytes
        beq     done_loop

        lda     a:user_o65,y

        ; Store received byte in output buffer
        sta     a:0,x

        ; Increment buffer pointer and decrement number of bytes
        inx
        iny

        bra     loop

done_loop:

        rep     #$30
        lda     z:7 ; nbytes

        leave_nostackvars
        rts
.endproc
