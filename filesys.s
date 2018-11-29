.p816

.macpack generic

.autoimport

.include "functions.inc"
.include "filesys.inc"

; void mount_fs(struct FSNode *mount_point, struct FSNode *mounted)
.proc mount_fs
        setup_frame
        
        ; Load mounted into X
        ldx     z:3
        
        ; Check that the mounted is a directory
        lda     FSNode::flags,x
        and     #FS_TYPE_BITS
        cmp     FS_DIRECTORY
        bne     invalid_type
        
        ; Move mounted to Y
        txy

        ; Load mount_point into X
        rep     #$30
        ldx     z:1
        
        ; Store mounted into mount point's ptr
        sty     FSNode::ptr,x
        
        ; Add mount point flag to flags
        lda     FSNode::flags,x
        ora     FS_MOUNTPOINT
        sta     FSNode::flags,x

invalid_type:
        restore_frame
        rts
.endproc

; unsigned int read_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc read_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:1
        
        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     FSNode::read,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:7
        pha
        lda     z:5
        pha
        lda     z:3
        pha
        lda     z:1
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
.proc write_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:1
        
        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     FSNode::read,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:7
        pha
        lda     z:5
        pha
        lda     z:3
        pha
        lda     z:1
        pha
        
        ; Jump to file-system-specific read function
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
.proc open_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:1
        
        ; Check if function exists in node and if it doesn't, exit
        lda     FSNode::read,x
        bze     done
        
        ; Copy parameters onto current stack
        sep     #$20
        lda     z:5
        pha
        lda     z:3
        pha
        rep     #$20
        lda     z:1
        pha
        
        ; Jump to file-system-specific read function
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
.proc close_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:1
        
        ; Check if function exists in node and if it doesn't, exit
        lda     FSNode::read,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:1
        pha
        
        ; Jump to file-system-specific read function
        jsr     (FSNode::close,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        
done:
        restore_frame
        rts
.endproc

; struct DirEnt *readdir_fs(struct FSNode *node, unsigned int index)
.proc readdir_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:1
        
        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     FSNode::readdir,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:3
        pha
        lda     z:1
        pha
        
        ; Jump to file-system-specific read function
        jsr     (FSNode::read,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        ply
        
done:
        restore_frame
        rts
.endproc

; struct FSNode *finddir_fs(struct FSNode *node, char *name)
.proc finddir_fs
        setup_frame

        rep     #$30
        
        ; Load node to x
        ldx     z:1
        
        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     FSNode::read,x
        bze     done
        
        ; Copy parameters onto current stack
        lda     z:3
        pha
        lda     z:1
        pha
        
        ; Jump to file-system-specific read function
        jsr     (FSNode::finddir,x)
        
        ; Remove parameters from stack
        rep     #$30
        ply
        ply
        
done:
        restore_frame
        rts
.endproc
