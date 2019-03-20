.p816
.smart

.macpack generic

.include "unistd.inc"
.include "functions.inc"
.include "string.inc"
.include "proc.inc"

; void _exit(int status)
; TODO: Put status somewhere
.proc _exit
        enter

        ; Store status into process ret_val
        ldx     current_process_p
        lda     z:arg 0 ; status
        sta     a:Process::ret_val,x

        ; Load parent struct pointer to X
        lda     a:Process::ppid,x
        asl
        tax
        lda     a:proc_table,x
        tax

        ; Skip to vfork section if the parent is waiting for vfork to finish
        lda     a:Process::state,x
        cmp     #PROCESS_WAIT_VFORK
        beq     is_vfork

        ; Call terminate on process
        lda     current_process_p
        tax
        lda     a:Process::pid,x
        pha
        jsr     term_proc
        rep     #$30
        ply

; Loop, waiting for control to be taken away
loop:
        bra     loop

is_vfork:

        ; Load child PID to Y
        ldx     current_process_p
        ldy     a:Process::pid,x

        ; Load parent process struct to X
        lda     a:Process::ppid,x
        asl
        tax
        lda     a:proc_table,x
        tax

        ; Lock scheduler mutex
        inc     disable_scheduler

        ; Set parent as running
        lda     #PROCESS_READY
        sta     a:Process::state,x

        ; Load stack
        lda     a:Process::stack_p,x
        tcs
        inc
        inc
        inc
        inc
        tcd
        
        stx     current_process_p
        
        ; Push the child PID
        phy
        
        ; Call term_proc on child PID
        phy
        jsr     term_proc
        rep     #$30
        ply

        ; Unlock scheduler mutex
        dec     disable_scheduler
        
        ; Pull child PID to A
        pla
        
        rts
.endproc

; pid_t vfork(void)
; Only to be called from syscall
.proc vfork
        jsr     clone_current_proc
        rep     #$30

        ; Lock scheduler mutex
        inc     disable_scheduler

        ; Load parent process struct to X
        ldx     current_process_p

        ; Store child process struct as current process
        sta     current_process_p

        ; Set parent as waiting for the child to do something
        lda     #PROCESS_WAIT_VFORK
        sta     a:Process::state,x

        ; Save current stack as parent's saved stack
        tsc
        sta     a:Process::stack_p,x

        ; Set child process as running
        ldx     current_process_p
        lda     #PROCESS_READY
        sta     a:Process::state,x

        ; Unlock scheduler mutex
        dec     disable_scheduler

        ; Replicate last 16 bytes of stack and reposition D in these
        ; When syscall returns, D will be the correct value but the stack will be offset down to ensure no clobbering

        ; Transfer original SP to A
        tsc

        ; Transfer original SP + 1 to X
        tax
        inx

        ; Subtract 16 from SP
        sub     #16
        tcs

        ; Transfer new SP + 1 to Y
        tay
        iny

        ; Call memcpy to create duplicate of current stack
        pea     16  ; Push number of bytes to copy
        phx         ; Push original SP + 1
        phy         ; Push new SP + 1
        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        tdc
        sub     #16
        tcd

        ; Child returns with 0
        lda     #0

        rts
.endproc

; int execve(const char *filename, char *const argv[], char *const envp[])
.proc execve
        enter



        leave
        rts
.endproc
