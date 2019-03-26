.p816
.smart

.macpack generic

.include "functions.inc"
.include "fcntl.inc"

.code

; int open(const char *pathname, int flags, ... /* mode_t mode */)
.proc open
        enter
        rep     #$30

        lda     z:arg 4 ; mode
        pha
        lda     z:arg 2 ; flags
        pha
        lda     z:arg 0 ; pathname
        pha

        cop     $03

        leave
        rts
.endproc
