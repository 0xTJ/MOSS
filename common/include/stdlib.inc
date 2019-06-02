.struct div_t
        quot    .word
        rem     .word
.endstruct

.struct udiv_t
        quot    .word
        rem     .word
.endstruct

EXIT_FAILURE    := 1
EXIT_SUCCESS    := 0
NULL            := 0

; int abs(int n)
.global abs
; div_t div(int dividend, int divisor)
.global div
; long int abs(long int n)
.global labs
; ldiv_t ldiv(long int dividend, long int divisor)
.global ldiv
; char *itoa (int value, char *str, int base)
.global itoa
; void *malloc(size_t size)
.global malloc
; void *calloc (size_t num, size_t size)
.global calloc
; void free(void *ptr)
.global free
; void exit(int status)
.global exit
; void _Exit(int status)
.global _Exit
