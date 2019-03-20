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
.include "string.inc"
.include "dump_process_table.inc"
.include "w65c265s.inc"
.include "dirent.inc"
.include "unistd.inc"

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
syscall debug, 0
syscall open, 6
syscall read, 6
syscall write, 6
syscall clone, 14
syscall getpid, 0
syscall getppid, 0
syscall readdir, 6
syscall close, 2
syscall _exit, 2
syscall execve, 6
syscall vfork, 0

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
        lda     2,s ; Program Counter
        tax
        dex

        ; Load COP signature to A
        lda     a:0,x
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

        ; Load Syscall # - 1 to X
        ldx     z:1 ; Syscall #
        dex

        ; Load number of argument bytes in syscall to x
        lda     a:sysargn,x
        and     #$FF    ; 16-bit load and mask out upper byte
        tax

        ; Subtract number of argument bytes from SP
        phx
        tsc
        sub     1,s
        tcs
        
        ; Put address above current SP into Y
        tay
        iny

        ; Load address of arguments to A
        tdc
        add     #9

        phx     ; Push number of argument bytes
        pha     ; Push address of arguments
        phy     ; Push address of space reserved for arguments
        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        ; Stack now contains the frame needed to call functions with arguments

        ; Load Syscall # - 1 multiplied by 2 into X
        lda     z:1
        dec
        asl
        tax

        ; Re-enable interrupts
        cli

        ; Call appropriate handler
        jsr     (__SYSCALL_TABLE__,x)
        rep     #$30

        ; Save A value to Y
        tay
        
        ; Restore SP
        tdc
        tcs
        
        ; Restore A value from Y
        tya
        
        ; Remove Syscall # from stack
        ply
        
        ; Restore D
        pld

        rti

invalid_syscall:
        ;jsr     core_dump
        rti

emul_mode:  ; Syscalls in emulation mode not supported
        xce
        rti
.endproc

.proc sc_none
        rts
.endproc

.proc sc_debug
        jmp     dump_process_table
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

.proc sc_readdir
        jmp     readdir
.endproc

.proc sc_close
        jmp     close
.endproc

.proc sc__exit
        jmp     _exit
.endproc

.proc sc_execve
        jmp     execve
.endproc

.proc sc_vfork
        jmp     vfork
.endproc
