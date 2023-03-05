;
;==================================================================================================
; ASCI DRIVER (Z180 SERIAL PORTS)
;==================================================================================================
;
;  SETUP PARAMETER WORD:
;  +-------+---+-------------------+ +---+---+-----------+---+-------+
;  |	   |RTS| ENCODED BAUD RATE | |DTR|XON|	PARITY	 |STP| 8/7/6 |
;  +-------+---+---+---------------+ ----+---+-----------+---+-------+
;    F	 E   D	 C   B	 A   9	 8     7   6   5   4   3   2   1   0
;	-- MSB (D REGISTER) --		 -- LSB (E REGISTER) --
;
; STAT:
; 7 6 5 4 3 2 1 0
; R O P F R C T T
; 0 0 0 0 0 0 0 0   DEFAULT VALUES
; | | | | | | | |
; | | | | | | | +-- TIE:	TRANSMIT INTERRUPT ENABLE
; | | | | | | +---- TDRE:	TRANSMIT DATA REGISTER EMPTY
; | | | | | +------ DCD0/CTS1E:	CH0 CARRIER DETECT, CH1 CTS ENABLE
; | | | | +-------- RIE:	RECEIVE INTERRUPT ENABLE
; | | | +---------- FE:		FRAMING ERROR
; | | +------------ PE:		PARITY ERROR
; | +-------------- OVRN:	OVERRUN ERROR
; +---------------- RDRF:	RECEIVE DATA REGISTER FULL
;
; CNTLA:
; 7 6 5 4 3 2 1 0
; M R T R E M M M
; 0 1 1 0 0 1 0 0   DEFAULT VALUES
; | | | | | | | |
; | | | | | | | +-- MOD0:	STOP BITS: 0=1 BIT, 1=2 BITS
; | | | | | | +---- MOD1:	PARITY: 0=NONE, 1=ENABLED
; | | | | | +------ MOD2:	DATA BITS: 0=7 BITS, 1=8 BITS
; | | | | +-------- MPBR/EFR:	MULTIPROCESSOR BIT RECEIVE / ERROR FLAG RESET
; | | | +---------- RTS0/CKA1D:	CH0 ~RTS, CH1 CLOCK DISABLE
; | | +------------ TE:		TRANSMITTER ENABLE
; | +-------------- RE:		RECEIVER ENABLE
; +---------------- MPE:	MULTI-PROCESSOR MODE ENABLE
;
; CNTLB:
; 7 6 5 4 3 2 1 0
; T M P R D S S S
; 0 0 X 0 X X X X   DEFAULT VALUES
; | | | | | | | |
; | | | | | + + +-- SS: SOURCE/SPEED SELECT (R/W)
; | | | | +-------- DR: DIVIDE RATIO (R/W)
; | | | +---------- PEO: PARITY EVEN ODD (R/W)
; | | +------------ PS: ~CTS/PS: CLEAR TO SEND(R) / PRESCALE(W)
; | +-------------- MP: MULTIPROCESSOR MODE (R/W)
; +---------------- MPBT: MULTIPROCESSOR BIT TRANSMIT (R/W)
;
; ASEXT:
; 7 6 5 4 3 2 1 0
; R D C X B F D S
; 0 1 1 0 0 1 1 0   DEFAULT VALUES
; | | | | | | | |
; | | | | | | | +-- SEND BREAK
; | | | | | | +---- BREAK DETECT (RO)
; | | | | | +------ BREAK FEATURE ENABLE
; | | | | +-------- BRG MODE
; | | | +---------- X1 BIT CLK ASCI
; | | +------------ CTS0 DISABLE
; | +-------------- DCD0 DISABLE
; +---------------- RDRF INT INHIBIT
;
ASCI_BUFSZ	.EQU	32		; RECEIVE RING BUFFER SIZE
;
ASCI_NONE	.EQU	0		; NOT PRESENT
ASCI_ASCI	.EQU	1		; ORIGINAL ASCI (Z8S180 REV. K)
ASCI_ASCIB	.EQU	2		; REVISED ASCI W/ BRG & FIFO (Z8S180 REV. N)
;
ASCI0_BASE	.EQU	Z180_BASE	; RELATIVE TO Z180 INTERNAL IO PORTS
ASCI1_BASE	.EQU	Z180_BASE + 1	; RELATIVE TO Z180 INTERNAL IO PORTS
;
ASCI_RTS	.EQU	%00010000	; ~RTS BIT OF CNTLA REG
;
#IF (ASCIINTS)
;
  #IF (INTMODE == 2)
;
ASCI0_IVT	.EQU	IVT(INT_SER0)
ASCI1_IVT	.EQU	IVT(INT_SER1)
;
  #ENDIF
;
#ENDIF
;
;
;
ASCI_PREINIT:
;
; SETUP THE DISPATCH TABLE ENTRIES
; NOTE: INTS WILL BE DISABLED WHEN PREINIT IS CALLED AND THEY MUST REMAIN
; DISABLED.
;
	LD	B,ASCI_CFGCNT		; LOOP CONTROL
	XOR	A			; ZERO TO ACCUM
	LD	(ASCI_DEV),A		; CURRENT DEVICE NUMBER
	LD	IY,ASCI_CFG		; POINT TO START OF CFG TABLE
ASCI_PREINIT0:
	PUSH	BC			; SAVE LOOP CONTROL
	CALL	ASCI_INITUNIT		; HAND OFF TO GENERIC INIT CODE
	POP	BC			; RESTORE LOOP CONTROL
