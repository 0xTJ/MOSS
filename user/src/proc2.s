.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

.export proc2
.proc proc2
        pea     2
        pea     $2000
        pea     $863B
        jsr     itoa
        pha
        jsr     puts

loop:
        safe_brk
        bra     loop
.endproc
