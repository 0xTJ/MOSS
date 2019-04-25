.p816
.smart

.macpack generic

.include "proc.inc"
.include "functions.inc"
.include "vfs.inc"
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

        ; Fail if fd isn't in bounds
        lda     z:arg 0 ; fd
        cmp     #0
        blt     failed
        cmp     #PROC_MAX_FILES
        bge     failed

        ; Put fd * 2 + base of file table into X
        asl
        add     current_process_p
        add     #Process::files_p
        tax

        ; Load address of vnode to A
        lda     a:0,x
        bze     failed

        ; Run read on it
        ldx     z:arg 2 ; buf
        phx
        ldx     z:arg 4 ; nbyte
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

        ; Fail if fd isn't in bounds
        lda     z:arg 0 ; fd
        cmp     #0
        blt     failed
        cmp     #PROC_MAX_FILES
        bge     failed

        ; Put fd * 2 + base of file table into X
        asl
        add     current_process_p
        add     #Process::files_p
        tax

        ; Load address of vnode to A
        lda     a:0,x
        bze     failed

        ; Run read on it
        ldx     z:arg 2 ; buf
        phx
        ldx     z:arg 4 ; nbyte
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
        enter 	2
		
		; 0: struct vnode *found_node

        ; Traverse path
		tdc
		add		#var 0	; &found_node
        pha
        lda     z:arg 0 ; path
        pha
        jsr     traverse_abs_path
        rep     #$30
        ply
        ply

        ; If failed, fail
        cmp     #$FFFF
        beq     failed

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
        lda		z:var 0 ; found_node
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

        ; Return file #
        pla
        leave
        rts

failed_out_of_fd:
        ; Allocated vnode pointer already on stack
        jsr     vrele
        rep     #$30
        ply

failed:
        ; Return -1
        lda     #$FFFF
        leave
        rts
.endproc

; int close(int fd)
.proc close
        enter
        rep     #$30

        ; Fail if fd isn't in bounds
        lda     z:arg 0 ; fd
        cmp     #0
        blt     failed
        cmp     #PROC_MAX_FILES
        bge     failed

        ; Put fd * 2 + base of file table into X
        asl
        add     current_process_p
        add     #Process::files_p
        tax

        ; Push pointer to pointer to vnode to stack for later
        phx

        ; Load address of vnode to A
        lda     a:0,x
        bze     failed

        ; Run close on it
        pha
        jsr     close_fs
        rep     #$30
        ply

        ; Pull pointer to pointer to vnode from stack and push it back
        plx
        phx

        ; Load address of vnode to A
        lda     a:0,x

        ; Free the pointer to vnode
        pha
        jsr     vrele
        rep     #$30
        ply

        ; Pull pointer to pointer to vnode from stack
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

        ; Fail if fd isn't in bounds
        lda     z:arg 0 ; fd
        cmp     #0
        blt     failed
        cmp     #PROC_MAX_FILES
        bge     failed

        ; Put fd * 2 + base of file table into X
        asl
        add     current_process_p
        add     #Process::files_p
        tax

        ; Load address of vnode to A
        lda     a:0,x
        bze     failed

        ; Run read on it
        ldx     z:arg 4 ; result
        phx
        ldx     z:arg 2 ; count
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
