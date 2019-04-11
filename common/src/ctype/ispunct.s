.p816
.smart

.macpack generic

.include "ctype.inc"
.include "functions.inc"

.code

; int ispunct (int c)
.proc ispunct
        enter

        lda     z:arg 0 ; c
        bmi     is_not
        cmp     #$21
        blt     is_not
        cmp     #$30
        blt     is
        cmp     #$3A
        blt     is_not
        cmp     #$41
        blt     is
        cmp     #$5B
        blt     is_not
        cmp     #$61
        blt     is
        cmp     #$7B
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