;
	LD	A,(IY+1)		; GET THE ASCI TYPE DETECTED
	OR	A			; SET FLAGS
	JR	Z,ASCI_PREINIT2		; SKIP IT IF NOTHING FOUND
;
	PUSH	BC			; SAVE LOOP CONTROL
	PUSH	IY			; CFG ENTRY ADDRESS
	POP	DE			; ... TO DE
	LD	BC,ASCI_FNTBL		; BC := FUNCTION TABLE ADDRESS
	CALL	NZ,CIO_ADDENT		; ADD ENTRY IF ASCI FOUND, BC:DE
	POP	BC			; RESTORE LOOP CONTROL
;
ASCI_PREINIT2:
	LD	DE,ASCI_CFGSIZ		; SIZE OF CFG ENTRY
	ADD	IY,DE			; BUMP IY TO NEXT ENTRY
	DJNZ	ASCI_PREINIT0		; LOOP UNTIL DONE
;
#IF (ASCIINTS)
;
  #IF (INTMODE >= 1)
	; SETUP INT VECTORS AS APPROPRIATE
	LD	A,(ASCI_DEV)		; GET DEVICE COUNT
	OR	A			; SET FLAGS
	JR	Z,ASCI_PREINIT3		; IF ZERO, NO ASCI DEVICES, ABORT
;
    #IF (INTMODE == 1)
	; ADD IM1 INT CALL LIST ENTRY
	LD	HL,ASCI_INT		; GET INT VECTOR
	CALL	HB_ADDIM1		; ADD TO IM1 CALL LIST
    #ENDIF
;
    #IF (INTMODE == 2)
	; SETUP IM2 VECTORS
	LD	HL,ASCI_INT0
	LD	(ASCI0_IVT),HL		; IVT INDEX
	LD	HL,ASCI_INT1
	LD	(ASCI1_IVT),HL		; IVT INDEX
    #ENDIF
;
  #ENDIF
;
#ENDIF
;
ASCI_PREINIT3:
	XOR	A			; SIGNAL SUCCESS
	RET				; AND RETURN
;
; ASCI INITIALIZATION ROUTINE
;
ASCI_INITUNIT:
	CALL	ASCI_DETECT		; DETERMINE ASCI TYPE
	LD	(IY+1),A		; SAVE IN CONFIG TABLE
	OR	A			; SET FLAGS
	RET	Z			; ABORT IF NOTHING THERE

	; UPDATE WORKING ASCI DEVICE NUM
	LD	HL,ASCI_DEV		; POINT TO CURRENT UART DEVICE NUM
	LD	A,(HL)			; PUT IN ACCUM
	INC	(HL)			; INCREMENT IT (FOR NEXT LOOP)
	LD	(IY),A			; UPDATE UNIT NUM
;
	; IT IS EASY TO SPECIFY A SERIAL CONFIG THAT CANNOT BE IMPLEMENTED
	; DUE TO THE CONSTRAINTS OF THE ASCI.  HERE WE FORCE A GENERIC
	; FAILSAFE CONFIG ONTO THE CHANNEL.  IF THE SUBSEQUENT "REAL"
	; CONFIG FAILS, AT LEAST THE CHIP WILL BE ABLE TO SPIT DATA OUT
	; AT A RATIONAL BAUD/DATA/PARITY/STOP CONFIG.
	CALL	ASCI_INITSAFE
;
	; SET DEFAULT CONFIG
	LD	DE,-1			; LEAVE CONFIG ALONE
	; CALL INITDEV TO IMPLEMENT CONFIG, BUT NOTE THAT WE CALL
	; THE INITDEVX ENTRY POINT THAT DOES NOT ENABLE/DISABLE INTS!
	JP	ASCI_INITDEVX		; IMPLEMENT IT AND RETURN
;
;
;
ASCI_INIT:
	LD	B,ASCI_CFGCNT		; COUNT OF POSSIBLE ASCI UNITS
	LD	IY,ASCI_CFG		; POINT TO START OF CFG TABLE
ASCI_INIT1:
	PUSH	BC			; SAVE LOOP CONTROL
	LD	A,(IY+1)		; GET ASCI TYPE
	OR	A			; SET FLAGS
	CALL	NZ,ASCI_PRTCFG		; PRINT IF NOT ZERO
	POP	BC			; RESTORE LOOP CONTROL
	LD	DE,ASCI_CFGSIZ		; SIZE OF CFG ENTRY
	ADD	IY,DE			; BUMP IY TO NEXT ENTRY
	DJNZ	ASCI_INIT1		; LOOP TILL DONE
;
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
; RECEIVE INTERRUPT HANDLER
;
#IF (ASCIINTS)
;
  #IF (INTMODE > 0)
;
; IM1 ENTRY POINT
;
ASCI_INT:
	; CHECK/HANDLE FIRST PORT
	LD	A,(ASCI0_CFG + 1)	; GET ASCI TYPE FOR FIRST ASCI
	OR	A			; SET FLAGS
	CALL	NZ,ASCI_INT0		; CALL IF EXISTS
	RET	NZ			; DONE IF INT HANDLED
;
	; CHECK/HANDLE SECOND PORT
	LD	A,(ASCI1_CFG + 1)	; GET ASCI TYPE FOR SECOND ASCI
	OR	A			; SET FLAGS
	CALL	NZ,ASCI_INT1		; CALL IF EXISTS
;
	RET				; DONE
;
; IM2 ENTRY POINTS
;
ASCI_INT0:
	; INTERRUPT HANDLER FOR FIRST ASCI (ASCI0)
	LD	IY,ASCI0_CFG		; POINT TO ASCI0 CFG
	JR	ASCI_INTRCV
