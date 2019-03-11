.p816
.smart

.macpack generic

.include "proc.inc"
.include "functions.inc"
.include "stdlib.inc"
.include "stdio.inc"
.include "fcntl.inc"
.include "filesys.inc"
.include "unistd.inc"
.include "dirent.inc"

.code

; ssize_t read(int fd, void *buf, size_t nbyte)
.proc read
        enter
        rep     #$30

        lda     z:3 ; fd
        cmp     #0
        blt     failed
        cmp     #PROC_MAX_FILES
        bge     failed

        ; Put fd * 2 + base of file table into X
        asl
        add     current_process_p
        add     #Process::files_p
        tax

        ; Load address of FSNode to A
        lda     a:0,x
        bze     failed

        ; Run read on it
        ldx     z:5 ; buf
        phx
        ldx     z:7 ; nbyte
        phx
        pea     0
        pha
        jsr     read_fs
        rep     #$30
        ply
        ply
        ply
        ply

done:
        leave
        rts
failed:
        lda     #$FFFF  ; -1
        bra     done
.endproc

; ssize_t write(int fd, const void *buf, size_t nbyte)
.proc write
        enter
        rep     #$30

        lda     z:3 ; fd
        cmp     #0
        blt     failed
        cmp     #PROC_MAX_FILES
        bge     failed

        ; Put fd * 2 + base of file table into X
        asl
        add     current_process_p
        add     #Process::files_p
        tax

        ; Load address of FSNode to A
        lda     a:0,x
        bze     failed

        ; Run read on it
        ldx     z:5 ; buf
        phx
        ldx     z:7 ; nbyte
        phx
        pea     0
        pha
        jsr     write_fs
        rep     #$30
        ply
        ply
        ply
        ply

done:
        leave
        rts
failed:
        lda     #$FFFF  ; -1
        bra     done
.endproc

; int open(const char *pathname, int flags, ... /* mode_t mode */)
.proc open
        enter
        rep     #$30

        ; Allocate result FSNode
        pea     .sizeof(FSNode)
        jsr     malloc
        rep     #$30
        ply

        cmp     #0
        beq     failed_malloc

        ; Push pointer to result FSNode for later
        pha

        ; Push pointer to result FSNode for path traversal
        pha

        ; Push path
        lda     z:3 ; path
        pha

        jsr     traverse_abs_path
        rep     #$30
        ply
        ply

        cmp     #$FFFF
        beq     failed_traverse_path

        ; Result FSNode pointer already on stack

        ; Load pointer to file table to X
        lda     current_process_p
        add     #Process::files_p
        tax

        ; Find the location in table of free file, location in X, file # in Y
        ldy     #0
table_loop:
        cpy     #PROC_MAX_FILES
        beq     failed_out_of_fd
        lda     a:0,x
        bze     table_done
        inx
        inx
        iny
        bra     table_loop
table_done:

        ; Store into table
        pla     ; found FSNode
        sta     a:0,x

        ; Push file #
        phy

        ; Run open on it
        pea     0
        pha
        jsr     open_fs
        rep     #$30
        ply
        ply

        ; Pull file #
        pla

done:
        leave
        rts

failed_traverse_path:
failed_out_of_fd:
        ; Allocated FSNode pointer already on stack
        jsr     free
        rep     #$30

failed_malloc:
        lda     #$FFFF  ; -1
        bra     done
.endproc

; int close(int fd)
.proc close
        enter
        rep     #$30

        lda     z:3 ; fd
        cmp     #0
        blt     failed
        cmp     #PROC_MAX_FILES
        bge     failed

        ; Put fd * 2 + base of file table into X
        asl
        add     current_process_p
        add     #Process::files_p
        tax

        ; Push pointer to pointer to FSNode to stack for later
        phx

        ; Load address of FSNode to A
        lda     a:0,x
        bze     failed

        ; Run close on it
        pha
        jsr     close_fs
        rep     #$30
        ply

        ; Pull pointer to pointer to FSNode from stack and push it back
        plx
        phx

        ; Load address of FSNode to A
        lda     a:0,x

        ; Free the pointer to FSNode
        pha
        jsr     free
        rep     #$30
        ply

        ; Pull pointer to pointer to FSNode from stack
        plx
        
        ; Clear file descriptor
        stz     a:0,x

done:
        leave
        rts

failed:
        lda     #$FFFF  ; -1
        bra     done
.endproc

; int readdir(unsigned int fd, unsigned int count, struct DirEnt *result)
.proc readdir
        enter
        rep     #$30

        lda     z:3 ; fd
        cmp     #0
        blt     failed
        cmp     #PROC_MAX_FILES
        bge     failed

        ; Put fd * 2 + base of file table into X
        asl
        add     current_process_p
        add     #Process::files_p
        tax
        
        ; Load address of FSNode to A
        lda     a:0,x
        bze     failed

        ; Run read on it
        ldx     z:7 ; result
        phx
        ldx     z:5 ; count
        phx
        pha
        jsr     readdir_fs
        rep     #$30
        ply
        ply
        ply

done:
        leave
        rts

failed:
        lda     #$FFFF  ; -1
        bra     done
.endproc
