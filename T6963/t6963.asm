;	     	T6963C HBIOS DRIVER V0.01 
; 
;		SOURCE PROGRAM for TMPZ84C00P 
;			1991 - 2 -15 
;	      	Display Size: 20 Column × 8 Lines 
; 
;	      	Character Font: 8 Dots Mode 
; 
TXHOME 		.EQU 40H 		; SET TXT HM ADD 
TXAREA 		.EQU 41H 		; SET TXT AREA 
GRHOME 		.EQU 42H 		; SET GR HM ADD 
GRAREA 		.EQU 43H 		; SET GR AREA 
CURSOR          .EQU 21H                 ; cursor pointer
OFFSET 		.EQU 22H 		; SET OFFSET ADD 
ADPSET 		.EQU 24H 		; SET ADD PTR 
AWRON 		.EQU 0B0H 		; SET AUTO WRITE MODE 
ARDON		.EQU 0B1H		; set auto read mode
AWROFF 		.EQU 0B2H 		; RESET AUTO WRITE MODE  
DATAWR          .EQU 0C0H                ; data write
;DATAWR          .EQU 0C4H                ; data write, address unchanged
CMDP 		.EQU 01H 		; CMD PORT 
DP 		.EQU 00H 		; DATA PORT 

TL1             .EQU 108H
TL2             .EQU 18cH
TL3             .EQU 1ccH
TSPOS           .EQU    058H             ; abs top left position of splash message 

; 16 x 40 @ 8x8

LCD_XWIDTH              .EQU 240
LCD_YHEIGHT             .EQU 128
LCD_KBYTES              .EQU 8

LCD_WIDTH               .EQU 48
LCD_HEIGHT              .EQU 16 


_TH                  .EQU 0
_TA                  .EQU 40H    ; 40 rounded to next multiple of 16, 64
_GH                  .EQU 400H
_GA                  .EQU 40H

_AH                  .EQU 1800H

_CG_OFFSET           .EQU 3
_CG_STARTADDRESS     .EQU 1800H

SCROLL_TEXT          .EQU _TH
SCROLL_ATTR          .EQU _AH



;STACK 		.EQU 9FFFH 		; STACK POINTER BASE ADDRESS 
; 
;                .ORG 0100H 
;START: 
;              	LD SP, STACK 

T6963_INIT:

; 
;   SET GRAPHIC HOME ADDRESS 
; 
		LD HL, _GH   		; GRAPHIC HOME ADDRESS 
		CALL DT2 
		LD A, GRHOME 
		CALL CMD 
; 
;   SET GRAPHIC AREA 
; 
		 LD HL, _GA  		; GRAPHIC AREA 
		 CALL DT2 
		 LD A, GRAREA 
		 CALL CMD 
; 
;   SET TEXT HOME ADDRESS 
; 
		LD HL, _TH   		; TEXT HOME ADDRESS 0000H 
		CALL DT2 
		LD A, TXHOME 
		CALL CMD 
; 
;   SET TEXT AREA 
; 
		 LD HL, _TA  		; TEXT AREA  (Columns) 
		 CALL DT2 
		 LD A, TXAREA 
		 CALL CMD 
; 
;   SET OFFSET REGISTER 
;      					CHARACTER CODE 80H 
		LD HL, _CG_OFFSET
		CALL DT2 
		LD A, OFFSET 
		CALL CMD 
; 
;   DISPLAY MODE 
;   (TEXT ON, GRAPHICS ON, CURSOR ON, BLINK ON) 
; 
		LD A, 9FH 
		CALL CMD 
;
; cursor
;
                ld a,0a1h
                call CMD				
; 
;   MODE SET (OR MODE, Internal Character Generator MODE) 
; 
		LD A,84H ;80H 
		CALL CMD 

		CALL	T6963_CLEAR	; clear text and graphic screens
		CALL    T6963_HOME      ; home cursor
; 
;   WRITE EXTERNAL CHARACTER GENERATOR DATA 
; 
		LD DE, EXTCG  		; CG data address in Program 
		LD HL, _CG_STARTADDRESS + 480H		; CG RAM Start Address (1c00H) 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 
