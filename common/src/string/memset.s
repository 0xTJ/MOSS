.p816
.smart

.macpack generic

.include "string.inc"
.include "functions.inc"

.code

; void *memset(void *s, int c, size_t n)
.export memset
.proc memset
        enter
        rep     #$30

        ldx     z:arg 4 ; n
        bze     done

        lda     z:arg 2 ; c

        ; Manually store once, will be used as source for copy
        sep     #$20
        sta     (arg 0) ; *s
        dex     ; n - 1
        bze     done
        rep     #$30

        txa     ; n - 1
        dec     ; n - 2
        ldx     z:arg 0 ; s
        txy     ; s
        iny     ; s + 1

        ; Run mvn with:
        ; A: n - 2
        ; X: s (source of MVN)
        ; Y: s + 1 (destination of MVN)
        ; Src and dst banks 0
        mvn     0, 0

done:
        rep    #$30
        leave
        rts
.endproc
