.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.code

; int fputs(const char *s, FILE * stream)
.proc fputs
        enter
        rep     #$30

        lda     z:arg 0 ; s
        pha
        jsr     strlen
        rep     #$30
        ply

        pha             ; strlen(s)
        lda     z:arg 0 ; s
        pha
        ldx     z:arg 2 ; stream
        lda     a:FILE::fd,x
        pha             ; File Descriptor
        jsr     write

        leave
        rts
.endproc
