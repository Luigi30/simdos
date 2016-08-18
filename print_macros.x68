PrintString MACRO   
    move.l  a1, -(SP)
    move.l  d0, -(SP)
    lea     \1, a1
    move.b  #14, d0
    trap    #15
    move.l  (SP)+, d0
    move.l  (SP)+, a1
    ENDM
    
PrintStringNL MACRO 
    move.l  a1, -(SP)
    move.l  d0, -(SP)  
    lea     \1, a1
    move.b  #13, d0
    trap    #15
    move.l  (SP)+, d0
    move.l  (SP)+, a1
    ENDM
    
PrintCRLF   MACRO
    movem.l d0-d1, -(SP)
    move.b  #6, d0
    move.b  #$0D, d1
    trap    #15
    move.b  #6, d0
    move.b  #$0A, d1
    trap    #15
    movem.l (SP)+, d0-d1
    ENDM
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
