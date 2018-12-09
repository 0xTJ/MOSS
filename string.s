.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

.code

; char *strcpy(char *dest, const char *src)
.export strcpy
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

        rep     #$10
        sep     #$20
        ldy     #0

loop:
        lda     (3),y
        sub     (5),y
        bnz     sign_extend

        lda     (3),y
        bze     sign_extend

        iny

        bra     loop

sign_extend:
        ; Sign-extend A
        rep     #$30
        bit     #$80    ; Negative bit
        bze     clear_upper_byte
set_upper_byte:
        ora     #$FF00
        bra     done
clear_upper_byte:
        and     #$00FF
done:
        restore_frame
        rts
.endproc

; int memset (void *ptr, int value, size_t num)
.export memset
.proc memset
        setup_frame
        rep     #$30

        ldx     z:7 ; num
        bze     done

        lda     z:5 ; value
        
        ; Manually store once, will be used as source for copy
        sep     #$20
        sta     (3) ; *ptr
        dex     ; num - 1
        bze     done
        rep     #$30

        txa     ; num - 1
        dec     ; num - 2
        ldx     z:3 ; ptr
        txy     ; ptr
        iny     ; ptr + 1

        ; Run mvn with:
        ; A: num - 2
        ; X: ptr (source of MVN)
        ; Y: ptr + 1 (destination of MVN)
        ; Src and dst banks 0
        mvn     0, 0

done:
        rep    #$30
        restore_frame
        rts
.endproc