; 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

		LD B, 128  		; 48 Character × 8 byte (64 = 40H) 
EXCG1: 
		LD A, (DE)  		; WRITE DATA TO EXTERNAL RAM 
;		xor 255
		CALL ADT  		; 
		INC HL 
		INC DE 
		DJNZ EXCG1 
		LD B, 128  		; 48 Character × 8 byte (64 = 40H) 
EXCG2: 
		LD A, (DE)  		; WRITE DATA TO EXTERNAL RAM 
;		xor 255
		CALL ADT  		; 
		INC HL 
		INC DE 
		DJNZ EXCG2 
		LD B, 128  		; 48 Character × 8 byte (64 = 40H) 
EXCG3: 
		LD A, (DE)  		; WRITE DATA TO EXTERNAL RAM 
;		xor 255
		CALL ADT  		; 
		INC HL 
		INC DE 
		DJNZ EXCG3 

		LD A, AWROFF  		; AUTO RESET 
		CALL  CMD 
#if 1
;==============================================================================
; 
;   WRITE TEXT DISPLAY DATA (INTERNAL CG) 
;
		LD HL, _TH+TSPOS  		; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 
		LD B, 06H  		; 13 Character 
		LD DE, DJRM1 
TXLPD1: 	LD A, (DE)  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd		
		CALL ADT 
		INC DE 
		DJNZ TXLPD1 
		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

		LD HL, _TH+TSPOS+040H  		; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 
		LD B, 06H  		; 13 Character 
		LD DE, DJRM1+6 
TXLPD2: 	LD A, (DE)  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd		
		CALL ADT 
		INC DE 
		DJNZ TXLPD2 
		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

		LD HL, _TH+TSPOS+080H  		; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 
		LD B, 06H  		; 13 Character 
		LD DE, DJRM1+12 
TXLPD3: 	LD A, (DE)  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd		
		CALL ADT 
		INC DE 
		DJNZ TXLPD3 
		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

		LD HL, _TH+TSPOS+0C0H  		; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 
		LD B, 06H  		; 13 Character 
		LD DE, DJRM1+18 
TXLPD4: 	LD A, (DE)  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd		
		CALL ADT 
		INC DE 
		DJNZ TXLPD4 
		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

		LD HL, _TH+TSPOS+0100H  		; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 
		LD B, 06H  		; 13 Character 
		LD DE, DJRM1+24 
TXLPD5: 	LD A, (DE)  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd		
		CALL ADT 
		INC DE 
		DJNZ TXLPD5 
		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

;==============================================================================
;
; write attribute home address to GH
; 
;   SET GRAPHIC HOME ADDRESS 
; 
		LD HL, _AH   		; SET ATTRIBUTE HOME ADDRESS (GRHOME)
		CALL DT2 
		LD A, GRHOME 
		CALL CMD 


; write attribute data
		LD HL, _AH+TSPOS+040H  		; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD
		 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 
		LD B, 06H  		; 13 Character 
		LD DE, DJRM2 
TXLPA1: 	LD A, (DE)  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd		
		CALL ADT 
		INC DE 
		DJNZ TXLPA1 
		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

		LD HL, _AH+TSPOS+040H+080H  		; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 
		LD B, 06H  		; 13 Character 
		LD DE, DJRM2+6 
TXLPA2: 	LD A, (DE)  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd		
		CALL ADT 
		INC DE 
		DJNZ TXLPA2 
		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 
;==============================================================================
#endif
                ret
;-------------------------------------------------------------------------------                
; 
; Subroutine start 
; 

; arithmatic functions from 
; http://z80-heaven.wikidot.com/math

;Inputs:
;     DE and A are factors
;Outputs:
;     A is not changed
;     B is 0
;     C is not changed
;     DE is not changed
;     HL is the product
;Time:
;     342+6x
;
DE_Times_A:
     ld b,8          ;7           7
     ld hl,0         ;10         10
       add hl,hl     ;11*8       88
       rlca          ;4*8        32
       jr nc,$+3     ;(12|18)*8  96+6x
         add hl,de   ;--         --
       djnz $-5      ;13*7+8     99
     ret             ;10         10


