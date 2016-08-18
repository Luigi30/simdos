;FAT12 library for Easy68K.

ReadBootSector:
    lea     floppy_data, a1
    move.l  #$200000, floppy_pointer
    
    ;3 bytes: bootstrap code
    add.l   #$00000003, floppy_pointer

    ;8 bytes: OEM name
    move.b  #0, d0
    move.l  floppy_pointer, a1
    move.w  #8, d1
    ;trap    #15
    add.l   #$00000008, floppy_pointer
    
    ;2 bytes: Bytes per sector
    move.l  floppy_pointer, a0
    jsr Read16BitLittleEndian
    move.w  d1, bytes_per_sector
    add.l   #$00000002, floppy_pointer
    
    ;1 byte: Sectors per cluster
    move.l  floppy_pointer, a0
    move.b  (a0), sectors_per_cluster
    add.l   #$00000001, floppy_pointer
    
    ;2 bytes: Reserved sectors
    move.l  floppy_pointer, a0
    jsr Read16BitLittleEndian
    move.w  d1, reserved_sectors
    add.l   #$00000002, floppy_pointer
    
    ;1 byte: FAT copies
    move.l  floppy_pointer, a0
    move.b  (a0), FAT_copies
    add.l   #$00000001, floppy_pointer
    
    ;2 bytes: Root directory entries
    move.l  floppy_pointer, a0
    jsr Read16BitLittleEndian
    move.w  d1, root_dir_entries
    add.l   #$00000002, floppy_pointer
    
    ;2 bytes: Number of sectors in filesystem
    move.l  floppy_pointer, a0
    jsr Read16BitLittleEndian
    move.w  d1, sector_count
    add.l   #$00000002, floppy_pointer
    
    ;1 bytes: Media descriptor
    move.l  floppy_pointer, a0
    move.b  (a0), media_descriptor
    add.l   #$00000001, floppy_pointer 

    ;2 bytes: Sectors per FAT
    move.l  floppy_pointer, a0
    jsr Read16BitLittleEndian
    move.w  d1, sectors_per_fat
    add.l   #$00000002, floppy_pointer  
    
    ;2 bytes: Sectors per track
    move.l  floppy_pointer, a0
    jsr Read16BitLittleEndian
    move.w  d1, sectors_per_track
    add.l   #$00000002, floppy_pointer 
    
    ;2 bytes: Number of heads
    move.l  floppy_pointer, a0
    jsr Read16BitLittleEndian
    move.w  d1, number_of_heads
    add.l   #$00000002, floppy_pointer 
    
    ;2 bytes: Number of hidden sectors
    move.l  floppy_pointer, a0
    jsr Read16BitLittleEndian
    move.w  d1, hidden_sector_count
    add.l   #$00000002, floppy_pointer 

    RTS
    
ReadRootDirectoryEntry:
    ;Retrieves the root directory entry for file_index and stores it in file_directory_entry.
    PushAll
    
    ;file data offset
    move.w  file_index, d0
    mulu.w  #32, d0
    
    ;find sector 19's offset
    move.w  #19, d1
    mulu.w  bytes_per_sector, d1
    
    lea     floppy_data, a0
    add.l   d1, a0
    add     d0, a0 ;a0 = offset of file directory entry
    
    move.l  #31, d2
    lea     file_directory_entry, a1
    
CopyRootDirectoryEntry:
    move.b  (a0)+, (a1)+
    dbra    d2, CopyRootDirectoryEntry
    PopAll
    RTS   
    
PrintDirectoryEntry:
    ;directory entry is 32 bytes loaded into file_directory_entry
    PushAll
    
    lea     file_directory_entry, a4
    
.filename:
    ;8 characters
    move    a4, a1
    move.w  #8, d1
    move.b  #1, d0
    trap    #15
    
    ;spacer
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15
    
    ;3 characters
    add.l   #$00000008, a4
    move.l  a4, a1
    move.b  #3, d1
    move.b  #1, d0
    trap    #15
    
    ;spacer
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15    
    
.filesize:
    add.l   #20, a4
    move.l  a4, a1
    move.l  a1, a0
    jsr     Read32BitLittleEndian
    
    cmp     #0, d1
    beq     .label_dir
    
.label_file:
    move.b  #20, d0
    move.b  #8, d2
    trap    #15
    jmp     .label_date
    
.label_dir:
    PrintString msg_directory
    
.label_date:
    ;spacer
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15

    ;year number
    sub.l   #4, a4
    move.l  a4, a1
    move.l  a1, a0
    jsr     Read16BitLittleEndian
    
    ;d1.w is now a 16 bit date code
    ;0-6   = years since 1980
    ;7-10  = months
    ;10-15 = days
    move.w  d1, d4
    and.w   #%1111111000000000, d4
    ror.l   #8, d4 ;shift the number to the low byte
    ror.l   #1, d4 ;shift it over by 1 so it's aligned properly
    addi.w  #1980, d4 ;date is years since 1980
    PUSH    d2
    PUSH    d1
    PUSH    d0
    clr.l   d1
    move.w  d4, d1
    move.b  #2, d2
    move.l  #20, d0
    trap    #15
    
    ;dash
    move.b  #6, d0
    move.b  #$2D, d1
    trap    #15
    POP     d0
    POP     d1
    POP     d2
    
    ;month number
    move.w  d1, d4
    and.w   #%0000000111100000, d4
    ror.l   #5, d4
    PUSH    d2
    PUSH    d1
    PUSH    d0
    clr.l   d1
    move.w  d4, d1
    move.b  #2, d2
    move.l  #20, d0
    trap    #15

    ;dash
    move.b  #6, d0
    move.b  #$2D, d1
    trap    #15
    POP     d0
    POP     d1
    POP     d2
    
    ;day number
    move.w  d1, d4
    and.w   #%0000000000011111, d4
    PUSH    d2
    PUSH    d1
    PUSH    d0
    clr.l   d1
    move.w  d4, d1
    move.b  #2, d2
    move.l  #20, d0
    trap    #15
    POP     d0
    POP     d1
    POP     d2
    