;
ASCI_INT1:
	; INTERRUPT HANDLER FOR SECOND ASCI (ASCI1)
	LD	IY,ASCI1_CFG		; POINT TO ASCI1 CFG
	JR	ASCI_INTRCV
;
; HANDLE INT FOR A SPECIFIC CHANNEL
; BASED ON UNIT CFG POINTED TO BY IY
;
ASCI_INTRCV:
	; CHECK TO SEE IF SOMETHING IS ACTUALLY THERE
	CALL	ASCI_ICHK		; CHECK FOR CHAR PENDING
	RET	Z			; RETURN IF NOTHING AVAILABLE
;
ASCI_INTRCV1:
	; RECEIVE CHARACTER INTO BUFFER
	LD	A,(IY+3)		; BASE PORT TO A
	ADD	A,8			; BUMP TO RDR PORT
	LD	C,A			; PUT IN C, B IS STILL ZERO
	IN	A,(C)			; READ PORT
    #IF (ASCIBOOT != 0)
	CP	ASCIBOOT		; REBOOT REQUEST?
	JP	Z,SYS_RESCOLD		; IF SO, DO IT, NO RETURN
    #ENDIF
	LD	B,A			; SAVE BYTE READ
	LD	L,(IY+6)		; SET HL TO
	LD	H,(IY+7)		; ... START OF BUFFER STRUCT
	LD	A,(HL)			; GET COUNT
	CP	ASCI_BUFSZ		; COMPARE TO BUFFER SIZE
	JR	Z,ASCI_INTRCV4		; BAIL OUT IF BUFFER FULL, RCV BYTE DISCARDED
	INC	A			; INCREMENT THE COUNT
	LD	(HL),A			; AND SAVE IT
	CP	ASCI_BUFSZ / 2		; BUFFER GETTING FULL?
	JR	NZ,ASCI_INTRCV2		; IF NOT, BYPASS CLEARING RTS
	; CLEAR RTS
	; THE SECONDARY ASCI PORT ON Z180 ACTUALLY HAS NO RTS LINE
	; AND THE CNTLA BIT FOR THIS PORT CONTROLS THE FUNCTION OF THE
	; MULTIPLEXED CKA1/~TEND0 LINE.	 BELOW, WE TEST REG C TO SEE IF
	; IT IS AN ODD NUMBERED PORT.  IF SO, WE MUST BE ON THE SECONDARY
	; SERIAL PORT, SO WE NEED TO BYPASS MANIPULATING THE RTS BIT.
	BIT	0,C			; IS C ADDRESSING AN ODD NUMBERED PORT?
	JR	NZ,ASCI_INTRCV2		; IF SO, THIS IS SEC SERIAL, NO RTS!
	PUSH	BC			; PRESERVE READ CHAR
	LD	C,(IY+3)		; CNTLA PORT ADR
	LD	B,0			; MSB FOR 16 BIT I/O
	IN	A,(C)			; GET CUR CNTLA VAL
	OR	ASCI_RTS		; DEASSERT ~RTS
	OUT	(C),A			; DO IT
	POP	BC			; RESTORE READ CHAR
ASCI_INTRCV2:
	INC	HL			; HL NOW HAS ADR OF HEAD PTR
	PUSH	HL			; SAVE ADR OF HEAD PTR
	LD	A,(HL)			; DEREFERENCE HL
	INC	HL
	LD	H,(HL)
	LD	L,A			; HL IS NOW ACTUAL HEAD PTR
	LD	(HL),B			; SAVE CHARACTER RECEIVED IN BUFFER AT HEAD
	INC	HL			; BUMP HEAD POINTER
	POP	DE			; RECOVER ADR OF HEAD PTR
	LD	A,L			; GET LOW BYTE OF HEAD PTR
	SUB	ASCI_BUFSZ+4		; SUBTRACT SIZE OF BUFFER AND POINTER
	CP	E			; IF EQUAL TO START, HEAD PTR IS PAST BUF END
	JR	NZ,ASCI_INTRCV3		; IF NOT, BYPASS
	LD	H,D			; SET HL TO
	LD	L,E			; ... HEAD PTR ADR
	INC	HL			; BUMP PAST HEAD PTR
	INC	HL
	INC	HL
	INC	HL			; ... SO HL NOW HAS ADR OF ACTUAL BUFFER START
ASCI_INTRCV3:
	EX	DE,HL			; DE := HEAD PTR VAL, HL := ADR OF HEAD PTR
	LD	(HL),E			; SAVE UPDATED HEAD PTR
	INC	HL
	LD	(HL),D
	; CHECK FOR MORE PENDING...
	CALL	ASCI_ICHK		; CHECK FOR CHAR PENDING
	JR	NZ,ASCI_INTRCV1		; IF SO, LOOP TO HANDLE
ASCI_INTRCV4:
	OR	$FF			; NZ SET TO INDICATE INT HANDLED
	RET				; AND RETURN
;
  #ENDIF
;
#ENDIF
;
; DRIVER FUNCTION TABLE
;
ASCI_FNTBL:
	.DW	ASCI_IN
	.DW	ASCI_OUT
	.DW	ASCI_IST
	.DW	ASCI_OST
	.DW	ASCI_INITDEV
	.DW	ASCI_QUERY
	.DW	ASCI_DEVICE
#IF (($ - ASCI_FNTBL) != (CIO_FNCNT * 2))
	.ECHO	"*** INVALID ASCI FUNCTION TABLE ***\n"
