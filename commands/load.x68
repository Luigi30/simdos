DoLoadCommand:
    lea     input_buffer+5, a0
    jsr     ConvertStringTo83
    jsr     GetStartingCluster ;puts starting cluster in d0
    
    move.l  #$800000, a0
    jsr     ReadFileIntoMemory
    
    RTS