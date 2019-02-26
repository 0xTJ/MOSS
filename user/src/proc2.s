.p816
.smart

.macpack generic

.include "functions.inc"
.include "stdio.inc"
.include "unistd.inc"

.bss

tmp_buff:
        .byte   0

.code

.export proc2
.proc proc2
loop:
        pea     1
        pea     tmp_buff
        pea     0
        jsr     read
        rep     #$30
        ply
        ply
        ply
        
        pea     1
        pea     tmp_buff
        pea     1
        jsr     write
        rep     #$30
        ply
        ply
        ply
        
        bra     loop
.endproc
