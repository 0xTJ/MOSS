.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.code

; int getchar(void)
.proc getchar
        enter
        rep     #$30

        pea     stdin
        jsr     fgetc

done:
        leave
        rts
.endproc
