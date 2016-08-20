;FAT12 library for Easy68K.

    SECTION FAT12
    ORG     $A000
    
;See functions for parameters
Trap2Table:
Trap2Task0  dc.l    Trap2TestMessage
Trap2Task1  dc.l    ReadBootSector
Trap2Task2  dc.l    CountObjectsInRootDirectory
Trap2Task3  dc.l    PrintDirectoryEntry
Trap2Task4  dc.l    CalculateDiskCapacity
Trap2Task5  dc.l    EnumerateRootDirectory
Trap2Task6  dc.l    ReadFATEntry
Trap2Task7  dc.l    GetStartingCluster    
    
Trap2Handler: ;Trap #2 - FAT12 driver functions.
    mulu.w  #4, d7 ;multiply d7 by 4 to get the offset of the table entry.
    lea     Trap2Table, a6
    add.l   d7, a6
    move.l  (a6), a6
    jsr     (a6)
    RTE
    
Trap2TestMessage:
    PrintStringNL   msg_trap_2
    rts

ReadBootSector:
    ;Read the BPB into a structure in memory.
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
    
    ;4 bytes: Volume serial
    lea     floppy_data, a0
    add     #$27, a0
    lea     volume_serial, a1
    move.b  1(a0), 0(a1)
    move.b  0(a0), 1(a1)
    move.b  3(a0), 2(a1)
    move.b  2(a0), 3(a1)
    ;move.l  (a0),(a1)
    
    ;11 bytes: Volume label
    lea     floppy_data, a0
    add     #$2B, a0
    lea     volume_label, a1
    move.l  #10, d6
.read_volume_label:
    move.b  (a0)+, (a1)+
    dbra    d6, .read_volume_label

    RTS
    
CountObjectsInRootDirectory:
    ;Input:
    ;a0.l = address of floppy data
    ;Output:
    ;d0.w = number of files in root directory.
    ;d7.w = number of directories in root directory.
    PUSH    a1-a7
    PUSH    d1-d6
    
    move.l  #$0, total_file_size
    
    clr.l   d0 ;number of files in directory
    clr.l   d1 ;offset calculation
    clr.l   d2 ;directory index we're at
    clr.l   d4
    clr.l   d7 ;number of directories in directory
    move.b  #SECTOR_ROOT_DIR, d1 ;root directory is sector 19
    mulu.w  bytes_per_sector, d1 ;offset of sector 19
    move.l  a0, a1
    add     d1, a1 ;a1 = start of the root directory
    
.chek:
    ;Check the first byte of the root directory entry.
    cmp.b   #$00, (a1) ;$00 = unallocated entry
    beq     .next
    
    cmp.b   #$E5, (a1) ;$E5 = deleted file
    beq     .next
    
    ;This is a real object. Is it a file or a directory?
    move.b  11(a1), d3
    btst    #3, d3
    bne     .lbl ;Neither, it's a volume label!
    btst    #4, d3
    bne     .dir
    
.file:
    ;Increment the counter, add to the running file size total, and proceed to the next file.
    PUSH    a0
    PUSH    d1
    move.l  a1, a0
    add     #28, a0
    jsr     Read32BitLittleEndian
    add.l   d1, total_file_size
    POP     d1
    POP     a0
    
    addi    #1, d0
    jmp     .next
    
.dir:
    addi    #1, d7
    jmp     .next

.next:
    add.b   #1, d2
    add.l   #32, a1
    cmp.b   #224, d2 ;have we processed 224 directory entries?
    beq     .done
    jmp     .chek
    
.lbl:
    move.l  a1, a4
    move.l  #10, d4
    lea     volume_label, a5
.loop:
    move.b  (a4)+, (a5)+
    dbra    d4, .loop
    jmp     .next

.done:
    POP     d1-d6
    POP     a1-a7
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
    ;One line that comes out when we do a DIR command.
    ;This retrieves the data for the command and writes it to the screen.
    ;Called once per entry in the directory.
    
    ;directory entry is 32 bytes loaded into file_directory_entry
    PushAll
   
