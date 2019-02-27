.p816
.smart

.macpack generic

.include "dump_process_table.inc"
.include "proc.inc"
.include "functions.inc"
.include "stdlib.inc"
.include "string.inc"
.include "w65c265s.inc"
.include "isr.inc"
.include "stdio.inc"

.bss

tmp_string:
        .res 16

.rodata

sep_str:
        .asciiz "-"
pid_str:
        .asciiz "PID:"
ppid_str:
        .asciiz "PPID:"
state_str:
        .asciiz "State:"
this_struct_p_str:
        .asciiz "This Struct Pointer:"
next_struct_p_str:
        .asciiz "Next Struct Pointer:"
stack_p_str:
        .asciiz "Stack Pointer:"
prg_cnt_str:
        .asciiz "Program Counter:"

.code

; void print_process(struct Process *proc)
.proc print_process
        setup_frame
        rep     #$30

        pea     10
        pea     tmp_string

        pea     pid_str
        jsr     puts
        rep     #$30
        ply
        ldx     z:3 ; proc
        lda     a:Process::pid,x
        pha
        jsr     itoa
        rep     #$30
        ply
        pha
        jsr     puts
        rep     #$30
        ply

        pea     ppid_str
        jsr     puts
        rep     #$30
        ply
        ldx     z:3 ; proc
        lda     a:Process::ppid,x
        pha
        jsr     itoa
        rep     #$30
        ply
        pha
        jsr     puts
        rep     #$30
        ply

        pea     state_str
        jsr     puts
        rep     #$30
        ply
        ldx     z:3 ; proc
        lda     a:Process::state,x
        pha
        jsr     itoa
        rep     #$30
        ply
        pha
        jsr     puts
        rep     #$30
        ply

        ply
        ply
        pea     16
        pea     tmp_string
        
        pea     stack_p_str
        jsr     puts
        rep     #$30
        ply
        ldx     z:3 ; proc
        lda     a:Process::stack_p,x
        pha
        jsr     itoa
        rep     #$30
        ply
        pha
        jsr     puts
        rep     #$30
        ply
        
        ; pea     this_struct_p_str
        ; jsr     puts
        ; rep     #$30
        ; ply
        ; lda     z:3 ; proc
        ; pha
        ; jsr     itoa
        ; rep     #$30
        ; ply
        ; pha
        ; jsr     puts
        ; rep     #$30
        ; ply
        
        ; pea     next_struct_p_str
        ; jsr     puts
        ; rep     #$30
        ; ply
        ; ldx     z:3 ; proc
        ; lda     a:Process::next,x
        ; pha
        ; jsr     itoa
        ; rep     #$30
        ; ply
        ; pha
        ; jsr     puts
        ; rep     #$30
        ; ply
        
        pea     prg_cnt_str
        jsr     puts
        rep     #$30
        ply
        ldx     z:3 ; proc
        lda     a:Process::stack_p,x
        tax
        dex     ; Get base of ISR frame
        lda     a:ISRFrame::prg_bnk,x
        pha
        jsr     itoa
        rep     #$30
        ply
        pha
        jsr     puts
        rep     #$30
        ply

        ply
        ply

        restore_frame
        rts
.endproc

; void dump_process_table(void)
.proc dump_process_table
        rep     #$30

        ldx     #0

        inc     disable_scheduler

loop:
        lda     a:proc_table,x
        bze     skip
        phx
        pha

        pea     sep_str
        jsr     puts
        rep     #$30
        ply

        jsr     print_process
        rep     #$30
        ply
        plx
skip:
        inx
        inx
        cpx     #PROC_NUM * 2
        blt     loop

        pea     sep_str
        jsr     puts
        rep     #$30
        ply

        dec     disable_scheduler

        rts
.endproc