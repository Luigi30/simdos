Trap3Table:
Trap3Task0  dc.l    CON_write_string
Trap3Task1  dc.l    CON_read_char
Trap3Task2	dc.l	CON_write_char
    
Trap3Handler: ;#Trap #3 - Console I/O functions
    mulu.w  #4, d7 ;get the offset of the table entry
    lea     Trap3Table, a6
    add.l   d7, a6
    move.l  (a6), a6
    jsr     (a6)
    RTE

;***********************************
;*CON_write_string
;*
;* Description: Writes the string at a0 to the text console.
;* Inputs:
;*  - a0.l = Pointer to string
;* Outputs:
;*  - none
;***********************************
CON_write_string:
    PUSH    d0
    exg     a0,a1
    move.b  #14,d0
    trap    #15
    POP     d0
    RTS
    
;***********************************
;*CON_write_char
;*
;* Description: Writes the character in d0 to the text console.
;* Inputs:
;*  - d0.b - ASCII character
;* Outputs:
;*  - none
;***********************************
CON_write_char:
    PUSH    d0-d1
    exg     d0,d1
    move.b  #6,d0
    trap    #15
    POP     d0-d1
    RTS
    
;***********************************
;*CON_read_char
;*
;* Description: Reads an ASCII character from the text console.
;* Inputs:
;*  - none
;* Outputs:
;*  - d0.b = Character read from console
;***********************************
CON_read_char:
    PUSH    d1
    move.b  #5,d0
    trap    #15
    exg     d0,d1
    POP     d1
    RTS
