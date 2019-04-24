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

.rodata

init_o65:
        .incbin "../../init/init.o65"
sh_o65:
        .incbin "../../sh/sh.o65"
ls_o65:
        .incbin "../../ls/ls.o65"

.data

; struct vops initrd_dir_vops
initrd_dir_vops:
        .addr   fs_dev_read         ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   0                   ; readdir
        .addr   0                   ; finddir

; struct vops initrd_file_vops
initrd_file_vops:
        .addr   0                   ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   fs_initrd_readdir   ; readdir
        .addr   fs_initrd_finddir   ; finddir

.code

; void initrd_init(void)
; .constructor initrd_init, 6
.proc initrd_init
        enter

		; Get new vnode for root of initrd
		pea		initrd_root_dir
		pea		dev_root_dir_vops
		pea		VTYPE_DIRECTORY
		jsr		newvnode
        rep     #$30
        ply
        ply
        ply

        pea     initrd_root_dir
        pea     root_dir
        jsr     mount_fs
        rep     #$30
        ply
        ply

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
        lda     a:vnode::impl,x
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
        rep     #$30

        ; Fail if this is not the root
        ; lda     z:arg 0 ; node
        ; cmp     #initrd_root_dir
        ; bne     failed

        ; Skip if this is not index 0
        lda     z:arg 2 ; index
        cmp     #0
        jne     not_0

        ; Push source string
        pea     initrd_dev_dir + vnode::name

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     initrd_dev_dir + vnode::inode
        ldx     z:arg 4 ; result
        sta     a:DirEnt::inode,x

        ; Return 0 on success
        lda     #0
        bra     done

not_0:
        ; Skip if this is not index 1
        lda     z:arg 2 ; index
        cmp     #1
        jne     not_1

        ; Push source string
        pea     initrd_sh_file + vnode::name

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     initrd_sh_file + vnode::inode
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
        pea     initrd_init_file + vnode::name

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     initrd_init_file + vnode::inode
        ldx     z:arg 4 ; result
        sta     a:DirEnt::inode,x

        ; Return 0 on success
        lda     #0
        bra     done

not_2:
        ; Skip if this is not index 2
        lda     z:arg 2 ; index
        cmp     #3
        jne     not_3

        ; Push source string
        pea     initrd_ls_file + vnode::name

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     initrd_ls_file + vnode::inode
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

; int fs_initrd_finddir(struct vnode *node, char *name, struct vnode *result)
.proc fs_initrd_finddir
        enter
        rep     #$30

try_0:
        lda     z:arg 2 ; name
        pha
        pea     initrd_root_dir + vnode::name
        jsr     strcmp
        rep     #$30
        ply
        ply
        cmp     #0
        bne     try_1

        ; Use memmove to fill result
        pea     .sizeof(vnode)
        pea     initrd_root_dir
        lda     z:arg 4 ; result
        pha
        jsr     memmove
        rep     #$30
        ply
        ply
        ply

        ; Return 0
        lda     #0
        jmp     done

try_1:
        lda     z:arg 2 ; name
        pha
        pea     initrd_dev_dir + vnode::name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_2

        ; Use memmove to fill result
        pea     .sizeof(vnode)
        pea     initrd_dev_dir
        lda     z:arg 4 ; result
        pha
        jsr     memmove
        rep     #$30
        ply
        ply
        ply

        ; Return 0
        lda     #0
        bra     done

try_2:
        lda     z:arg 2 ; name
        pha
        pea     initrd_sh_file + vnode::name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_3

        ; Use memmove to fill result
        pea     .sizeof(vnode)
        pea     initrd_sh_file
        lda     z:arg 4 ; result
        pha
        jsr     memmove
        rep     #$30
        ply
        ply
        ply

        ; Return 0
        lda     #0
        bra     done

try_3:
        lda     z:arg 2 ; name
        pha
        pea     initrd_init_file + vnode::name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_4

        ; Use memmove to fill result
        pea     .sizeof(vnode)
        pea     initrd_init_file
        lda     z:arg 4 ; result
        pha
        jsr     memmove
        rep     #$30
        ply
        ply
        ply

        ; Return 0
        lda     #0
        bra     done

try_4:
        lda     z:arg 2 ; name
        pha
        pea     initrd_ls_file + vnode::name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_5

        ; Use memmove to fill result
        pea     .sizeof(vnode)
        pea     initrd_ls_file
        lda     z:arg 4 ; result
        pha
        jsr     memmove
        rep     #$30
        ply
        ply
        ply

        ; Return 0
        lda     #0
        bra     done

try_5:
        bra     failed
        
done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc
