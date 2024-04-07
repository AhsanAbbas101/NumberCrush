include GUImac.inc
.model small
.stack 100h

.data

; Auxiliary row col variables to store rowNumber & colNumber respectively
row BYTE ?
col BYTE ?

row_h WORD ?
col_h WORD ?
row_h1 WORD ?
col_h1 WORD ?

x WORD 120
y WORD 0
temp word 1
x1 WORD ?
y1 WORD ?

repeatCrushing BYTE 0

moves WORD 20
score WORD 0

array db 100 DUP(0)

gameString BYTE "NUMBER CRUSH GAME","$"
inputString BYTE "ENTER NAME: ","$"
devNameString BYTE "Ahsan Abbas","$"

nameStr BYTE "PLAYER NAME:","$"
nameString BYTE 9 DUP(?),"$"

movesStr BYTE "MOVES:","$"
scoreStr BYTE "SCORE:","$"
 
endStr BYTE "YOU RAN OUT OF MOVES!","$"
yourScore BYTE "YOUR SCORE : ","$"
 
seed WORD 0
range WORD 0
 
.code


MAIN PROC
	
	; give ds data stack address
	MOV ax , @data
	MOV ds , ax

	;------------------------------------------------------------
	;	Draw welcome screen
	;	intialize game array
	;	check for possible combinations
	;------------------------------------------------------------
	initiate:

		; Open Graphics mode 12h ( 640X480X16 )
		MOV ah , 0
		MOV al , 12h
		INT 10h
		
		;-------------------------------------------------------
		
		; draw "NUMBER CRUSH GAME"
		REPOSITION 5 , 32
		MOV si , OFFSET gameString
		CALL DRAWSTRING
		
		; draw "ENTER NAME: "
		REPOSITION 13 , 20
		MOV si , OFFSET inputString
		CALL DRAWSTRING

		; draw "Ahsan Abbas"
		REPOSITION 28 , 1
		MOV si , OFFSET devNameString
		CALL DRAWSTRING

		; input user string ( max 8 chars )
		REPOSITION 13 , 34
		MOV si , OFFSET nameString
		CALL INPUTNAME
		
		;----------------------------------------------------
		
		; Array initialize
		MOV bx , OFFSET array
		PUSH bx
		MOV ax , 100
		PUSH ax
		CALL INTIALIZEARRAY
		
		CALL PERFORM_CRUSHING

		;----------------------------------------------------
		
		; Refresh Screen
		MOV ah , 0
		MOV al , 12h
		INT 10h

		CALL DISPLAYBOARD
		CLEARREGISTERS

	;------------------------------------------------------------
	;	Draw array elements
	;	Take mouse inputs and check for adjacent cells
	;	Check for possible combinations
	;	Maintain moves and score 
	;	Repeat till game ends
	;------------------------------------------------------------
		MOV score , 0
	process:

		CALL DISPLAYARRAY
		
		CLEARREGISTERS
		
		; display mouse pointer
		MOV ax , 01
		INT 33H

		;---------------------------------------------------------
				
		;	get mouse input
		mouse_input:
			
			MOV bx,0
			Loop_mouse_input:
			
				MOV ax,03
				INT 33h
				
				CMP bx,0
				JE Loop_mouse_input
			
		; coordinates stored in cx,dx
		MOV x , cx
		MOV y , dx

		; Check boundries of x_axis 
		; y_axis already occupies all area so no need to check its Boundries
		CMP x,120
		JBE mouse_input
		CMP x,520
		jAE mouse_input
		
		; to convert pixels to cell row & colNumber
		PUSH x
		PUSH y
		CALL PIXELTOCELL
		POP row_h
		POP col_h
		
		;-------------------------------------------------------------------
		
		;	get second mouse input
		mouse_input_second:
			
			MOV bx,1

			Loop_mouse_input_second:
			
				MOV ax,03
				INT 33h
				
				CMP bx,0
				JNE Loop_mouse_input_second
				
		; coordinates stored in cx,dx
		MOV x1 , cx
		MOV y1 , dx
		
		
		; Check boundries of x_axis 
		; y_axis already occupies all area so no need to check its Boundries
		CMP x1,120
		JBE process
		CMP x1,520
		JAE process

		; to convert pixels to cell row & colNumber
		PUSH x1
		PUSH y1
		CALL PIXELTOCELL
		POP row_h1
		POP col_h1
		
		;------------------------------------------------------------------
		; check for adjecent cells
		MOV ax , row_h
		CMP ax , row_h1
		JE checkCol
		
		MOV ax , col_h
		CMP ax , col_h1
		JE checkRow
		
		JMP process
		
			checkCol:

				MOV ax , col_h
				CMP ax , col_h1
				JA decrementCol
				JB incrementCol
				
				JMP process
			
			decrementCol:
				
				DEC ax
				CMP ax , col_h1
				JNE process
				
				JMP do_swaping
				
			incrementCol:

				INC ax 
				CMP ax , col_h1
				JNE process
				
				JMP do_swaping
				
			checkRow:

				MOV ax , row_h
				CMP ax , row_h1
				JA decrementRow
				JB incrementRow
				
				JMP process
				
				
			decrementRow:
				
				DEC ax
				CMP ax , row_h1
				JNE process
				
				JMP do_swaping
				
			incrementRow:

				INC ax 
				CMP ax , row_h1
				JNE process
				
				JMP do_swaping

		;------------------------------------------------------------------		
		do_swaping:	
			; swaping
			CLEARREGISTERS
			
			; convert si & di to indexing array
			MOV dx , 0
			MOV ax , row_h
			MOV bx , 10		; number of columns
			MUL bx
			ADD ax , col_h
			
			MOV si , ax			; index 1
			
			MOV dx , 0
			MOV ax , row_h1
			MOV bx , 10		; number of columns
			MUL bx
			ADD ax , col_h1
			
			MOV di , ax			; index 2
			
			; if blocker , donot swap
			CMP array[si] , 'X'
			JE process
			
			CMP array[di] , 'X'
			JE process
			
			; swap
			MOV ax , 0
			MOV dx , 0
			MOV al , array[si]
			MOV dl , array[di]
			MOV array[si] , dl
			MOV array[di] , al
			
			DEC moves
			
			CMP array[si] , 'B'		; BOMB
			JE si_true

			CMP array[di] , 'B'		; BOMB
			JE di_true
			
			JMP crushing
			si_true:

				
				MOV ah , 0
				MOV al , array[di]
				
				PUSH ax					
				CALL DESTROYNUMBER
				
				MOV array[si] , 'C'
				
				CLEARREGISTERS
				CALL DISPLAYARRAY		
				DELAY 07h, 0A120h
				CLEARREGISTERS

				CALL DROPPING_RANDOM_NUMBERS
				
				JMP crushing
				
			di_true:

				MOV ah , 0
				MOV al , array[si]
				
				PUSH ax
				CALL DESTROYNUMBER
				
				MOV array[di] , 'C'
				
				CLEARREGISTERS
				CALL DISPLAYARRAY		
				DELAY 07h, 0A120h
				CLEARREGISTERS
				CALL DROPPING_RANDOM_NUMBERS
				
				JMP crushing

		;--------------------------------------------------------
	
		crushing:
		
			CLEARREGISTERS
			
		; // do crushing		
			CALL PERFORM_CRUSHING
			
			CMP moves , 9
			JE reDraw
			
			CMP moves , 0
			JE endGame
		
			JMP process
		
		reDraw:
		
			; refresh screen
			MOV ah , 0
			MOV al , 12h
			INT 10h

			CALL DISPLAYBOARD
			CALL DISPLAYARRAY
			
			JMP process
		
		;----------------------------------------------------------
		endGame:

			; refresh screen
			MOV ah , 0
			MOV al , 12h
			INT 10h
		
			; draw "YOU RAN OUT OF MOVES!"
			REPOSITION 13 , 25
			MOV si , OFFSET endStr
			CALL DRAWSTRING

			; draw "YOUR SCORE : "
			REPOSITION 15 , 27
			MOV si , OFFSET yourScore
			CALL DRAWSTRING

			REPOSITION 15 , 40
			; draw score
			MOV si , 15
			MOV di , 40
			MOV ax , score
			CALL DISPLAYNUMBER

			MOV ah , 0
			INT 16h
	
			MOV ah , 4Ch
			INT 21h
