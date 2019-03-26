.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.code

; char *gets(char *str)
.proc gets
        enter
        rep     #$30

        pea     stdin
        lda     z:arg 0 ; str
        pha
        jsr     fgets

done:
        leave
        rts
.endproc