#ENDIF
;
#IF ((!ASCIINTS) | (INTMODE == 0))
;
ASCI_IN:
	CALL	ASCI_IST		; CHECK FOR CHAR READY
	JR	Z,ASCI_IN		; IF NOT, LOOP
	LD	A,(IY+3)		; BASE REG
	ADD	A,8			; Z180 RDR REG OFFSET
	LD	C,A			; PUT IN C FOR I/O
	LD	B,0			; MSB FOR 16 BIT I/O
	IN	E,(C)			; GET CHAR
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
#ELSE
;
ASCI_IN:
	CALL	ASCI_IST		; SEE IF CHAR AVAILABLE
	JR	Z,ASCI_IN		; LOOP UNTIL SO
	HB_DI				; AVOID COLLISION WITH INT HANDLER
	LD	L,(IY+6)		; SET HL TO
	LD	H,(IY+7)		; ... START OF BUFFER STRUCT
	LD	A,(HL)			; GET COUNT
	DEC	A			; DECREMENT COUNT
	LD	(HL),A			; SAVE UPDATED COUNT
	CP	ASCI_BUFSZ / 4		; BUFFER LOW THRESHOLD
	JR	NZ,ASCI_IN1		; IF NOT, BYPASS SETTING RTS
	; SET RTS
	; THE SECONDARY ASCI PORT ON Z180 ACTUALLY HAS NO RTS LINE
	; AND THE CNTLA BIT FOR THIS PORT CONTROLS THE FUNCTION OF THE
	; MULTIPLEXED CKA1/~TEND0 LINE.	 BELOW, WE TEST REG C TO SEE IF
	; IT IS AN ODD NUMBERED PORT.  IF SO, WE MUST BE ON THE SECONDARY
	; SERIAL PORT, SO WE NEED TO BYPASS MANIPULATING THE RTS BIT.
	LD	C,(IY+3)		; CNTLA PORT ADR
	BIT	0,C			; IS C ADDRESSING AN ODD NUMBERED PORT?
	JR	NZ,ASCI_IN1		; IF SO, THIS IS SEC SERIAL, NO RTS!
	LD	B,0			; MSB FOR 16 BIT I/O
	IN	A,(C)			; GET CUR CNTLA VAL
	AND	~ASCI_RTS		; ASSERT ~RTS
	OUT	(C),A			; DO IT
ASCI_IN1:
	INC	HL			; HL := ADR OF TAIL PTR
	INC	HL			; "
	INC	HL			; "
	PUSH	HL			; SAVE ADR OF TAIL PTR
	LD	A,(HL)			; DEREFERENCE HL
	INC	HL
	LD	H,(HL)
	LD	L,A			; HL IS NOW ACTUAL TAIL PTR
	LD	C,(HL)			; C := CHAR TO BE RETURNED
	INC	HL			; BUMP TAIL PTR
	POP	DE			; RECOVER ADR OF TAIL PTR
	LD	A,L			; GET LOW BYTE OF TAIL PTR
	SUB	ASCI_BUFSZ+2		; SUBTRACT SIZE OF BUFFER AND POINTER
	CP	E			; IF EQUAL TO START, TAIL PTR IS PAST BUF END
	JR	NZ,ASCI_IN2		; IF NOT, BYPASS
	LD	H,D			; SET HL TO
	LD	L,E			; ... TAIL PTR ADR
	INC	HL			; BUMP PAST TAIL PTR
	INC	HL			; ... SO HL NOW HAS ADR OF ACTUAL BUFFER START
ASCI_IN2:
	EX	DE,HL			; DE := TAIL PTR VAL, HL := ADR OF TAIL PTR
	LD	(HL),E			; SAVE UPDATED TAIL PTR
	INC	HL			; "
	LD	(HL),D			; "
	LD	E,C			; MOVE CHAR TO RETURN TO E
	HB_EI				; INTERRUPTS OK AGAIN
	XOR	A			; SIGNAL SUCCESS
	RET				; AND DONE
;
#ENDIF
;
;
;
ASCI_OUT:
	CALL	ASCI_OST		; CHECK IF OUTPUT REGISTER READY
	JR	Z,ASCI_OUT		; LOOP UNTIL SO
	LD	A,(IY+3)		; GET ASCI BASE REG
	ADD	A,6			; Z180 TDR REG OFFSET
	LD	C,A			; PUT IN C FOR I/O
	LD	B,0			; MSB FOR 16 BIT I/O
	OUT	(C),E			; WRITE CHAR
#IF (LCDTERMENABLE)
                CALL    LCDTERM_PUTC
#ENDIF
	RET				; DONE
;
;
;
#IF ((!ASCIINTS) | (INTMODE == 0))
;
ASCI_IST:
	CALL	ASCI_ICHK		; ASCI INPUT CHECK
	JP	Z,CIO_IDLE		; IF NOT READY, RETURN VIA IDLE PROCESSING
	RET				; NORMAL RETURN
;
#ELSE
;
ASCI_IST:
	LD	L,(IY+6)		; GET ADDRESS
	LD	H,(IY+7)		; ... OF RECEIVE BUFFER
	LD	A,(HL)			; BUFFER UTILIZATION COUNT
	OR	A			; SET FLAGS
	JP	Z,CIO_IDLE		; NOT READY, RETURN VIA IDLE PROCESSING
	RET				; DONE
