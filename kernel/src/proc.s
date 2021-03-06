.p816
.smart

.macpack generic
.macpack longbranch

.include "proc.inc"
.include "functions.inc"
.include "stdlib.inc"
.include "fcntl.inc"
.include "string.inc"
.include "w65c265s.inc"
.include "isr.inc"
.include "stdio.inc"
.include "errcode.inc"
.include "unistd.inc"
.include "filesys.inc"
.include "o65.inc"

EXECVE_SIZE = 3000

.bss

tmp_str:
        .res    16

current_process_p:
        .addr   0

proc_table:
        .res    2 * PROC_NUM

; Used to keep scheduler from loading other processes.
; The current process's data will still be accesses and modified.
; Disable interrupts when modifying the current process.
disable_scheduler:
        .word   0

.rodata

root_path_str:
        .asciiz "/"

.code

.constructor init_processes
.proc init_processes
        enter
        rep     #$30

        pea     .sizeof(Process)
        jsr     malloc
        rep     #$30
        ply

        cmp     #$0000
        beq     failed

        ; Zero-fill struct
        pha
        pea     .sizeof(Process)
        pea     0
        pha
        jsr     memset
        rep     #$30
        ply
        ply
        ply
        pla

        ; Store struct as first process and as current process
        sta     proc_table + 0
        sta     current_process_p

        ; Transfer struct to X
        tax

        ; Set process as own next in execution chain
        sta     a:Process::next,x

        ; Set as PID 0 and PPID 0
        stz     a:Process::pid,x
        stz     a:Process::ppid,x

        ; Set as running
        lda     #PROCESS_READY
        sta     a:Process::state,x

done:
        leave
        rts

failed:
        pea     ERRCODE_INIT_PROC
        jsr     error_code
        rep     #$30
        pla
        bra     done
.endproc

; Get next process's saved stack pointer.
; Takes in and returns a SP in C
.proc scheduler
        rep     #$30

        ; If scheduler is disabled, return with current stack pointer.
        ldx     disable_scheduler
        bnz     done

        ; Load current processor struct to X.
        ldx     current_process_p

        ; Save SP for current process
        sta     a:Process::stack_p,x

loop_scheduling:
        lda     a:Process::next,x
        tax

        lda     a:Process::state,x
        cmp     #PROCESS_READY
        bne     loop_scheduling

commit_scheduling:
        stx     current_process_p

        lda     a:Process::pid,x

        ; Set LEDs to PID
        sep     #$20
        sta     PD7
        rep     #$20

        ; Load SP for new process
        lda     a:Process::stack_p,x

done:
        rts
.endproc

.interruptor sys_tick
.proc sys_tick
        enter_isr

        sep     #$20

        ; Clear interrupt
        lda     #1 << 2
        sta     TIFR

        rep     #$30

        tsc
        jsr     scheduler
        tcs

        leave_isr
        rti
.endproc

; struct Process *clone_current_proc()
; Properly setting SP must be managed by calling function.
; Set to not running.
.proc clone_current_proc
        enter   6

        ; 0: struct Process *new_proc

        ; Get new process handle
        jsr     create_proc

        ; Save new process
        sta     z:var 0 ; new_proc

        ; Check for failure
        cmp     #0
        beq     failed

        inc disable_scheduler

        ; Setup process info

        ; Load new process struct to X
        ldx     z:var 0 ; new_proc

        ; Reset SP to arbitrary value
        lda     #$DEAD
        sta     a:Process::stack_p,x

        ; Set to not running
        lda     #PROCESS_CREATED
        sta     a:Process::state,x

        ; Copy file table
        pea     .sizeof(Process::files_p)
        lda     current_process_p   ; Current process struct pointer
        add     #Process::files_p
        pha
        txa                         ; New process struct pointer
        add     #Process::files_p
        pha
        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        ; Load new process struct to X and current process struct to Y
        ldx     z:var 0 ; new_proc
        ldy     current_process_p

        ; Copy working directory
        lda     a:Process::working_dir,y
        sta     a:Process::working_dir,x

        dec disable_scheduler

        ; Load new process struct pointer to X
        lda     z:var 0 ; new_proc

done:
        leave
        rts

failed:
        lda     #0
        bra     done
.endproc

; struct Process *create_proc(void)
.proc create_proc
        enter
        rep     #$30

        inc     disable_scheduler

        ldx     #0

next_proc:
        lda     a:proc_table,x
        bze     found_empty_proc
        inx
        inx
        cpx     #PROC_NUM * 2
        blt     next_proc

failed:
        dec     disable_scheduler
        rep     #$30
        lda     #0
        leave
        rts

