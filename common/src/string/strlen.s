.p816
.smart

.macpack generic

.include "string.inc"
.include "functions.inc"

.code

; size_t strlen(const char *str)
.export strlen
.proc strlen
        enter

        ; Load initial values
        rep     #$10
        sep     #$20
        ldy     #0      ; Count variable
        ldx     z:arg 0 ; Pointer within string

        bra     skip_first_inc

loop:
        inx
        iny
skip_first_inc:
        lda     a:0,x
        bnz     loop

done:
        rep     #$30
        tya

        leave
        rts
.endproc
