;	     	T6963C SAMPLE PROGRAM V0.01 
; 
;		SOURCE PROGRAM for TMPZ84C00P 
;			1991 - 2 -15 
;	      	Display Size: 20 Column � 8 Lines 
; 
;	      	Character Font: 8 Dots Mode 
; 
TXHOME 		EQU 40H 		; SET TXT HM ADD 
TXAREA 		EQU 41H 		; SET TXT AREA 
GRHOME 		EQU 42H 		; SET GR HM ADD 
GRAREA 		EQU 43H 		; SET GR AREA 
CURSOR          EQU 21H                 ; cursor pointer
OFFSET 		EQU 22H 		; SET OFFSET ADD 
ADPSET 		EQU 24H 		; SET ADD PTR 
AWRON 		EQU 0B0H 		; SET AUTO WRITE MODE 
AWROFF 		EQU 0B2H 		; RESET AUTO WRITE MODE  
DATAWR          EQU 0C0H                ; data write, address unchanged
CMDP 		EQU 01H 		; CMD PORT 
DP 		EQU 00H 		; DATA PORT 

; 16 x 40 @ 8x8

LCD_XWIDTH              EQU 240
LCD_YHEIGHT             EQU 128
LCD_KBYTES              EQU 8

LCD_WIDTH               EQU 40
LCD_HEIGHT              EQU 16 


_TH                  EQU 0
_TA                  EQU 40
_GH                  EQU 280H
_GA                  EQU 40



;STACK 		EQU 9FFFH 		; STACK POINTER BASE ADDRESS 
; 
                ORG 0100H 
START: 
;              	LD SP, STACK 
; 
;   SET GRAPHIC HOME ADDRESS 
; 
		LD HL, _GH   		; GRAPHIC HOME ADDRESS 0200H 
		CALL DT2 
		LD A, GRHOME 
		CALL CMD 
; 
;   SET GRAPHIC AREA 
; 
		 LD HL, _GA  		; GRAPHIC AREA 20 Columns 
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
		 LD HL, _TA  		; TEXT AREA 20 Columns 
		 CALL DT2 
		 LD A, TXAREA 
		 CALL CMD 
; 
;   SET OFFSET REGISTER (00010 10000000 000 = 1400H CG RAM START ADDRESS) 
;      					CHARACTER CODE 80H 
		LD HL, 0002H 
		CALL DT2 
		LD A, OFFSET 
		CALL CMD 
; 
;   DISPLAY MODE 
;   (TEXT ON, GRAPHICS OFF, CURSOR OFF) 
; 
		LD A, 97H 
		CALL CMD 
;
; cursor
;
                ld a,0a1h
                call CMD				
; 
;   MODE SET (OR MODE, Internal Character Generator MODE) 
; 
		LD A,80H 
		CALL CMD 
; 
;   WRITE TEXT DISPLAY DATA (INTERNAL CG) DJRM
;
		LD HL, _TH+600+36  
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

		LD B, 4  		; 13 Character 
		LD DE, DJRM 
TXLP4: 
		LD A, (DE)  		; WRITE DATA 
		CALL ADT 
		INC DE 
		DJNZ TXLP4 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 
; 
;   WRITE TEXT BLANK CODE 
; 
		LD HL, _TH  		; SET Address Pointer 0000H 
		CALL DT2  		; (TEXT HOME ADDRESS) 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE
		CALL CMD  		; 

		LD BC, 280H  		; 40 Columns � 16 Lines (640 = 280H) 
TXCR: 
		LD A, 00H  		; WRITE DATA 00H 
		CALL ADT  		; (WRITE BLANK CODE) 

		DEC BC 
		LD A, B 
		OR C 
		JR NZ, TXCR 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

; 
;   WRITE EXTERNAL CHARACTER GENERATOR DATA 
; 
		LD DE, EXTCG  		; CG data address in Program 
		LD HL, 1400H  		; CG RAM Start Address (1400H) 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 
; 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

		LD B, 40H  		; 8 Character � 8 byte (64 = 40H) 
