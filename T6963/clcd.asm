;======================================================================
;	CHARACTER LCD DEVICE CONTROLLER
;======================================================================
;
;======================================================================
; CLCD DRIVER - CONSTANTS
;======================================================================
;
#IF (CLCDMODE == CLCDMODE_ECB)
CLCD_BASE	.EQU	$??		; CLCD BASE I/O PORT
CLCD_DAC_BASE	.EQU	$??		; RAMDAC BASE I/O PORT
#ENDIF
;
#IF (CLCDMODE == CLCDMODE_DJRM)
CLCD_KBDDATA	.EQU	$60		; KBD CTLR DATA PORT
CLCD_KBDST	.EQU	$64		; KBD CTLR STATUS/CMD PORT
CLCD_BASE       .EQU    $0              ; HD44680 LCD I/O PORT
#ENDIF
;
lcd_command     .equ CLCD_BASE + $00     ;LCD command I/O port
lcd_data        .equ CLCD_BASE + $01     ;LCD data I/O port

;CLCD_STAT	.EQU	CLCD_BASE + 0		; STATUS PORT
;CLCD_CMD	.EQU	CLCD_BASE + 1		; COMMAND PORT
;CLCD_PARAM	.EQU	CLCD_BASE + 0		; PARAM PORT
;CLCD_READ	.EQU	CLCD_BASE + 1		; READ PORT
;CLCD_DAC_WR	.EQU	CLCD_DAC_BASE + 0	; RAMDAC ADR WRITE
;CLCD_DAC_RD      .EQU	CLCD_DAC_BASE + 3	; RAMDAC ADR READ
;CLCD_DAC_PALRAM  .EQU	CLCD_DAC_BASE + 1	; RAMDAC PALETTE RAM
;CLCD_DAC_PIXMSK  .EQU	CLCD_DAC_BASE + 2	; RAMDAC PIXEL READ MASK
;CLCD_DAC_OVL_WR  .EQU	CLCD_DAC_BASE + 4	; RAMDAC OVERLAY WRITE
;CLCD_DAC_OVL_RD  .EQU	CLCD_DAC_BASE + 7	; RAMDAC OVERLAY READ
;CLCD_DAC_OVL_RAM .EQU	CLCD_DAC_BASE + 5	; RAMDAC OVERLAY RAM
;
CLCD_ROWS	.EQU	16
CLCD_COLS	.EQU	40
;
; *** TODO: CGA AND EGA ARE PLACEHOLDERS.  THESE EQUATES SHOULD
; BE USED TO ALLOW FOR MULTIPLE MONITOR TIMINGS AND/OR FONT
; DEFINITIONS.
;
#IF (CLCDMON == CLCDMON_NONE)
;  #DEFINE	USEFONTCGA
;  #DEFINE	CLCD_FONT FONTCGA
#ENDIF
;
#IF (CLCDMON == CLCDMON_DJRM)
;  #DEFINE	USEFONT8X16
;  #DEFINE	CLCD_FONT FONT8X16
#ENDIF
;
TERMENABLE	.SET	TRUE		; INCLUDE TERMINAL PSEUDODEVICE DRIVER
;
;======================================================================
; CLCD DRIVER - INITIALIZATION
;======================================================================
;
CLCD_INIT:
	LD	IY,CLCD_IDAT		; POINTER TO INSTANCE DATA
	
	CALL	NEWLINE
	PRTS("CLCD: MODE=$")
#IF (CLCDMODE == CLCDMODE_ECB)
	PRTS("$")
#ENDIF
#IF (CLCDMODE == CLCDMODE_DJRM)
	PRTS("T6963$")
#ENDIF
;
#IF (CLCDMON == CLCDMON_NONE)
	PRTS(" NONE$")
#ENDIF	
#IF (CLCDMON == CLCDMON_DJRM)
	PRTS(" CUSTOM$")
#ENDIF	
;
	PRTS(" IO=0x$")
	LD	A,CLCD_BASE
	CALL	PRTHEXBYTE
	CALL	CLCD_PROBE		; CHECK FOR HW PRESENCE
	JR	Z,CLCD_INIT1		; CONTINUE IF HW PRESENT
;
	; HARDWARE NOT PRESENT
	PRTS(" NOT PRESENT$")
	OR	$FF			; SIGNAL FAILURE
	RET
;
CLCD_INIT1:
	CALL 	CLCD_CRTINIT		; SETUP THE CLCD CHIP REGISTERS
	CALL	CLCD_VDARES		; RESET CLCD
        CALL    T6963_INIT
	CALL	KBD_INIT		; INITIALIZE KEYBOARD DRIVER

	; ADD OURSELVES TO VDA DISPATCH TABLE
	LD	BC,CLCD_FNTBL		; BC := FUNCTION TABLE ADDRESS
	LD	DE,CLCD_IDAT		; DE := CLCD INSTANCE DATA PTR
	CALL	VDA_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED

	; INITIALIZE EMULATION
	LD	C,A			; C := ASSIGNED VIDEO DEVICE NUM
	LD	DE,CLCD_FNTBL		; DE := FUNCTION TABLE ADDRESS
	LD	HL,CLCD_IDAT		; HL := CLCD INSTANCE DATA PTR
	CALL	TERM_ATTACH		; DO IT

	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
