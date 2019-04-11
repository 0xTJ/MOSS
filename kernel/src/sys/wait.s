.p816
.smart

.macpack generic
.macpack longbranch

.include "sys/wait.inc"
.include "functions.inc"
.include "proc.inc"

.code

; pid_t waitpid(pid_t pid, int *status, int options)
.proc waitpid
        enter   2

        ; 0: this_proc

        ; Save address of current process to local variable
        ldx     current_process_p
        lda     a:Process::pid,x
        sta     z:var 0 ; this_proc

        lda     z:arg 0 ; pid
        bpl     specific_pid
        cmp     #$FFFF
        beq     any_loop

specific_pid:
        ; Load address of target process to A
        asl
        tax
        lda     proc_table,x
        
        ; If it is NULL, fail
        bze     failed
        
        ; Check if this is a child of ours
        tax
        lda     a:Process::ppid,x
        cmp     z:var 0 ; this_proc
        bne     failed
        
specific_loop:
        ; Check to see if it is waiting to be reaped
        lda     a:Process::state,x
        cmp     #PROCESS_TERMINATED
        bne     specific_loop

        bra     found_proc

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

        bra     found_proc

found_proc:
        ; Put return status into status
        ldy     z:var 2 ; status
        bze     null_status
        lda     a:Process::ret_val,x
        sta     a:0,y   ; *status
null_status:

        ; Destroy process
        lda     a:Process::pid,x
        pha
        pha
        jsr     destroy_proc
        rep     #$30
        ply
        pla

done:
        leave
        rts
        
failed:
        lda     #$FFFF
        bra     done
.endproc
