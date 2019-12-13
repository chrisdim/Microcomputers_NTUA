/*
 * A program to display in the LCD the temperature measured by the sensor DS1820.
 * In order to check the functionality a test program is embedded in the code.
 *
 * Turn PB7 ON and reset to enter test mode.
 * Now give 2-byte values (from 4x4 keypad) as the sensor would have sent (see manual)
 * to check extreme temperatures, say ff92 that should show -55 oC in the LCD.
 *
 * Turn PB7 OFF and reset to enter real mode again.
 *
 * Author: Ntouros Evangelos
 *
 * The C version of this problem is implemented in two separate programs,
 * "4.2_real_mode_C.c" and "4.2_test_mode_C.c".
*/
.include "m16def.inc"

;--------DATA SEGMENT-------------
.DSEG
	_tmp_: .byte 2

;--------CODE SEGMENT-------------
.CSEG
	.org 0x0
	rjmp RESET

RESET:
	/*DO NOT USE r21: it is used from bcd_to_3hex*/
	.def temp=r16
	.def temp2=r23
	.def units=r17			;for bcd_to_3hex
	.def decades=r18		;for bcd_to_3hex
	.def hundrents=r19		;for bcd_to_3hex
	.def sign=r22			;for '-' or '+' sign

	clr temp
	clr temp2
	clr units
	clr decades
	clr hundrents
	clr sign

	ldi temp,LOW(RAMEND)
	out SPL, temp
	ldi temp,HIGH(RAMEND)
	out SPH, temp				;initialize the stack

	ldi temp,0x00
	out DDRB,temp				;PINB (input) for real or test mode (PB7 = 0/1)
	ser temp
	out DDRD,temp				;PORTD (output) for LCD
	ldi temp,(1<<PC7)|(1<<PC6)|(1<<PC5)|(1<<PC4)
	out DDRC,temp				;PORTC is used by READ4X4

	rcall lcd_init

;choose between TEST (PB7=1) or REAL MODE (PB7=0)
	in temp,PINB
	sbrs temp,7
	rjmp START

;------TEST-MODE--------------------------
START_TEST:
	clr temp			;counter for 4 digits

	/*read the 4 digits from the keyboard*/
LOOP1:
	ldi r24,0x20		;spark prevention delay
	rcall READ4X4
	cpi r24,0
	breq LOOP1
	push r24
	inc temp
	cpi temp,4
	brne LOOP1

	/*convert asciis to numbers*/
	ldi temp, 0x30
	pop r5				;least significal hex digit
	pop r6
	pop r7
	pop r8				;most significal hex digit
	sub r5,temp
	sub r6,temp
	sub r7,temp
	sub r8,temp

	/*estimate the hex number with digits r6,r5*/
	lsl r6
	lsl r6
	lsl r6
	lsl r6
	mov temp,r6
	mov temp2,r5
	add temp,temp2
	mov r24,temp		;r24 = r6*16 + r5

	/*r25 = first pressed digit*/
	mov r25,r8
	lsl r25
	lsl r25
	lsl r25
	lsl r25

	sbrs r25,7
	rjmp POSITIVE		;if msb is 0 the number is positive
	rjmp NEGATIVE		;otherwise if next bit 6 is 1 is negative
						;and if it is 0 take no device error

;------REAL-MODE--------------------------
START:
	rcall read_temp_routine		;returns in r25:r24 the measurement
	sbrs r25,7					;if msb of r25 is 0 the number in r24 is positive
	rjmp POSITIVE				;otherwise negative

NEGATIVE:
	sbrs r25,6					;if bit 7 of r25 is 1 and bit 6 is 1 then negative
	rjmp NO_DEVICE_DETECTED		;if bit 7 of r25 is 1 and bit 6 is 0 then no device

	ldi sign,'-'

	neg r24						;two's complement
	lsr r24                      ;because this value has accuracy 0.5 oC

	clr r10
	rol r10				        ;r10 takes the carry flag in lsb

	mov r21,r24
	rcall hex_to_3bcd
	rcall display_temp


	/*jump to START or START_TEST if you are in real or test mode, respectively*/
	in temp,PINB
	sbrs temp,7
	rjmp START
	rjmp START_TEST

POSITIVE:
	ldi sign,'+'
	lsr r24

	clr r10
	rol r10				    ;r10 takes the carry flag in lsb

	mov r21,r24
	rcall hex_to_3bcd
	rcall display_temp

	/*jump to START or START_TEST if you are in real or test mode, respectively*/
	in temp,PINB
	sbrs temp,7
	rjmp START
	rjmp START_TEST

	/*print NO device*/
