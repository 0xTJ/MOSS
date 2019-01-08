O_EXEC      = $04
O_RDONLY    = $01
O_RDWR      = $03
O_SEARCH    = $05
O_WRONLY    = $02

; int open(const char *path, int oflag, ... )
.global open
