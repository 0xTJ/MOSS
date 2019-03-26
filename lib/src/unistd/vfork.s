.p816
.smart

.macpack generic

.include "functions.inc"
.include "unistd.inc"

.code

; pid_t vfork(void)
.proc vfork
        ; No enter, we want to directly pass back changes to SP

        cop     $0D

        rts
.endproc
