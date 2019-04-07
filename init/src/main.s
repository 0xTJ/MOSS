.p816
.smart

.macpack generic

.include "functions.inc"
.include "fcntl.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "unistd.inc"
.include "sched.inc"

.rodata

sh_path:
        .asciiz "/sh"

.code

.global main
.proc main
        enter

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

        jsr     vfork
        cmp     #0
        bne     loop_forever
        pea     sh_path
        jsr     execve
parent:

loop_forever:
        bra     loop_forever

        leave
        rts
.endproc

.bss

tmp_str:
        .res    32

.rodata

dev_ttyS0_path:
        .asciiz "/dev/ttyS0"
init_welcome_string:
        .byte $0D
        .asciiz "Welcome to the init process of MOSS!"
