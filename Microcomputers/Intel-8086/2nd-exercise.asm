;The user gives as input from the keyboard two 2-digit decimal numbers.
;The program prints them and after that, their sum and sub in 
;hexadecimal format.

;This program is the second exercise of the fifth set from 2019.

INCLUDE MACROS.ASM
    .8086
    .MODEL SMALL
    .STACK 256    
;------DATA SEGMENT------------ 
.DATA
    SPACE DB " $"
    Z_EQUALS DB "Z=$" 
    W_EQUALS DB "W=$" 
    SUMMSG DB "Z+W=$"
    SUBMSG DB "Z-W=$"
    MINUSSUBMSG DB "Z-W=-$"
	NUM1 DW ?
	NUM2 DW ?
	NUM1HEX DB ?
	NUM2HEX DB ?  
	SUMA DB ?
	SUBA DB ?

;------CODE SEGMENT------------	   
.CODE
;----MAIN------------------
MAIN PROC FAR
	MOV AX,@DATA
	MOV DS,AX 
START:		
;FIRST NUMBER
	CALL READ_DEC 
	MOV NUM1,DX  				;NUM1 has the ASCI code of the first number
	CALL INPUT_TO_HEX
	MOV NUM1HEX,DL   			;NUM1HEX has the first number	
;SECOND NUMBER	
	CALL READ_DEC
	MOV NUM2,DX 				;NUM2 has the ASCI code of the second number
	CALL INPUT_TO_HEX
	MOV NUM2HEX,DL 				;NUM1HEX has the second number
	
    NEW_LINE
;PRINT FIRST
    PRINT_STRING Z_EQUALS
    MOV CX,NUM1
    MOV DL,CH
    MOV AH,2 
    INT 21H					 ;print the first digit
    MOV DL,CL
    INT 21H					 ;print the second digit 
     
    PRINT_STRING SPACE
;PRINT SECOND            
    PRINT_STRING Z_EQUALS
    MOV CX,NUM2
    MOV DL,CH
    MOV AH,2
    INT 21H					;print the first digit
    MOV DL,CL
    INT 21H 					;print the second digit

;ADD-SUB
    MOV DH,NUM1HEX
    MOV DL,NUM2HEX
    ADD DH,DL
    MOV SUMA,DH					;SUMA = NUM1HEX + NUM2HEX
    
    MOV DH,NUM1HEX
    CMP DH,DL					
    JL MINUS					
    SUB DH,DL					;if NUM1HEX > NUM2HEX 
    MOV SUBA,DH 				;SUBA = NUM1HEX - NUM2HEX
    JMP PRINT_SUM_AND_POSITIVE_SUB
MINUS:							;if NUM2HEX > NUM1HEX 
    SUB DL,DH					;SUBA = NUM2HEX - NUM1HEX
    MOV SUBA,DL
;print sum and sub when suba is negative 
    NEW_LINE       
    MOV DL,SUMA 
    PRINT_STRING SUMMSG
    CALL PRINT_HEX
     
    MOV DL,SUBA    
    PRINT_STRING SPACE
    PRINT_STRING MINUSSUBMSG
    CALL PRINT_HEX 
    JMP START  

;print sum and sub when suba is positive
PRINT_SUM_AND_POSITIVE_SUB:    
    NEW_LINE       
    MOV DL,SUMA 
    PRINT_STRING SUMMSG
    CALL PRINT_HEX
     
    MOV DL,SUBA    
    PRINT_STRING SPACE
    PRINT_STRING SUBMSG
    CALL PRINT_HEX                            
    
    JMP START                
	EXIT
MAIN ENDP

;----------PROCS----------------
READ_DEC PROC NEAR 
;returns input in dx register
	PUSHF    
NOT_INT_0:	
	READ
	CMP AL,'0'                  ;accept 0 <  < 9
	JL NOT_INT_0
	CMP AL,'9'
	JG NOT_INT_0	
	MOV DH,AL                   ;DH has the ASCII code of the first digit
NOT_INT_1:   	
	READ      
	CMP AL,'0'                  ;accept 0 <  < 9
	JL NOT_INT_1
	CMP AL,'9'
	JG NOT_INT_1	
	MOV DL,AL                   ;DL has the ASCII code of the second digit
    POPF  
    RET
ENDP READ_DEC

INPUT_TO_HEX PROC NEAR 
;takes input number in dx register
;outputs hex in DL
     PUSHF
     SUB DH,30H                 ;DH has the first digit in hex
     SUB DL,30H                 ;DL has the second digit in hex
     MOV BL,10                  
     MOV AL,DH                  
     MUL BL                     ;AL = (first digit) x 10
     ADD AL,DL                  ;AL = (first digit) x 10 + second digit
     MOV DL,AL                  ;DL = (first digit) x 10 + second digit
     POPF
     RET
ENDP INPUT_TO_HEX   

PRINT_HEX PROC NEAR
;prints hex number in dx 
;eg print 35H
;FIRST DIGIT
    MOV BH,DL 
    AND BH,0F0H                 ;isolate first digit's bits (35-->30)
    ROR BH,4                    ;rotate 4 times right (30-->3)
    
    CMP BH,9                    
    JG ADDR1
    ADD BH,30H                  ;if digit < 9 make ASCII by adding 30H (33H)
    JMP ADDR2
ADDR1:
    ADD BH,37H                  ;if digit > 9 make ASCII by adding 37H
ADDR2:
    PRINT BH                    ;print first digit (3: ASCII 33)
;SECOND DIGIT   
    MOV BH,DL                   
    AND BH,0FH                  ;isolate second digit's bits (35-->50)
    CMP BH,9
    JG ADDR3
    ADD BH,30H                  ;if digit < 9 make ASCII by adding 30H (35H)
    JMP ADDR4
ADDR3:
    ADD BH,37H                  ;if digit > 9 make ASCII by adding 37H
ADDR4:
    PRINT BH                    ;print second digit (5: ASCII 35)
    RET   
ENDP PRINT_HEX	
