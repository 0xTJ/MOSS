.p816
.smart

.macpack generic
.macpack longbranch

.autoimport

.include "functions.inc"
.include "filesys.inc"
.include "dev.inc"

.struct Device
        type    .word
        driver  .addr
        name    .addr
        next    .addr
.endstruct

.bss

.export devices_list
devices_list:
        .addr   0

.data

.export dev_root_dir
dev_root_dir:
        .byte   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; name
        .word   FS_DIRECTORY    ; flags
        .word   0               ; inode
        .addr   0               ; read
        .addr   0               ; write
        .addr   0               ; open
        .addr   0               ; close
        .addr   fs_dev_readdir  ; readdir
        .addr   fs_dev_finddir  ; finddir
        .addr   0               ; ptr

.code

; struct Device *dev_from_name(char *name)
.proc dev_from_name
        setup_frame
        rep     #$30

        ; Push name to compare
        lda     z:3 ; name
        pha
        
        ; Load devices pointer to X
        ldx     devices_list
        
loop:
        ; CHeck if NULL
        cpx     #0
        beq     done
        
        lda     a:Device::name
        pha
        jsr     strcmp
        rep     #$30
        ply
        
        ; Check if strcmp returned 0, and don't loop if it did
        cmp     #0
        bne     loop

done:
        txa
        restore_frame
        rts
.endproc

; struct DirEnt *fs_dev_readdir(struct FSNode *node, unsigned int index)
.export fs_dev_readdir
.proc fs_dev_readdir
        setup_frame
        rep     #$30

        ; Check that node is dev_root_dir
        lda     z:3
        cmp     #dev_root_dir
        jne     failed

        ; Load device list first item
        ldx     devices_list

        ; Exit if no devices exist yet
        bze     failed

        ; Load index into A
        lda     z:5

        ; Go through list until A is 0
        bze done_loop
loop:
        ldy     a:Device::next,x
        bze     failed  ; Exit if reached end of list
        tyx
        dec
        bnz     loop

done_loop:

        ; Store Device struct address to stack
        phx

        pea     .sizeof(DirEnt)
        jsr     malloc
        rep     #$30
        ply

        ; Check that malloc succeeded
        cmp     #0
        jeq     failed

        ; Push new DirEnt struct address
        pha

        ; Push driver name string address
        lda     3,s ; Device struct address
        tax
        lda     a:Device::name,x
        pha

        ; Push destination string
        lda     3,s ; New DirEnt struct
        add     #DirEnt::name
        pha

        jsr     strcpy
        rep     #$30
        ply
        ply

        ; Write inode
        lda     1,s
        tax
        lda     z:5
        inc
        sta     a:DirEnt::inode,x

        txa

done:
        restore_frame
        rts

failed:
        lda     #0
        bra     done
.endproc

; struct FSNode *fs_dev_finddir(struct FSNode *node, char *name)
.export fs_dev_finddir
.proc fs_dev_finddir
        setup_frame
        rep     #$30



        restore_frame
        rts
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
.export register_driver
.proc register_driver
        setup_frame
        rep     #$30

        ; Allocate driver struct and put address in X
        pea     .sizeof(Device)
        jsr     malloc
        rep     #$30
        ply
        bze     failed_driver_alloc
        tax

        ; Store driver to struct
        lda     z:3
        sta     a:Device::driver,x

        ; Store name string to struct
        lda     z:5
        sta     a:Device::name,x

        ; Store type to struct
        lda     z:7
        sta     a:Device::type,x

        ; Reset next device
        stz     a:Device::next,x

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

failed_driver_alloc:

done:
        restore_frame
        rts
.endproc
