.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "proc.inc"

PROC_NUM = 8

.bss

.export current_process_p
current_process_p:
        .addr   0

.export proc_table
proc_table:
        .res    2 * PROC_NUM

.export disable_scheduler
disable_scheduler:
        .word   0

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

        pea     .sizeof(Process::files_p)
        pea     0
        lda     current_process_p
        add     #Process::files_p
        pha
        jsr     memset
        rep     #$30
        ply
        ply
        ply
        
        stz     disable_scheduler

        rts
.endproc

.proc scheduler
        rep     #$30

        lda     disable_scheduler
        bnz     done

        ldx     current_process_p

loop_scheduling:
        lda     a:Process::next,x
        tax

        lda     a:Process::running,x
        bze     loop_scheduling

commit_scheduling:
        stx     current_process_p

        lda     z:Process::pid,x
done:
        rts
.endproc

.interruptor sys_tick
.proc sys_tick
        enter_isr

        ; Clear interrupt
        sep     #$20
        lda     #1 << 2
        sta     TIFR

        ; Enable interrupts globally
        cli

        ; Increment activity counter
        lda     PD7
        inc
        sta     PD7

        jsr     scheduler

        exit_isr
        rti
.endproc

; void setup_proc(struct Process *proc, void *initial_sp, void *initial_pc)
; Assumes Program Bank is $00
.export setup_proc
.proc setup_proc
        setup_frame

        rep     #$30
        ldx     z:3

        ; Store some registers in struct
        stz     a:Process::reg_c,x
        stz     a:Process::reg_d,x
        stz     a:Process::reg_x,x
        stz     a:Process::reg_y,x
        sep     #$20
        stz     a:Process::reg_db,x
        stz     a:Process::bit_e,x
        rep     #$20

        ; Get address to store initial PC
        ldx     z:5 ; initial_sp
        dex
        dex
        dex
        dex

        ; Store flags and program bank
        sep     #$20
        stz     a:1,x
        stz     a:4,x
        rep     #$20

        ; Store initial PC on process's stack
        lda     z:7 ; initial_pc
        sta     a:2,x   ; Store PC on process's stack

        ; Put process's SP in A and struct pointer in X
        txa
        ldx     z:3

        ; Store process's SP in struct
        sta     a:Process::reg_sp,x

        restore_frame
        rts
.endproc

; struct Process *create_proc(void)
.export create_proc
.proc create_proc
        rep     #$30
        inc     disable_scheduler

        ldx     #0

next_proc:
        lda     a:proc_table,x
        bze     found_empty_proc
        inx
        inx
        cpx     PROC_NUM * 2
        blt     next_proc

failed:
        dec     disable_scheduler
        rep     #$30
        lda     #0
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

        ; Mark as not yet running
        stz     a:Process::running,x

        ; Store existing next in new process
        tya
        sta     a:Process::next,x

        ; Store new process as next of existing
        txa
        ldx     current_process_p
        sta     a:Process::next,x

        dec     disable_scheduler
        
        ; Return with new PID in A
        rts
.endproc

.proc find_previous_proc
        setup_frame
        rep     #$30

        inc     disable_scheduler

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
        dec     disable_scheduler

        restore_frame
        rts
.endproc

; void destroy_proc(int pid)
.export destroy_proc
.proc destroy_proc
        setup_frame
        rep     #$30

        inc     disable_scheduler

        ; Load PID to destroy
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

        dec     disable_scheduler

        restore_frame
        rts
.endproc
