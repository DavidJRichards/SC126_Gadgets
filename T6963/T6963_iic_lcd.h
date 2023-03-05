/* MCP23S17 - Microchip MCP23S17 16-bit Port Extender using SPI
* Copyright (c) 2010 Gert van der Knokke
*/

#define IODIRA      0x00
#define IODIRB      0x01
#define IPOLA       0x02
#define IPOLB       0x03
#define GPINTENA    0x04
#define GPINTENB    0x05
#define DEFVALA     0x06
#define DEFVALB     0x07
#define INTCONA     0x08
#define INTCONB     0x09
#define IOCONA      0x0A
#define IOCONB      0x0B
#define GPPUA       0x0C
#define GPPUB       0x0D
#define INTFA       0x0E
#define INTFB       0x0F
#define INTCAPA     0x10
#define INTCAPB     0x11
#define GPIOA       0x12
#define GPIOB       0x13
#define OLATA       0x14
#define OLATB       0x15

// LCD pin connections / port A / pin numbers
// D0, pin 1
// D1, pin 2
// D2, pin 3
// D3, pin 4
// D4, pin 5
// D5, pin 6
// D6, pin 7

// LCD pin connections / port B bit values / pin numbers
#define LCD_HALT    0x80	// pin 28
				// pin 27
#define LCD_FS      0x20	// pin 26
#define LCD_RST     0x10	// pin 25
#define LCD_CD      0x08	// pin 24
#define LCD_CE      0x04	// pin 23
#define LCD_RD      0x02	// pin 22
#define LCD_WR      0x01	// pin 21


/***********************************************************************************************  
*                                       DESCRIPTION  
*  
* This module provides an interface to Toshiba T6963C-0101 Graphical LCD of size 128x64 dots  
* A 128-word character generator ROM (code 0101) T6963C-0101 built-in.  
* Graphics l.c.d. pinout function  
* pin 1 FG  frame ground  
* pin 2 GND signal ground  
* pin 3 +5V Positive supply  
* pin 4 CX  Negative supply (-3.5V approx)  
* pin 5 WR  Data write (active low)  
* pin 6 RD  Data read (active low)  
* pin 7 CE  Chip enable (active low)  
* pin 8 CD  CD=1, WR=0: command write  
*           CD=1, WR=1: command read  
*           CD=0, WR=0: data write  
*           CD=0, WR=1: data read  
* pin 9 RST Module reset (active low)  
* pin 10 - 17   Data bus  
* pin 18 FS Font select: FS=0(8x8 font), FS=1(or open circuit, 6x8 font)  
* On EQS console ver 2.5 PCB, FS is determined by JP23 jumper. FS=0 when shorted  
*  

* 20 way sheield connector:
* as MGL24064 LCD 240x64
* pin  1	nc Frame ground
* pin  2	0v
* pin  3	5v
* pin  4	nc V0 for lcd
* pin  5	WR
* pin  6	RD
* pin  7	CE
* pin  8	CD
* pin  9	nc
* pin 10	RST
* pin 11	D0
* pin 12	D1
* pin 13	D2
* pin 14	D3
* pin 15	D4
* pin 16	D5
* pin 17	D6
* pin 18	D7
* pin 19	FS
* pin 20	nc

* 20 way SIL connector on 240x128 display
* pin  1	0V
* pin  2	5v
* pin  3	CONTRAST SUPPLY
* pin  4	CD
* pin  5	RD
* pin  6	WR
* pin  7	D0
* pin  8	D1
* pin  9	D2
* pin 10	D3
* pin 11	D4
* pin 12	D5
* pin 13	D6
* pin 14	D7
* pin 15	CE
* pin 16	RST?
* pin 17	CONTRAST WIPER
* pin 18	0V (fs?)
* pin 19	0V
* pin 20	nc

***********************************************************************************************/ 

