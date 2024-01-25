* BOOTLOAD.ASM - Gravar Memoria Flash para MMSJ300
* Author: Moacir Silveira Junior (moacir.silveira@gmail.com)

STARTMEM    equ     $00800000           lowest memory location in use
ENDMEM      equ     $00FFFFFF           highest memory location used
BANKRAM0    equ     $00600000           Select RAM Bank Slot 0, 8MB
BANKRAM1    equ     $00600001           Select RAM Bank Slot 1, 8MB
PICPROG     equ     $00400000           I/O address of pic
STATUS      equ     $00400001           I/O address of status (switches/status pic)

            org     $0
            DC.L    $00FFFFFF
            DC.L    $00000400

            org     $400

            move.b  $00,BANKRAM0        Select RAM Slot 0
BOOTLOADER  move.w  STATUS,D0           read status and put in D0
            move.w  $01,D1				
            beq		LOOP2
            bra     $1000               start programm address

LOOP2                                   send to PIC solicit of the bootloader
            jrs     WAITPIC             wait pic response
            move.w  PICPROG,D0          read pic content
            move.w                      	     
            bra     LOOP2               repeat

WAITPIC     move.b  STATUS,D0           Only return if status is PIC READ
            move.b  $02,D1
            bne     WAITPIC
            rts

SAVEROM     rts
