FOPEN_MAX = 4

EOF = $FFFF

.struct FILE
        fd      .word
.endstruct

; FILE stdin
.global stdin
; FILE stdout
.global stdout
; FILE stderr
.global stderr

; int fgetc(FILE *stream)
.global fgetc
; char *fgets(char *str, int num, FILE * stream)
.global fgets
; int fputc(int c, FILE *stream)
.global fputc
; int fputs(const char *str, FILE * stream)
.global fputs
; int getc (FILE *stream);
.global getc
; int getchar(void)
.global getchar
; char *gets (char *str);
.global gets
; int putchar(int c)
.global putchar
; int puts(const char *str)
.global puts
; int putc(int c, FILE *stream)
.global putc
