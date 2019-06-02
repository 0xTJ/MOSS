.struct fs
        attach  .addr   ; vnode *attach(vnode *source, const void *data)
        name    .addr   ; const char *name
        next    .addr   ; struct fs *next
.endstruct

; int register_fs(struct fs *fs_prop)
.global register_fs
