// C implementation of stopwatch problem.

// Author: Ntouros Evangelos

#define F_CPU 8000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

/*
 * A structure to represent the two digits of a BCD number
 */
struct bcd_number {
	unsigned char msd;		//most significant digit of the BCD number
	unsigned char lsd;		//most significant digit of the BCD number
};

unsigned char seconds, minutes;

unsigned char swapnibbles(unsigned char);
void write_2_nibbles(unsigned char);
void lcd_data(unsigned char);
void lcd_command(unsigned char);
void lcd_init(void);
struct bcd_number hex_to_bcd(unsigned char);
void lcd_display(unsigned char, unsigned char, unsigned char, unsigned char);

/*
 *  Timer1 overflow ISR
 */
ISR(TIMER1_OVF_vect)
{
	TCCR1B = 0x00;		//Stop timer

	seconds++;			//increment seconds

    /*Check for 59 seconds or/and 59 minutes*/
	if (seconds == 60)
	{
		if (minutes == 59)
		{
			minutes = 0;
			seconds = 0;
		}
		else
		{
			minutes++;
			seconds = 0;
		}
	}

	TCNT1 = 57724;		//Timer set to overflow in 1 second
	TCCR1B = 0x05;		//Start the timer again
}

int main(void)
{
	TIMSK = (1 << TOIE1);				//Timer1 ,interrupt enable
	TCCR1B = 0x05;						//frequency of Timer1 8MHz/1024
	sei();

	struct bcd_number sec, min;        //bcd values

	seconds = minutes = 0;             //hex values

	DDRD = 0xFF;						//Output
	DDRB = 0X00;						//Input

	TCNT1 = 57724;						//Timer set to overflow in 1 second (0d57724)

    /*Hard code here the initial value of the stopwatch*/
    seconds = 0;
	minutes = 0;
	while(1)
	{
		lcd_init();

		if ((PINB & 0X01) == 0X00)       //if PB0 == 0
		{
			TCCR1B = 0x00;				//stop timer
		}
		else
		{
			TCCR1B = 0x05;				//start timer
		}

		if ((PINB & 0X80) == 0x80)		//if PB7 is pressed RESET
		{
			seconds = 0;
			minutes = 0;
		}

		min = hex_to_bcd(minutes);
		sec = hex_to_bcd(seconds);

		lcd_display(min.msd, min.lsd, sec.msd, sec.lsd);
	}

	return 0;
}

/*A function to convert an 8 bit hex number to a bcd*/
struct bcd_number hex_to_bcd(unsigned char number)
{
	struct bcd_number bcd = {.msd = 0, .lsd = 0};

	while (number >= 10)
	{
		number -= 10;
		bcd.msd++;
	}
	bcd.lsd = number;

	return bcd;
}

/*
 * A function to print in the LCD formatted messages:
 *             XX MIN:YY SEC
 */
void lcd_display(unsigned char msd_min, unsigned char lsd_min, unsigned char msd_sec, unsigned char lsd_sec)
{
	msd_min += 0x30;
	lsd_min += 0x30;
	msd_sec += 0x30;
	lsd_sec += 0x30;

	lcd_data(0x20);
	lcd_data(0x20);

	lcd_data(msd_min);
	lcd_data(lsd_min);

	lcd_data(0x20);

	lcd_data('M');
	lcd_data('I');
	lcd_data('N');

	lcd_data(0x3a);

	lcd_data(msd_sec);
	lcd_data(lsd_sec);

	lcd_data(0x20);

	lcd_data('S');
	lcd_data('E');
	lcd_data('C');

	lcd_data(0x20);
	lcd_data(0x20);
}

/*A function to swap the nibbles of a 8 bit number*/
unsigned char swapNibbles(unsigned char x)
{
    return ((x & 0x0F)<<4 | (x & 0xF0)>>4);
}

/*
 *	2x16 LCD driver for EASYAVR6
 *  For explanation look at the commented in the assembly
 *  assembly code implementation of the program.
 */
void write_2_nibbles(unsigned char data)
{
	unsigned char temp, nibble_data;

	temp = PIND;
	temp = temp & 0x0f;
	nibble_data = data & 0xf0;
	nibble_data = temp + nibble_data;
	PORTD = nibble_data;

	PORTD |= (1 << PD3);
	PORTD &= (0 << PD3);

	data = swapNibbles(data);
	nibble_data = data & 0xf0;
	nibble_data = nibble_data + temp;
	PORTD = nibble_data;

	PORTD |= (1 << PD3);
	PORTD &= (0 << PD3);
}

void lcd_data(unsigned char data)
{
	PORTD |= (1 << PD2);
	write_2_nibbles(data);
	_delay_us(43);
}

void lcd_command(unsigned char data)
{
	PORTD &= (0 << PD2);
	write_2_nibbles(data);
	_delay_us(39);
}

void lcd_init(void)
{
	_delay_ms(40);
	for(int i = 1; i<=2; i++)
	{
		PORTD = 0x30;
		PORTD |= (1 << PD3);
		PORTD &= (0 << PD3);

		_delay_us(39);
	}

	PORTD = 0x20;
	PORTD |= (1 << PD3);
	PORTD &= (0 << PD3);

	_delay_us(39);

	lcd_command(0x28);
	lcd_command(0x0C);
	lcd_command(0x01);

	_delay_us(1530);

	lcd_command(0x06);

	return;
}
