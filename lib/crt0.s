.p816
.smart

.include "functions.inc"
.include "stdlib.inc"

.import main

.segment "STARTUP"

.proc _start
        enter

        ; Setup stack frame
        lda     z:2 ; argv
        pha
        lda     z:0 ; argc
        pha

        ; Call main
        jsr     main
        rep     #$30

        ; Call exit
        pha
        jsr     exit

loop_forever:
        bra     loop_forever
.endproc
