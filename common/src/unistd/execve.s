.p816
.smart

.macpack generic

.include "functions.inc"
.include "unistd.inc"

.code

; int execve(const char *filename, char *const argv[], char *const envp[])
.proc execve
        enter

        lda     z:arg 4 ; envp
        pha
        lda     z:arg 2 ; argv
        pha
        lda     z:arg 0 ; filename
        pha
        
        cop     $0C

        leave
        rts
.endproc
