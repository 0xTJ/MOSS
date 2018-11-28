.p816

.macpack generic
.macpack longbranch

.autoimport

.include "functions.inc"

.struct HeapTag
        size    .word
        used    .byte
        next    .addr
.endstruct

.segment "HEAP"
        .res    $1000

.code


.constructor heap_init
.proc heap_init
        rep     #$30
        pea     __HEAP_LOAD__
        plx
        pea     __HEAP_SIZE__ - .sizeof(HeapTag)
        pla
        sta     HeapTag::size,x
        lda     #0
        sta     HeapTag::next,x
        sep     #$20
        sta     HeapTag::used,x
        rep     #$20
        rts
.endproc


; void * near malloc(size_t size) near
.export malloc
.proc malloc
        setup_frame

        rep     #$30
        lda     z:1
        pea     __HEAP_LOAD__
        plx
        jmp     skip_next_inc

next:
        ldy     HeapTag::next,x
        cpy     #0
        beq     not_found
        tyx
skip_next_inc:
        ldy     HeapTag::used,x
        bnz     next
        cmp     HeapTag::size,x
        bgt     next
        
        ; Prevent fragmentation
        add     #.sizeof(HeapTag) + 8
        cmp     HeapTag::size,x
        bgt     skip_resize
        
        ; Resize fragment
        pha
        txa
        add     #.sizeof(HeapTag)
        add     1,s
        tay
        ; Y contains address of heap tag for new fragment
        
        ; Update sizes
        lda     HeapTag::size,x ; Size of the fragment to be split
        sub     #.sizeof(HeapTag)
        sub     1,s
        sta     HeapTag::size,y ; Size of new fragment
        pla
        sta     HeapTag::size,x
        
        ; Update next pointers
        lda     HeapTag::next,x
        sta     HeapTag::next,y
        sty     HeapTag::next,x
        
        ; Update new used status
        lda     #0
        sta     HeapTag::used,y
        
skip_resize:
        sep     #$20
        lda     #1
        sta     HeapTag::used,x
        rep     #$20
        txa
        add     #.sizeof(HeapTag)
        
not_found:   ; A should already contain NULL if it was not found
        restore_frame
        rts
.endproc


; void free(void * far ptr) far
.export free
.proc free
        setup_frame

        lda     z:1
        sub     #.sizeof(HeapTag)
        tax
        stz     HeapTag::used,x
        
        restore_frame
        rts
.endproc
