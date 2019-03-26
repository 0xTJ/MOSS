.p816
.smart

.macpack generic

.include "stdlib.inc"
.include "functions.inc"
.include "builtin.inc"

.rodata

base36chars:
        .byte '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'

.code

; char *itoa (int value, char *str, int base)
.proc itoa
        enter
        rep     #$30
        
        ; Check that base is acceptable
        lda     z:arg 4 ; base
        cmp     #2
        blt     failed
        cmp     #36
        bgt     failed

        ; Push str
        lda     z:arg 2 ; str
        pha

        lda     z:arg 4 ; base
        cmp     #10
        bne     skip_negate
        
        lda     z:arg 0 ; value
        bpl     skip_negate

        ; Negate value
        eor     #$FFFF
        inc
        
        ; Store negated value into value in parameters
        sta     z:arg 0 ; value
        
        ; Put '-' at beginning of str
        ldx     z:arg 2 ; str
        sep     #$20
        lda     #'-'
        sta     a:0,x
        rep     #$20
        inx
        stx     z:arg 2 ; str

skip_negate:

        ; Push $00
        sep     #$20
        lda     #0
        pha
        rep     #$20
        
check_zero_value:
        lda     z:arg 0 ; value
        bnz     loop_finding_chars
        sep     #$20
        lda     #'0'
        pha
        rep     #$20
        phy
        bra     done_finding_chars

loop_finding_chars:
        lda     z:arg 4 ; base
        pha
        lda     z:arg 0 ; value
        bze     done_finding_chars
        pha
        jsr     __divide_u16_u16
        rep     #$30
        ply
        ply
        ; X: value / base
        ; A: least significant digit of value that was removed
        stx     z:arg 0 ; Replace value with value / base
        tax

        sep     #$20
        lda     base36chars,x
        pha
        rep     #$20

        bra     loop_finding_chars

done_finding_chars:

        ply         ; Remove extra base that was pushed

        sep     #$20
        ldx     z:arg 2 ; str

write_loop:
        pla         ; Pull a char
        sta     a:0,x
        inx
        cmp     #0
        bne     write_loop

        rep     #$20

        pla     ; Pull original str

done:
        leave
        rts
        
failed:
        lda     #NULL
        bra     done
.endproc
