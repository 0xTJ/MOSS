.p816
.smart

.macpack generic

.include "functions.inc"
.include "sched.inc"
.include "stdio.inc"

.rodata

test_str:
        .asciiz "test string"

.code

.export proc2
.proc proc2
        pea     test_str

loop:
        jsr     puts
        bra     loop
.endproc