MAIN ENDP


;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			DISPLAYBOARD
;		Arguments:			NIL
;		Return:				NIL
;		Details:			Procedure displys static game elements like name, score 
;							and moves string and grid lines
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

DISPLAYBOARD PROC 

	;------------------------------------------------------------
	;	Draw static screen elements
	;	Draw vertical and horizontal lines
	;------------------------------------------------------------

		REPOSITION 4 ,1 
		MOV si , OFFSET nameStr
		CALL DRAWSTRING

		REPOSITION 6 ,4
		MOV si , OFFSET nameString
		CALL DRAWSTRING

		REPOSITION 11 , 4
		MOV si , OFFSET movesStr
		CALL DRAWSTRING
		
		REPOSITION 13 , 6
		DRAWCHAR '/',03,1

		REPOSITION 13 , 8
		MOV ax , 20
		MOV si , 13
		MOV di , 8
		CALL DISPLAYNUMBER	
		
		REPOSITION 18 ,4
		MOV si , OFFSET scoreStr
		CALL DRAWSTRING	

	;------------------------------------------------------------
	
		MOV si , 120		; x_axis
		verlines:
			MOV di , 0			; y_axis
			
			draw_vertical_line:
				
				; draw pixel
				DRAWPIXEL 03 , si , di
			
				INC di
				CMP di , 480
				JE move_next
				JMP draw_vertical_line
				
			move_next:

			ADD si, 40
			CMP si,520
			JA proceed
			JMP verlines

		proceed:
		MOV di,0		; y_axis  = 0
		horilines:
			MOV si,120		; x_axis = 120
			draw_horizontal_line:
				
				; draw pixel
				DRAWPIXEL 03 , si , di
				
				INC si
				MOV ax,si
				CMP ax,520
				JE move_next1
				JMP draw_horizontal_line
				
			move_next1:

			ADD di,48
			CMP di,480
			JA exit
			JMP horilines
		exit:
	;------------------------------------------------------
		RET 
