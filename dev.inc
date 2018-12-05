.struct CharDriver
        read    .addr   ; ssize_t (*read)(void *buf, size_t nbytes, off_t offset)
        write   .addr   ; ssize_t (*read)(const void *buf, size_t nbytes, off_t offset)
.endstruct

DEV_TYPE_CHAR = 1
