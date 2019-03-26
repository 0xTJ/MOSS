.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.code

; int fputc(int c, FILE *stream)
.proc fputc
        enter
        rep     #$30

        pea     1       ; write 1 byte
        tdc
        add     #arg 0  ; &c
        pha
        ldx     z:arg 2 ; stream
        lda     a:FILE::fd,x
        pha             ; File Descriptor
        jsr     write

        leave
        rts
.endproc
