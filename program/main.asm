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
extern mvaddch
extern wtimeout

section .data
	title			db "GAME TITLE", 0x0
	play_str		db "PLAY", 0x0

	win_str			db "YOU WON!", 0x0
	lose_str		db "YOU LOST", 0x0
	play_again_str	db "PLAY AGAIN", 0x0

	pause_str		db "PAUSE", 0x0
	resume_str		db "RESUME", 0x0

	info_str		db "INFO", 0x0
	goal_info_str	db "Reach the 'E' marked on the map without being attacked.", 0x0
	mv_key_info_str	db "The player controllers use standard AWSD keys or HJKL.", 0x0
	ex_key_info_str db "To pause the game press the 'p' key.", 0x0
	hint_str		db "Hint: Holding the keys will increase the players speed.", 0x0
	credit_str		db "Created by: Angel Aguayo and Nicholas Kunzler", 0x0

	exit_str		db "EXIT", 0x0

	map:		db "map2.txt", 0x0
	map_width	equ 101
	map_height	equ 30

section .text
global _start

_start:
	PUSH	rbp
	MOV		rbp, rsp

	SUB		rsp, 0x8		; root screen

	CALL	initscr
	MOV		[rbp-0x8], rax
	CALL	cbreak
	CALL	noecho

_load_main_menu:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load the main menu system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	; WARNING
	; This procedure does not follow standard calling convention
	; All the menu items are stored on the stack and not within the
	; standared registers
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	MOV		rdi, [rbp-0x8]	; Window to which to render menu
	MOV		rsi, title		; Title for the menu, currently not working
	MOV		rcx, 3			; Number of menu items
	PUSH	exit_str		; Middle menu item
	PUSH	info_str		; Last menu item
	PUSH	play_str		; First menu item
	CALL	_show_menu

	CMP		rax, 0x0		; First list item selected, PLAY
	JE		_load_map		

	CMP		rax, 0x1		; Second list item selected, INFO
	JE		_load_info_menu

	CMP		rax, 0x2		; Second list item selected, EXIT
	JE		_exit_success

	JMP		_exit_error		; Strange selection is an error

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Creates a new Info window that tells a little about how
; to move around in the game, gives a movement hint, and
; how to pause the game, and of course given credit to the
; creators, use.
;;;;;;;;;;;;;;;;;;;;;;;;;;;
_load_info_menu:
	MOV		rdi, [rbp-0x8]	; Window to which to render menu
	MOV		rsi, info_str	; Title for the menu, currently not working
	MOV		rcx, 5			; Number of menu items
	PUSH	credit_str
	PUSH	hint_str
	PUSH	ex_key_info_str
	PUSH	mv_key_info_str
	PUSH	goal_info_str
	CALL	_show_menu

	JMP		_load_main_menu


