.p816
.smart

.macpack generic

.include "stdlib.inc"
.include "functions.inc"
.include "builtin.inc"

.code

; div_t div(int dividend, int divisor)
div             := __divide_s16_s16
