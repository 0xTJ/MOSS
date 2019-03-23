.p816
.smart

.macpack generic

.include "functions.inc"
.include "fcntl.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "unistd.inc"
.include "sched.inc"

.import proc2

.segment "STARTUP"

.proc _start
        enter

        ; Setup stack frame
        lda     z:2 ; argv
        pha
        lda     z:0 ; argc
        pha

        ; Call main
        jsr     main
        rep     #$30

        ; Call exit
        pha
        jsr     exit

loop_forever:
        bra     loop_forever
.endproc

.code

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
        
        cop     2
        jsr     _exit

        ; Start running process 2
        ; pea     0
        ; pea     0
        ; pea     $EFFF
        ; pea     proc2
        ; jsr     clone
        ; rep     #$30
        ; ply
        ; ply
        ; ply
        ; ply

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
dev_prgload_path:
        .asciiz "/dev/prgload"
