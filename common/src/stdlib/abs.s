.p816
.smart

.macpack generic

.include "stdlib.inc"
.include "functions.inc"
.include "builtin.inc"

.code

; int abs(int n)
.proc abs
        enter
        rep     #$30

        lda     arg 0 ; n
        bpl     is_positive ; Skip if already positive

        eor     #$FFFF
        inc

is_positive:

        leave
        rts
.endproc
