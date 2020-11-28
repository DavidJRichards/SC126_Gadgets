// Demo program displaying an analog clock
// on a T6963 based LCD connected to the mbed through 
// SPI with a MCP23S17 thereby using only 4 pins I/O
// by Gert van der Knokke 2010
//#include "mbed.h"
//
// zcc +scz180 -subtype=hbios -v --list -m -SO3 --c-code-in-asm  -clib=sdcc_iy -lm -llib/scz180/time --max-allocs-per-node200000 T6963_SPI_LCD.c  -o t6963  -create-app
//
//

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <z80.h>
#include <math.h>
#include <time.h>
#include <lib/scz180/time.h>

#include "T6963_iic_lcd.h"

extern void rtc_init(void);
extern void rtc_get_date(unsigned char *day, unsigned char *mth, unsigned char *year, unsigned char *dow);
extern void rtc_get_time(unsigned char *hr, unsigned char *min, unsigned char *sec);


// SC126 built-in I2C port definitions
#define I2C_PORT	0x0C	// Host I2C port address
__sfr __at I2C_PORT IO_I2C;	// Host I2C port i/o

// input and output register bit definitions
#define I2C_SDA_WR	7	// Host I2C write SDA bit number
#define I2C_SCL_WR	0	// Host I2C write SCL bit number
#define I2C_SDA_RD	7	// Host I2C read SDA bit number

#define RTC_SCLK	6	// RTC Serial Clock line
#define RTC_DOUT	7 	// RTC Data write,  also I2C_SDA_WR & I2C_SDA_RD
#define RTC_DIN		0	// RTC data read
#define RTC_WE		5	// RTC not write enable
#define RTC_CE		4	// RTC not chip enable

volatile int i2c_ramcpy;	// readable copy of output register
// register i/o read/write macros
#define I2C_SCL_HI  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy |   (1 << I2C_SCL_WR) ) )
#define I2C_SCL_LO  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << I2C_SCL_WR) ) )
#define I2C_SDA_HI  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy |   (1 << I2C_SDA_WR) ) )
#define I2C_SDA_LO  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << I2C_SDA_WR) ) )
#define I2C_WrPort(data)  ( i2c_ramcpy = IO_I2C = data ) 
#define I2C_RdPort  (IO_I2C)
#define RTC_OUT_HI(iobit)           ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy |   (1 << iobit) ) )
#define RTC_OUT_LO(iobit)           ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << iobit) ) )
#define RTC_OUT_BIT(iobit,databit)  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << iobit) ) | (databit << iobit) )
#define RTC_IN_BIT(iobit)           ( IO_I2C & (1 << iobit) )

// DS1302 Internal register addresses
#define DS1802_WR_SEC	0x80
#define DS1802_RD_SEC	0x81
#define DS1802_WR_MIN	0x82
#define DS1802_RD_MIN	0x83
#define DS1802_WR_HOUR	0x84
#define DS1802_RD_HOUR	0x85
#define DS1802_WR_DATE	0x86
#define DS1802_RD_DATE	0x87
#define DS1802_WR_MONTH	0x88
#define DS1802_RD_MONTH	0x89
#define DS1802_WR_DAY	0x8A
#define DS1802_RD_DAY	0x8B
#define DS1802_WR_YEAR	0x8C
#define DS1802_RD_YEAR	0x8D
#define DS1802_WR_WP	0x8E
#define DS1802_RD_WP	0x8F
#define DS1802_WR_TC	0x90
#define DS1802_RD_TC	0x91
#define DS1802_RD_CKBST	0xBF
#define DS1802_WR_BRAM	0xC0
#define DS1802_RD_BRAM	0xC1
#define DS1802_RD_CKBST	0xFE


// MCP23017 attached to I2c bus
#define I2C_ADDR	2 * 0x20	// I2C MCP23017 device addess


// for 21 characters on a row (6x8 font)
//#define LCDFONTSEL  0xFF
// for 16 characters on a row (8x8 font)
#define LCDFONTSEL  (0xFF - LCD_FS)

