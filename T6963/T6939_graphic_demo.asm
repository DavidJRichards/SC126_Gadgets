$mod51
; **************************************************
; * *
; * T6963 Application Note V1.0 *
; * *
; **************************************************
; The processor clock speed is 16MHz.
; Cycle time is .750mS.
; Demo software to display a bit-mapped
; graphic on a 240x64 graphics display
; with a T6963C LCD controller.

        org 000h
        ljmp start              ;program start
   
        org 100h
   
start:

; Initialize the T6963C
        clr p3.3                ;hardware reset
        nop
        nop
        setb p3.3
        mov dptr,#msgi1         ;initialization bytes
        lcall msgc
   
; Start of regular program

; Display graphic

        mov dptr,#msgi2         ;set auto mode   
        lcall msgc
        mov dptr,#msg1          ;display graphic
        lcall msgd
        sjmp $
   
;*************************************************
;SUBROUTINES

; MSGC sends the data pointed to by
; the DPTR to the graphics module
; as a series of commands with
; two parameters each.

msgc:
        mov r0,#2               ;# of data bytes
msgc2:
        clr a
        movc a,@a+dptr          ;get byte
        cjne a,#0a1h,msgc3      ;done?
        ret
msgc3:  mov r1,a
        lcall writed            ;send it   
        inc dptr
        djnz r0,msgc2
        clr a
        movc a,@a+dptr          ;get command
        mov r1,a
        lcall writec            ;send command
        sjmp msgc               ;next command
   
; MSGD sends the data pointed to by
; the DPTR to the graphics module.

msgd:
        clr a
        movc a,@a+dptr          ;get byte
        cjne a,#0a1h,msgd1      ;done?
        ret
msgd1:
        mov r1,a
        lcall writed            ;send data
        inc dptr
        sjmp msgd   

; WRITEC sends the byte in R1 to a
; graphics module as a command.

writec:
        lcall status            ;display ready?
        setb p3.2               ;c/d=1
writec1:
        mov p1,r1               ;get data
        clr p3.0                ;strobe it
        setb p3.0
        ret
   
; WRITED sends the byte in R1 to the
; graphics module as data.

writed:
        lcall status            ;display ready?
        clr p3.0                ;c/d = 0
        sjmp writec1   
   
; STATUS check to see that the graphic
; display is ready. It won't return
; until it is.

status:
        setb p3.2               ;c/d=1
        mov p1,#0ffh            ;P1 to input
        mov r3,#0bh             ;status bits mask
stat1:
        clr p3.1                ;read it
        mov a,p1
        setb p3.1
        anl a,r3                ;status OK?
        clr c
        subb a,r3
        jnz stat1
        ret

;************************************************
; TABLES AND DATA

; Initialization bytes for 240x64

msgi1:
        db 80h,07h,40h          ;text home address
        db 1eh,00,41h           ;text area
        db 00,00,42h            ;graphic home address
        db 1eh,00,43h           ;graphic area
        db 00,00,81h            ;mode set
        db 00,00,24h            ;address pointer set
        db 00,00,98h            ;display mode set
        db 0a1h

msgi2:
        db 00,00,0b0h           ;auto mode
        db 0a1h
   
;240x64 Bitmap graphic data
;Only the first 8 bytes are shown here
;The real graphic consists of 1920 bytes
;of binary data.

msg1:
        db 00h,00h,00h,00h,00h,00h,00h,00h
        db 0a1h
   
   end
