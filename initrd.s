.p816
.smart

.macpack generic
.macpack longbranch

.autoimport

.include "functions.inc"
.include "filesys.inc"

.data

.export initrd_root_dir
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
        .addr   0                   ; ptr

.export initrd_dev_dir
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

; struct DirEnt *fs_initrd_readdir(struct FSNode *node, unsigned int index)
.proc fs_initrd_readdir
        setup_frame
        rep     #$30

        lda     z:3     ; node
        cmp     #initrd_root_dir
        jne     failed

        lda     z:5     ; index
        cmp     #0
        jne     not_0

        ; Is rev

        ; Allocate memory for DirEnt
        pea     .sizeof(DirEnt)
        jsr     malloc
        rep     #$30
        ply

        ; Push new DirEnt struct address
        pha

        ; Push source string
        pea     initrd_dev_dir + FSNode::name

        ; Push destination string
        lda     3,s ; New DirEnt struct
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply
        
        lda     initrd_dev_dir + FSNode::inode
        plx     ; new Dirent Struct address
        sta     a:DirEnt::inode,x
        
        txa
        
        bra     done

not_0:
        bra     failed

done:
        restore_frame
        rts

failed:
        lda     #0
        bra     done
.endproc

; struct FSNode *fs_initrd_finddir(struct FSNode *node, char *name)
.proc fs_initrd_finddir
        setup_frame

        rep     #$20
        lda     #0

        restore_frame
        rts
.endproc
