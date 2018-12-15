PROC_MAX_FILES = 4

.struct Process
        reg_c   .word
        reg_db  .byte
        reg_d   .word
        reg_sp  .word
        reg_x   .word
        reg_y   .word
        bit_e   .byte
        
        pid     .word
        running .word
        next    .addr
        
        skp_sav .word
        
        files_p .addr 4
.endstruct
