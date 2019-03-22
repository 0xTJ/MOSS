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
        .asciiz "/"
        .res    62

.rodata

level_string:
        .asciiz "+-- "
four_spaces_string:
        .asciiz "    "
dev_prgload_path:
        .asciiz "/dev/prgload"

.code

; void rls_helper(char *abs_str, char *rel_str, int level);
.proc rls_helper
        enter
        rep     #$30

        ; Load level to A
        lda     z:arg 4 ; level

        ; If level == 0, is root and don't print an entry
        bze     done_printing_entry

        ; A = level - 1
        dec

        ; Skip printing spaces if level was 1
        bze     done_space_loop

space_loop:
        ; Push current 4 spaces to print left to stack
        pha

        ; Write out four spaces
        pea     stdout
        pea     four_spaces_string
        jsr     fputs
        rep     #$30
        ply
        ply

        ; Pull current 4 spaces to print left from stack and decrement
        pla
        dec

        ; If there are spaces left to print, loop
        bnz     space_loop

done_space_loop:

        ; Write out level indicator
        pea     stdout
        pea     level_string
        jsr     fputs
        rep     #$30
        ply
        ply

        ; Write only the name of the current entry
        lda     z:arg 2 ; rel_str
        pha
        jsr     puts
        rep     #$30
        ply

done_printing_entry:

        ; Open the current file
        pea     O_RDONLY
        lda     z:arg 0 ; abs_str
        pha
        jsr     open
        rep     #$30
        ply
        ply

        ; If that failed, done with this entry, don't close
        cmp     #$FFFF
        jeq     failed

        ; Push file descriptor
        pha

        ; Push 0, the first entry in directory
        pea     0

loop:
        ; Pull entry in directory to X and file descriptor to Y
        plx
        ply

        ; Push file descriptor, then index in directory plus 1
        phy
        inx
        phx
        dex

        ; Run readdir on this entry, at current index
        pea     tmp_dirent
        phx     ; Entry in directory
        phy     ; File descriptor
        cop     9
        rep     #$30
        ply
        ply
        ply

        ; If it didn't succeed, done with this entry
        cmp     #0
        jne     done

        lda     z:arg 2 ; rel_str
        pha
        jsr     strlen
        rep     #$30
        ply
        add     z:arg 2 ; rel_str
        pha

        ; Add slash to end of current path
        tax
        sep     #$20
        lda     #'/'
        sta     a:0,x
        rep     #$20

        ; Load latest pointer in strong from stack to A
        lda     1,s

        ; Increment level for next recursion
        ldx     z:arg 4 ; level
        inx
        phx

        ; Push pointer past current one to stack
        inc
        pha

        ; Copy name of this entry from DirEnt to path string
        pea     tmp_dirent + DirEnt::name
        pha
        jsr     strcpy
        rep     #$30
        ply
        ply

        ; Push absolute path
        ldy     z:arg 0 ; abs_str
        phy

        ; Call this function recursively
        jsr     rls_helper
        rep     #$30
        ply
        ply
        ply

        ; Set byte to 0 at position of slash to reset path length
        plx
        sep     #$20
        stz     a:0,x
        rep     #$20

        ; Go to next entry
        jmp     loop

done:
        ; Pull file index
        ply

        ; Close file descriptor
        jsr     close

failed:
        leave
        rts
.endproc

; void rls(char *root_path)
.proc rls
        enter
        rep     #$30

        ; Push 0 as int
        pea     0

        ; Push end of root_path
        lda     arg 0 ; root_path
        pha
        jsr     strlen
        rep     #$30
        ply
        add     #tmp_str
        pha

        ; Push root_path
        lda     z:arg 0 ; root_path
        pha

        ; Call helper
        jsr     rls_helper

        leave
        rts
.endproc

.export proc2
.proc proc2
        enter

        pea     tmp_str
        jsr     rls

loop:
        jsr     getchar
        rep     #$30

        pha
        jsr     putchar
        rep     #$30
        ply

        cop 2
        
        bra     loop

        leave
.endproc
