/*
 * This program measures the analog voltage of the potensiometer in EASYAVR6 
 * development board and sends it with usart. 
 *
 * It measures two decimal digits.
 *
 * ADC values are received by polling in ADCSRA.
 * 
 * The main program is a binary counter in the LEDS of PORTB.
 *
 * Author: Ntouros Evangelos
 *
 */ 

#define F_CPU 8000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

void usart_init(void);
void usart_transmit(char);
char usart_receive(void);
void usart_transmit_string(char *);
void ADC_init(void);

unsigned char counter = 0x01;

ISR(TIMER1_OVF_vect)
{
	TCCR1B = 0x00;		//Stop timer
	PORTB = counter;	//update the leds
	counter++;			//update the counter

	TCNT1 = 63974;		//Timer set to overflow in 200 msec
	TCCR1B = 0x05;		//Start the timer again
}

int main(void)
{
	DDRB = 0xff;
	usart_init();
	ADC_init();
	
	TIMSK = (1 << TOIE1);				//Timer1 ,interrupt enable
	TCCR1B = 0x05;						//frequency of Timer1 8MHz/1024
	TCNT1 = 63974;						//Timer set to overflow in 200 msec

	sei();
	
	while (1)
	{
		while ((ADCSRA & (1 << ADSC)) != 0) //stuck here till converion ends (ADSC = 0)
			;
			
		char integer = (ADC*5)/1024 + 0x30;
		char first_decimal = ((ADC*5)%1024*10)/1024 + 0x30;
		char second_decimal = ((((ADC*5)%1024*10)%1024)*10)/1024 + 0x30;
		usart_transmit(integer);
		usart_transmit('.');
		usart_transmit(first_decimal);
		usart_transmit(second_decimal);
		usart_transmit(0x0a);
		
		ADCSRA |= (1<<ADSC);          // Start the next conversion
	}
	
	return 0;
}



void usart_init(void)
{
	UCSRA = 0x00;
	UCSRB = (1 << RXEN)|(1 << TXEN);
	UBRRH = 0x00;
	UBRRL = 51;
	UCSRC = (1 << URSEL)|(3 << UCSZ0);
}

void usart_transmit(char byte_to_transmit)
{
	while ((UCSRA & (1 << UDRE)) == 0)
	;
	UDR = byte_to_transmit;
}

char usart_receive(void)
{
	while ((UCSRA & (1 << RXC)) == 0)
	;
	return UDR;
}

void usart_transmit_string(char *message)
{
	while (*message != 0)
	{
		usart_transmit(*message);
		message++;
	}
}

void ADC_init(void)
{
	ADMUX = 1 << REFS0;
	ADCSRA = (1 << ADEN)|(1 << ADSC)|(0 << ADIE)|(7 << ADPS0);
}
