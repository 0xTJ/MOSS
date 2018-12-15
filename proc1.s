.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "proc.inc"
.include "fcntl.inc"

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
        
        ; Manually start running process 2
        jsr     create_proc
        pea     proc2
        pea     $77ff
        pha
        jsr     setup_proc
        rep     #$30
        plx
        ply
        ply
        lda     #1
        sta     a:Process::running,x

loop:
        bra     loop
.endproc

.rodata

dev_ttyS0_path:
        .asciiz "/dev/ttyS0"
init_welcome_string:
        .asciiz "Welcome to the Init process of MOSS!"
