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

.bss

tmp_dirent:
        .tag    DirEnt
tmp_str:
        .res    64

.rodata

level_string:
        .asciiz "+-- "
four_spaces_string:
        .asciiz "    "
line_string:
        .asciiz "> "

.code

.global main
.proc main
        enter
        
        pea     stdout
        pea     line_string
        jsr     fputs
        rep     #$30
        ply
        ply
        
loop:
        jsr     getchar
        rep     #$30

        pha
        jsr     putchar
        rep     #$30
        ply

        bra     loop

        leave
        rts
.endproc
