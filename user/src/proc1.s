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
        
        cop 2

        ; Print init_welcome_string to stdout
        ; pea     init_welcome_string
        ; jsr     puts
        ; rep     #$30
        ; ply

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
        cop 2   
        pea     init_welcome_string
        jsr     puts
        rep     #$30
        ply
        bra     loop_forever

        leave
        rts
.endproc

.rodata

dev_ttyS0_path:
        .asciiz "/dev/ttyS0"
init_welcome_string:
        .byte $0D
        .asciiz "Welcome to the init process of MOSS!"
dev_prgload_path:
        .asciiz "/dev/prgload"
