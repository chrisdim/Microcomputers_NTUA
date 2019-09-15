/*
This program has the input in portA and the output in portB.
It implements the bellow logical expression.
	f0 = not((a and b and c) or (not c and d))
	f1 = (a or b) and (c or d)
Where a is the LSB of the input, b the second bit of input and so on,
f0 is the LSB of the output and f0 the second bit.

This example is the second exercise of the fourth set from 2019.
*/

#include <avr/io.h>
unsigned char a, b, c, notc, d, f0, f1;

int main(void){
	DDRB = 0xff;	//portB output
	DDRA = 0x00;	//portA input 
	
	while(1){
		a = PINA & 0x01;
		b = PINA & 0x02;
		b = b>>1;
		c = PINA & 0x04;
		c = c>>2;
		d = PINA & 0x08;
		d = d>>3;


		f1 = (a | b) & (c | d);
		f1 = f1<<1;		

		notc = c^0x01;	//complementary in bits is achieved with XOR		

		f0 = ((a & b & c) | (notc & d));
		f0 = f0^0x1;
		
		f0 = f0 + f1;
		PORTB = f0;
	}

	return 0;	
}
