.p816
.smart

.macpack generic
.macpack longbranch

.include "unistd.inc"
.include "functions.inc"
.include "string.inc"
.include "o65.inc"
.include "stdlib.inc"
.include "fcntl.inc"
.include "filesys.inc"
.include "stdio.inc"
.include "proc.inc"

.data

tmp_str:
        .res    10

.code

; void _exit(int status)
.proc _exit
        enter

        ; Store status into process ret_val
        ldx     current_process_p
        lda     z:arg 0 ; status
        sta     a:Process::ret_val,x

        ; Lock scheduler mutex
        inc     disable_scheduler

        ; Call terminate on process
        ldx     current_process_p
        lda     a:Process::pid,x
        pha
        jsr     term_proc
        rep     #$30
        ply

        ; Load parent struct pointer to X
        ldx     current_process_p
        lda     a:Process::ppid,x
        asl
        tax
        lda     a:proc_table,x
        tax

        ; Skip the vfork section if the parent is not waiting for vfork to finish
        lda     a:Process::state,x
        cmp     #PROCESS_WAIT_VFORK
        bne     no_vfork

        ; Set parent as running
        lda     #PROCESS_READY
        sta     a:Process::state,x

no_vfork:
        ; Unlock scheduler mutex
        dec     disable_scheduler

; Loop, waiting for control to be taken away
loop:
        bra     loop
.endproc

; pid_t vfork_no_direct_call(void)
; Only to be called from syscall
.global vfork_no_direct_call
.proc vfork_no_direct_call
        jsr     clone_current_proc
        rep     #$30

        cmp     #0
        beq     failed

        ; Push ISR frame for parent
        phk
        pea     parent_vfork
        php
        pea     $FFFF
        phx
        phy
        phd
        phb

        ; Lock scheduler mutex
        inc     disable_scheduler

        ; Load parent process struct to X
        ldx     current_process_p

        ; Store child process struct as current process
        sta     current_process_p

        ; Set parent as waiting for the child to do something
        lda     #PROCESS_WAIT_VFORK
        sta     a:Process::state,x

        ; Save current stack as parent's saved stack
        tsc
        sta     a:Process::stack_p,x

        ; Set child process as running
        ldx     current_process_p
        lda     #PROCESS_READY
        sta     a:Process::state,x

        ; Store child PID as parent return
        lda     a:Process::pid,x
        sta     8,s

        ; Zero segment bases memory ownership
        stz     a:Process::text_base,x
        stz     a:Process::data_base,x
        stz     a:Process::bss_base,x
        stz     a:Process::zero_base,x
        stz     a:Process::stack_base,x

        ; TODO: copy current dir

        ; Unlock scheduler mutex
        dec     disable_scheduler

        ; Replicate last 32 bytes of stack and reposition D in these
        ; When syscall returns, D will be the correct value but the stack will be offset down to ensure no clobbering

        ; Transfer original SP to A
        tsc

        ; Transfer original SP + 1 to X
        tax
        inx

        ; Subtract 32 from SP
        sub     #32
        tcs

        ; Transfer new SP + 1 to Y
        tay
        iny

        ; Call memcpy to create duplicate of current stack
        pea     32  ; Push number of bytes to copy
        phx         ; Push original SP + 1
        phy         ; Push new SP + 1
        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        ; Move D accordingly
        tdc
        sub     #32
        tcd

        ; ISR frame for child
        sep     #$20
        pla
        ply
        ply
        ply
        ply
        pla
        ply
        pla
        rep     #$20

        ; Child returns with 0
        lda     #0

done:
parent_vfork:
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc

EXEC_SIZE = 3000

; void *load_o65(uint8_t *o65)
; stack_init returned in A, stack_base returned in X
.proc load_o65
        enter   12

        ; 0: void *text_base
        ; 2: void *data_base
        ; 4: void *bss_base
        ; 6: void *zero_base
        ; 8: void *stack_init
        ; 10: void *stack_base

        stz     z:var 0     ; text_base
        stz     z:var 2     ; data_base
        stz     z:var 4     ; bss_base
        stz     z:var 6     ; zero_base
        stz     z:var 8     ; stack_init
        stz     z:var 10    ; stack_base

        ; Allocate text space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::tlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 0 ; text_base

        ; Allocate data space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::dlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 2 ; data_base

        ; Allocate bss space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::blen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 4 ; bss_base

        ; Allocate zero space and store pointer to stack
        ldx     z:arg 0 ; o65
        lda     a:O65Header::zlen,x
        pha
        jsr     malloc
        rep     #$30
        ply
        cmp     #0
        jeq     failed
        sta     z:var 6 ; zero_base

        ; Allocate stack space and store pointer to stack
        ldx     z:arg 0 ; o65
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
        sta     z:var 10    ; stack_base
        add     1,s
        dec
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
        lda     z:arg 0 ; o65
        pha
        jsr     o65_load
        rep     #$30
        ply
        ply
        ply
        ply
        ply

        ; Lock scheduler mutex
        inc     disable_scheduler

        ldx     current_process_p
        lda     a:Process::text_base,x
        pha
        lda     z:var 0 ; text_base
        sta     a:Process::text_base,x
        jsr     free
        rep     #$30
        ply

        ldx     current_process_p
        lda     a:Process::data_base,x
        pha
        lda     z:var 2 ; data_base
        sta     a:Process::data_base,x
        jsr     free
        rep     #$30
        ply

        ldx     current_process_p
        lda     a:Process::bss_base,x
        pha
        lda     z:var 4 ; bss_base
        sta     a:Process::bss_base,x
        jsr     free
        rep     #$30
        ply

        ldx     current_process_p
        lda     a:Process::zero_base,x
        pha
        lda     z:var 6 ; zero_base
        sta     a:Process::zero_base,x
        jsr     free
        rep     #$30
        ply

        ; Unlock scheduler mutex
        dec     disable_scheduler

        lda     z:var 8     ; stack_init
        ldx     z:var 10    ; stack_base

