DoRunCommand:
    PushAll
    move.l  #$800000, a0
    jsr     (a0)
    PopAll
    rts