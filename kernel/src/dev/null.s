.p816
.smart

.macpack generic

.include "functions.inc"
.include "dev.inc"

.bss

null_driver:
        .tag    CharDriver

.rodata

null_name:
        .asciiz "null"

.code

.constructor dev_null_init
.proc dev_null_init
        rep     #$30

        ldx     #null_driver

        lda     #dev_null_write
        sta     a:CharDriver::write,x

        pea     DEV_TYPE_CHAR
        pea     null_name
        pea     null_driver
        jsr     register_driver
        rep     #$30
        ply
        ply
        ply

        rts
.endproc

; ssize_t dev_null_write(const void *buf, size_t nbytes, off_t offset)
.proc dev_null_write
        setup_frame
        rep     #$30

        ; Accept all bytes written
        lda     z:5

        restore_frame
        rts
.endproc
