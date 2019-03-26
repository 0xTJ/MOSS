.p816
.smart

.macpack generic

.include "stdlib.inc"
.include "functions.inc"
.include "builtin.inc"

.code

; long int labs(long int n)
.proc labs
        enter
        rep     #$30

        lda     arg 0 ; loword(n)
        ldx     arg 2 ; hiword(n)
        bpl     done ; Skip if already positive

        ; Invert lobyte(n)
        eor     #$FFFF

        ; Invert hibyte(n)
        pha
        txa
        eor     #$FFFF
        tax
        pla

        ; Add 1 to inverted lobyte(n)
        add     #1

        ; If no carry, we're done
        bcc     done

        ; Otherwise, add 1 to inverted hibyte(n)
        inx

done:
        leave
        rts
.endproc