;
#ENDIF
;
;
;
ASCI_OST:
	LD	A,(IY+3)		; GET ASCI BASE REG
	ADD	A,4			; Z180 STAT REG OFFSET
	LD	C,A			; PUT IN C FOR I/O
	LD	B,0			; MSB FOR 16 BIT I/O
	IN	A,(C)			; READ STATUS
	AND	$02			; CHECK BIT FOR OUTPUT READY
	JP	Z,CIO_IDLE		; IF NOT, DO IDLE PROCESSING AND RETURN
	XOR	A			; OTHERWISE SIGNAL
	INC	A			; ... BUFFER EMPTY, A = 1
	RET				; DONE
;
; AT INITIALIZATION THE SETUP PARAMETER WORD IS TRANSLATED TO THE FORMAT
; REQUIRED BY THE ASCI AND STORED IN A PORT/REGISTER INITIALIZATION TABLE,
; WHICH IS THEN LOADED INTO THE ASCI.
;
; NOTE THAT THERE ARE TWO ENTRY POINTS.	 INITDEV WILL DISABLE/ENABLE INTS
; AND INITDEVX WILL NOT.  THIS IS DONE SO THAT THE PREINIT ROUTINE ABOVE
; CAN AVOID ENABLING/DISABLING INTS.
;
ASCI_INITDEV:
	HB_DI				; DISABLE INTS
	CALL	ASCI_INITDEVX		; DO THE WORK
	HB_EI				; INTS BACK ON
	RET				; DONE
;
ASCI_INITDEVX:
;
; THIS ENTRY POINT BYPASSES DISABLING/ENABLING INTS WHICH IS REQUIRED BY
; PREINIT ABOVE.  PREINIT IS NOT ALLOWED TO ENABLE INTS!
;
	; TEST FOR -1 WHICH MEANS USE CURRENT CONFIG (JUST REINIT)
	LD	A,D			; TEST DE FOR
	AND	E			; ... VALUE OF -1
	INC	A			; ... SO Z SET IF -1
	JR	NZ,ASCI_INITDEV1	; IF DE == -1, REINIT CURRENT CONFIG
;
	; LOAD EXISTING CONFIG TO REINIT
	LD	E,(IY+4)		; LOW BYTE
	LD	D,(IY+5)		; HIGH BYTE
;
ASCI_INITDEV1:
;
	LD	A,E			; GET CONFIG LSB
	AND	$E0			; CHECK FOR DTR, XON, PARITY=MARK/SPACE
	JR	NZ,ASCI_INITFAIL	; IF ANY BIT SET, FAIL, NOT SUPPORTED
;
	; DETERMINE APPROPRIATE CNTLB VALUE (BASED ON BAUDRATE & CPU SPEED)
	LD	A,D			; BYTE W/ ENCODED BAUD RATE
	AND	$1F			; ISOLATE BITS
	LD	L,A			; MOVE TO L
	LD	H,0			; CLEAR MSB
	PUSH	DE			; SAVE CONFIG
	CALL	ASCI_CNTLB		; DERIVE CNTLB VALUE TO C
	POP	DE			; RESTORE CONFIG
	JR	NZ,ASCI_INITFAIL	; ABORT ON ERROR
;
	; BUILD CNTLA VALUE IN REGISTER B
	LD	B,$64			; START WITH DEFAULT CNTLA VALUE
;
	; DATA BITS
	LD	A,E			; LOAD CONFIG BYTE
	AND	$03			; ISOLATE DATA BITS
	CP	$03			; 8 DATA BITS?
	JR	Z,ASCI_INITDEV2		; IF SO, NO CHG, CONTINUE
	RES	2,B			; RESET CNTLA BIT 2 FOR 7 DATA BITS
;
ASCI_INITDEV2:
	; STOP BITS
	BIT	2,E			; TEST STOP BITS CONFIG BIT
	JR	Z,ASCI_INITDEV3		; IF CLEAR, NO CHG, CONTINUE
	SET	0,B			; SET CNTLA BIT 0 FOR 2 STOP BITS
;
ASCI_INITDEV3:
	; PARITY ENABLE
	BIT	3,E			; TEST PARITY ENABLE CONFIG BIT
	JR	Z,ASCI_INITDEV4		; NO PARITY, SKIP ALL PARITY CHGS
	SET	1,B			; SET CNTLA BIT 1 FOR PARITY ENABLE

	; PARITY EVEN/ODD
	BIT	4,E			; TEST EVEN PARITY CONFIG BIT
	JR	NZ,ASCI_INITDEV4	; EVEN PARITY, NO CHG, CONTINUE
	SET	4,C			; SET CNTLB BIT 4 FOR ODD PARITY
;
ASCI_INITDEV4:
	; SAVE CONFIG PERMANENTLY NOW
	LD	(IY+4),E		; SAVE LOW WORD
	LD	(IY+5),D		; SAVE HI WORD
	JR	ASCI_INITGO
;
ASCI_INITSAFE:
	LD	B,$64			; CNTLA FAILSAFE VALUE
	LD	C,$20			; CNTLB FAILSAFE VALUE
;
ASCI_INITGO:
	; IMPLEMENT CONFIGURATION
	LD	H,B			; H := CNTLA VAL
	LD	L,C			; L := CNTLB VAL
	LD	B,0			; MSB OF PORT MUST BE ZERO!
	LD	C,(IY+3)		; GET ASCI BASE REG (CNTLA)
	OUT	(C),H			; WRITE CNTLA VALUE
	INC	C			; BUMP TO
	INC	C			; ... CNTLB REG, B IS STILL 0
	OUT	(C),L			; WRITE CNTLB VALUE
	INC	C			; BUMP TO
	INC	C			; ... STAT REG, B IS STILL 0
