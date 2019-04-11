.p816
.smart

.macpack generic

.include "ctype.inc"
.include "functions.inc"

.code

; int isdigit (int c)
.proc isdigit
        enter

        lda     z:arg 0 ; c
        bmi     is_not
        cmp     #$30
        blt     is_not
        cmp     #$3A
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