;Inputs:
;     HL is the numerator
;     C is the denominator
;Outputs:
;     A is the remainder
;     B is 0
;     C is not changed
;     DE is not changed
;     HL is the quotient
;
HL_Div_C:
       ld b,16
       xor a
         add hl,hl
         rla
         cp c
         jr c,$+4
           inc l
           sub c
         djnz $-7
       ret

;
;   COMMAND WRITE ROUTINE 
; 
CMD: 
		PUSH AF 
CMD1:           IN A, (CMDP) 
		AND 03H 
		CP 03H  		; STATUS CHECK 
		JR NZ, CMD1 
		POP AF 
		OUT (CMDP), A  		; WRITE COMMAND 
		RET 
; 
;   DATA WRITE (1 byte) ROUTINE 
; 
DT1:
		PUSH AF 
DT11: 		IN A, (CMDP) 
		AND 03H 
		CP 03H  		; STATUS CHECK 
		JR NZ, DT11 
		POP AF 
		OUT (DP), A  		; WRITE DATA 
		RET 
; 
; DATA WRITE (2 byte) ROUTINE 
; 
DT2: 
		IN A, (CMDP) 
		AND 03H 
		CP 03H  		; STATUS CHECK 
		JR NZ, DT2 
		LD A, L 
		OUT (DP), A  		; WRITE DATA (D1) 
DT21: 
		IN A, (CMDP) 
		AND 03H 
		CP 03H  		; STATUS CHECK 
		JR NZ, DT21 

		LD A, H 
		OUT (DP), A  		; WRITE DATA (D2) 
		RET 
; 
;   AUTO WRITE MODE ROUTINE 
;  
ADT: 
		PUSH AF 
ADT1: 		IN A, (CMDP) 
		AND 08H 
		CP 08H  		; STATUS CHECK 
		JR NZ, ADT1 
		POP AF 
		OUT (DP), A  		; WRITE DATA 
		RET 
		
; 
;   AUTO READMODE ROUTINE 
;  
ARD: 
		PUSH AF 
ARD1: 		IN A, (CMDP) 
		AND 04H 		; STA2 mask
		CP 04H  		; STATUS CHECK 
		JR NZ, ARD1 
		POP AF 
;		OUT (DP), A  		; WRITE DATA 
		IN  A,(DP)		; read data
		RET 

; 
;   READ TEXT buffer, LCD addr in HL
;
READBUFFER:	
;		LD HL, _TH+TL1  	; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 

;		LD A, AWRON  		; SET DATA AUTO WRITE 
		LD A, ARDON  		; SET DATA AUTO read
		CALL CMD 

		LD B, 64  		; n Character 
		LD DE, TXBUF 		; line buffer
RXLP1: 
		LD A, (DE)  		; read DATA 
		CALL ARD 
		ADD a,32			; to ascii
		ld (de),a		; store data

		INC DE 
		DJNZ RXLP1 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD
		ret

; 
;   WRITE TEXT buffer, LCD addr in HL
;
WRITEBUFFER:
;		LD HL, _TH
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

		LD B, 64  		;  Character 
		LD DE, TXBUF 
TXLP7: 
		LD A, (DE)  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd
		CALL ADT 
		INC DE 
		DJNZ TXLP7 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 
		ret
		
; 
;   WRITE TEXT buffer, LCD addr in HL
;
WRITEBLANKS:
;		LD HL, _TH
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

		LD B, 64  		;  Character 
		LD DE, TXBUF 
TXLP8: 
		LD A, ' '  		; WRITE DATA 
                SUB 	32          	; from ascii to lcd
		CALL ADT 
		INC DE 
		DJNZ TXLP8 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 
		ret
		
;
; write attribute
;
T6963_PUTA:
                push af

 		push 	hl		  ; set attr address
		ld    	HL, (T6963_ATR)
		call 	T6963_POS
		pop 	hl
		
;                PUSH 	AF
                CALL 	DT1                
                LD A, 	DATAWR    	; write character
                CALL    CMD
                POP     AF  

 		push 	hl		  ; bump addr
		ld    	HL, (T6963_ATR)
    		ld    	e, 1    ; DE = A
    		ld    	d, 0
    		add   	hl, de  ; HL = HL+DE
		ld 	(T6963_ATR),HL
		call 	T6963_POS
		pop 	hl

				
		RET 
