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
