AllRegisters REG    d0-d7/a0-a6
PushAll MACRO
    movem.l AllRegisters, -(SP)
    ENDM
    
PopAll MACRO
    movem.l (SP)+, AllRegisters
    ENDM

PUSH    MACRO
    movem.l  \1,-(SP)
    ENDM
    
POP     MACRO
    movem.l  (SP)+, \1
    ENDM

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
