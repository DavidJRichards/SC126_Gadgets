;------------------------------------------------------------------------------
RTCIO		EQU	0xC		; RTC LATCH REGISTER ADR
Z180BASE	equ	0xC0
Z180CNTR	EQU	Z180BASE + 0xA	; CSI/O CONTROL
Z180TRDR	EQU	Z180BASE + 0xB	; CSI/O TRANSMIT/RECEIVE

OPRDEF	EQU	00001100b	; QUIESCENT STATE (/CS1 & /CS2 DEASSERTED)
OPRMSK	EQU	00001100b	; MASK FOR BITS WE OWN IN RTC LATCH PORT
CS0	EQU	00000100b	; RTC:2 IS SELECT FOR PRIMARY SPI CARD
CS1	EQU	00001000b	; RTC:3 IS SELECT FOR SECONDARY SPI CARD
CNTR	EQU	Z180CNTR
CNTR_TE	equ 	10h
CNTR_RE	equ	20h
TRDR	EQU	Z180TRDR
IOSYSTEM equ	RTCIO

SECTION code_driver

PUBLIC _cslower
PUBLIC _csraise
PUBLIC _lmirror
PUBLIC _readbyte
PUBLIC _writebyte


; reverse or mirror the bits in a byte
; 76543210 -> 01234567
;
; 18 bytes / 70 cycles
;
; from http://www.retroprogramming.com/2014/01/fast-z80-bit-reversal.html
;
; enter :  a = byte
;
; exit  :  a, l = byte reversed
; uses  : af, l
    
_lmirror:
    ld l,a      ; a = 76543210
    rlca
    rlca        ; a = 54321076
    xor l
    and 0xAA
    xor l       ; a = 56341270
    ld l,a
    rlca
    rlca
    rlca        ; a = 41270563
    rrc l       ; l = 05634127
    xor l
    and 0x66
    xor l       ; a = 01234567
    ld l,a
    ret

;Lower the SC130 SD card CS using the GPIO address
;
;input (H)L = SD CS selector of 0 or 1
;uses AF

_cslower:
    in0 a,(CNTR)            ;check the CSIO is not enabled
    and CNTR_TE|CNTR_RE
    jr NZ,_cslower

    ld a,l
    and 01h                 ;isolate SD CS 0 and 1 (to prevent bad input).    
    inc a                   ;convert input 0/1 to SD1/2 CS
    xor 03h                 ;invert bits to lower correct I/O bit.
    rlca
    rlca                    ;SC130 SD1 CS is on Bit 2 (SC126 SD2 is on Bit 3).
    out (IOSYSTEM),a
    ret

;Raise the SC180 SD card CS using the GPIO address
;
;uses AF

_csraise:
    in0 a,(CNTR)            ;check the CSIO is not enabled
    and CNTR_TE|CNTR_RE
    jr NZ,_csraise

    ld a,0Ch                ;SC130 SC1 CS is on Bit 2 and SC126 SC2 CS is on Bit 3, raise both.
    out (IOSYSTEM),a
    ret


;Do a write bus cycle to the SD drive, via the CSIO
;
;input L = byte to write to SD drive
    
_writebyte:
    ld a,l
    call _lmirror           ; reverse the bits before we busy wait
writewait:
    in0 a,(CNTR)
    tst CNTR_TE|CNTR_RE     ; check the CSIO is not enabled
    jr NZ,writewait

    or a,CNTR_TE            ; set TE bit
    out0 (TRDR),l           ; load (reversed) byte to transmit
    out0 (CNTR),a           ; enable transmit
    ret

;Do a read bus cycle to the SD drive, via the CSIO
;  
;output L = byte read from SD drive

_readbyte:
    in0 a,(CNTR)
    tst CNTR_TE|CNTR_RE     ; check the CSIO is not enabled
    jr NZ,_readbyte

    or a,CNTR_RE            ; set RE bit
    out0(CNTR),a            ; enable reception
readwait:
    in0 a,(CNTR)
    tst CNTR_RE             ; check the read has completed
    jr NZ,readwait

    in0 a,(TRDR)            ; read byte
    jp _lmirror             ; reverse the byte, leave in L and A

;------------------------------------------------------------------------------

