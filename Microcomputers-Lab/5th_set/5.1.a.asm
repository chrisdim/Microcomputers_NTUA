; This program stores a string "Hello\0" in the RAM of the microcontroller and then 
; transmits it with usart.
;
;Author: Ntouros Evangelos

.include "m16def.inc"

;--------DATA SEGMENT-------------
.DSEG
	_string_: .byte 6


;--------CODE SEGMENT-------------
.CSEG
	.org 0x0
	rjmp RESET

RESET:
	.def temp=r16

	ldi temp,LOW(RAMEND)
	out SPL, temp
	ldi temp,HIGH(RAMEND)
	out SPH, temp				;initialize the stack

	/*Initialize the string 'Hello' in the RAM*/
	ldi r26,low(_string_)
	ldi r27,high(_string_)
	ldi temp,'H'
	st X+,temp
	ldi temp,'e'
	st X+,temp
	ldi temp,'l'
	st X+,temp
	ldi temp,'l'
	st X+,temp
	ldi temp,'o'
	st X+,temp
	ldi temp,0
	st X,temp

	/*take the address of the string*/
	ldi r26,low(_string_)
	ldi r27,high(_string_)

	rcall usart_init

START:
	/*transmit the _string_ byte by byte till NUL*/
	ld r24,X+
	rcall usart_transmit
	
	cpi r24,0		;check for NUL
	brne START

	ldi r24,0x0a	;send "\n"
	rcall usart_transmit
	/*when done transmiting stay here and do nothing*/
END_LOOP:
	rjmp END_LOOP


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
 
