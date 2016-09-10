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

M_WriteString   MACRO
    lea     \1, a0
    move.w  #0, d7
    trap    #3
                ENDM
                
M_WriteStringNL MACRO
    lea     \1, a0
    move.w  #0, d7
    trap    #3
    lea     NEWLINE_CONST, a0
    trap    #3
                ENDM    
    
    SECTION DATA
NEWLINE_CONST dc.b 13,10
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
