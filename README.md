# SC126_Gadgets
Bits and pieces for the SC126 Z180 RomWBW Single board computer.

Included here is the C source code for some SC126 programs.
First an demo of accessing the built in IIC port to drive an MCP23017 port expander.
![Alt text](mcp23017_breakout.jpg?raw=true "mcp23017")

Second, a tool to read the SC126 DS1302 RTC and set the system time.
Finally, combine these together with a driver for the T6963 LCD controller to make an analogue clock.

![Alt text](t6963_lcd.jpg?raw=true "t6963")

Various problems needed to be solved to make the working demo show. The toolcahin used is z88dk, to access the system time the time library had to be compiled and installed. An unexpected time offset was found to be needed when using the set_system_time function.

[Youtube clock video](https://youtu.be/SXmMnbZyj9E)

The Wiznet W5500 has been added to the SC126 on the second SPI (SD) port
Low level functions in assembler comminicate withthe hardware at the lowes level.
A C program has been used to exercise the functions.

The Wiznet W5500 module connected to the SC126 second SPI port
![Alt text](W5500_SC126.jpg?raw=true "W5500")

This shows the SPI protocol witing to the W5500
![Alt text](DSView-SC126-set-MAC-test.png?raw=true "DSView")