NO_DEVICE_DETECTED:
	rcall lcd_init
	ldi r24,'N'
	rcall lcd_data
	ldi r24,'O'
	rcall lcd_data
	ldi r24,' '
	rcall lcd_data
	ldi r24,'D'
	rcall lcd_data
	ldi r24,'e'
	rcall lcd_data
	ldi r24,'v'
	rcall lcd_data
	ldi r24,'i'
	rcall lcd_data
	ldi r24,'c'
	rcall lcd_data
	ldi r24,'e'
	rcall lcd_data

	/*jump to START or START_TEST if you are in real or test mode, respectively*/
	in temp,PINB
	sbrs temp,7
	rjmp START
	rjmp START_TEST

/********************************* DRIVERS and routines***************************************/

;ROUTINE to display measured temperatures in LCD
display_temp:
	rcall lcd_init			;clear display

	ldi temp,0x30
	add hundrents,temp
	add decades,temp
	add units,temp

	mov r24,sign
	rcall lcd_data

	cpi hundrents,0x30
	breq SKIP_HUNDRENTS		;if hundrents are 0 dont display

	mov r24,hundrents
	rcall lcd_data
SKIP_HUNDRENTS:
	cpi decades,0x30
	breq SKIP_DECADES		;if decades are 0 dont display

	mov r24,decades
	rcall lcd_data
SKIP_DECADES:
	mov r24,units
	rcall lcd_data

    /*add a .5 value of temperature if carry flag was 1 previously*/
	ror r10				;give carry flag to SREG
	brcc NO_POINT5
	ldi r24,'.'
	rcall lcd_data
	ldi r24,'5'
	rcall lcd_data

NO_POINT5:
	ldi r24,0xb2		;degree symbol
	rcall lcd_data
	ldi r24,'C'
	rcall lcd_data
	ret

;ROUTINE: hex_to_bcd --> convert a hex number to 3 a digit bcd
;receives input number in r21
hex_to_3bcd:
    clr units
	clr decades
	clr hundrents
CONTINUE_hex_to_3bcd:
	;clr decades				;99% not needed. In case a bug occurs turn them on and see if they are needed
	;clr units					;99% not needed. In case a bug occurs turn them on and see if they are needed

    cpi r21,100
    brge GREATER_100			;if number - 100 >= 100 go to increase the hundrents
LOWER_100:
	rjmp CONTINUE_for_decades
GREATER_100:
    inc hundrents				;increase hundrents
    subi r21,100				;number = number - 100
    rjmp CONTINUE_hex_to_3bcd

CONTINUE_for_decades:
	clr units					;99% not needed. In case a bug occurs turn them on and see if they are needed

	cpi r21,10
	brge GREATER_10
LOWER_10:
	mov units,r21
	rjmp EXIT_hex_to_3bcd
GREATER_10:
	inc decades					;increase decades
	subi r21,10					;number = number - 10
	rjmp CONTINUE_for_decades

EXIT_hex_to_3bcd:
    ret

/*
 * A driver for temperature sensor DS1820
 * Affected registers r27:r26, r25:r24(it returns the measured temperature)
 */
read_temp_routine:
	rcall one_wire_reset
	sbrs r24,0
	rjmp NO_DEVICE

	;disable device choose feature, since we have only one device
	ldi r24, 0xCC
	rcall one_wire_transmit_byte

	;start a measurement
	ldi r24, 0x44
	rcall one_wire_transmit_byte

	;check if measurement has been completed
loop_till_measurement_is_over:
	rcall one_wire_receive_bit
	sbrs r24,0
	rjmp loop_till_measurement_is_over

	;wake up from low power mode and check for connected device
	rcall one_wire_reset
	sbrs r24,0
	rjmp NO_DEVICE

	;disable device choose feature, since we have only one device
	ldi r24, 0xCC
	rcall one_wire_transmit_byte
	;send command for reading measured temperature
	ldi r24,0xBE
	;read the 16bit temperature in r25:r24
	rcall one_wire_transmit_byte
	rcall one_wire_receive_byte
	push r24
	rcall one_wire_receive_byte
	mov r25,r24
	pop r24
	rjmp EXIT_read_temp_routine

NO_DEVICE:
	ldi r25,0x80
	ldi r24,0x00

