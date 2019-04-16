.p816
.smart

.macpack generic
.macpack longbranch

.include "functions.inc"
.include "vfs.inc"
.include "filesys.inc"
.include "dev.inc"
.include "dirent.inc"
.include "initrd.inc"
.include "stdlib.inc"
.include "string.inc"

.struct Device
        type    .word
        driver  .addr
        name    .addr
        fsnode  .tag    vnode
        next    .addr
.endstruct

.bss

devices_list:
        .addr   0

last_dev_inode:
        .word   0

; struct vnode *dev_root_dir
dev_root_dir:
        .addr   0

.data

; struct vops dev_root_dir_vops
dev_root_dir_vops:
        .addr   0               ; read
        .addr   0               ; write
        .addr   0               ; open
        .addr   0               ; close
        .addr   fs_dev_readdir  ; readdir
        .addr   fs_dev_finddir  ; finddir

; struct vops dev_root_dir_vops
dev_device_vops:
        .addr   fs_dev_read     ; read
        .addr   fs_dev_write    ; write
        .addr   0               ; open
        .addr   0               ; close
        .addr   0               ; readdir
        .addr   0               ; finddir

.code

; struct Device *dev_from_name(char *name)
.proc dev_from_name
        enter
        rep     #$30

        ; Push name to compare
        lda     z:arg 0 ; name
        pha

        ; Load devices pointer to X
        ldx     devices_list

        bra     skip_first_loop

loop:
        ldy     a:Device::next,x
        tyx

skip_first_loop:
        ; Check if NULL
        cpx     #0
        beq     done

        lda     a:Device::name,x
        pha
        jsr     strcmp
        rep     #$30
        ply

        ; Check if strcmp returned 0, and don't loop if it did
        cmp     #0
        bne     loop

done:
        txa
        leave
        rts
.endproc

