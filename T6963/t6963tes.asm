;	     	T6963C SAMPLE PROGRAM V0.01 
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
BITRES 		.EQU 0F0H 		; Bit RESET
BITSET 		.EQU 0F8H 		; Bit SET
CMDP 		.EQU 01H 		; CMD PORT 
DP 		.EQU 00H 		; DATA PORT 

TL1             .EQU 10CH
TL2             .EQU 190H
TL3             .EQU 1D0H

; 16 x 40 @ 8x8

LCD_XWIDTH              .EQU 240
LCD_YHEIGHT             .EQU 128
LCD_KBYTES              .EQU 8

LCD_WIDTH               .EQU 48
LCD_HEIGHT              .EQU 16 


_TH                  .EQU 0
_TA                  .EQU 40H    ; 40 rounded to next multiple of 16, 64
_GH                  .EQU 400H
_GA                  .EQU 400H



;STACK 		.EQU 9FFFH 		; STACK POINTER BASE ADDRESS 
; 
                .ORG 0100H 
START: 
;              	LD SP, STACK 
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
;   SET OFFSET REGISTER (00010 10000000 000 = 1400H CG RAM START ADDRESS) 
;      					CHARACTER CODE 80H 
		LD HL, 0002H 
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
		LD A,80H 
		CALL CMD 

		CALL	T6963_CLEAR	; clear text and graphic screens, home cursor

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

		LD B, 40H  		; 8 Character × 8 byte (64 = 40H) 
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
		LD HL, _TH+TL2		; Address Pointer 5 Line, 8 Column 
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
		LD HL, _TH+TL3  		; Address Pointer 6 Line, 8 Column 
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
		LD HL, _TH+TL1  		; Address Pointer 3 Line, 4 Column 
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

		ld    	HL, 0H
		ld 	(T6963_ADR),HL
                CALL T6963_POS
;-----------------------------------------------------------------------------
;
; read test buffer
;


;		ret
                
                ld a,'d'
                call T6963_PUTC
                ld a,'j'
                call T6963_PUTC
                ld a,'r'
                call T6963_PUTC
                ld a,'m'
                call T6963_PUTC
;	ret
                ld a,0DH
                call T6963_PUTC
                ld a,0AH
                call T6963_PUTC

                ld a,'1'
                call T6963_PUTC
                ld a,'2'
                call T6963_PUTC
                ld a,'3'
                call T6963_PUTC
                ld a,'4'
                call T6963_PUTC

                ld a,0DH
                call T6963_PUTC
                ld a,0AH
                call T6963_PUTC

                ld a,'A'
                call T6963_PUTC
                ld a,'B'
                call T6963_PUTC
                ld a,'C'
                call T6963_PUTC
                ld a,'D'
                call T6963_PUTC


		LD HL, 3c0H
		call WRITEBUFFER
		call T6963_SCROLL

		
PEND: 
                ret
		JP PEND  		; PROGRAM END 
; 
; Subroutine start 
; 

; MULTIPLY 8-BIT VALUES
; IN:  MULTIPLY H BY E
; OUT: HL = RESULT, E = 0, B = 0
;
MULT8:
	LD D,0
	LD L,D
	LD B,8
MULT8_LOOP:
	ADD HL,HL
	JR NC,MULT8_NOADD
	ADD HL,DE
MULT8_NOADD:
	DJNZ MULT8_LOOP
	RET

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
; write data
;
T6963_PUTC:
                CP     	$0A                ; line feed, bump row
                JR     	Z, T6963_LF
                CP     	$0D                ; cariage return, clear col
                JR     	Z, T6963_CR


T6963_PUTC_RAW
                PUSH 	AF
                SUB 	32          	; from ascii to lcd
                CALL 	DT1                
                LD A, 	DATAWR    	; write character
                CALL    CMD	
                POP     AF  

 		push 	hl		; bump addr
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
		push 	af
                push 	HL                         
		CALL 	DT2 
		LD 	A, ADPSET    ; set
		CALL 	CMD 
; mask to 6 bits
		ld	a,l
		and	3fh
		call	DT1

		pop 	HL
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
		LD 	A, CURSOR    ; set
		CALL 	CMD 
		pop 	af
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

		LD BC, 0100H  		; 
GXCR: 
		LD A, 0H  		; WRITE DATA 00H 
		CALL ADT  		; (WRITE BLANK CODE) 

		DEC BC 
		LD A, B 
		OR C 
		JR NZ, GXCR 

		LD A, AWROFF  		; AUTO RESET 
		CALL CMD 

;
; home cursor and return
;
		ld    	HL, 0H
		ld 	(T6963_ADR),HL
                CALL T6963_POS
;
 		RET


T6963_SCROLL


		LD HL, 40H 
		call READBUFFER
		LD HL, 0h
		call WRITEBUFFER

		LD HL, 80H 
		call READBUFFER
		LD HL, 40h
		call WRITEBUFFER

		LD HL, 0C0H 
		call READBUFFER
		LD HL, 80h
		call WRITEBUFFER

		LD HL, 100H 
		call READBUFFER
		LD HL, 0C0H
		call WRITEBUFFER


		LD HL, 140H 
		call READBUFFER
		LD HL, 100h
		call WRITEBUFFER

		LD HL, 180H 
		call READBUFFER
		LD HL, 140h
		call WRITEBUFFER

		LD HL, 1c0H 
		call READBUFFER
		LD HL, 180h
		call WRITEBUFFER

		LD HL, 200H 
		call READBUFFER
		LD HL, 1c0h
		call WRITEBUFFER


		LD HL, 240H 
		call READBUFFER
		LD HL, 200h
		call WRITEBUFFER

		LD HL, 280H 
		call READBUFFER
		LD HL, 240h
		call WRITEBUFFER

		LD HL, 2c0H 
		call READBUFFER
		LD HL, 280h
		call WRITEBUFFER

		LD HL, 300H 
		call READBUFFER
		LD HL, 2c0h
		call WRITEBUFFER


		LD HL, 340H 
		call READBUFFER
		LD HL, 300h
		call WRITEBUFFER

		LD HL, 380H 
		call READBUFFER
		LD HL, 340h
		call WRITEBUFFER

		LD HL, 3c0H 
		call READBUFFER
		LD HL, 380h
		call WRITEBUFFER

