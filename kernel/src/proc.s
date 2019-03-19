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
.include "o65.inc"

EXECVE_SIZE = 3000

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

        ; Store struct as first process and as current process
        sta     proc_table + 0
        sta     current_process_p

        ; Transfer struct to X
        tax

        ; Set process as own next in execution chain
        sta     a:Process::next,x

        ; Set as PID 0 and own parent
        stz     a:Process::pid,x
        stz     a:Process::ppid,x

        ; Set as running
        lda     #PROCESS_READY
        sta     a:Process::state,x

        ; Clear file descriptors
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

        ; Clear segment bases, they aren't used and shouldn't be deleted
        stz     a:Process::text_base,x
        stz     a:Process::data_base,x
        stz     a:Process::bss_base,x
        stz     a:Process::zero_base,x
        stz     a:Process::stack_base,x

        ; Clear replacement stack values
        stz     a:Process::new_stack_p,x
        stz     a:Process::new_stack_base,x

        stz     disable_scheduler

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
        enter

        ; Disable interrupts to safely modify current process
        php
        sei

        ; Get new process handle
        jsr     create_proc

        ; Check for failure
        cmp     #0
        beq     failed

        ; Copy processor struct pointer to X
        tax

        ; Save PID and next for later
        ldy     a:Process::pid,x
        phy
        ldy     a:Process::next,x
        phy

        ; Save process struct pointer for later
        phx

        ; Load current process struct
        ldx     current_process_p

        ; Copy process info
        pea     .sizeof(Process)
        phx     ; Current process struct pointer
        pha     ; New process struct pointer
        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        ; Restore new process struct pointer
        plx

        ; Restore PID and next
        pla
        sta     a:Process::next,x
        lda     a:Process::pid,x
        sta     a:Process::ppid,x
        pla
        sta     a:Process::pid,x

        ; Reset SP to arbitrary value
        lda     #$DEAD
        sta     a:Process::stack_p,x

        ; Set to not running
        lda     #PROCESS_CREATED
        sta     a:Process::state,x

        txa

done:
        ; Enable interrupts if they were disabled
        plp

        leave
        rts

failed:
        lda     #0
        bra     done
.endproc

; void setup_proc(struct Process *proc, void *initial_sp, void *initial_pc)
; Assumes Program Bank is $00
.proc setup_proc
        enter
        rep     #$30

        ; Lock scheduler mutex
        inc     disable_scheduler

        ; Get address to store initial stack in A
        lda     z:arg 2 ; initial_sp

        ; Make space for main arguments
        sub     #4

        ; Make space for ISR frame
        sub     #.sizeof(ISRFrame)

        ; Increment stack pointer in A to get base of stack, and put into X
        inc
        tax

        ; Reset values
        sep     #$20
        stz     a:ISRFrame::prg_bnk,x
        stz     a:ISRFrame::p_reg,x
        stz     a:ISRFrame::dat_bnk,x
        rep     #$20
        stz     a:ISRFrame::dir_pag,x

        ; Store initial PC on process's stack
        lda     z:arg 4 ; initial_pc
        sta     a:ISRFrame::prg_cnt,x   ; Store PC on process's stack

        ; Put process's SP in A and struct pointer in X
        txa
        ldx     z:arg 0 ; proc

        ; Decrement SP because it was one above
        dec

        ; Store process's SP in struct
        sta     a:Process::stack_p,x

        ; Unlock scheduler mutex
        dec     disable_scheduler

        leave
        rts
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

        ; Clear replacement stack values
        stz     a:Process::new_stack_p,x
        stz     a:Process::new_stack_base,x

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
        lda     proc_table,x
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

        ; TODO: Release resources

        dec     disable_scheduler

        leave
        rts
.endproc

; void destroy_proc(int pid)
.proc destroy_proc
        enter   2

        ; 0: stuct proc *proc_p
        ; 2: stuct proc *next_p
        ; 4: stuct proc *prev_p

        inc     disable_scheduler

        ; Load PID to destroy to A
        lda     z:arg 0 ; pid

        ; Get address of process struct into X and proc_p
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
        sta     z:var 4 ; prev_p

        ; Store the next of the process to be destroyed to the next of the previous
        tax             ; prev_p
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

