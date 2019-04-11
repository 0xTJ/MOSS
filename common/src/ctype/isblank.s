.p816
.smart

.macpack generic

.include "ctype.inc"
.include "functions.inc"

.code

; int isblank (int c)
.proc isblank
        enter

        lda     z:arg 0 ; c
        bmi     is_not
        cmp     #$09
        blt     is_not
        cmp     #$0A
        blt     is
        cmp     #$20
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
