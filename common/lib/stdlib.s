.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "stdlib.inc"

.code

; int abs(int n)
.proc abs
        setup_frame
        rep     #$30

        lda     z:3 ; n
        bpl     is_positive ; Skip if already positive

        eor     #$FFFF
        inc

is_positive:

        restore_frame
        rts
.endproc

; div_t div(int dividend, int divisor)
.proc div
        ; Reserve stack frame space for quotient
        rep     #$30
        lda     #0
        pha

        setup_frame
        ; Frame: int quotient, void *ret_addr, int dividend, int divisor

        lda     z:7 ; divisor
        bpl     divisor_positive
divisor_negative:
        pea     1
        eor     #$FFFF
        inc
        sta     z:7
        bra     done_divisor
divisor_positive:
        pea     0
done_divisor:

        lda     z:5 ; dividend
        bpl     dividend_positive
dividend_negative:
        pea     1
        eor     #$FFFF
        inc
        sta     z:5
        bra     done_dividend
dividend_positive:
        pea     0
done_dividend:

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

        ; Put quotient into A
        lda     z:1

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
        lda     z:5 ; dividend
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

; long int labs(long int n)
.proc labs
        setup_frame
        rep     #$30

        lda     z:3 ; lobyte(n)
        ldx     z:5 ; hibyte(n)
        bpl     done ; Skip if already positive

        ; Invert lobyte(n)
        eor     #$FFFF

        ; Invert hibyte(n)
        pha
        txa
        eor     #$FFFF
        tax
        pla

        ; Add 1 to inverted lobyte(n)
        add     #1

        ; If no carry, we're done
        bcc     done

        ; Otherwise, add 1 to inverted hibyte(n)
        inx

done:
        restore_frame
        rts
.endproc

.rodata

base36chars:
        .byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'

.code

; char *itoa (int value, char *str, int base)
.proc itoa
        setup_frame
        rep     #$30

        ; Push str
        lda     z:5 ; str
        pha

        lda     z:3 ; value
        bpl     value_positive

        ; Negate value
        eor     $FFFF
        inc
        
        ; Store negated value into value in parameters
        sta     z:3 ; value
        
        ; Put '-' at beginning of str
        ldx     z:5 ; str
        sep     #$20
        lda     '-'
        sta     0,x
        rep     #$20
        inx
        stx     z:5 ; str

value_positive:

        ; Push $00
        sep     #$20
        lda     #0
        pha
        rep     #$20

loop_finding_chars:
        lda     z:7 ; base
        pha
        lda     z:3 ; value
        bze     done_finding_chars
        pha
        jsr     div
        rep     #$30
        ply
        ply
        ; A: value / base
        ; X: least significant digit of value that was removed
        sta     z:3 ; Replace value with value / base

        sep     #$20
        lda     base36chars,x
        pha
        rep     #$20

        bra     loop_finding_chars

done_finding_chars:

        ply         ; Remove extra base that was pushed

        sep     #$20
        ldx     z:5 ; str

write_loop:
        pla         ; Pull a char
        sta     a:0,x
        inx
        cmp     #0
        bne     write_loop

        rep     #$20

        pla     ; Pull original str

        restore_frame
        rts
.endproc
