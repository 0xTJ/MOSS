.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

.code

; char *strcpy(char *dest, const char *src)
.proc strcpy
        setup_frame

        sep     #$20    ; Set main data to 8-bit
        rep     #$10    ; Set index registers to 16-bit

        ; Load Y with dest, X with src
        ldy     z:3
        ldx     z:5

        bra     skip_first_inc

loop:
        inx
        iny
skip_first_inc:
        lda     a:0,x
        sta     a:0,y
        bnz     loop

        lda     z:3

        restore_frame
        rts
.endproc

; size_t strlen(const char *str)
.export strlen
.proc strlen
        setup_frame

        ; Load initial values
        rep     #$10
        sep     #$20
        ldy     #0      ; Count variable
        ldx     z:3     ; Pointer within string

        bra     skip_first_inc

loop:
        inx
        iny
skip_first_inc:
        lda     a:0,x
        bnz     loop

done:
        rep     #$30
        tya

        restore_frame
        rts
.endproc

;int strcmp (const char *str1, const char *str2)
.export strcmp
.proc strcmp
        setup_frame

        rep     #$30
        ldx     #0

loop:        
        lda     z:3,x
        sub     z:5,x
        
        bne     done
        
        ldy     z:3,x
        bze     done
        
        inx
        
        bra     loop
        
done:
        restore_frame
        rts
.endproc
