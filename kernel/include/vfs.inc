; enum vtype
VTYPE_FILE         = $01
VTYPE_DIRECTORY    = $02
VTYPE_CHARDEVICE   = $03
VTYPE_BLOCKDEVICE  = $04
VTYPE_PIPE         = $05
VTYPE_SYMLINK      = $06
VTYPE_MOUNTPOINT   = $08

.struct vnode
        type        .word
        vops        .addr
        usecount    .word
        impl        .addr
        ptr         .addr
.endstruct

.struct vops
        read    .addr
        write   .addr
        open    .addr
        close   .addr
        readdir .addr
        finddir .addr
.endstruct

; .struct DirEnt
        ; name    .byte   16
        ; inode   .word
; .endstruct

; struct vnode root_vnode
.global root_vnode

; int newvnode(enum vtype type, struct vops *vops, struct vnode **new_vnode)
.global newvnode
; void vref(struct vnode *vp)
.global vref
; void vrele(struct vnode *vp)
.global vrele
