.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

; int putchar(int c)
.export putchar
.proc putchar
        setup_frame
        
        lda     z:3
        sep     #$20

        ; Fix ROM functions not allowing D != 0
        phd
        pea     $0000
        pld
        
        jsl     PUT_CHR
        
        ; Restore D
        pld

        restore_frame
        rts
.endproc

; int puts(const char *s)
.export puts
.proc puts
        setup_frame

        rep     #$10
        sep     #$20

        lda     #00
        ldx     z:3

        ; Fix ROM functions not allowing D != 0
        phd
        pea     $0000
        pld
        
        jsl     PUT_STR
        jsl     SEND_CR
        
        ; Restore D
        pld

        restore_frame
        rts
.endproc
