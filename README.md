# SC126_Gadgets
Bits and pieces for the SC126 Z180 RomWBW Single board computer

Included here is the C source code for some SC126 programs.
First an demo of accessing the built in IIC port to drive an MCP23017 port expander.
![Alt text](mcp23017.jpg?raw=true "mcp23017")

Second, a tool to read the SC126 DS1302 RTC and set the system time.
Finally, combine these together with a driver for the T6963 LCD controller to make an analogue clock.

![Alt text](t6963_clock.mp4?raw=true "t6963")

Various problems needed to be solved to make the working demo show. The toolcahin used is z88dk, to access the system time the time library had to be compiled and installed. An unexpected time offset was found to be needed when using the set_system_time function.