#IF ((ASCIINTS) & (INTMODE > 0))
	LD	A,$08			; SET RIE BIT ON
#ELSE
	XOR	A			; CLEAR RIE/TIE
#ENDIF
	OUT	(C),A			; WRITE STAT REG
	LD	A,$0E			; BUMP TO
	ADD	A,C			; ... ASEXT REG
	LD	C,A			; PUT IN C FOR I/O, B IS STILL 0
	LD	A,$66			; STATIC VALUE FOR ASEXT
	OUT	(C),A			; WRITE ASEXT REG
;
#IF ((ASCIINTS) & (INTMODE > 0))
;
	; RESET THE RECEIVE BUFFER
	LD	E,(IY+6)
	LD	D,(IY+7)		; DE := _CNT
	XOR	A			; A := 0
	LD	(DE),A			; _CNT = 0
	INC	DE			; DE := ADR OF _HD
	PUSH	DE			; SAVE IT
	INC	DE
	INC	DE
	INC	DE
	INC	DE			; DE := ADR OF _BUF
	POP	HL			; HL := ADR OF _HD
	LD	(HL),E
	INC	HL
	LD	(HL),D			; _HD := _BUF
	INC	HL
	LD	(HL),E
	INC	HL
	LD	(HL),D			; _TL := _BUF
;
#ENDIF
;
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
ASCI_INITFAIL:
	OR	$FF			; SIGNAL FAILURE
	RET				; RETURN
;
;
;
ASCI_QUERY:
	LD	E,(IY+4)		; FIRST CONFIG BYTE TO E
	LD	D,(IY+5)		; SECOND CONFIG BYTE TO D
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
;
;
ASCI_DEVICE:
	LD	D,CIODEV_ASCI		; D := DEVICE TYPE
	LD	E,(IY)			; E := PHYSICAL UNIT
	LD	C,$00			; C := DEVICE TYPE, 0x00 IS RS-232
	LD	H,0			; H := 0, DRIVER HAS NO MODES
	LD	L,(IY+3)		; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET
;
; ASCI DETECTION ROUTINE
; ALWAYS PRESENT, JUST SAY SO.
;
ASCI_DETECT:
	LD	A,(IY+3)		; BASE PORT ADR
	ADD	A,$1A			; BUMP TO ASCI CONSTANT LOW
	LD	C,A			; PUT IN C
	LD	B,0			; MSB FOR 16 BIT I/O
	XOR	A			; ZERO TO ACCUM
	OUT	(C),A			; WRITE TO REG
	IN	A,(C)			; READ IT BACK
	INC	A			; FF -> 0
	LD	A,ASCI_ASCI		; ASSUME ORIG ASCI, NO BRG
	RET	Z			; IF SO, RETURN
	LD	A,ASCI_ASCIB		; MUST BE NEWER ASCI W/ BRG
	RET				; DONE
;
; DERIVE CNTLB VALUE BASED ON AN ENCODED BAUD RATE AND CURRENT CPU SPEED
; ENTRY: HL = ENCODED BAUD RATE
; EXIT: C = CNTLB VALUE, A=0/Z IFF SUCCESS
;
; DESIRED DIVISOR == CPUHZ / BAUD
; DUE TO ENCODING BAUD IS ALWAYS DIVISIBLE BY 75
; Z180 DIVISOR IS ALWAYS A FACTOR OF 160
;
; CNTLB=	XXPXDSSS
; FAILSAVE = 	00100000
;
; PS (PRESCALE): 0=/10, 1=/30
; DR (DIVIDE RATIO): 0=/16, 1=/64
; SS2	SS1	SS0
; ---	---	---
; 0	0	0	/1
; 0	0	1	/2
; 0	1	0	/4
; 0	1	1	/8
; 1	0	0	/16
; 1	0	1	/32
; 1	1	0	/64
;
; FAILSAFE: CLOCK / 30 / 16 / 1 = CLOCK / 480
;	IF CLOCK=18432000, BAUD=38400
;
; X := CPU_HZ / 160 / 75 ==> SIMPLIFIED ==> X := CPU_KHZ / 12
; X := X / (BAUD / 75)
; IF X % 3 == 0, THEN (PS := 1, X := X / 3) ELSE PS=0
; IF X % 4 == 0, THEN (DR := 1, X := X / 4) ELSE DR=0
; SS := LOG2(X)
;
ASCI_CNTLB:
	LD	DE,1			; USE DECODE CONSTANT OF 1 TO GET BAUD RATE ALREADY DIVIDED BY 75
	CALL	DECODE			; DECODE THE BAUDATE INTO DE:HL, DE IS DISCARDED
	RET	NZ			; ABORT ON ERROR
	PUSH	HL			; HL HAS (BAUD / 75), SAVE IT
	LD	HL,(CB_CPUKHZ)		; GET CPU CLK IN KHZ
;
	; DUE TO THE LIMITED DIVISORS POSSIBLE WITH CNTLB, YOU PRETTY MUCH
	; NEED TO USE A CPU SPEED THAT IS A MULTIPLE OF 128KHZ.	 BELOW, WE
	; ATTEMPT TO ROUND THE CPU SPEED DETECTED TO A MULTIPLE OF 128KHZ
	; WITH ROUNDING.  THIS JUST MAXIMIZES POSSIBILITY OF SUCCESS COMPUTING
	; THE DIVISOR.
	LD	DE,$0040		; HALF OF 128 IS 64
	ADD	HL,DE			; ADD FOR ROUNDING
	LD	A,L			; MOVE TO ACCUM
	AND	$80			; STRIP LOW ORDER 7 BITS
	LD	L,A			; ... AND PUT IT BACK
