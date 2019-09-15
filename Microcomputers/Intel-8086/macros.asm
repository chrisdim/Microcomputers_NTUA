;######################################
READ MACRO
    MOV AH,01
    INT 21H
ENDM
;######################################
PRINT MACRO CHAR
    PUSH AX
    PUSH DX
    MOV DL,CHAR
    MOV AH,2
    INT 21H
    POP DX
    POP AX
ENDM
;######################################
PRINT_STRING MACRO STRING
    PUSH AX
    PUSH DX
    MOV DX,OFFSET STRING
    MOV AH,9
    INT 21H
    POP DX
    POP AX
ENDM
;######################################
EXIT MACRO
	MOV AX,4C00H
	INT 21H
ENDM
;######################################
NEW_LINE MACRO
	PUSH DX
	PUSH AX
	MOV DX,13
	MOV AH,2
	INT 21H  
	MOV DX,10
	MOV AH,2
	INT 21H
	POP AX
	POP DX
ENDM
;######################################
READ_WITHOUT_PRINT MACRO
    MOV AH,08
    INT 21H
ENDM
;######################################