; CLCD DRIVER - VIDEO DISPLAY ADAPTER (VDA) FUNCTIONS
;======================================================================
;
CLCD_FNTBL:
	.DW	CLCD_VDAINI
	.DW	CLCD_VDAQRY
	.DW	CLCD_VDARES
	.DW	CLCD_VDADEV
	.DW	CLCD_VDASCS
	.DW	CLCD_VDASCP
	.DW	CLCD_VDASAT
	.DW	CLCD_VDASCO
	.DW	CLCD_VDAWRC
	.DW	CLCD_VDAFIL
	.DW	CLCD_VDACPY
	.DW	CLCD_VDASCR
	.DW	KBD_STAT
	.DW	KBD_FLUSH
	.DW	KBD_READ
	.DW	CLCD_VDARDC
#IF (($ - CLCD_FNTBL) != (VDA_FNCNT * 2))
	.ECHO	"*** INVALID CLCD FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
CLCD_VDAINI:
	; RESET VDA
	CALL	CLCD_VDARES		; RESET VDA
	XOR	A			; SIGNAL SUCCESS
	RET
;
CLCD_VDAQRY:	; VIDEO INFORMATION QUERY
	LD	C,$00		; MODE ZERO IS ALL WE KNOW
	LD	D,CLCD_ROWS	; ROWS
	LD	E,CLCD_COLS	; COLS
	LD	HL,0		; EXTRACTION OF CURRENT BITMAP DATA NOT SUPPORTED YET
	XOR	A		; SIGNAL SUCCESS
	RET
;
CLCD_VDARES:	; VIDEO SYSTEM RESET
	; *** TODO: RESET VIDEO SYSTEM HERE, CLEAR SCREEN,
	; CURSOR TO TOP LEFT, CLEAR ATTRIBUTES
	CALL    T6963_CLEAR
	CALL    T6963_HOME
	XOR	A
	RET
;
CLCD_VDADEV:	; VIDEO DEVICE INFORMATION
	LD	D,VDADEV_CLCD	; D := DEVICE TYPE
	LD	E,0		; E := PHYSICAL UNIT IS ALWAYS ZERO
	LD	H,0		; H := 0, DRIVER HAS NO MODES
	LD	L,CLCD_BASE	; L := BASE I/O ADDRESS
	XOR	A		; SIGNAL SUCCESS
	RET
;
CLCD_VDASCS:	; SET CURSOR STYLE
	SYSCHKERR(ERR_NOTIMPL)
	RET

CLCD_VDASCP:	; SET CURSOR POSITION
	CALL	CLCD_XY		; SET CURSOR POSITION
	XOR	A		; SIGNAL SUCCESS
	RET

CLCD_VDASAT:	; SET ATTRIBUTES
	LD	A,E		; GET THE INCOMING ATTRIBUTE
	LD	(CLCD_ATTR),A	; AND SAVE FOR LATER
	XOR	A		; SIGNAL SUCCESS
	RET

CLCD_VDASCO:	; SET COLOR
	LD	A,E		; GET THE INCOMING COLOR
	LD	(CLCD_COLOR),A	; AND SAVE FOR LATER
	XOR	A		; SIGNAL SUCCESS
	RET

CLCD_VDAWRC:	; WRITE CHARACTER
	LD	A,E		; CHARACTER TO WRITE GOES IN A
	CALL	CLCD_PUTCHAR	; PUT IT ON THE SCREEN
;	CALL    CLCD_PUTATTR
	XOR	A		; SIGNAL SUCCESS
	RET

CLCD_VDAFIL:	; FILL WITH CHARACTER
	LD	A,E		; FILL CHARACTER GOES IN A
	EX	DE,HL		; FILL LENGTH GOES IN DE
	CALL	CLCD_FILL	; DO THE FILL
	XOR	A		; SIGNAL SUCCESS
	RET

CLCD_VDACPY:	; COPY CHARACTERS/ATTRIBUTES
	; LENGTH IN HL, SOURCE ROW/COL IN DE, DEST IS CLCD_POS
	; BLKCPY USES: HL=SOURCE, DE=DEST, BC=COUNT
	PUSH	HL		; SAVE LENGTH
	CALL	CLCD_XY2IDX	; ROW/COL IN DE -> SOURCE ADR IN HL
	POP	BC		; RECOVER LENGTH IN BC
	LD	DE,(CLCD_POS)	; PUT DEST IN DE
	JP	CLCD_BLKCPY	; DO A BLOCK COPY

