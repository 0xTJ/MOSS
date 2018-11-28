.struct Process
        reg_c   .word
        reg_db  .byte
        reg_d   .word
        reg_sp  .word
        reg_x   .word
        reg_y   .word
        bit_e   .byte
                .res    16
        pid     .byte
        running .byte
        next    .addr
.endstruct
.if (.sizeof(Process) <> 32)
.error  "Bad Process struct size"
.endif
