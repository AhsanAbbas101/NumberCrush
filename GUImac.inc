

CLEARREGISTERS MACRO
	MOV ax , 0
	MOV bx , 0
	MOV cx , 0
	MOV dx , 0
;	MOV si , 0
;	MOV di , 0

ENDM


DELAY MACRO p1,p2

	; p1 = p2 = WORD

	MOV cx , p1		; microsecond
	MOV dx , p2		; combined

;	MOV cx , 0Fh		; microsecond
;	MOV dx , 4240h		; combined
	
;	MOV cx , 7
;	MOV dx , 0A120h
	
	MOV ah , 86h
	INT 15h

ENDM


CLEARSCREEN MACRO
	
	MOV ah , 0
	MOV al , 13h
	INT 10h

ENDM

DRAWPIXEL MACRO p1 , p2 , p3
	; p1 (BYTE) == color number
	; p2 (WORD) == x-axis
	; p3 (WORD) == y-axis
	
	MOV ah , 0Ch
	MOV al , p1
	MOV cx , p2
	MOV dx , p3
	INT 10h

ENDM

DRAWCHAR MACRO p1,p2,p3
	MOV ah , 09h		; display character at the cursor position
	MOV al , p1			; character to display
	MOV bh , 0h			; page number
	MOV bl , p2			; color
	MOV cx , p3			; number of times to display the character
 	INT 10h
ENDM
	
REPOSITION MACRO p1,p2

	; p1 == row Number
	; p2 == column Number 
	
	MOV ah , 02h		; cursor position
	MOV dh , p1			; row Number
	MOV dl , p2			; column Number
	INT 10h

ENDM
