.p816
.smart

.macpack generic

.include "functions.inc"
.include "unistd.inc"

.code

; ssize_t read(int fd, void *buf, size_t nbyte)
.proc read
        enter
        rep     #$30

        lda     z:arg 4 ; nbyte
        pha
        lda     z:arg 2 ; buf
        pha
        lda     z:arg 0 ; fd
        pha
        
        cop     $04

        leave
        rts
.endproc

; ssize_t write(int fd, const void *buf, size_t nbyte)
.proc write
        enter
        rep     #$30

        lda     z:arg 4 ; nbyte
        pha
        lda     z:arg 2 ; buf
        pha
        lda     z:arg 0 ; fd
        pha
        
        cop     $05

        leave
        rts
.endproc

; int close(int fd)
.proc close
        enter
        rep     #$30

        lda     z:arg 0 ; fd
        pha
        
        cop     $0A

        leave
        rts
.endproc
