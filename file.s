.p816
.smart

.macpack generic

.autoimport

.include "proc.inc"
.include "functions.inc"
.include "filesys.inc"

; int open(const char *path, int oflag, ... )
.export open
.proc open
        setup_frame
        rep     #$30

        lda     z:3 ; path
        pha
        jsr     traverse_abs_path
        rep     #$30
        ply

        cmp     #0
        beq     failed

        ; Push found FSNode
        pha

        ; Load pointer to file table to X
        lda     current_process_p
        add     #Process::files_p
        tax

        ; Find the location in table of free file, location in X, file # in Y
        ldy     #0
table_loop:
        cpy     #PROC_MAX_FILES
        beq     failed
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
        restore_frame
        rts
failed:
        lda     #$FFFF  ; -1
        bra     done
.endproc
