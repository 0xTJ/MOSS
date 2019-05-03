.p816
.smart

.macpack generic
.macpack longbranch

.include "initrd.inc"
.include "functions.inc"
.include "dirent.inc"
.include "vfs.inc"
.include "filesys.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "string.inc"

.struct initrd_entry
        name    .addr
        data    .addr
        next    .addr
.endstruct

.bss

initrd_root_dir:
        .addr   0
initrd_dev_dir:
        .addr   0
initrd_init_file:
        .addr   0
initrd_sh_file:
        .addr   0
initrd_ls_file:
        .addr   0

.rodata

init_o65:
        .incbin "../../init/init.o65"
sh_o65:
        .incbin "../../sh/sh.o65"
ls_o65:
        .incbin "../../ls/ls.o65"

root_name:
        .asciiz ""
dev_name:
        .asciiz "dev"
init_name:
        .asciiz "init"
sh_name:
        .asciiz "sh"
ls_name:
        .asciiz "ls"

root_data:
        .addr   root_name
        .addr   0
        .addr   dev_data
dev_data:
        .addr   dev_name
        .addr   0
        .addr   init_data
init_data:
        .addr   init_name
        .addr   init_o65
        .addr   sh_data
sh_data:
        .addr   sh_name
        .addr   sh_o65
        .addr   ls_data
ls_data:
        .addr   ls_name
        .addr   ls_o65
        .addr   0

.data

; struct vops initrd_dir_vops
initrd_dir_vops:
        .addr   0                   ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   fs_initrd_readdir   ; readdir
        .addr   fs_initrd_finddir   ; finddir

; struct vops initrd_dev_vops
initrd_dev_vops:
        .addr   0                   ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   0                   ; readdir
        .addr   0                   ; finddir

; struct vops initrd_file_vops
initrd_file_vops:
        .addr   fs_initrd_read      ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   0                   ; readdir
        .addr   0                   ; finddir

.code

; void initrd_init(void)
.constructor initrd_init, 6
.proc initrd_init
        enter

		jsr		vfs_init

		; Get new vnode for root of initrd
		pea		initrd_root_dir
		pea		initrd_dir_vops
		pea		VTYPE_DIRECTORY
		jsr		newvnode
        rep     #$30
        ply
        ply
        ply

        lda     initrd_root_dir
        pha
        lda     root_vnode
        pha
        jsr     mount_fs
        rep     #$30
        ply
        ply

        pea     initrd_dev_dir
		pea		0
		pea		VTYPE_DIRECTORY
		jsr		newvnode
        rep     #$30
        ply
        ply
        ply

        pea     initrd_init_file
		pea		initrd_file_vops
		pea		VTYPE_FILE
		jsr		newvnode
        rep     #$30
        ply
        ply
        ply

        pea     initrd_sh_file
		pea		initrd_file_vops
		pea		VTYPE_FILE
		jsr		newvnode
        rep     #$30
        ply
        ply
        ply

        pea     initrd_ls_file
		pea		initrd_file_vops
		pea		VTYPE_FILE
		jsr		newvnode
        rep     #$30
        ply
        ply
        ply

        ldx     initrd_root_dir
        lda     #root_data
        sta     a:vnode::impl,x

        ldx     initrd_dev_dir
        lda     #dev_data
        sta     a:vnode::impl,x

        ldx     initrd_init_file
        lda     #init_data
        sta     a:vnode::impl,x

        ldx     initrd_sh_file
        lda     #sh_data
        sta     a:vnode::impl,x

        ldx     initrd_ls_file
        lda     #ls_data
        sta     a:vnode::impl,x

        leave
        rts
.endproc

; unsigned int fs_initrd_read(struct vnode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc fs_initrd_read
        enter

        ; Push number of bytes to read
        lda     z:arg 4 ; size
        pha

        ; Push source pointer
        ldx     z:arg 0 ; node
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::data,y
        add     z:arg 2 ; offset
        pha

        ; Push destination pointer
        lda     z:arg 6 ; buffer
        pha

        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        lda     z:arg 4 ; size

done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc

; int fs_initrd_readdir(struct vnode *node, unsigned int index, struct DirEnt *result)
.proc fs_initrd_readdir
        enter

        ; Fail if this is not the root
        lda     z:arg 0 ; node
        cmp     initrd_root_dir
        jne     failed

        ; Skip if this is not index 0
        lda     z:arg 2 ; index
        cmp     #0
        jne     not_0

        ; Push source string
        ldx     initrd_dev_dir
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     #0
        ldx     z:arg 4 ; result
        sta     a:DirEnt::inode,x

        ; Return 0 on success
        lda     #0
        jmp     done

not_0:
        ; Skip if this is not index 1
        lda     z:arg 2 ; index
        cmp     #1
        jne     not_1

        ; Push source string
        ldx     initrd_ls_file
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     #1
        ldx     z:arg 4 ; result
        sta     a:DirEnt::inode,x

        ; Return 0 on success
        lda     #0
        bra     done

not_1:
        ; Skip if this is not index 2
        lda     z:arg 2 ; index
        cmp     #2
        jne     not_2

        ; Push source string
        ldx     initrd_init_file
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     #2
        ldx     z:arg 4 ; result
        sta     a:DirEnt::inode,x

        ; Return 0 on success
        lda     #0
        bra     done

not_2:
        ; Skip if this is not index 3
        lda     z:arg 2 ; index
        cmp     #3
        jne     not_3

        ; Push source string
        ldx     initrd_sh_file
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     #3
        ldx     z:arg 4 ; result
        sta     a:DirEnt::inode,x

        ; Return 0 on success
        lda     #0
        bra     done

not_3:
        bra     failed

done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc

; int fs_initrd_finddir(struct vnode *node, char *name, struct vnode **result)
.proc fs_initrd_finddir
        enter

        lda     z:arg 2 ; name
        pha
        ldx     initrd_root_dir
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha
        jsr     strcmp
        rep     #$30
        ply
        ply
        cmp     #0
        bne     try_1

        ; Fill result
        lda     initrd_root_dir
        sta     (arg 4)

        bra     success

try_1:
        lda     z:arg 2 ; name
        pha
        ldx     initrd_dev_dir
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_2

        ; Fill result
        lda     initrd_dev_dir
        sta     (arg 4)

        bra     success

try_2:
        lda     z:arg 2 ; name
        pha
        ldx     initrd_sh_file
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_3

        ; Fill result
        lda     initrd_sh_file
        sta     (arg 4)

        bra     success

try_3:
        lda     z:arg 2 ; name
        pha
        ldx     initrd_init_file
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_4

        ; Fill result
        lda     initrd_init_file
        sta     (arg 4)

        bra     success

try_4:
        lda     z:arg 2 ; name
        pha
        ldx     initrd_ls_file
        ldy     a:vnode::impl,x
        lda     a:initrd_entry::name,y
        pha
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_5

        ; Fill result
        lda     initrd_ls_file
        sta     (arg 4)

        bra     success

try_5:
        bra     failed

success:
        ; Reference vnode
        pha
        jsr     vref
        rep     #$30
        ply

        ; Return 0
        lda     #0

done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc
