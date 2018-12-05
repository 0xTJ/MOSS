.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

.code

; int putchar(int c)
.export putchar
.proc putchar
        setup_frame
        
        inc     disable_scheduler
        
        lda     z:3
        sep     #$20

        ; Fix ROM functions not allowing D != 0
        phd
        pea     $0000
        pld
        
        jsl     PUT_CHR
        
        ; Restore D
        pld
        
        dec     disable_scheduler
        
        restore_frame
        rts
.endproc

; int puts(const char *s)
.export puts
.proc puts
        setup_frame
        
        inc     disable_scheduler

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
        
        dec     disable_scheduler

        restore_frame
        rts
.endproc