DISPLAYBOARD ENDP

;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			DISPLAYARRAY
;		Arguments:			NIL
;		Return:				NIL
;		Details:			Procedure display non-static game elements like game array
;							score and moves count.
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

DISPLAYARRAY PROC

	;------------------------------------------------------------
	;	Draw non-static screen elements
	;	Draw moves and score
	;------------------------------------------------------------

		MOV si, 0
		MOV row , 1
	
	L1:
		MOV col , 17
		MOV di , 0
	
		L2:

			; convert si & di to indexing array
			MOV dx , 0
			MOV ax , si
			MOV bx , 10		; number of columns
			MUL bx
			ADD ax , di
			MOV bx , ax

			; reposition
			REPOSITION row , col
			
			; draw char
			mov ah,09h
			mov al,array[bx]
			mov dl , al

			cmp al , 'X'			; blocker
			je cont
			cmp al , 'B'			; bomb
			je cont
			cmp al , 'C'			; crushed index
			je cont
			
			add al , 48
		cont:
			mov bh,0h
			mov bl,03
			mov cx,1
			
			CMP dl , 1
			JE number1
			CMP dl , 2
			JE number2
			CMP dl , 3
			JE number3
			CMP dl , 4
			JE number4
			CMP dl , 5
			JE number5
			CMP dl , 'C'
			JE crushed
			JMP interupt
			
			number1:
				MOV bl , 01
				JMP interupt
				
			number2:
				MOV bl , 02
				JMP interupt

			number3:
				MOV bl , 03
				JMP interupt

			number4:
				MOV bl , 04
				JMP interupt

			number5:
				MOV bl , 05
				JMP interupt
			crushed:
				MOV al , '-'
			
			interupt:
				int 10h

			ADD col , 5

			INC di 
			CMP di , 10
			JB L2

		ADD row , 3

		INC si 
		CMP si , 10
		JB L1

		;-------------------------------------------------------
		CLEARREGISTERS
		
		REPOSITION 13 , 4
		; draw move number
		MOV si , 13
		MOV di , 4
		MOV ax , moves
		CALL DISPLAYNUMBER

		REPOSITION 20 , 6
		; draw score number
		MOV si , 20
		MOV di , 6
		MOV ax , score
		CALL DISPLAYNUMBER

		;--------------------------------------------------------
		RET
