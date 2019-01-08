.p816
.smart

.macpack generic
.macpack longbranch

.include "syscall.inc"
.include "functions.inc"
.include "proc.inc"
.include "unistd.inc"
.include "sched.inc"
.include "fcntl.inc"

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

.export sysargn
sysargn:
syscall none, 0
syscall x0, 0
syscall open, 6
syscall read, 6
syscall write, 6
syscall clone, 14
syscall getpid, 0
syscall getppid, 0

.import __SYSCALL_TABLE__
.import __SYSCALL_COUNT__

; Syscall number must be loaded into A
.interruptor sys_call
.proc sys_call
        clc
        xce
        jcs     emul_mode

        rep     #$30

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
        
        ; Load address of COP signature to X
        lda     2,s
        tax
        dex
        
        ; Load COP signature to A
        sep     #$20
        lda     a:0,x
        rep     #$20
        and     #$00FF

        ; Check syscall bounds
        bze     invalid_syscall
        cmp     #__SYSCALL_COUNT__
        bgt     invalid_syscall

        ; Push D then the Syscall #
        phd
        pha

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
        ; |                     |
        ; + D Register          +
        ; |                     |
        ; +---------------------+
        ; |                     |
        ; + Syscall #           +
        ; |                     |
        ; +---------------------+

        lda     1,s
        tax
        dex
        sep     #$20
        lda     a:sysargn,x
        rep     #$20
        bze     no_syscall_args
        pha

        tsc
        inc
        inc
        tay         ; Address right below the Syscall # in stack

        add     #8  ; Address of the K Register in stack
        add     1,s ; Add the number of arguments
        tax         ; Address of the deepest byte in the stack

        pla         ; Stack is again as shown above, and # of arguments is in A
        dec
        
        mvp     0,0

        ; Y will contain the new SP, below the arguments
        tya
        tcs

no_syscall_args:
        lda     z:1 ; Load Syscall # into A

syscall_call:
        ; Multiply Syscall # - 1 by 2
        dec
        asl
        tax

        ; Re-enable interrupts
        cli
        
        jsr     (__SYSCALL_TABLE__,x)
        ; Return value in A
        
        rep     #$30

        ; Restore SP, D and remove Syscall # from stack
        tax
        tdc
        tcs
        pla
        txa
        pld

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

.proc sc_x0
        rts
.endproc

.proc sc_getpid
        rep     #$30
        
        ldx     current_process_p
        lda     Process::pid,x

        rts
.endproc

.proc sc_getppid
        rep     #$30
        
        ldx     current_process_p
        lda     Process::ppid,x

        rts
.endproc

.proc sc_open
        jmp     open
.endproc

.proc sc_read
        jmp     read
.endproc

.proc sc_write
        jmp     write
.endproc

.proc sc_clone
        jmp     clone
.endproc
