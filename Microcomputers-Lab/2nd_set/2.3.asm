;When INT1 or PD7 is pressed PB0 should turn ON. It should stay ON for 4 seconds
;and then go OFF. If one of them is pressed again turn ON all the LEDS of PORTB
;renew the time of 4 seconds and continue running. After 500msec turn OFF PB1-PB7.
; Author: Ntouros Evangelos

.include "m16def.inc"
	.org 0x0
	rjmp RESET					;put the main program in the start  of the RAM
	.org 0x4					;0x4 is the address where PC jumps if int1 occurs
	rjmp ISR1					;jump to the isr for int1
    .org 0x10					;0x10 is the address where PC jumps if timer1 overflows
    rjmp ISR_TIMER1_OVF			;jump to the isr for timer1 overflow
;-----------------------------------------------------------
RESET:
    .def temp=r16
    clr temp
	.def flag=r18
	clr flag					;flag is 0xff when the next int=errupt or 
								;push of PA7 causes renewal of 4 seconds
	ldi temp,LOW(RAMEND)
	out SPL,temp
	ldi temp,HIGH(RAMEND)
	out SPH,temp				;initialize the stack

	ldi temp,(1<<ISC11)|(1<<ISC10)
	out MCUCR,temp				;MCUCR: ....1100 (int1 going upwards)
	ldi temp,(1<<INT1)
	out GICR,temp				;GICR: 10...... (enable int1)
    ldi temp,(1<<TOIE1)
    out TIMSK,temp              ;enable interrupts from timer1
	sei							;enable interrupts in general
;THE FOLLOWING TWO LINE COULD BE HERE BUT ARE NOT NESSESARY BECAUSE
;RENEWAL AND ISR_TIMER1_OVF FUNCTIONS TAKE CARE OF THAT
    ;ldi temp,(1<<CS12)|(0<<CS11)|(1<<CS10)
    ;out TCCR1B,temp             ;CK/1024

    ser temp
    out DDRB,temp               ;port B for output
    clr temp
    out DDRA,temp               ;port A for input
;-----------------------------------------------------------
MAIN_LOOP:
	sbic PINA,7
	rjmp MAIN_LOOP				;stay here while PA7=1
IS_ZERO:
	sbis PINA,7
	rjmp IS_ZERO				;stay here while PA7=0

;here the button PA7 has gone from OFF to ON aka has been pushed
	cpi flag,0xff
	breq DO_RENEWAL_FROM_PA7_PUSH
	rcall NOT_RENEWAL
	rjmp MAIN_LOOP
DO_RENEWAL_FROM_PA7_PUSH:
	rcall RENEWAL
    rjmp MAIN_LOOP
;-----------------------------------------------------------
ISR1:
    push temp
	in temp,SREG
	push temp

	cpi flag,0xff
	breq DO_RENEWAL_FROM_INTERRUPT
	rcall NOT_RENEWAL
	rjmp EXIT_ISR1
DO_RENEWAL_FROM_INTERRUPT:
	rcall RENEWAL

EXIT_ISR1:
;IF I WANT TO REMOVE AN INTERRUPT IF THIS OCCURS WHILE I AM ALREADY IN AN INTERRUPT
	;ldi temp,(1<<INTF1)			;make 6th bit of GIFR 0 by writing 1 to it
	;out GIFR,temp

    pop temp
	out SREG,temp
	pop temp
    reti
;-----------------------------------------------------------
ISR_TIMER1_OVF:
	push temp
	in temp,SREG
	push temp

	ldi temp,(0<<CS12)|(0<<CS11)|(0<<CS10) ;stop the timer
	out TCCR1B,temp

    ldi temp,0
    out PORTB,temp
	clr flag					;turn off lights and clear renewal flag because
								;4 seconds have expired
	pop temp
	out SREG,temp
	pop temp
    reti
;-----------------------------------------------------------
NOT_RENEWAL:
	push temp
	in temp,SREG
	push temp

	ldi temp,(1<<CS12)|(0<<CS11)|(1<<CS10)
	out TCCR1B,temp             ;CK/1024

	ser flag					;set the renewal flag

	ldi temp,0x85               ;timer1 initialization for overflow after 4 seconds
    out TCNT1H,temp             ;8MHz/1024=7812.5Hz-->65536-4x7812.5=0d34286=0x85ee
    ldi temp,0xee
    out TCNT1L,temp

	ldi temp,0x01
	out PORTB,temp				;turn on the PB0

	pop temp
	out SREG,temp
	pop temp
	ret
;-----------------------------------------------------------
RENEWAL:
	push temp
	in temp,SREG
	push temp

    ldi temp,0x85               ;timer1 initialization for overflow after 4 seconds
    out TCNT1H,temp             ;8MHz/1024=7812.5Hz-->65536-4x7812.5=0d34286=0x85ee
    ldi temp,0xee
    out TCNT1L,temp

    ser temp                   ;light all leds in PORTB
    out PORTB,temp

	ldi r24,low(500)
	ldi r25,high(500)
	rcall wait_msec				;delay 500msec

    ldi temp,0x01
    out PORTB,temp              ;turn off the lights after 0.5 sec except for LSB

	pop temp
	out SREG,temp
	pop temp
	ret
;-----------------------------------------------------------
;WAIT ROUTINES
;-----------------------------------------------------------
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