EXIT_read_temp_routine:
	ret

/*
 * One wire receive and transmit protocol implementation
 */

; File Name: one_wire.asm
; Title: one wire protocol
; Target mcu: atmega16
; Development board: easyAVR6
; Assembler: AVRStudio assembler
; Description:
; This file includes routines implementing the one wire protocol over the PA4 pin of the microcontroller.
; Dependencies: wait.asm

; Routine: one_wire_receive_byte
; Description:
; This routine generates the necessary read
; time slots to receives a byte from the wire.
; return value: the received byte is returned in r24.
; registers affected: r27:r26 ,r25:r24
; routines called: one_wire_receive_bit

one_wire_receive_byte:
	ldi r27 ,8
	clr r26
loop_:
	rcall one_wire_receive_bit

	lsr r26
	sbrc r24 ,0
	ldi r24 ,0x80
	or r26 ,r24
	dec r27
	brne loop_
	mov r24 ,r26
	ret

; Routine: one_wire_receive_bit
; Description:
; This routine generates a read time slot across the wire.
; return value: The bit read is stored in the lsb of r24.
; if 0 is read or 1 if 1 is read.
; registers affected: r25:r24
; routines called: wait_usec

one_wire_receive_bit:
	sbi DDRA ,PA4
	cbi PORTA ,PA4  ; generate time slot
	ldi r24 ,0x02
	ldi r25 ,0x00
	rcall wait_usec
	cbi DDRA ,PA4    ;  release the line
	cbi PORTA ,PA4
	ldi r24 ,10       ; wait 10 �s
	ldi r25 ,0
	rcall wait_usec
	clr r24           ; sample the line
	sbic PINA ,PA4
	ldi r24 ,1
	push r24
	ldi r24 ,49       ; delay 49 �s to meet the standards
	ldi r25 ,0        ; for a minimum of 60 �sec time slot
	rcall wait_usec ; and a minimum of 1 �sec recovery time
	pop r24
	ret

; Routine: one_wire_transmit_byte
; Description:
; This routine transmits a byte across the wire.
; parameters:
; r24: the byte to be transmitted must be stored here.
; return value: None.
; registers affected: r27:r26 ,r25:r24
; routines called: one_wire_transmit_bit

one_wire_transmit_byte:
	mov r26 ,r24
	ldi r27 ,8
_one_more_:
	clr r24
	sbrc r26 ,0
	ldi r24 ,0x01
	rcall one_wire_transmit_bit

	lsr r26
	dec r27
	brne _one_more_
	ret

; Routine: one_wire_transmit_bit
; Description:
; This routine transmits a bit across the wire.
; parameters:
; r24: if we want to transmit 1
; then r24 should be 1, else r24 should
; be cleared to transmit 0.
; return value: None.
; registers affected: r25:r24
; routines called: wait_usec

one_wire_transmit_bit:
	push r24          ; save r24
	sbi DDRA ,PA4
	cbi PORTA ,PA4  ; generate time slot
	ldi r24 ,0x02
	ldi r25 ,0x00
	rcall wait_usec

	pop r24           ; output bit
	sbrc r24 ,0
	sbi PORTA ,PA4
	sbrs r24 ,0
	cbi PORTA ,PA4
	ldi r24 ,58     ; wait 58 �sec for the
	ldi r25 ,0        ; device to sample the line
	rcall wait_usec

	cbi DDRA ,PA4  ; recovery time
	cbi PORTA ,PA4
	ldi r24 ,0x01
	ldi r25 ,0x00
	rcall wait_usec

	ret

; Routine: one_wire_reset
; Description:
; This routine transmits a reset pulse across the wire
; and detects any connected devices.
; parameters: None.
; return value: 1 is stored in r24
; if a device is detected, or 0 else.
; registers affected r25:r24
; routines called: wait_usec


one_wire_reset:
	sbi DDRA ,PA4  ; PA4 configured for output
	cbi PORTA ,PA4; 480 �sec reset pulse
	ldi r24 ,low(480)
	ldi r25 ,high(480)
	rcall wait_usec

	cbi DDRA ,PA4      ; PA4 configured for input
	cbi PORTA ,PA4
	ldi r24 ,100       ; wait 100 �sec for devices
	ldi r25 ,0         ; to transmit the presence pulse
	rcall wait_usec

	in r24 ,PINA    ; sample the line
	push r24
	ldi r24 ,low(380) ; wait for 380 �sec
	ldi r25 ,high(380)
	rcall wait_usec

	pop r25            ; return 0 if no device was
	clr r24            ; detected or 1 else
	sbrs r25 ,PA4
	ldi r24 ,0x01
	ret

