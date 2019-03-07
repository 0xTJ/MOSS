.p816
.smart

.macpack generic
.macpack longbranch

.include "o65.inc"
.include "functions.inc"
.include "stdio.inc"
.include "stdlib.inc"
.include "string.inc"

.bss

tmp_str:
        .res    64

.rodata

magic_str:
        .asciiz "Magic: "
mode_str:
        .asciiz "Mode:  "
tbase_str:
        .asciiz "TBase: "
tlen_str:
        .asciiz "TLen:  "
dbase_str:
        .asciiz "DBase: "
dlen_str:
        .asciiz "DLen:  "
bbase_str:
        .asciiz "BBase: "
blen_str:
        .asciiz "BLen:  "
zbase_str:
        .asciiz "ZBase: "
zlen_str:
        .asciiz "ZLen:  "
stack_str:
        .asciiz "Stack: "
filename_str:
        .asciiz "Filename: "
os_header_str:
        .asciiz "OS Header: "
asm_program_str:
        .asciiz "Assembler Program: "
author_str:
        .asciiz "Author: "
creation_data_str:
        .asciiz "Creation Data: "
unknown_otype_str:
        .asciiz "Unrecognized Header Option Type"

.code

; void o65_load(const uint8_t *o65, uint8_t *tbase, uint8_t *dbase, uint8_t *bbase, uint8_t *zbase)
.proc o65_load
        setup_frame
        rep     #$30

        ; Stack variables:
        ;  1: uint8_t *segments_p
        ;  3: uint8_t *reloc_tab_p
        ;  5: size_t reloc_location
        ;  7: uint8_t *tbase_diff
        ;  9: uint8_t *dbase_diff
        ; 11: uint8_t *bbase_diff
        ; 13: uint8_t *zbase_diff

        ; Allocate stack space for variables
        tsc
        sub     #20
        tcs

        ; Get o65 segments location and store to stack variables
        lda     z:3 ; o65
        pha
        jsr     o65_segments_p
        rep     #$30
        ply
        sta     1,s ; segments_p

        ; Copy from o65's text to load text
        ldx     z:3 ; o65
        ; Load o65 text pointer to A
        lda     1,s ; segments_p
        ; Push tlen
        ldy     a:O65Header::tlen,x
        phy
        ; Push o65 text pointer
        pha
        ; Push load text pointer
        lda     z:5 ; tbase
        pha
        ; Call memcpy
        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        ; Copy from o65's data to load data
        ldx     z:3 ; o65
        ; Load o65 data pointer to A
        lda     1,s ; segments_p
        add     a:O65Header::tlen,x
        ; Push dlen
        ldy     a:O65Header::dlen,x
        phy
        ; Push o65 data pointer
        pha
        ; Push load data pointer
        lda     z:7 ; dbase
        pha
        ; Call memcpy
        jsr     memcpy
        rep     #$30
        ply
        ply
        ply

        ; Zero-out load bss
        ldx     z:3 ; o65
        ; Push blen
        lda     a:O65Header::blen,x
        pha
        ; Push (int) 0
        pea     0
        ; Push load bbase
        lda     z:9 ; dbase
        pha
        jsr     memset
        rep     #$30
        ply
        ply
        ply

        ; Get o65 relocation table location and store to stack variables
        lda     z:3 ; o65
        pha
        jsr     o65_reloc_tab_p
        rep     #$30
        ply
        sta     3,s ; reloc_tab_p

        ; Setup delta bases
        ldx     z:3     ; o65
        lda     z:5     ; tbase
        sub     a:O65Header::tbase,x
        sta     7,s     ; tbase_diff
        lda     z:7     ; dbase
        sub     a:O65Header::dbase,x
        sta     9,s     ; dbase_diff
        lda     z:9     ; bbase
        sub     a:O65Header::bbase,x
        sta     11,s    ; bbase_diff
        lda     z:11    ; zbase
        sub     a:O65Header::zbase,x
        sta     13,s    ; zbase_diff

        ; Load real tbase - 1 to reloc_location
        lda     #$FFFF
        add     z:5 ; tbase
        sta     5,s ; reloc_location

reloc_text_loop:
        ldy     #0

offset_text_loop:
        lda     (3,s),y ; *reloc_tab_p
        and     #$00FF

        ; Exit inner loop if value is not 255
        cmp     #255
        bne     done_offset_text_loop

        ; Add 254 to reloc_location
        lda     #254
        add     5,s ; reloc_location
        sta     5,s ; reloc_location

        ; Increment reloc_tab_p
        lda     3,s ; reloc_tab_p
        inc
        sta     3,s ; reloc_tab_p

        bra     offset_text_loop

done_offset_text_loop:

        ; Check if offset is 0
        cmp     #0
        beq     done_reloc_text_loop

        ; Add value to reloc_location
        add     5,s ; reloc_location
        sta     5,s ; reloc_location

        ; Increment reloc_tab_p
        lda     3,s ; reloc_tab_p
        inc
        sta     3,s ; reloc_tab_p

        ; Get segment ID to A
        lda     (3,s),y ; *reloc_tab_p
        and     #$1F

        ; Jump to correct segment loader
        ; cmp     #$00
        ; beq     text_seg_undefined
        ; cmp     #$01
        ; beq     text_seg_absolute
        cmp     #$02
        beq     text_seg_text
        cmp     #$03
        beq     text_seg_data
        cmp     #$04
        beq     text_seg_bss
        cmp     #$05
        beq     text_seg_zero
        ; bra     seg_bad

        ; Load base diff to X