;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Loading the map the player will run on
;;;;;;;;;;;;;;;;;;;;;;;;;;;
_load_map:
	CALL	refresh

	; Get Y position for game map window
	MOV		rdx, map_height	; RDX = y coord
	SHR		rdx, 1			; Map height / 2

	MOV		rdi, [rbp-0x8]	; Root window
	CALL	_get_win_centerY; Center X position of root window
	SUB		rax, rdx		; Game window y = (root_window_height / 2) - (map_height / 2)
	MOV		rdx, rax		; RDX = y coord where the game window is centered in root window

	; Get X position for game map window 
	MOV		rcx, map_width	; RCX = x coord
	SHR		rcx, 1			; Map width / 2

	MOV		rdi, [rbp-0x8]	; Root window
	CALL	_get_win_centerX; Center X coord of root window
	SUB		rax, rcx		; Game window x = (root_window_width / 2) - (map_width / 2)
	MOV		rcx, rax		; RCX = x coord where the game window is centered in root window

	MOV		rdi, map_height	; Number of rows
	MOV		rsi, map_width	; Number of columns
	CALL	newwin
	MOV		rbx, rax		; Game Window

	; Calculate map size = (# Cols) * (# Rows)
	MOV		rax, map_width
	MOV		rdx, map_height
	MUL		rdx				; RAX = RDX * RAX
	MOV		rdx, rax		; map_size

	; Draw map on game window
	MOV		rdi, rbx		; Game window
	MOV		rsi, map		; The map to load
	MOV		rcx, 0
	MOV		r8, 0
	CALL	_render_map		; Draws the map to the terminal and set cursor to start

	TEST	rax, rax		; Making sure the game map was rendered, error if rax < 0
	JL		_exit_error

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Player movement / Game loop here
;
; Can use window.asm for maybe helpful procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	XOR		r12, r12		; Key pressed

	MOV		rdi, rbx
	MOV		rsi, 100
	CALL	wtimeout	

_game_loop:
	MOV		rdi, rbx		; Window in which to get input from
	CALL	wgetch			; Waiting for user input

	CMP		eax, -1
	JE		.move_player
	MOV		r12, rax
	
	CMP		r12, 0xa		; If user input is new line, exit game
	JE		_menus.show_lose_menu

	CMP		r12, 'p'
	JE		_menus.show_pause_menu

.move_player:

	;
	; Start of player movement
	;

	; Sorry just have to have vim movement for my sanity

	CMP		r12, 's'		; S key for gamers
	JE		.mv_player_down
	CMP		r12, 'j'		; J key for vimers
	JE		.mv_player_down

	CMP		r12, 'w'
	JE		.mv_player_up
	CMP		r12, 'k'		
	JE		.mv_player_up

	CMP		r12, 'a'
	JE		.mv_player_left
	CMP		r12, 'h'	
	JE		.mv_player_left

	CMP		r12, 'd'
	JE		.mv_player_right
	CMP		r12, 'l'
	JE		.mv_player_right

	; Add other movements here
	; There is a _move_cursor_x method that can maybe be used
	; See window.asm file for parameter info

	JMP		_game_loop		; Infinite loop / game loop


.mv_player_right:
	MOV		rdi, rbx		; Window from which to move the cursor
	MOV		rsi, 1			; Number of squares to jump each press
	CALL	_mov_cursor_x	; CALL window.asm corresponding function
	JMP		_game_loop		; Jump back to game loop to get next input


.mv_player_left:
	MOV		rdi, rbx		; Window from which to move the cursor
	MOV		rsi, -1			; Number of squares to jump each press
	CALL	_mov_cursor_x	; CALL window.asm corresponding function
	JMP		_game_loop		; Jump back to game loop to get next input


.mv_player_up:
	MOV 	rdi, rbx
	MOV		rsi, -1
	CALL	_mov_cursor_y
	JMP		_game_loop


.mv_player_down:
	MOV		rdi, rbx		; Window from which to move the cursor
	MOV		rsi, 1			; Number of square to jump each press
	CALL	_mov_cursor_y	; CALL window.asm corresponding function
	JMP		_game_loop		; Jump back to game loop to get next input

_menus:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a new pause window that will prompt the user
; to either resume the game play or to exit the game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.show_pause_menu:
	MOV		rdi, [rbp-0x8]	; Window to which to render menu
	MOV		rsi, pause_str	; Title for the pause menu
	MOV		rcx, 2			; Number of menu items
	PUSH	exit_str		; Last menu item
	PUSH	resume_str		; First menu item
	CALL	_show_menu
	
	CMP		rax, 0x0		; First list item selected, RESUME
	JE		_game_loop.mv_player_left

	CMP		rax, 0x1		; Second list item selected, EXIT
	JE		_end_game
	JMP		_exit_error		; Strange selection is an error

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a new win window that indicates to the user that
; they have won the game. They are given the option to play
; again or to exit the game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.show_win_menu:
	MOV		rdi, [rbp-0x8]	; Window to which to render menu
	MOV		rsi, win_str	; Title for the win menu
	MOV		rcx, 2			; Number of menu items
	PUSH	exit_str		; Last menu item
	PUSH	play_again_str	; First menu item
	CALL	_show_menu

	CMP		rax, 0x0		; First list item selected, PLAY AGAIN
	JE		_restart

	CMP		rax, 0x1		; Second list item selected, EXIT
	JE		_end_game

	JMP		_exit_error		; Strange selection is an error

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays a new win window that indicates to the user that
; they have lost the game. They are given the option to play
; again or to exit the game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.show_lose_menu:
	MOV		rdi, [rbp-0x8]	; Window to which to render menu
	MOV		rsi, lose_str	; Title for the lose menu
	MOV		rcx, 2			; Number of menu items
	PUSH	exit_str		; Last menu item
	PUSH	play_again_str	; First menu item
	CALL	_show_menu

	CMP		rax, 0x0		; First list item selected, PLAY AGAIN
	JE		_restart

	CMP		rax, 0x1		; Second list item selected, EXIT
	JE		_end_game

	JMP		_exit_error		; Strange selection is an error

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Destroys the current game window and will rerender the game
; board representing a restart.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_restart:
	mov		rdi, rdx
	CALL	endwin
	JE		_load_map

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Destroys the current game window and then exits the program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_end_game:
	mov		rdi, rdx
	CALL	endwin
	; Falls through to exit_success

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

	LEAVE		; restoring the stack

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

	LEAVE		; restoring the stack

	; Exit with error code 1
	MOV		rax, 0x3c
	MOV		rdi, 1
	SYSCALL
