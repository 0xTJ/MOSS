.p816
.smart

.include "functions.inc"
.include "stdlib.inc"

.import __BSS_LOAD__
.import __BSS_SIZE__
.import main

.segment "STARTUP"

.proc _start
        enter

        ; Zero BSS
        ; pea     __BSS_SIZE__
        ; pea     0
        ; pea     __BSS_LOAD__

        ; Setup stack frame
        lda     z:2 ; argv
        pha
        lda     z:0 ; argc
        pha

        ; Call mainm
        jsr     main
        rep     #$30

        ; Call exit
        pha
        jsr     exit

loop_forever:
        bra     loop_forever
.endproc
