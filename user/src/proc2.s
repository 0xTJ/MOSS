.p816
.smart

.macpack generic

.include "functions.inc"
.include "stdio.inc"
.include "dirent.inc"
.include "fcntl.inc"
.include "stdlib.inc"
.include "unistd.inc"

.bss

tmp:
        .tag    DirEnt
tmp_str:
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0
        .word   0

.rodata

path:
        .asciiz "/"

.code

.export proc2
.proc proc2
        pea     O_RDONLY
        pea     path
        jsr     open
        rep     #$30
        ply
        ply

        pea     tmp
        pea     0
        pha
        cop     9
        rep     #$30
        ply
        ply
        ply

        pea     10
        pea     tmp_str
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     tmp + DirEnt::name
        jsr     puts
        rep     #$30
        ply

loop:
        jsr     getchar
        rep     #$30

        pha
        jsr     putchar
        rep     #$30
        ply

        bra     loop
.endproc
