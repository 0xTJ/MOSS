.p816
.smart

.macpack generic
.macpack longbranch

.include "functions.inc"
.include "stdio.inc"
.include "dirent.inc"
.include "fcntl.inc"
.include "ctype.inc"
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
failed_exec_str:
        .asciiz "Failed to execute"
failed_fork_str:
        .asciiz "Failed to fork"

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
        ; Set index to 0 and store 0 to that location
        ldx     #0
        stx     line_idx
        stz     line,x
        
        ; Put prompt
        pea     stdout
        pea     line_string
        jsr     fputs
        rep     #$30
        ply
        ply

loop:
        ; Get a character
        jsr     getchar
        rep     #$30

        ; Check if it is printable
        pha
        pha
        jsr     isprint
        rep     #$30
        ply
        tax
        pla
        cpx     #0
        bne     is_printable
        
        ; Check for EOF or NL, and loop if found
        cmp     #EOF
        beq     loop
        cmp     #$0A
        beq     loop
        
        ; Check for BS or DEL, and backspace if found
        cmp     #$08
        beq     is_backspace
        cmp     #$7F
        beq     is_backspace
        
        ; Check for CR, and loop if found
        cmp     #$0D
        beq     done_line

is_printable:
        ; Loop if at maximum index
        ldx     line_idx
        cpx     #63
        bge     loop

        ; Put received character
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

        ; Loop
        bra     loop

is_backspace:
        ; Don't do anything if we can't backspace
        ldx     line_idx
        cpx     #0
        beq     loop

        ; Print backspace to update screen
        pha
        jsr     putchar
        rep     #$30
        ply

        ; Back up index and store 0 to this location
        sep     #$20
        ldx     line_idx
        dex
        stz     line,x
        stx     line_idx
        rep     #$20

        ; Loop
        bra     loop

done_line:
        ; Print CR
        pea     $0D
        jsr     putchar
        rep     #$30
        ply

        ; Check if it is exit, and exit if it is
        pea     exit_str
        pea     line
        jsr     strcmp
        rep     #$30
        ply
        ply
        cmp     #0
        bne     no_exit
        pea     0
        jsr     exit
no_exit:

        ; Perform vfork
        jsr     vfork
        
        ; If vfork failed, handle
        ora     #0
        bmi     out_of_proc
        
        ; If this is the parent process, 
        cmp     #0
        bne     in_parent

        ; Run command
        pea     NULL
        pea     NULL
        pea     line
        jsr     execve
        rep     #$30
        ply
        ply
        ply

        ; If execve returned, it failed and we must notify and _exit
        pea     failed_exec_str
        jsr     puts
        rep     #$30
        ply
        pea     $FFFF
        jsr     _exit

in_parent:
        ; Wait for child to exit
        pea     NULL
        jsr     wait
        rep     #$30
        ply

        ; Start again
        jmp     main_loop

out_of_proc:
        ; Notify that no process could be made
        pea     failed_fork_str
        jsr     puts
        rep     #$30
        ply

        ; Start again
        jmp     main_loop
.endproc