;
; write data
;
T6963_PUTC:
                CP     $0A                ; line feed, bump row
                JR     Z, T6963_LF
                CP     $0D                ; cariage return, clear col
                JR     Z, T6963_CR
; now write attribute

#if 1
                push af
                push hl
; set addr
		ld    	HL, (T6963_ADR)
		ld      bc, _AH
		add     HL, bc
		CALL DT2 
		LD A, ADPSET    ; set
		CALL CMD 
		
                ld      A,(CLCD_ATTR)   ; reverse
		AND     04H 
		CP      04H  
		JR      NZ, CP12 
		ld      A,05H
                jr      CP15
                
CP12:           ld      A,(CLCD_ATTR)   ; blink
		AND     01H 
		CP      01H  
		JR      NZ, CP13 
		ld      A,08H
		jr      CP15

CP13:           ld      A,(CLCD_COLOR)   ; bold
		AND     08H 
		CP      08H  
		JR      NZ, CP14 
		ld      A,0dH
		jr      CP15

CP14:           ld      A,0  
CP15:
                
; write attribute
                CALL 	DT1                
                LD A, 	DATAWR    	; write character
                CALL    CMD
                
		ld    	HL, (T6963_ADR)
		CALL DT2 
		LD A, ADPSET    ; set
		CALL CMD 

                pop hl
                pop af
#endif

T6963_PUTC_RAW
                PUSH 	AF
                SUB 	32          ; from ascii to lcd
                CALL 	DT1                
                LD A, 	DATAWR    	; write character
                CALL    CMD
                POP     AF  

; bump cursor
 		push 	hl		  ; bump addr
		ld    	HL, (T6963_ADR)
    		ld    	e, 1    ; DE = A
    		ld    	d, 0
    		add   	hl, de  ; HL = HL+DE
		ld 	(T6963_ADR),HL
		call 	T6963_POS
		pop 	hl



    
		RET 
		
T6963_LF:
 		push 	hl
		ld    	HL, (T6963_ADR)
    		ld    	e, 64    ; DE = A
    		ld    	d, 0
    		add   	hl, de  ; HL = HL+DE
		ld 	(T6963_ADR),HL
		call 	T6963_POS
		pop 	hl
;		call 	T6963_CR	; implicit cr when lf received
                RET           

T6963_CR:
 		push 	hl
		ld    	HL, (T6963_ADR)
		ld 	A,0C0H
		and     L
		ld	L,A
		ld 	(T6963_ADR),HL
		call 	T6963_POS
		pop 	hl
;		call 	T6963_LF	; implicit lf when cr received
                RET


T6963_NEWLINE:
                call    T6963_CR
                call    T6963_LF
                ret

T6963_POSITION:	
		; in: row in d, col in e
		; out: pos in hl
		
		LD	A,E			; SAVE COLUMN NUMBER IN A
		LD	H,D			; SET H TO ROW NUMBER
		LD	E,64			; SET E TO ROW LENGTH
		CALL	MULT8			; MULTIPLY TO GET ROW OFFSET
		LD	E,A			; GET COLUMN BACK
		ADD	HL,DE			; ADD IT IN
				
		ld 	(T6963_ADR),HL
;                CALL T6963_POS

T6963_POS:      				;          
		push af
                push HL                         
		CALL DT2 
		LD A, ADPSET    ; set
		CALL CMD 
; mask to 6 bits
		ld	a,l
		and	3fh
		call	DT1

		pop HL
; shift right 6 bits		
  XOR A
  ADD HL, HL
  RLA
  ADD HL, HL
  RLA
  LD L, H
  LD H, A	
	ld a,l
		CALL 	DT1 
		LD A, CURSOR    ; set
		CALL CMD 
		pop af
		ret

