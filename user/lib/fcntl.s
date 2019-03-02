.p816
.smart

.macpack generic

.include "functions.inc"
.include "fcntl.inc"

.code

; int open(const char *pathname, int flags, ... /* mode_t mode */)
.proc open
        setup_frame
        rep     #$30

        lda     z:7 ; mode
        pha
        lda     z:5 ; flags
        pha
        lda     z:3 ; pathname
        pha

        cop     $03

        restore_frame
        rts
.endproc
