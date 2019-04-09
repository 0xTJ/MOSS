.p816
.smart

.macpack generic
.macpack longbranch

.include "sys/wait.inc"
.include "functions.inc"
.include "proc.inc"

.code

; pid_t waitpid(pid_t pid, int *wstatus, int options)
.proc waitpid
        enter   2
        
        ; 0: this_proc

        ldx     current_process_p
        lda     a:Process::pid,x
        sta     z:var 0 ; this_proc
        
any_loop:
        ; Get next process in list
        lda     a:Process::next,x
        tax

        ; Check if this is a child of ours
        lda     a:Process::ppid,x
        cmp     z:var 0 ; this_proc
        bne     any_loop
        
        ; Check to see if it is waiting to be reaped
        lda     a:Process::state,x
        cmp     #PROCESS_TERMINATED
        bne     any_loop
        
        ; Put return status into wstatus
        lda     a:Process::ret_val,x
        ; sta     (var 2) ; *wstatus

        lda     a:Process::pid,x
        pha
        pha
        jsr     destroy_proc
        rep     #$30
        ply
        pla
        
        leave
.endproc
