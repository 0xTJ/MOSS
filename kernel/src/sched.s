.p816
.smart

.macpack generic

.include "sched.inc"
.include "functions.inc"
.include "proc.inc"
.include "fcntl.inc"

; int clone(int (*fn)(void *), void *child_stack, int flags, void *arg, ... /* pid_t *ptid, void *newtls, pid_t *ctid */)
.export clone
.proc clone
        setup_frame
        rep     #$30

        inc     disable_scheduler
        jsr     clone_current_proc  ; TODO: Check for error state
        rep     #$30

        pha

        ldx     z:3 ; fn
        phx
        ldx     z:5 ; child_stack
        phx
        pha
        jsr     setup_proc
        ply
        ply
        ply

        plx

        lda     #PROCESS_READY
        sta     a:Process::state,x
        dec     disable_scheduler

        restore_frame
        rts
.endproc
