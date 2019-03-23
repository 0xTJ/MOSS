.p816
.smart

.macpack generic

.include "sched.inc"
.include "functions.inc"
.include "proc.inc"
.include "fcntl.inc"

; int clone(int (*fn)(void *), void *child_stack, int flags, void *arg, ... /* pid_t *ptid, void *newtls, pid_t *ctid */)
; .export clone
; .proc clone
        ; enter
        ; rep     #$30

        ; inc     disable_scheduler
        ; jsr     clone_current_proc  ; TODO: Check for error state
        ; rep     #$30

        ; Push new process struct
        ; pha

        ; ldx     z:arg 0 ; fn
        ; phx
        ; ldx     z:arg 2 ; child_stack
        ; phx
        ; pha
        ; jsr     setup_proc
        ; rep     #$30
        ; ply
        ; ply
        ; ply

        ; Pull new process struct
        ; plx

        ; Set new process as ready to run
        ; lda     #PROCESS_READY
        ; sta     a:Process::state,x
        ; dec     disable_scheduler

        ; leave
        ; rts
; .endproc