// lcd dimensions in pixels
#define LCD_XWIDTH     240
#define LCD_YHEIGHT    128
#define LCD_KBYTES	8

#if LCDFONTSEL == 0xFF
// lcd dimensions in characters
#warning 8x6 font
#define LCD_WIDTH   22
#define LCD_HEIGHT  8
#define PIXELWIDTH  6
#else
#warning 8x8 font
#define LCD_WIDTH   16
#define LCD_HEIGHT  8
#define PIXELWIDTH  8
#endif

//#define TEXT_STARTADDRESS       0x0000
//#define GRAPHIC_STARTADDRESS    0x1000
#define TEXT_STARTADDRESS       0x000
#define GRAPHIC_STARTADDRESS    0x280


#define  GLCD_NUMBER_OF_LINES LCD_YHEIGHT
#define  GLCD_PIXELS_PER_LINE LCD_XWIDTH
#define  _FW PIXELWIDTH
#define  _GA (LCD_XWIDTH / PIXELWIDTH)		//Supercedes GLCD_GRAPHIC_AREA
#define  _TA (LCD_XWIDTH / PIXELWIDTH)		//Supercedes GLCD_TEXT_AREA
#define  _sizeMem  LCD_KBYTES			//size of attached memory in kb.
#define  sizeGA  (_GA*LCD_YHEIGHT)		//Supercedes GLCD_GRAPHIC_SIZE
#define  sizeTA  (_TA*LCD_YHEIGHT/8)		//Supercedes GLCD_TEXT_SIZE

#define _TH 0
#define _GH (_TH+sizeTA)

   
#define CENTERX 190
#define CENTERY 50
#define INNER_RADIUS    46
#define OUTER_RADIUS    48
#define CENTER_CIRCLE   5



//DigitalOut myled(LED1);
//SPI spi(p5, p6, p7); // mosi, miso, sclk
//DigitalOut cs(p20);

//Serial pc(USBTX, USBRX); // tx, rx

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


unsigned char bcd(unsigned char input)
{
  unsigned char result;
  result = 10 * (input>>4);
  result += (input % 16);
  return result;
}


unsigned char shift_right(unsigned char *data, unsigned char nbits, unsigned char inbit)
{
  unsigned char outbit;
  outbit = (*data) & 0x1 ? 1 : 0;
  *data >>= nbits;
  *data |= inbit & 0x01 ? 0x80 : 0;
  return outbit; 
}

void write_ds1302_byte(unsigned char cmd) {
   unsigned char i;
   unsigned char bit;
   //printf("cmd=%2x:",cmd);
   for(i=0;i<=7;++i) 
   {
      bit = shift_right(&cmd,1,0);
      //printf("%d",bit);
      RTC_OUT_BIT(RTC_DOUT,bit);
      RTC_OUT_HI(RTC_SCLK);
      RTC_OUT_HI(RTC_SCLK);
      RTC_OUT_LO(RTC_SCLK);
   }
   //printf("\n\r");
}

void write_ds1302(unsigned char cmd, unsigned char data) {

   RTC_OUT_LO(RTC_WE);
   RTC_OUT_HI(RTC_CE);
   write_ds1302_byte(cmd);
   write_ds1302_byte(data);
   RTC_OUT_LO(RTC_CE);
   RTC_OUT_HI(RTC_WE);
}

unsigned char read_ds1302(unsigned char cmd) {
   unsigned char i,data,bit;

   RTC_OUT_LO(RTC_WE);
   RTC_OUT_HI(RTC_CE);
   write_ds1302_byte(cmd);

   RTC_OUT_HI(RTC_WE);
   //printf("\n\rdata:%c",bit);
   for(i=0;i<=7;++i) 
   {
      bit = RTC_IN_BIT(RTC_DIN);
      //printf("%c",0x30+bit);
      shift_right(&data,1,bit);
      RTC_OUT_HI(RTC_SCLK);
      RTC_OUT_HI(RTC_SCLK);
      RTC_OUT_LO(RTC_SCLK);
   }
   //printf(" %2x, ",data);
   RTC_OUT_HI(RTC_WE);
   RTC_OUT_LO(RTC_CE);
   return(data);
}

