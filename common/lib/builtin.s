.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

.code

; div_t __divide_s16_s16(int dividend, int divisor)
.export __divide_s16_s16
.proc __divide_s16_s16
        setup_frame
        rep     #$30

        lda     z:5 ; divisor
        bpl     divisor_positive
divisor_negative:
        pea     1
        eor     #$FFFF
        inc
        sta     z:5
        bra     done_divisor
divisor_positive:
        pea     0
done_divisor:

        lda     z:3 ; dividend
        bpl     dividend_positive
dividend_negative:
        pea     1
        eor     #$FFFF
        inc
        sta     z:3
        bra     done_dividend
dividend_positive:
        pea     0
done_dividend:

        lda     z:5 ; divisor
        lda     z:3 ; dividend
        jsr     __divide_u16_u16
        rep     #$30
        ply
        ply

        ; Fix values for negative dividend
        ply         ; 1 if dividend was negative
        bze     skip_negate_for_dividend
        ; Negate quotient
        eor     #$FFFF
        inc

        cpx     #0
        beq     skip_fix_remainder_for_neg_dividend

        dec     ; Subtract 1 from quotient

        pha
        phx
        lda     z:3 ; dividend
        sub     1,s ; subtract remainder from dividend
        tax         ; Put fixed remainder back into X
        pla
        pla         ; Restore quotient to A

skip_fix_remainder_for_neg_dividend:
skip_negate_for_dividend:

        ; Fix values for negative divisor
        ply         ; 1 if divisor was negative
        bze     skip_negate_for_divisor
        ; Negate quotient
        eor     #$FFFF
        inc
skip_negate_for_divisor:

        restore_frame
        ply         ; Cleanup stack before return
        rts
.endproc

; udiv_t __divide_u16_u16(unsigned int dividend, unsigned int divisor)
.export __divide_u16_u16
.proc __divide_u16_u16
        ; Reserve stack frame space for quotient
        rep     #$30
        lda     #0
        pha

        setup_frame
        ; Frame: int quotient, void *ret_addr, int dividend, int divisor

        lda     z:7 ; divisor
        ldx     z:5 ; dividend
        ldy     #1
        clc

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
        rol     z:1 ; Shifts in 1 to quotient if division was successful, otherwise 0
        pla         ; Pull divisor
        lsr         ; Shift divisor to the right
        dey         ; Decrement shift count
        bnz     division_loop   ; Loop if Y is not 0

        restore_frame
        ; Put quotient into A
        pla
        rts
.endproc
