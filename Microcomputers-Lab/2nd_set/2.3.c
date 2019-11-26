/*
 * Author: Tagarakis Konstantinos 
 */
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#define F_CPU  8000000UL

unsigned char z = 0;
volatile int flag = 0;

ISR(TIMER1_OVF_vect){
	//timer routine
	cli();
	TCCR1B = 0x00;
	PORTB = 0x00;
	flag = 0;
	sei();
}

ISR(INT1_vect){
	//PD3 routine
	cli();
	leds_on();
	sei();
}

void leds_on(){
	//A routine to handle the push of PD3 and PA7
	TCNT1 = 34286;		//initialization of timer1
	TCCR1B = 0x05;		//frequency of timer1 8MHz/1024

	if(!flag){
		PORTB = 0x01;
		flag = 1;
	}
	else{
		PORTB = 0xFF;
		_delay_ms(500);
		PORTB = 0x01;
	}
}

int main(void)
{
	TIMSK = (1<<TOIE1);		//Timer1 ,interrupt enable
	//external interrupt INT1 configuration
	GICR = (1<<INT1);
	MCUCR = (1<<ISC11 | 1<< ISC10);

	DDRB = 0xFF;		//portB as output
	DDRA = 0x00;		//portA as input

	sei();

	while (1){
		//main loop
		z = PINA;		//input in z

		if (z & 0x80){	//if input msb is 1 enter the if statement aka when PA7 is pressed
			while(!(z & 0x80) == 0){z = PINA;}	//stuck here till PA7 is released
			cli();
			leds_on();
			sei();
		}
	}
}
