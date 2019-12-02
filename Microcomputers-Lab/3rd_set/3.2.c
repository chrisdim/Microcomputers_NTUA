/*
 * Author: Tagarakis Konstantinos
 */
#define F_CPU 8000000UL
#define DE_BOUNCE_TIME 20
#include <avr/io.h>
#include <util/delay.h>


short int  _temp_ = 0;
char ascii[] = {'E', '0', 'F', 'D', '7', '8', '9', 'C', '4', '5', '6', 'B', '1', '2', '3', 'A' };
char res[3] ;
void keypad_init(void){

	DDRC = (1 << PC7)|(1 << PC6)|(1 << PC5)|(1 << PC4); /* 4 msb out 4 lsb in 4*4*/
}

unsigned char scan_row(short int row) {
	unsigned char z = 8;
	
	PORTC = (z << row);	//find and activate the line
	asm("NOP");
	asm("NOP");
	z = PINC ; // read the line
	z = z & 0x0f;
	return z;
	
}

unsigned char swapNibbles(unsigned char x)
{
	return ( (x & 0x0F)<<4 | (x & 0xF0)>>4 );
}

unsigned short int scan_keypad (void)

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

unsigned short int scan_keypad_rising_edge (short int de_bounce_time){
	unsigned short int keypad, keypad_2, prev;

	keypad = scan_keypad();
	_delay_ms(DE_BOUNCE_TIME);

	keypad_2 =  (scan_keypad());
	keypad_2 = keypad_2 & keypad;

	prev = _temp_;

	_temp_ = keypad_2;

	prev = ~prev;


	return keypad_2 & prev;




}

char keypad_to_ascii(unsigned short int key){
	if (key == 0)
	return 0;


	int i = -1;
	while (key != 0){
		key = (key >> 1);
		i = i + 1;
	}
	return ascii[i];
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
char* hex_dec_char(char key){
	
	for(int i = 0; i<=2; i++){
		res[i] = 0;
	}

	while(key >= 100){
		key = key - 100;
		res[0] = res[0] + 1;
	}
	res[0] = res[0] + '0';
	
	while(key >= 10){
		key = key - 10;
		res[1] = res[1] + 1;
	}
	res[1] = res[1] + '0';    //gia na ginei ascii
	
	
	res[2] = res[2] + key;
	res[2] = res[2] + '0';

	return res;
}
int main(void){
	
	char key1,key2, char_hex;
	int ikey1, ikey2;
	char* res;

	DDRB = 0xFF;
	DDRD = 0xFF;

	keypad_init();
	lcd_init();

	while(1){
		/*.................................................................................................
		....read first digit as char   ex:'5' == 0x35
		....convert it to integer  ex before '5' convert after 5
		....shift 5 --> 50
		....read second digit as char ex 'A' == 0x41
		....convert it to integer  ex before 'A' convert after A hex
		....input = 50 + 0A = 5A
		....convert 5A to dec
		....display it
		.................................................................................................*/
		// read first digit
		do{
			key1 = keypad_to_ascii(scan_keypad_rising_edge(20));

			
		}while (key1 == 0);
		// convert it to integer
		if(key1 >= 'A'){
			
			ikey1 = key1 - 'A' + 10;
			
			}else{
			
			ikey1 = key1 - '0';

		}
		ikey1 = ikey1 << 4;
		// read second digit
		do{
			
			key2 = keypad_to_ascii(scan_keypad_rising_edge(20));
			
		}while (key2 == 0);

		// convert it to integer
		if(key2 >= 'A'){
			
			ikey2 = key2 - 'A' + 10;
			
		}
		else{
			
			ikey2 = key2 - '0';
		}

		// create input	ex: 50 + 0A = 5A
		char_hex = ikey1+ikey2; // input: char_hex = key1key2
		
		lcd_init();

		lcd_data(key1);
		lcd_data(key2);
		lcd_data('=');
		
		signed char temp = char_hex;
		// check if the number is negative or positive
		if ( temp < 0 ){
			
			lcd_data('-');
			
			char_hex = ~char_hex + 1; //2's complement
		}
		else{

			lcd_data('+');

		}
		//hex_dec_char takes as input a hex and returns an array with res[0] = hundreds, res[1] = Tens, res[0] = Units
		res = hex_dec_char(char_hex);
		
		
		lcd_data(res[0]);
		lcd_data(res[1]);
		lcd_data(res[2]);




		
	}
}