;
	LD	DE,12			; PREPARE TO DIVIDE BY 12
	CALL	DIV16			; BC := (CPU_KHZ / 12), REM IN HL, ZF
	POP	DE			; RESTORE (BAUD / 75)
	RET	NZ			; ABORT IF REMAINDER
	PUSH	BC			; MOVE WORKING VALUE
	POP	HL			; ... BACK TO HL
	CALL	DIV16			; BC := X / (BAUD / 75)
	RET	NZ			; ABORT IF REMAINDER
;
	; DETERMINE PS BIT BY ATTEMPTING DIVIDE BY 3
	PUSH	BC			; SAVE WORKING VALUE ON STACK
	PUSH	BC			; MOVE WORKING VALUE
	POP	HL			; ... TO HL
	LD	DE,3			; SETUP TO DIVIDE BY 3
	CALL	DIV16			; BC := X / 3, REM IN HL, ZF
	POP	HL			; HL := PRIOR WORKING VALUE
	LD	E,0			; INIT E := 0 AS WORKING CNTLB VALUE
	JR	NZ,ASCI_CNTLB1		; DID NOT WORK, LEAVE PS==0, SKIP AHEAD
	SET	5,E			; SET PS BIT
	PUSH	BC			; MOVE NEW WORKING
	POP	HL			; ... VALUE TO HL
;
ASCI_CNTLB1:
	; DETERMINE DR BIT BY ATTEMPTING DIVIDE BY 4
	LD	A,L			; LOAD LSB OF WORKING VALUE
	AND	$03			; ISOLATE LOW ORDER BITS
	JR	NZ,ASCI_CNTLB2		; NOT DIVISIBLE BY 4, SKIP AHEAD
	SET	3,E			; SET PS BIT
	SRL	H			; DIVIDE HL BY 4
	RR	L			; ...
	SRL	H			; ...
	RR	L			; ...
;
ASCI_CNTLB2:
	; DETERMINE SS BITS BY RIGHT SHIFTING AND INCREMENTING
	LD	B,7			; LOOP COUNTER, MAX VALUE OF SS IS 7
	LD	C,E			; MOVE WORKING CNTLB VALUE TO C
ASCI_CNTLB3:
	BIT	0,L			; CAN WE SHIFT AGAIN?
	JR	NZ,ASCI_CNTLB4		; NOPE, DONE
	SRL	H			; IMPLEMENT THE
	RR	L			; ... SHIFT OPERATION
	INC	C			; INCREMENT SS BITS
	DJNZ	ASCI_CNTLB3		; LOOP IF MORE SHIFTING POSSIBLE
;
	; AT THIS POINT HL MUST BE EQUAL TO 1 OR WE FAILED!
	DEC	HL			; IF HL == 1, SHOULD BECOME ZERO
	LD	A,H			; TEST HL
	OR	L			; ... FOR ZERO
	RET	NZ			; ABORT IF NOT ZERO
;
ASCI_CNTLB4:
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
; SPECIAL INPUT STATUS CHECK ROUTINE FOR ASCI.	IF THE ASCI PORT DETECTS A LINE
; ERROR (PARITY, OVERRUN, ETC.) IT WILL STALL UNTIL THE ERROR IS EXPLICITY
; ACKNOWLEDGED.	 THIS ROUTINE HANDLES ALL OF THAT AND RETURNS WITH A=1 IF CHAR
; READY, ELSE A=0.  ZF SET OR CLEARED.
;
ASCI_ICHK:
	LD	A,(IY+3)		; GET ASCI BASE REG
	ADD	A,4			; Z180 STAT REG OFFSET
	LD	C,A			; PUT IN C FOR I/O
	LD	B,0			; MSB FOR 16 BIT I/O
	IN	A,(C)			; READ STAT REG
	PUSH	AF			; SAVE STATUS
	AND	$70			; PARITY, FRAMING, OR OVERRUN ERROR?
	JR	Z,ASCI_ICHK1		; JUMP AHEAD IF NO ERRORS
;
	; CLEAR ERROR(S) OR NOTHING FURTHER CAN BE RECEIVED!!!
	LD	C,(IY+3)		; GET ASCI BASE REG (CNTLA)
	LD	B,0			; MSB FOR 16 BIT I/O
	IN	A,(C)			; READ CNTLA
	RES	3,A			; CLEAR EFR (ERROR FLAG RESET)
	OUT	(C),A			; WRITE UPDATED CNTLA
;
ASCI_ICHK1:
	POP	AF			; RESTORE STATUS VALUE
	AND	$80			; DATA READY?
	JP	Z,CIO_IDLE		; IF NOT, DO IDLE PROCESSING AND RETURN
	XOR	A			; SIGNAL CHAR WAITING
	INC	A			; ... BY SETTING A TO 1
	RET				; DONE
;
;
;
ASCI_PRTCFG:
	; ANNOUNCE PORT
	CALL	NEWLINE			; FORMATTING
	PRTS("ASCI$")			; FORMATTING
	LD	A,(IY)			; DEVICE NUM
	CALL	PRTDECB			; PRINT DEVICE NUM
	PRTS(": IO=0x$")		; FORMATTING
	LD	A,(IY+3)		; GET BASE PORT
	CALL	PRTHEXBYTE		; PRINT BASE PORT

	; PRINT THE ASCI TYPE
	CALL	PC_SPACE		; FORMATTING
	LD	A,(IY+1)		; GET ASCI TYPE BYTE
	RLCA				; MAKE IT A WORD OFFSET
	LD	HL,ASCI_TYPE_MAP	; POINT HL TO TYPE MAP TABLE
	CALL	ADDHLA			; HL := ENTRY
	LD	E,(HL)			; DEREFERENCE
	INC	HL			; ...
	LD	D,(HL)			; ... TO GET STRING POINTER
	CALL	WRITESTR		; PRINT IT