DISPLAYARRAY ENDP


;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			PIXELTOCELL
;		Arguments:			x_axis , y_axis
;		Return:				colNumber , rowNumber
;		Details:			Procedure receives x_axis and y_axis and converts to 
;							rowNumber and columnNumber by dividing it with coordinates
;							of one cell 40x48
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

; receives x_axis and y_axis as stack entries
PIXELTOCELL PROC

	POP si 		; return address

	MOV dx , 0
	rowNumber:
		POP ax		; ax = y_axis
		MOV bx,48
		DIV bx
		MOV cx,ax		; store rowNumber for a while
		
		
		MOV dx , 0
	colNumber:
		POP ax	       ;	ax = x_axis
		SUB ax,120
		MOV bx,40
		DIV bx

	PUSH ax			; colNumber Pushed to stack
	PUSH cx			; rowNumber Pushed to stack

	PUSH si
	RET
PIXELTOCELL ENDP


;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			INTIALIZEARRAY
;		Arguments:			rowNumber , colNumber
;		Return:				y_axis , x_axis
;		Details:			Procedure receives rowNumber and colNumber and converts to 
;							x_axis and y_axis by multiplyingit with coordinates
;							of one cell 40x48
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

CELLTOPIXEL PROC
	
	POP si		; return address

	MOV dx , 0
	x_axis:
		POP ax 		; ax = colNumber
	
		MOV bx , 40
		MUL bx
		ADD ax , 120
		MOV cx , ax

		MOV dx , 0
	y_axis:	
		POP ax		; ax = rowNumber
	
		MOV bx , 48
		MUL bx
    
	PUSH ax			; push y_axis
	PUSH cx			; push x_axis


	PUSH si
	RET
CELLTOPIXEL ENDP


;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			DRAWSTRING
;		Arguments:			Array OFFSET , rowNumber , colNumber
;		Return:				NIL
;		Details:			Procedure draws string on given rowNumber and colNumber
;							receives offset in si 
; 							row number in dh 
; 							colNumber in dl
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

DRAWSTRING PROC

L0:
	; reposition
	MOV ah , 02h		; cursor position
	INT 10h
	
	; draw char
	MOV ah , 09h		; display character at the cursor position
	MOV al , [si]			; character to display
	MOV bh , 0h			; page number
	MOV bl , 03			; color
	MOV cx , 1			; number of times to display the character
 	INT 10h
	
	INC dl				; increment Col number
	
	INC si
	MOV al , [si]
	CMP al , '$'
	JNE L0

	RET

DRAWSTRING ENDP

;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			INPUTNAME
;		Arguments:			Array OFFSET , rowNumber , colNumber
;		Return:				NIL
;		Details:			Procedure input a string and stores in the given array offset
;							and simultaniously displays the entered character at given 
;							rowNumber and colNumber
; 							receives offset in si 
; 							row number in dh 
; 							colNumber in dl
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

INPUTNAME PROC

