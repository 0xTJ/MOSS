.p816
.smart

.macpack generic

.include "ctype.inc"
.include "functions.inc"

.code

; int toupper (int c)
.proc toupper
        enter

        ; Check if it is a lowercase letter
        lda     z:arg 0 ; c
        pha
        jsr     islower
        rep     #$30
        ply

        ; Skip if it is not lowercase
        tax
        lda     z:arg 0 ; c
        cpx     #0
        beq     done

        sub     #'a' - 'A'

done:
        leave
        rts
.endproc
