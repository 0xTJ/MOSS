.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

.export proc2
.proc proc2
loop:
        safe_brk
        bra     loop
.endproc
