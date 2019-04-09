.p816
.smart

.macpack generic

.include "stdio.inc"
.include "functions.inc"
.include "string.inc"
.include "unistd.inc"

.code

; int fgetc(FILE *stream)
.proc fgetc
        enter   2
        
        ; 0: int c
        
        stz     z:var 0 ; c

        pea     1       ; read 1 byte
        tdc
        add     #var 0  ; Space for read value
        pha
        ldx     z:arg 0 ; stream
        lda     a:FILE::fd,x
        pha             ; File Descriptor
        jsr     read
        rep     #$30
        ply
        ply
        ply

        ; If read returned -1, return EOF
        cmp     #$FFFF
        beq     failed

        ; Load read value for return
        lda     z:var 0

done:
        leave
        rts

failed:
        lda     #EOF
        bra     done
.endproc
