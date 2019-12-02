;This program implements a stopwatch that counts seconds and minutes from 00:00
;till 59:59. After that it resets. In order to start counting the PB0 has to be
;pressed. When its released it should stop. When PB0 is pressed again it should
;start from the last state. PB7 resets the stopwatch and has higher priority than
;PB0.
;There is also a C implementation which uses a slightly different approach. It
;implements the delay with a timer1.
;Look at file "3.3_C.c"
;
; Author: Ntouros Evangelos

    .include "m16def.inc"
    .org 0x0
    rjmp RESET

RESET:
	.def units=r5
	.def decades=r4
    .def temp=r16				;a temporary multiusage register
    .def seconds=r17			;holds the seconds (hex)
    .def minutes=r18			;holds minutes (hex)
	.def msd_sec=r19			;holds most significant digit of BCD seconds
	.def lsd_sec=r20			;holds least significant digit of BCD seconds
	.def msd_min=r22			;holds most significant digit of BCD minutes
	.def lsd_min=r23			;holds least significant digit of BCD minutes

	clr units
	clr decades
	clr seconds
    clr minutes
	clr msd_min
	clr lsd_min
	clr msd_sec
	clr lsd_sec

    ldi temp,LOW(RAMEND)
    out SPL,temp
    ldi temp,HIGH(RAMEND)
    out SPH,temp				;initialize the stack

	ser temp
	out DDRD,temp				;PORTD for LCD
    clr temp
    out DDRB,temp               ;PINB (B as input)

    rcall lcd_init				;initialize LCD

    ldi msd_min,0
    ldi lsd_min,0
    ldi msd_sec,0
    ldi lsd_sec,0
    rcall display_lcd			;print "00 MIN: 00 SEC"

START:
	sbic PINB,7
	rjmp RESET                  ;if PB7 is pressed RESET

	sbis PINB,0                 ;if PB0 is not pressed STOP
	rjmp STOP

    inc seconds                 ;seconds++

    cpi seconds,60              ;if I ve reached 60 seconds increment minutes
    breq INC_MIN
    rjmp DISPLAY
INC_MIN:
    inc minutes
	cpi minutes,60
	breq RESET
    ldi seconds,0
DISPLAY:
    mov r21,seconds
    rcall hex_to_bcd
    mov msd_sec,decades
    mov lsd_sec,units           ;convert seconds from hex to bcd

    mov r21,minutes
    rcall hex_to_bcd
	mov msd_min,decades
	mov lsd_min,units          ;convert minutes from hex to bcd

/*
 * Below is implemented the 1 sec delay as a 10-times loop with
 * 100msec delay each one. This had to be done in order to be able
 * to control PB0 and PB7 while on the delay. A different implementation
 * would be with a timer. This is implemented in the C version.
*/
	ldi temp,10            ;loop 10 times
DELAY_LOOP:
	sbic PINB,7            ;check for PB7
	rjmp RESET
	sbic PINB,0            ;check for PB0
	rjmp FLAG1
	dec seconds
	rjmp STOP
FLAG1:
	ldi r24,low(100)
    ldi r25,high(100)
	rcall wait_msec
	dec temp
	brne DELAY_LOOP

	rcall display_lcd

	rjmp START

STOP:
	sbic PINB,7            ;check for PB7
	rjmp RESET

    sbis PINB,0            ;check for PB0
    rjmp STOP
    rjmp START

;ROUTINE: diplay_lcd --> display a timer instant on LCD
display_lcd:
    push temp
    in temp,SREG
    push temp

	/*reset*/
	rcall lcd_init

	ldi temp,0x30
	/*make ascii values*/
	add msd_min,temp
	add lsd_min,temp
	add msd_sec,temp
	add lsd_sec,temp

	/*two spaces*/
	ldi r24,0x20
	rcall lcd_data
	ldi r24,0x20
	rcall lcd_data

	/*bcd minutes*/
    mov r24,msd_min
    rcall lcd_data
    mov r24,lsd_min
    rcall lcd_data

	/*space*/
	ldi r24,0x20
	rcall lcd_data

	/*"MIN"*/
    ldi r24,'M'
    rcall lcd_data
    ldi r24,'I'
    rcall lcd_data
    ldi r24,'N'
    rcall lcd_data

	/*":"*/
	ldi r24,0x3a
	rcall lcd_data

	/*bcd seconds*/
    mov r24,msd_sec
	rcall lcd_data
    mov r24,lsd_sec
    rcall lcd_data

	/*space*/
	ldi r24,0x20
	rcall lcd_data

	/*"SEC"*/
    ldi r24,'S'
    rcall lcd_data
    ldi r24,'E'
    rcall lcd_data
    ldi r24,'C'
    rcall lcd_data

    pop temp
    out SREG,temp
    pop temp
    ret

;ROUTINE: hex_to_bcd --> convert a hex number to bcd
hex_to_bcd:
    clr units
	clr decades
CONTINUE_hex_to_bcd:
	clr units

    cpi r21,10
    brge GREATER_10		    ;if number - 10 >= 10 go to increase the decades
LOWER_10:
    mov units,r21	        ;move the remaining number of r21(the units) to units
	rjmp EXIT_hex_to_bcd
GREATER_10:
    inc decades             ;increase decades
    subi r21,10             ;number = number - 10
    rjmp CONTINUE_hex_to_bcd

EXIT_hex_to_bcd:
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
	cbi PORTD ,PD2			;now choose the command register
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

	ldi r24 ,0x30          ;change to 8-bit mode
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec

	ldi r24 ,0x20			;change to 4-bit mode
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec

	ldi r24 ,0x28
	rcall lcd_command      ;5x8

	ldi r24 ,0x0c
	rcall lcd_command      ;LCD ON, hide cursor

	ldi r24 ,0x01
	rcall lcd_command      ;clean LCD

	ldi r24 ,low(1530)
	ldi r25 ,high(1530)
	rcall wait_usec

	ldi r24 ,0x06
	rcall lcd_command      ;auto increment ON, shift OFF

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
