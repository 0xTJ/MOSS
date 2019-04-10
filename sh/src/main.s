.p816
.smart

.macpack generic
.macpack longbranch

.include "functions.inc"
.include "stdio.inc"
.include "dirent.inc"
.include "fcntl.inc"
.include "builtin.inc"
.include "stdlib.inc"
.include "string.inc"
.include "unistd.inc"
.include "sys/wait.inc"

.bss

tmp_dirent:
        .tag    DirEnt
line:
        .res    64
line_idx:
        .word   0

.rodata

level_string:
        .asciiz "+-- "
four_spaces_string:
        .asciiz "    "
line_string:
        .asciiz "> "
exit_str:
        .asciiz "exit"
cant_run_str:
        .asciiz "No such file or directory"
out_of_proc_str:
        .asciiz "Out of processes"

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
        enter

main_loop:

        pea     stdout
        pea     line_string
        jsr     fputs
        rep     #$30
        ply
        ply

loop:
        jsr     getchar
        rep     #$30

        cmp     #EOF
        beq     loop
        cmp     #$0A
        beq     loop
        cmp     #$08
        beq     is_backspace
        cmp     #$7F
        beq     is_backspace
        cmp     #$0D
        beq     done_line

        ldx     line_idx
        cpx     #63
        bge     loop

        pha
        pha
        jsr     putchar
        rep     #$30
        ply
        pla

        ; Store character to buffer
        sep     #$20
        ldx     line_idx
        sta     line,x
        inx
        stz     line,x
        stx     line_idx
        rep     #$20

        bra     loop

is_backspace:
        ldx     line_idx
        cpx     #0
        beq     loop

        pha
        jsr     putchar
        rep     #$30
        ply

        sep     #$20
        ldx     line_idx
        dex
        stz     line,x
        stx     line_idx
        rep     #$20

        bra     loop

done_line:
        pea     $0D
        jsr     putchar
        rep     #$30
        ply

        pea     exit_str
        pea     line
        jsr     strcmp
        rep     #$30
        ply
        ply

        cmp     #0
        beq     exit_sh

        jsr     vfork
        cmp     #0
        bmi     out_of_proc
        cmp     #0
        bne     is_parent

        pea     line
        jsr     execve
        rep     #$30
        ply

is_parent:
        ldx     #0
        stx     line_idx
        stz     line,x

        cmp     #0
        bmi     cant_run

        jsr     wait

        jmp     main_loop

        leave
        rts

out_of_proc:
        pea     out_of_proc_str
        jsr     puts
        rep     #$30
        ply

        bra     is_parent

cant_run:
        pea     cant_run_str
        jsr     puts
        rep     #$30
        ply

        pea     $FFFF
        jsr     _exit

exit_sh:
        jsr     exit
.endproc
