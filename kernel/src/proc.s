.p816
.smart

.macpack generic

.include "proc.inc"
.include "functions.inc"
.include "stdlib.inc"
.include "string.inc"
.include "w65c265s.inc"
.include "isr.inc"
.include "stdio.inc"

PROC_NUM = 8

.bss

current_process_p:
        .addr   0

proc_table:
        .res    2 * PROC_NUM

; Used to keep scheduler from loading other processes.
; The current process's data will still be accesses and modified.
; Disable interrupts when modifying the current process.
disable_scheduler:
        .word   0

.code

.pushseg
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

.popseg

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

        ply
        ply

        restore_frame
        rts
.endproc

; void dump_process_table(void)
.proc dump_process_table
        rep     #$30

        inc     disable_scheduler

        ldx     #0

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
        plx
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

        dec disable_scheduler

        rts
.endproc

.constructor init_processes
.proc init_processes
        rep     #$30

        pea     .sizeof(Process)
        jsr     malloc
        rep     #$30
        ply

        ; TODO: check for success of malloc

        sta     proc_table + 0
        sta     current_process_p

        tax
        sta     a:Process::next,x
        lda     #0
        sta     a:Process::pid,x
        sta     a:Process::ppid,x
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

        lda     a:Process::pid,x

        ; Set LEDs to PID
        sta     PD7

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

        jsr     scheduler

        exit_isr
        rti
.endproc

; struct Process *clone_current_proc()
; Properly setting SP must be managed by calling function.
; Set to not running.
.proc clone_current_proc
        rep     #$30

        ; Disable interrupts to safely modify current process
        sei

        ; Lock scheduler mutex for clarity
        inc     disable_scheduler

        ; Get new process handle
        jsr     create_proc

        ; Check for failure
        cmp     #0
        beq     failed

        tax

        ; Save PID and next for later
        ldy     a:Process::pid,x
        phy
        ldy     a:Process::next,x
        phy

        ; Save process struct for later
        phx

        ; Load current process struct
        ldx     current_process_p

        ; Copy process info
        pea     .sizeof(Process)
        phx
        pha
        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        ; Restore new process struct
        plx

        ; Restore PID and next
        pla
        sta     a:Process::next,x
        lda     a:Process::pid,x
        sta     a:Process::ppid,x
        pla
        sta     a:Process::pid,x

        ; Reset SP
        stz     a:Process::reg_sp,x

        ; Set to not running
        stz     a:Process::running,x

        txa

done:
        ; Unlock scheduler mutex
        dec     disable_scheduler

        ; Enable interrupts
        cli

        rts

failed:
        lda     #0
        bra     done
.endproc

; void setup_proc(void *initial_sp, void *initial_pc)
.proc replace_current_proc
        setup_frame
        rep     #$30

        ; Disable interrupts to safely modify current process
        sei

        ; Lock scheduler mutex for clarity
        inc     disable_scheduler

        ; Load current process
        ldx     current_process_p

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
        ldx     z:3 ; initial_sp
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
        lda     z:5     ; initial_pc
        sta     a:2,x   ; Store PC on process's stack

        ; Put process's SP in A and struct pointer in X
        txa
        ldx     current_process_p

        ; Store process's SP in struct
        sta     a:Process::reg_sp,x

        ; Set not saving state
        lda     #1
        sta     a:Process::skp_sav,x

        ; Unlock scheduler mutex
        dec     disable_scheduler

        ; Enable interrupts, and wait for scheduler to take over
        cli
loop:
        bra     loop
.endproc

; void setup_proc(struct Process *proc, void *initial_sp, void *initial_pc)
; Assumes Program Bank is $00
.proc setup_proc
        setup_frame
        rep     #$30

        ; Lock scheduler mutex
        inc     disable_scheduler

        ldx     z:3

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

        ; Reset not saving state
        stz     a:Process::skp_sav,x

        ; Unlock scheduler mutex
        dec     disable_scheduler

        restore_frame
        rts
.endproc

; struct Process *create_proc(void)
.proc create_proc
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
        stz     a:Process::running,x

        ; Reset registers in struct
        stz     a:Process::reg_c,x
        stz     a:Process::reg_d,x
        stz     a:Process::reg_x,x
        stz     a:Process::reg_y,x
        sep     #$20
        stz     a:Process::reg_db,x
        stz     a:Process::bit_e,x
        rep     #$20

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
