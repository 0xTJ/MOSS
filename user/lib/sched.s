.p816
.smart

.macpack generic

.include "sched.inc"
.include "functions.inc"
.include "fcntl.inc"

; int clone(int (*fn)(void *), void *child_stack, int flags, void *arg, ... /* pid_t *ptid, void *newtls, pid_t *ctid */)
; .export clone
; .proc clone
        ; enter
        ; rep     #$30

        ; lda     z:arg 12    ; ctid
        ; pha
        ; lda     z:arg 10    ; newtls
        ; pha
        ; lda     z:arg 8     ; ptid
        ; pha
        ; lda     z:arg 6     ; arg
        ; pha
        ; lda     z:arg 4     ; flags
        ; pha
        ; lda     z:arg 2     ; child_stack
        ; pha
        ; lda     z:arg 0     ; fn
        ; pha
        
        ; cop     $06

        ; leave
        ; rts
; .endproc
