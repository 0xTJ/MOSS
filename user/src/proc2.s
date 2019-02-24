.p816
.smart

.macpack generic

.include "functions.inc"
.include "sched.inc"
.include "stdio.inc"

.code

.export proc2
.proc proc2
loop:
        bra     loop
.endproc
