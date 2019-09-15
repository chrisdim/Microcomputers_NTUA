/*
This program has the input in portC and the output in portA.
It starts with the led in the LSB of portA on (PA0 = 1). 
	When I press PC0 this led rotates left by one.
	When I press PC1 the led rotates right by one.
	When I press PC3 the MSB led turns on and every other one off.
	When I press PC4 the LSB led turns on and every other one off.
The signal for one of the above operations is given when i release the push button.

This example is the third exercise of the fourth set from 2019.
*/

#include <avr/io.h>
unsigned char x;
 
int main(void){
	DDRA = 0xff;    //portA output
	DDRC = 0x00;    //portC input 
     
	x = 1;
	while(1){
		if((PINC & 0x01) == 1){
			//first push-button is pushed
			while((PINC & 0x01) == 1){} //wait for push-button release
			if(x == 0x80){	
				x = 0x01;
			}
			else{
				x = x<<1;
			}
		}
		if((PINC & 0x02) == 2){			
			//second push-button is pushed
			while((PINC & 0x02) == 2){} //wait for push-button release
			if(x == 0x01){
				x = 0x80;
			}
			else{
				x = x>>1;
			}
		}
		if((PINC & 0x04) == 4){
			//third push-button is pushed
			while((PINC & 0x04) == 4){} //wait for push-button release
			x = 0x80;
		}
		if((PINC & 0x08) == 8){
			//fourth push-button is pushed
			while((PINC & 0x08) == 8){} //wait for push-button release
			x = 0x01;
		}
		PORTA = x;
	}
	return 0;   
}

