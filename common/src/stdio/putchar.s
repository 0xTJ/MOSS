.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.code

; int putchar(int c)
.proc putchar
        enter
        rep     #$30

        pea     stdout
        lda     z:arg 0 ; c
        pha
        jsr     fputc

        leave
        rts
.endproc
