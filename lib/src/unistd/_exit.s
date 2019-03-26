.p816
.smart

.macpack generic

.include "functions.inc"
.include "unistd.inc"

.code

; void _exit(int status)
.proc _exit
        enter

        lda     z:arg 0 ; status
        pha
        
        cop     $0B

        leave
        rts
.endproc
