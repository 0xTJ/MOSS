.p816
.smart

.macpack generic

.include "functions.inc"
.include "unistd.inc"

.code

; ssize_t read(int fd, void *buf, size_t nbyte)
.proc read
        enter
        rep     #$30

        lda     z:arg 4 ; nbyte
        pha
        lda     z:arg 2 ; buf
        pha
        lda     z:arg 0 ; fd
        pha
        
        cop     $04

        leave
        rts
.endproc

; ssize_t write(int fd, const void *buf, size_t nbyte)
.proc write
        enter
        rep     #$30

        lda     z:arg 4 ; nbyte
        pha
        lda     z:arg 2 ; buf
        pha
        lda     z:arg 0 ; fd
        pha
        
        cop     $05

        leave
        rts
.endproc

; int close(int fd)
.proc close
        enter

        lda     z:arg 0 ; fd
        pha
        
        cop     $0A

        leave
        rts
.endproc

; void _exit(int status)
.proc _exit
        enter

        lda     z:arg 0 ; status
        pha
        
        cop     $0B

        leave
        rts
.endproc

; pid_t vfork(void)
.proc vfork
        ; No enter, we want to directly pass back changes to SP

        cop     $0D

        rts
.endproc

; int execve(const char *filename, char *const argv[], char *const envp[])
.proc execve
        enter

        lda     z:arg 0 ; filename
        pha
        lda     z:arg 2 ; argv
        pha
        lda     z:arg 4 ; envp
        pha
        
        cop     $0C

        leave
        rts
.endproc
