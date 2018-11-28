.p816

.macpack generic

.autoimport

.include "functions.inc"
.include "proc.inc"

PROC_NUM = 8

.code

.constructor init_processes
.proc init_processes
        rep     #$30
        pea     .sizeof(Process)
        jsr     malloc

        sta     proc_table + 0
        sta     current_process_p

        tax
        sta     Process::next,x
        lda     #0
        sta     Process::pid,x
        lda     #1
        sta     Process::running,x

        rts
.endproc

.proc scheduler
        ldx     current_process_p

loop_scheduling:
        lda     Process::next,x
        tax

        lda     Process::running,x
        bze     loop_scheduling

commit_scheduling:
        stx     current_process_p

        rts
.endproc

.interruptor sys_tick
.proc sys_tick
        enter_isr

        jsr     scheduler

        exit_isr
.endproc

.proc create_proc
        rep     #$30
        ldx     #0

next_proc:
        lda     proc_table,x
        bze     found_empty_proc
        inx
        inx
        cpx     PROC_NUM * 2
        blt     next_proc

failed:
        lda     #0
        rts

found_empty_proc:
        pea     .sizeof(Process)
        jsr     malloc

        ; If malloc fails, exit in a failure state
        cmp     #0
        beq     failed

        ; Store new process as next of current, and put existing next in Y
        rep     #$30
        ldx     current_process_p
        ldy     Process::next,x
        sta     Process::next,x
        
        ; Put address of new process struct into X
        tax

        ; Get pid from address in table, and store
        pea     proc_table
        sub     1,s
        lsr
        sta     Process::pid,x
        pla     ; Pop from stack, and discard

        ; Mark as not yet running
        lda     #0
        sta     Process::running,x

        ; Store existing next in new process
        sty     Process::next,x
        
        ; Return with new PID in A
        lda     Process::pid,x
        rts
.endproc

.proc find_previous_proc
        setup_frame

        rep     #$30
        ldx     z:1

loop:
        ; Get next of this one
        lda     Process::next,x
        
        ; Compare to the one to be found
        cmp     z:1
        
        ; If not the same, move next to X and repeat
        beq     found_prev
        tax
        jmp     loop
        
found_prev:
        
        restore_frame
        rts
.endproc

.proc destroy_proc
        setup_frame
        
        ; Load PID to destroy
        rep     #$30
        lda     z:1
        
        ; Get address of process struct into X
        asl
        tax
        lda     proc_table,x
        tax

        ; Mark as not running
        lda     #0
        sta     Process::running,x
        
        ; Get the next of the process to be destroyed and push to stack
        lda     Process::next,x
        pha
        
        ; Push address of process struct to be destroyed
        phx
        
        ; Find previous of the one to be destroyed and load to X
        jsr     find_previous_proc
        tax
        
        ; Load the next of the process to be destroyed to A
        rep     #$30
        lda     3,s
        
        ; Store the next of the process to be destroyed to the next of the previous
        sta     Process::next,x
        
        ; Load address of process struct to be destroyed to X
        plx
        
        ; Pop the next of the process to be destroyed from stack
        ply
        
        ; The process to be removed has now been removed from the execution chain
        
        ; TODO: Release resources
        
        ; Store struct address for use by free
        phx
        
        ; Remove process from process table
        lda     z:1
        asl
        tax
        lda     #0
        sta     proc_table,x
        
        ; Free struct
        jsr     free
        
        restore_frame
        rts
.endproc

.bss

.export current_process_p
current_process_p:
        .addr   0

proc_table:
        .res    2 * PROC_NUM