void rtc_init() {
   unsigned char x;
   RTC_OUT_LO(RTC_DOUT);
   RTC_OUT_HI(RTC_CE);
   RTC_OUT_LO(RTC_WE);
   RTC_OUT_LO(RTC_SCLK);
   write_ds1302(DS1802_WR_WP,0);
   write_ds1302(DS1802_WR_TC,0xa6);
   x=read_ds1302(DS1802_RD_SEC);
   if((x & 0x80)!=0)
     write_ds1302(DS1802_WR_SEC,0);
}

void rtc_set_datetime(unsigned char day, unsigned char mth, unsigned char year, unsigned char dow, unsigned char hr, unsigned char min) {
   write_ds1302(DS1802_WR_DATE,day);
   write_ds1302(DS1802_WR_MONTH,mth);
   write_ds1302(DS1802_WR_YEAR,year);
   write_ds1302(DS1802_WR_DAY,dow);
   write_ds1302(DS1802_WR_HOUR,hr);
   write_ds1302(DS1802_WR_MIN,min);
   write_ds1302(DS1802_WR_SEC,0);
}

void rtc_get_date(unsigned char *day, unsigned char *mth, unsigned char *year, unsigned char *dow) {
   *day = bcd(read_ds1302(DS1802_RD_DATE));
   *mth = bcd(read_ds1302(DS1802_RD_MONTH));
   *year = bcd(read_ds1302(DS1802_RD_YEAR));
   *dow = read_ds1302(DS1802_RD_DAY);
}


void rtc_get_time(unsigned char *hr, unsigned char *min, unsigned char *sec) {
   *hr = bcd(read_ds1302(DS1802_RD_HOUR));
   *min = bcd(read_ds1302(DS1802_RD_MIN));
   *sec = bcd(read_ds1302(DS1802_RD_SEC));
}

volatile int i2c_ramcpy;
#define I2C_SCL_HI  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy |   (1 << I2C_SCL_WR) ) )
#define I2C_SCL_LO  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << I2C_SCL_WR) ) )
#define I2C_SDA_HI  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy |   (1 << I2C_SDA_WR) ) )
#define I2C_SDA_LO  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << I2C_SDA_WR) ) )
#define I2C_WrPort(data)  ( i2c_ramcpy = IO_I2C = data ) 
#define I2C_RdPort  (IO_I2C)

void i2c_start(void)
{
  I2C_SCL_HI;
  I2C_SDA_HI;
  I2C_SDA_LO;
  I2C_SCL_LO;
}

void i2c_stop(void)
{
  I2C_SDA_LO;
  I2C_SCL_LO;
  I2C_SCL_HI;
  I2C_SDA_HI;
}

//unsigned char i2c_write(unsigned char data)
unsigned char i2c_write(unsigned int data)
{
  int bitcnt;
  volatile int ack, result=0;
  for(bitcnt = 0; bitcnt < 8; bitcnt++)
  {
    data & 0x80 ? I2C_SDA_HI : I2C_SDA_LO;
    I2C_SCL_HI;
    I2C_SCL_LO;
    data = data << 1;
  }
  I2C_SDA_HI;
  I2C_SCL_HI;
  result = I2C_RdPort;
  I2C_SCL_LO;
  ack= ( (I2C_RdPort & (1 << I2C_SDA_RD) ) ? 1 : 0);
//  printf("\n\rw-ack[%d] ",ack);

  if(result == 0)
  {
    printf("\n\rw-ack[%d] ",ack);
    I2C_SDA_LO;
    I2C_SCL_HI;
    I2C_SDA_HI;
    result =  2;
  }
  return result;
}

void i2c_open(unsigned char address)
{
  i2c_start();
  i2c_write(address); 
}

unsigned char i2c_read(void)
{
  int bitcnt;
  unsigned char data=0;

  I2C_SDA_HI;
  for(bitcnt = 8; bitcnt < 8; bitcnt++)
  {
    I2C_SCL_HI;
    data = (data << 1) | ( (I2C_RdPort & (1 << I2C_SDA_RD) ) ? 0 : 1);
    I2C_SCL_LO;
  }
  I2C_SDA_LO;
  I2C_SCL_HI;
  I2C_SCL_LO;
  return data;
}

void i2c_close(void)
{
  i2c_stop;
}



// write 8 bits lcd data
void lcd_data(unsigned char d)
{
  i2c_open(I2C_ADDR);
  i2c_write(GPIOB);
  i2c_write(d);
  i2c_stop();

//  i2c_open(I2C_ADDR);
//  i2c_write(GPIOA);
//  i2c_write(LCDFONTSEL-LCD_CE-LCD_CD);
//  i2c_stop();

  i2c_open(I2C_ADDR);
  i2c_write(GPIOA);
  i2c_write(LCDFONTSEL - LCD_WR - LCD_CE - LCD_CD);
  i2c_stop();

  i2c_open(I2C_ADDR);
  i2c_write(GPIOA);
  i2c_write(LCDFONTSEL - LCD_CD);
  i2c_stop();
}

// write 8 bits lcd command
void lcd_command(unsigned char c)
{
  i2c_open(I2C_ADDR);
  i2c_write(GPIOB);
  i2c_write(c);
  i2c_stop();

//  i2c_open(I2C_ADDR);
//  i2c_write(GPIOA);
//  i2c_write(LCDFONTSEL-LCD_CE);
//  i2c_stop();

  i2c_open(I2C_ADDR);
  i2c_write(GPIOA);
  i2c_write(LCDFONTSEL - LCD_WR - LCD_CE);
  i2c_stop();

  i2c_open(I2C_ADDR);
  i2c_write(GPIOA);
  i2c_write(LCDFONTSEL);
  i2c_stop();
}

void lcd_init()
{
  I2C_WrPort( 0b11000000 );		// SCL and SDA high + LED 1

  i2c_open(I2C_ADDR);
  i2c_write(IODIRA);
  i2c_write(0);
  i2c_stop();

  i2c_open(I2C_ADDR);
  i2c_write(IODIRB);
  i2c_write(0);
  i2c_stop();
    wait(0.1);
    
  i2c_open(I2C_ADDR);
  i2c_write(GPIOA);
  i2c_write(LCDFONTSEL-LCD_RST);
  i2c_stop();

  i2c_open(I2C_ADDR);
  i2c_write(GPIOB);
  i2c_write(0);
  i2c_stop();
    wait(0.1);

  i2c_open(I2C_ADDR);
  i2c_write(GPIOA);
  i2c_write(LCDFONTSEL);
  i2c_stop();
    wait(0.1);


//printf("\n\r_TH=%d",_TH);
//printf("\n\r_GH=%d",_GH);
//printf("\n\r");


#if 1
    // set graphic home address at 0x1000
    lcd_data(_GH%0x100);
    lcd_data(_GH/0x100);
    lcd_command(GRHOME);
    
    // set graphic area
    lcd_data(_GA);
    lcd_data(0x00);
    lcd_command(GRAREA);
    
    // set text home address at 0x0000
    lcd_data(_TH%0x100);
    lcd_data(_TH/0x100);
    lcd_command(TXHOME);
    
    // set text area 
    lcd_data(_TA);
    lcd_data(0x00);
    lcd_command(TXAREA);

    // set offset register
    lcd_data(((_sizeMem/2)-1));
    lcd_data(0x00);
    lcd_command(OFFSET);
    wait(0.1);
    
    // display mode (text on graphics on cursor off)
    lcd_command(0x90+0x08+0x04);
    wait(0.1);
    
    // mode set (internal character generation mode)
    lcd_command(0x80);
    wait(0.1);
#endif       
}

// put a text string at position x,y (character row,column)
void lcd_string(char x,char y,char *s)
{
    int adr;
    //adr=TEXT_STARTADDRESS+x+y*LCD_WIDTH;
    adr = _TH +  x + (_TA * y);
    lcd_data(adr%0x100);
    lcd_data(adr/0x100);
    lcd_command(ADPSET);
    lcd_command(AWRON);
    
    while (s[0])
    {
        // convert from ascii to t6963
        lcd_data(s[0]-32);
        s++;
    }
    lcd_command(AWROFF);
}