;----------------------------------------------------------------------
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING AT THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
; ** todo ** just clears text screen at present
T6963_FILL
; 
;   WRITE TEXT BLANK CODE 
; 
		LD HL, _TH  		; SET Address Pointer 0000H 
		CALL DT2  		; (TEXT HOME ADDRESS) 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE
		CALL CMD  		; 

		LD BC, 400H  		; 64 (40 visible) Columns × 16 Lines = 400H (640 = 280H) 
TXCR: 
		LD A, 00H  		; WRITE DATA 00H 
		CALL ADT  		; (WRITE BLANK CODE) 

		DEC BC 
		LD A, B 
		OR C 
		JR NZ, TXCR 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 
		RET



T6963_CLEAR:		; clear text and graphics screens, home cursor	
		CALL	T6963_FILL
;
;   WRITE Graphics BLANK CODE 
; 
		LD HL, _GH  		; SET Address Pointer 0000H 
		CALL DT2  		; (TEXT HOME ADDRESS) 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE
		CALL CMD  		; 

		LD BC, 1C00H  		; 
GXCR: 
		LD A, 0H  		; WRITE DATA 00H 
		CALL ADT  		; (WRITE BLANK CODE) 

		DEC BC 
		LD A, B 
		OR C 
		JR NZ, GXCR 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 
                RET
;
; home cursor and return
;
T6963_HOME:
		ld    	HL, 0H
		ld 	(T6963_ADR),HL
                CALL T6963_POS
 		RET


T6963_SCROLL


#if 1
; scroll attributes 
		LD HL, SCROLL_ATTR+40H 
		call READBUFFER
		LD HL, SCROLL_ATTR+0h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+80H 
		call READBUFFER
		LD HL, SCROLL_ATTR+40h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+0C0H 
		call READBUFFER
		LD HL, SCROLL_ATTR+80h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+100H 
		call READBUFFER
		LD HL, SCROLL_ATTR+0C0H
		call WRITEBUFFER


		LD HL, SCROLL_ATTR+140H 
		call READBUFFER
		LD HL, SCROLL_ATTR+100h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+180H 
		call READBUFFER
		LD HL, SCROLL_ATTR+140h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+1c0H 
		call READBUFFER
		LD HL, SCROLL_ATTR+180h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+200H 
		call READBUFFER
		LD HL, SCROLL_ATTR+1c0h
		call WRITEBUFFER


		LD HL, SCROLL_ATTR+240H 
		call READBUFFER
		LD HL, SCROLL_ATTR+200h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+280H 
		call READBUFFER
		LD HL, SCROLL_ATTR+240h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+2c0H 
		call READBUFFER
		LD HL, SCROLL_ATTR+280h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+300H 
		call READBUFFER
		LD HL, SCROLL_ATTR+2c0h
		call WRITEBUFFER


		LD HL, SCROLL_ATTR+340H 
		call READBUFFER
		LD HL, SCROLL_ATTR+300h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+380H 
		call READBUFFER
		LD HL, SCROLL_ATTR+340h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+3c0H 
		call READBUFFER
		LD HL, SCROLL_ATTR+380h
		call WRITEBUFFER

		LD HL, SCROLL_ATTR+3c0h
		call WRITEBLANKS

		LD HL, SCROLL_ATTR+3c0h			; set cursor
		ld 	(T6963_ADR),HL
                CALL T6963_POS
#endif

; scroll text 
		LD HL, SCROLL_TEXT+40H 
		call READBUFFER
		LD HL, SCROLL_TEXT+0h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+80H 
		call READBUFFER
		LD HL, SCROLL_TEXT+40h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+0C0H 
		call READBUFFER
		LD HL, SCROLL_TEXT+80h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+100H 
		call READBUFFER
		LD HL, SCROLL_TEXT+0C0H
		call WRITEBUFFER


		LD HL, SCROLL_TEXT+140H 
		call READBUFFER
		LD HL, SCROLL_TEXT+100h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+180H 
		call READBUFFER
		LD HL, SCROLL_TEXT+140h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+1c0H 
		call READBUFFER
		LD HL, SCROLL_TEXT+180h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+200H 
		call READBUFFER
		LD HL, SCROLL_TEXT+1c0h
		call WRITEBUFFER


		LD HL, SCROLL_TEXT+240H 
		call READBUFFER
		LD HL, SCROLL_TEXT+200h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+280H 
		call READBUFFER
		LD HL, SCROLL_TEXT+240h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+2c0H 
		call READBUFFER
		LD HL, SCROLL_TEXT+280h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+300H 
		call READBUFFER
		LD HL, SCROLL_TEXT+2c0h
		call WRITEBUFFER


		LD HL, SCROLL_TEXT+340H 
		call READBUFFER
		LD HL, SCROLL_TEXT+300h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+380H 
		call READBUFFER
		LD HL, SCROLL_TEXT+340h
		call WRITEBUFFER

		LD HL, SCROLL_TEXT+3c0H 
		call READBUFFER
		LD HL, SCROLL_TEXT+380h
		call WRITEBUFFER

