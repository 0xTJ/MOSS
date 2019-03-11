.p816
.smart

.macpack generic

.include "stdlib.inc"
.include "functions.inc"
.include "builtin.inc"

.code

; int abs(int n)
.proc abs
        enter_nostackvars
        rep     #$30

        lda     z:3 ; n
        bpl     is_positive ; Skip if already positive

        eor     #$FFFF
        inc

is_positive:

        leave_nostackvars
        rts
.endproc

; div_t div(int dividend, int divisor)
div             := __divide_s16_s16

; long int labs(long int n)
.proc labs
        enter_nostackvars
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
        leave_nostackvars
        rts
.endproc

.rodata

base36chars:
        .byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'

.code

; char *itoa (int value, char *str, int base)
.proc itoa
        enter_nostackvars
        rep     #$30
        
        ; Check that base is acceptable
        lda     z:7 ; base
        cmp     #2
        blt     failed
        cmp     #36
        bgt     failed

        ; Push str
        lda     z:5 ; str
        pha

        lda     z:7 ; base
        cmp     #10
        bne     skip_negate
        
        lda     z:3 ; value
        bpl     skip_negate

        ; Negate value
        eor     #$FFFF
        inc
        
        ; Store negated value into value in parameters
        sta     z:3 ; value
        
        ; Put '-' at beginning of str
        ldx     z:5 ; str
        sep     #$20
        lda     #'-'
        sta     a:0,x
        rep     #$20
        inx
        stx     z:5 ; str

skip_negate:

        ; Push $00
        sep     #$20
        lda     #0
        pha
        rep     #$20
        
check_zero_value:
        lda     z:3 ; value
        bnz     loop_finding_chars
        sep     #$20
        lda     #'0'
        pha
        rep     #$20
        phy
        bra     done_finding_chars

loop_finding_chars:
        lda     z:7 ; base
        pha
        lda     z:3 ; value
        bze     done_finding_chars
        pha
        jsr     __divide_u16_u16
        rep     #$30
        ply
        ply
        ; X: value / base
        ; A: least significant digit of value that was removed
        stx     z:3 ; Replace value with value / base
        tax

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

done:
        leave_nostackvars
        rts
        
failed:
        lda     #NULL
        bra     done
.endproc
