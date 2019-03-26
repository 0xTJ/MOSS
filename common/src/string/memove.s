.p816
.smart

.macpack generic

.include "string.inc"
.include "functions.inc"

.code

; void *memmove(void *dest, const void *src, size_t n)
.export memmove
.proc memmove
        enter
        rep     #$30

        ; Done if n == 0
        lda     z:arg 4 ; n
        bze     done

        ; Load compare dest to src
        lda     z:arg 0 ; dest
        cpa     z:arg 2 ; src

        ; If equal, we're done
        beq     done

        ; If destination is greater than source
        bgt    copy_pos

        ; If destination if less than source
        blt     copy_neg

copy_pos:
        ; Load src + n - 1 to X
        lda     z:arg 2 ; src
        add     z:arg 4 ; n
        dec
        tax

        ; Load dest + n - 1 to Y
        lda     z:arg 0 ; dest
        add     z:arg 4 ; n
        dec
        tay

        ; Load n - 1 to A
        lda     z:arg 4 ; n
        dec

        ; Run mvn with:
        ; A: n - 1
        ; X: src + n - 1
        ; Y: dest + n - 1
        ; Src and dst banks 0
        mvp     0, 0
        bra     done

copy_neg:
        ; Load source to X
        ldx     z:arg 2 ; src

        ; Load destination to Y
        ldy     z:arg 0 ; dest

        ; Load n - 1 to A
        ldx     z:arg 4 ; n
        dec

        ; Run mvn with:
        ; A: n - 1
        ; X: src
        ; Y: dest
        ; Src and dst banks 0
        mvn     0, 0
        bra     done

done:
        leave
        rts
.endproc