MOV di , 0
L0:

	MOV ah , 0h
	INT 16h
	
	MOV [si] , al
	
	CMP al , 13
	JE enterPressed
	
	; reposition
	MOV ah , 02h		; cursor position
	INT 10h
	
	; draw char
	MOV ah , 09h		; display character at the cursor position
	MOV al , [si]			; character to display
	MOV bh , 0h			; page number
	MOV bl , 03			; color
	MOV cx , 1			; number of times to display the character
 	INT 10h

	INC si
	INC dl 		; increment column number
	
	INC di 
	CMP di , 7
	JNE L0
	
enterPressed:
	MOV al , "$"
	MOV [si],al

	RET
INPUTNAME ENDP


;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			DISPLAYNUMBER
;		Arguments:			Number to display , rowNumber , colNumber
;		Return:				NIL 
;		Details:			Procedure receives a number and displays at the given rowNumber
;							and colNumber
;							number in ax , rowNumber in si , colNumber in di
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

DISPLAYNUMBER PROC

	PUSH bx 
	PUSH cx 
	PUSH dx
	
    MOV bx , 10
    MOV cx , 0				; to handle count of stack pushes

L1:
    MOV dx , 0
    DIV bx					; divide number by 10 till quotient reaches 0

    PUSH dx					; push remainder to stack
	INC cx					; increment count 

    CMP ax , 0				; if quotient becomes zero , jump to displayDigit
    JBE displayDigit

    JMP L1					; else loop around

	
; cx contains the count of loop
displayDigit:

    POP dx					; extract remainder from stack and display digit
    ADD dx , 48

	
	PUSH cx
	DRAWCHAR dl , 03, 1
	INC di
	MOV ax , si
	MOV bx , di
	REPOSITION al , bl
	CLEARREGISTERS
	POP cx
	
    Loop displayDigit

	POP dx
	POP cx
	POP bx
	
	RET				; return 
DISPLAYNUMBER ENDP


;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			RANDNUMBER
;		Arguments:			Seed , Range
;		Return:				Random Number
;		Details:			Procedure receives seed and range and calculate a number
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

RANDNUMBER PROC 

	POP cx			; return address
	
	POP ax			; seed
	
	MOV dx , 0		; multiply seed with 7
	MOV bx , 7
	MUL bx
	
	MOV dx , 0		; take mod with 101
	MOV bx , 101
	DIV bl
	MOV al , 0
	MOV al , ah
	MOV ah , 0
	
	MOV dx , 0		; take mod with specified range
	POP bx			; range
	DIV bl
	
	INC ah
	MOV al , 0
	MOV al , ah
	MOV ah , 0

	PUSH ax			; random number pushed to stack
	
	PUSH cx			; return address pushed to stack
	RET
RANDNUMBER ENDP

;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			PERFORM_CRUSHING
;		Arguments:			NIL
;		Return:				NIL
;		Details:			Procedure traverses the array and replaces the combinations
;							with char 'C', updates the score and repeates until no 
;							combinations are found. Char 'C' are moved upwards and random
;							number is generated at that location by calling procedure 
;							RANDNUMBER.  It simultaniously draws array again.
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

