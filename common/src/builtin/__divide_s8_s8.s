.p816
.smart

.macpack generic

.include "functions.inc"
.include "builtin.inc"

.code

; cdiv_t __divide_s8_s8(char dividend, char divisor)
.proc __divide_s8_s8
        enter
        sep     #$30

        lda     z:arg 1 ; divisor
        bpl     divisor_positive
divisor_negative:
        ; Push negative divisor flag
        ldy     #1
        phy
        ; Negate and replace divisor in frame
        eor     #$FF
        inc
        sta     z:arg 1 ; divisor
        ; Done making divisor absolute
        bra     done_divisor
divisor_positive:
        ; Push positive divisor flag
        ldy     #0
        phy
done_divisor:

        lda     z:arg 0 ; dividend
        bpl     dividend_positive
dividend_negative:
        ; Push negative dividend flag
        ldy     #1
        phy
        ; Negate and replace dividend in frame
        eor     #$FF
        inc
        sta     z:arg 0 ; dividend
        ; Done making dividend absolute
        bra     done_dividend
dividend_positive:
        ; Push positive dividend flag
        ldy     #0
        phy
done_dividend:

        lda     z:arg 1 ; divisor
        pha
        lda     z:arg 0 ; dividend
        pha
        jsr     __divide_u8_u8
        ; Put remainder into X
        sep     #$30
        tax
        xba
        ; Pull arguments to unsigned division call
        ply
        ply

        ; Fix values for negative dividend
        ply         ; 1 if dividend was negative
        bze     done_fix_result_neg_dividend

        ; Negate quotient
        eor     #$FF
        inc

        cpx     #0  ; Compare remainder to 0
        beq     done_fix_result_neg_dividend

        ; Make remainder to be divisor - remainder
        pha         ; quotient
        txa
        ; Negate remainder
        eor     #$FF
        inc
        tax         ; Put fixed remainder back into X
        pla         ; Restore quotient to A

done_fix_result_neg_dividend:

        ; Fix values for negative divisor
        ply     ; 1 if divisor was negative
        bze     skip_negate_for_divisor
        ; Negate quotient
        eor     #$FF
        inc
skip_negate_for_divisor:

        ; Combine X and A to create the return value
        xba
        txa

        leave
        rts
.endproc
