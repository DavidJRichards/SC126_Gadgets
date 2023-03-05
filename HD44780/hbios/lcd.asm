;------------------------
; LCD dumb terminal
;------------------------

lcd_command .equ $00     ;LCD command I/O port
lcd_data .equ $01        ;LCD data I/O port
   
    
LCD_PREINIT:
LCDTERM_PREINIT:

    call lcd_initialise ;Setup LCD display
    
    ld hl,djrm_message
    call lcd_send_asciiz
    
    ld de,$0001         ;Position cursor on second line
    call lcd_gotoxy
    
    call lcd_cursor_on  ;Turn the cursor on
    CALL   VFDTERM_SOL    
    ret

    
djrm_message:
    .db "djrm SC126 HD44780",0    

vfdPtr           .DW     0
vfdLen           .DB     0
vfdLine1         .DW     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vfdLine2         .DW     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

vfdLineLen       .EQU    20


                  ; assume character in E
LCDTERM_PUTC:     PUSH   AF
                  PUSH   BC
                  PUSH   DE
                  PUSH   HL

                  LD     A,E
                  CP     $08
                  JR     Z, VFDTERM_BSPC
                  CP     $0A                ; line feed
                  JR     Z, VFDTERM_NEWLINE
                  CP     $0D                ; CR
                  JR     Z, VFDTERM_CR

VFDTERM_STOREC:   LD     A, E               ; write the character to the vfd
                  call  lcd_send_data
                  LD     HL, (vfdPtr)       ; update pointer
                  LD     (HL), E
                  INC    HL
                  LD     (vfdPtr), HL

                  LD     A, (vfdLen)        ; update position index
                  INC    A
                  LD     (vfdLen), A

                  LD     A, (vfdLen)        ; check if we just wrapped
                  CP     vfdLineLen
                  JR     NZ, VFDTERM_PUTC_OUT

VFDTERM_NEWLINE:
                  CALL   VFDTERM_SCROLL
                  CALL   VFDTERM_REDRAW
                  CALL   VFDTERM_SOL
                  JR     VFDTERM_PUTC_OUT

VFDTERM_BSPC:     LD     A, (vfdLen)
                  CP     $00
                  JR     Z, VFDTERM_PUTC_OUT ; at beginning of buffer, no-op

                  DEC    A                   ; decrement line len
                  LD     (vfdLen), A
                  LD     HL, (vfdPtr)        ; decrement ptr
                  DEC    HL
                  LD     (vfdPtr), HL

                  LD     A, $10              ; shift cursor left one place
                  call   lcd_send_command

                  JR     VFDTERM_PUTC_OUT

VFDTERM_CR:       CALL   VFDTERM_SOL
                  JR     VFDTERM_PUTC_OUT
VFDTERM_PUTC_OUT:
                  POP    HL
                  POP    DE
                  POP    BC
                  POP    AF
                  RET


                  ; scroll the buffer up one line
VFDTERM_SCROLL:
                  LD     HL, vfdLine2
                  LD     DE, vfdLine1
                  LD     BC, 20
                  LDIR                      ; do the move
                  LD     HL, vfdLine2       ; clear the last line of the buffer
                  LD     BC, vfdLineLen
                  LD     A, ' '
                  CALL   FILL
                  RET

                  ; move pointer to start of 2nd line
VFDTERM_SOL:
                  LD     HL, vfdLine2
                  LD     (vfdPtr), HL
                  LD     A, 0
                  LD     (vfdLen), A
                  LD     A, $C0             ; command to move to start of line 2
                  call   lcd_send_command   ; send to VFD
                  RET

VFDTERM_REDRAW:
                  LD     A, $80             ; command to move to start of line 1
                  call   lcd_send_command 
                  LD     DE, vfdLine1
                  LD     C, vfdLineLen
VFDTERM_REDRAW0:  LD     A, (DE)
                  INC    DE
                  call  lcd_send_data
                  DEC    C
                  JR     NZ, VFDTERM_REDRAW0

                  LD     A, $C0             ; command to move to start of line 2
                  call   lcd_send_command
                  LD     DE, vfdLine2
                  LD     C, vfdLineLen
VFDTERM_REDRAW1:  LD     A, (DE)
                  INC    DE
                  call  lcd_send_data
                  DEC    C
                  JR     NZ, VFDTERM_REDRAW1
                  RET

;Library To Use a Generic Character LCD Display From a Z80
;
;For devices using the HD44780U and compatible controllers
;Datasheet: https://cdn-shop.adafruit.com/datasheets/HD44780.pdf
;
;Intended for the Couch To 64k project.

