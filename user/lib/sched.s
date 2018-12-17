.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "fcntl.inc"

; int clone(int (*fn)(void *), void *child_stack, int flags, void *arg, ... /* pid_t *ptid, void *newtls, pid_t *ctid */)
.export clone
.proc clone
        setup_frame
        rep     #$30

        lda     z:15    ; ctid
        pha
        lda     z:13    ; newtls
        pha
        lda     z:11    ; ptid
        pha
        lda     z:9     ; arg
        pha
        lda     z:7     ; flags
        pha
        lda     z:5     ; child_stack
        pha
        lda     z:3     ; fn
        pha
        
        cop     $04

        restore_frame
        rts
.endproc