PERFORM_CRUSHING PROC
	
	;------------------------------------------------------------
	;	Make horizontal combinations 'C'
	;	Make vertical combinations 'C'
	;------------------------------------------------------------

	; /// Crushing
	crushing:
	
	;------------------------------------------------------------
	; horizontal
	MOV repeatCrushing , 0
	MOV si , 0
	L3:	
		MOV di , 0
		L4:	
			MOV temp , 1
			; indexing
			; convert si & di to indexing array
			MOV dx , 0
			MOV ax , si
			MOV bx , 10		; number of columns
			MUL bx
			ADD ax , di

			MOV bx , ax
			MOV dx , ax
			
			MOV ah , 0
			MOV al , array[bx]
			
			cmp_first:

				MOV cx , di
				INC cx 
				CMP cx , 10
				JE bound_end
				
				MOV bx , dx
				ADD bx , temp
				
				CMP al , array[bx]
				JNE combination_not_found
				
				INC temp
			cmp_second:

				INC cx
				CMP cx , 10
				JE bound_end

				MOV bx , dx
				ADD bx , temp

				
				CMP al , array[bx]
				JNE combination_not_found
				
				INC temp
			cmp_allNextnumbers:

				INC cx 
				CMP cx , 10
				JE combination_found
				
				MOV bx , dx
				ADD bx , temp
				

				CMP array[bx] , 'X'
				JNE continue
				
				MOV array[bx] , 'B'			; BOOOMBBB
				JMP combination_found
				
				continue:

					CMP al , array[bx]
					JNE combination_found
					
					MOV array[bx] , 'C'
					ADD score , 10
					
					INC temp
					JMP cmp_allNextnumbers

			combination_found:
				; make 3 'C'
				MOV bx , dx
			;	ADD bx , temp

				MOV array[bx] , 'C'
				MOV array[bx+1] , 'C'
				MOV array[bx+2] , 'C'

				MOV repeatCrushing , 1
				ADD score , 30
				; remove blockers
				MOV ax , bx
				mov bx,10
				DIV bl
				CMP ah , 0			; left bound error
				JE cont
				
			;	POP dx
				
				MOV bx , dx
				CMP array[bx-1] , 'X'
				JE destoryBlocker
				JNE cont
				
			destoryBlocker:
				MOV array[bx-1] , 'B'		; BOOOMBBB
				
				

		cont:	
			ADD di , temp
			DEC di
			
		combination_not_found:	
			INC di 

			CMP di , 10
			JB L4
			
	bound_end:
	
	INC si
	CMP si , 10
	JB L3

	;----------------------------------------------------------------
	; vertical
	CLEARREGISTERS
	MOV si , 0
	L5:
		MOV di , 0
		L6:
			MOV temp , 10
		;	mov temp1,1
			; indexing
			; convert si & di to indexing array
			MOV dx , 0
			MOV ax , di
			MOV bx , 10		; number of columns
			MUL bx
			ADD ax , si

			MOV bx , ax
			MOV dx , ax
			
			MOV ah , 0
			MOV al , array[bx]
			
			cmp_first_ver:

				MOV cx , di
				add cx,10;;;;;;;
				CMP cx , 100	;;;
				JaE bound_end_ver
				
				MOV bx , dx
				ADD bx , temp
				
				CMP al , array[bx]
				JNE combination_not_found_ver
				
				add temp,10
			;	inc temp1
			cmp_second_ver:

				add cx,10  ;;;;;
				CMP cx , 100	;;;;
				JaE bound_end_ver

				MOV bx , dx
				ADD bx , temp

				
				CMP al , array[bx]
				JNE combination_not_found_ver
				
				add temp,10
			;	inc temp1
			cmp_allNextnumbers_ver:

				add cx,10
				CMP cx , 100	;;;;
				JaE combination_found_ver
				
				MOV bx , dx
				ADD bx , temp

				
				CMP array[bx] , 'X'
				JNE continueVer

				MOV array[bx] , 'B'				; BOOOMBBB
				JMP combination_found_ver
				
				continueVer:
					
					CMP al , array[bx]
					JNE combination_found_ver
					
					MOV array[bx] , 'C'
					ADD score , 10
					add temp,10
				;	inc temp1
					JMP cmp_allNextnumbers_ver


		combination_found_ver:
			; make 3 'C'
			MOV bx , dx
			
		;	ADD bx , temp
			MOV array[bx] , 'C'
			MOV array[bx+10] , 'C'
			MOV array[bx+20] , 'C'

			MOV repeatCrushing , 1
			ADD score , 30
			; remove blockers
			MOV ax , bx
			mov bx,10
			DIV bl
			CMP ah , 0			; left bound error
			JE cont_ver

			MOV bx , dx
			CMP array[bx-10] , 'X'
			JE destoryBlockerVer
			JNE cont_ver

		destoryBlockerVer:
			MOV array[bx-10] , 'B'		; BOOOMBBB

		cont_ver:
			
			ADD di , temp
			
		combination_not_found_ver:
			INC di 

			CMP di , 10
			JB L6
		
	bound_end_ver:
		
		INC si
		CMP si , 10
		JB L5

	;------------------------------------------------------------
		
	CALL DISPLAYARRAY		
	DELAY 07h, 0A120h

	CALL DROPPING_RANDOM_NUMBERS
	CLEARREGISTERS
	CALL DISPLAYARRAY
	
	CMP repeatCrushing , 1
	JE crushing

	RET


