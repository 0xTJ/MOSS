.p816
.smart

.macpack generic

.include "functions.inc"
.include "fcntl.inc"
.include "stdio.inc"
.include "stdlib.inc"
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

        ; Start running process 1
        pea     0
        pea     0
        pea     $BFFF
        pea     proc2
        jsr     clone
        rep     #$30
        ply
        ply
        ply
        ply

        leave
        rts
.endproc

.rodata

dev_ttyS0_path:
        .asciiz "/dev/ttyS0"
init_welcome_string:
        .byte $0D
        .asciiz "Welcome to the init process of MOSS!"
