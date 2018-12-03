.p816
.smart

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
        rep     #$30
        ply

        sta     proc_table + 0
        sta     current_process_p

        tax
        sta     a:Process::next,x
        lda     #0
        sta     a:Process::pid,x
        lda     #1
        sta     a:Process::running,x

        rts
.endproc

.proc scheduler
        rep     #$30

        ldx     current_process_p

loop_scheduling:
        lda     a:Process::next,x
        tax

        lda     a:Process::running,x
        bze     loop_scheduling

commit_scheduling:
        stx     current_process_p

        rts
.endproc

.interruptor sys_tick
.proc sys_tick
        enter_isr
        
        ; Clear interrupt
        sep     #$20
        lda     #1 << 2
        sta     TIFR
        
        ; Enable interrupts
        cli
        
        ; Increment activity counter
        lda     PD7
        inc
        sta     PD7
        
        jsr     scheduler

        exit_isr
        rti
.endproc

; int create_proc(void)
.proc create_proc
        sep     #$30
        lda     enable_scheduler
        pha
        lda     #0
        sta     enable_scheduler

        ldx     #0

next_proc:
        lda     a:proc_table,x
        bze     found_empty_proc
        inx
        inx
        cpx     PROC_NUM * 2
        blt     next_proc

failed:
        sep     #$20
        pla
        sta     enable_scheduler
        rep     #$30
        lda     #0
        rts

found_empty_proc:
        pea     .sizeof(Process)
        jsr     malloc
        rep     #$30
        ply

        ; If malloc fails, exit in a failure state
        cmp     #0
        beq     failed

        ; Put existing next in Y
        rep     #$30
        ldx     current_process_p
        ldy     a:Process::next,x

        ; Put address of new process struct into X
        tax

        ; Get pid from address in table, and store
        sub     #proc_table
        lsr
        sta     a:Process::pid,x
        pla     ; Pop from stack, and discard

        ; Mark as not yet running
        lda     #0
        sta     a:Process::running,x

        ; Store existing next in new process
        tya
        sta     a:Process::next,x

        ; Store new process as next of existing
        txa
        ldx     current_process_p
        sta     a:Process::next,x

        ; Return with new PID in A
        tax
        sep     #$20
        pla
        sta     enable_scheduler
        rep     #$30
        lda     a:Process::pid,x
        rts
.endproc

.proc find_previous_proc
        setup_frame

        sep     #$20
        lda     enable_scheduler
        pha
        lda     #0
        sta     enable_scheduler

        rep     #$30
        ldx     z:3

loop:
        ; Get next of this one
        lda     a:Process::next,x

        ; Compare to the one to be found
        cmp     z:3

        ; If not the same, move next to X and repeat
        beq     found_prev
        tax
        jmp     loop

found_prev:

        restore_frame
        rts
.endproc

; void destroy_proc(int pid)
.proc destroy_proc
        setup_frame
        
        sep     #$20
        pla
        sta     enable_scheduler
        rep     #$30

        ; Load PID to destroy
        rep     #$30
        lda     z:3

        ; Get address of process struct into X
        asl
        tax
        lda     proc_table,x
        tax

        ; Mark as not running
        lda     #0
        sta     a:Process::running,x

        ; Get the next of the process to be destroyed and push to stack
        lda     a:Process::next,x
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
        sta     a:Process::next,x

        ; Load address of process struct to be destroyed to X
        plx

        ; Pop the next of the process to be destroyed from stack
        ply

        ; The process to be removed has now been removed from the execution chain

        ; TODO: Release resources

        ; Store struct address for use by free
        phx

        ; Remove process from process table
        lda     z:3
        asl
        tax
        lda     #0
        sta     a:proc_table,x

        ; Free struct of process to be destroyed
        jsr     free
        rep     #$30
        pla
        
        sep     #$20
        pla
        sta     enable_scheduler
        rep     #$30

        restore_frame
        rts
.endproc

.bss

.export current_process_p
current_process_p:
        .addr   0

.export proc_table
proc_table:
        .res    2 * PROC_NUM

enable_scheduler:
        .byte   0
