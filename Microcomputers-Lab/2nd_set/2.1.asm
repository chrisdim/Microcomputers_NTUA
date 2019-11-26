;This program implements a binary counter in PORTB with frequency=1/200ms.
;IF PD7 (Pin7 of PORTD) is ON:
;   When an interrupt occurs (INT1) a counter for the number of interrupts is
;   updated. This counter is displayed in binary format in portA.
;ELSE:
;   Dont update
;The Interrupt Service Routine, also, includes a Spark Prevention Loop
; Author: Ntouros Evangelos


.include "m16def.inc"
	.org 0x0
	rjmp RESET					;put the main program in the start  of the RAM
	.org 0x4					;0x4 is the address where PC jumps if int1 occurs
	rjmp ISR1					;jump to the isr for int1

RESET:
	.def temp=r16
	.def timer_counter=r18
	clr timer_counter
	.def inter_counter=r19
	clr inter_counter

	ldi temp,LOW(RAMEND)
	out SPL,temp
	ldi temp,HIGH(RAMEND)
	out SPH,temp				;initialize the stack

	ldi temp,(1<<ISC11)|(1<<ISC10)
	out MCUCR,temp				;MCUCR: ....1100 (int1 going upwards)
	ldi temp,(1<<INT1)
	out GICR,temp				;GICR: 10...... (enable int1)
	sei							;enable interrupts in general

	ser temp
	out DDRB,temp				;B port for output
	out DDRA,temp				;A port for output
	clr temp
	out DDRD,temp				;D port for input
;-----------MAIN LOOP--------------------------------
MAIN_LOOP:
	out PORTB,timer_counter		;main program loop
	ldi r24,low(200)
	ldi r25,high(200)			;(r24:r25) = 200(dec)
	rcall wait_msec
	inc timer_counter
	rjmp MAIN_LOOP
;------------WAIT ROUTINES---------------------------
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

wait_usec:				    ;998.375usec in total
	sbiw r24,1			    ;2 cycles (0.250usec)
	nop					    ;1 cycle (0.125usec)
	nop					    ;1 cycle (0.125usec)
	nop					    ;1 cycle (0.125usec)
	nop					    ;1 cycle (0.125usec)
	brne wait_usec		    ;1 or 2 cycles (0.125 or 0.250usec)
	ret					    ;4 cycles (0.500usec)
;-----------------Interrupt Service Routine----------------------
ISR1:
	in temp,SREG
	push temp					;save the MCU flags in stack
	push r24
	push r25

SPARK_PREVENTION_LOOP:
	ldi temp,(1<<INTF1)			;make 7th bit of GIFR 0 by writing 1 to it
	out GIFR,temp

	ldi r24,low(5)
	ldi r25,high(5)
	rcall wait_msec				;delay 5msec and
	in temp,GIFR				;and read GIFR
	andi temp,0x80
	subi temp,0x80
	breq SPARK_PREVENTION_LOOP	;if 7th bit of GIFR is 1 a spark occured and I run the loop again

	in temp, PIND
	andi temp,0x80
	subi temp,0x80
	brne SKIP_INTER				;if 7th bit is 0 then dont count this interrupt
	inc inter_counter

SKIP_INTER:
	out PORTA,inter_counter

	pop r25
	pop r24
	pop temp
	out SREG,temp				;pop previus flag state
	reti 						;this command pops the PC from the stack and set the I flag of SREG
