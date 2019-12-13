//Author: Tagarakis Konstantinos
#define F_CPU 8000000UL
#include <avr/io.h>
#include <util/delay.h>

char one_wire_receive_bit(void); //done

char one_wire_receive_byte(void); //done

void one_wire_transmit_bit(char bit); //done

void one_wire_transmit_byte(char byte); //done

char one_wire_reset(void); //done

char* read_temperature(void);

char format_temperature(char* temp);

void lcd_init();

void lcd_command(char data);

void lcd_data(char data);

void hex_to_dec(char key);

//global variables
char temp[2];
char res[4] ;
static char message[] = { 'N', 'O', ' ', 'D', 'e', 'v', 'i', 'c', 'e'};

int main(void)
{	//char output;
	DDRB = 0xFF; // init PORTB
	DDRD = 0xFF;

	char mytemp;


	while(1)
	{
		lcd_init();
		mytemp = format_temperature(read_temperature());
		PORTB = mytemp;

		if(mytemp == 0x80)
		{

			for(int i = 0; i < 9; i++)
			{
				lcd_data(message[i]);
			}

			do{
				mytemp = format_temperature(read_temperature());
				//wait until something change
			}while(mytemp == 0x80);


		}
		else
		{
			char state, test;

			state = mytemp;
			hex_to_dec(mytemp);

			lcd_data(res[0]);

			if(res[1] != '0')
			{
				lcd_data(res[1]);
				lcd_data(res[2]);
				lcd_data(res[3]);

			}
			else if (res[2] != '0')
			{
				lcd_data(res[2]);
				lcd_data(res[3]);
			}
			else
			{
				lcd_data(res[3]);
			}
			lcd_data('o');
			lcd_data('C');


			do{
				test = format_temperature(read_temperature());
				//wait until something change
			}while(state == test);
		}


	}


}
void hex_to_dec(char key){



	for(int i = 0; i < 4; i++){
		res[i] = 0;
	}

	if ( key >> 7 ){

		res[0] = '-';

		key = ~key + 1;
	}
	else{

		res[0] = '+';

	}

	while(key >= 100){

		key = key - 100;

		res[1] = res[1] + 1;

	}

	res[1] = res[1] + '0';


	while(key >= 10){

		key = key - 10;

		res[2] = res[2] + 1;
	}

	res[2] = res[2] + '0';


	res[3] = res[3] + key;
	res[3] = res[3] + '0';

}

char format_temperature(char* temp)
{
	if(temp[1] == 0x80)
	{
		return temp[1]; // device not found
	}

	if(temp[1] == 0xFF)
	{
		// number is negative
		temp[0] = ~temp[0] + 1; // 2's complement
		temp[0] = temp[0] >> 1; //divide by 2
		temp[0] = ~temp[0] + 1; // 2's complement
		return temp[0];
	}
	else
	{
		//number is positive
		temp[0] = temp[0] >> 1; //divide by 2
		return temp[0];
	}
}
char* read_temperature(void)
{
	char check, bit;
	temp[0] = 0; //cleat array from previous values
	temp[1] = 0; // temp is global array

	check = one_wire_reset();
	if(check == 0)
	{

		temp[0] = 0x00;
		temp[1] = 0x80;
		return temp;
	}

	one_wire_transmit_byte(0xCC);
	one_wire_transmit_byte(0x44);

	do
	{
		bit = one_wire_receive_bit();

	}while(bit == 0);

	check = one_wire_reset();
	if(check == 0)
	{

		temp[0] = 0x00;
		temp[1] = 0x80;
		return temp;
	}

	one_wire_transmit_byte(0xCC);
	one_wire_transmit_byte(0xBE);

	temp[0] = one_wire_receive_byte();
	temp[1] = one_wire_receive_byte();

	return temp;
}

void one_wire_transmit_byte(char byte)
{
	char bit;

	for (int counter = 0; counter <8; counter ++)
	{
		bit  = (byte & 0x01);
		byte = (byte >> 1);
		one_wire_transmit_bit(bit);
	}
}

void one_wire_transmit_bit(char bit)
{
	DDRA  |= (1 << PA4);
	PORTA &= ~(1 << PA4);
	_delay_us(0x02);

	if(bit == 1 )
	{
		PORTA |= (1 << PA4);
	}
	if(bit == 0)
	{
		PORTA &= (0 << PA4);
	}
	_delay_us(58);

	DDRA  &= ~(1 << PA4);
	PORTA &= ~(1 << PA4);
	_delay_us(0x01);
}

char one_wire_receive_byte(void)
{
	char byte = 0, bit = 0;

	for (int counter = 0; counter <8; counter ++)
	{
		bit = one_wire_receive_bit();

		if (bit == 0)
		{
			byte = byte >> 1;

		}
		else
		{
			byte = byte >> 1;
			byte = byte | 0x80;
		}
	}
	return byte;
}

char one_wire_receive_bit(void)
{
	char bit;

	DDRA  |= (1 << PA4);
	PORTA &= ~(1 << PA4);
	_delay_us(0x02);

	DDRA  &= ~(1 << PA4);
	PORTA &= ~(1 << PA4);
	_delay_us(10);

	bit = PINA;
	;
	if (bit == 0b00010000)
	{
		_delay_us(49);
		return 1;
	}
	else
	{
		_delay_us(49);
		return 0;
	}


}
char one_wire_reset(void)
{
	char device_status;

	DDRA  |= (1 << PA4);
	PORTA &= ~(1 << PA4);
	_delay_us(480);

	DDRA &= (0 << PA4);
	PORTA &= (0 << PA4);
	_delay_us(100);

	device_status = PINA;
	_delay_us(380);

	if(device_status == 0b00010000)
	{
		return 0;
	}
	else
	{
		return 1;
	}

}

unsigned char swapNibbles(unsigned char x)
{
	return ( (x & 0x0F)<<4 | (x & 0xF0)>>4 );
}

void write_2_nibbles(char data){
	char temp,Nibble_data ;


	temp = PIND;
	temp = temp & 0x0f;
	Nibble_data = data & 0xf0;
	Nibble_data = temp + Nibble_data;
	PORTD = Nibble_data;

	PORTD |= (1 << PD3);
	PORTD &= (0 << PD3);

	data = swapNibbles(data);
	Nibble_data = data & 0xf0;
	Nibble_data = Nibble_data + temp;
	PORTD = Nibble_data;

	PORTD |= (1 << PD3);
	PORTD &= (0 << PD3);
	return;

}

void lcd_data(char data){
	PORTD |= (1 << PD2);
	write_2_nibbles(data);
	_delay_us(43);
	return;

}

void lcd_command(char data){
	PORTD &= (0 << PD2);
	write_2_nibbles(data);
	_delay_us(39);
	return;

}

void lcd_init(){
	_delay_ms(40);
	for(int i = 1; i<=2; i++){
		PORTD = 0x30;
		PORTD |= (1 << PD3);
		PORTD |= (0 << PD3);

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
