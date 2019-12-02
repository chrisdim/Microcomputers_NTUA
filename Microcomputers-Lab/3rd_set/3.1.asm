;This program implements an electronic lock. In RESET flag are defined two digits of a dec number.
;If the user presses the right number in the 4x4 keypad of EASYAVR6 then a success message is
;displayed. Otherwise an error message should be displayed.
;Success message: PB0-7 --> ON for 4 seconds
;Error message  : PB0-7 --> ON and OFF with freq=1/250msec for 4 seconds
;The program should not accept any pressed buttons when two have been already pressed, for 4 seconds.
/*
 * Author: Ntouros Evangelos
 */

.include "m16def.inc"

;--------DATA SEGMENT-------------
.DSEG
	_tmp_: .byte 2


;--------CODE SEGMENT-------------
.CSEG
	.org 0x0
	rjmp RESET					;put the main program in the start of the RAM

RESET:
	.equ FIRST_DIGIT=0x31
	.equ SECOND_DIGIT=0x32

	.def temp=r16
	.def buttons_pressed=r17
	.def first_number=r18
	.def second_number=r19
	.def loop_error_counter=r20
	clr buttons_pressed
	clr first_number
	clr second_number
	ldi loop_error_counter,8

	ldi temp,LOW(RAMEND)
	out SPL, temp
	ldi temp,HIGH(RAMEND)
	out SPH, temp				;initialize the stack

	ser temp
	out DDRB, temp				;PORTB (output)
	ldi temp,(1<<PC7)|(1<<PC6)|(1<<PC5)|(1<<PC4)
	out DDRC,temp				;PORTC is used by READ4X4

START:
	ldi r24,20				;20 msec delay in READ4X4 for sparks
	rcall READ4X4			;input r22, output r24 with the ascii code of the pressed button
	cpi r24,0				;if a button is pressed -->r24!=0
	breq START				;loop here while (no button pressed)
	push r24				;when a button is pressed save its ascii
	inc buttons_pressed		;increment the number of pressed buttons
	cpi buttons_pressed,2
	brne START				;when 2 buttons are pressed stop reading and evaluate
EVALUATE:
	pop second_number
	pop first_number
	cpi first_number,FIRST_DIGIT
	brne ERROR
	cpi second_number,SECOND_DIGIT
	brne ERROR
SUCCESS:					;reached here because both buttons where the right ones
	clr buttons_pressed		;make number of pressed buttons ZERO for the next check of numbers
	ldi r24,0xa0
	ldi r25,0x0f
	ser temp
	out PORTB,temp
	rcall wait_msec
	clr temp
	out PORTB,temp
	rjmp START
ERROR:						;reached here(jumping SUCCESS flag) because one or two buttons wrong
	clr buttons_pressed		;make number of pressed buttons ZERO for the next check of numbers
LOOP_ERROR:					;this loop implements ON-->OFF frequency=1/250 Hz
	ldi r24,0xfa
	ldi r25,0x00			;250 = 0x00fa
	ser temp
	out PORTB,temp
	rcall wait_msec
	ldi r24,0xfa
	ldi r25,0x00			;250 = 0x00fa
	clr temp
	out PORTB,temp
	rcall wait_msec
	dec loop_error_counter
	cpi loop_error_counter,0
	brne LOOP_ERROR
	ldi loop_error_counter,8
	rjmp START

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
	ldi r24,'*'
	sbrc r26,0
	ret
	ldi r24,'0'
	sbrc r26,1
	ret
	ldi r24,'#'
	sbrc r26,2
	ret
	ldi r24,'D'
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
	ldi r24,'C'
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
	ldi r24,'B'
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
	ldi r24,'A'
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
