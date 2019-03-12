.p816
.smart

.macpack generic
.macpack longbranch

.include "filesys.inc"
.include "functions.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "string.inc"

.pushseg
.bss
tmp:
.res 64
.popseg

.data

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
        .word   0               ; impl
        .addr   0               ; ptr

.code

; struct FSNode *follow_mounts(struct FSNode *node)
.proc follow_mounts
        enter

        rep     #$30

        lda     z:arg 0
        tax

        bra     skip_first

loop:
        ldy     a:FSNode::ptr,x
        tyx
skip_first:
        lda     a:FSNode::flags,x
        and     #FS_TYPE_BITS
        cmp     #FS_DIRECTORY | FS_MOUNTPOINT
        beq     loop

        txa
        leave
        rts
.endproc

; char *follow_mounts(const char *path)
.proc skip_slashes
        enter
        rep     #$30

        ldx     z:arg 0 ; path

        ; Check first char of path for '/', and ignore it in a loop
        sep     #$20
loop:
        lda     a:0,x
        cmp     #'/'
        bne     done_loop
        inx
        bra     loop
done_loop:

        rep     #$30
        txa

        leave
        rts
.endproc

; int traverse_rel_path(struct FSNode *node, char *path, struct FSNode *result)
; Both nodes can be the same, node is read before result is overwritten
.proc traverse_rel_path
        enter
        rep     #$30

        ; User follow_mounts to update node in arguments
        lda     z:arg 0 ; node
        pha
        jsr     follow_mounts
        rep     #$30
        ply
        sta     z:arg 0 ; node

        ; Skip leading slashes in path and write back
        lda     z:arg 2 ; path
        pha
        jsr     skip_slashes
        rep     #$30
        ply
        sta     z:arg 2

        ; Check for path being empty and jump to empty_path if it is.
        ldx     z:arg 2 ; node
        sep     #$20
        lda     a:0,x
        jeq     empty_path
        rep     #$30

        ; Check that node is a directory
        ldx     z:arg 0 ; node
        lda     a:FSNode::flags,x
        cmp     #FS_DIRECTORY
        jne     failed

        ; Make space for string on stack
        tsc
        sub     #17
        tcs

        ; Push address of string twice
        inc
        pha
        pha

        ; Load path to X
        ldx     z:arg 2

        sep     #$20

path_segment_loop:
        ; Load first character of relative path to A
        lda     a:0,x

        ; If it is 0 or '/', done segment
        cmp     #0
        beq     done_path_segment
        cmp     #'/'
        beq     done_path_segment

        ; Temporarily store pointer in path argument into Y
        txy

        ; Store A into string on stack, and increment pointer on stack (second pushed) to string on stack
        plx
        sta     a:0,x
        inx
        phx

        ; Transfer location in path back to X
        tyx

        ; Increment pointer in path
        inx

        bra     path_segment_loop

done_path_segment:
        ; Store null-terminator in string on stack
        txy     ; Store location in path argument in Y
        plx     ; Load string on stack from stack to X
        stz     a:0,x   ; Store 0 to string on stack
        ; Intentionally don't push back the location in string on stack

        rep     #$30

        ; Pull beginning of string on stack to X
        plx

        ; Make stack space for FSNode and put pointer to it in A
        tsc
        sub     #.sizeof(FSNode)
        tcs
        inc

        ; Push location of result FSNode as result for recursive call
        lda     z:arg 4
        pha

        ; Push pointer in path to stack as path for recursive call
        phy

        ; Push location of result FSNode twice
        ; Once as base for recursive call
        ; Once for call to finddir_fs
        pha
        pha

        ; Push beginning of string on stack from X
        phx

        ; Push starting node
        lda     z:arg 0
        pha

        ; Call finddir_fs and pull arguments
        jsr     finddir_fs
        rep     #$30
        ply
        ply
        ply

        cmp     #$FFFF
        beq     failed

        ; Location of 0 or '/' in path argument is currently on stack

        ; Call self recursively
        jsr     traverse_rel_path

        ; Return with result from recursive call
done:
        leave
        rts

empty_path:
        rep     #$30

        ; Move node to result
        pea     .sizeof(FSNode)
        lda     z:arg 0 ; node
        pha
        lda     z:arg 4 ; result
        pha
        jsr     memmove
        rep     #$30
        ply
        ply
        ply

        ; Return 0 on success
        lda     #0

        bra     done

failed:
        rep     #$30
        lda     #$FFFF  ; Return -1
        bra     done
.endproc

