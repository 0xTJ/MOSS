.p816
.smart

.macpack generic

.include "functions.inc"
.include "fcntl.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "unistd.inc"
.include "sched.inc"
.include "sys/wait.inc"

.rodata

dev_ttyS0_path:
        .asciiz "/dev/ttyS0"
sh_path:
        .asciiz "/sh"
init_welcome_string:
        .byte $0D
        .asciiz "MOSS Started!"
exit_str:
        .asciiz "Exiting to Monitor ROM"

.code

; void print_int(int value, int base)
.proc print_int
        enter   6

        lda     z:arg 2 ; base
        pha
        tda
        add     #var 0
        pha
        lda     z:arg 0 ; value
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply

        tda
        add     #var 0
        pha
        jsr     puts
        rep     #$30
        ply
        ply

        leave
        rts
.endproc

.global main
.proc main
        enter   2

        ; 0: pid_t root_shell

        ; Setup stdin
        pea     O_RDONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

        ; Setup stdout
        pea     O_WRONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

        ; Setup stderr
        pea     O_WRONLY
        pea     dev_ttyS0_path
        cop     3
        rep     #$30
        ply
        ply

        ; Print init_welcome_string to stdout
        pea     init_welcome_string
        jsr     puts
        rep     #$30
        ply

        ; Fork process
        jsr     vfork
        
        ; If it failed, exit to monitor ROM
        cmp     #$FFFF
        beq     exit_to_monrom
        
        ; If we're in parent, branch to appropriate location
        cmp     #0
        bne     in_parent
        
        ; Execute shell
        pea     NULL
        pea     NULL
        pea     sh_path
        jsr     execve
        rep     #$30
        ply
        ply
        ply
        
        ; If we get here, exec failed, reboot
        bra     exit_to_monrom

in_parent:
        ; Store root child in root_shell
        sta     z:var 0 ; root_shell

loop_forever:
        ; Wait for child to exit
        pea     NULL
        jsr     wait
        rep     #$30
        ply

        ; Loop if it is not root child PID
        cmp     z:var 0 ; root_shell
        bne     loop_forever

exit_to_monrom:
        ; Indicate that we are exiting
        pea     exit_str
        jsr     puts
        rep     #$30
        ply

        ; Delay a bit to allow message to finish printing
        ldy     #$FFFF
delay_loop:
        dey
        bnz     delay_loop

        ; Perform watchdog hard reset
        hard_reset
.endproc
