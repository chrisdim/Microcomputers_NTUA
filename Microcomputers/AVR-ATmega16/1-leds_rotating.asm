;This program has the input in portA and the output in portB.
;It implements a rotating led that starts from LSB of portB and rotates
;left. When it goes to the MSB it starts rotating right and so on, continuously. 
;When I press PA0 it should stop and when I release it it should 
;continue from where it has stopped.

;This example is the first exercise of the fourth set from 2019.

.INCLUDE "m16def.inc"

.def counter=r20
.def temp=r21
.def lightBit=r22
.def inputA=r23
.org 0

reset:
	ldi r24,low(RAMEND)		;itilialize stack pointer
	out SPL,r24
	ldi r24,high(RAMEND)
	out SPH,r24
	clr lightBit

main:
	clr temp			;reset temp
	out DDRA,temp			;portA for input
	ser temp			;set temp 
	out DDRB,temp			;portB for output
	
	ldi lightBit,0x01		
	out PORTB,lightBit		;flash the LSB
	ldi counter,7			;set counter value 7

left:
	in inputA,PINA			;read input
	subi inputA,1	
	breq left			;if input 0x01 stay on loop and do nothing
					;if not exit and do the following
	ldi r24,low(500)
	ldi r25,high(500)		;(r25:r24) <-- 500 
	rcall wait_msec			;delay 0.5sec
	clc				;reset C flag, rol does LSB <-- C
	rol lightBit			
	out PORTB,lightBit		;flash the next led to the left
	dec counter			;counter--
	cpi counter,0			;if counter == 0 I arrived the MSB so I go right
	breq right
	rjmp left			;if counter != 0 go left again

right:
	in inputA,PINA			
	subi inputA,1
	breq right
	ldi r24,low(500)
	ldi r25,high(500)		
	rcall wait_msec			;delay 0.5sec
	clc				;reset C flag, ror does MSB <-- C
	ror lightBit
	out PORTB,lightBit		;flash the next led to the right
	inc counter			;counter++
	cpi counter,7			;if counter == 7 I arrived the LSB so I go left
	breq left
	rjmp right			;if counter != 7 go right again

wait_msec:				;1msec in total
	push r24			;2 cycles (0.250usec)
	push r25			;2 cycles (0.250usec)
	ldi r24,low(998)		;1 cycle  (0.125usec)
	ldi r25,high(998)		;1 cycle  (0.125usec)
	rcall wait_usec			;3 cycles (0.375usec)
	pop r25				;2 cycles (0.250usec)
	pop r24				;2 cycles (0.250usec)
	sbiw r24,1			;2 cycle  (0.250usec)
	brne wait_msec			;1 or 2 cycles	
	ret				;4 cycles (0.500usec)

wait_usec:				;998.375usec in total
	sbiw r24,1			;2 cycles (0.250usec)
	nop				;1 cycle (0.125usec)
	nop				;1 cycle (0.125usec)
	nop				;1 cycle (0.125usec)
	nop				;1 cycle (0.125usec)
	brne wait_usec			;1 or 2 cycles (0.125 or 0.250usec)
	ret				;4 cycles (0.500usec)

end:
