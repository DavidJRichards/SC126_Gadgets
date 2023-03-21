;STACK 		.EQU 9FFFH 		; STACK POINTER BASE ADDRESS 
; 


                .ORG 0100H 
                call T6963_INIT
;-----------------------------------------------------------------------------
;
; read test buffer
;

                call T6963_HOME
                
                ld a,'d'
                call T6963_PUTC
                ld a,'j'
                call T6963_PUTC
                ld a,'r'
                call T6963_PUTC
                ld a,'m'
                call T6963_PUTC
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
;		call T6963_SCROLL

;                call T6963_CLEAR
;                call T6963_HOME
#if 1
; 
;   WRITE EXTERNAL CHARACTER GENERATOR DATA 
; 
		LD DE, TEST_CG  		; CG data address in Program 
		LD HL, _CG_STARTADDRESS + 500H  		; CG RAM Start Address (1c00H) 
		CALL DT2 
		LD A, ADPSET 
		CALL CMD 
; 
		LD A, AWRON  		; SET DATA AUTO WRITE 
		CALL CMD 

;		LD B, 40H  		; 8 Character × 8 byte (64 = 40H) 
		LD B, 232  		; 29 Character × 8 byte (64 = 40H) 
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
#endif
#if 0
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

;		LD HL, _AH  		; SET Address Pointer 0000H 
;		CALL DT2  		; (TEXT HOME ADDRESS) 
;		LD A, GRHOME 
;		CALL CMD 


;		ld    	HL, 0H
;		ld 	(T6963_ADR),HL
;                CALL T6963_POS
;                CALL T6963_CLEAR
;                CALL T6963_HOME
                
;                ld     de,0202h
;                call    T6963_POSITION
                
                ret                


;-----------------------------------------------------------------------------
                
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

DJRM:          .DB     24H,2AH,32H,2DH

;	TEXT DISPLAY CHARACTER CODE
;
#if 0
DJRM1:
                .DB     0A4H, 0A0H, 0A0H, 0A0H, 0A0H, 0A7H
                .DB     0A1H, 'D',  'J',  'R',  'M',  0A1H
                .DB     0B0H, 0A0H, 0A0H, 0A0H, 0A0H, 0B3H
                .DB     0A1H, '2',  '0',  '2',  '3',  0A1H
                .DB     0AAH, 0A0H, 0A0H, 0A0H, 0A0H, 0ADH

DJRM2:
                .DB     000H, 008H, 008H, 008H, 008H, 000H
                .DB     000H, 00DH, 00DH, 00DH, 00DH, 000H
#endif


TXPRT:
		.DB	34H, 00H, 2FH, 00H, 33H, 00H		; INTERNAL CG CODE "T O S H I B A"
		.DB	28H, 00H, 29H, 00H, 22H, 00H, 21H

EXPRT1:
		.DB	0A0H, 0A1H, 00H, 00H, 0A4H, 0A5H		; EXTERNAL CG CODE (semi graphic)
EXPRT2:
		.DB	0A2H, 0A3H, 00H, 00H, 0A6H, 0A7H
;        
; TOSHIBA glyphs
;
TEST_CG
; upper / left CHARACTER CODE 80H
		.DB	01H, 01H, 0FFH, 01H, 3FH, 21H, 3FH, 21H

; upper / right CHARACTER CODE 81H
		.DB	00H, 00H, 0FFH, 00H, 0FCH, 04H, 0FCH, 04H

; lower/left CHARACTER CODE 82H
		.DB	21H, 3FH, 05H, 0DH, 19H, 31H, 0E1H, 01H

; lower/right CHARACTER CODE 83H
		.DB	04H, 0FCH, 40H, 60H, 30H, 1CH, 07H, 00H

; upper/left CHARACTER CODE 84H
		.DB	08H, 08H, 0FFH, 08H, 09H, 01H, 01H, 7FH

; upper/right CHARACTER CODE 85H
		.DB	10H, 10H, 0FFH, 10H, 10H, 00H, 00H, 0FCH

; lower/left CHARACTER CODE 86H
		.DB	00H, 00H, 00H, 01H, 07H, 3CH, 0E7H, 00H

; lower/right CHARACTER CODE 87H
		.DB	18H, 30H, 60H, 0C0H, 00H, 00H, 0E0H, 3FH


#include "../../../HBIOS/t6963.asm"
        
                .END
                
               
