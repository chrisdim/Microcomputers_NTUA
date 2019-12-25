; This program measures the analog voltage of the potensiometer in EASYAVR6 
; development board and sends it with usart. 
; 
; It measures two decimal digits.

; ADC values are received via ADC interrupts. In 5.2.b.c file the program has 
; the same functionality but the ADC values are received by polling in ADCSRA
; register.
;
; 5.2.a.c is the same program implemented in C language.
; 
; The main program is a binary counter in the LEDS of PORTB.
;
; Author: Ntouros Evangelos
;

.include "m16def.inc"

;--------DATA SEGMENT-------------
.DSEG

;--------CODE SEGMENT-------------
.CSEG
	.org 0x0
	rjmp RESET
	.org 0x1c
	rjmp ADC_ISR

RESET:
	.def temp=r16
	.def counter=r17
	.def voltageL=r18
	.def voltageH=r19
	.def readADCL=r20
	.def readADCH=r22

	clr counter
	clr voltageL
	clr voltageH

	ldi temp,LOW(RAMEND)
	out SPL, temp
	ldi temp,HIGH(RAMEND)
	out SPH, temp				;initialize the stack

	ser temp
	out DDRB,temp

	/*Initialize uart and ADC*/
	rcall usart_init
	rcall ADC_init 
	sei

;----------------MAIN_LOOP---------------------
START:
	;uart delays the program so instead of 200 ms delay, I should
	;give something a lot smaller
	out PORTB,counter
	ldi r24,low(5)
	ldi r25,high(5)			
	rcall wait_msec
	inc counter
	rjmp START

ADC_ISR:
	in temp,SREG
	push temp
	push r24
	push r25

	clr voltageL
	clr voltageH
	
	;read 10 bit ADC
	in readADCL,ADCL
	in readADCH,ADCH
	
	/*BELOW IS IMPLEMENTED ADC*5/1024*/
	;ADC * 5
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH

	;integer
	; /1024 h pairnw ta bit 10-13
	mov temp,voltageH
	lsr temp
	lsr temp
	andi temp,0x0f

	mov r24,temp	
	ldi temp,0x30
	add r24,temp
	rcall usart_transmit
	
	ldi r24,'.'
	rcall usart_transmit

	;first decimal
	; *10 and take bits 10-13
	andi voltageH,0x03

	mov readADCL,voltageL
	mov readADCH,voltageH

	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
		
	mov temp,voltageH
	lsr temp
	lsr temp
	andi temp,0x0f

	mov r24,temp	
	ldi temp,0x30
	add r24,temp
	rcall usart_transmit

	;second decimal
	; *10 and take bits 10-13
	andi voltageH,0x03

	mov readADCL,voltageL
	mov readADCH,voltageH

	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
	add voltageL,readADCL
	adc voltageH,readADCH
		
	mov temp,voltageH
	lsr temp
	lsr temp
	andi temp,0x0f

	mov r24,temp	
	ldi temp,0x30
	add r24,temp
	rcall usart_transmit

	ldi r24,0x0a
	rcall usart_transmit

	/*start a new conversion*/
	ldi temp,(1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)    
	out ADCSRA,temp

	pop r25
	pop r24
	pop temp
	out SREG,temp
 
	reti

;--------------------------------------------------------------
; Routine: ADC_init 
; Description: 
; This routine initializes the 
; ADC as shown below. 
; ------- INITIALIZATIONS ------- 
; 
; Vref: Vcc (5V for easyAVR6) 
; Selected pin is A0 
; ADC Interrupts are Enabled 
; Prescaler is set as CK/128 = 62.5kHz 
; -------------------------------- 
; parameters: None. 
; return value: None. 
; registers affected: r24 
; routines called: None   
ADC_init:   
ldi r24,(1<<REFS0) ; Vref: Vcc   
out ADMUX,r24      ;MUX4:0 = 00000 for A0.   
;ADC is Enabled (ADEN=1)   
;ADC Interrupts are Enabled (ADIE=1)   
;Set Prescaler CK/128 = 62.5Khz (ADPS2:0=111)   
ldi r24,(1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)    
out ADCSRA,r24   
ret 

/*
 * A driver for USART communication
 */

; Routine: usart_init 
; Description: 
; This routine initializes the 
; usart as shown below. 
; ------- INITIALIZATIONS ------- 
; 
; Baud rate: 9600 (Fck= 8MH) 
; Asynchronous mode 
; Transmitter on 
; Reciever on 
; Communication parameters: 8 Data ,1 Stop , no Parity 
; -------------------------------- 
; parameters: None. 
; return value: None. 
; registers affected: r24 
; routines called: None 
 
 
usart_init: 
clr r24                               ; initialize UCSRA to zero 
out UCSRA ,r24 
ldi r24 ,(1<<RXEN) | (1<<TXEN)        ; activate transmitter/receiver
out UCSRB ,r24
ldi r24 ,0                            ; baud rate = 9600 
out UBRRH ,r24
ldi r24 ,51 
out UBRRL ,r24 
ldi r24 ,(1 << URSEL) | (3 << UCSZ0)  ; 8-bit character size, 
out UCSRC ,r24                        ; 1 stop bit 
ret

; Routine: usart_transmit 
; Description: 
; This routine sends a byte of data 
; using usart. 
; parameters: 
; r24: the byte to be transmitted 
; must be stored here. 
; return value: None. 
; registers affected: r24 
; routines called: None. 
 
usart_transmit: 
sbis UCSRA ,UDRE       ; check if usart is ready to transmit 
rjmp usart_transmit    ; if no check again, else transmit 
out UDR ,r24           ; content of r24 
ret    

; Routine: usart_receive 
; Description: 
; This routine receives a byte of data 
; from usart. 
; parameters: None. 
; return value: the received byte is 
; returned in r24. 
; registers affected: r24 
; routines called: None. 
 
usart_receive: 
sbis UCSRA ,RXC        ; check if usart received byte 
rjmp usart_receive     ; if no check again, else read 
in r24 ,UDR            ; receive byte and place it in 
ret                    ; r24 

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
