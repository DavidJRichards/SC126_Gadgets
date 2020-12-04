// Wiznet W5500 test for SC126 Z180
// David Richards, December 4th 2020
// zcc +scz180 -subtype=hbios -v --list -m -SO3   -clib=sdcc_iy -lm  SPI_fn_test.c fn_SPI.asm  -o SPI_fn_test  -create-app; mv SPI_fn_test_CODE.bin ../spitest.com

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <z80.h>
#include <math.h>
#include"W5500.h"
#include "fn_SPI.h"


#if 0
int main(void)
{
	unsigned char data;
	cslower(1);
	writebyte(0xaa);
	csraise(1);

	cslower(1);
	data=readbyte();
	csraise(1);

	return data;
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

/******************************* W5500 Read Operation *******************************/
/* Read W5500 Common register 1 Byte */
unsigned char Read_1_Byte(unsigned short reg)
{
	unsigned char i;

	/* Set W5500 SCS Low */
	cslower(1);	
	/* Write Address */
	writebyte(reg/256);
	writebyte(reg);

	/* Write Control Byte */
	writebyte((FDM1|RWB_READ|COMMON_R));

	/* Write a dummy byte */
	writebyte(0x00);

	/* Read 1 byte */
	i=readbyte();

	/* Set W5500 SCS High*/
	csraise(1);

	return i;
}

/******************************* W5500 Write Operation *******************************/
/* Write W5500 Common Register a byte */
void Write_1_Byte(unsigned short reg, unsigned char dat)
{
	/* Set W5500 SCS Low */
	cslower(1);	

	/* Write Address */
	writebyte(reg/256);
	writebyte(reg);

	/* Write Control Byte */
	writebyte(FDM1|RWB_WRITE|COMMON_R);

	/* Write 1 byte */
	writebyte(dat);

	/* Set W5500 SCS High */
	csraise(1);

}

/* Write W5500 Common Register n bytes */
void Write_Bytes(unsigned short reg, unsigned char *dat_ptr, unsigned short size)
{
	unsigned short i;

	/* Set W5500 SCS Low */
	cslower(1);	

	/* Write Address */
	writebyte(reg/256);
	writebyte(reg);

	/* Write Control Byte */
	writebyte((VDM|RWB_WRITE|COMMON_R));

	/* Write n bytes */
	for(i=0;i<size;i++)
	{
		writebyte(*dat_ptr);
		dat_ptr++;
	}

	/* Set W5500 SCS High */
	csraise(1);

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
//	rtc_ramcpy=0xFF;	// readable copy of i/o register, I/O initialzed to all bit on at first write	/* Config W5500 */
//	IO_CNTR = 0;

	W5500_Configuration();
	return 0;
}
#endif
