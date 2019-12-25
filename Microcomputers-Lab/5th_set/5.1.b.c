/*
 * This program reads a number between 0 and 9 from the usart and turns ON LEDS in PORTB
 * according to that number. Also it sends with usart the message "Read <number>".
 *
 * eg: input --> 5, output --> light the 5 LSB LEDS from PORTB and send "Read 5".
 * if 9 is given as input it sends the message "invalid number" and doesnt affect the LEDS.
 *
 * Author: Ntouros Evangelos
 */

#include <avr/io.h>
void usart_init(void);
void usart_transmit(char);
char usart_receive(void);
void usart_transmit_string(char *);

int main(void)
{
	char number, leds, *message;
	DDRB = 0xff;
	usart_init();
	
	while (1)
	{
		number = usart_receive() - 0x30;	//get the input number
		if ((number >=0) & (number <= 8))
		{
			leds = 0xff;
			leds = leds >> (8 - number);
			PORTB = leds;					//leds ON
			message = "Read ";
			usart_transmit_string(message);
			usart_transmit(number + 0x30);
			usart_transmit(0x0A); //newline
		}
		else
		{
			message = "Invalid number";
			usart_transmit_string(message);
			usart_transmit(0x0A); //newline
		}
	}
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
