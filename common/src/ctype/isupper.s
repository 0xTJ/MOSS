.p816
.smart

.macpack generic

.include "ctype.inc"
.include "functions.inc"

.code

; int isupper (int c)
.proc isupper
        enter

        lda     z:arg 0 ; c
        bmi     is_not
        cmp     #$41
        blt     is_not
        cmp     #$5B
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
