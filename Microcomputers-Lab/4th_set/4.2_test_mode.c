/*
 * A program to simulate DS1820 temperature sensor.
 *
 * Give 2-byte values (from 4x4 keypad), as the sensor would have sent (see manual),
 * to check extreme temperatures, say ff92 that should show -55 oC in the LCD.
 *
 * Author: Ntouros Evangelos
 */

#define F_CPU 8000000UL
#include <avr/io.h>
#include <util/delay.h>

/*LCD driver*/
void write_2_nibbles(unsigned char);
void lcd_data(unsigned char);
void lcd_command(unsigned char);
void lcd_init(void);

/*keypad driver*/
#define SPARK_DELAY_TIME 20
unsigned int previous_keypad_state = 0;
int ascii[16];
unsigned char scan_row(int);
unsigned int scan_keypad(void);
unsigned int scan_keypad_rising_edge(void);
unsigned char keypad_to_ascii(unsigned int);
void initialize_ascii(void);
unsigned char read4x4(void);

/*functions*/
struct bcd_number hex_to_3bcd(unsigned char);
void lcd_display(struct bcd_number);
unsigned char swapnibbles(unsigned char);
void print_no_device(void);

/*
 * A structure to represent the two digits of a BCD number
 */
struct bcd_number {
	unsigned char sign;
	unsigned char first_digit;
	unsigned char second_digit;
	unsigned char third_digit;
};
char point5 = 0;		//flag for .5. when it is 1 means that we have a number with .5, say 25.5 oC

int main(void)
{
	DDRD = 0xFF;				//for LCD
	DDRC = 0xf0;				//for 4x4 keypad
	initialize_ascii();
	lcd_init();

	unsigned char first_key, second_key, third_key, fourth_key;
	unsigned char hex_temperature;
	struct bcd_number temperature;

    while (1)
    {
		/*read the four keys*/
		do
		{
			first_key = read4x4();
		}
		while(!first_key);

		do
		{
			second_key = read4x4();
		}
		while(!second_key);

		do
		{
			third_key = read4x4();
		}
		while(!third_key);

		do
		{
			fourth_key = read4x4();
		}
		while(!fourth_key);

		/*convert asciis to numbers*/
		if (first_key > 0x40)     //in case key = A,B,C,D,E or F
		first_key -= 55;
		else
		first_key -= 0x30;        //in case key = 0,1,... or 9

		if (third_key > 0x40)
			third_key -= 55;
		else
			third_key -= 0x30;

		if (fourth_key > 0x40)
			fourth_key -= 55;
		else
			fourth_key -= 0x30;


		first_key = first_key << 4;
		third_key = third_key << 4;

		if ((first_key & 0x80) == 0x80)                   //check for negative/positive
		{
			if ((first_key & 0x40) == 0x40)              //check for negative/no device
			{
                //negative
				hex_temperature = third_key + fourth_key;
				hex_temperature = ~hex_temperature + 1;
                hex_temperature = hex_temperature/2;

                /*check for .5 oC*/
				if (!hex_temperature%2)
					point5 = 1;
				else
					point5 = 0;

				temperature = hex_to_3bcd(hex_temperature);
				temperature.sign = '-';
				lcd_display(temperature);
			}
			else
                //no device
				print_no_device();
		}
		else
		{
            //positive
			hex_temperature = third_key + fourth_key;
            hex_temperature = hex_temperature/2;
			if (!hex_temperature%2)
				point5 = 1;
			else
				point5 = 0;
			temperature = hex_to_3bcd(hex_temperature);
			temperature.sign = '+';
			lcd_display(temperature);
		}
    }

	return 0;
}

/*---------------------------DRIVERS AND FUNCTIONS-----------------------------*/

void lcd_display(struct bcd_number temperature)
{
	lcd_init();

	temperature.first_digit += 0x30;
	temperature.second_digit += 0x30;
	temperature.third_digit += 0x30;

	lcd_data(temperature.sign);
	if (temperature.first_digit != '0')
		lcd_data(temperature.first_digit);
	if (temperature.second_digit != '0')
		lcd_data(temperature.second_digit);
	lcd_data(temperature.third_digit);
    /*.5 oC*/
	if (point5)
	{
		lcd_data('.');
		lcd_data('5');
	}

	lcd_data(0xb2);    //degree symbol
	lcd_data('C');
}

