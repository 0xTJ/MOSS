.p816
.smart

.macpack generic
.macpack longbranch

.autoimport

.include "functions.inc"

.struct HeapTag
        size    .word
        flags   .word
        next    .addr
.endstruct

.segment "HEAP"
        .res    $1000

.code


.constructor heap_init, 1
.proc heap_init
        rep     #$30 
        ldx     #__HEAP_LOAD__
        lda     #__HEAP_SIZE__ - .sizeof(HeapTag)
        sta     HeapTag::size,x
        stz     HeapTag::next,x
        stz     HeapTag::flags,x
        rts
.endproc


; void * near malloc(size_t size) near
.export malloc
.proc malloc
        setup_frame
        
        rep     #$30
        lda     z:3
        ldx     #__HEAP_LOAD__
        jmp     skip_next_inc

next:
        ldy     a:HeapTag::next,x
        cpy     #0
        jeq     not_found
        tyx
skip_next_inc:
        ldy     a:HeapTag::flags,x
        bnz     next
        cmp     a:HeapTag::size,x
        bgt     next
        
        ; Prevent fragmentation
        add     #.sizeof(HeapTag) + 8
        cmp     a:HeapTag::size,x
        bgt     skip_resize
        
        ; Resize fragment
        txa
        add     #.sizeof(HeapTag)
        add     z:3
        tay
        ; Y contains address of heap tag for new fragment
        
        ; Update sizes
        lda     a:HeapTag::size,x ; Size of the fragment to be split
        sub     #.sizeof(HeapTag)
        sub     z:3
        sta     a:HeapTag::size,y ; Size of new fragment
        lda     z:3
        sta     a:HeapTag::size,x
        
        ; Update next pointers
        lda     a:HeapTag::next,x
        sta     a:HeapTag::next,y
        tya
        sta     a:HeapTag::next,x
        
        ; Update new flags status
        lda     #0
        sta     a:HeapTag::flags,y
        
skip_resize:
        lda     #1
        sta     a:HeapTag::flags,x
        txa
        add     #.sizeof(HeapTag)
        
        ; So that the next part works
        tay
        
not_found:   ; Y will contain NULL if it was not found
        tya
        restore_frame
        rts
.endproc


; void free(void * far ptr) far
.export free
.proc free
        setup_frame

        lda     z:3
        sub     #.sizeof(HeapTag)
        tax
        stz     a:HeapTag::flags,x
        
        restore_frame
        rts
.endproc