/*
 *	A driver for the 2x16 LCD peripheral of EASYAVR6
 */
write_2_nibbles:
	;SEND THE 4 MSB
	push r24				;save r24
	in r25 ,PIND			;read in r25 the PIND
	andi r25 ,0x0f			;the 4 lsb have the value that must not be changed during time
							;(I read them and I put them back every time)
	andi r24 ,0xf0			;the 4 msb have the value to transfer
	add r24 ,r25
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3			;make a pulse (Enable) in PD3 to transfer the data
	;SEND THE 4 LSB
	pop r24					;pop saved r24 to transfer the 4 lsb
	swap r24
	andi r24 ,0xf0
	add r24 ,r25
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3			;make a pulse (Enable) in PD3 to transfer the data
	ret

lcd_data:
	sbi PORTD ,PD2			;choose the data register (PD2 = 1)
	rcall write_2_nibbles	;send the byte

	ldi r24 ,43				;wait 43 msec so the transfer is completed
	ldi r25 ,0
	rcall wait_usec

	ret

lcd_command:
	cbi PORTD ,PD2			;choose the command register
	rcall write_2_nibbles

	ldi r24 ,39				;less waiting is needed now
	ldi r25 ,0
	rcall wait_usec
	ret

lcd_init:
	ldi r24 ,40
	ldi r25 ,0
	rcall wait_msec			;wait 40msec for the auto-initialization

	ldi r24 ,0x30			;change to 8-bit mode
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec

	ldi r24 ,0x30
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec

	ldi r24 ,0x20			;change to 4 bit mode
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec

	ldi r24 ,0x28
	rcall lcd_command		;

	ldi r24 ,0x0c
	rcall lcd_command

	ldi r24 ,0x01
	rcall lcd_command

	ldi r24 ,low(1530)
	ldi r25 ,high(1530)
	rcall wait_usec

	ldi r24 ,0x06
	rcall lcd_command

	ret

/*
 *	A driver for the 4x4 buttons peripheral of EASYAVR6
 *
 *	READ FROM:			4x4 KEYPAD DRIVER
 *	INPUT:				R24 HAS THE SPARK PREVENTION DELAY TIME
 *	OUTPUT:				R24 HAS THE ASCII CODE OF THE PRESSED BUTTON
 *	AFFECTED REGISTERS: R27,R26,R25,R24,R23,R22
 *			IF PUSH AND POP ARE USED LIKE BELOW AFFECTED IS ONLY r24
 *	AFFECTED PORTS:		PORTC
 *
 */

READ4X4:
	push r22			;save r22
	push r23			;save r23
	push r25			;save r25
	push r26			;save r26
	push r27			;save r27
	in r27,SREG
	push r27			;save SREG

	rcall scan_keypad_rising_edge
	rcall keypad_to_ascii

	pop r27
	out SREG,r27		;pop SREG
	pop r27				;pop r27
	pop r26				;pop r26
	pop r25				;pop r25
	pop r23				;pop r23
	pop r22				;pop r22
	ret

;ROUTINE: scan_row -->Checks one line of the keyboard for pressed buttons.
;INPUT: The number of the line checked(1-4)
;OUTPUT: 4 lsbs of r24 have the pressed buttons
;REGS: r25:r24
;CALLED SUBROUTINES: None
scan_row:
	ldi r25,0x08			;initialize with 0b00001000
back_:
	lsl r25					;logical swift left of the '1' as many times as
	dec r24					;r24 indicates (the number of the row currently checked->1 to 4)
	brne back_
	out PORTC,r25			;the checked row is set to '1'
	nop
	nop						;delay 2 x nop so as state changes correctly
	in r24,PINC				;read PINC. The 4 lsb have the positions of the pushed buttons
	andi r24,0x0f
	ret

