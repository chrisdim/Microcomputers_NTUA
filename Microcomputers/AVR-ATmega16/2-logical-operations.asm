;This program has the input in portA and the output in portB.
;It implements the bellow logical expression.
;	f0 = not((a and b and c) or (not c and d))
;	f1 = (a or b) and (c or d)
;Where a is the LSB of the input, b the second bit of input and so on,
;f0 is the LSB of the output and f0 the second bit.

;This example is the second exercise of the fourth set from 2019.


.INCLUDE "m16def.inc"

.def input=r18
.def temp=r19
.def regForXor=r17
.def A=r20
.def B=r21
.def C=r22
.def D=r23
.def F0=r24
.def F1=r25

	ldi regForXor,1
main:	
	clr temp
	out DDRA,temp		;portA for input
	ser temp
	out DDRB,temp		;portB for output

	in input,PINA		;A
	mov A,input
	andi A,0x01		;make A in format 0000000x

	mov B,input		;B
	andi B,0x02
	ror B			;make B in format 0000000x

	mov C,input		;C
	andi C,0x04
	ror C
	ror C			;make C in format 0000000x

	mov D,input		;D
	andi D,0x08
	ror D
	ror D
	ror D			;make D in format 0000000x

	mov F0,A		;F0
	and F0,B
	and F0,C
	mov temp,C
	eor temp,regForXor;	;not in bits is achieved with XOR
	and temp,D
	or F0,temp
	eor F0,regForXor

	mov F1,A		;F1
	or F1,B
	mov temp,C
	or temp,D
	and F1,temp
	
	clc
	rol F1
	add F0,F1
	out PORTB,F0		;result in portB

	rjmp main
end:
