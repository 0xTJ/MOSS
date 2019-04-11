.p816
.smart

.macpack generic

.include "ctype.inc"
.include "functions.inc"

.code

; int tolower (int c)
.proc tolower
        enter

        ; Check if it is a lowercase letter
        lda     z:arg 0 ; c
        pha
        jsr     isupper
        rep     #$30
        ply

        ; Skip if it is not lowercase
        tax
        lda     z:arg 0 ; c
        cpx     #0
        beq     done

        add     #'a' - 'A'

done:
        leave
        rts
.endproc
