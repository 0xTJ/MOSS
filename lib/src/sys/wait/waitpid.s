.p816
.smart

.macpack generic

.include "functions.inc"
.include "sys/wait.inc"

.code

; pid_t waitpid(pid_t pid, int *wstatus, int options)
.proc waitpid
        enter

        lda     z:arg 4 ; options
        pha
        lda     z:arg 2 ; wstatus
        pha
        lda     z:arg 0 ; pid
        pha

        cop     $0E

        leave
        rts
.endproc
