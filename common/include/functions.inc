.charmap    $30, $30
.charmap    $31, $31
.charmap    $32, $32
.charmap    $33, $33
.charmap    $34, $34
.charmap    $35, $35
.charmap    $36, $36
.charmap    $37, $37
.charmap    $38, $38
.charmap    $39, $39
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
.charmap    $5F, $5F
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

.define var(byte_offset) 1 + byte_offset
.define stored_direct    1 + stack_space
.define return_addr      1 + stack_space + 2
.define arg(byte_offset) 1 + stack_space + 2 + 2 + byte_offset

.macro enter stack_space_in
.ifblank stack_space_in
        stack_space .set 0
.else
        stack_space .set stack_space_in
.endif
        rep     #$30
        phd
        tsc
.if stack_space > 0
        sec
        sbc     #stack_space
.endif
        tcs
        tcd
.endmacro

.macro leave
.ifblank stack_space
        .error  "`leave` without `enter` in scope"
.endif
        rep     #$30
        tay
        tdc
.if stack_space > 0
        clc
        adc     #stack_space
.endif
        tcs
        pld
        tya
.endmacro

.macro hard_reset
        sei

        sep     #$20

        lda     #$01
        sta     $00DF56
        stz     $00DF67

        lda     #(1 << 4)
        tsb     $00DF40

        lda     #(1 << 0)
        trb     $00DF43
        tsb     $00DF43

        .local loop_waiting
loop_waiting:
        bra     loop_waiting
.endmacro