;
	; ALL DONE IF NO ASCI WAS DETECTED
	LD	A,(IY+1)		; GET ASCI TYPE BYTE
	OR	A			; SET FLAGS
	RET	Z			; IF ZERO, NOT PRESENT
;
	PRTS(" MODE=$")			; FORMATTING
	LD	E,(IY+4)		; LOAD CONFIG
	LD	D,(IY+5)		; ... WORD TO DE
	CALL	PS_PRTSC0		; PRINT CONFIG
;
	XOR	A
	RET
;
;
;
ASCI_TYPE_MAP:
	.DW	ASCI_STR_NONE
	.DW	ASCI_STR_ASCI
	.DW	ASCI_STR_ASCIB

ASCI_STR_NONE	.DB	"<NOT PRESENT>$"
ASCI_STR_ASCI	.DB	"ASCI$"
ASCI_STR_ASCIB	.DB	"ASCI W/BRG$"
;
; WORKING VARIABLES
;
ASCI_DEV	.DB	0		; DEVICE NUM USED DURING INIT
;
#IF ((!ASCIINTS) | (INTMODE == 0))
;
ASCI0_RCVBUF	.EQU	0
ASCI1_RCVBUF	.EQU	0
;
#ELSE
;
; RECEIVE BUFFERS
;
ASCI0_RCVBUF:
ASCI0_BUFCNT	.DB	0		; CHARACTERS IN RING BUFFER
ASCI0_HD	.DW	ASCI0_BUF	; BUFFER HEAD POINTER
ASCI0_TL	.DW	ASCI0_BUF	; BUFFER TAIL POINTER
ASCI0_BUF	.FILL	ASCI_BUFSZ,0	; RECEIVE RING BUFFER
ASCI0_BUFEND	.EQU	$		; END OF BUFFER
ASCI0_BUFSZ	.EQU	$ - ASCI0_BUF	; SIZE OF RING BUFFER
;
ASCI1_RCVBUF:
ASCI1_BUFCNT	.DB	0		; CHARACTERS IN RING BUFFER
ASCI1_HD	.DW	ASCI1_BUF	; BUFFER HEAD POINTER
ASCI1_TL	.DW	ASCI1_BUF	; BUFFER TAIL POINTER
ASCI1_BUF	.FILL	ASCI_BUFSZ,0	; RECEIVE RING BUFFER
ASCI1_BUFEND	.EQU	$		; END OF BUFFER
ASCI1_BUFSZ	.EQU	$ - ASCI1_BUF	; SIZE OF RING BUFFER
;
#ENDIF
;
; ASCI PORT TABLE
;
ASCI_CFG:
;
#IF (ASCISWAP)
;
ASCI1_CFG:
	; ASCI CHANNEL B CONFIG
	.DB	0			; DEVICE NUMBER (SET DURING INIT)
	.DB	0			; ASCI TYPE (SET DURING INIT)
	.DB	1			; MODULE ID
	.DB	ASCI1_BASE		; BASE PORT
	.DW	ASCI1CFG		; LINE CONFIGURATION
	.DW	ASCI1_RCVBUF		; POINTER TO RCV BUFFER STRUCT
;
ASCI_CFGSIZ	.EQU	$ - ASCI_CFG	; SIZE OF ONE CFG TABLE ENTRY
;
ASCI0_CFG:
	; ASCI CHANNEL A CONFIG
	.DB	0			; DEVICE NUMBER (SET DURING INIT)
	.DB	0			; ASCI TYPE (SET DURING INIT)
	.DB	0			; MODULE ID
	.DB	ASCI0_BASE		; BASE PORT
	.DW	ASCI0CFG		; LINE CONFIGURATION
	.DW	ASCI0_RCVBUF		; POINTER TO RCV BUFFER STRUCT
;
#ELSE
;
ASCI0_CFG:
	; ASCI CHANNEL A CONFIG
	.DB	0			; DEVICE NUMBER (SET DURING INIT)
	.DB	0			; ASCI TYPE (SET DURING INIT)
	.DB	0			; MODULE ID
	.DB	ASCI0_BASE		; BASE PORT
	.DW	ASCI0CFG		; LINE CONFIGURATION
	.DW	ASCI0_RCVBUF		; POINTER TO RCV BUFFER STRUCT
;
ASCI_CFGSIZ	.EQU	$ - ASCI_CFG	; SIZE OF ONE CFG TABLE ENTRY
;
ASCI1_CFG:
	; ASCI CHANNEL B CONFIG
	.DB	0			; DEVICE NUMBER (SET DURING INIT)
	.DB	0			; ASCI TYPE (SET DURING INIT)
	.DB	1			; MODULE ID
	.DB	ASCI1_BASE		; BASE PORT
	.DW	ASCI1CFG		; LINE CONFIGURATION
	.DW	ASCI1_RCVBUF		; POINTER TO RCV BUFFER STRUCT
;
#ENDIF
;
;
ASCI_CFGCNT	.EQU	($ - ASCI_CFG) / ASCI_CFGSIZ