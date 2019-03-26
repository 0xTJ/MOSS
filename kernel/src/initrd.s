.p816
.smart

.macpack generic
.macpack longbranch

.include "initrd.inc"
.include "functions.inc"
.include "dirent.inc"
.include "filesys.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "string.inc"

.rodata

root_name:
        .asciiz ""
dev_name:
        .asciiz "dev"
sh_name:
        .asciiz "sh"
init_name:
        .asciiz "init"
sh_o65:
        .incbin "../../sh/sh.o65"
init_o65:
        .incbin "../../init/init.o65"

.data

initrd_root_dir:
        .byte   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; name
        .word   FS_DIRECTORY        ; flags
        .word   0                   ; inode
        .addr   0                   ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   fs_initrd_readdir   ; readdir
        .addr   fs_initrd_finddir   ; finddir
        .word   0                   ; impl
        .addr   0                   ; ptr

initrd_dev_dir:
        .byte   'd', 'e', 'v', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; name
        .word   FS_DIRECTORY        ; flags
        .word   1                   ; inode
        .addr   0                   ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   fs_initrd_readdir   ; readdir
        .addr   fs_initrd_finddir   ; finddir
        .word   0                   ; impl
        .addr   0                   ; ptr

initrd_sh_file:
        .byte   's', 'h', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; name
        .word   FS_FILE             ; flags
        .word   2                   ; inode
        .addr   fs_initrd_read      ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   0                   ; readdir
        .addr   0                   ; finddir
        .word   sh_o65              ; impl
        .addr   0                   ; ptr

initrd_init_file:
        .byte   'i', 'n', 'i', 't', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; name
        .word   FS_FILE             ; flags
        .word   3                   ; inode
        .addr   fs_initrd_read      ; read
        .addr   0                   ; write
        .addr   0                   ; open
        .addr   0                   ; close
        .addr   0                   ; readdir
        .addr   0                   ; finddir
        .word   init_o65            ; impl
        .addr   0                   ; ptr

.code

; void initrd_init(void)
.constructor initrd_init, 6
.proc initrd_init
        enter

        pea     initrd_root_dir
        pea     root_dir
        jsr     mount_fs
        rep     #$30
        ply
        ply

        leave
        rts
.endproc

; unsigned int fs_initrd_read(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc fs_initrd_read
        enter

        lda     z:arg 0 ; node
        pha
        jsr     puts
        rep     #$30
        ply
        
        ; Push number of bytes to read
        lda     z:arg 4 ; size
        pha

        ; Push source pointer
        ldx     z:arg 0 ; node
        lda     a:FSNode::impl,x
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

; int fs_initrd_readdir(struct FSNode *node, unsigned int index, struct DirEnt *result)
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
        pea     initrd_dev_dir + FSNode::name

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     initrd_dev_dir + FSNode::inode
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
        pea     initrd_sh_file + FSNode::name

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     initrd_sh_file + FSNode::inode
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
        pea     initrd_init_file + FSNode::name

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     initrd_init_file + FSNode::inode
        ldx     z:arg 4 ; result
        sta     a:DirEnt::inode,x

        ; Return 0 on success
        lda     #0
        bra     done

not_2:
        bra     failed

done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc

; int fs_initrd_finddir(struct FSNode *node, char *name, struct FSNode *result)
.proc fs_initrd_finddir
        enter
        rep     #$30

try_0:
        lda     z:arg 2 ; name
        pha
        pea     root_name
        jsr     strcmp
        rep     #$30
        ply
        ply
        cmp     #0
        bne     try_1

        ; Use memmove to fill result
        pea     .sizeof(FSNode)
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
        bra     done

try_1:
        lda     z:arg 2 ; name
        pha
        pea     dev_name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_2

        ; Use memmove to fill result
        pea     .sizeof(FSNode)
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
        pea     sh_name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_3

        ; Use memmove to fill result
        pea     .sizeof(FSNode)
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
        pea     init_name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_4

        ; Use memmove to fill result
        pea     .sizeof(FSNode)
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
        bra     failed
        
done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc
