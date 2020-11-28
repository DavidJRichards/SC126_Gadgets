#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <z80.h>
#include <math.h>
#include <time.h>
#include <lib/scz180/time.h>
#include <arch/scz180.h>

// zcc +scz180 -subtype=hbios -v --list -m -SO3 --c-code-in-asm  -clib=sdcc_iy -lm -llib/scz180/time --max-allocs-per-node200000 DS1302.c  -o ds1302  -create-app


// SC126 built-in I2C port definitions
#define I2C_PORT	0x0C	// Host I2C port address
__sfr __at I2C_PORT IO_I2C;	// Host I2C port i/o
#define I2C_SDA_WR	7	// Host I2C write SDA bit number
#define I2C_SCL_WR	0	// Host I2C write SCL bit number
#define I2C_SDA_RD	7	// Host I2C read SDA bit number

//; Constants
#define mask_data	0b10000000	; RTC data line		RTC_DOUT & I2C_SDA_WR & I2C_SDA_RD
#define mask_clk	0b01000000	; RTC Serial Clock line	RTC_SCLK
#define mask_rd		0b00100000	; Enable data read from nRTC_WE
#define mask_rst	0b00010000	; De-activate RTC reset nRTC_CE
//			0b00001000	; 			nSD_CS2
//			0b00000100	; 			nSD_CS1
//			0b00000010	; 			FS
//			0b00000001	; 			I2C_SCL_WR


void wait(unsigned long loops) 		// wait for a bit
{
  int ia=0;
  unsigned long wd;
loops=500;
  for(wd=0L; wd<loops; wd++)
  {
    ia=ia+1;
  }
  return;
}


volatile int i2c_ramcpy;
#define I2C_SCL_HI  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy |   (1 << I2C_SCL_WR) ) )
#define I2C_SCL_LO  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << I2C_SCL_WR) ) )
#define I2C_SDA_HI  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy |   (1 << I2C_SDA_WR) ) )
#define I2C_SDA_LO  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << I2C_SDA_WR) ) )
#define I2C_WrPort(data)  ( i2c_ramcpy = IO_I2C = data ) 
#define I2C_RdPort  (IO_I2C)






//////////////////////////////////////////////////////////////////////////
////                               DS1302.C                           ////
////                     Driver for Real Time Clock                   ////
////                                                                  ////
////  rtc_init()                                   Call after power up////
////                                                                  ////
////  rtc_set_datetime(day,mth,year,dow,hour,min)  Set the date/time  ////
////                                                                  ////
////  rtc_get_date(day,mth,year,dow)               Get the date       ////
////                                                                  ////
////  rtc_get_time(hr,min,sec)                     Get the time       ////
////                                                                  ////
////  rtc_write_nvr(address,data)                  Write to NVR       ////
////                                                                  ////
////  data = rtc_read_nvr(address)                 Read from NVR      ////
////                                                                  ////
//////////////////////////////////////////////////////////////////////////

void write_ds1302_byte(unsigned char cmd);
void write_ds1302(unsigned char cmd, unsigned char data);
unsigned char read_ds1302(unsigned char cmd);
void rtc_init();
void rtc_set_datetime(unsigned char day, unsigned char mth, unsigned char year, unsigned char dow, unsigned char hr, unsigned char min);
void rtc_get_date(unsigned char *day, unsigned char *mth, unsigned char *year, unsigned char *dow);
void rtc_get_time(unsigned char *hr, unsigned char *min, unsigned char *sec);
void rtc_write_nvr(unsigned char address, unsigned char data);
unsigned char rtc_read_nvr(unsigned char address);

#if 0
char Shift_Left(char* address, char bytes, char value) {
   char oldch, ch, carry;
   
   // set carry for the lowest (first) byte:
   carry = 0;
   if (value)       // if nonzero:
      carry.B0 = 1; // 1 to be shifted in to new LSB
   for ( ; bytes ; ++address, --bytes ) { // loop 'bytes' times
 
      oldch = ch = *address; // get and save the actual byte
      ch <<= 1; // left shifted one times and ch.B0 = 0
      if (carry.B0)
         ch.B0 = 1;
      *address = ch; // write it back to the array
      // set carry for the next byte:
      carry = 0;
      if (oldch.B7)
         carry.B0 = 1; // carry = 1

   } // end for
   return carry; // out-shifted bit (original MSB), 0 or 1
}

unsigned char shift_right(unsigned char* address, unsigned char bytes, unsigned char value) {
   unsigned char oldch, ch, carry;

   // set carry for the highest (last) byte:
   carry = 0;
   if (value)            // if nonzero:
      carry.B0 = 1;      // 1 to be shifted in to new MSB
   address += bytes - 1; // points to last byte
   for ( ; bytes ; --address, --bytes ) { // loop 'bytes' times

      oldch = ch = *address; // get and save the actual byte
      ch >>= 1; // right shifted one times and ch.B7 = 0
      if (carry.B0)
         ch.B7 = 1;
      *address = ch; // write it back to the array
      // set carry for the next byte:
      carry = 0;
      if (oldch.B0)
         carry.B0 = 1; // carry = 1

   } // end for
   return carry; // out-shifted bit (original LSB), 0 or 1
}
#endif 

unsigned char shift_right(unsigned char *data, unsigned char nbits, unsigned char inbit)
{
  unsigned char outbit;
  outbit = *data & x01 : 1 ? 0;
  *data >> 1;
  *data |= inbit & 0x01 : 0x80 : 0;
  return outbit; 
}

void write_ds1302_byte(unsigned char cmd) {
   unsigned char i;

   for(i=0;i<=7;++i) {
      output_bit(RTC_IO, shift_right(&cmd,1,0) );
      output_high(RTC_SCLK);
      output_low(RTC_SCLK);
   }
}

void write_ds1302(unsigned char cmd, unsigned char data) {

   output_high(RTC_RST);
   write_ds1302_byte(cmd);
   write_ds1302_byte(data);
   output_low(RTC_RST);
}

unsigned char read_ds1302(unsigned char cmd) {
   unsigned char i,data;

   output_high(RTC_RST);
   write_ds1302_byte(cmd);

   for(i=0;i<=7;++i) {
      shift_right(&data,1,input(RTC_IO));
      output_high(RTC_SCLK);
      delay_us(2);
      output_low(RTC_SCLK);
      delay_us(2);
   }
   output_low(RTC_RST);
   return(data);
}

void rtc_init() {
   unsigned char x;
   output_low(RTC_RST);
   delay_us(2);
   output_low(RTC_SCLK);
   write_ds1302(0x8e,0);
   write_ds1302(0x90,0xa6);
   x=read_ds1302(0x81);
   if((x & 0x80)!=0)
     write_ds1302(0x80,0);
}

void rtc_set_datetime(unsigned char day, unsigned char mth, unsigned char year, unsigned char dow, unsigned char hr, unsigned char min) {
   write_ds1302(0x86,day);
   write_ds1302(0x88,mth);
   write_ds1302(0x8c,year);
   write_ds1302(0x8a,dow);
   write_ds1302(0x84,hr);
   write_ds1302(0x82,min);
   write_ds1302(0x80,0);
}

void rtc_get_date(unsigned char& day, unsigned char& mth, unsigned char& year, unsigned char& dow) {
   day = read_ds1302(0x87);
   mth = read_ds1302(0x89);
   year = read_ds1302(0x8d);
   dow = read_ds1302(0x8b);
}


void rtc_get_time(unsigned char& hr, unsigned char& min, unsigned char& sec) {
   hr = read_ds1302(0x85);
   min = read_ds1302(0x83);
   sec = read_ds1302(0x81);
}

void rtc_write_nvr(unsigned char address, unsigned char data) {
   write_ds1302(address|0xc0,data);
}

unsigned char rtc_read_nvr(unsigned char address) {
    return(read_ds1302(address|0xc1));
}

void main(void)
{
   rtc_init();
   rtc_get_date( day, mth, year, dow);
   printf("%d/%d/%d', day, mth, year );
   printf("    ");
   rtc_get_time( hour, min, sec );
   printf("%d:%d:%d', hour, min, sec );
   printf("\r");


    // setup time structure
    t.tm_sec = sec;    // 0-59
    t.tm_min = min;    // 0-59
    t.tm_hour = hour;   // 0-23
    t.tm_mday = day;   // 1-31
    t.tm_mon = mth;     // 0-11
    t.tm_year = year;  // year since 1900
    t.tm_isdst = 0;

    ltime = time(&t);

    set_system_time(ltime - UNIX_TIME) ;
    printf("\n\rltime=%ld",ltime);

    /* Print the local time as a string */
    printf("\n\rThe current date and time are %s", asctime(newtime));




}

#if 0
void rtc_init() {
   output_low(RTC_CE);
   output_low(RTC_IO);
}


void write_rtc_byte(BYTE data_byte, BYTE number_of_bits) {
   BYTE i;

   for(i=0; i<number_of_bits; ++i) {
      if((data_byte & 1)==0)
        output_low(RTC_DATA);
      else
        output_high(RTC_DATA);
      data_byte=data_byte>>1;
      output_high(RTC_CLK);
      output_low(RTC_CLK);
   }
}


BYTE read_rtc_byte(BYTE number_of_bits) {
   BYTE i,data;

   for(i=0;i<number_of_bits;++i) {
      output_high(RTC_CLK);
      shift_right(&data,1,input(RTC_DATA));
      output_low(RTC_CLK);
   }
   return(data);
}


void rtc_set_datetime(BYTE day, BYTE mth, BYTE year, BYTE dow,
                      BYTE hour, BYTE min){

   output_low(RTC_CLK);
   output_high(RTC_IO);
   output_high(RTC_CE);
   write_rtc_byte(year,8);
   write_rtc_byte(mth,8);
   write_rtc_byte(day,8);
   write_rtc_byte(dow,4);
   write_rtc_byte(hour,8);
   write_rtc_byte(min,8);
   output_low(RTC_CE);
   output_low(RTC_IO);
}


void rtc_get_date(BYTE& day, BYTE& mth, BYTE& year, BYTE& dow) {
   output_low(RTC_CLK);
   output_low(RTC_IO);
   output_high(RTC_CE);
   year=read_rtc_byte(8);
   mth=read_rtc_byte(8);
   day=read_rtc_byte(8);
   dow=read_rtc_byte(4)>>4;

   read_rtc_byte(8*3);
   output_low(RTC_CE);
   output_low(RTC_IO);
}


void rtc_get_time(BYTE& hr, BYTE& min, BYTE& sec) {
   output_low(RTC_CLK);
   output_low(RTC_IO);
   output_high(RTC_CE);
   read_rtc_byte(8*3+4);
   hr=read_rtc_byte(8);
   min=read_rtc_byte(8);
   sec=read_rtc_byte(8);

   output_low(RTC_CE);
   output_low(RTC_IO);
}

#endif

