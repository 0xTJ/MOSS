.p816
.smart

.macpack generic

.include "ctype.inc"
.include "functions.inc"

.code

; int isgraph (int c)
.proc isgraph
        enter

        lda     z:arg 0 ; c
        bmi     is_not
        cmp     #$21
        blt     is_not
        cmp     #$7F
        blt     is
        bra     is_not

is_not:
        lda     #0
        bra     done

is:
        lda     #1
        bra     done

done:
        leave
        rts
.endproc
