.p816
.smart

.macpack generic

.include "functions.inc"
.include "string.inc"
.include "kio.inc"

.import dev_ttyS0_write
.import tx_head
.import tx_tail

.rodata

carriage_return:
        .byte   $0D, $00

.code

; void kputs(const char *str)
.proc kputs
        setup_frame

        rep     #$30

        lda     z:3
        pha
        jsr     strlen
        rep     #$30
        ply
        ply

        pea     0
        pha
        lda     z:3
        pha
        pea     0
        jsr     dev_ttyS0_write
        rep     #$30
        ply
        ply
        ply
        ply

        pea     0
        pea     1
        pea     carriage_return
        pea     0
        jsr     dev_ttyS0_write
        rep     #$30
        ply
        ply
        ply
        ply

loop:
        ; Skip waiting for transmission if interrupts are disabled
        sep     #$20
        php
        pla
        bit     #(1 << 2)
        bnz     done
        
        rep     #$20
        lda     tx_tail
        cmp     tx_head
        bne     loop
        
done:
        restore_frame
        rts
.endproc
