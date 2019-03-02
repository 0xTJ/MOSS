.struct DirEnt
        name    .byte   16
        inode   .word
.endstruct

; int readdir(unsigned int fd, unsigned int count, struct DirEnt *result)
.global readdir