.filename:
    ;11 characters, dot is implied between 8-9
    ;8 characters
    lea     file_directory_entry, a1
    move.w  #8, d1
    move.b  #1, d0
    trap    #15
    
    ;spacer
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15
    
    ;3 characters
    lea     file_directory_entry+8, a1
    move.b  #3, d1
    move.b  #1, d0
    trap    #15
    
    ;spacer
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15    
    
.filesize: ;File size in bytes.
    lea     file_directory_entry+28, a0
    jsr     Read32BitLittleEndian
    
    cmp     #0, d1
    beq     .label_dir ;If the file size is 0, it's either a 0-byte file or a directory.
    
.label_file: ;Assume any files bigger than 0 bytes are a file.
    move.b  #20, d0
    move.b  #8, d2
    trap    #15
    jmp     .label_date
    
.label_dir: ;Print <DIR> on 0-byte files (todo: fix this, only directories)
    PrintString msg_directory
    
.label_date:
    ;Convert the date code into a human-readable YYYY-DD-MM date.

    ;spacer
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15

    ;year number
    lea     file_directory_entry+16, a0
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
    
.lbl_attribs:
    ;spacer
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15

.lbl_readonly
    ;Read-only
    btst    #0, file_directory_entry+11
    beq     .lbl_ro_space
    move.b  #6, d0
    move.b  #$52, d1
    trap    #15
    jmp     .lbl_hidden
    
.lbl_ro_space
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15  
    
.lbl_hidden
    ;Hidden
    btst    #1, file_directory_entry+11
    beq     .lbl_h_space
    move.b  #6, d0
    move.b  #$48, d1
    trap    #15
    jmp     .lbl_system
    
.lbl_h_space
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15
    
.lbl_system
    ;System
    btst    #2, file_directory_entry+11
    beq     .lbl_s_space
    move.b  #6, d0
    move.b  #$53, d1
    trap    #15
    jmp     .lbl_cluster
    
.lbl_s_space
    move.b  #6, d0
    move.b  #$20, d1
    trap    #15
    
.lbl_cluster:
    ;Debugging: What cluster does this file start on?
    lea     file_directory_entry+26, a0
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
    
GetStartingCluster:
    ;Call ReadRootDirectoryEntry repeatedly.
    ;Stop after 224 loops or when we find the file we need.
    ;Input: 
    ;   a0.l = address of string to find
    ;Output:
    ;   d0.w = starting cluster of the file, 0x0000 if not found
    PUSH    a1
    PUSH    d7
    
    move.w  #$FFFF, file_index
    move.b  #223, d7
.loop:
    addq    #1, file_index
    JSR     ReadRootDirectoryEntry
    JSR     strlen ;will return string length in d0
    lea     file_directory_entry, a1
    JSR     StringsAreEqual ;compare d0.b bytes of a0 and a1
    beq     .found
    dbra    d7, .loop
    
.notfound:
    PrintStringNL   msg_invalid_image
    jmp     .done
    
.found:
    PrintStringNL   msg_valid_image
    move.w  file_directory_entry+26, d0
    ror.w   #8, d0
    jmp     .done
    
.done:
    POP     d7
    POP     a1
    RTS

    ORG     $B000
;Constants
SECTOR_ROOT_DIR     equ     19
DIR_ENTRY_SIZE      equ     32
    
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
volume_serial       dcb.l   1,$00
volume_label        dcb.b   11,$00
total_file_size     dcb.l   1,$00

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
msg_file_count          dc.b    ' files in folder',0
msg_directory_count     dc.b    ' directories in folder',0
msg_volume_name     dc.b    'Volume name is ',0
msg_volume_serial   dc.b    'Volume serial number is ',0
msg_bytes_used      dc.b    ' bytes used',0
msg_bytes_free      dc.b    ' bytes free',0
msg_trap_2          dc.b    'Trap 2 Task 0 called!',0

    ORG $200000    
floppy_data         dcb.b   1474560,$00




















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
