.p816
.smart

.macpack generic

.include "functions.inc"
.include "builtin.inc"

.code

; udiv_t __divide_u16_u16(unsigned int dividend, unsigned int divisor)
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
