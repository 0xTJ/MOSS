.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

.export proc2
.proc proc2
        pea     $FBE5
        pea     $7530
        jsr     __divide_s16_s16
        safe_brk
        
        pea     $041B
        pea     $8AD0
        jsr     __divide_s16_s16
        safe_brk
        
        pea     $7530
        pea     $FBE5
        jsr     __divide_s16_s16
        safe_brk
        
        pea     $8AD0
        pea     $041B
        jsr     __divide_s16_s16
        safe_brk
        
loop:
        safe_brk
        bra     loop
.endproc
