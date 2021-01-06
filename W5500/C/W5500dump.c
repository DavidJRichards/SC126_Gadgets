// Wiznet W5500 test for SC126 Z180
// David Richards, December 3rd 2020
// zcc +scz180 -subtype=hbios -v --list -m -SO3   -clib=sdcc_iy -lm  W5500dump.c  -o W5500dump  -create-app; mv W5500dump_CODE.bin ./wdump.com

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <z180.h>
#include <math.h>
#include "W5500.h"
#include "W5500dump.h"
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

// buffers for wiznet data
tCommonRegs CommonRegisterBlock;
//tSocketRegs SocketRegisterBlock[4];
tSocketRegs SocketRegisterBlock;
tbyte TxBuffer[2048];
tbyte RxBuffer[2048];

/*****************************************************************
                           Main Program
*****************************************************************/

int main(void)
{
	rtc_ramcpy=0xFF;	// readable copy of i/o register, I/O initialzed to all bit on at first write	/* Config W5500 */
	
	printf("\nTX Buffer\n");
	Read_Bytes(2, 0, TxBuffer, 2048);
	DumpHex (TxBuffer,2048);

	printf("\nRX Buffer\n");
	Read_Bytes(3, 0, RxBuffer, 2048);
	DumpHex (RxBuffer,2048);

	printf("\nCommon Registers\n");
	Read_Bytes(0, MR, (tbyte*)CommonRegisterBlock, 0x3A);
	DumpHex ((tbyte*)CommonRegisterBlock,0x3A);
	DumpCommon();

	printf("\nSocket 1 Registers\n");
	Read_Bytes(1, Sn_MR,(tbyte*)SocketRegisterBlock, 0x30);
	DumpHex ((tbyte*)SocketRegisterBlock,0x30);
	DumpSocket(&SocketRegisterBlock);


	return 0;
}

void DumpCommon(void)
{
	printf("Mode                   	%02X\n",CommonRegisterBlock.Mode);
	printf("Subnet Mask        	%d.%d.%d.%d\n",CommonRegisterBlock.SubnetMaskAddress[0],CommonRegisterBlock.SubnetMaskAddress[1],CommonRegisterBlock.SubnetMaskAddress[2],CommonRegisterBlock.SubnetMaskAddress[3]);
	printf("Source MAC Address 	%02X:%02X:%02X:%02X:%02X:%02X\n",CommonRegisterBlock.SourceHardwareAddress[0],CommonRegisterBlock.SourceHardwareAddress[1],CommonRegisterBlock.SourceHardwareAddress[2],CommonRegisterBlock.SourceHardwareAddress[3],CommonRegisterBlock.SourceHardwareAddress[4],CommonRegisterBlock.SourceHardwareAddress[5]);
	printf("Source IP Addr     	%d.%d.%d.%d\n",CommonRegisterBlock.SourceIP_Address[0],CommonRegisterBlock.SourceIP_Address[1],CommonRegisterBlock.SourceIP_Address[2],CommonRegisterBlock.SourceIP_Address[3]);
	printf("Chip Version       	%02X\n",CommonRegisterBlock.ChipVersion);
}

void DumpSocket(tSocketRegs* SocketRegs) {

	printf("Mode 			%0X\n",SocketRegs->Mode);	
	printf("Command 		%02X\n",SocketRegs->Command);
	printf("Destination IP Addr	%d.%d.%d.%d\n",SocketRegs->DestinationIP_Address[0],SocketRegs->DestinationIP_Address[1],SocketRegs->DestinationIP_Address[2],SocketRegs->DestinationIP_Address[3]);

	printf("Receive Buffer Size     %d\n", SocketRegs->ReceiveBufferSize);
	printf("Transmit Buffer Size    %d\n", SocketRegs->TransmitBufferSize);
	printf("Tx Free Size            0x%04X\n", SocketRegs->TX_FreeSize);
	printf("Tx Read Pointer         0x%04X\n", SocketRegs->TX_ReadPointer);
	printf("Tx Write Pointer        0x%04X\n", SocketRegs->TX_WritePointer);

	printf("Rx Received Size        0x%04X\n", SocketRegs->RX_ReceivedSize);
	printf("Rx Read Pointer         0x%04X\n", SocketRegs->RX_ReadPointer);
	printf("Rx Write Pointer        0x%04X\n", SocketRegs->RX_WritePointer);

}

void DumpHex(const void* data, size_t size) {
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
	for (i = 0; i < size; ++i) {
		if(i%16==0){
			printf(" %04X | ",i);
		}

		printf("%02X ", ((unsigned char*)data)[i]);
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
			} else if (i+1 == size) {
				ascii[(i+1) % 16] = '\0';
				if ((i+1) % 16 <= 8) {
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
				}
				printf("|  %s \n", ascii);
			}
		}
	}
}


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



void SPI_SendData(unsigned short data)
{
	data = reverse (data);
	while (((IO_CNTR) & (CNTR_TE|CNTR_RE))); 	// wait for EF set before sending
	IO_TRDR = data;				// send data
	IO_CNTR = CNTR_TE; 		// set TE
}

unsigned short SPI_ReceiveData(void)
{
	volatile unsigned short data;
	while (((IO_CNTR) & (CNTR_TE|CNTR_RE))); 	// wait for TE RE clear
	IO_CNTR = CNTR_RE;
//	data = IO_TRDR;
	while (((IO_CNTR) & (CNTR_RE))); 	// wait for EF clear
	data = IO_TRDR;
	data = reverse (data);
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

unsigned char Read_Bytes(unsigned short skt, unsigned short reg, tbyte * data, unsigned short count)
{
	unsigned short i;

	/* Set W5500 SCS Low */
	SPI_CS2_LO;

	/* Write Address */
	SPI_SendData(reg/256);
	SPI_SendData(reg);

	/* Write Control Byte */
	SPI_SendData((VDM|RWB_READ|COMMON_R|(skt<<3)));

	/* Read n bytes */
	for (i=0; i<count; i++)
	{
		*data=SPI_ReceiveData();
		data++;
	}

	/* Set W5500 SCS High */
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

