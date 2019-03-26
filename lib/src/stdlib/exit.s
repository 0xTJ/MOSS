.p816
.smart

.macpack generic

.include "functions.inc"
.include "stdlib.inc"

.code

; void exit(int status)
.proc exit
        enter

        lda     z:arg 0 ; status
        pha

        jsr     _Exit

        leave
        rts
.endproc
