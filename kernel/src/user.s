.p816

.segment "USER"
.org    $8000
.export user
user:
.incbin "../user/user.bin"
