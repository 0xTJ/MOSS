.macro enter_isr
        rep     #$30
        pha
        phx
        phy
        phd
        phb
.endmacro

.macro exit_isr
        rep     #$30
        plb
        pld
        ply
        plx
        pla
.endmacro