; int traverse_abs_path(char *path, struct FSNode *result)
.export traverse_abs_path
.proc traverse_abs_path
        enter
        rep     #$30

        ; Push result node
        lda     z:arg 2
        pha

        ; Load path to X
        ldx     z:arg 0

        ; Check first char of path for '/'
        sep     #$20
        lda     a:0,x
        cmp     #'/'
        bne     failed
        rep     #$20

        ; Push path string
        phx

        ; Push root_dir
        pea     root_dir

        jsr     traverse_rel_path
        rep     #$30
        ply
        ply
        ply

done:
        leave
        rts

failed:
        rep     #$20
        lda     #$FFFF
        bra     done
.endproc

; void mount_fs(struct FSNode *mount_point, struct FSNode *mounted)
.proc mount_fs
        enter
        rep     #$30

        ; Load mounted into X
        ldx     z:arg 2

        ; Check that the mounted is a directory, and not already mounted on
        lda     a:FSNode::flags,x
        and     #FS_TYPE_BITS
        cmp     #FS_DIRECTORY
        bne     invalid_type

        ; Move mounted to Y
        txy

        ; Load mount_point into X
        rep     #$30
        ldx     z:arg 0

        ; Store mounted into mount point's ptr
        tya
        sta     a:FSNode::ptr,x

        ; Add mount point flag to flags
        lda     a:FSNode::flags,x
        ora     #FS_MOUNTPOINT
        sta     a:FSNode::flags,x

invalid_type:
        leave
        rts
.endproc

; unsigned int read_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc read_fs
        enter
        rep     #$30

        ; Load node to x
        ldx     z:arg 0

        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     a:FSNode::read,x
        bze     done

        ; Copy parameters onto current stack
        lda     z:arg 6
        pha
        lda     z:arg 4
        pha
        lda     z:arg 2
        pha
        lda     z:arg 0
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
        leave
        rts
.endproc

; unsigned int write_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc write_fs
        enter
        rep     #$30

        ; Load node to x
        ldx     z:arg 0

        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     a:FSNode::write,x
        bze     done

        ; Copy parameters onto current stack
        lda     z:arg 6
        pha
        lda     z:arg 4
        pha
        lda     z:arg 2
        pha
        lda     z:arg 0
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
        leave
        rts
.endproc

; void open_fs(struct FSNode *node, uint8_t read, uint8_t write)
.proc open_fs
        enter
        rep     #$30

        ; Load node to x
        ldx     z:arg 0

        ; Check if function exists in node and if it doesn't, exit
        lda     a:FSNode::open,x
        bze     done

        ; Copy parameters onto current stack
        sep     #$20
        lda     z:arg 3
        pha
        lda     z:arg 2
        pha
        rep     #$20
        lda     z:arg 0
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

        ; Return 0
        lda     #0

done:
        leave
        rts
.endproc

; void close_fs(struct FSNode *node)
.proc close_fs
        enter
        rep     #$30

        ; Load node to x
        ldx     z:arg 0

        ; Check if function exists in node and if it doesn't, exit
        lda     a:FSNode::close,x
        bze     done

        ; Copy parameters onto current stack
        lda     z:arg 0
        pha

        ; Jump to file-system-specific close function
        jsr     (FSNode::close,x)

        ; Remove parameters from stack
        rep     #$30
        ply

done:
        leave
        rts
.endproc

; int readdir_fs(struct FSNode *node, unsigned int index, struct DirEnt *result)
.proc readdir_fs
        enter
        rep     #$30

        ; Load node to x
        ldx     z:arg 0

        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     a:FSNode::readdir,x
        bze     not_found

        ; Copy parameters onto current stack
        lda     z:arg 4
        pha
        lda     z:arg 2
        pha
        lda     z:arg 0
        pha

        ; Jump to file-system-specific readdir function
        jsr     (FSNode::readdir,x)

        ; Remove parameters from stack
        rep     #$30
        ply
        ply
        ply

done:
        leave
        rts

not_found:
        lda     #$FFFF
        bra     done
.endproc

; int finddir_fs(struct FSNode *node, char *name, struct FSNode *result)
.proc finddir_fs
        enter
        rep     #$30

        ; Load node to x
        ldx     z:arg 0

        ; Check if function exists in node and if it doesn't, exit with A = 0
        lda     a:FSNode::finddir,x
        bze     not_found

        ; Copy parameters onto current stack
        lda     z:arg 4
        pha
        lda     z:arg 2
        pha
        lda     z:arg 0
        pha

        ; Jump to file-system-specific finddir function
        jsr     (FSNode::finddir,x)

        ; Remove parameters from stack
        rep     #$30
        ply
        ply
        ply

done:
        leave
        rts

not_found:
        lda     #$FFFF
        bra     done
.endproc
