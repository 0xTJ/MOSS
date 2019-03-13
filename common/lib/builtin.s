.p816
.smart

.macpack generic

.include "functions.inc"

.code

; cdiv_t __divide_s8_s8(char dividend, char divisor)
.export __divide_s8_s8
.proc __divide_s8_s8
        enter
        ; 8-bit A, X, Y
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

; ucdiv_t __divide_u8_u8(unsigned char dividend, unsigned char divisor)
.export __divide_u8_u8
.proc __divide_u8_u8
        enter 1

        ; 0: unsigned char quotient

        sep     #$30

        stz     z:var 0 ; quotient
        ldx     z:arg 0 ; dividend
        lda     z:arg 1 ; divisor
        ldy     #1

find_left_divisor_bit:
        asl         ; Shift divisor and put previous leftmost into carry
        bcs     found_left_divisor_bit  ; Branch when we find the leftmost bit
        iny         ; Increment shift count
        cpy     #9  ; Check if we have a exceeded max shifts
        bne     find_left_divisor_bit

found_left_divisor_bit:
        ror         ; Shift last bit shifted out back in

division_loop:
        pha         ; Push divisor
        txa         ; Dividend into A
        sub     1,s ; Subtract divisor from dividend
        bcc     after_dividend_commit   ; Skip transferring dividend back to X if subtraction failed
        tax
after_dividend_commit:
        rol     z:var 0 ; Shifts in 1 to quotient if division was successful, otherwise 0
        pla             ; Pull divisor
        lsr             ; Shift divisor to the right
        dey             ; Decrement shift count
        bnz     division_loop   ; Loop if Y is not 0

        lda     z:var 0 ; Load quotient into A
        xba
        txa     ; Put remainder into A

        leave
        rts
.endproc

; div_t __divide_s16_s16(int dividend, int divisor)
.export __divide_s16_s16
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

; udiv_t __divide_u16_u16(unsigned int dividend, unsigned int divisor)
.export __divide_u16_u16
.proc __divide_u16_u16
        enter   2

        ; 0: unsigned int quotient

        stz     z:var 0 ; quotient
        ldx     z:arg 0 ; dividend
        lda     z:arg 2 ; divisor
        ldy     #1

find_left_divisor_bit:
        asl         ; Shift divisor and put previous leftmost into carry
        bcs     found_left_divisor_bit  ; Branch when we find the leftmost bit
        iny         ; Increment shift count
        cpy     #17 ; Check if we have a exceeded max shifts
        bne    find_left_divisor_bit

found_left_divisor_bit:
        ror         ; Shift last bit shifted out back in

division_loop:
        pha         ; Push divisor
        txa         ; Dividend into A
        sub     1,s ; Subtract divisor from dividend
        bcc     after_dividend_commit   ; Skip transferring dividend back to X if subtraction failed
        tax
after_dividend_commit:
        rol     z:var 0 ; Shifts in 1 to quotient if division was successful, otherwise 0
        pla         ; Pull divisor
        lsr         ; Shift divisor to the right
        dey         ; Decrement shift count
        bnz     division_loop   ; Loop if Y is not 0

        ; Move remainder to A
        txa
        ; Load quotient into X
        ldx     z:var 0 ; quotient

        leave
        rts
.endproc
