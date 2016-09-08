;Memory allocation
;
; Memory map as of 9/8/16
;
; 0x000000 - 0x0FFFFF = reserved for operating system
; 0x100000 - 0x1FFFFF = free RAM
; 0x200000 - 0x3FFFFF = FAT12 ramdisk
; 0x400000 - 0xEFFFFF = free RAM

; block format:
;   0x00-0x01 = CHUNK_IS_FREE or CHUNK_IS_INUSE
;   0x02-0x09 = size in bytes
;   0x10... = data
;   Last 8 bytes before the end of the chunk = size in bytes

initialize_heap:
    move.l  HEAP_START, a0
    move.w  #CHUNK_IS_FREE,(a0)+
    
    ;Setup the initial chunk's size
    move.l  HEAP_END, a1
    sub.l   HEAP_START,a1
    sub.l   #9,a1 ;word + word + byte
    move.l  a1,(a0)
    add.l   a1,a0
    add     #4,a0
    move.l  a1,(a0)
    sub.l   a1,a0
    move.l  a1,d0
    
.sentinel:
    move.b  #$CC, (a0)+
    cmp.l   #0, d0
    sub.l   #1, d0
    bne     .sentinel
    
    rts

malloc:
    rts

free:
    rts
    
HEAP_START  dc.l    $100000
HEAP_END    dc.l    $1FFFFF

CHUNK_IS_FREE   equ $AAAA
CHUNK_IS_INUSE  equ $5555
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