//-------------------------------------------------------------------------------------------------
//
// Sets address pointer for display RAM memory
//
//-------------------------------------------------------------------------------------------------
void SetAddressPointer(unsigned int address){
  lcd_data(address & 0xFF);
  lcd_data(address >> 8);
  lcd_command(APS);
}
//-------------------------------------------------------------------------------------------------
// Writes display data and increment address pointer
//-------------------------------------------------------------------------------------------------
void WriteDisplayData(unsigned char x){
	lcd_data(x);
	lcd_command(DWAAI);
}
//-------------------------------------------------------------------------------------------------
//
// Clears text area of display RAM memory
//
//-------------------------------------------------------------------------------------------------
void clearText(){
  SetAddressPointer(_TH);
  for(int i = 0; i < sizeTA; i++){
    WriteDisplayData(0);
  }
}

//-------------------------------------------------------------------------------------------------
// Clears characters generator area of display RAM memory
//-------------------------------------------------------------------------------------------------
void clearCG(){
  unsigned int i=((_sizeMem/2)-1)*0x800;
  SetAddressPointer(i);
  for(i = 0; i < 256 * 8; i++){
    WriteDisplayData(0);
  }
}

//-------------------------------------------------------------------------------------------------
// Clears graphics area of display RAM memory
//-------------------------------------------------------------------------------------------------
void clearGraphic(){
  SetAddressPointer(_GH);
  for(unsigned int i = 0; i < sizeGA; i++){
    WriteDisplayData(0x00);
  }
}

// clear lcd display memory (8k)        
void lcd_cls()
{
printf("\nErasing");
clearText();
//printf(".");
//clearCG();
printf(".");
clearGraphic();
printf(".");
}

// clear lcd display memory (8k)        
void lcd_cls_()
{
    int a;
    lcd_data(0x00);
    lcd_data(0x00);
    lcd_command(ADPSET);
    lcd_command(AWRON);
    for (a=0; a<8192; a++) 
      lcd_data(0);
    lcd_command(AWROFF);
}

// set or reset a pixel on the display on position x,y with color 0 or 1
void lcd_plot(char x,char y,char color)
{
    int adr;
    unsigned char tmp=0b11111000;                         
    //adr = GRAPHIC_STARTADDRESS + ((LCD_WIDTH) * y) + (x/PIXELWIDTH);   // calculate offset
    adr = _GH + (x / _FW) + (_GA * y);

    lcd_data(adr%0x100);       // set low byte
    lcd_data(adr/0x100);       // set high byte
    lcd_command(ADPSET);           // set address pointer
//    if (color) lcd_command(BS + ((PIXELWIDTH-1)-(x%PIXELWIDTH)));   // use bit set mode
//         else  lcd_command(BR + ((PIXELWIDTH-1)-(x%PIXELWIDTH)));  // use bit reset mode
    if(color) tmp = BS; else tmp = BR;
    tmp |= (_FW-1)-(x%_FW);
    lcd_command(tmp);

}

// Bresenham line routine
void lcd_line(int x0, int y0, int x1, int y1,char color)
{
    char steep=1;
    int i,dx,dy,e;
    signed char sx,sy;
    
    dx = abs(x1-x0);
    sx = ((x1 - x0) >0) ? 1 : -1;
    dy=abs(y1-y0);
    sy = ((y1 - y0) >0) ? 1 : -1;
    
    if (dy > dx)
    {
        steep=0;
        // swap X0 and Y0
        x0=x0 ^ y0;
        y0=x0 ^ y0;
        x0=x0 ^ y0;

        // swap DX and DY
        dx=dx ^ dy;
        dy=dx ^ dy;
        dx=dx ^ dy;

        // swap SX and SY
        sx=sx ^ sy;
        sy=sx ^ sy;
        sx=sx ^ sy;
    }

    e = (dy << 1) - dx;

    for (i=0; i<=dx; i++)
    {
        if (steep)
        {
            lcd_plot(x0,y0,color);
        }
        else
        {
            lcd_plot(y0,x0,color);
        }
        while (e >= 0)
        {
            y0 += sy;
            e -= (dx << 1);
        }
        x0 += sx;
        e += (dy << 1);
    }
 }

