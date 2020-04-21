

section		.data
		nums		dq		420, 69, 4, 20, 6969, 69420, 42060
		len			equ		$ - nums
		new_line	db		0xa
	

section		.bss
		buffer		resq	33


section		.text

global		_start


_start:
		mov		rdi, nums
		call 	_insertsort


_print:
		mov		rdi, 1235
		call 	_itoa			

		; Printing out the newly created integer string
		mov		rsi, buffer
		mov		rax, 0x1
		mov		rdi, 0x1
		mov		rdx, 33
		syscall

		; Printing a new line
		mov		rax, 0x1
		mov		rdi, 0x1
		mov		rsi, new_line
		mov		rdx, 0x1
		syscall					

		; Exit
		mov		rax, 0x3c
		xor		rdi, rdi
		syscall

_insertsort:
		mov		r11, 1 				; i = 1


; for(int i=1; i<len; i++)
_loop:
		cmp		r11, len   			; if i >= len
		jge		_print
		
		mov		r12, [rdi+r11*8]	; main element = array[i]

		mov		r13, r11			
		dec		r13					; j = i - 1

; while ( j<=0 )
;		if(array[j] <= array[i]
			
;			break
;		array[j+1] = array[j]		
;	
_beginWhile:
		cmp		r13, 0				; if j < 0
		jl		_next	

		mov		r14, [rdi + r13*8]	; temp = array[j]
		cmp		r14, r12			; if temp <= main element
		jng		_next

		mov		[nums+r13*8+8], r14	; array[j+1] = array[j] 
		dec		r13					; j --
		jmp		_beginWhile


;	array[j+1]= main element 
;
_next:
		mov		[rdi + r13*8+8], r11 
		
		dec		r13					; j ++
		

		jmp		_beginWhile


; Converts an integer value to a string
; Not very optimized, can be better
_itoa:
	MOV		rax, rdi
	XOR		rcx, rcx
	
_itoa_h:
	XOR		rdx, rdx
	MOV		rbx, 10			
	DIV		rbx					; Div input value by 10
	ADD		rdx, '0'			; int val to corresponding str val

	LEA		rsi, [buffer + rcx]
	MOV		[rsi], dl			; Remainder of the division
	ADD		rcx, 1

	CMP		rax, 0x0			; Checking if quotient is zero
	JNE		_itoa_h
	
	ADD		rcx, -1	; Go to last char

_swap:
	CMP		rax, rcx
	JG		_end

	MOV		rdx, [buffer+rax]	; tmp

	LEA		rdi, [buffer+rax]	; &lhs
	MOV		rsi, [buffer+rcx]	; *rhs
	MOV		[rdi], sil			; *lhs = *rhs

	LEA		rsi, [buffer+rcx]	; &rhs
	MOV		[rsi], dl			; *rhs = tmp

	ADD		rax, 1				; lhs + 1
	ADD		rcx, -1				; rhs - 1
	JMP		_swap

_end:
	RET
