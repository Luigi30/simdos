memset:
    ;a1 = destination pointer
    ;d1 = byte to fill memory with
    ;d2 = number of bytes to set
    PushAll
    
    subi    #1, d2 ;dbra needs 1 less    
.memset_inner:
    move.b  d1, (a1)+
    dbra    d2, .memset_inner
    
    PopAll  
    RTS
    
strlen:
    ;Takes a null-terminated string.
    ;a0.l = string to test
    ;d0.b = string length, max 255
    PUSH    a0-a7
    PUSH    d1-d7
    
    move.l  #$0000FFFF, d0
    move.l  #$000000FE, d1
    
.loop:
    addq.w  #1, d0
    cmp.b   #$00, (a0)+
    beq     .done
    dbra    d1, .loop    
    
.done:
    POP     d1-d7
    POP     a0-a7
    RTS
    
StringsAreEqual:
    ;Compare d0.b bytes of the strings at a0.L and a1.L.
    ;If equal, d0 will be set to 0. If not, d0.B will be set to 1.
    PUSH    a0
    PUSH    a1
    PUSH    d6
    PUSH    d7
    
    subi.b  #1, d0
    
.comparison_loop:
    ;cmp.b  (a0)+,(a1)+
    move.b  (a0)+, d6
    move.b  (a1)+, d7
    cmp.b   d6, d7
    bne     .notequal
    dbra    d0, .comparison_loop
    jmp     .equal
    
.notequal:
    move.b  #1, d0
    jmp     .gohome
    
.equal:
    move.b  #0, d0
    jmp     .gohome
    
.gohome:    
    POP     d7
    POP     d6
    POP     a1
    POP     a0
    RTS

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