text_seg_text:
        lda     7,s     ; tbase_diff
        tax
        bra     text_sel_type
text_seg_data:
        lda     9,s     ; dbase_diff
        tax
        bra     text_sel_type
text_seg_bss:
        lda     11,s    ; bbase_diff
        tax
        bra     text_sel_type
text_seg_zero:
        lda     13,s    ; zbase_diff
        tax
        bra     text_sel_type

text_sel_type:
        ; Load relocator to A
        lda     (3,s),y ; *reloc_tab_p
        and     #$E0

        ; Jump to correct relocator
        cmp     #$80
        beq     text_type_word
        ; cmp     #$40
        ; beq     text_type_high
        ; cmp     #$20
        ; beq     text_type_low
        ; cmp     #$c0
        ; beq     text_type_segadr
        ; cmp     #$a0
        ; beq     text_type_seg
        ; bra     text_type_bad

text_type_word:
        ; Load location of relocation to A
        lda     5,s ; table
        tay
        lda     a:0,y

        ; Add diff in X to A
        phx
        add     1,s
        plx

        ; Store new value to location of relocation
        sta     a:0,y

        ; Increment reloc_tab_p
        lda     3,s ; reloc_tab_p
        inc
        sta     3,s ; reloc_tab_p

        jmp     reloc_text_loop

done_reloc_text_loop:

        ; Load real dbase - 1 to reloc_location
        lda     #$FFFF
        add     z:7 ; dbase
        sta     5,s ; reloc_location

reloc_data_loop:
        ldy     #0

offset_data_loop:
        lda     (3,s),y ; *reloc_tab_p
        and     #$00FF

        ; Exit inner loop if value is not 255
        cmp     #255
        bne     done_offset_data_loop

        ; Add 254 to reloc_location
        lda     #254
        add     5,s ; reloc_location
        sta     5,s ; reloc_location

        ; Increment reloc_tab_p
        lda     3,s ; reloc_tab_p
        inc
        sta     3,s ; reloc_tab_p

        bra     offset_data_loop

done_offset_data_loop:

        ; Check if offset is 0
        cmp     #0
        beq     done_reloc_data_loop

        ; Add value to reloc_location
        add     5,s ; reloc_location
        sta     5,s ; reloc_location

        ; Increment reloc_tab_p
        lda     3,s ; reloc_tab_p
        inc
        sta     3,s ; reloc_tab_p

        ; Get segment ID to A
        lda     (3,s),y ; *reloc_tab_p
        and     #$1F

        ; Jump to correct segment loader
        ; cmp     #$00
        ; beq     data_seg_undefined
        ; cmp     #$01
        ; beq     data_seg_absolute
        cmp     #$02
        beq     data_seg_text
        cmp     #$03
        beq     data_seg_data
        cmp     #$04
        beq     data_seg_bss
        cmp     #$05
        beq     data_seg_zero
        ; bra     seg_bad

        ; Load base diff to X
data_seg_text:
        lda     7,s     ; tbase_diff
        tax
        bra     data_sel_type
data_seg_data:
        lda     9,s     ; dbase_diff
        tax
        bra     data_sel_type
data_seg_bss:
        lda     11,s    ; bbase_diff
        tax
        bra     data_sel_type
data_seg_zero:
        lda     13,s    ; zbase_diff
        tax
        bra     data_sel_type

data_sel_type:
        ; Load relocator to A
        lda     (3,s),y ; *reloc_tab_p
        and     #$E0

        ; Jump to correct relocator
        cmp     #$80
        beq     data_type_word
        ; cmp     #$40
        ; beq     data_type_high
        ; cmp     #$20
        ; beq     data_type_low
        ; cmp     #$c0
        ; beq     data_type_segadr
        ; cmp     #$a0
        ; beq     data_type_seg
        ; bra     data_type_bad

data_type_word:
        ; Load location of relocation to A
        lda     5,s ; table
        tay
        lda     a:0,y

        ; Add diff in X to A
        phx
        add     1,s
        plx

        ; Store new value to location of relocation
        sta     a:0,y

        ; Increment reloc_tab_p
        lda     3,s ; reloc_tab_p
        inc
        sta     3,s ; reloc_tab_p

        jmp     reloc_data_loop

done_reloc_data_loop:

        restore_frame
        rts
.endproc

; void *o65_segments_p(void *o65)
.proc o65_segments_p
        setup_frame
        rep     #$30

        ; Skip header
        lda     z:3 ; o65
        add     #.sizeof(O65Header)
        sta     z:3 ; o65

