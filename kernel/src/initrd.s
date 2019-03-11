.p816
.smart

.macpack generic
.macpack longbranch

.include "initrd.inc"
.include "functions.inc"
.include "dirent.inc"
.include "filesys.inc"
.include "stdlib.inc"
.include "string.inc"

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

.code

; void initrd_init(void)
.constructor initrd_init, 6
.proc initrd_init
        rep     #$30

        pea     initrd_root_dir
        pea     root_dir
        jsr     mount_fs
        rep     #$30
        ply
        ply

        rts
.endproc

; int fs_initrd_readdir(struct FSNode *node, unsigned int index, struct DirEnt *result)
.proc fs_initrd_readdir
        enter
        rep     #$30

        lda     z:5     ; index
        cmp     #0
        jne     not_0

        ; Push result DirEnt struct pointer
        lda     z:7
        pha

        ; Push source string
        pea     initrd_dev_dir + FSNode::name

        ; Push destination string
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        lda     initrd_dev_dir + FSNode::inode
        plx     ; result Dirent Struct address
        sta     a:DirEnt::inode,x

        ; Return 0 on success
        lda     #0

        bra     done

not_0:
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

        lda     z:5 ; name
        pha

        pea     root_name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_next_0

        lda     #initrd_root_dir
        bra     done

try_next_0:
        pea     dev_name
        jsr     strcmp
        rep     #$30
        ply
        cmp     #0
        bne     try_next_1

        ; Use memmove to fill result
        pea     .sizeof(FSNode)
        pea     initrd_dev_dir
        lda     z:7 ; result
        pha
        jsr     memmove
        rep     #$30
        ply
        ply
        ply
        
        lda     #0
        
        bra     done

try_next_1:
        lda     #$FFFF

done:
        leave
        rts
.endproc

.rodata

root_name:
        .asciiz ""
dev_name:
        .asciiz "dev"
