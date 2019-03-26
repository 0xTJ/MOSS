.p816
.smart

.macpack generic

.include "string.inc"
.include "functions.inc"

.code

; char *strcpy(char *dest, const char *src)
.export strcpy
.proc strcpy
        enter

        sep     #$20    ; Set main data to 8-bit
        rep     #$10    ; Set index registers to 16-bit

        ; Load Y with dest, X with src
        ldy     z:arg 0 ; dest
        ldx     z:arg 2 ; src

        bra     skip_first_inc

loop:
        inx
        iny
skip_first_inc:
        lda     a:0,x
        sta     a:0,y
        bnz     loop

        lda     z:arg 0 ; dest

        leave
        rts
.endproc
