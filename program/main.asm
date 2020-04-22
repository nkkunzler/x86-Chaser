;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The following will read in a map file, render it
; to the screen and exit when the user adds an input.
;
; Remaining Tasks (Current Thoughts):
;	- Center the map on the window
; 	- Add player movement
;	- Add enemy movement
;	- Add win/lose screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%include "./map_render.asm"
%include "./window.asm"
%include "./menu.asm"

extern initscr
extern refresh
extern cbreak
extern noecho
extern getch
extern endwin
extern newwin
extern box

section .data
	title		db "JAIL GAME", 0x0

	play_str	db "PLAY", 0x0
	exit_str	db "EXIT", 0x0

	map:		db "map1.txt", 0x0
	map_width	equ 60
	map_height	equ 21

section .text
global _start

_start:
	CALL	initscr
	MOV		rbx, rax
	CALL	cbreak
	CALL	noecho

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load the main menu system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	; WARNING
	; This procedure does not follow standard calling convention
	; All the menu items are stored on the stack and not within the
	; standared registers
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	MOV		rdi, rbx		; Window to which to render menu
	MOV		rsi, title		; Title for the menu, currently not working
	MOV		rcx, 2			; Number of menu items
	PUSH	exit_str		; Last menu item
	PUSH	play_str		; First menu item
	CALL	_show_menu
	POP		r9				; Need to move this to callee
	POP		r9				; Need to move this to callee

	CMP		rax, 0x0		; First list item selected, PLAY
	JE		_load_map		

	CMP		rax, 0x1		; Second list item selected, EXIT
	JE		_exit_success

	JMP		_exit_error		; Strange selection is an error

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Loading the map the player will run on
;;;;;;;;;;;;;;;;;;;;;;;;;;;
_load_map:
	CALL	refresh

	; Get Y position for the map
	MOV		r9, map_height
	SHR		r9, 1			; half map height

	MOV		rdi, rbx
	CALL	_get_win_centerY
	SUB		rax, r9
	MOV		r8, rax

	; Get X position for the map
	MOV		r9, map_width
	SHR		r9, 1			; half map height

	MOV		rdi, rbx
	CALL	_get_win_centerX
	SUB		rax, r9
	MOV		rcx, rax

	; Get the number of bytes to read based off of width and height
	MOV		rax, map_width
	MOV		rdx, map_height
	MUL		rdx
	MOV		rdx, rax

	; Rendering the map to terminal screen
	MOV		rdi, rbx
	MOV		rsi, map	; The map to load
	CALL	_render_map	; Draws the map to the terminal and set cursor to start

	TEST	rax, rax
	JL		_exit_error


;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Player movement / Game loop here
;
; Can use window.asm for maybe helpful procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;
_game_loop:
	MOV		rdi, rbx		; Window in which to get input from
	CALL	wgetch			; Waiting for user input

	CMP		rax, 0xa		; If user input is new line, exit game
	JE		_exit_success

	;
	; Start of player movement
	;

	CMP		rax, 's'		; S key for gamers
	JE		.mv_player_down
	CMP		rax, 'j'		; J key for vimers
	JE		.mv_player_down

	; Add other movements here
	; There is a _move_cursor_x method that can maybe be used
	; See window.asm file for parameter info

	JMP		_game_loop		; Infinite loop / game loop

.mv_player_down:
	MOV		rdi, rbx		; Window from which to move the cursor
	MOV		rsi, 1			; Number of square to jump each press
	MOV		rdx, 0			; Minimum y value the player can move to
	MOV		rcx, 49			; Miximum y value the player can move to
	CALL	_mov_cursor_y	; CALL window.asm corresponding function
	JMP		_game_loop		; Jump back to game loop to get next input


;;;;;;;;;;;;;;;;;;;;;;;;;
; Code to exit the program
; 
; Contains: 
; 		exit success, returns error code 0
; 		exit error, returns error code 1
;;;;;;;;;;;;;;;;;;;;;;;;;
section .data
	suc_msg		db ":( Why are you leaving me? Please come back!", 0xa, 0x0
	suc_msg_len	equ $ - suc_msg

	err_msg		db ":() An Error Has Occured!", 0xa, 0x0
	err_msg_len	equ $ - err_msg

section .text

_exit_success:
	CALL	endwin

	; Print success leave message
	MOV		rax, 0x1
	MOV		rdi, 0x1
	MOV		rsi, suc_msg
	MOV		rdx, suc_msg_len
	SYSCALL

	; Exit with error code 0
	MOV		rax, 0x3c
	XOR		rdi, rdi
	SYSCALL

_exit_error:
	CALL	endwin

	; Print error message
	MOV		rax, 0x1
	MOV		rdi, 0x1
	MOV		rsi, err_msg
	MOV		rdx, err_msg_len
	SYSCALL

	; Exit with error code 1
	MOV		rax, 0x3c
	MOV		rdi, 1
	SYSCALL
