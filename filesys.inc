FS_FILE        = $01
FS_DIRECTORY   = $02
FS_CHARDEVICE  = $03
FS_BLOCKDEVICE = $04
FS_PIPE        = $05
FS_SYMLINK     = $06
FS_MOUNTPOINT  = $08

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
        ptr     .addr
.endstruct

.struct DirEnt
        name    .byte   16
        inode   .word
.endstruct

; unsigned int read_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
; unsigned int write_fs(struct FSNode *node, unsigned int offset, unsigned int size, uint8_t *buffer)
; void open_fs(struct FSNode *node, uint8_t read, uint8_t write)
; void close_fs(struct FSNode *node)
; struct DirEnt *readdir_fs(struct FSNode *node, unsigned int index)
; struct FSNode *finddir_fs(struct FSNode *node, char *name)
