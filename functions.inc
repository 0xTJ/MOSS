.macro safe_brk
        ; Fix ROM functions not allowing D != 0
        php
        phd
        pea     $0000
        pld

        brk
        nop

        ; Restore D
        pld
        plp
.endmacro

.macro setup_frame
        rep     #$30
        ; Store D on stack and set new stack frame
        tsc
        phd
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
        sub     #2
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
        
        ; Check if flag not to save latest state is set
        lda     a:Process::skp_sav,x
        bnz     @dont_save_registers

        ; Store Data Bank as 8-bit
        sep     #$20
        pla
        sta     a:Process::reg_db,x

        ; Store Accumulator as 16-bit
        rep     #$20
        pla
        sta     a:Process::reg_c,x

        ; Store X and Y, all as 16-bit
        pla
        sta     a:Process::reg_x,x
        tya
        sta     a:Process::reg_y,x

        ; Store P where E matters as 8-bit
        sep     #$20
        pla
        sta     a:Process::bit_e,x

        ; Store Direct Register as 16-bit
        rep     #$20
        tdc
        sta     a:Process::reg_d,x

        ; Store Stack Pointer as 16-bit
        tsc
        sta     a:Process::reg_sp,x
        
        bra     @done
        
@dont_save_registers:
        ; Disable skip saving
        stz     a:Process::skp_sav,x

        ; Load PID 0's stack pointer, because it's guaranteed to always have space
        ldx     proc_table + 0
        lda     a:Process::reg_sp,x
        tcs
        
@done:
.endmacro

.macro exit_isr
        ; Put the address of the Process struct in X
        ldx     current_process_p

        ; Load Stack Pointer as 16-bit
        rep     #$20
        lda     a:Process::reg_sp,x
        tcs

        ; Load Direct Register as 16-bit
        lda     a:Process::reg_d,x
        tcd

        ; Load P where E matters as 8-bit
        sep     #$20
        lda     a:Process::bit_e,x
        pha

        ; Load X and Y, all as 16-bit
        rep     #$20
        ldy     a:Process::reg_y,x
        lda     a:Process::reg_x,x
        pha

        ; Load Accumulator as 16-bit
        lda     a:Process::reg_c,x
        pha

        ; Load Data Bank as 8-bit
        sep     #$20
        lda     a:Process::reg_db,x
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
.endmacro