loop:
        ; Load length bit to A in 16-bit mode.
        ldx     z:3 ; o65
        lda     a:O65HeaderOption::olen,x
        and     #$00FF

        ; Add current header option pointer to this length to get next option.
        add     z:3 ; o65

        ; Check if the pointer didn't change, so olen was 0
        ; If olen was 0, exit loop
        cmp     z:3
        beq     done_loop

        ; Update argument
        sta     z:3

        bra     loop

done_loop:
        ; Return the pointer past the last header option checked
        inc

        restore_frame
        rts
.endproc

; uint8_t *o65_reloc_tab_p(uint8_t *o65)
.proc o65_reloc_tab_p
        setup_frame
        rep     #$30

        ; Skip to beginning of segments
        lda     z:3 ; o65
        pha
        jsr     o65_segments_p
        rep     #$30
        ply

        ; Put pointer to byte past segments into o65
        ldx     z:3 ; o65
        add     a:O65Header::tlen,x
        add     a:O65Header::dlen,x
        sta     z:3 ; o65

        ; Load number of labels to Y
        tax
        ldy     a:O65UndefList::n_undef_labels,x

        ; Skip number of undefined labels, and store to o65
        inx
        inx
        stx     z:3 ; o65

loop:
        ; Done if 0 labels left
        cpy     #0
        beq     done_loop

        ; Push labels left to stack
        phy

        ; Get length of label to A, and increment
        lda     z:3 ; o65
        ; add     #O65UndefList::undef_labels
        pha
        jsr     strlen
        rep     #$30
        ply
        inc

        ; Add offset to next label to the current label, and store back to o65
        add     z:3 ; o65
        sta     z:3 ; o65

        ; Pull labels left, and decrement
        ply
        dey

        bra     loop

done_loop:
        lda     z:3 ; o65

        restore_frame
        rts
.endproc

; uint8_t *print_o65_header_option(uint8_t *header_opt)
.proc print_o65_header_option
        setup_frame
        rep     #$30

        ; Load option length to A, and return NULL if it is 0
        ldx     z:3 ; header_opt
        sep     #$20
        lda     a:O65HeaderOption::olen,x
        jeq     ret_null

        lda     a:O65HeaderOption::otype,x
        rep     #$30
        and     #$00FF
        bze     filename
        ; cmp     #1
        ; beq     os_header
        cmp     #2
        beq     asm_program
        cmp     #3
        beq     author
        cmp     #4
        beq     creation_data

        ; If we get here, header option type isn't recognized
        pea     unknown_otype_str
        jsr     puts
        rep     #$30
        ply
        bra     get_next_option

filename:
        pea     stdout
        pea     filename_str
        jsr     fputs
        rep     #$30
        ply
        ply

        bra     options_bytes_str

asm_program:
        pea     stdout
        pea     asm_program_str
        jsr     fputs
        rep     #$30
        ply
        ply

        bra     options_bytes_str

author:
        pea     stdout
        pea     author_str
        jsr     fputs
        rep     #$30
        ply
        ply

        bra     options_bytes_str

creation_data:
        pea     stdout
        pea     author_str
        jsr     fputs
        rep     #$30
        ply
        ply

        bra     options_bytes_str

options_bytes_str:
        lda     z:3 ; header_opt
        add     #O65HeaderOption::option_bytes
        pha
        jsr     puts
        rep     #$30
        ply

        bra     get_next_option

get_next_option:
        ldx     z:3 ; header_opt
        sep     #$20
        lda     a:O65HeaderOption::olen,x
        rep     #$20
        and     #$00FF
        add     z:3 ; header_opt

done:
        restore_frame
        rts

ret_null:
        rep     #$30
        lda     #0
        bra     done
.endproc

; uint8_t *print_o65_header_options(uint8_t *header_opts)
.proc print_o65_header_options
        setup_frame
        rep     #$30

        ; Load target pointer and push once
        lda     z:3 ; header_opts
        pha

        ; The latest known valid option pointer is kept on the stack
loop:
        ; Clear current latest good
        ply

        pha
        pha
        jsr     print_o65_header_option
        rep     #$30
        ply

        cmp     #0
        bne     loop

        ; Pull latest known good and increment
        pla
        inc

        restore_frame
        rts
.endproc

; uint8_t print_o65_header(uint8_t *header)
.proc print_o65_header
        setup_frame
        rep     #$30

        pea     stdout
        pea     magic_str
        jsr     fputs
        rep     #$30
        ply
        ply
        lda     z:3 ; header
        add     #O65Header::magic
        pha
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     mode_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::mode,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     tbase_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::tbase,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     tlen_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::tlen,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     dbase_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::dbase,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     dlen_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::dlen,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     bbase_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::bbase,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     blen_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::blen,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     zbase_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::zbase,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     zlen_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::zlen,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        pea     stdout
        pea     stack_str
        jsr     fputs
        rep     #$30
        ply
        ply
        pea     16
        pea     tmp_str
        ldx     z:3 ; header
        lda     a:O65Header::stack,x
        pha
        jsr     itoa
        rep     #$30
        ply
        ply
        ply
        pea     tmp_str
        jsr     puts
        rep     #$30
        ply

        ; Return address after header
        lda     z:3 ; header
        add     #.sizeof(O65Header)

        restore_frame
        rts
.endproc
