;This program stores numbers 128 ... 0 in continuous memory places starting at
;memory TABLE.
;Then it finds and prints the average of the odd numbers between 0 and 128 and
;the maximum and minumum of numbers 0 ... 128.

;This program is the first exercise of the fifth set from 2019.

INCLUDE MACROS.ASM 
    .8086
    .MODEL SMALL
    .STACK 256
;------DATA SEGMENT------------ 
    .DATA                          
    HEADER DB "Exercise 1$"
    STORING DB "Storing...$" 
    TABLE DB 128 DUP(?) 
    MIN db ?
    MAX db ?

;------CODE SEGMENT------------
    .CODE 
    ;----MAIN------------------
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
        
    PRINT_STRING HEADER 
    NEW_LINE
        
    MOV AL,128				;first number to be stored
    MOV DI,0   				;initialize index
STORE_ARRAY:            
    MOV [TABLE + DI],AL     		;store numbers in TABLE[128]   
    DEC AL				;next number to be stored
    INC DI				;i++
    CMP AL,0 				;if all number are stored exit the loop		
    JNE STORE_ARRAY
    
	MOV DI,1
    MOV AH,0     
CONTINUE_ADD: 
    MOV AL,[TABLE + DI] 		;load number
    ADD DX,AX 				;add number
    ADD DI,2				;load only odd numbers  
    CMP DI,129
    JL CONTINUE_ADD       	        ;if di gets > 127 exit
    
    MOV AX,DX
    MOV BH,0
    MOV BL,64
    DIV BL				;divide sum with 64 to find average
    
    MOV AH,0   				;Is needed for procedure 'PRINT_DEC'     
    CALL PRINT_DEC
    NEW_LINE   
    
    MOV DI,0xFFFF
    MOV MIN,0xFF
    mov MAX,0
FIND_MIN_MAX: 
;if MIN < current number then current number isn't the MIN
;but it may be the MAX
    INC DI
    MOV AL,[TABLE + DI]
    CMP MIN,AL				
    JNA SKIP
    MOV MIN,AL				;if current number < MIN --> MIN = current number
    JMP MIN_MAX_FOUND     
SKIP:
    CMP MAX,AL
    JA FIND_MIN_MAX
    MOV MAX,AL				;if current number > MAX --> MAX = current number
    CMP DI,128    
    JNE FIND_MIN_MAX 
 
MIN_MAX_FOUND: 
;when MIN and MAX are found print them
    MOV AH,0
    MOV AL,MIN
    CALL PRINT_DEC 
    NEW_LINE
    MOV AH,0
    MOV AL,MAX
    CALL PRINT_DEC 
    NEW_LINE   
          
ENDP
EXIT

;----------PROC----------------
PRINT_DEC proc NEAR
;input: number in BL 
;output: print the decimal number
    MOV BL,10 
    MOV CX,1 				;decades counter
LOOP_10: 
    DIV BL				;divide number with 10
    PUSH AX                		;save units  
    CMP AL,0 				;if quotient zero I have splitted 
    JE PRINT_DIGITS_10      		;the whole number into dec digits          
    INC CX				;increase number of decades
    MOV AH,0   
    JMP LOOP_10				;if quotient is not zero I have to divide again
PRINT_DIGITS_10:
    POP DX				;pop dec digit to be printed
    MOV DL,DH
    MOV DH,0				;DX = 00000000xxxxxxxx (ASCII of number to be printed)
    ADD DX,30H				;make ASCII code
    MOV AH,2
    INT 21H				;print
    LOOP PRINT_DIGITS_10       
    RET
ENDP PRINT_DEC      
