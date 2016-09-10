DoDirCommand:
    ;this gets the volume name, for now
    lea     floppy_data, a0
    jsr     CountObjectsInRootDirectory
    clr.l   d6
    add     d0, d6
    add     d7, d6

    ;display volume name text
    M_WriteString msg_volume_name
    move.l  #0, d0
    lea     volume_label, a1
    move.l  #11, d1
    trap    #15
    
    ;display volume serial number text
    M_WriteString msg_volume_serial
    move.l  #15, d0
    move.w  volume_serial, d1
    move.b  #16, d2
    trap    #15
    
    move.b  #6, d0
    move.b  #$2D, d1
    trap    #15
    
    move.l  #15, d0
    move.w  volume_serial+2, d1
    move.b  #16, d2
    trap    #15
    
    M_WriteString newline_str

    ;move.l  #9, d0 ;TODO: there are 10 objects in the root, get that number dynamically    
    move.l  d6, d0
.dirloop: 
    ;loop over root directory entries and display them.    
    jsr ReadRootDirectoryEntry
    lea     file_directory_entry, a2
    add     #11, a2    
    btst    #3, (a2)
    bne     .loop ;Do not print volume labels.
    jsr PrintDirectoryEntry    
    
.loop:
    dbra    d0, .dirloop
    
    ;output number of files in directory
    clr.l   d0
    clr.l   d1
    clr.l   d2
    clr.l   d7
    lea     floppy_data, a0
    jsr     CountObjectsInRootDirectory
    move.w  d0, d1
    move.l  #20, d0
    move.b  #4, d2
    trap    #15
    PrintStringNL   msg_file_count
    
    move.w  d7, d1
    trap    #15
    PrintStringNL   msg_directory_count
    
    move.b  #20, d0
    move.l  total_file_size, d1
    move.b  #10, d2
    trap    #15
    PrintStringNL   msg_bytes_used
    
    move.w  bytes_per_sector, d1
    move.w  sector_count, d3
    sub     #33, d3 ;33 sectors are reserved
    mulu    d3, d1
    sub.l   total_file_size, d1
    trap    #15
    PrintStringNL   msg_bytes_free
    
    rts
