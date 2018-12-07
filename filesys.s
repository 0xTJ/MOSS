.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "filesys.inc"

.data

.export root_dir
root_dir:
        .byte   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; name
        .word   FS_DIRECTORY    ; flags
        .word   0               ; inode
        .addr   0               ; read
        .addr   0               ; write
        .addr   0               ; open
        .addr   0               ; close
        .addr   0               ; readdir
        .addr   0               ; finddir
        .addr   0               ; ptr

.code

; void mount_fs(struct FSNode *mount_point, struct FSNode *mounted)
.export mount_fs
.proc mount_fs
        setup_frame
        
        ; Load mounted into X
        ldx     z:5
        
        ; Check that the mounted is a directory, and not already mounted on
        lda     a:FSNode::flags,x
        and     #FS_TYPE_BITS
        cmp     #FS_DIRECTORY
        bne     invalid_type
        
        ; Move mounted to Y
        txy

        ; Load mount_point into X
        rep     #$30
        ldx     z:3
        
        ; Store mounted into mount point's ptr
        tya
        sta     a:FSNode::ptr,x
        
        ; Add mount point flag to flags
        lda     a:FSNode::flags,x
        ora     #FS_MOUNTPOINT
        sta     a:FSNode::flags,x

invalid_type:
        restore_frame
        rts
.endproc

; unsigned int read_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.export read_fs
.proc read_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:3
        
        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     a:FSNode::read,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:9
        pha
        lda     z:7
        pha
        lda     z:5
        pha
        lda     z:3
        pha
        
        ; Jump to file-system-specific read function
        jsr     (FSNode::read,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        ply
        ply
        ply
        
done:
        restore_frame
        rts
.endproc

; unsigned int write_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.export write_fs
.proc write_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:3
        
        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     a:FSNode::write,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:9
        pha
        lda     z:7
        pha
        lda     z:5
        pha
        lda     z:3
        pha
        
        ; Jump to file-system-specific write function
        jsr     (FSNode::write,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        ply
        ply
        ply
        
done:
        restore_frame
        rts
.endproc

; void open_fs(struct FSNode *node, uint8_t read, uint8_t write)
.export open_fs
.proc open_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:3
        
        ; Check if function exists in node and if it doesn't, exit
        lda     a:FSNode::open,x
        bze     done
        
        ; Copy parameters onto current stack
        sep     #$20
        lda     z:6
        pha
        lda     z:5
        pha
        rep     #$20
        lda     z:3
        pha
        
        ; Jump to file-system-specific open function
        jsr     (FSNode::open,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        sep     #$10
        ply
        ply
        rep     #$10
        
done:
        restore_frame
        rts
.endproc

; void close_fs(struct FSNode *node)
.export close_fs
.proc close_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:3
        
        ; Check if function exists in node and if it doesn't, exit
        lda     a:FSNode::close,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:3
        pha
        
        ; Jump to file-system-specific close function
        jsr     (FSNode::close,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        
done:
        restore_frame
        rts
.endproc

; struct DirEnt *readdir_fs(struct FSNode *node, unsigned int index)
.export readdir_fs
.proc readdir_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:3
        
        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     a:FSNode::readdir,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:5
        pha
        lda     z:3
        pha
        
        ; Jump to file-system-specific readdir function
        jsr     (FSNode::readdir,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        ply
        
done:
        restore_frame
        rts
.endproc

; struct FSNode *finddir_fs(struct FSNode *node, char *name)
.export finddir_fs
.proc finddir_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:3
        
        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     a:FSNode::finddir,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:5
        pha
        lda     z:3
        pha
        
        ; Jump to file-system-specific finddir function
        jsr     (FSNode::finddir,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        ply
        
done:
        restore_frame
        rts
.endproc
