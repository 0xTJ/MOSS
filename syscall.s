.p816
.smart

.macpack generic

.autoimport

.include "proc.inc"
.include "functions.inc"

.macro syscall sc_proc, arg_count
.ifndef syscall_count
syscall_count .set 1
.out "|Syscall #|Syscall Name|Arg Count|"
.endif
        .byte arg_count
.condes .ident(.sprintf("sc_%s", .string(sc_proc))), 3, syscall_count + 1
.out .sprintf("|       %02X|%-12s|       %2X|", syscall_count, .string(sc_proc), arg_count)
syscall_count .set syscall_count + 1
.endmacro

sysargn:
syscall none, 0
syscall get_pid, 0
syscall putc_serial, 1

; Syscall number must be loaded into A
.interruptor sys_call
.proc sys_call
        clc
        xce
        bcs     emul_mode

        and     #$00FF  ; Only lower 8 bits matter
        
        ; Check syscall bounds
        bze     invalid_syscall
        cmp     __SYSCALL_COUNT__
        bgt     invalid_syscall
        
        sep     #$20
        pha     ; Push the Syscall #
        rep     #$30

        ; Load D with the address below the Syscall #
        tsc
        tcd
        
        ; Stack:
        ; | Arguments           |
        ; +---------------------+
        ; | K Register          | \
        ; +---------------------+  |
        ; |                     |  |
        ; + Program Counter     +  |- Pushed by interrupt
        ; |                     |  |
        ; +---------------------+  |
        ; | Status Register     | /
        ; +---------------------+
        ; | Syscall #           |
        ; +---------------------+
        
        tax
        lda     sysargn,x
        bze     no_syscall_args
        pha
        
        tsc
        inc
        tay         ; Address right below the Syscall # in stack
        
        add     #5  ; Address of the K Register in stack
        add     1,s ; Add the number of arguments
        tax         ; Address of the deepest byte in the stack
        
        pla         ; Stack is again as shown above, and # of arguments is in A
        dec
        
        mvp     0,0
        
        ; Y will contain the new SP, below the arguments
        tya
        tcs

no_syscall_args:
        lda     z:3 ; Load Syscall # into A

syscall_call:
        ; Multiply Syscall # by 2
        asl
        tax

        jsr     (__SYSCALL_TABLE__,x)
        ; Return value in A
        
        ; Restore SP and remove Syscall # from stack
        tax
        tdc
        tcs
        pla
        txa
        
        rti
        
invalid_syscall:
        ;jsr     core_dump
        rti

emul_mode:  ; Syscalls in emulation mode not supported
        lda     #$FF
        ldx     #$FF
        xce
        rti
.endproc

.proc sc_none
        rts
.endproc

.proc sc_get_pid
        rep     #$30
        ldx     current_process_p
        lda     Process::pid,x

        rts
.endproc

.proc sc_putc_serial
        setup_frame
        jsl     SEND_BYTE_TO_PC
        restore_frame
.endproc
