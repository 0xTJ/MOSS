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
        setup_frame
        rep     #$30

        pea     1   ; write 1 byte
        tdc
        add     #3
        pha         ; &c
        pea     1   ; stdout

        jsr     write

        restore_frame
        rts
.endproc

; int puts(const char *s)
.proc puts
        setup_frame
        rep     #$30

        lda     z:3 ; s
        pha

        jsr     strlen
        rep     #$30
        ply

        pha         ; strlen(s)
        lda     z:3 ; s
        pha         ; s
        pea     1   ; stdout
        jsr     write
        rep     #$30
        ply
        ply
        ply

        pea     a:10    ; NL
        jsr     putchar
        rep     #$30
        ply

        restore_frame
        rts
.endproc
