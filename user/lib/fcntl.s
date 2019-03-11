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

        lda     z:7 ; mode
        pha
        lda     z:5 ; flags
        pha
        lda     z:3 ; pathname
        pha

        cop     $03

        leave
        rts
.endproc
