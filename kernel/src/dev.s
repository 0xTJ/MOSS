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
        vnode   .addr
        next    .addr
.endstruct

.bss

.global devices_list
devices_list:
        .addr   0

last_dev_inode:
        .word   0

; struct vnode *dev_root_dir
.global dev_root_dir
dev_root_dir:
        .addr   0

.rodata

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

        ; Load struct Device * to X
        ldx     z:arg 0 ; node
        lda     a:vnode::impl,x
        tax

        ; If impl is NULL, not a device, fail
        bze     failed

        ; Load device type to A
        lda     a:Device::type,x

        ; Is it a character device?
        cmp     #DEV_TYPE_CHAR
        beq     chardevice

        ; Device type not recognized, fail
        bra     failed

chardevice:
        ; Load char driver to X
        lda     a:Device::driver,x
        tax

        ; Call read with arguments
        lda     z:arg 2 ; offset
        pha
        lda     z:arg 4 ; size
        pha
        lda     z:arg 6 ; buffer
        pha
        phx
        jsr     (CharDriver::read,x)
        rep     #$30
        ply
        ply
        ply
        ply

        ; Done read operation, return with value from device read
        bra     done

done:
        leave
        rts

failed:
        lda     #0
        bra     done
.endproc

; unsigned int fs_dev_write(struct vnode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.proc fs_dev_write
        enter

        ; Load struct Device * to X
        ldx     z:arg 0 ; node
        lda     a:vnode::impl,x
        bze     failed
        tax

        lda     a:Device::type,x

        cmp     #DEV_TYPE_CHAR
        beq     chardevice
        bra     failed

chardevice:
        ; Load char driver to X
        lda     a:Device::driver,x
        tax

        ; Call write with arguments
        ldy     z:arg 2 ; offset
        phy
        ldy     z:arg 4 ; size
        phy
        ldy     z:arg 6 ; buffer
        phy
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

		; Return 0
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
        
        ; Get device pointer from name
        lda     z:arg 2 ; name
        pha
        jsr     dev_from_name
        rep     #$30
        ply

        ; If it returned NULL, return error
		tax
        beq     failed

        ; Get pointer to vnode in A
        lda     a:Device::vnode,x

        ; Reference this vnode
        pha
        pha
        jsr     vref
        rep     #$30
        ply
        pla

        ; Store vnode to result
        sta     (arg 4)

		; Return 0
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
        enter

		; jsr		vfs_init

		; Get new vnode for root of dev
		pea		dev_root_dir
		pea		dev_root_dir_vops
		pea		VTYPE_DIRECTORY
		jsr		newvnode
        rep     #$30
        ply
        ply
        ply

		; TODO: Check for success

        lda     dev_root_dir
        pha
        lda     initrd_dev_dir
        ; lda     root_vnode
        pha
        jsr     mount_fs
        rep     #$30
        ply
        ply

        leave
        rts
.endproc

; void register_char_driver(struct CharDriver *driver, const char *name)
.proc register_char_driver
        enter

        ; Allocate driver struct and put pointer into X
        pea     .sizeof(Device)
        jsr     malloc
        rep     #$30
        ply
        tax

		; If alloc failed, exit
        jeq     failed

        ; Store driver to struct
        lda     z:arg 0 ; driver
        sta     a:Device::driver,x

        ; Store name string to struct
        lda     z:arg 2 ; name
        sta     a:Device::name,x

        ; Store type to struct
        lda     #DEV_TYPE_CHAR
        sta     a:Device::type,x

        ; Reset next device
        stz     a:Device::next,x

		; Push new device for later
		phx

		; Get new vnode
		txa
		add		#Device::vnode
		pha		; Result location
		pea		dev_device_vops
		pea		VTYPE_CHARDEVICE
		jsr		newvnode
        rep     #$30
        ply
        ply
        ply

		; Pull new device to A
		pla

        ; Load new vnode to X
        tax
        ldy     a:Device::vnode,x
        tyx

		; Store device pointer as impl in vnode
        sta     a:vnode::impl,x

        ; Add to list
        ldy     devices_list
        bnz     find_loop		; Will branch if the list pointer is not NULL
        sta     devices_list    ; Store directly to the list pointer if this is the first being added
        bra     done
find_loop:
        tyx
        ldy     a:Device::next,x
        bnz     find_loop
        sta     a:Device::next,x

done:
        leave
        rts

failed:
		bra		done
.endproc