// Bresenham circle routine
void lcd_circle(int x0,int y0, int radius, char color)
{

    int f = 1 - radius;
    int dx = 1;
    int dy = -2 * radius;
    int x = 0;
    int y = radius;
 
    lcd_plot(x0, y0 + radius,color);
    lcd_plot(x0, y0 - radius,color);
    lcd_plot(x0 + radius, y0,color);
    lcd_plot(x0 - radius, y0,color);
 
    while(x < y)
    {
        if(f >= 0) 
        {
            y--;
            dy += 2;
            f += dy;
        }
        x++;
        dx += 2;
        f += dx;    
        lcd_plot(x0 + x, y0 + y,color);
        lcd_plot(x0 - x, y0 + y,color);
        lcd_plot(x0 + x, y0 - y,color);
        lcd_plot(x0 - x, y0 - y,color);
        lcd_plot(x0 + y, y0 + x,color);
        lcd_plot(x0 - y, y0 + x,color);
        lcd_plot(x0 + y, y0 - x,color);
        lcd_plot(x0 - y, y0 - x,color);
    }
}

void lcd_rectangle(unsigned char x, unsigned char y, unsigned char b, unsigned char a, unsigned char color)
{
  unsigned char j; 
  // Draw vertical lines
  for (j = 0; j < a; j++) {
		lcd_plot(x, y + j, color);
		lcd_plot(x + b - 1, y + j, color);
	}
  // Draw horizontal lines
  for (j = 0; j < b; j++)	{
		lcd_plot(x + j, y, color);
		lcd_plot(x + j, y + a - 1, color);
	}
}
//==============================================================================================================
#define EPOCH_YEAR 1970
#define SECS_PER_DAY  86400UL
#define SECS_PER_HOUR  3600UL
#define SECS_PER_MIN     60UL
#define DAYS_PER_YEAR   365UL

const int _tot[] = {
		0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };

static int is_leap( int year )
{
    
    if( year % 100 == 0 ) {
	return year % 400 == 0;
    }

    return year % 4 == 0;
}

time_t mktime2(struct tm *tp)
{
    unsigned long days;
    int           i,j,year;

    if ( tp->tm_year  < EPOCH_YEAR - 1900 ) 
	return -1L;

    days = ( tp->tm_year - ( EPOCH_YEAR - 1900 ) ) * DAYS_PER_YEAR;

    /* Now chase up the leap years */
    for ( i = EPOCH_YEAR; i < ( tp->tm_year + 1900 ); i++ ) {
	if ( is_leap(i) )
		++days;
    }

    days += _tot[tp->tm_mon];
    if ( is_leap(tp->tm_year) )
	    ++days;

    days += (tp->tm_mday - 1);

    /* So days has the number of days since the epoch */
    days *= SECS_PER_DAY;
    

    days += ( tp->tm_hour * SECS_PER_HOUR ) + ( tp->tm_min * SECS_PER_MIN ) + tp->tm_sec;

    return days;
}


