;This program uses the main core of the previous one (a binary counter in PORTB).
;When an INT0 occurs it turns ON a number of LEDS in PORTC (lsb to msb).
;This number is the number of turned ON switches in PORTA.
; Author: Ntouros Evangelos

.include "m16def.inc"
	.org 0x0
	rjmp RESET					;put the main program in the start  of the RAM
	.org 0x2					;0x2 is the address where PC jumps if int0 occurs
	rjmp ISR0					;jump to the isr for int0

RESET:
	.def timer_counter=r22
	clr timer_counter
	.def outC=r21
	.def inA=r20
	.def temp=r16

	ldi temp,LOW(RAMEND)
	out SPL, temp
	ldi temp,HIGH(RAMEND)
	out SPH, temp				;initialize the stack

	ldi temp,(1<<ISC01)|(1<<ISC00)
	out MCUCR,temp				;MCUCR: ....0011 (int0 going upwards)
	ldi temp,(1<<INT0)
	out GICR,temp				;GICR: 01...... (enable int0)
	sei							;enable interrupts in general

	ser temp
	out DDRB,temp				;B and C ports for output
	out DDRC,temp
	clr temp
	out DDRA,temp				;A port for input

MAIN_LOOP:
	out PORTB,timer_counter		;main program loop
	ldi r24,low(200)
	ldi r25,high(200)
	rcall wait_msec
	inc timer_counter
	rjmp MAIN_LOOP

wait_msec:				;1msec in total
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

wait_usec:				    ;998.375usec in total
	sbiw r24,1			    ;2 cycles (0.250usec)
	nop					    ;1 cycle (0.125usec)
	nop					    ;1 cycle (0.125usec)
	nop					    ;1 cycle (0.125usec)
	nop					    ;1 cycle (0.125usec)
	brne wait_usec		    ;1 or 2 cycles (0.125 or 0.250usec)
	ret					    ;4 cycles (0.500usec)

ISR0:
	in temp,SREG
	push temp					;save the MCU flags in the stack
	push r24
	push r25
SPARK_PREVENTION_LOOP:
	ldi temp,(1<<INTF0)			;make 6th bit of GIFR 0 by writing 1 to it
	out GIFR,temp

	ldi r24,low(5)
	ldi r25,high(5)
	rcall wait_msec				;delay 5msec and
	in temp,GIFR				;and read GIFR
	andi temp,0x40
	subi temp,0x40
	breq SPARK_PREVENTION_LOOP	;if 7th bit of GIFR is 1 a spark occured and I run the loop again

	in inA,PINA					;read input from port A
	ldi outC,0xff				;initialize output for port C
	ldi temp,0					;initialize LOOP2 counter for the 8 digits of input

;LOOP2 counter should go up to 9 because due to this implentation. For every LOOP2 iteration
;the input (PORTA) shifts logically left.  So with, totally 8, iterations we can check every
;digit of the input. If its 1 dont do anything. If its 0 lsr the output in PORTB which is
;initialized in ff (all lights on). Every time a "1" is found in the input a "0" is added in
;the msb side of the output.
LOOP2:
	inc temp
	cpi temp,9
	breq EXIT_LOOP2
	lsr inA
	brcs LOOP2
	lsr outC
	rjmp LOOP2
EXIT_LOOP2:
	out PORTC,outC

	pop r25
	pop r24
	pop temp
	out SREG,temp				;pop previus flag state

	reti						;this command pops the PC from the stack and set the I flag of SREG
