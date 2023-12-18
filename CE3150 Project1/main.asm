;
; Project1.asm
;
; Created: 10/21/2023 5:45 PM
; Author : Adam Camerer, Evan Parrish, Ethan Mollet, Jerrett Martin
;

.EQU MAX = 0x00
.EQU MIN = 0xFF

LDI R16, 0x00 ;Set register 16 to 0 initially. This register will store the current count.
LDI R17, 0x01 ;Set register 17 to 1 initially. This register will store the increment amount.
LDI R18, 0xFF
LDI R19, 0x00
LDI R20, 0x05 ; Set register 20 to 5 initially. This register will count the change in increment amount.
LDI R21, 0x00 ; Set register 21 to 0 initially. This register will hold the initial value
LDI R26, 30	  ; max / min counter for increment

OUT DDRD, R18 ;Port D in output mode
OUT PORTD, R18 ;Turn off LEDS (active low)

LDI R24, 0b00110000 ; temporary variable
OUT DDRE, R24 ; Everything in Port E except for switch 5 is in output mode

;SBIS PINE, 5
;CBI PORTD, 7

;SBIC PINE, 5
;CBI PORTD, 6

OUT DDRA, R19 ; Port A in input mode
OUT PORTA, R18 ; enable pull-ups on PA
OUT PORTE, R18 ; turn everything off on Port E

; set the leds to an initial value, make sure buttons are not being pressed
INIT:
	CALL RESET_COUNT
	CALL SET_LEDS ; turn all LEDS off
	CALL QDELAY

MAIN:
	; function to increment the counter
	CHECK_UP:
		; skip to CHECK_DOWN if button 8 not pressed
		; otherwise, increment counter, adjust lights and return to main
		SBIC PINA, 6
		RJMP CHECK_DOWN
		CP R16, R26
		BREQ COUNT_MAX ; ensure R16 <= 30
		INC R16
		CALL SET_LEDS
		CALL QDELAY
		RJMP MAIN

	CHECK_DOWN:
		; skip to CHECK_RESET if button 7 not pressed
		; otherwise, decrement counter, adjust lights and return to main
		SBIC PINA, 5 
		RJMP CHECK_RESET
		CP R19, R16
		BREQ COUNT_MIN ; ensure R16 >= 0
		DEC R16
		CALL SET_LEDS
		CALL QDELAY
		RJMP MAIN

	;;;;;;;;;;;;;;;;;;;;;;;;;;custom function;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; activating switch 6 (i.e. pinA4) resets the the counter to 0, changes the lights
	CHECK_RESET:
		; skip to CHECK_CHG_INC if button 6 not pressed
		; otherwise, reset counter, adjust lights and return to main
		SBIC PINA, 4
		RJMP CHECK_SHIFT_MODE
		CALL RESET_COUNT
		CALL SET_LEDS
		CALL QDELAY
		RJMP MAIN
	;;;;;;;;;;;;;;;;;;;;;;;;;;custom function;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CHECK_SHIFT_MODE:
		SBIC PINA, 3 ; Skip next instruction if button3 gets a 0
		RJMP CHECK_LIGHT_UP_MODE
		CHECK_SHIFT_WAIT_REL:
			SBIS PINA, 3
			RJMP CHECK_SHIFT_WAIT_REL
		CALL SHIFT_MODE
		CALL QDELAY
		RJMP MAIN

	; function to check if program should switch to light up mode
	CHECK_LIGHT_UP_MODE:
	; return to main if pin E6 is not pressed
	; otherwise call the function, wait until finished, and then return to main
	SBIC PINE, 6
	RJMP CHECK_STOPWATCH_MODE
	CHECK_LIGHT_WAIT_REL:
		SBIS PINE, 6
		RJMP CHECK_LIGHT_WAIT_REL
	CALL QDELAY
	CALL LIGHT_UP_MODE
	RJMP MAIN

	; function to check if program should switch to stopwatch mode
	CHECK_STOPWATCH_MODE:
		; return to main if pin A7 is not pressed
		; otherwise call the function, wait until finished, and then return to main
		SBIC PINA, 7 ; Skip next instruction if button9 gets a 0
		RJMP MAIN
		CHECK_STOPWATCH_WAIT_REL:
			SBIS PINA, 7 ; Skip next instruction if button9 gets a 0
			RJMP CHECK_STOPWATCH_WAIT_REL
		CALL QDELAY
		CALL STOPWATCH_MODE
		RJMP MAIN

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; called if counter < 0 (i.e. 255)
	COUNT_MAX:
		CALL RESET_COUNT
		CALL SET_LEDS
		CALL TURN_ON_SPEAKER
		CALL QDELAY
		RJMP MAIN

	; called if counter > 30 (i.e. 31)
	COUNT_MIN:
		CALL SET_COUNT
		CALL SET_LEDS
		CALL TURN_ON_SPEAKER
		CALL QDELAY
		RJMP MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;; COMMON FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; reset counter to 0
