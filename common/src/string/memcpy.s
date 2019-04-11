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

        ; Set arguments of MVN to the current bank
        sep     #$20
        phb
        pla
        sta     a:mvn_instr + 1
        sta     a:mvn_instr + 2
        rep     #$20

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
        ; Src and dst banks are DBR
mvn_instr:
        mvn     0, 0

done:
        leave
        rts
.endproc