.lbl_cluster:
    ;spacer
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15

    add     #2, a4
    move.l  a4, a1
    move.l  a1, a0
    jsr     Read16BitLittleEndian
    move.b  #16, d2
    move.b  #15, d0
    trap    #15
    
.new_line:
    move.b  #6, d0
    move.b  #$0D, d1
    trap    #15
    move.b  #6, d0
    move.b  #$0A, d1
    trap    #15
    
    PopAll
    RTS
    
CopyFileDirEntry:
    move.b  (a0)+, (a1)+
    dbra    d2, CopyFileDirEntry
    PopAll
    RTS   
    
RunProgram.Bin: ;todo: expand this to take a filename
    ;read cluster 0x40F into memory at 0x800000
    
    ;calculate cluster size
    clr.l   d0
    move.w  bytes_per_sector, d0
    clr.w   d1
    move.b  sectors_per_cluster, d1
    mulu.w  d1, d0
    move.w  d0, d2 ;save this for later
    mulu.w  #$40F, d0
    add.l   #$3E00, d0 ;file storage starts at 0x4200 from the start of the disk, the first cluster is 2
    lea     floppy_data, a1
    move.l  d0, a0
    add.l   a1, a0
    
    ;copy one cluster into memory at 0x800000
CopyCluster:
    move.l  #$800000, a1
    sub.w   #1, d2
.copycluster_inner:
    move.b  (a0)+, (a1)+
    dbra    d2, .copycluster_inner
    
    jsr     $800000   
    
CalculateDiskCapacity:
    PrintString msg_disk_size
    clr.l   d0
    clr.l   d1
    clr.l   d2
    move.w  bytes_per_sector, d0
    mulu.w  sector_count, d0
    move.l  d0, d1
    move.b  #10, d2
    move.b  #15, d0
    trap    #15
    PrintStringNL msg_bytes
    RTS
    
EnumerateRootDirectory:
    move.w  #19, sector_pointer
    move.w  sector_pointer, d0
    mulu.w  bytes_per_sector, d0
    lea     floppy_data, a1
    add.l   d0, a1
    move.b  #8, d6
    RTS
    
ReadDirectoryLoop:
    lea     file_directory_entry, a2
    move.l  #31, d7
    RTS
    
ReadFATEntry:
    ;Read the FAT data for the specified cluster.
    ;Input:
    ;   a2 is the start of the FAT
    ;   d4.w is the FAT index we want
    ;Output:
    ;   d5.w is the file's next cluster
    
    clr.l   d5
    clr.l   d6
    clr.l   d7
    move.l  #$200200, a2
    btst.l  #$00, d4
    bne     .read_fat_low
    
.read_fat_high:
    
    ;low 8 bits
    move.w  d4, d6
    mulu.w  #3, d6
    divu.w  #2, d6
    move.l  a2, a3
    add.w   d6, a3
    move.b  (a3), d5
    
    ;high 4 bits
    add     #1, a3
    move.b  (a3), d7
    and.b   #%00001111, d7
    rol.w   #8, d7
    or.w    d7, d5
    jmp     .done

.read_fat_low:
    ;high 4 bits
    move.w  d4, d6
    mulu.w  #3, d6
    divu.w  #2, d6
    move.l  a2, a3
    add.w   d6, a3
    move.b  (a3), d5
    and.b   #%11110000, d5
    ror.b   #4, d5
    
    ;low 8 bits
    add     #1, a3
    move.b  (a3), d7
    rol.w   #4, d7
    or.w    d7, d5  
        
.done:
    RTS

    
;Variables
floppy_name         dc.b    'floppy.ima',0
file_id             dcb.l   1,$00
floppy_pointer      dcb.l   1,$00
floppy_logical_size dcb.w   1,$00

sector_pointer      dcb.w   1,$00

;floppy BPB
bytes_per_sector    dcb.w   1,$00
sectors_per_cluster dcb.b   1,$00
reserved_sectors    dcb.w   1,$00
FAT_copies          dcb.b   1,$00
root_dir_entries    dcb.w   1,$00
sector_count        dcb.w   1,$00
media_descriptor    dcb.b   1,$00
sectors_per_fat     dcb.w   1,$00
sectors_per_track   dcb.w   1,$00
number_of_heads     dcb.w   1,$00
hidden_sector_count dcb.w   1,$00
next_fat_high_or_low    dcb.b   1,$00 ;$00 = high, $FF = low

file_index              dcb.w   1,$00
file_directory_entry    dcb.b  32,$00 ;raw directory data
file_directory_pointer  dcb.b   1,$00

msg_reading_floppy  dc.b    'Reading floppy.ima.',0
msg_invalid_image   dc.b    'Image is not a valid floppy disk.',0
msg_valid_image     dc.b    'Image loaded successfully.',0
msg_oem_name        dc.b    'OEM name is ',0
msg_disk_size       dc.b    'Total size ',0
msg_bytes           dc.b    ' bytes',0
msg_directory       dc.b    '   <DIR>',0

    ORG $200000    
floppy_data         dcb.b   1474560,$00











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
