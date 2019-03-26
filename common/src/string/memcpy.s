.p816
.smart

.macpack generic

.include "string.inc"
.include "functions.inc"

.code

; void *memcpy(void *dest, const void *src, size_t n)
.export memcpy
.proc memcpy
        enter
        rep     #$30

        ; Put n - 1 into A, or done if n == 0
        lda     z:arg 4 ; n
        bze     done
        dec

        ; Load dest and src to Y and X
        ldy     z:arg 0 ; dest
        ldx     z:arg 2 ; src

        ; Run mvn with:
        ; A: n - 1
        ; X: src
        ; Y: dest
        ; Src and dst banks 0
        mvn     0, 0

done:
        leave
        rts
.endproc