; unsigned int fs_dev_read(struct vnode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc fs_dev_read
        enter
        rep     #$30

        ldx     z:arg 0 ; node

        ; Load struct Device * to X
        lda     a:vnode::impl,x
        bze     failed
        tax

        ldy     z:arg 2 ; offset
        phy
        ldy     z:arg 4 ; size
        phy
        ldy     z:arg 6 ; buffer
        phy

        lda     a:Device::type,x

        cmp     #DEV_TYPE_CHAR
        beq     chardevice
        bra     failed

chardevice:
        ; Load char driver to X
        lda     a:Device::driver,x
        tax

        ; Push char driver pointer and call read
        phx
        jsr     (CharDriver::read,x)
        rep     #$30
        ply
        ply
        ply
        ply

failed:

        leave
        rts
.endproc

; unsigned int fs_dev_write(struct vnode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc fs_dev_write
        enter
        rep     #$30

        ldx     z:arg 0 ; node

        ; Load struct Device * to X
        lda     a:vnode::impl,x
        bze     failed
        tax

        ldy     z:arg 2 ; offset
        phy
        ldy     z:arg 4 ; size
        phy
        ldy     z:arg 6 ; buffer
        phy

        lda     a:Device::type,x

        cmp     #DEV_TYPE_CHAR
        beq     chardevice
        bra     failed

chardevice:
        ; Load char driver to X
        lda     a:Device::driver,x
        tax

        ; Push char driver pointer and call write
        phx
        jsr     (CharDriver::write,x)
        rep     #$30
        ply
        ply
        ply
        ply

failed:

        leave
        rts
.endproc

; int fs_dev_readdir(struct vnode *node, unsigned int index, struct DirEnt *result)
.proc fs_dev_readdir
        enter
        rep     #$30

        ; Load device list first item
        ldx     devices_list

        ; Exit if no devices exist yet
        bze     failed

        ; Load index into A
        lda     z:arg 2

        ; Go through list until A is 0
        bze done_loop
loop:
        ldy     a:Device::next,x
        bze     failed  ; Exit if reached end of list
        tyx
        dec
        bnz     loop

done_loop:

        ; Push driver name string pointer
        lda     a:Device::name,x
        pha

        ; Push destination string
        lda     z:arg 4 ; result
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        ; Write inode
        lda     1,s
        tax
        lda     z:arg 4 ; result
        inc
        sta     a:DirEnt::inode,x

        lda     #0

done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc

; int fs_dev_finddir(struct vnode *node, char *name, struct vnode **result)
.proc fs_dev_finddir
        enter
        rep     #$30

        ; Get device pointer from name
        lda     z:arg 2 ; name
        pha
        jsr     dev_from_name
        rep     #$30
        ply

        ; If it failed, return error
        cmp     #0
        beq     failed

        ; Get pointer to vnode
        add     #Device::fsnode

        ; Use memmove to fill result
        pea     .sizeof(vnode)
        pha
        lda     z:arg 4 ; result
        pha
        jsr     memmove
        rep     #$30
        ply
        ply
        ply

        lda     #0

done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc

; void dev_init(void)
.constructor dev_init
.proc dev_init
        rep     #$30

        pea     dev_root_dir
        pea     initrd_dev_dir
        jsr     mount_fs
        rep     #$30
        ply
        ply

        rts
.endproc

; void register_driver(struct CharDriver *driver, const char *name, int type)
.proc register_driver
        enter
        rep     #$30

        ; Allocate driver struct and put address in X
        pea     .sizeof(Device)
        jsr     malloc
        rep     #$30
        ply
        jeq     failed_driver_alloc
        tax

        ; Store driver to struct
        lda     z:arg 0 ; driver
        sta     a:Device::driver,x

        ; Store name string to struct
        lda     z:arg 2 ; name
        sta     a:Device::name,x

        ; Store type to struct
        lda     z:arg 4 ; type
        sta     a:Device::type,x

        ; Reset next device
        stz     a:Device::next,x

        ; Generate inode #
        ; TODO

        ; Load vnode
        ; lda     z:arg 4 ; type
        ; cmp     #DEV_TYPE_CHAR
        ; beq     chardevice
        bra     failed_device_type

; chardevice:
        ; phx     ; Save X
        ; lda     a:Device::name,x
        ; pha     ; Push address of source string
        ; txa
        ; add     a:Device::fsnode + vnode::name
        ; pha     ; Push address of vnode string
        ; jsr     strcpy
        ; rep     #$30
        ; ply
        ; ply
        ; plx     ; Restore X

        ; lda     #FS_CHARDEVICE
        ; sta     a:Device::fsnode + vnode::flags,x
        ; inc     last_dev_inode
        ; lda     last_dev_inode
        ; sta     a:Device::fsnode + vnode::inode,x
        ; lda     #fs_dev_read
        ; sta     a:Device::fsnode + vnode::read,x
        ; lda     #fs_dev_write
        ; sta     a:Device::fsnode + vnode::write,x
        ; stz     a:Device::fsnode + vnode::open,x
        ; stz     a:Device::fsnode + vnode::close,x
        ; stz     a:Device::fsnode + vnode::readdir,x
        ; stz     a:Device::fsnode + vnode::finddir,x
        ; txa
        ; sta     a:Device::fsnode + vnode::impl,x
        ; stz     a:Device::fsnode + vnode::ptr,x
        ; bra     done_type_spec

done_type_spec:

        ; Add to list
        txa                     ; Move struct address to A
        ldy     devices_list    ; Will jump if the list pointer is not NULL
        bnz     find_loop
        sta     devices_list    ; Store directly to the list pointer if this is the first being added
        bra     done
find_loop:
        tyx
        ldy     a:Device::next,x
        bnz     find_loop
        sta     a:Device::next,x

        bra     done

failed_device_type:
        phx
        jsr     free
        rep     #$30
        ply

failed_driver_alloc:

done:
        leave
        rts
.endproc
