/*
 * uses SC126 iic i/o port
 *
 * Compiled to .com (.bin) file with z88dk - sdcc
 * david@I7MINT:~/z88dk/examples/sc126$ zcc +rc2014 -subtype=hbios -v --list -m -SO3 --c-code-in-asm  -clib=sdcc_iy  --max-allocs-per-node200000 iictest.c  -o iictest  -create-app
 * 
 * rename .bin to .com
 * mv iicest.bin iictest.com 
 *
 * D. Richards, November 2020
*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <z80.h>

// SC126 built-in I2C port definitions
#define I2C_PORT	0x0C	// Host I2C port address
__sfr __at I2C_PORT IO_I2C;	// Host I2C port i/o
#define I2C_SDA_WR	7	// Host I2C write SDA bit number
#define I2C_SCL_WR	0	// Host I2C write SCL bit number
#define I2C_SDA_RD	7	// Host I2C read SDA bit number

// MCP23017 attached to I2c bus
#define I2C_ADDR	2 * 0x20	// I2C MCP23017 device addess
// registers
#define MCP23017_IODIRA 0x00
#define MCP23017_IPOLA 0x02
#define MCP23017_GPINTENA 0x04
#define MCP23017_DEFVALA 0x06
#define MCP23017_INTCONA 0x08
#define MCP23017_IOCONA 0x0A
#define MCP23017_GPPUA 0x0C
#define MCP23017_INTFA 0x0E
#define MCP23017_INTCAPA 0x10
#define MCP23017_GPIOA 0x12
#define MCP23017_OLATA 0x14


#define MCP23017_IODIRB 0x01
#define MCP23017_IPOLB 0x03
#define MCP23017_GPINTENB 0x05
#define MCP23017_DEFVALB 0x07
#define MCP23017_INTCONB 0x09
#define MCP23017_IOCONB 0x0B
#define MCP23017_GPPUB 0x0D
#define MCP23017_INTFB 0x0F
#define MCP23017_INTCAPB 0x11
#define MCP23017_GPIOB 0x13
#define MCP23017_OLATB 0x15

#define MCP23017_INT_ERR 255

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

unsigned char i2c_write(unsigned char data)
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


void delay(int loops) 		// wait for a bit
{
  volatile int ia=0;
  int wd=0;
  for(wd=0; wd<loops; wd++)
  {
    ia=ia+1;
  }
  return;
}

void init(void)
{
  unsigned int value;

  I2C_WrPort( 0b11000000 );		// SCL and SDA high + LED 1

  i2c_open(I2C_ADDR);
  i2c_write(MCP23017_IODIRA);
  i2c_write(0xfe);			// bit 0 of port a to output
  i2c_stop();

//  i2c_open(I2C_ADDR);
//  i2c_write(MCP23017_IODIRB 0x01);
//  i2c_write(0xFF);			
//  i2c_stop();
//  delay(50);

  i2c_open(I2C_ADDR);
  i2c_write(MCP23017_OLATA);
  i2c_write(0x01);			// set bit 0 of port a hi
  i2c_stop();
  delay(30000);				// wait a bit
  delay(30000);

  i2c_open(I2C_ADDR);
  i2c_write(MCP23017_OLATA);
  i2c_write(0x00);			// set bit 0 of port a lo
  i2c_stop();

  i2c_close();

}
#define IODIRA      0x00
#define IODIRB      0x01

//int main(int argc, char* argv[])
int main(void)
{
  //#pragma argsused argc, argv
  int key=-1;

  init(); 
  return 0;              
}
