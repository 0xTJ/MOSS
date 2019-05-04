.p816
.smart

.macpack generic

.include "functions.inc"
.include "dev.inc"

.bss

null_driver:
        .tag    DeviceDriver

.rodata

null_name:
        .asciiz "null"

.code

.constructor dev_null_init
.proc dev_null_init
        rep     #$30

        ldx     #null_driver

        lda     #dev_null_write
        sta     a:DeviceDriver::write,x

        pea     null_name
        pea     null_driver
        jsr     register_device
        rep     #$30
        ply
        ply

        rts
.endproc

; ssize_t dev_null_write(const void *buf, size_t nbytes, off_t offset)
.proc dev_null_write
        enter
        rep     #$30

        ; Accept all bytes written
        lda     z:arg 2

        leave
        rts
.endproc