PERFORM_CRUSHING ENDP

;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			DROPPING_RANDOM_NUMBERS
;		Arguments:			NIL
;		Return:				NIL
;		Details:			Procedure locates elements with char 'C' and moves them 
;							towards top. It then genereate random number at that locations
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

DROPPING_RANDOM_NUMBERS PROC


dropping:

	; // DROPPING 
	MOV range , 5
	MOV di , 0
	
L0:

	MOV si , 9
	MOV cx  , 0
L1:
	; indexing
	MOV dx , 0
	MOV ax , si
	MOV bx , 10		; number of columns
	MUL bx
	ADD ax , di
	
	MOV bx , ax
		
	CMP array[bx] , 'C'
	JNE L1_end
	
	;// found 
	
	
innerLoop:
	
	; // swap
	MOV al , array[bx]
	MOV dl , array[bx-10]
	MOV array[bx] , dl
	MOV array[bx-10] , al

	SUB bx , 10
	CMP bx , 10
	JAE innerLoop
		
	INC cx 
	CMP si , cx 
	JA L1

L1_end:
	
	DEC si
	CMP si , cx
	JA L1


	INC di
	CMP di , 10
	JB L0
	
	; genereate random
	MOV range , 5
	MOV si , 0
L10:

	cmp array[si], 'C'
	jne not_space
	make_random:
		
		PUSH range
		PUSH seed		
		CALL RANDNUMBER
		INC seed
		
		pop ax
		mov array[si],al
	not_space:
	
	INC si 
	CMP si , 100
	JB L10	
		
	RET
DROPPING_RANDOM_NUMBERS ENDP

;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			DESTROYNUMBER
;		Arguments:			Number to destroy
;		Return:				NIL
;		Details:			Procedure traverses the array and replaces the number with 'C'
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

DESTROYNUMBER PROC
	
	MOV cx , 0
	MOV bx , 0
	
	POP bx  		; return address
	POP cx 			; number to destroy
	
	PUSH si
	
	MOV si , 0
L0:

	CMP array[si] , cl
	JNE cont
	
	MOV array[si] , 'C'
	ADD score , 10
	
cont:

	INC si
	CMP si , 100
	JB L0

	POP si
	
	PUSH bx
	RET

DESTROYNUMBER ENDP

;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
; 		Procedure:			INTIALIZEARRAY
;		Arguments:			Array OFFSET , Array size
;		Return:				NIL 
;		Details:			Procedure intializes array with random numbers and blockers.
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

INTIALIZEARRAY PROC 

	POP si 			; return address

	POP cx 			; array size
	POP bx 			; array OFFSET
	
	MOV range, 5
	MOV di , 0
	
	L0:
		PUSH bx
		PUSH cx
		; genereate a random number 
		
		PUSH range
		PUSH seed		
		CALL RANDNUMBER
		INC seed
		
		POP ax 				; receive random number		
		
		POP cx
		POP bx
		
		MOV [bx+di] , al
		
		INC di 
		CMP di , cx
		JB L0
	
	MOV range, 100	
	MOV cx , 0
	L1:
		; genereate a random number 
		PUSH bx
		PUSH cx
		
		PUSH range
		PUSH seed
		CALL RANDNUMBER
		INC seed
		
		POP di				; random index
		POP cx
		POP bx
		
		MOV al , 'X'
		MOV [bx+di] , al

		INC cx
		CMP cx , 15
		JB L1
	
	PUSH si
	RET
		
INTIALIZEARRAY ENDP


END
