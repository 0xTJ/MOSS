.macro setup_frame
        rep     #$30
        ; Store D on stack and set new stack frame
        tsc
        phd
        inc
        tcd
.endmacro

.macro restore_frame preserve_a
        ; Setting preserve_a will obliterate Y instead of A
        ; Defaults to preserving A
        
        rep     #$30
        
.if .blank(preserve_a)
        tay
.elseif preserve_a
        tay
.endif

        tdc
        sub     3
        tcs
        pld

.if .blank(preserve_a)
        tya
.elseif preserve_a
        tya
.endif
.endmacro

.macro enter_isr
        ; Push P as 8-bit, but only the emulation bit matters,
        ; and set native mode
        clc
        xce
        php

        ; Push X and A as 16-bit each
        rep     #$30
        phx
        pha
        
        ; Push Data Bank as 8-bit
        phb

        ; + - - - - - - - - - - +
        ; : K Register (Native) : \
        ; +---------------------+  |
        ; |                     |  |
        ; + Program Counter     +  |- Pushed by interrupt
        ; |                     |  |
        ; +---------------------+  |
        ; | P Status Register   | /
        ; +---------------------+
        ; | P with E in C       |
        ; +---------------------+
        ; |                     |
        ; + X Register          +
        ; |                     |
        ; +---------------------+
        ; |                     |
        ; + C Register          +
        ; |                     |
        ; +---------------------+
        ; | DB Register         |
        ; +---------------------+

        ; Load Data Bank with $00
        lda     #$00
        tad

        ; Put the address of the Process struct in X
        ldx     current_process_p

        ; Store Data Bank as 8-bit
        sep     #$20
        pla
        sta     Process::reg_db,x

        ; Store Accumulator as 16-bit
        rep     #$20
        pla
        sta     Process::reg_c,x

        ; Store X and Y, all as 16-bit
        pla
        sta     Process::reg_x,x
        sty     Process::reg_y,x

        ; Store P where E matters as 8-bit
        sep     #$20
        pla
        sta     Process::bit_e,x

        ; Store Direct Register as 16-bit
        rep     #$20
        tdc
        sta     Process::reg_d,x

        ; Store Stack Pointer as 16-bit
        tsc
        sta     Process::reg_sp,x
.endmacro

.macro exit_isr
        ; Put the address of the Process struct in X
        ldx     current_process_p

        ; Load Stack Pointer as 16-bit
        rep     #$20
        lda     Process::reg_sp,x
        tcs

        ; Load Direct Register as 16-bit
        lda     Process::reg_d,x
        tcd

        ; Load P where E matters as 8-bit
        lda     Process::bit_e,x
        pha

        ; Store X and Y, all as 16-bit
        rep     #$20
        ldy     Process::reg_y,x
        lda     Process::reg_x,x
        pha

        ; Store Accumulator as 16-bit
        lda     Process::reg_c,x
        pha

        ; Store Data Bank as 8-bit
        sep     #$20
        lda     Process::reg_db,x
        pha

        ; + - - - - - - - - - - +
        ; : K Register (Native) : \
        ; +---------------------+  |
        ; |                     |  |
        ; + Program Counter     +  |- Pushed by interrupt
        ; |                     |  |
        ; +---------------------+  |
        ; | Status Register     | /
        ; +---------------------+
        ; | P with E in C       |
        ; +---------------------+
        ; |                     |
        ; + X Register          +
        ; |                     |
        ; +---------------------+
        ; |                     |
        ; + C Register          +
        ; |                     |
        ; +---------------------+
        ; | DB Register         |
        ; +---------------------+

        ; Pull Data Bank as 8-bit
        plb

        ; Pull A and X as 16-bit each
        rep     #$30
        pla
        plx

        ; Restore emulation mode
        plp
        xce
        ; Bit C in P will always be cleared, but will be restored by RTI

        rti
.endmacro
