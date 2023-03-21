// zcc +scz180 -subtype=cpm -clib=new Test.c -o Test.com -create-app
// zcc +scz180 -subtype=cpm -clib=sdcc_iy Test.c -o Test.com -create-app
// zcc +scz180 -subtype=cpm -clib=sdcc_iy hbiostest.c -o Test.com -create-app

#include <stdio.h>
#include <arch.h>
#include <arch/hbios.h>

int main()
{
	// Write to HBIOS char unit 0
	hbios_a_de(0x4280, '@');

	// Write to CP/M console
	printf("Hello\n");
	
	// Write to HBIOS char unit 0
//	hbios_a_de(0x0100, 'X');
	
	// Write to current HBIOS console (special char unit 0x80)
//	hbios_a_de(0x0180, 'Y');
	
	return 0;
}

