.p816
.smart

.macpack generic

.include "functions.inc"
.include "sys/wait.inc"

.code

; pid_t wait(int *status)
.proc wait
        enter

        pea     0
        lda     z:arg 0 ; status
        pha
        pea     $FFFF

        jsr     waitpid

        leave
        rts
.endproc
