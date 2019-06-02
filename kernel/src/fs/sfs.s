.p816
.smart

.macpack generic

.include "functions.inc"
.include "fs.inc"

.bss

; struct fs sfs_fs
sfs_fs:
        .tag   fs


.rodata

sfs_name:
        .asciiz "sfs"

.code

; void sfs_init(void)
.constructor sfs_init
.proc sfs_init
        enter

        ldx     #sfs_fs
        lda     #sfs_attach
        sta     a:fs::attach,x
        lda     #sfs_name
        sta     a:fs::name,x
        
        phx
        jsr     register_fs
        rep     #$30
        ply

        leave
        rts
.endproc

; vnode *sfs_attach(vnode *source, const void *data)
.proc sfs_attach
        enter

        leave
        rts
.endproc
