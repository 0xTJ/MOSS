.p816
.smart

.macpack generic
.macpack longbranch

.include "vfs.inc"
.include "functions.inc"
.include "stdlib.inc"

.data

; struct vops root_vops
root_vops:
        .addr   0     			; read
        .addr   0    			; write
        .addr   0               ; open
        .addr   0               ; close
        .addr   0               ; readdir
        .addr   0               ; finddir

.bss

root_vnode:
        .addr   0

.code

; void vfs_init(void)
.constructor vfs_init, 4
.proc vfs_init
		enter

		pea		root_vnode
		pea		root_vops
		pea		VTYPE_DIRECTORY
		jsr		newvnode

		leave
		rts
.endproc

; int newvnode(enum vtype type, struct vops *vops, struct vnode **new_vnode)
.proc newvnode
        enter

        ; Allocate new vnode
        pea     .sizeof(vnode)
        jsr     malloc
        rep     #$30
        ply

        ; Fail if couldn't allocate
        cmp     #0
        beq     failed

        ; Put new vnode pointer into X
        tax

        ; Store type and vops
        lda     z:arg 0 ; type
        sta     a:vnode::type,x
        lda     z:arg 2 ; vops
        sta     a:vnode::vops,x

        ; Set usecount to 1
        lda     #1
        sta     a:vnode::usecount,x

        ; Reset other fields
        stz     a:vnode::impl,x
        stz     a:vnode::ptr,x

        ; Store vnode pointer to return pointer
        txa
        ldx     z:arg 4 ; new_vnode
        sta     a:0,x   ; *new_vnode

        ; Return 0
        lda     #0
        leave
        rts

failed:
        ; Return -1
        lda     #$FFFF
        leave
        rts
.endproc

; void vref(struct vnode *vp)
.proc vref
        enter

        ldx     z:arg 0 ; vp
        inc     a:vnode::usecount,x

        leave
        rts
.endproc

; void vrele(struct vnode *vp)
.proc vrele
        enter

        ldx     z:arg 0 ; vp
        dec     a:vnode::usecount,x

        leave
        rts
.endproc
