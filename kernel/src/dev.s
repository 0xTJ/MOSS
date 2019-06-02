.p816
.smart

.macpack generic
.macpack longbranch

.include "functions.inc"
.include "dev.inc"

DEV_COUNT = 8

.bss

dev_tab:
        .res    2 * DEV_COUNT

.code

; int dev_register(struct DeviceDriver *driver, int major_num)
.proc dev_register
        enter

        lda     z:arg 0 ; driver
        asl
        tax

        ; If major_num isn't negative, don't find new number
        bpl     fixed_major

        ; Find an available slot
        ldx     #0
search_loop:
        cpx     #DEV_COUNT * 2
        bge     failed
        
        lda     dev_tab,x
        bze     found_slot
        
        inx
        inx
        bra     search_loop
found_slot:

fixed_major:
        ; Fail if major_num is greater than maximum
        cpx     #DEV_COUNT * 2
        bge     failed

        ; Fail if major number is already occupied
        lda     dev_tab,x
        bnz     failed

done:
        leave
        rts

failed:
        lda     #$FFFF
        bra     done
.endproc
