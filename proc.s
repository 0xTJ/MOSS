.p816

.macpack generic

.autoimport

.include "functions.inc"
.include "proc.inc"

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

.bss

.export current_process_p
current_process_p:
        .addr   0

proc_table:
        .res    2 * 8