RESET_COUNT:
	MOV R16, R19
	RET

; set counter to 30
SET_COUNT:
	MOV R16, R26
	RET

; Turns on the LEDs according to value stored in R16 (The count register) 
SET_LEDS:
	MOV R1, R16   ; R1 is used as a temporary register to store the count value
	COM R1        ; Takes Ones compliment because LEDs are active low
	OUT PORTD, R1 ; Turns LEDs on
	RET

; delay function
QDELAY:
	LDI R31, MAX
	AGAIN3:
		LDI R30, MAX
		AGAIN2:
			LDI R29, 25 ; was set to 10 to speed up testing; calculated in report at 25
			AGAIN1:
				NOP
				DEC R29
				BRNE AGAIN1
			DEC R22
			BRNE AGAIN2
		DEC R23
		BRNE AGAIN3
	RET

;;;;		SPEAKER FUNCTIONS	;;;;
; Function to run the buzzer
TURN_ON_SPEAKER:	LDI R31, 0x2F ; change this up depending how long you want it to last
	SQUARE_WAVE:
						CBI PORTE, 4 ; set buzzer to high
						CALL SM_DELAY
						SBI PORTE, 4 ; set buzzer to low
						CALL SM_DELAY
						DEC R31
						BRNE SQUARE_WAVE
					RET

; Delay Function used for the buzzer
SM_DELAY:
	LDI R30, 100				
	OUT_LOOP:
		LDI R29, MAX
		IN_LOOP:
			NOP
			DEC R29
			BRNE IN_LOOP
		DEC R30
		BRNE OUT_LOOP
	RET
;;;;		SPEAKER FUNCTIONS	;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CUSTOM FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;Stopwatch Mode ;;;;
; super function to increment or decrement a value from 0 or 30 according to a clock
STOPWATCH_MODE:
	CALL RESET_COUNT
	CALL SET_LEDS
	CBI PORTD, 7 ; turn LED 9 on
	UP:
		; Check if down if button 8 is pressed (i.e. gets a 0)
		; if not pressed, skip to checking if down
		SBIC PINA, 6 ;
		RJMP DOWN
		; wait until  button 8 is released before continuing
		WAIT_UNTIL_REL1:
			SBIS PINA, 6 ;
			RJMP WAIT_UNTIL_REL1

		; Loop until counter = 30, or button 
		UP_LOOP:
			CP R16, R26 ; check if R16 == R26 (i.e. 30)
			BREQ DOWN
			INC R16
			CALL SET_LEDS
			CBI PORTD, 7
			CALL QDELAY
			; exit out of the increment loop if button 8 is touched
			; otherwise, keep looping until counter = 30
			SBIC PINA, 6
			RJMP UP_LOOP
			UP_LOOP_WAIT_TIL_REL:
				SBIS PINA, 6
				RJMP UP_LOOP_WAIT_TIL_REL
			CALL QDELAY

	DOWN:
		; Check if down if button 8 is pressed (i.e. gets a 0)
		; if not pressed, skip to checking if reset button is pressed
		SBIC PINA, 5 ; Skip next instruction if button8 gets a 0
		RJMP STOP_RESET
		WAIT_UNTIL_REL2:
			SBIS PINA, 5 ; Skip next instruction if button8 gets a 0
			RJMP WAIT_UNTIL_REL2
		DOWN_LOOP:			
			CPI R16, 0 ; check if R16 == 0
			BREQ STOP_RESET
			DEC R16
			CALL SET_LEDS
			CBI PORTD, 7
			CALL QDELAY
			; exit out of the increment loop if button 7 is touched
			SBIC PINA, 5 ; Skip next instruction if button 7 gets a 0
			RJMP DOWN_LOOP
			DOWN_LOOP_WAIT_TIL_REL:
				SBIS PINA, 5
				RJMP DOWN_LOOP_WAIT_TIL_REL
			CALL QDELAY

	; reset the counter and the lights if button 6 is pressed
	STOP_RESET:
		CBI PORTD, 7 ; LED 6 already being used
		SBIC PINA, 4 ; Skip next instruction if button6 gets a 0
		RJMP EXIT_STOPWATCH
		CALL RESET_COUNT
		CALL SET_LEDS
		CBI PORTD, 7

	EXIT_STOPWATCH:
		SBIC PINA, 7 ; Skip next instruction if button9 gets a 0
		RJMP UP
		WAIT_UNTIL_REL3:
			SBIS PINA, 7 ; Skip next instruction if button9 gets a 1
			RJMP WAIT_UNTIL_REL3

		CALL RESET_COUNT ; set counter to 0
		CALL SET_LEDS ; turn all LEDs off
		CALL QDELAY
		RET ; return to main
;;;;Stopwatch Mode;;;;



