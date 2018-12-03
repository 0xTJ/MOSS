.p816
.smart

.macpack generic

.autoimport

.code

.export zerobss
.proc zerobss
        rep     #$30
        lda     #__BSS_SIZE__
        bze     done_bss
        stz     __BSS_LOAD__
        dec
        bze     done_bss
        dec
        ldx     #.loword(__BSS_LOAD__)
        txy
        iny
        mvn     .bankbyte(__BSS_LOAD__), .bankbyte(__BSS_LOAD__)
done_bss:
        rts
.endproc


.export copydata
.proc copydata
        rep     #$30
        lda     #__DATA_SIZE__
        bze     done_data
        dea
        ldx     #.loword(__DATA_LOAD__)
        ldy     #.loword(__DATA_RUN__)
        mvn     .bankbyte(__DATA_RUN__), .bankbyte(__DATA_LOAD__)
done_data:
        rts
.endproc


.export initlib
.proc initlib
        rep     #$30
        lda     #__CONSTRUCTOR_COUNT__
        bze     done_constructors
        lda     #0
loop_constructors:
        pha
        
        asl
        tax
        
        jsr     (__CONSTRUCTOR_TABLE__,x)
        rep     #$30
        pla
        ina
        cpa     #__CONSTRUCTOR_COUNT__
        bne     loop_constructors
done_constructors:
        rts
.endproc


.export donelib
.proc donelib
        rep     #$30
        lda     #__DESTRUCTOR_COUNT__
        bze     done_destructors
        lda     #0
loop_destructors:
        pha
        
        asl
        tax
        
        jsr     (__DESTRUCTOR_TABLE__,x)
        rep     #$30
        pla
        inx
        cpx     #__DESTRUCTOR_COUNT__
        bne     loop_destructors
done_destructors:
        rts
.endproc
