.macro enter_isr
        rep     #$30
        pha
        phx
        phy
        phd
        phb
.endmacro

.macro leave_isr
        rep     #$30
        plb
        pld
        ply
        plx
        pla
.endmacro

        ; + - - - - - - - - - - +
        ; : K Register (Native) : \
        ; +---------------------+  |
        ; |                     |  |
        ; + Program Counter     +  |- Pushed by interrupt
        ; |                     |  |
        ; +---------------------+  |
        ; | P Status Register   | /
        ; +---------------------+
        ; |                     |
        ; | C Register          |
        ; |                     |
        ; +---------------------+
        ; |                     |
        ; | X Register          |
        ; |                     |
        ; +---------------------+
        ; |                     |
        ; | Y Register          |
        ; |                     |
        ; +---------------------+
        ; |                     |
        ; | Direct Page         |
        ; |                     |
        ; +---------------------+
        ; | Data Bank           |
        ; +---------------------+

.struct ISRFrame
        dat_bnk .byte
        dir_pag .word
        y_reg   .word
        x_reg   .word
        c_reg   .word
        p_reg   .byte
        prg_cnt .word
        prg_bnk .byte
.endstruct
