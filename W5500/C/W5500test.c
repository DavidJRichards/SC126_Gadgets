// Wiznet W5500 test for SC126 Z180
// David Richards, December 3rd 2020
// zcc +scz180 -subtype=hbios -v --list -m -SO3   -clib=sdcc_iy -lm  W5500test.c  -o W5500test  -create-app; mv W5500test_CODE.bin ../wtest.com

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <z180.h>
#include <math.h>
#include "W5500.h"
#pragma portmode z180

// Z180 I/O registers
#define Z180_BASE	0xC0	// SC126 specific 
#define Z180_CNTR_PORT	(Z180_BASE + 0xA)	// CSI/O CONTROL
#define Z180_TRDR_PORT	(Z180_BASE + 0xB)	// CSI/O TRANSMIT/RECEIVE
volatile __sfr __at Z180_CNTR_PORT IO_CNTR;	// Z180 SPI control port
volatile __sfr __at Z180_TRDR_PORT IO_TRDR;	// Z180 SPI data port

// SC126 built-in I2C port definitions
#define RTC_PORT	0x0C	// Host I/O port address
__sfr __at RTC_PORT IO_RTC;	// Host I/O port i/o

// input and output register bit definitions
#define I2C_SDA_WR	7	// Host I2C write SDA bit number
#define I2C_SCL_WR	0	// Host I2C write SCL bit number
#define I2C_SDA_RD	7	// Host I2C read SDA bit number

#define RTC_SCLK	6	// RTC Serial Clock line
#define RTC_DOUT	7 	// RTC Data write,  also I2C_SDA_WR & I2C_SDA_RD
#define RTC_DIN		0	// RTC data read
#define RTC_WE		5	// RTC not write enable
#define RTC_CE		4	// RTC not chip enable

#define SD_CS2		3	// spare SPI chip select
#define SD_CS1		2	// main SPI chip select

#define FS_U1U2		1	// Flash select U1 / U2


// Z180 SPI control port register bit masks
#define CNTR_TE	 	0x10
#define CNTR_RE		0x20
#define CNTR_EF		0x80

volatile int rtc_ramcpy;
#define SPI_CS2_HI  ( rtc_ramcpy = IO_RTC = ( rtc_ramcpy |   (1 << SD_CS2) ) )
#define SPI_CS2_LO  ( rtc_ramcpy = IO_RTC = ( rtc_ramcpy & ~ (1 << SD_CS2) ) )


#if 1
int main(void)
{
	int flags0, flags1, flags2, data1;
	int io_cntr_val;
	rtc_ramcpy=0xFF;	// readable copy of i/o register, I/O initialzed to all bit on at first write	/* Config W5500 */

	
	io_cntr_val=IO_CNTR;
	printf("\n\rInitial IO_CNTR = 0x%02x",io_cntr_val);

	printf("\n\rSetting IO_CNTR to 0x00");
	IO_CNTR = 0;

	io_cntr_val=IO_CNTR;
	printf("\n\rPresent IO_CNTR = 0x%02x",io_cntr_val);

#if 0

	SPI_CS2_LO;

//__asm    ld b,0h __endasm;
	IO_CNTR = 0;
//	flags0 = IO_CNTR;
//	data1 = IO_TRDR;
//printf(" d1=%02x",data1);
	flags0 = IO_CNTR;
	IO_TRDR = 0xAA;
	IO_CNTR = 0x10;
	flags1 = IO_CNTR;
	flags2 = IO_CNTR;

	SPI_CS2_HI;

printf(" f0=%02x",flags0);
printf("\n\r>AA");
printf("\n\r TR");
printf("\n\rf1=%02x",flags1);
printf("\n\rf2=%02x",flags2);
//	IO_TRDR = data;				// send data

//printf("\n\r>%02x",data);


#endif
	return 0;
}

#else
void Delay(unsigned int d)
{
	long /*i,*/j,k=0;
//	for(i = 0; i < 10; i++)
		for(j = 0; j < d; j++)
			k+=1;

}

unsigned char reverse(unsigned char b) {
   b = (b & 0b11110000) >> 4 | (b & 0b00001111) << 4;
   b = (b & 0b11001100) >> 2 | (b & 0b00110011) << 2;
   b = (b & 0b10101010) >> 1 | (b & 0b01010101) << 1;
   return b;
}

#if 0
void GPIO_SetBits(int port, int mask)
{
#define I2C_SCL_HI  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy |   (1 << I2C_SCL_WR) ) )
	rtc_ramcpy = port = (rtc_ramcpy | mask);
}

void GPIO_ResetBits(int port, int mask)
{
#define I2C_SCL_LO  ( i2c_ramcpy = IO_I2C = ( i2c_ramcpy & ~ (1 << I2C_SCL_WR) ) )
	rtc_ramcpy = port = (rtc_ramcpy & ~ mask);
}
#endif

