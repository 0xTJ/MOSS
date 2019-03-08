.struct O65Header
        nonc64  .byte   2

        magic   .byte   4

        mode    .word

        tbase   .addr
        tlen    .addr
        dbase   .addr
        dlen    .addr
        bbase   .addr
        blen    .addr
        zbase   .addr
        zlen    .addr
        stack   .addr
.endstruct

.struct empty
.endstruct

.struct O65HeaderOption
        olen            .byte
        otype           .byte
        option_bytes    .tag empty
.endstruct

; void o65_load(const uint8_t *o65, uint8_t *tbase, uint8_t *dbase, uint8_t *bbase, uint8_t *zbase)
.global o65_load
; uint8_t *o65_segments_p(uint8_t *o65)
.global o65_segments_p
; uint8_t *o65_reloc_tab_p(uint8_t *o65)
.global o65_reloc_tab_p