found_empty_proc:   ; X contains new PID * 2
        phx

        pea     .sizeof(Process)
        jsr     malloc
        rep     #$30
        plx

        ; Put PID * 2 in X
        plx

        ; If malloc fails, exit in a failure state
        cmp     #0
        beq     failed

        ; Store address in table
        sta     a:proc_table,x

        ; Push PID * 2
        phx

        ; Put existing next in Y
        rep     #$30
        ldx     current_process_p
        ldy     a:Process::next,x

        ; Put address of new process struct into X
        tax

        ; Get PID from stack and store in new process
        pla
        lsr
        sta     a:Process::pid,x

        ; Set parent PID
        phx
        ldx     current_process_p
        lda     a:Process::pid,x
        plx
        sta     a:Process::ppid,x

        ; Mark as not yet running
        lda     #PROCESS_CREATED
        sta     a:Process::state,x

        ; Clear return value
        stz     a:Process::ret_val,x

        ; Clear segment bases
        stz     a:Process::text_base,x
        stz     a:Process::data_base,x
        stz     a:Process::bss_base,x
        stz     a:Process::zero_base,x
        stz     a:Process::stack_base,x

        ; Clear working directory
        stz     a:Process::working_dir,x

        ; Store X and Y
        phx
        phy

        ; Zero file descriptor pointer table
        pea     .sizeof(Process::files_p)
        pea     0
        txa
        add     #Process::files_p
        pha
        jsr     memset    ; TODO: fix
        rep     #$30
        pla
        pla
        pla

        ; Restore X and Y
        ply
        plx

        ; Store existing next in new process
        tya
        sta     a:Process::next,x

        ; Store new process as next of existing
        txa
        ldx     current_process_p
        sta     a:Process::next,x

        dec     disable_scheduler

        ; Return with new PID in A
        leave
        rts
.endproc

; struct Process *find_previous_proc(struct Process *proc)
.proc find_previous_proc
        enter
        rep     #$30

        inc     disable_scheduler

        ldx     z:arg 0 ; proc

loop:
        ; Get next of this one
        lda     a:Process::next,x

        ; Compare to the one to be found
        cmp     z:arg 0 ; proc

        ; If not the same, move next to X and repeat
        beq     found_prev
        tax
        jmp     loop

found_prev:
        dec     disable_scheduler

        txa

        leave
        rts
.endproc

; void term_proc(int pid)
.proc term_proc
        enter
        rep     #$30

        inc     disable_scheduler

        ; Load PID to terminate
        lda     z:arg 0 ; pid

        ; Get address of process struct into X
        asl
        tax
        lda     a:proc_table,x
        tax

        ; Mark as not running
        lda     #PROCESS_TERMINATED
        sta     a:Process::state,x

        ; Set all children to have PPID 1
        ldx     #0
child_ppid_loop:
        ; Load PPID of a process in table to A, but skip if process doesn't exist
        ldy     a:proc_table,x
        bze     skip
        lda     a:Process::ppid,y
        ; Check if process has PPID as process being deleted
        cmp     z:arg 0 ; pid
        bne     skip
        ; Set PPID to 1
        lda     #1
        sta     a:Process::ppid,y
skip:
        ; Go to next process in table, and end if end of table
        inx
        inx
        cpx     #PROC_NUM * 2
        blt     child_ppid_loop

        ; Load process struct to X
        lda     z:arg 0 ; pid
        asl
        tax
        lda     a:proc_table,x
        tax

        ; Push all segments to delete
        lda     a:Process::text_base,x
        pha
        lda     a:Process::data_base,x
        pha
        lda     a:Process::bss_base,x
        pha
        lda     a:Process::zero_base,x
        pha
        lda     a:Process::stack_base,x
        pha

        ; Run free on all segments
        jsr     free
        rep     #$30
        ply
        jsr     free
        rep     #$30
        ply
        jsr     free
        rep     #$30
        ply
        jsr     free
        rep     #$30
        ply
        jsr     free
        rep     #$30
        ply

        ; TODO: Release other resources

        dec     disable_scheduler

        leave
        rts
.endproc

; void destroy_proc(int pid)
.proc destroy_proc
        enter   6

        ; 0: stuct proc *proc_p
        ; 2: stuct proc *next_p
        ; 4: stuct proc *prev_p

        inc     disable_scheduler

        ; Load PID to destroy to A
        lda     z:arg 0 ; pid

        ; Get address of process struct into proc_p
        asl
        tax
        lda     a:proc_table,x
        sta     z:var 0 ; proc_p

        ; Get the next of the process to be destroyed and store to next_p
        tax             ; proc_p
        lda     a:Process::next,x
        sta     z:var 2 ; next_p

        ; Find previous of the one to be destroyed and store to prev_p
        phx             ; proc_p
        jsr     find_previous_proc
        rep     #$30
        ply
        sta     z:var 4 ; prev_p

        ; Store the next of the process to be destroyed to the next of the previous
        ldx     z:var 4 ; prev_p
        ; tax             ; prev_p
        lda     z:var 2 ; next_p
        sta     a:Process::next,x

        ; The process to be removed has now been removed from the list

        ; Remove process from process table
        lda     z:arg 0 ; pid
        asl
        tax
        stz     a:proc_table,x

        ; Free struct of process to be destroyed
        lda     z:var 0 ; proc_p
        pha
        jsr     free
        rep     #$30
        ply

        dec     disable_scheduler

        leave
        rts
.endproc
