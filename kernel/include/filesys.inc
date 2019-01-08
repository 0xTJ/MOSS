FS_FILE         = $01
FS_DIRECTORY    = $02
FS_CHARDEVICE   = $03
FS_BLOCKDEVICE  = $04
FS_PIPE         = $05
FS_SYMLINK      = $06
FS_MOUNTPOINT   = $08
FS_TYPE_BITS    = $0F

.struct FSNode
        name    .byte   16
        flags   .word
        inode   .word
        read    .addr
        write   .addr
        open    .addr
        close   .addr
        readdir .addr
        finddir .addr
        impl    .word
        ptr     .addr
.endstruct

.struct DirEnt
        name    .byte   16
        inode   .word
.endstruct

.global root_dir

; struct FSNode *follow_mounts(struct FSNode *node)
.global follow_mounts
; struct FSNode *traverse_rel_path(struct FSNode *node, char *path)
.global traverse_rel_path
; struct FSNode *traverse_abs_path(char *path)
.global traverse_abs_path
; void mount_fs(struct FSNode *mount_point, struct FSNode *mounted)
.global mount_fs
; unsigned int read_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.global read_fs
; unsigned int write_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
.global write_fs
; void open_fs(struct FSNode *node, uint8_t read, uint8_t write)
.global open_fs
; void close_fs(struct FSNode *node)
.global close_fs
; struct DirEnt *readdir_fs(struct FSNode *node, unsigned int index)
.global readdir_fs
; struct FSNode *finddir_fs(struct FSNode *node, char *name)
.global finddir_fs
