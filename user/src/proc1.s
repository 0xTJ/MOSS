.p816
.smart

.macpack generic

.include "functions.inc"
.include "fcntl.inc"
.include "stdio.inc"
.include "sched.inc"

.segment "STARTUP"

        jmp     proc1

.code

.import proc2

.export proc1
.proc proc1
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

        ; Start running process 2
        pea     0
        pea     0
        pea     $77ff
        pea     proc2
        jsr     clone
        rep     #$30
        ply
        ply
        ply
        ply

loop:
        bra     loop
.endproc

.rodata

dev_ttyS0_path:
        .asciiz "/dev/ttyS0"
init_welcome_string:
        .byte "Welcome to the init process of MOSS!", $D, 0
