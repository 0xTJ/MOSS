.p816
.smart

.macpack generic

.include "functions.inc"
.include "unistd.inc"

.code

; int close(int fd)
.proc close
        enter

        lda     z:arg 0 ; fd
        pha
        
        cop     $0A

        leave
        rts
.endproc