; char *malloc_load_exec(const char *filename)
.proc malloc_load_exec
        enter 4

        ; 0: buffer
        ; 2: exec_fd

        ; Allocate buffer for reading file
        pea     EXECVE_SIZE
        jsr     malloc
        rep     #$30
        ply

        ; Check success
        cmp     #0
        blt     failed_malloc

        ; Store buffer
        sta     z:var 0 ; buffer

        ; Call open on file descriptor
        pea     O_EXEC
        lda     z:arg 0
        pha
        jsr     open
        rep     #$30
        ply
        ply

        ; Check success
        cmp     #$FFFF
        blt     failed_open

        ; Store fd
        sta     z:var 2 ; exec_fd

        ; Read from file into buffer
        pea     EXECVE_SIZE
        pha
        jsr     read
        rep     #$30
        ply
        ply
        ply

        ; Check that at least a header was read
        cmp     #.sizeof(O65Header)
        blt     failed_read

        ; Close fd
        lda     z:var 2 ; file_fd
        pha
        jsr     close
        rep     #$30
        ply

        ; Load buffer for return
        lda     z:var 0 ; buffer

done:
        leave
        rts

failed_read:
        lda     z:var 2 ; file_fd
        pha
        jsr     close
        rep     #$30
        ply
failed_open:
        lda     z:var 0 ; buffer
        pha
        jsr     free
        rep     #$30
        ply
failed_malloc:
        bra     done
.endproc

; int execve(const char *filename, char *const argv[], char *const envp[]);
.proc execve
        enter   14

        ; 0:    void *text_base
        ; 2:    void *data_base
        ; 4:    void *bss_base
        ; 6:    void *zero_base
        ; 8:    void *stack_init
        ; 10:   void *exec_buff
        ; 12:   void *stack_base

        inc     disable_scheduler

        ; Read filename into malloc buffer
        lda     z:arg 0 ; filename
        pha
        jsr     malloc_load_exec
        rep     #$30
        ply

        ; Fail if this failed
        cmp     #0
        jeq     failed

        ; Store executable buffer to variable
        sta     z:var 10    ; exec_buff

         ; Allocate text space and store pointer to stack
        ldx     z:var 10    ; exec_buff
        lda     a:O65Header::tlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 0 ; text_base

        ; Allocate data space and store pointer to stack
        ldx     z:var 10    ; exec_buff
        lda     a:O65Header::dlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 2 ; data_base

        ; Allocate bss space and store pointer to stack
        ldx     z:var 10    ; exec_buff
        lda     a:O65Header::blen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 4 ; bss_base

        ; Allocate zero space and store pointer to stack
        ldx     z:var 10    ; exec_buff
        lda     a:O65Header::zlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 6 ; zero_base

        ; Allocate stack space and store pointer to stack
        ldx     z:var 10    ; exec_buff
        lda     a:O65Header::stack,x
        bnz     not_zero_stack
        lda     #$200
not_zero_stack:
        add     #$80
        pha
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 12 ; stack_base
        add     1,s
        ply
        sta     z:var 8 ; stack_init

        ; Call o65 loader
        lda     z:var 6 ; zero_base
        pha
        lda     z:var 4 ; bss_base
        pha
        lda     z:var 2 ; data_base
        pha
        lda     z:var 0 ; text_base
        pha
        lda     z:var 10    ; exec_buff
        pha
        jsr     o65_load
        rep     #$30
        ply
        ply
        ply
        ply
        ply

        ; Free temporary buffer
        lda     z:var 10    ; exec_buff
        pha
        jsr     free
        rep     #$30
        ply

        ; Free old text, data, bss, and zero segments
        ldx     current_process_p
        lda     a:Process::text_base,x
        stz     a:Process::text_base,x
        pha
        jsr     free
        rep     #$30
        ply
        ldx     current_process_p
        lda     a:Process::data_base,x
        stz     a:Process::data_base,x
        pha
        jsr     free
        rep     #$30
        ply
        ldx     current_process_p
        lda     a:Process::bss_base,x
        stz     a:Process::bss_base,x
        pha
        jsr     free
        rep     #$30
        ply
        ldx     current_process_p
        lda     a:Process::zero_base,x
        stz     a:Process::zero_base,x
        pha
        jsr     free
        rep     #$30
        ply

        ; Setup new segments in struct
        ldx     current_process_p
        lda     z:var 0 ; text_base
        sta     a:Process::text_base,x
        lda     z:var 2 ; data_base
        sta     a:Process::data_base,x
        lda     z:var 4 ; bss_base
        sta     a:Process::bss_base,x
        lda     z:var 6 ; zero_base
        sta     a:Process::zero_base,x
        lda     z:var 8 ; stack_init
        sta     a:Process::new_stack_p,x
        lda     z:var 12 ; stack_base
        sta     a:Process::new_stack_base,x

        dec     disable_scheduler

        leave
        rts

failed:
        sei
        bra     failed
.endproc

; void _exit(int status)
.proc _exit
        enter

        ; Call terminate on process
        lda     a:current_process_p
        pha
        jsr     term_proc
        rep     #$30
        ply

; Loop, waiting for control to be taken away
loop:
        bra     loop
.endproc