EXCG: 
		LD A, (DE)  		; WRITE DATA TO EXTERNAL RAM 
		CALL ADT  		; 
		INC HL 
		INC DE 
		DJNZ EXCG 

		LD A, AWROFF  		; AUTO RESET 
		CALL  CMD 
; 
;   WRITE TEXT DISPLAY DATA (EXTERNAL CG upper part) 
; 
		LD HL, _TH+80+98 		; Address Pointer 5 Line, 8 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

		LD B, 06H  		; 6 Character 
		LD DE, EXPRT1 
TXLP2: 
		LD A, (DE)  		; WRITE DATA 
		CALL ADT 
		INC DE 
		DJNZ TXLP2 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 
; 
;   WRITE TEXT DISPLAY DATA (EXTERNAL CG lower part) 
; 
		LD HL, _TH+120+98  		; Address Pointer 6 Line, 8 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

		LD B, 06H  		; 6 Character 
		LD DE, EXPRT2 
TXLP3: 
		LD A, (DE)  		; WRITE DATA 
		CALL ADT 
		INC DE 
		DJNZ TXLP3 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

; 
;   WRITE TEXT DISPLAY DATA (INTERNAL CG) 
;
		LD HL, _TH+94  		; Address Pointer 3 Line, 4 Column 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 

		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

		LD B, 0DH  		; 13 Character 
		LD DE, TXPRT 
TXLP1: 
		LD A, (DE)  		; WRITE DATA 
		CALL ADT 
		INC DE 
		DJNZ TXLP1 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

                
		LD HL, _TH+4    ; addr
		CALL DT2 
		LD A, ADPSET    ; set
		CALL CMD 

		LD HL, _TH+4    ; addr
		CALL DT2 
		LD A, CURSOR    ; set
		CALL CMD 
                
                LD A, 033H
                CALL T6_PUTC
                
                LD A, 034H
                CALL DT1                
                LD A, DATAWR    ; write
                CALL CMD
		
PEND: 
                ret
		JP PEND  		; PROGRAM END 
; 
; Subroutine start 
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
; write data
;
T6_PUTC:
                PUSH AF
                CALL DT1                
                LD A, DATAWR    ; write
                CALL    CMD
                POP     AF      
		RET 
		
		
;
; Subroutine end
;
;	TEXT DISPLAY CHARACTER CODE
;
TXPRT:
		DEFB	34H, 00H, 2FH, 00H, 33H, 00H		; INTERNAL CG CODE "T O S H I B A"
		DEFB	28H, 00H, 29H, 00H, 22H, 00H, 21H


DJRM:          DEFB     24H,2AH,32H,2DH

EXPRT1:
		DEFB	80H, 81H, 00H, 00H, 84H, 85H		; EXTERNAL CG CODE (semi graphic)
EXPRT2:
		DEFB	82H, 83H, 00H, 00H, 86H, 87H
;
;	EXTERNAL CG FONT DATA
;
EXTCG:
;
; upper / left CHARACTER CODE 80H
		DEFB	01H, 01H, 0FFH, 01H, 3FH, 21H, 3FH, 21H

; upper / right CHARACTER CODE 81H
		DEFB	00H, 00H, 0FFH, 00H, 0FCH, 04H, 0FCH, 04H

; lower/left CHARACTER CODE 82H
		DEFB	21H, 3FH, 05H, 0DH, 19H, 31H, 0E1H, 01H

; lower/right CHARACTER CODE 83H
		DEFB	04H, 0FCH, 40H, 60H, 30H, 1CH, 07H, 00H

; upper/left CHARACTER CODE 84H
		DEFB	08H, 08H, 0FFH, 08H, 09H, 01H, 01H, 7FH

; upper/right CHARACTER CODE 85H
		DEFB	10H, 10H, 0FFH, 10H, 10H, 00H, 00H, 0FCH

; lower/left CHARACTER CODE 86H
		DEFB	00H, 00H, 00H, 01H, 07H, 3CH, 0E7H, 00H

; lower/right CHARACTER CODE 87H
		DEFB	18H, 30H, 60H, 0C0H, 00H, 00H, 0E0H, 3FH
;
		END