;;;;Shift Mode;;;;
; super function to shift a single bit left or right from 1 to 64
SHIFT_MODE:
	; set variables, reset leds
	LDI R16, 1
	CALL SET_LEDS
	CBI PORTE, 5 ; turn LED5 on
	CBI PORTD, 7 ; turn LED9 on
	;function only variable

		

	; loop for all shifting operations
	SHIFT_LOOP:
		CALL SET_LEDS
		CBI PORTD, 7
		CALL QDELAY


		;function to multiply by 2 (i.e. shift right)
		CHECK_SHIFT_LEFT:
			; check if button 7 is pressed
			; if pressed, shift left by 1
			; otherwise, jump to shift left
			SBIC PINA, 6
			RJMP CHECK_SHIFT_RIGHT
			; no spamming allowed
			SHIFT_LEFT_WAIT_REL:
				SBIS PINA, 6
				RJMP SHIFT_LEFT_WAIT_REL

			; check to make sure R16 < 64
			; if not, reset to 1 and return to shift loop
			CPI R16, 64
			BREQ RESET_SHIFT_COUNTER

			; shift counter left, return to shift loop
			LSL R16
			RJMP SHIFT_LOOP


		; function to divide by 2 (i.e. shift right)
		CHECK_SHIFT_RIGHT:
			; check if button 6 is pressed
			; if pressed, shift right by 1
			; otherwise, jump to check reset
			SBIC PINA, 5
			RJMP CHECK_SHIFT_RESET
			SHIFT_RIGHT_WAIT_REL:
				SBIS PINA, 5
				RJMP SHIFT_RIGHT_WAIT_REL
			
			; check to make sure R16 > 1
			; if not, reset to 1 and return to shift loop
			CPI R16, 1
			BREQ SET_SHIFT_COUNTER
			
			; shift counter right, return to shift loop
			LSR R16
			RJMP SHIFT_LOOP


		; function to reset shift counter to 1 if button 6 pressed
		CHECK_SHIFT_RESET:
			; check if button 4 is pressed
			; if pressed, reset shift counter
			; otherwise, jump to check exit
			SBIC PINA, 4
			RJMP CHECK_EXIT
			SHIFT_RESET_WAIT_REL:
				SBIS PINA, 4
				RJMP SHIFT_RESET_WAIT_REL
			; reset shift counter to 1, jump to shift loop
			RJMP RESET_SHIFT_COUNTER
		

		; function to exit shifting mode if button 4 is pressed
		CHECK_EXIT:
			; check if button 4 is pressed
			; if pressed, return to main function
			; otherwise, jump back to start of shift loop
			SBIC PINA, 3
			RJMP SHIFT_LOOP
			CHECK_EXIT_WAIT_REL:
				SBIS PINA, 3
				RJMP CHECK_EXIT_WAIT_REL
			; exit shift mode
			RJMP EXIT_SHIFT_MODE


		;set shift counter to 1 (i.e. 0b00000001)
		RESET_SHIFT_COUNTER:
			LDI R16, 1
			RJMP SHIFT_LOOP


		;set shift counter to 64 (i.e. 0b01000000)
		SET_SHIFT_COUNTER:
			LDI R16, 64
			RJMP SHIFT_LOOP


	; exit shift mode, return to main function
	EXIT_SHIFT_MODE:
		; reset counter to 0, turn all LEDs off
		CALL RESET_COUNT
		CALL SET_LEDS
		SBI PORTE, 5 ; turn LED5 off

		; wait a bit, then return to main function
		CALL QDELAY
		RET
;;;;Shift Mode;;;;



;;;;Light Up Mode;;;;
;super function to turn LEDs on and off as you please (exits w/ switch 5)
LIGHT_UP_MODE:
	CALL RESET_COUNT ; set R16 to 0
	CALL SET_LEDS	 ; turn all LEDs off
	CBI PORTE, 5     ; turn LED5 on

	;R24 is used as a temporary variable to store the input of pin A
	LIGHT_UP_LEDS:
		;get the input from the buttons
		IN R24, PINA
		COM R24
		EOR R16, R24

		; wait until all the buttons are unpressed before continuing
		LIGHT_WAIT_TIL_RELEASED_1:
			IN R24, PINA
			COM R24
			CPI R24, 0
			BRNE LIGHT_WAIT_TIL_RELEASED_1

		; turn the leds on
		CALL SET_LEDS
		CALL QDELAY

		; if switch 5 pressed, wait until unpressed and then return to main
		SBIC PINE, 6
		RJMP LIGHT_UP_LEDS
		LIGHT_WAIT_TIL_RELEASED_2:
			SBIS PINE, 6
			RJMP LIGHT_WAIT_TIL_RELEASED_2
		RJMP EXIT_LIGHT_UP_MODE

	; leave light up mode, return to main
	EXIT_LIGHT_UP_MODE:
		SBI PORTE, 5 ; turn LED5 off
		CALL RESET_COUNT
		CALL SET_LEDS
		RET
;;;;Light Up Mode;;;;