;		LD HL, 100H 
;		call READBUFFER
;		LD HL, c0h
;		call WRITEBUFFER

		LD HL, 3c0h
		call WRITEBLANKS

;		LD HL, 3c0h			; set cursor
;		ld 	(T6963_ADR),HL
;                CALL T6963_POS

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

;	TEXT DISPLAY CHARACTER CODE
;
TXPRT:
		.DB	34H, 000H, 02FH, 000H, 033H, 000H		; INTERNAL CG CODE "T O S H I B A"
		.DB	28H, 000H, 029H, 000H, 022H, 000H, 021H


DJRM:          .DB     24H,2AH,32H,2DH

EXPRT1:
		.DB	80H, 081H, 000H, 000H, 084H, 085H		; EXTERNAL CG CODE (semi graphic)
EXPRT2:
		.DB	82H, 083H, 000H, 000H, 086H, 087H
;
;	EXTERNAL CG FONT DATA
;
EXTCG:

;
; 29 box drawing characters
;
        .DB    000H, 000H, 000H, 0ffH, 0ffH, 000H, 000H, 000H
        .DB    018H, 018H, 018H, 018H, 018H, 018H, 018H, 018H
        .DB    000H, 000H, 000H, 00fH, 00fH, 008H, 008H, 008H
        .DB    000H, 000H, 000H, 000H, 01fH, 018H, 018H, 018H
        .DB    000H, 000H, 000H, 01fH, 01fH, 018H, 018H, 018H
        .DB    000H, 000H, 000H, 0f0H, 0f0H, 010H, 010H, 010H
        .DB    000H, 000H, 000H, 000H, 0f8H, 018H, 018H, 018H
        .DB    000H, 000H, 000H, 0f8H, 0f8H, 018H, 018H, 018H
        .DB    008H, 008H, 008H, 00fH, 00fH, 000H, 000H, 000H
        .DB    018H, 018H, 018H, 018H, 01fH, 000H, 000H, 000H
        .DB    018H, 018H, 018H, 01fH, 01fH, 000H, 000H, 000H
        .DB    010H, 010H, 010H, 0f0H, 0f0H, 000H, 000H, 000H
        .DB    018H, 018H, 018H, 018H, 0f8H, 000H, 000H, 000H
        .DB    018H, 018H, 018H, 0f8H, 0f8H, 000H, 000H, 000H
        .DB    008H, 008H, 008H, 00fH, 00fH, 008H, 008H, 008H
        .DB    018H, 018H, 018H, 018H, 01fH, 018H, 018H, 018H
        .DB    018H, 018H, 018H, 01fH, 01fH, 018H, 018H, 018H
        .DB    010H, 010H, 010H, 0f0H, 0f0H, 010H, 010H, 010H
        .DB    018H, 018H, 018H, 018H, 0f8H, 018H, 018H, 018H
        .DB    018H, 018H, 018H, 0f8H, 0f8H, 018H, 018H, 018H
        .DB    000H, 000H, 000H, 0ffH, 0ffH, 010H, 010H, 010H
        .DB    000H, 000H, 000H, 000H, 0ffH, 018H, 018H, 018H
        .DB    000H, 000H, 000H, 0ffH, 0ffH, 018H, 018H, 018H
        .DB    010H, 010H, 010H, 0ffH, 0ffH, 000H, 000H, 000H
        .DB    018H, 018H, 018H, 018H, 0ffH, 000H, 000H, 000H
        .DB    018H, 018H, 018H, 0ffH, 0ffH, 000H, 000H, 000H
        .DB    010H, 010H, 010H, 0ffH, 0ffH, 010H, 010H, 010H
        .DB    018H, 018H, 018H, 018H, 0ffH, 018H, 018H, 018H
        .DB    018H, 018H, 018H, 0ffH, 0ffH, 018H, 018H, 018H

;        
; TOSHIBA glyphs
;
; upper / left CHARACTER CODE 80H
		.DB	01H, 001H, 00FFH, 001H, 03FH, 021H, 03FH, 021H

; upper / right CHARACTER CODE 81H
		.DB	00H, 000H, 00FFH, 000H, 00FCH, 004H, 00FCH, 004H

; lower/left CHARACTER CODE 82H
		.DB	21H, 03FH, 005H, 00DH, 019H, 031H, 00E1H, 001H

; lower/right CHARACTER CODE 83H
		.DB	04H, 00FCH, 040H, 060H, 030H, 01CH, 007H, 000H

; upper/left CHARACTER CODE 84H
		.DB	08H, 008H, 00FFH, 008H, 009H, 001H, 001H, 07FH

; upper/right CHARACTER CODE 85H
		.DB	10H, 010H, 00FFH, 010H, 010H, 000H, 000H, 00FCH

; lower/left CHARACTER CODE 86H
		.DB	00H, 000H, 000H, 001H, 007H, 03CH, 00E7H, 000H

; lower/right CHARACTER CODE 87H
		.DB	18H, 030H, 060H, 00C0H, 000H, 000H, 00E0H, 03FH
;
;
; line buffer
;
TXBUF:
		.DB	"The quick brown fox jumps over the lazy_dog."
;		.DB	"Now is the time for all good me to come to the aid of the party." 
;		.DS	64
		.END

