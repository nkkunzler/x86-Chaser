section		.bss
	temp			resq	1


section		.data
	newline			db		0xa, 0x0
	newline_len		equ		$ - newline

	output			db		"The max of the array is: "
	output_len		equ		($ - output)
	
	nums			dq		1, 2, 3, 9, 5, 6, 7, 8
	len				equ		($ - nums)/8

	EXIT_SUCCESS 	equ		0
	SYS_exit		equ		60


section		.text

global		_start

_start:
	xor 	r10, r10			; index = 0
	mov		r11, [nums]			; max (r11) = nums[0]


_loop:	
	cmp		r10, len			; if index > len(nums)
	jge		_print_max

	inc		r10					; index ++
	mov 	r12, [nums+r10*8]

	cmp 	r12, r11			; if num[i] > max
	jg		_replace        	; set max=num[i]

	jmp		_loop

_replace:
	mov		r11, r12			; max = num[i]
	jmp		_loop

_print_max:
	add		r11, '0'			; convert integer to character
		
	mov		[temp], r11			; move integer to memory to pass as a pointer

	mov		rax, 1				; syscall to write
	mov 	rdi, 0x1			; write to stdout

	mov		rsi, output
	mov		rdx, output_len
	syscall	

	mov		rax, 0x1
	mov 	rsi, temp			; store element of array
	mov		rdx, 8				; size of input
	syscall

	mov		rax, 0x1
	mov 	rsi, newline
	mov		rdx, newline_len
	syscall
	
	mov 	rax, SYS_exit
	mov		rdi, EXIT_SUCCESS
	syscall
