.p816
.smart

.macpack generic

.include "string.inc"
.include "functions.inc"

.code

;int strcmp (const char *str1, const char *str2)
.export strcmp
.proc strcmp
        enter

        rep     #$10
        sep     #$20
        ldy     #0

loop:
        lda     (arg 0),y
        sub     (arg 2),y
        bnz     sign_extend

        lda     (arg 0),y
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
        leave
        rts
.endproc