done:
        leave
        rts

failed:
        lda     z:var 0 ; text_base
        pha
        jsr     free
        rep     #$30
        ply

        lda     z:var 2 ; data_base
        pha
        jsr     free
        rep     #$30
        ply

        lda     z:var 4 ; bss_base
        pha
        jsr     free
        rep     #$30
        ply

        lda     z:var 6 ; zero_base
        pha
        jsr     free
        rep     #$30
        ply

        lda     z:var 10 ; stack_base
        pha
        jsr     free
        rep     #$30
        ply

        lda     #0
        ldx     #0
        bra     done
.endproc

; int chdir(const char *path)
; .proc chdir
        ; enter   2

        ; 0: void *new_node

        ; Allocate new space for node
        ; pea     .sizeof(FSNode)
        ; jsr     malloc
        ; rep     #$30
        ; ply

        ; cmp     #0
        ; beq     failed

        ; Save to local variable
        ; sta     z:var 0 ; new_node

        ; Traverse path and put into allocated node
        ; pha
        ; lda     z:arg 0 ; path
        ; pha
        ; jsr     traverse_abs_path
        ; TODO: Also allow for relative
        ; rep     #$30
        ; ply
        ; ply

        ; cmp     #$FFFF
        ; beq     failed_and_free

        ; Set new dir as the one for the process, and free the old one
        ; ldx     current_process_p
        ; lda     a:Process::working_dir,x
        ; pha
        ; lda     z:var 0 ; new_node
        ; sta     a:Process::working_dir,x
        ; jsr     free
        ; rep     #$30
        ; ply

        ; lda     #0

; done:
        ; leave
        ; rts

; failed_and_free:
        ; pha
        ; jsr     free
        ; rep     #$30
        ; ply

; failed:
        ; lda     #$FFFF
        ; bra     done
; .endproc

; int execve_no_direct_call(const char *filename, char *const argv[], char *const envp[])
; Only to be called directly by syscall
.global execve_no_direct_call
.proc execve_no_direct_call
        enter

        ; Open executable file
        pea     O_RDONLY
        lda     z:arg 0 ; filename
        pha
        jsr     open
        rep     #$30
        ply
        ply

        ; If open failed, fail
        cmp     #$FFFF
        jeq     failed

        ; Push fd for later
        pha

        ; Allocate temporary load buffer
        pea     EXEC_SIZE
        jsr     malloc
        rep     #$30
        ply

        ; If malloc failed, fail.
        ; fd is currently latest on stack, so close that
        cmp     #0
        jeq     failed_malloc

        ; Pull fd to X, push buffer twice, and push fd
        plx
        pha
        pha
        phx

        ; Read program to buffer
        pea     EXEC_SIZE
        pha
        phx
        jsr     read
        rep     #$30
        ply
        ply
        ply

        ; Close fd
        jsr     close
        rep     #$30
        ply

        ; TODO: Check all above functions for errors

        ; TODO: Check for valid o65

        ; TODO: Make space for arguments and pass them in

        ; Load o65 and segments, returns new stack pointer
        jsr     load_o65
        rep     #$30
        ply

        ; If load_o65 failed, fail
        ; Buffer is the latest on stack, so free that
        cmp     #0
        jeq     failed_load_o65

        ; Pull buffer to Y, push new stack pointer and stack base
        ply
        phx     ; stack_base
        pha     ; stack_init

        ; Free load buffer
        phy     ; Buffer
        jsr     free
        rep     #$30
        ply

        ; Pull new SP to A
        pla

        ; Pull new stack_base to X
        plx

        ; Lock scheduler mutex
        inc     disable_scheduler

        ; Exit context to allow access to return address
        leave

        ; Pull return address to Y
        ply

        ; Switch to new SP
        tcs

        ; Copy new stack_base from X to D
        txa
        tcd

        ; Load current process struct to X
        ldx     current_process_p

        ; Push fake main arguments
        pea     0
        pea     0

        sep     #$20
        lda     #0
        pha     ; Program Bank
        rep     #$20
        lda     a:Process::text_base,x
        pha     ; Program Counter
        sep     #$20
        lda     #0
        pha     ; Status Register
        rep     #$20
        lda     a:Process::zero_base,x
        pha     ; Direct Page
        lda     #0
        pha     ; Fake Syscall #

        ; Load old stack_base to X, and replace in struct with new one held in D
        lda     a:Process::stack_base,x
        pha
        tdc
        sta     a:Process::stack_base,x
        plx

        ; Set D to current SP
        tsc
        tcd

        ; Push this call's return address
        phy

        enter

        ; If parent is waiting for vfork to complete, complete it
        ldx     current_process_p
        lda     a:Process::ppid,x
        asl
        tax
        lda     a:proc_table,x  ; Load parent process struct
        tax
        lda     a:Process::state,x
        cmp     #PROCESS_WAIT_VFORK
        bne     done_vfork_status
        lda     #PROCESS_READY
        sta     a:Process::state,x
done_vfork_status:

        ; Unlock scheduler mutex
        dec     disable_scheduler

        leave
        rts

failed_malloc:
        ; fd is currently latest on stack, so close that
        jsr     close
        rep     #$30
        ply
        bra     failed

failed_load_o65:
        ; Buffer is the latest on stack, so free that
        jsr     free
        rep     #$30
        ply
        bra     failed

failed:
        lda     #$FFFF
        leave
        rts
.endproc