;		LD HL, 100H 
;		call READBUFFER
;		LD HL, c0h
;		call WRITEBUFFER

		LD HL, SCROLL_TEXT+3c0h
		call WRITEBLANKS

		LD HL, SCROLL_TEXT+3c0h			; set cursor
		ld 	(T6963_ADR),HL
                CALL T6963_POS

		ret
		
;
; Subroutine end
;

;
; working data
;
T6963_ROW:      .DB     0
T6963_COL       .DB     0
T6963_ADR       .DW     _TH
T6963_ATR       .DW     _AH

;
;	EXTERNAL CG FONT DATA
;
EXTCG:

;
; 48 box drawing characters
;
;//    .DB    086H, 000H, 086H, 000H, 030H, 0c0H, 030H, 0c0H
;//    .DB    0b6H, 0c0H, 049H, 020H, 049H, 020H, 0b6H, 0c0H
;//    .DB    079H, 0e0H, 079H, 0e0H, 0cfH, 020H, 0cfH, 020H

        .DB    00cH, 00cH, 021H, 021H, 00cH, 00cH, 000H, 021H
        .DB    02dH, 0d2H, 0d2H, 02dH, 0d2H, 0d2H, 02dH, 0d2H
        .DB    0f3H, 0f3H, 0deH, 0deH, 0f3H, 0f3H, 0deH, 0deH
    
    .DB    010H, 010H, 010H, 010H, 010H, 010H, 010H, 010H
    .DB    010H, 010H, 010H, 010H, 0f0H, 010H, 010H, 010H
    .DB    010H, 010H, 0f0H, 0f0H, 010H, 0f0H, 0f0H, 010H
    .DB    02cH, 02cH, 02cH, 02cH, 0ecH, 02cH, 02cH, 02cH
    .DB    000H, 000H, 000H, 000H, 0fcH, 02cH, 02cH, 02cH
    .DB    000H, 000H, 0f0H, 0f0H, 010H, 0f0H, 0f0H, 010H
    .DB    02cH, 02cH, 0ecH, 0ecH, 00cH, 0ecH, 0ecH, 02cH
    .DB    02cH, 02cH, 02cH, 02cH, 02cH, 02cH, 02cH, 02cH
    .DB    000H, 000H, 0fcH, 0fcH, 00cH, 0ecH, 0ecH, 02cH
    .DB    02cH, 02cH, 0ecH, 0ecH, 00cH, 0fcH, 0fcH, 000H
    .DB    02cH, 02cH, 02cH, 02cH, 0fcH, 000H, 000H, 000H
    .DB    010H, 010H, 0f0H, 0f0H, 010H, 0f0H, 0f0H, 000H
    .DB    000H, 000H, 000H, 000H, 0f0H, 010H, 010H, 010H
    .DB    010H, 010H, 010H, 010H, 01fH, 000H, 000H, 000H
    .DB    010H, 010H, 010H, 010H, 0ffH, 000H, 000H, 000H
    .DB    000H, 000H, 000H, 000H, 0ffH, 010H, 010H, 010H
    .DB    010H, 010H, 010H, 010H, 01fH, 010H, 010H, 010H
    .DB    000H, 000H, 000H, 000H, 0ffH, 000H, 000H, 000H
    .DB    010H, 010H, 010H, 010H, 0ffH, 010H, 010H, 010H
    .DB    010H, 010H, 01fH, 01fH, 010H, 01fH, 01fH, 010H
    .DB    02cH, 02cH, 02cH, 02cH, 02fH, 02cH, 02cH, 02cH
    .DB    02cH, 02cH, 02fH, 02fH, 020H, 03fH, 03fH, 000H
    .DB    000H, 000H, 03fH, 03fH, 020H, 02fH, 02fH, 02cH
    .DB    02cH, 02cH, 0efH, 0efH, 000H, 0ffH, 0ffH, 000H
    .DB    000H, 000H, 0ffH, 0ffH, 000H, 0efH, 0efH, 02cH
    .DB    02cH, 02cH, 02fH, 02fH, 020H, 02fH, 02fH, 02cH
    .DB    000H, 000H, 0ffH, 0ffH, 000H, 0ffH, 0ffH, 000H
    .DB    02cH, 02cH, 0efH, 0efH, 000H, 0efH, 0efH, 02cH
    .DB    010H, 010H, 0ffH, 0ffH, 000H, 0ffH, 0ffH, 000H
    .DB    02cH, 02cH, 02cH, 02cH, 0ffH, 000H, 000H, 000H
    .DB    000H, 000H, 0ffH, 0ffH, 000H, 0ffH, 0ffH, 010H
    .DB    000H, 000H, 000H, 000H, 0ffH, 02cH, 02cH, 02cH
    .DB    02cH, 02cH, 02cH, 02cH, 03fH, 000H, 000H, 000H
    .DB    010H, 010H, 01fH, 01fH, 010H, 01fH, 01fH, 000H
    .DB    000H, 000H, 01fH, 01fH, 010H, 01fH, 01fH, 010H
    .DB    000H, 000H, 000H, 000H, 03fH, 02cH, 02cH, 02cH
    .DB    02cH, 02cH, 02cH, 02cH, 0ffH, 02cH, 02cH, 02cH
    .DB    010H, 010H, 0ffH, 0ffH, 010H, 0ffH, 0ffH, 010H
    .DB    010H, 010H, 010H, 010H, 0f0H, 000H, 000H, 000H
    .DB    000H, 000H, 000H, 000H, 01fH, 010H, 010H, 010H
    
        .DB    0ffH, 0ffH, 0ffH, 0ffH, 0ffH, 0ffH, 0ffH, 0ffH
        .DB    000H, 000H, 000H, 000H, 0ffH, 0ffH, 0ffH, 0ffH
        .DB    0f0H, 0f0H, 0f0H, 0f0H, 0f0H, 0f0H, 0f0H, 0f0H
        .DB    00fH, 00fH, 00fH, 00fH, 00fH, 00fH, 00fH, 00fH
        .DB    0ffH, 0ffH, 0ffH, 0ffH, 000H, 000H, 000H, 000H
    
