*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
;Macros will live here for now
    ORG     $4000
    include 'print_macros.x68'
    include 'stack_macros.x68'
    include 'memory_macros.x68'

    ORG     $1000
    
START:                  ; first instruction of program
    PrintStringNL   msg_boot
    
    ;load ramdisk file
    move.b  #51, d0
    lea     floppy_name, a1
    trap    #15 ;load the floppy image
    move.l  d1, file_id
    
    ;read ramdisk into memory
    move.b  #53, d0
    lea     floppy_data, a1
    move.l  #1474560, d2 ;1.44mb
    trap    #15
    
    PrintString     msg_ramdisk
    ;print ramdisk location
    lea     floppy_data, a0
    move.l  a0, d1
    move.b  #16, d2
    move.b  #15, d0
    trap    #15
    PrintString     newline_str
    
    move.l  floppy_data, floppy_pointer
    jsr     ReadBootSector
    
    move.l  #$300000, a0
    move.w  #$191, d0
    jsr     ReadFileIntoMemory
    
    PrintStringNL   msg_ready
   
ConsoleLoop:
    PrintString prompt_str
    
    ;clear the input buffer  
    lea     input_buffer, a1
    move.l  #$00000000, d1
    move.l  #$00000064, d2
    jsr     memset
    
    move.b  #2, d0
    trap    #15
    
    JSR     ProcessConsole
    
    JMP     ConsoleLoop

    SIMHALT             ; halt simulator
       
ReadFileIntoMemory:
    ;Read file starting at cluster d0.w into (a0).l
    ;In FAT12, 1 cluster = 1 sector
    ;for testing, just read the file at cluster 0x191 into 0x300000
        
    ;find this file in the FAT.
    clr.l   d2    
    clr.l   d5
    move.w  d0, d4 ;preload the sector index
    
    ;calculate the offset of sector 1 (the start of the FAT)
    move.l  bytes_per_sector, d2
    lea     floppy_data, a1
    add.w   d2, a1
    
.read_cluster:
    ;calculate the address of cluster d0's data
    clr.l   d2
    lea     floppy_data, a1
        
    move.w  bytes_per_sector, d2
    addi    #31, d0 ;data starts at sector 33 and all data is offset 2 sectors.
    mulu.w  d0, d2
    add.l   d2, a1
    clr.l   d2
    move.w  bytes_per_sector, d2
    sub.w   #1, d2
    
.copyloop:
    move.b  (a1)+,(a0)+
    dbra    d2, .copyloop
    
.get_next:    
    jsr     ReadFATEntry ;returns next cluster in d5
    cmp.w   #$FFF, d5 ;0xFFF = file is complete
    beq     .done
    move.w  d5, d0
    add.w   #1, d4

    jmp     .read_cluster

.done:    
    RTS
      
;Console processing and command list.
ProcessConsole:
    ;process a console command.
    move.w  #0, command_index
    lea     ConsoleCommandTable, a1
    
CommandCheckLoop:
    ;check the next command in the table and see if what we entered matches it.
    mulu.w  #command_length, d1
    lea     input_buffer, a0
    move.w  #command_length, d0
    JSR     CapitalizeString ;capitalize the input
    JSR     StringsAreEqual ;compare d0.b bytes at a0 and a1
    cmp.b   #0, d0 ;0 = equal, 1 = not equal
    beq     .equal
    
    ;not equal, check the next command string
    addi.w  #1, command_index
    add     #8, a1
    cmp.w   #command_count, command_index
    bne     CommandCheckLoop
    
.cmd_invalid:
    PrintStringNL cmd_invalid
    jmp     .gohome
    
.equal:
    PrintStringNL cmd_valid
    
    ;find the command in the jump table
    lea     ConsoleCommandAddressTable, a0
    move.w  #$00000004, d0
    mulu.w  command_index, d0
    adda    d0, a0
    move.l  (a0),a1
    jsr     (a1) ;do the command
    
.gohome:
    RTS

DoShutdownCommand:
    PrintStringNL cmd_halting
    SIMHALT
    rts
    
DoDirCommand:
    move.l  #8, d0 ;TODO: there are 9 files in the root
    
.dirloop: 
    ;loop over root directory entries and display them.
    move.w  d0, file_index
    jsr ReadRootDirectoryEntry
    jsr PrintDirectoryEntry    
    dbra    d0, .dirloop
    rts
    
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
    
CapitalizeString:
    ;Capitalize a null-terminated string located at (a0) in place. Runs until it finds a null character.
    PUSH    d0
    PUSH    a0
    jmp     .loop
    
.fetch:
    ;Advance a0 by 1 character
    addq    #1, a0
    
.loop:
    move.b  (a0), d0
    ;is the character null? if so, we're done
    cmp.b   #$00, d0
    beq     .done
    
    ;is the character 0x61 or higher?
    cmp.b   #$61, d0
    blt     .fetch ; nope, get the next character
    
    ;is the character 0x7a or lower?
    cmp.b   #$7A, d0
    bgt     .fetch ; nope, get the next character
    
    ;this is a character we can capitalize, so capitalize it.
    sub.b   #$20, (a0)
    jmp     .fetch
    
.done:
    POP     a0
    POP     d0
    RTS
    
;Constants and variables and tables and stuff
msg_boot        dc.b    'Sim68k Disk Operating System ROM',0
msg_ramdisk     dc.b    'Ramdisk located at 0x',0
msg_ready       dc.b    'Ready.',0

newline_str     dc.b    $0D,$0A,0
prompt_str      dc.b    '> ',0
input_buffer    dcb.b   80,$00
    
command_count   equ     2 ;how many commands are there?
command_length  equ     8 ;how long can a command be?
command_index   dcb.w   1,$00 ;which command did we just enter?
cmd_invalid     dc.b    'Command not recognized',0
cmd_valid       dc.b    'OK',0

cmd_halting     dc.b    'Halting system.',0
cmd_doing_dir   dc.b    'Doing DIR, beep boop.',0

;All commands are 8 characters, padded with nulls.
ConsoleCommandTable:
cmd_shutdown    dc.b    'SHUTDOWN'
cmd_dir         dc.b    'DIR',0,0,0,0,0

ConsoleCommandAddressTable:
cmd_shutdown_effect dc.l    DoShutdownCommand
cmd_dir_effect      dc.l    DoDirCommand

    
    ;FAT12 driver goes at the end
    include 'fat12.x68'

    END    START        ; last line of source












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