;==================Character LCD Display Library

;Partial set of LCD commands. See data sheet for the full functionality.
lcd_cmd_cls          .equ $01
lcd_cmd_home         .equ $02
lcd_cmd_entry_mode   .equ $06    ;Left to right mode
lcd_cmd_function_set .equ $3f    ;8-bit, 2-line, small font

lcd_cmd_display_on   .equ $0c    ;Display on, cursor off
lcd_cmd_cursor_blink .equ $01    ;Blinking cursor. OR with lcd_cmd_display_on
lcd_cmd_cursor_on    .equ $02    ;Undercore cursor. OR with lcd_cmd_display_on

;List of commands to run at start up, $ff terminated
lcd_init_commands:
    .db lcd_cmd_function_set
    .db lcd_cmd_display_on
    ;db lcd_cmd_display_on or lcd_cmd_cursor_on or lcd_cmd_cursor_blink
                                ;Alt version with cursor on
    .db lcd_cmd_cls
    .db $ff                      ;End of data marker
    
    
;----Send a data byte to the LCD
;In: Data in A
;Out: All registers preserved
lcd_send_data:
    push af             ;Preserve A
lcd_send_data_loop:     ;Loop while busy
    in a,(lcd_command)  ;Read status data
    rlca                ;Bit 7=1 if busy
    jr c,lcd_send_data_loop
    
    pop af              ;Retrieve A
    out (lcd_data),a    ;Output it
    ret

;-----Send a command byte to the LCD
;In: Data in A
;Out: All registers preserved
lcd_send_command:
    push af             ;Preserve A
lcd_send_command_loop:     ;Loop while busy
    in a,(lcd_command)  ;Read status data
    rlca                ;Bit 7=1 if busy
    jr c,lcd_send_command_loop
    
    pop af              ;Retrieve A
    out (lcd_command),a    ;Output it
    ret

;-----Send a list of commands to the LCD display ($ff terminated)
;In: HL=Pointer to command list
;Out: AF,HL corrupt. All other registers preserved
lcd_send_command_list:
    ld a,(hl)           ;Load command
    cp $ff               ;Test if it's $ff...
    ret z               ;...and exit if it is
    call lcd_send_command   ;Send it to the LCD
    inc hl              ;Advance to next byte
    jr lcd_send_command_list    ;Loop

;-----Send an ASCIIZ string to the LCD
;In: HL=Pointer to the first byte of the string
;Out: AF, HL corrupt. All other registers preserved
lcd_send_asciiz:
    
lcd_send_asciiz_loop:
    ld a,(hl)           ;Load command
    and a               ;Test if it's zero...
    jr z,lcd_send_asciiz_done  
                        ;...and exit if it is
    call lcd_send_data  ;Send it to the LCD
    inc hl              ;Advance to next byte
    jr lcd_send_asciiz  ;Loop
    
lcd_send_asciiz_done:
    ret
    
;---------LCD Initialisation
;In: None
;Out: AF,HL corrupt
lcd_initialise:
    ld hl,lcd_init_commands     ;Address of command list, $ff terminated
    jp lcd_send_command_list    ;Send the command list to the display
                        ;(and return)

;-----Clear the LCD display
;In: None
;Out: A corrupt
lcd_cls:
    ld a,$01            ;Clear screen command
    jp lcd_send_command ;Send and return
    
;-----Set the X,Y position of the LCD cursor
;NOTE: This code only works on one or two line displays
;In: D=X position (0-max), Y=Y position (0-1)
;Out: AF,DE corrupt

lcd_chars_per_line .equ 40   ;Constant: number of characters per LCD line

lcd_gotoxy:
    ld a,$80    ;Set cursor position command
    or d        ;Add on the X position
    dec e       ;Do we want line 0 or line 1
    jr c,lcd_gotoxy_done        ;Line 0 = no addition, else...
    add a,lcd_chars_per_line    ;...add line length to get to next line

lcd_gotoxy_done:
    jp lcd_send_command ;Send command and return
    
;-----Turn the cursor on.
;Change the lcd_cursor_on constant to change the cursor type
;In: None
;Out: AF Corrupt
lcd_cursor_on:
    ld a,lcd_cmd_display_on | lcd_cmd_cursor_blink
    jp lcd_send_command
    
;-----Turn the cursor off
;In: None
;Out: AF Corrupt
lcd_cursor_off:
    ld a,lcd_cmd_display_on ;Display on, cursor off
    jp lcd_send_command
    
;===========================LCD Library END
