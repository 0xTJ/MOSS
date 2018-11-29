.p816

.macpack generic

.autoimport

.include "functions.inc"

; char *strcpy(char *dest, const char *src)
.proc strcpy
        setup_frame

        sep     #$20    ; Set main data to 8-bit
        rep     #$10    ; Set index registers to 16-bit
        
        ; Load Y with dest, X with src
        ldy     z:1
        ldx     z:3
        
        bra     skip_first_inc
        
loop:
        inx
        iny
skip_first_inc:
        lda     0,x
        sta     0,y
        bnz     loop
        
        lda     z:1

        restore_frame
        rts
.endproc
