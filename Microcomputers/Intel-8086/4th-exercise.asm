;This program waits from the user 20 character from the keyboard and then prints
;them, as following:
;	prints 0 ... 9 as they are
;	prints a to z in uppercases 
;	avoids all other characters.
;eg input: jhgf.!111
;  output: JHGF111	

;This program is the fourth exercise of the fifth set from 2019.

INCLUDE MACROS.ASM
    .8086
    .MODEL SMALL
    .STACK 256    
;------DATA SEGMENT------------
.DATA
    TABLE DB 20 DUP(?)

;------CODE SEGMENT------------    	   
.CODE
;----MAIN------------------
MAIN PROC FAR
	 MOV AX,@DATA
	 MOV DS,AX 
START:  
     NEW_LINE          
     MOV DI,0  
     MOV CX,0 
LOOP_READ:   
     READ_WITHOUT_PRINT         
     CMP AL,'='                 ;if '=' quit
     JE QUIT                    
     CMP AL,13                  ;if 'enter' start printing 
     JE CONVERT
     CMP AL,'0'                 ;accept if 0 < < 9 or a < < z
     JL LOOP_READ
     CMP AL,'9'
     JNA ACCEPTED
     CMP AL,'a'
     JL LOOP_READ
     CMP AL,'z' 
     JG LOOP_READ
ACCEPTED:     
     MOV [TABLE + DI],AL
     INC DI
     INC CL
     CMP CL,20                  ;if 20 characters are given start printing
     JZ CONVERT
     JMP LOOP_READ    
      
CONVERT:
     MOV DI,0
LOOP_CONVERT:
     MOV AL,[TABLE + DI]        
     CMP AL,'9'                 ;if > 9 that means I have character from
     JG PRINT_HEX_CHAR          ;a to z so subtract 32 from ASCII code to 
                                ;make upper case
PRINT_HEX_NUM:
     PRINT AL
     JMP NEXT 
     
PRINT_HEX_CHAR:
     CMP AL,13
     JZ NEXT                    ;dont print 'enter'
     SUB AL,32   
     PRINT AL
     
NEXT:          
     INC DI 
     INC CH   
     CMP CH,CL
     JG START 
     JMP LOOP_CONVERT      
           
     JMP START
QUIT:
    EXIT     
MAIN ENDP
