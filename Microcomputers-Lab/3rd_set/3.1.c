/* C version of the electronic lock problem.
 *!!WARNING!!
 * The use of volatile may not be necessary. It has to be checked more.
 * 
 * Author: Ntouros Evangelos
 */
#define F_CPU 8000000UL //needs to be defined before including the avr/delay.h library
#define SPARK_DELAY_TIME 20
#define FIRST_DIGIT 0x31
#define SECOND_DIGIT 0x32

#include <avr/io.h>
#include <util/delay.h>

unsigned char scan_row(int);
unsigned int scan_keypad(void);
unsigned int scan_keypad_rising_edge(void);
unsigned char keypad_to_ascii(unsigned int);
void initialize_ascii(void);
unsigned char read4x4(void);

unsigned int previous_keypad_state = 0;
int ascii[16];

int main(void)
{
	int i;
	volatile unsigned char first_number, second_number;

	DDRB = 0Xff;
	DDRC = 0xf0;

	initialize_ascii();

    while (1)
    {
		do
		{
			first_number = read4x4();
		}
		while(!first_number);

		do
		{
			second_number = read4x4();
		}
		while(!second_number);

		if ((first_number == FIRST_DIGIT) & (second_number == SECOND_DIGIT))
		{
			PORTB = 0Xff;
			_delay_ms(4000);
			PORTB = 0X00;
		}
		else
		{
			for (i=0; i<8; i++)
			{
				PORTB = 0Xff;
				_delay_ms(250);
				PORTB = 0X00;
				_delay_ms(250);
			}
		}
	}

	return 0;
}

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
	ascii[0] = '*';
	ascii[1] = '0';
	ascii[2] = '#';
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