void SPI_SendData(unsigned short data)
{
	unsigned int flags0, flags1, flags2, data1;
	flags0 = IO_CNTR;
	data1 = IO_TRDR;
	data = reverse (data);
	flags0 = IO_CNTR;
	flags1 = IO_CNTR;
//	while (((IO_CNTR) & CNTR_EF) != CNTR_EF); 	// wait for EF set before sending
	flags2 = IO_CNTR;
	IO_TRDR = data;				// send data
//	IO_CNTR = flags1 | CNTR_TE; 		// set TE
//	IO_CNTR = CNTR_TE; 		// set TE

printf("\n\r>%02x",data);
printf(" d1=%02x",data1);
printf(" f0=%02x",flags0);
printf(" f1=%02x",flags1);
printf(" f2=%02x",flags2);
}

unsigned short SPI_ReceiveData(void)
{
	volatile unsigned short data;
	unsigned char flags;
	flags = IO_CNTR;	
	IO_CNTR = flags | CNTR_RE;
	data = IO_TRDR;
printf("\n\r<%02x",data);
printf(" f=%02x",flags);

//	data = reverse (data);
	return data;
}


/******************************* W5500 Read Operation *******************************/
/* Read W5500 Common register 1 Byte */
unsigned char Read_1_Byte(unsigned short reg)
{
	unsigned char i;

	/* Set W5500 SCS Low */
	SPI_CS2_LO;
	/* Write Address */
	SPI_SendData(reg/256);
	SPI_SendData(reg);

	/* Write Control Byte */
	SPI_SendData((FDM1|RWB_READ|COMMON_R));

	/* Write a dummy byte */
	i=SPI_ReceiveData();
	SPI_SendData(0x00);

	/* Read 1 byte */
	i=SPI_ReceiveData();

	/* Set W5500 SCS High*/
	SPI_CS2_HI;

	return i;
}

/******************************* W5500 Write Operation *******************************/
/* Write W5500 Common Register a byte */
void Write_1_Byte(unsigned short reg, unsigned char dat)
{
	/* Set W5500 SCS Low */
	SPI_CS2_LO;

	/* Write Address */
	SPI_SendData(reg/256);
	SPI_SendData(reg);

	/* Write Control Byte */
	SPI_SendData((FDM1|RWB_WRITE|COMMON_R));

	/* Write 1 byte */
	SPI_SendData(dat);

	/* Set W5500 SCS High */
	SPI_CS2_HI;

}

/* Write W5500 Common Register n bytes */
void Write_Bytes(unsigned short reg, unsigned char *dat_ptr, unsigned short size)
{
	unsigned short i;

	/* Set W5500 SCS Low */
	SPI_CS2_LO;

	/* Write Address */
	SPI_SendData(reg/256);
	SPI_SendData(reg);

	/* Write Control Byte */
	SPI_SendData((VDM|RWB_WRITE|COMMON_R));

	/* Write n bytes */
	for(i=0;i<size;i++)
	{
		SPI_SendData(*dat_ptr);
		dat_ptr++;
	}

	/* Set W5500 SCS High */
	SPI_CS2_HI;

}


/* W5500 configuration */
void W5500_Configuration()
{
	unsigned char array[6];

	//GPIO_SetBits(GPIOB, RST_W5500);		/* Hard Reset W5500 */
	//Delay(200);
	//while((Read_1_Byte(PHYCFGR)&LINK)==0); 	/* Waiting for Ethernet Link */

	Write_1_Byte(MR, RST);				/* Soft reset W5500 */
	Delay(10);

	/* Set MAC Address as: 0x48,0x53,0x00,0x57,0x55,0x00 */
	array[0]=0x48;
	array[1]=0x53;
	array[2]=0x00;
	array[3]=0x57;
	array[4]=0x55;
	array[5]=0x00;
	Write_Bytes(SHAR, array, 6);
#if 0
	/* Set Gateway IP as: 192.168.178.1 */
	array[0]=192;
	array[1]=168;
	array[2]=0;
	array[3]=1;
	Write_Bytes(GAR, array, 4);

	/* Set Subnet Mask as: 255.255.255.0 */
	array[0]=255;
	array[1]=255;
	array[2]=255;
	array[3]=0;
	Write_Bytes(SUBR, array, 4);

	/* Set W5500 IP as: 192.168.178.226 */
	array[0]=192;
	array[1]=168;
	array[2]=0;
	array[3]=20;
	Write_Bytes(SIPR, array, 4);
#endif
}

/*****************************************************************
                           Main Program
*****************************************************************/
int main(void)
{
	rtc_ramcpy=0xFF;	// readable copy of i/o register, I/O initialzed to all bit on at first write	/* Config W5500 */
	IO_CNTR = 0;

	W5500_Configuration();
	return 0;
}
#endif