//      T6963C OPCODES
#define TXHOME      0x40    // SET TXT HOME ADDRESS
#define TXAREA      0x41    // SET TXT AREA
#define GRHOME      0x42    // SET GRAPHIC HOME ADDRESS
#define GRAREA      0x43    // SET GRAPHIC AREA
#define OFFSET      0x22    // SET OFFSET ADDRESS
#define ADPSET      0x24    // SET ADDRESS POINTER
#define AWRON       0xB0    // SET AUTO WRITE MODE
#define AWROFF      0xB2    // RESET AUTO WRITE MODE


/* This file contains definitions for all of the commands in a t6963. */
/********************************************************************/
/*  Register set */
#define CPS 0x21 //Cursor pointer set
#define ORS 0x22 //Offset register set
#define APS 0x24 //Address pointer set
#define THAS 0x40 //Text home address set
#define TAS 0x41 //Text area set
#define GHAS 0x42 //Graphic home address set
#define GAS 0x43 //Graphic area set
#define OM 0x80 //OR mode
#define EM 0x81 //EXOR mode
#define AM 0x83 //AND mode
#define TAM 0x84 //TEXT ATTRIBUTE mode
#define DOF 0x90 //Display OFF
#define CONBOF 0x92 //Cursor ON, Blink OFF
#define CONBON 0x93 //Cursor ON, Blink ON
#define TONGOF 0x94 //Text ON, Graphic OFF
#define TOFGON 0x98 //Text OFF, Graphic ON
#define TONGON 0x9C //Text ON, Graphic ON
#define LC1 0xA0 //1 Line cursor
#define LC2 0xA1 //2 Line cursor
#define LC3 0xA2 //3 Line cursor
#define LC4 0xA3 //4 Line cursor
#define LC5 0xA4 //5 Line cursor
#define LC6 0xA5 //6 Line cursor
#define LC7 0xA6 //7 Line cursor
#define LC8 0xA7 //8 Line cursor
#define DAWS 0xB0 //Data auto write set
#define DARS 0xB1 //Data auto read set
#define AR 0xB2 //Auto reset
#define DWAAI 0xC0 //Data write and ADP increment
#define DRAAI 0xC1 //Data read and ADP increment
#define DWAAD 0xC2 //Data write and ADP decrement
#define DRAAD 0xC3 //Data read and ADP decrement
#define DWAAN 0xC4 //Data write and ADP nonvariable
#define DRAAN 0xC5 //Data read and ADP nonvariable
#define SP 0xE0 //Screen PEEK
#define SC 0xE8 //Screen COPY
#define BR 0xF0 //Bit RESET
#define BS 0xF8 //Bit SET
//add 3 bit data to these
//commands to select bit


/*
const byte T6963_CURSOR_PATTERN_SELECT=0xA0; //cursor patter select command prefix or with desired size-1.
const byte T6963_DISPLAY_MODE=0x90; 
const byte T6963_MODE_SET=0x80;
const byte T6963_SET_CURSOR_POINTER=0x21;
const byte T6963_SET_OFFSET_REGISTER=0x22;
const byte T6963_SET_ADDRESS_POINTER=0x24;
const byte T6963_SET_TEXT_HOME_ADDRESS=0x40;
const byte T6963_SET_TEXT_AREA=0x41;
const byte T6963_SET_GRAPHIC_HOME_ADDRESS=0x42;
const byte T6963_SET_GRAPHIC_AREA=0x43;
const byte T6963_SET_DATA_AUTO_WRITE=0xB0;
const byte T6963_SET_DATA_AUTO_READ=0xB1;
const byte T6963_AUTO_RESET=0xB2;

const byte T6963_DATA_WRITE_AND_INCREMENT=0xC0;
const byte T6963_DATA_READ_AND_INCREMENT=0xC1;
const byte T6963_DATA_WRITE_AND_DECREMENT=0xC2;
const byte T6963_DATA_READ_AND_DECREMENT=0xC3;
const byte T6963_DATA_WRITE_AND_NONVARIALBE=0xC4;
const byte T6963_DATA_READ_AND_NONVARIABLE=0xC5;

const byte T6963_SCREEN_PEEK=0xE0;
const byte T6963_SCREEN_COPY=0xE8;
*/
