.p816
.smart

.macpack generic

.autoimport

.include "functions.inc"
.include "dev.inc"

; void register_driver(struct Device *dev, char *name)
.proc register_driver
        setup_frame

        ; Get string length
        lda     z:5
        pha
        jsr     strlen
        ply
        
        inc
        pha
        jsr     malloc
        

        restore_frame
        rts
.endproc
