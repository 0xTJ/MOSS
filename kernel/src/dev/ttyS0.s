.p816
.smart

.macpack generic

.include "functions.inc"
.include "proc.inc"
.include "dev.inc"
.include "mensch.inc"
.include "w65c265s.inc"

.bss

ttyS0_driver:
        .tag    CharDriver

.rodata

ttyS0_name:
        .asciiz "ttyS0"

.code

.constructor dev_ttyS0_init
.proc dev_ttyS0_init
        rep     #$30
        
        ldx     #ttyS0_driver

        lda     #dev_ttyS0_read
        sta     a:CharDriver::read,x

        lda     #dev_ttyS0_write
        sta     a:CharDriver::write,x

        pea     DEV_TYPE_CHAR
        pea     ttyS0_name
        pea     ttyS0_driver
        jsr     register_driver
        rep     #$30
        ply
        ply
        ply

        rts
.endproc

; ssize_t dev_ttyS0_read(struct CharDriver *device, void *buf, size_t nbytes, off_t offset)
.proc dev_ttyS0_read
        setup_frame
        rep     #$30

        ldx     z:5 ; buf
        ldy     z:7 ; nbytes

        ; Fix ROM functions not allowing D != 0
        phd
        pea     $0000
        pld

        sep     #$20

loop:
        cpy     #0
        beq     done_loop

        phx
        phy

        jsl     GET_CHR

        rep     #$10
        sep     #$20

        sta     a:0,x

        ply
        plx

        ; Increment buffer pointer and decrement number of bytes
        inx
        dey

        bra     loop

done_loop:
        ; Restore D
        pld

        rep     #$30
        lda     z:7 ; nbytes

        restore_frame
        rts
.endproc

; ssize_t dev_ttyS0_write(struct CharDriver *device, const void *buf, size_t nbytes, off_t offset)
.proc dev_ttyS0_write
        setup_frame
        rep     #$30
        
        ldx     z:5 ; buf
        ldy     z:7 ; nbytes

        ; Fix ROM functions not allowing D != 0
        phd
        pea     $0000
        pld

        sep     #$20

loop:
        cpy     #0
        beq     done_loop

        lda     a:0,x

        phx
        phy

        inc     disable_scheduler
        
        
send_loop:
        jsl     SEND_BYTE_TO_PC
        bcs     send_loop
        ; sta     ARTD3

        dec     disable_scheduler

        rep     #$10
        sep     #$20

        ply
        plx

        ; Increment buffer pointer and decrement number of bytes
        inx
        dey

        bra     loop

done_loop:
        
        sep     #$20
        lda     #$0F
        sta     PD7
        rep     #$20
        
        rep     #$30
        lda     z:7 ; nbytes

        ; Restore D
        pld

        restore_frame
        rts
.endproc
