.struct CharDriver
        read    .addr   ; ssize_t (*read)(struct CharDriver *device, void *buf, size_t nbytes, off_t offset)
        write   .addr   ; ssize_t (*write)(struct CharDriver *device, const void *buf, size_t nbytes, off_t offset)
.endstruct

; enum devtype
DEV_TYPE_CHAR = 1

; void register_char_driver(struct CharDriver *driver, const char *name, enum devtype type)
.global register_char_driver