;//    .DB    0ffH, 0e0H, 0ffH, 0e0H, 0ffH, 0e0H, 0ffH, 0e0H
;//    .DB    000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
;//    .DB    0f8H, 000H, 0f8H, 000H, 0f8H, 000H, 0f8H, 000H
;//    .DB    007H, 0e0H, 007H, 0e0H, 007H, 0e0H, 007H, 0e0H
;//    .DB    0ffH, 0e0H, 0ffH, 0e0H, 0ffH, 0e0H, 0ffH, 0e0H
        
DJRM1:
                .DB     0c9H, 0cdH, 0cdH, 0cdH, 0cdH, 0bbH
                .DB     0baH, 'D',  'J',  'R',  'M',  0baH
                .DB     0ccH, 0cdH, 0cdH, 0cdH, 0cdH, 0B9H
                .DB     0baH, '2',  '0',  '2',  '3',  0baH
                .DB     0c8H, 0cdH, 0cdH, 0cdH, 0cdH, 0bcH

DJRM2:
                .DB     000H, 008H, 008H, 008H, 008H, 000H
                .DB     000H, 005H, 005H, 005H, 005H, 000H


;
;
; line buffer
;
TXBUF:
		.DB	"The quick brown fox jumps over the lazy_dog."
;		.DB	"Now is the time for all good me to come to the aid of the party." 
;		.DS	64
;		.END

