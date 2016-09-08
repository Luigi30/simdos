Read16BitLittleEndian:
    ;Read a 16-bit little endian number at (a0). Result will be put in d1.w
    movem.l d2-d3, -(SP)
        
    move.b  (a0)+, d1
    ror.w   #8, d1
    move.b  (a0), d1
    rol.w   #8, d1
    
    movem.l (SP)+, d2-d3
    RTS
    
Read32BitLittleEndian:
    ;Read a 32-bit little endian number at (a0). Result will be put in d1.l
    movem.l d2-d3, -(SP)
        
    move.b  (a0)+, d1
    ror.w   #8, d1
    move.b  (a0)+, d1
    rol.w   #8, d1
    rol.l   #8, d1
    rol.l   #8, d1
    
    move.b  (a0)+, d1
    ror.w   #8, d1
    move.b  (a0), d1
    rol.w   #8, d1
    
    rol.l   #8, d1
    rol.l   #8, d1
    
    movem.l (SP)+, d2-d3
    RTS
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
