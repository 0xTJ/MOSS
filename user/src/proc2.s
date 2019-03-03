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
        .asciiz "/dev"

.code

.export proc2
.proc proc2
        pea     O_RDONLY
        pea     path
        jsr     open
        rep     #$30
        ply
        ply

        pha
        pea     0

list_loop:
        plx
        ply
        phy
        phx

        pea     tmp
        phx
        phy
        cop     9
        rep     #$30
        ply
        ply
        ply

        cmp     #0
        bne     done_list

        pea     tmp + DirEnt::name
        jsr     puts
        rep     #$30
        ply

        pla
        inc
        pha

        bra     list_loop

done_list:

        ply
        
        jsr     close

loop:
        jsr     getchar
        rep     #$30

        pha
        jsr     putchar
        rep     #$30
        ply

        bra     loop
.endproc
