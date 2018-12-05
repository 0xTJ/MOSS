.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "dev.inc"

.struct Device
        type    .word
        driver  .addr
        name    .addr
        next    .addr
.endstruct

.bss

.export devices_list
devices_list:
        .addr   0

.code

; void register_driver(struct CharDriver *driver, const char *name, int type)
.export register_driver
.proc register_driver
        setup_frame
        rep     #$30

        ; Allocate driver struct and put address in X
        pea     .sizeof(Device)
        jsr     malloc
        rep     #$30
        ply
        bze     failed_driver_alloc
        tax

        ; Store driver to struct
        lda     z:3
        sta     a:Device::driver,x

        ; Store name string to struct
        lda     z:5
        sta     a:Device::name,x

        ; Store type to struct
        lda     z:7
        sta     a:Device::type,x

        ; Reset next device
        stz     a:Device::next,x

        ; Add to list
        txa                     ; Move struct address to A
        ldy     devices_list    ; Will jump if the list pointer is NULL
        bnz     find_loop
        sta     devices_list    ; Store directly to the list pointer if this is the first being added
        bra     done
find_loop:
        tyx
        ldy     a:Device::next,x
        bnz     find_loop
        sta     a:Device::next,x

failed_driver_alloc:

done:
        restore_frame
        rts
.endproc