;ROUTINE: scan_keypad --> Checks the whole keyboard for pressed buttons.
;INPUT: None
;OUTPUT: r24:r25 have the status of the 16 buttons
;REGS: r27:r26, r25:r24
;CALLED SUBROUTINES: scan_row
scan_keypad:
	ldi r24,0x01			;check first line
	rcall scan_row
	swap r24				;save the result
	mov r27,r24				;in the 4 msbs of r27
	ldi r24,0x02			;check second line
	rcall scan_row
	add r27,r24				;save the result in the 4 lsbs of 27
	ldi r24,0x03			;check third line
	rcall scan_row
	swap r24				;save the result
	mov r26,r24				;in the 4 msbs of r26
	ldi r24,0x04			;check fourth line
	rcall scan_row
	add r26,r24				;save the result in the 4 lsbs of 26
	movw r24,r26			;move the result in r25:r24
	ret

;ROUTINE: scan_keypad_rising_edge --> Checks for pressed button that weren't pressed the last time it was called and now are.
;									  It also takes care of sparks.
;									  _tmp_ should be initialized by the programer in the start of the program.
;INPUT: r24 has the spark delay time
;OUTPUT: r25:r24 have the status of the 16 buttons
;REGS: r27:r26, r25:r24. r22:r23
;CALLED SUBROUTINES: scan_keypad, wait_msec
scan_keypad_rising_edge:
	mov r22,r24				;save spark prevention delay time in r22
	rcall scan_keypad		;check the keyboard for pressed numbers
	push r24				;save the result
	push r25
	mov r24,r22				;delay r22 msec
	ldi r25,0
	rcall wait_msec
	rcall scan_keypad		;check the keyboard again and discard
	pop r23					;the buttons that show spark effects
	pop r22
	and r24,r22
	and r25,r23
	ldi r26,low(_tmp_)		;load previous buttons status in r27:r26
	ldi r27,high(_tmp_)
	ld r23,X+
	ld r22,X
	st X,r24				;save in RAM the new state
	st -X,r25				;of the buttons
	com r23
	com r22
	and r24,r22				;find the ones that have really been pressed
	and r25,r23
	ret

;ROUTINE: keypad_to_ascii --> Returns ascii of the first pressed button's character
;INPUT:	r25:24 have the state of the 16 buttons
;OUTPUT: r24 has the ascii of the first pressed button's character
;REGS: r27:r26, r25:r24
;CALLED SUBROUTINES: None
keypad_to_ascii:
	movw r26,r24
	;this should return the ascii code of 'e'
	;but in order to avoid extra commands in main program
	;I make it return a value according to the other returns
	;0x3e will receive a -0x30 from main to take its value
	;just like 0x39 will give 9
	ldi r24, 0x3e
	sbrc r26,0
	ret
	ldi r24,'0'
	sbrc r26,1
	ret
	ldi r24, 0x3f
	sbrc r26,2
	ret
	ldi r24,0x3d
	sbrc r26,3
	ret
	ldi r24,'7'
	sbrc r26,4
	ret
	ldi r24,'8'
	sbrc r26,5
	ret
	ldi r24,'9'
	sbrc r26,6
	ret
	ldi r24,0x3c
	sbrc r26,7
	ret
	ldi r24,'4'
	sbrc r27,0
	ret
	ldi r24,'5'
	sbrc r27,1
	ret
	ldi r24,'6'
	sbrc r27,2
	ret
	ldi r24,0x3b
	sbrc r27,3
	ret
	ldi r24,'1'
	sbrc r27,4
	ret
	ldi r24,'2'
	sbrc r27,5
	ret
	ldi r24,'3'
	sbrc r27 ,6
	ret
	ldi r24,0x3a
	sbrc r27,7
	ret
	clr r24
	ret


;--------------WAIT ROUTINES---------------------------
wait_msec:					;1msec in total
	push r24				;2 cycles (0.250usec)
	push r25				;2 cycles (0.250usec)
	ldi r24,low(998)		;1 cycle  (0.125usec)
	ldi r25,high(998)		;1 cycle  (0.125usec)
	rcall wait_usec			;3 cycles (0.375usec)
	pop r25					;2 cycles (0.250usec)
	pop r24					;2 cycles (0.250usec)
	sbiw r24,1				;2 cycle  (0.250usec)
	brne wait_msec			;1 or 2 cycles
	ret						;4 cycles (0.500usec)

wait_usec:					;998.375usec in total
	sbiw r24,1				;2 cycles (0.250usec)
	nop						;1 cycle (0.125usec)
	nop						;1 cycle (0.125usec)
	nop						;1 cycle (0.125usec)
	nop						;1 cycle (0.125usec)
	brne wait_usec			;1 or 2 cycles (0.125 or 0.250usec)
	ret						;4 cycles (0.500usec)
