.charmap    $41, $41
.charmap    $42, $42
.charmap    $43, $43
.charmap    $44, $44
.charmap    $45, $45
.charmap    $46, $46
.charmap    $47, $47
.charmap    $48, $48
.charmap    $49, $49
.charmap    $4A, $4A
.charmap    $4B, $4B
.charmap    $4C, $4C
.charmap    $4D, $4D
.charmap    $4E, $4E
.charmap    $4F, $4F
.charmap    $50, $50
.charmap    $51, $51
.charmap    $52, $52
.charmap    $53, $53
.charmap    $54, $54
.charmap    $55, $55
.charmap    $56, $56
.charmap    $57, $57
.charmap    $58, $58
.charmap    $59, $59
.charmap    $5A, $5A
.charmap    $61, $61
.charmap    $62, $62
.charmap    $63, $63
.charmap    $64, $64
.charmap    $65, $65
.charmap    $66, $66
.charmap    $67, $67
.charmap    $68, $68
.charmap    $69, $69
.charmap    $6A, $6A
.charmap    $6B, $6B
.charmap    $6C, $6C
.charmap    $6D, $6D
.charmap    $6E, $6E
.charmap    $6F, $6F
.charmap    $70, $70
.charmap    $71, $71
.charmap    $72, $72
.charmap    $73, $73
.charmap    $74, $74
.charmap    $75, $75
.charmap    $76, $76
.charmap    $77, $77
.charmap    $78, $78
.charmap    $79, $79
.charmap    $7A, $7A

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
