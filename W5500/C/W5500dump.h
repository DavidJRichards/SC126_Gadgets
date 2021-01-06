typedef unsigned char tbyte ;
typedef unsigned int tword;

typedef struct sCommonRegs {
   tbyte Mode;
   tbyte GatewayAddress[4];
   tbyte SubnetMaskAddress[4];
   tbyte SourceHardwareAddress [6];
   tbyte SourceIP_Address[4];
   tword InterruptLowLevelTimer;
   tbyte Interrupt;
   tbyte InterruptMask;
   tbyte SocketInterrupt;
   tbyte SocketInterruptMask;
   tword RetryTime;
   tbyte RetryCount;
   tbyte PPP_LCP_RequestTimer;
   tbyte PPP_LCP_MagicNumber;
   tbyte PPP_DestinationMAC_Address[6];
   tbyte PPP_SessionIdentification[2];
   tbyte PPP_Maximum_SegmentSize[2];
   tbyte UnreachableIP_Address[4];
   tbyte UnreachablePort[2];
   tbyte PHY_Configuration;
   tbyte reserved1[9];
   tbyte ChipVersion;
} tCommonRegs;

typedef struct sSocketRegs {
   tbyte Mode;
   tbyte Command;
   tbyte Interrupt;
   tbyte Status;
   tword SourcePort;
   tbyte DestinationHA[6];
   tbyte DestinationIP_Address[4];
   tword DestinationPort;
   tword MaximumSegmentSize;
   tbyte Reserved1;
   tbyte IP_TOS;
   tbyte IP_TTL;
   tbyte Reserved2[7];
   tbyte ReceiveBufferSize;
   tbyte TransmitBufferSize;
   tword TX_FreeSize;
   tword TX_ReadPointer;
   tword TX_WritePointer;
   tword RX_ReceivedSize;
   tword RX_ReadPointer;
   tword RX_WritePointer;
   tbyte InterruptMask;
   tword FrafmentOffsetInIP_Header;
   tbyte KeepAliveTimer;
} tSocketRegs;


// buffers for wiznet data
//CommonRegs CommonRegisterBlock;
//SocketRegs SocketRegisterBlock;
//tbyte TxBuffer[2048];
//tbyte RxBuffer[2048];

void DumpHex(const void* data, size_t size, size_t disp_addr);
void DumpCommon(void);
void DumpSocket(tSocketRegs* SocketRegs);
//unsigned char Read_Bytes(tbyte * data, unsigned short reg, unsigned short count);
unsigned char Read_Bytes(unsigned short skt, unsigned short reg, tbyte * data, unsigned short count);


   
