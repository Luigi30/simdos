*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

CODE    EQU     0
DATA    EQU     1
MACROS  EQU     2
FAT12   EQU     3

    SECTION MACROS
    ORG     $8000
    include 'print_macros.x68'
    include 'stack_macros.x68'
    include 'memory_macros.x68'

    ;Goal:
    ;Main code between $1000-7FFF
    ;Main variables $F000-$FFFF
    SECTION CODE
    ORG     $1000
    
START:                  ; first instruction of program
    ;Populate the trap handler vectors
    ;TRAP 2 = FAT12 driver
    lea     Trap2Handler, a0
    move.l  #$88, a1
    move.l  a0, (a1)

    ;Setup memory
    jsr     initialize_heap
    
    PrintStringNL   msg_boot

    move.w  #0, d7
    trap    #2 ;call trap 2, task 0
    
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
    
    jsr     ReadBootSector
    
    PrintStringNL   msg_ready

;***************************************
;Function: ConsoleLoop
;
;Description:
;   The console input loop. When the user enters something,
;   send it to ProcessConsole via input_buffer.
;***************************************
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
    JSR     FindCommandLength ;find the length of the first word of the command
    JSR     memcmp ;compare d0.b bytes at a0 and a1
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
    ;find the command in the jump table
    lea     ConsoleCommandAddressTable, a0
    move.w  #$00000004, d0
    mulu.w  command_index, d0
    adda    d0, a0
    move.l  (a0),a1
    jsr     (a1) ;do the command
    
.gohome:
    RTS
    
FindCommandLength:
    ;Find the first 0x20 or 0x00 in the command.
    PUSH    a0-a6
    PUSH    d1-d7
    
    lea     input_buffer, a0
    move.l  #command_length, d1
    subq    #1, d1
    move.l  #$0000FFFF, d0
    
.loop:
    addq.w  #1, d0
    cmp.b   #$20, (a0)
    beq     .done
    cmp.b   #$00, (a0)
    beq     .done
    addq.l  #1, a0
    dbra    d1, .loop
    
.done:    
    POP     d1-d7
    POP     a0-a6
    RTS

DoShutdownCommand:
    PrintStringNL cmd_halting
    SIMHALT
    rts
    
DoDirCommand:
    ;this gets the volume name, for now
    lea     floppy_data, a0
    jsr     CountObjectsInRootDirectory
    clr.l   d6
    add     d0, d6
    add     d7, d6

    ;display volume name text
    PrintString msg_volume_name
    move.l  #0, d0
    lea     volume_label, a1
    move.l  #11, d1
    trap    #15
    
    ;display volume serial number text
    PrintString msg_volume_serial
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
    
    PrintString newline_str

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
    
DoLoadCommand:
    lea     input_buffer+5, a0
    jsr     ConvertStringTo83
    jsr     GetStartingCluster ;puts starting cluster in d0
    
    move.l  #$800000, a0
    jsr     ReadFileIntoMemory
    
    RTS
    
DoRunCommand:
    PushAll
    move.l  #$800000, a0
    jsr     (a0)
    PopAll
    rts
    
    include 'memory_management.x68'
    
    SECTION DATA
    ORG     $F0000
;Constants and variables and tables and stuff
msg_boot        dc.b    'Sim68k Disk Operating System ROM',0
msg_ramdisk     dc.b    'Ramdisk located at 0x',0
msg_ready       dc.b    'Ready.',0
msg_trap_1      dc.b    'Trap #1 called!',0

newline_str     dc.b    $0D,$0A,0
prompt_str      dc.b    '> ',0
input_buffer    dcb.b   80,$00
filename_buffer dcb.b   16,$00
    
command_count   equ     4 ;how many commands are there?
command_length  equ     8 ;how long can a command be?
command_index   dcb.w   1,$00 ;which command did we just enter?
cmd_invalid     dc.b    'Command not recognized',0
cmd_valid       dc.b    'OK',0

cmd_halting     dc.b    'Halting system.',0
cmd_doing_load  dc.b    'Doing LOAD, beep boop.',0

;All commands are 8 characters, padded with nulls.
                ds.w    0 ;force even word alignment
ConsoleCommandTable:
cmd_shutdown    dc.b    'SHUTDOWN'
cmd_dir         dc.b    'DIR',0,0,0,0,0
cmd_load        dc.b    'LOAD',0,0,0,0
cmd_run         dc.b    'RUN',0,0,0,0,0

                    ds.w    0 ;force even word alignment
ConsoleCommandAddressTable:
cmd_shutdown_effect dc.l    DoShutdownCommand
cmd_dir_effect      dc.l    DoDirCommand
cmd_load_effect     dc.l    DoLoadCommand
cmd_run_effect      dc.l    DoRunCommand

    ;FAT12 driver lives at $A000-$C000
    include 'fat12.x68'
    
    END    START        ; last line of source

























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
