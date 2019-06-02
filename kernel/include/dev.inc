.struct DeviceDriver
        read    .addr   ; size_t (*read)(struct DeviceDriver *device, void *buf, size_t nbytes, off_t offset)
        write   .addr   ; ssize_t (*write)(struct DeviceDriver *device, const void *buf, size_t nbytes, off_t offset)
.endstruct