void print_no_device(void)
{
	lcd_init();

	lcd_data('N');
	lcd_data('o');
	lcd_data(' ');
	lcd_data('d');
	lcd_data('e');
	lcd_data('v');
	lcd_data('i');
	lcd_data('c');
	lcd_data('e');
}

/*A function to convert an 8 bit hex number to a bcd*/
struct bcd_number hex_to_3bcd(unsigned char number)
{
	struct bcd_number bcd = {.sign = '*', .first_digit = 0, .second_digit = 0, .third_digit = 0};

	while (number >= 100)
	{
		number -= 100;
		bcd.first_digit++;
	}

	while (number >= 10)
	{
		number -= 10;
		bcd.second_digit++;
	}
	bcd.third_digit = number;

	return bcd;
}

/*A function to swap the nibbles of an 8 bit number*/
unsigned char swapNibbles(unsigned char x)
{
	return ((x & 0x0F)<<4 | (x & 0xF0)>>4);
}

/*
 *	2x16 LCD driver for EASYAVR6
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

/*
 * A driver for reading the 4x4 keypad, slightly modified to read
 * F instead of # and E instead of *.
 * !!! Be careful. You should subtract 0x40 from A,B,C,D,E,F to get the actual number !!!
 */

unsigned char read4x4(void)
{
	unsigned int keypad_state;
	unsigned char ascii_code;

	keypad_state = scan_keypad_rising_edge();
	if (!keypad_state)
	{
		return 0;
	}
	ascii_code = keypad_to_ascii(keypad_state);

	return ascii_code;
}

unsigned char scan_row(int row)
{
	unsigned char temp;
	volatile unsigned char pressed_row;

	temp = 0x08;
	PORTC = temp << row;
	asm("nop");
	asm("nop");
	pressed_row = PINC & 0x0f;

	return pressed_row;
}

unsigned int scan_keypad(void)
{
	volatile unsigned char pressed_row1, pressed_row2, pressed_row3, pressed_row4;
	volatile unsigned int pressed_keypad = 0x0000;

	pressed_row1 = scan_row(1);
	pressed_row2 = scan_row(2);
	pressed_row3 = scan_row(3);
	pressed_row4 = scan_row(4);

	pressed_keypad = (pressed_row1 << 12 | pressed_row2 << 8) | (pressed_row3 << 4) | (pressed_row4);

	return pressed_keypad;
}

unsigned int scan_keypad_rising_edge(void)
{
	unsigned int pressed_keypad1, pressed_keypad2, current_keypad_state, final_keypad_state;

	pressed_keypad1 = scan_keypad();
	_delay_ms(SPARK_DELAY_TIME);
	pressed_keypad2 = scan_keypad();
	current_keypad_state = pressed_keypad1 & pressed_keypad2;
	final_keypad_state = current_keypad_state & (~ previous_keypad_state);
	previous_keypad_state = current_keypad_state;

	return final_keypad_state;
}

unsigned char keypad_to_ascii(unsigned int final_keypad_state)
{
	volatile int j;
	volatile unsigned int temp;

	for (j=0; j<16; j++)
	{
		temp = 0x01;
		temp = temp << j;
		if (final_keypad_state & temp)
		{
			return ascii[j];
		}
	}
	//should not reach here
	return 1;
}

void initialize_ascii(void)
{
	ascii[0] = 'E';
	ascii[1] = '0';
	ascii[2] = 'F';
	ascii[3] = 'D';
	ascii[4] = '7';
	ascii[5] = '8';
	ascii[6] = '9';
	ascii[7] = 'C';
	ascii[8] = '4';
	ascii[9] = '5';
	ascii[10] = '6';
	ascii[11] = 'B';
	ascii[12] = '1';
	ascii[13] = '2';
	ascii[14] = '3';
	ascii[15] = 'A';
}
