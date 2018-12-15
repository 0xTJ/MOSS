.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"

.code

.ifndef KERNEL
; ssize_t read(int fildes, void *buf, size_t nbyte)
.export read
.proc read
        setup_frame
        rep     #$30

        lda     z:7 ; nbyte
        pha
        lda     z:5 ; buf
        pha
        lda     z:3 ; fildes
        pha
        
        cop     $04

        restore_frame
        rts
.endproc

; ssize_t write(int fildes, const void *buf, size_t nbyte)
.export write
.proc write
        setup_frame
        rep     #$30

        lda     z:7 ; nbyte
        pha
        lda     z:5 ; buf
        pha
        lda     z:3 ; fildes
        pha
        
        cop     $05

        restore_frame
        rts
.endproc
.endif
