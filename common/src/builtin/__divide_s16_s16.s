.p816
.smart

.macpack generic

.include "functions.inc"
.include "builtin.inc"

.code

; div_t __divide_s16_s16(int dividend, int divisor)
.proc __divide_s16_s16
        enter
        rep     #$30

        lda     z:arg 2 ; divisor
        bpl     divisor_positive
divisor_negative:
        ; Push negative divisor flag
        ldy     #1
        phy
        ; Negate and replace divisor in frame
        eor     #$FFFF
        inc
        sta     z:arg 2 ; divisor
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
        eor     #$FFFF
        inc
        sta     z:arg 0 ; dividend
        ; Done making dividend absolute
        bra     done_dividend
dividend_positive:
        ; Push positive dividend flag
        ldy     #0
        phy
done_dividend:

        lda     z:arg 2 ; divisor
        pha
        lda     z:arg 0 ; dividend
        pha
        jsr     __divide_u16_u16
        rep     #$30
        ; Pull arguments to unsigned division call
        ply
        ply

        ; Swap A and X
        pha
        txa
        plx
        ; Quotient is in A, remainder in X

        ; Fix values for negative dividend
        ply         ; 1 if dividend was negative
        bze     done_fix_result_neg_dividend

        ; Negate quotient
        eor     #$FFFF
        inc

        cpx     #0  ; Compare remainder to 0
        beq     done_fix_result_neg_dividend

        ; Make remainder to be divisor - remainder
        pha         ; quotient
        txa
        ; Negate remainder
        eor     #$FFFF
        inc
        tax         ; Put fixed remainder back into X
        pla         ; Restore quotient to A

done_fix_result_neg_dividend:

        ; Fix values for negative divisor
        ply         ; 1 if divisor was negative
        bze     skip_negate_for_divisor
        ; Negate quotient
        eor     #$FFFF
        inc
skip_negate_for_divisor:

        ; Swap A and X
        pha
        txa
        plx
        ; Remainder is in A, quotient in X

        leave
        rts
.endproc