int main() 
{
    float b;
    float pi=3.14159265;
    float h_pi=pi/6;
    float m_pi=pi/30;
    int s_sx,s_sy,s_ex,s_ey;
    int h_sx,h_sy,h_ex,h_ey;
    int m_sx,m_sy,m_ex,m_ey;

    struct tm *newtime;
    struct tm t;
    time_t ltime;

   unsigned char day, mth, year, dow;
   unsigned char hour, min, sec;

    time_t tim = time(NULL);
    time_t tim2;
    struct tm *tp;

   rtc_init();
   rtc_get_date( &day, &mth, &year, &dow);
   rtc_get_time( &hour, &min, &sec );

   printf("\n\r%d/%d/20%d", day, mth, year );
   printf("    ");
   printf("%d:%02d:%02d", hour, min, sec );
   printf("\n\r");

    // setup time structure
    t.tm_sec = sec;    // 0-59
    t.tm_min = min;    // 0-59
    t.tm_hour = hour;   // 0-23
    t.tm_mday = day;   // 1-31
    t.tm_mon = mth;     // 0-11
    t.tm_year = year;  // year since 1900
    t.tm_isdst = 0;

    ltime = mktime(&t);
    set_system_time(ltime - 508141696L) ; // magic to convert from unix time to sc126 time
    ltime=time(NULL);
    printf("\n\rltime=%ld",ltime);

    /* Convert it to the structure tm */
    newtime = localtime(&ltime);

    /* Print the local time as a string */
    printf("\n\rThe current date and time are %s", asctime(newtime));

    lcd_init();
    lcd_cls();

    lcd_rectangle(2,2,124,28,1);
    lcd_rectangle(4,4,120,24,1);
    lcd_string(1,1,"T6963 Display");
    lcd_string(1,2,"SC126 Z180 I2C");
 
    // draw outer circle of analog clock
    lcd_circle(CENTERX,CENTERY,OUTER_RADIUS+1,1);    
   
   // draw hour markings  
    for (min=0; min<59; min+=5)
    {
        b=min*m_pi;
        m_sx=sin(b)*INNER_RADIUS+CENTERX;
        m_sy=-cos(b)*INNER_RADIUS+CENTERY;
        m_ex=sin(b)*OUTER_RADIUS+CENTERX;
        m_ey=-cos(b)*OUTER_RADIUS+CENTERY;
        lcd_line(m_sx,m_sy,m_ex,m_ey,1);
    }

    for(;;)
    {
	ltime=time(NULL);
    	newtime = localtime(&ltime);
    	/* Print the local time as a string */
    	lcd_string(0,15,asctime(newtime));
        
	hour = newtime->tm_hour;
	min = newtime->tm_min;
	sec = newtime->tm_sec;;

        b=sec*m_pi;
        s_sx=CENTERX;
        s_sy=CENTERY;
        s_ex=sin(b)*(INNER_RADIUS-3)+CENTERX;
        s_ey=-cos(b)*(INNER_RADIUS-3)+CENTERY;
        
        b=min*m_pi;
        m_sx=sin(b)*(CENTER_CIRCLE)+CENTERX;
        m_sy=-cos(b)*(CENTER_CIRCLE)+CENTERY;
        m_ex=sin(b)*(INNER_RADIUS-8)+CENTERX;
        m_ey=-cos(b)*(INNER_RADIUS-8)+CENTERY;

        // advancing hour hand
        if (hour<12)
        {
            // draw hour hand with an offset
            // calculated by dividing minutes by 12 
            b=(hour*5+min/12)*m_pi;
        }
        else
        {
            // hour would be 0 offset at 12 o'clock
            // so we can leave it out of the equation...
            b=(min/12)*m_pi;
        }
        h_sx=sin(b)*(CENTER_CIRCLE)+CENTERX;
        h_sy=-cos(b)*(CENTER_CIRCLE)+CENTERY;
        h_ex=sin(b)*(INNER_RADIUS-16)+CENTERX;
        h_ey=-cos(b)*(INNER_RADIUS-16)+CENTERY;

        // draw 'new' hands
        lcd_line(s_sx,s_sy,s_ex,s_ey,1);
        lcd_line(m_sx,m_sy,m_ex,m_ey,1);
        lcd_line(h_sx,h_sy,h_ex,h_ey,1);

        lcd_circle(CENTERX,CENTERY,CENTER_CIRCLE,1);        
        lcd_circle(CENTERX,CENTERY,1,1);        
 
        // now wait until the seconds change
        while (ltime==time(NULL)) wait(0.1);
        
        // erase 'old' hands
        lcd_line(s_sx,s_sy,s_ex,s_ey,0);
        lcd_line(m_sx,m_sy,m_ex,m_ey,0);
        lcd_line(h_sx,h_sy,h_ex,h_ey,0);
        
    }

  return 0;
}