CLCD_VDASCR:	; SCROLL ENTIRE SCREEN
	LD	A,E		; LOAD E INTO A
	OR	A		; SET FLAGS
	RET	Z		; IF ZERO, WE ARE DONE
	PUSH	DE		; SAVE E
	JP	M,CLCD_VDASCR1	; E IS NEGATIVE, REVERSE SCROLL
	CALL	CLCD_SCROLL	; SCROLL FORWARD ONE LINE
	POP	DE		; RECOVER E
	DEC	E		; DECREMENT IT
	JR	CLCD_VDASCR	; LOOP
CLCD_VDASCR1:
	CALL	CLCD_RSCROLL	; SCROLL REVERSE ONE LINE
	POP	DE		; RECOVER E
	INC	E		; INCREMENT IT
	JR	CLCD_VDASCR	; LOOP
;
CLCD_VDARDC:	; READ CHAR/ATTR VALUE FROM VIDEO BUFFER
	OR	$FF		; UNSUPPORTED FUNCTION
	RET
;
;======================================================================
; CLCD DRIVER - PRIVATE DRIVER FUNCTIONS
;======================================================================
;
;----------------------------------------------------------------------
; PROBE FOR CLCD HARDWARE
;----------------------------------------------------------------------
;
; ON RETURN, ZF SET INDICATES HARDWARE FOUND
;
; *** TODO: IMPLEMENT THIS
;
CLCD_PROBE:
	XOR	A			; SIGNAL SUCCESS
	RET				; RETURN WITH ZF SET BASED ON CP
;
;----------------------------------------------------------------------
; DISPLAY CONTROLLER CHIP INITIALIZATION
;----------------------------------------------------------------------
;
; *** TODO: IMPLEMENT THIS
;
CLCD_CRTINIT:
	XOR	A			; SIGNAL SUCCESS
	RET
;
;----------------------------------------------------------------------
; SET CURSOR POSITION TO ROW IN D AND COLUMN IN E
;----------------------------------------------------------------------
;
CLCD_XY:
        push de
	CALL	CLCD_XY2IDX		; CONVERT ROW/COL TO BUF IDX
	LD	(CLCD_POS),HL		; SAVE THE RESULT (DISPLAY POSITION)
	; *** TODO: MOVE THE CURSOR
	pop de
	call    T6963_POSITION
	
	RET
;
;----------------------------------------------------------------------
; CONVERT XY COORDINATES IN DE INTO LINEAR INDEX IN HL
; D=ROW, E=COL
;----------------------------------------------------------------------
;
CLCD_XY2IDX:
	LD	A,E			; SAVE COLUMN NUMBER IN A
	LD	H,D			; SET H TO ROW NUMBER
	LD	E,CLCD_COLS		; SET E TO ROW LENGTH
	CALL	MULT8			; MULTIPLY TO GET ROW OFFSET
	LD	E,A			; GET COLUMN BACK
	ADD	HL,DE			; ADD IT IN
	RET				; RETURN
;
;----------------------------------------------------------------------
; WRITE VALUE IN A TO CURRENT VDU BUFFER POSITION, ADVANCE CURSOR
;----------------------------------------------------------------------
;
CLCD_PUTCHAR:
	; *** TODO: IMPLEMENT THIS
	CALL    T6963_PUTC
	RET
;
;----------------------------------------------------------------------
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING AT THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
;----------------------------------------------------------------------
;
CLCD_FILL:
	; *** TODO: IMPLEMENT THIS
	CALL    T6963_FILL
	RET
;
;----------------------------------------------------------------------
; SCROLL ENTIRE SCREEN FORWARD BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
CLCD_SCROLL:
	; *** TODO: IMPLEMENT THIS
	call    T6963_SCROLL
	RET
;
;----------------------------------------------------------------------
; REVERSE SCROLL ENTIRE SCREEN BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
CLCD_RSCROLL:
	; *** TODO: IMPLEMENT THIS
	RET
;
;----------------------------------------------------------------------
; BLOCK COPY BC BYTES FROM HL TO DE
;----------------------------------------------------------------------
;
CLCD_BLKCPY:
	; *** TODO: IMPLEMENT THIS
	RET
;
;==================================================================================================
;   CLCD DRIVER - DATA
;==================================================================================================
;
CLCD_ATTR	.DB	0	; CURRENT ATTRIBUTES
CLCD_COLOR	.DB	0	; CURRENT COLOR
CLCD_POS		.DW 	0	; CURRENT DISPLAY POSITION
;
;==================================================================================================
;   CLCD DRIVER - INSTANCE DATA
;==================================================================================================
;
CLCD_IDAT:
	.DB	CLCD_KBDST
	.DB	CLCD_KBDDATA
