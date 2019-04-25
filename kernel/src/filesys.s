.p816
.smart

.macpack generic
.macpack longbranch

.include "filesys.inc"
.include "functions.inc"
.include "vfs.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "string.inc"

.code

; struct vnode *follow_mounts(struct vnode *node)
; Input node must be referenced before input, and must not be used afterwards, it is released.
.proc follow_mounts
        enter

        ldx     z:arg 0

        bra     skip_first

loop:
        ldy     a:vnode::ptr,x

        ; Reference the new one, release the old one, and load the new one to X
        phy
        phx
        phy
        jsr     vref
        rep     #$30
        ply
        jsr     vrele
        rep     #$30
        ply
        plx

skip_first:
        lda     a:vnode::type,x
        cmp     #VTYPE_DIRECTORY | VTYPE_MOUNTPOINT
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

; int traverse_rel_path(struct vnode *node, char *path, struct vnode **result)
; Both nodes can be the same, node is read before result is overwritten
.proc traverse_rel_path
        enter   2
        
        ; 0: struct vnode *new_vnode_p

start:
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
        lda     a:vnode::type,x
        cmp     #VTYPE_DIRECTORY
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
        
        ; Push result pointer

        ; Push pointer in path to stack as path for recursive call
        phy

        ; Push location of new_vnode_p twice
        ; Once for finddir_fs
        ; Once for recursive call
        tdc
        add     #var 0
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

        ; Loop
        jmp     start

        ; Return with result from recursive call
done:
        leave
        rts

empty_path:
        rep     #$30

        ; Move address of node to result
        lda     z:arg 0 ; node
        sta     (arg 4) ; result

        ; Return 0 on success
        lda     #0

        bra     done

failed:
        rep     #$30
        lda     #$FFFF  ; Return -1
        bra     done
.endproc

; int traverse_abs_path(char *path, struct vnode *result)
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

        ; Push root_vnode
        pea     root_vnode

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

; void mount_fs(struct vnode *mount_point, struct vnode *mounted)
.proc mount_fs
        enter
        rep     #$30

        ; Load mounted into X
        ldx     z:arg 2

        ; Check that the mounted is a directory, and not already mounted on
        lda     a:vnode::type,x
        cmp     #VTYPE_DIRECTORY
        bne     invalid_type

        ; Move mounted to Y
        txy

        ; Load mount_point into X
        rep     #$30
        ldx     z:arg 0

        ; Store mounted into mount point's ptr
        tya
        sta     a:vnode::ptr,x

        ; Add mount point flag to type
        lda     a:vnode::type,x
        ora     #VTYPE_MOUNTPOINT
        sta     a:vnode::type,x

invalid_type:
        leave
        rts
.endproc

; unsigned int read_fs(struct vnode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc read_fs
        enter
        rep     #$30

        ; Load node to x
        ldy     z:arg 0

        ; Check if function exists in node and if it doesn't, exit with A = 0
        ldx     a:vnode::vops,y
        lda     a:vops::read,x
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
        jsr     (vops::read,x)

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

; unsigned int write_fs(struct vnode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc write_fs
        enter
        rep     #$30

        ; Load node to x
        ldy     z:arg 0

        ; Check if function exists in node and if it doesn't, exit with A = 0
        ldx     a:vnode::vops,y
        lda     a:vops::write,x
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
        jsr     (vops::write,x)

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

; void open_fs(struct vnode *node, uint8_t read, uint8_t write)
.proc open_fs
        enter
        rep     #$30

        ; Load node to x
        ldy     z:arg 0

        ; Check if function exists in node and if it doesn't, exit
        ldx     a:vnode::vops,y
        lda     a:vops::open,x
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
        jsr     (vops::open,x)

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

; void close_fs(struct vnode *node)
.proc close_fs
        enter
        rep     #$30

        ; Load node to x
        ldy     z:arg 0

        ; Check if function exists in node and if it doesn't, exit
        ldx     a:vnode::vops,y
        lda     a:vops::close,x
        bze     done

        ; Copy parameters onto current stack
        lda     z:arg 0
        pha

        ; Jump to file-system-specific close function
        jsr     (vops::close,x)

        ; Remove parameters from stack
        rep     #$30
        ply

done:
        leave
        rts
.endproc

; int readdir_fs(struct vnode *node, unsigned int index, struct DirEnt *result)
.proc readdir_fs
        enter
        rep     #$30

        ; Load node to x
        ldy     z:arg 0

        ; Check if function exists in node and if it doesn't, exit with A = 0
        ldx     a:vnode::vops,y
        lda     a:vops::readdir,x
        bze     not_found

        ; Copy parameters onto current stack
        lda     z:arg 4
        pha
        lda     z:arg 2
        pha
        lda     z:arg 0
        pha

        ; Jump to file-system-specific readdir function
        jsr     (vops::readdir,x)

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

; int finddir_fs(struct vnode *node, char *name, struct vnode **result)
.proc finddir_fs
        enter
        rep     #$30

        ; Load node to x
        ldy     z:arg 0

        ; Check if function exists in node and if it doesn't, exit with A = 0
        ldx     a:vnode::vops,y
        lda     a:vops::finddir,x
        bze     not_found

        ; Copy parameters onto current stack
        lda     z:arg 4
        pha
        lda     z:arg 2
        pha
        lda     z:arg 0
        pha

        ; Jump to file-system-specific finddir function
        jsr     (vops::finddir,x)

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
