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
        jsr     getchar
        rep     #$30
        
        pha
        jsr     putchar
        rep     #$30
        pla
        
        bra     loop
.endproc
