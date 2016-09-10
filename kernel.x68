CODE    equ 0
DATA    equ 1
MACROS  equ 2
FAT12   equ 3

    ;set the reset vector for START
    ;ORG     $4
    ;dc.l    $00F00000

    include 'print_macros.x68'
    include 'stack_macros.x68'
    include 'memory_macros.x68'
    
    SECTION CODE
    ORG     $F00000
    
START:
    ;Populate the trap handler vectors
    ;TRAP 2 = FAT12 driver
    lea     Trap2Handler, a0
    move.l  #$88, a1
    move.l  a0, (a1)
    
    ;TRAP 3 = Console I/O
    lea     Trap3Handler, a0
    move.l  #$8C, a1
    move.l  a0, (a1)

    ;Setup memory
    ;jsr     initialize_heap
    ;move.w  #1000,d0
    ;jsr     malloc
    
    M_WriteString   msg_boot
    
    jmp     LoadRamdisk
    
LoadRamdisk:
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

    M_WriteString   msg_ramdisk
    
    ;print ramdisk location
    lea     floppy_data, a0
    move.l  a0, d1
    move.b  #16, d2
    move.b  #15, d0
    trap    #15
    M_WriteString   newline_str
    
    jsr     ReadBootSector
    
    M_WriteString   msg_ready
    M_WriteString   newline_str
    
    ;Run the console
    jmp     ConsoleLoop
    
;let's add some system calls
    
    SECTION DATA
    ORG     $FF0000
msg_boot        dc.b    'Sim68k Disk Operating System ROM',13,10,0
msg_ramdisk     dc.b    'Ramdisk located at 0x',0
msg_ready       dc.b    'Ready.',13,10,0

    SECTION CODE
    
    ;System calls
    include 'syscalls\console.x68'
    
    ;(ahem) "modules"
    include 'console.x68'
    include 'memory_management.x68'
    include 'fat12.x68' 

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
