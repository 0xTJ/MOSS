.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.code

; int puts(const char *s)
.proc puts
        enter
        rep     #$30

        pea     stdout
        lda     z:arg 0 ; s
        pha
        jsr     fputs
        rep     #$30
        ply
        ply

        pea     stdout
        pea     $0A     ; LF
        jsr     putchar

        leave
        rts
.endproc
