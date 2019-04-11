.p816
.smart

.macpack generic

.include "ctype.inc"
.include "functions.inc"

.code

; int isspace (int c)
.proc isspace
        enter

        lda     z:arg 0 ; c
        bmi     is_not
        cmp     #$09
        blt     is_not
        cmp     #$21
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
