;====================================================================
; AC Control System with Hardcoded Temperature Values
; 
; Created:   December 12, 2025
; Processor: 8086
; Compiler:  MASM32
;
; Before starting simulation set Internal Memory Size to 0x10000
;====================================================================

DATA SEGMENT

   ;======== PPI 1 (F0H - F6H) =========;
   
   PORTA1 EQU 0F0H  ;ADC CONTROL LINES
   PORTB1 EQU 0F2H  ;MODE SET BUTTONS AND TIMER / THERMO DIPSWITCH
   PORTC1 EQU 0F4H  ;MOTOR DRIVER (FOR COMPRESSOR AND FAN)
   CMD_REG_1 EQU 0F6H ; COMMAND REGISTER FOR PPI1
   
   ;======== PPI 2 (F8H - FEH) =========;
    
   PORTA2 EQU 0F8H  ;LCD DATA LINES   
   PORTB2 EQU 0FAH  ;LCD CONTROL PINS  
   PORTC2 EQU 0FCH  ;ADC TEMPERATURE OUTPUT FED AS INPUT
   CMD_REG_2 EQU 0FEH  ; COMMAND REGISTER FOR PPI2
   
   ;======== PPI 3 (D0H - D6H) - NEW =========;
   
   PORTA3 EQU 0D0H  ;COMPRESSOR AND FAN MOTOR SIGNALS
   PORTB3 EQU 0D2H  ;SYSTEM POWER SIGNAL
   PORTC3 EQU 0D4H  ;8253 CLOCK PULSE INPUT
   CMD_REG_3 EQU 0D6H ; COMMAND REGISTER FOR PPI3
   
   ;======== 8253 TIMER (D8H - DEH) - NEW =========;
   
   COUNTER0 EQU 0D8H   ;Counter 0 - 15 second intervals
   COUNTER1 EQU 0DAH   ;Counter 1 - Reserved
   COUNTER2 EQU 0DCH   ;Counter 2 - Reserved
   TIMER_CTRL EQU 0DEH ;Control Word Register
   
   ; ================================= DISPLAY MESSAGES FOR LCD =================================;
   DISP_TEMP DB "TEMPERATURE (C): ","$"
   DISP_TIMER DB "CURRENT TIME SET: 0","$"
   
   DISP_SWING_EN DB "AC SWING: ENABLED", "$"
   DISP_SWING_DISEN DB "AC SWING: DISABLED", "$"
   
   DISP_MODE DB "MODE SET:","$"
   DISP_COOLMODE DB "MODE SET: COOL MODE","$"
   DISP_FANMODE DB "MODE SET: FAN MODE","$"
   
   DISP_SUBMODE DB "SUBMODE SET:","$"
   DISP_ECOMODE DB "SUBMODE SET: ECO    ","$"  ; Added spaces
   DISP_TURBOMODE DB "SUBMODE SET: TURBO  ","$"  ; Added spaces
   
   CLEAR_LINE DB "                    $"  ; 20 spaces to clear a full line  
   
   ; ========== HARDCODED TEMPERATURE STRINGS ==========
   TEMP16 DB "TEMPERATURE (C): 16","$"
   TEMP17 DB "TEMPERATURE (C): 17","$"
   TEMP18 DB "TEMPERATURE (C): 18","$"
   TEMP19 DB "TEMPERATURE (C): 19","$"
   TEMP20 DB "TEMPERATURE (C): 20","$"
   TEMP21 DB "TEMPERATURE (C): 21","$"
   TEMP22 DB "TEMPERATURE (C): 22","$"
   TEMP23 DB "TEMPERATURE (C): 23","$"
   TEMP24 DB "TEMPERATURE (C): 24","$"
   TEMP25 DB "TEMPERATURE (C): 25","$"
   TEMP26 DB "TEMPERATURE (C): 26","$"
   TEMP27 DB "TEMPERATURE (C): 27","$"
   TEMP28 DB "TEMPERATURE (C): 28","$"
   TEMP29 DB "TEMPERATURE (C): 29","$"
   TEMP30 DB "TEMPERATURE (C): 30","$"
   
   ;==================TEMPERATURE VALUE ASSETS ====================;
   LAST_TEMP DB 0FFH     ; Store last displayed temperature
   TEMP_UPDATE_COUNTER DB 0  ; Update every N loops to reduce flicker
   TEMP_ASCII DB "00$"   ; 2 digits + terminator for actual reading
   
   ;===================== TIMER VALUE ASSETS ====================;
   TIMER_ASCII DB '0','$' 
   CURRENT_TIMER DB 1 ;Current Timer Value
   PREV_TIMER_BUTTONS DB 0   
   
   DISP_TIMER_EXPIRED DB "TIMER EXPIRED!      ","$" ;Display Message for Timer Expired!
   
   TIMER_ACTIVE DB 0        ; 0=inactive, 1=active (countdown running)
   TIMER_ELAPSED_15S DB 0   ; Counts 15-second intervals
   
   TIMER_STARTED DB 0       ; 0=not started, 1=user has set timer (inc/dec pressed)
   SYSTEM_SHUTDOWN DB 0     ; 0=normal operation, 1=system shutdown (timer expired) 
   
   ;================ Preset Binary Values for Hours ====================
   HOURS DB 0001B ;1HR
   DB 0010B ;2HRS
   DB 0011B ;3HRS
   DB 0100B ;4HRS
   DB 0101B ;5HRS
   DB 0110B ;6HRS
   DB 0111B ;7HRS
   DB 1000B ;8HRS
   
   PREV_DIP_STATE DB 0FFH  ; Previous DIP switch state (initialize to invalid)
   PREV_CLOCK_STATE DB 0    ; Previous state of PC0 for edge detection                                                       
   
   ;====================== STEPPER MOTOR SEQUENCE VALUES (SWING) ===============
   STEP_SEQUENCE DB 00001000B  ; Step 0: Coil A
                 DB 00001100B  ; Step 1: Coil A + B
                 DB 00000100B  ; Step 2: Coil B
                 DB 00000110B  ; Step 3: Coil B + C
                 DB 00000010B  ; Step 4: Coil C
                 DB 00000011B  ; Step 5: Coil C + D
                 DB 00000001B  ; Step 6: Coil D
                 DB 00001001B  ; Step 7: Coil D + A
   
   STEP_INDEX DB 0             ; Current step index (0-7)
   SWING_ACTIVE DB 0           ; Flag: 0=swing off, 1=swing on
   STEP_COUNTER DB 0           ; Counter for steps   
   SWING_DIRECTION DB 1        ; 1 = Forward, 0 = Backward
   SWING_RANGE DB 40           ; No. of Steps
   
   ;======================= BLOWER FAN RPM VALUES =======================;
   
   ; Fan/Compressor Motor Control
   FAN_MODE DB 0          ; 0=None, 1=FAN, 2=COOL
   SUBMODE DB 0           ; 0=None, 1=ECO, 2=TURBO
   
   ; Speed level mappings (4-bit values for upper nibble)
   SPEED_75_RPM   EQU 0001B   ; Lowest speed  (~1.5V if 12V max)
   SPEED_100_RPM  EQU 0010B   ; Low speed     (~3V)
   SPEED_150_RPM  EQU 0100B   ; Medium-low    (~6V)
   SPEED_200_RPM  EQU 0110B   ; Medium        (~7.5V)
   SPEED_250_RPM  EQU 1000B   ; Medium-high   (~9V)
   SPEED_300_RPM  EQU 1010B   ; High speed    (~10.5V)
   
   ;======================= CURRENT DISPLAY MODE =======================
   CURRENT_DISPLAY_MODE DB 0  ; 0=TEMP, 1=TIMER (prevents flashing updates)
   LCD_DISPLAY_STATE DB 1     ; 0=OFF, 1=ON (default ON)
   PREV_DISPLAY_BUTTON DB 0   ; Previous state of PB0 for edge detection
   
   COMPRESSOR_STATE DB 0    ; Tracks compressor state (0=OFF, 1=ON)
   SYSTEM_POWERED_ON DB 1   ; Tracks overall power state (1=ON by default)
   
   ; ===================== FAN ENABLE STATE VARIABLE =====================
   PORTB2_STATE DB 00H    ; Shadow register for PORTB2 state
                          ; Bits 0-1: LCD control
                          ; Bits 2-3: Fan enable pins
   
   ; Fan Enable bit positions in PORTB2
   FAN_EN1_BIT EQU 00000100B  ; PB2 = bit 2
   FAN_EN2_BIT EQU 00001000B  ; PB3 = bit 3
   FAN_ENABLE_MASK EQU 00001100B  ; Both enable bits (PB2 and PB3)
   
DATA ENDS


;============ DEPENDENCY ASSUMPTIONS ===============
CODE SEGMENT PUBLIC 'CODE'
   ASSUME CS:CODE, DS:DATA
   
; ============ MAIN INITIALIZATION SECTION =============;

START:
   MOV AX, DATA
   MOV DS, AX
   
   ;Setting Up PPI1
   MOV DX, CMD_REG_1 
   MOV AL, 80H
   OUT DX, AL
   
   ;Setting Up PPI2
   MOV DX, CMD_REG_2
   MOV AL, 80H
   OUT DX, AL
   
   ;Setting Up PPI3 (NEW)
   MOV DX, CMD_REG_3
   MOV AL, 89H  ; Port A=output, Port B=input, Port C=input
   OUT DX, AL
   
   ; Initialize timer
   MOV [TIMER_ACTIVE], 0 ;Sets the timer status as Inactive
   MOV [TIMER_STARTED], 0 ;The timer has not started upon initialization
   
   ; Initialize LCD display toggle
   MOV [LCD_DISPLAY_STATE], 1    ; Display starts ON
   MOV [PREV_DISPLAY_BUTTON], 0  ; Button starts unpressed
   
   ; Initialize power state
   MOV [SYSTEM_POWERED_ON], 1    ; System starts powered ON
   MOV [COMPRESSOR_STATE], 1     ; Compressor starts ON
   
   ; Initialize 8253 Timer
   CALL INIT_8253_TIMER
   
   ; Initialize PORTC1 to all zeros (both motors OFF)
   MOV DX, PORTC1
   MOV AL, 00H
   OUT DX, AL
   
   ; Initialize PORTA3 with compressor ON
   MOV DX, PORTA3
   MOV AL, 07H
   OUT DX, AL
   
   ; Initialize motor states
   MOV [FAN_MODE], 0
   MOV [SUBMODE], 0
   MOV [SWING_ACTIVE], 0
   
   ; Initialize timer
   MOV [CURRENT_TIMER], 1
   MOV [PREV_TIMER_BUTTONS], 0
   MOV [CURRENT_DISPLAY_MODE], 0  ; Start with TEMP mode
   
   ;Initializing the LCD
   CALL INIT_LCD  
   CALL DISPLAY

   ;Main loop
   JMP INPUT_LOOP

 ; ============= SYSTEM STATE HANDLING ===============;  
   
INPUT_LOOP:
   ; Check if system is shutdown - if yes, ensure motors stay off and loop
   CMP [SYSTEM_SHUTDOWN], 1
   JNE NORMAL_OPERATION
   
   ; Force motors off continuously during shutdown
   MOV DX, PORTC1
   MOV AL, 00H
   OUT DX, AL
   JMP INPUT_LOOP
   
 ; ============= NORMAL OPERATION UPON SYSTEM ON ===============;  
 
NORMAL_OPERATION:
   ; Step 1: Check inputs and update states
   CALL INPUT_CHECK
   
   ; Step 2: Update swing motor if active
   CMP [SWING_ACTIVE], 1
   JNE SKIP_SWING_UPDATE
   CALL SWING_MOTOR
   
SKIP_SWING_UPDATE:
   ; Step 3: Check timer countdown
   CALL CHECK_TIMER_15S
   
   ; Step 4: Update temperature display if in TEMP mode
   CMP [CURRENT_DISPLAY_MODE], 0
   JNE SKIP_TEMP_UPDATE
   CALL UPDATE_TEMP_DISPLAY_ONLY
   
SKIP_TEMP_UPDATE:
   ; Step 5: Loop back
   JMP INPUT_LOOP
   
INPUT_CHECK:
   ; Read PORTB1 once
   MOV DX, PORTB1
   IN AL, DX
   MOV BH, AL           ; Save original reading
   
   ; Check power button on PPI3 PB0
   CALL CHECK_DISPLAY_TOGGLE
   
   ; Check for inputs related to the timer
   CALL CHECK_TIMER_BUTTONS
   
   ; Check DIP switches for Timer / Thermo (bits 4-5)
   MOV AL, BH           ; Restore original
   AND AL, 00110000B    ; Mask bits 4-5
   MOV CL, 4
   SHR AL, CL           ; Shift to bits 0-1
   
   ; Route to appropriate case
   CMP AL, 00B          ; CASE 00 - TEMP ; SWING DISABLED
   JE CHECK_CASE1
   CMP AL, 01B          ; CASE 01 - TIMER ; SWING DISABLED
   JE CHECK_CASE2
   CMP AL, 10B          ; CASE 10 - TEMP ; SWING ENABLED
   JE CHECK_CASE3
   CMP AL, 11B          ; CASE 11 - TIMER; SWING ENABLED
   JE CHECK_CASE4
   JMP CHECK_BUTTONS    ; No valid case, check buttons

CHECK_CASE1:
   ; CASE 00 - TEMPERATURE MODE, SWING DISABLED
   MOV [SWING_ACTIVE], 0
   MOV [CURRENT_DISPLAY_MODE], 0  ; Set to TEMPERATURE display
   MOV [TIMER_ACTIVE], 1           ; Deactivate timer countdown
   MOV AL, 00B
   CMP AL, [PREV_DIP_STATE]
   JE SKIP_CASE1
   MOV [PREV_DIP_STATE], AL
   
   ; CLEAR LINE BEFORE DISPLAYING TEMP
   LEA SI, CLEAR_LINE
   MOV AL, 080H
   CALL INST_CTRL
   CALL DISP_STR
   
   CALL UPDATE_TEMP_DISPLAY_ONLY
   LEA SI, CLEAR_LINE
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
   LEA SI, DISP_SWING_DISEN
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
SKIP_CASE1:
   JMP CHECK_BUTTONS

CHECK_CASE2:
   ; CASE 01 - TIMER MODE, SWING DISABLED
   MOV [SWING_ACTIVE], 0
   MOV [CURRENT_DISPLAY_MODE], 1  ; Set to TIMER display
   MOV [TIMER_ACTIVE], 1           ; Activate timer countdown
   
   MOV AL, 01B
   CMP AL, [PREV_DIP_STATE]
   JE SKIP_CASE2
   MOV [PREV_DIP_STATE], AL
   LEA SI, DISP_TIMER
   MOV AL, 080H
   CALL INST_CTRL
   CALL DISP_STR
   CALL READ_TIMER
   LEA SI, TIMER_ASCII
   CALL DISP_STR
   LEA SI, CLEAR_LINE
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
   LEA SI, DISP_SWING_DISEN
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
SKIP_CASE2:
   JMP CHECK_BUTTONS

CHECK_CASE3:
   ; CASE 10 - TEMPERATURE MODE, SWING ENABLED
   MOV [SWING_ACTIVE], 1
   MOV [CURRENT_DISPLAY_MODE], 0  ; Set to TEMPERATURE display
   MOV [TIMER_ACTIVE], 1          ; Deactivate timer countdown
   
   MOV AL, 10B
   CMP AL, [PREV_DIP_STATE]
   JE SKIP_CASE3
   MOV [PREV_DIP_STATE], AL
   
   ; CLEAR LINE BEFORE DISPLAYING TEMP (FROM ALMOST_THERE)
   LEA SI, CLEAR_LINE
   MOV AL, 080H
   CALL INST_CTRL
   CALL DISP_STR
   
   CALL UPDATE_TEMP_DISPLAY_ONLY
   
   ; CLEAR SECOND LINE FIRST - THIS IS THE KEY FIX FROM ALMOST_THERE
   LEA SI, CLEAR_LINE
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
   
   LEA SI, DISP_SWING_EN
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
SKIP_CASE3:
   CALL SWING_MOTOR
   JMP CHECK_BUTTONS

CHECK_CASE4:
   ; CASE 11 - TIMER MODE, SWING ENABLED
   MOV [SWING_ACTIVE], 1
   MOV [CURRENT_DISPLAY_MODE], 1
   MOV [TIMER_ACTIVE], 1
   
   MOV AL, 11B
   CMP AL, [PREV_DIP_STATE]
   JE SKIP_CASE4
   MOV [PREV_DIP_STATE], AL
   
   LEA SI, DISP_TIMER
   MOV AL, 080H
   CALL INST_CTRL
   CALL DISP_STR
   CALL READ_TIMER
   LEA SI, TIMER_ASCII
   CALL DISP_STR
   
   LEA SI, CLEAR_LINE
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
   
   LEA SI, DISP_SWING_EN
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
   
SKIP_CASE4:
   JMP CHECK_BUTTONS

CHECK_BUTTONS:
   MOV AL, BH ;Load entry into BH
   AND AL, 00001111B ;Mask the upper 4 bits  
   
   ;Case 0001: FAN MODE
   CMP AL, 0001B
   JE FAN_DISPLAY
   
   ;Case 0010: COOL MODE
   CMP AL, 0010B
   JE COOL_DISPLAY
   
   ;Case 0100: ECO MODE
   CMP AL, 0100B
   JE ECO_DISPLAY
   
   ;Case 1000: TURBO MODE
   CMP AL, 1000B
   JE TURBO_DISPLAY
   RET

FAN_DISPLAY:
   MOV [FAN_MODE], 1 ;Activate FAN MODE speed config for fan motor
   
   LEA SI, CLEAR_LINE ;Clear line on LCD First
   MOV AL, 094H
   CALL INST_CTRL
   CALL DISP_STR
   
   LEA SI, DISP_FANMODE ;Display "Fan Mode" on the LCD
   MOV AL, 094H
   CALL INST_CTRL
   CALL DISP_STR
   CALL UPDATE_MOTOR_SPEED
   RET

COOL_DISPLAY:
   MOV [FAN_MODE], 2 ;Activate COOL MODE speed config for fan motor
   
   LEA SI, CLEAR_LINE ;Clear line on LCD First
   MOV AL, 094H
   CALL INST_CTRL
   CALL DISP_STR
   
   LEA SI, DISP_COOLMODE ;Display "Cool Mode" on the LCD
   MOV AL, 094H
   CALL INST_CTRL
   CALL DISP_STR
   CALL UPDATE_MOTOR_SPEED
   RET

ECO_DISPLAY:
   MOV [SUBMODE], 1 ;Activate ECO submode speed config for fan motor
   
   LEA SI, CLEAR_LINE ;Clear line on LCD First
   MOV AL, 094H
   CALL INST_CTRL
   CALL DISP_STR
   
   
   LEA SI, DISP_ECOMODE  ;Display "Eco Mode" on the LCD
   MOV AL, 0D4H
   CALL INST_CTRL
   CALL DISP_STR
   CALL UPDATE_MOTOR_SPEED
   RET

TURBO_DISPLAY:
   MOV [SUBMODE], 2 ;Activate TURBO submode speed config for fan motor
   
   LEA SI, CLEAR_LINE ;Clear line on LCD First
   MOV AL, 094H
   CALL INST_CTRL
   CALL DISP_STR
   
   LEA SI, DISP_TURBOMODE  ;Display "Turbo Mode" on the LCD
   MOV AL, 0D4H
   CALL INST_CTRL
   CALL DISP_STR
   CALL UPDATE_MOTOR_SPEED
   RET

; ================== ADC READING WITH TEMPERATURE BIT COMPARISON =====================

READ_ADC_AND_COMPARE PROC

   ;Push in all general purpose registers
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Step 1: Select ADC channel (IN0 = 000 for LM35)
    MOV DX, PORTA1
    MOV AL, 00000000B
    OUT DX, AL
    CALL DELAY_ADC
    
    ; Step 2: Pulse ALE high (bit 3)
    MOV AL, 00001000B
    OUT DX, AL
    CALL DELAY_ADC
    MOV AL, 00000000B
    OUT DX, AL
    CALL DELAY_ADC
    
    ; Step 3: Pulse START high (bit 4)
    MOV AL, 00010000B
    OUT DX, AL
    CALL DELAY_ADC
    MOV AL, 00000000B
    OUT DX, AL
    CALL DELAY_ADC
    
    ; Step 4: Wait for conversion
    CALL DELAY_CONVERSION
    
    ; Step 5: Enable output (OE high - bit 5)
    MOV AL, 00100000B
    OUT DX, AL
    CALL DELAY_ADC
    
    ; Step 6: Read the data from PORTC2
    MOV DX, PORTC2
    IN AL, DX
    MOV CL, AL            ; Save ADC value in CL
    
    ; ===== HARDCODED TEMPERATURE COMPARISON =====
    
    ;NOTE: The binary values are read from right to left (due to the ADC's bit positioning)
    
    CMP CL, 00001000B ;-> 10000 -> 16
    JE TEMP_16
    CMP CL, 10001000B ;-> 10001 -> 17
    JE TEMP_17
    CMP CL, 01001000B ;-> 10010 -> 18
    JE TEMP_18
    CMP CL, 11001000B ;-> 10011 -> 19
    JE TEMP_19
    CMP CL, 00101000B ;-> 10100 -> 20
    JE TEMP_20
    CMP CL, 10101000B ;-> 10101 -> 21
    JE TEMP_21
    CMP CL, 01101000B ;-> 10110 -> 22
    JE TEMP_22
    CMP CL, 11101000B ;-> 10111 -> 23
    JE TEMP_23
    CMP CL, 00011000B ;-> 11000 -> 24
    JE TEMP_24
    CMP CL, 10011000B ;-> 11001 -> 25
    JE TEMP_25
    CMP CL, 01011000B ;-> 11010 -> 26
    JE TEMP_26
    CMP CL, 11011000B ;-> 11011 -> 27
    JE TEMP_27
    CMP CL, 00111000B ;-> 11100 -> 28
    JE TEMP_28
    CMP CL, 10111000B ;-> 11101 -> 29
    JE TEMP_29
    CMP CL, 01111000B ;-> 11110 -> 30
    JE TEMP_30
    CMP CL, 11111000B ;-> 11111 -> 31 or greater
    JG TEMP_30
    
;============= TEMPERATURE CORRESPONDENT DISPLAY LABELS =============;
TEMP_16:
    LEA SI, TEMP16
    JMP DISPLAY_TEMP_STR
TEMP_17:
    LEA SI, TEMP17
    JMP DISPLAY_TEMP_STR
TEMP_18:
    LEA SI, TEMP18
    JMP DISPLAY_TEMP_STR
TEMP_19:
    LEA SI, TEMP19
    JMP DISPLAY_TEMP_STR
TEMP_20:
    LEA SI, TEMP20
    JMP DISPLAY_TEMP_STR
TEMP_21:
    LEA SI, TEMP21
    JMP DISPLAY_TEMP_STR
TEMP_22:
    LEA SI, TEMP22
    JMP DISPLAY_TEMP_STR
TEMP_23:
    LEA SI, TEMP23
    JMP DISPLAY_TEMP_STR
TEMP_24:
    LEA SI, TEMP24
    JMP DISPLAY_TEMP_STR
TEMP_25:
    LEA SI, TEMP25
    JMP DISPLAY_TEMP_STR
TEMP_26:
    LEA SI, TEMP26
    JMP DISPLAY_TEMP_STR
TEMP_27:
    LEA SI, TEMP27
    JMP DISPLAY_TEMP_STR
TEMP_28:
    LEA SI, TEMP28
    JMP DISPLAY_TEMP_STR
TEMP_29:
    LEA SI, TEMP29
    JMP DISPLAY_TEMP_STR
TEMP_30:
    LEA SI, TEMP30
    
    
DISPLAY_TEMP_STR:  	 ; Check if temperature changed
    MOV AL, CL           ; CL has current ADC value (from READ_ADC_AND_COMPARE)
    CMP AL, [LAST_TEMP]
    JE SKIP_CLEAR        ; If same temp, skip clearing
    
    MOV [LAST_TEMP], AL  ; Save new temp
    
    ; Only clear if temperature actually changed
    PUSH SI
    LEA SI, CLEAR_LINE
    MOV AL, 080H
    CALL INST_CTRL
    CALL DISP_STR
    POP SI
    
SKIP_CLEAR:
    MOV AL, 080H          ; Line 1 position
    CALL INST_CTRL
    CALL DISP_STR
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
READ_ADC_AND_COMPARE ENDP

UPDATE_TEMP_DISPLAY_ONLY PROC
    PUSH AX
    PUSH SI 	;Push the source index to the start
    
    CALL READ_ADC_AND_COMPARE	;Call function to read and compare ADC reading
    
    POP SI 	;Pop values from source index
    POP AX
    RET
UPDATE_TEMP_DISPLAY_ONLY ENDP

; ===================== LCD CONTROL FUNCTIONS =====================

INST_CTRL PROC ;INSTRUCTION CONTROL
   PUSH AX
   PUSH DX
   MOV DX, PORTA2
   OUT DX, AL
   MOV DX, PORTB2
   MOV AL, 02H
   OUT DX, AL
   CALL DELAY_1MS
   MOV DX, PORTB2
   MOV AL, 00H
   OUT DX, AL
   POP DX
   POP AX
   RET
INST_CTRL ENDP

DATA_CTRL PROC ;DATA CONTROL
   PUSH AX
   PUSH DX
   MOV DX, PORTA2
   OUT DX, AL
   MOV DX, PORTB2
   MOV AL, 03H
   OUT DX, AL
   CALL DELAY_1MS
   MOV DX, PORTB2
   MOV AL, 01H
   OUT DX, AL
   POP DX
   POP AX
   RET
DATA_CTRL ENDP

INIT_LCD PROC ;LCD INITIALIZATION
   MOV AL, 38H
   CALL INST_CTRL
   MOV AL, 08H
   CALL INST_CTRL
   MOV AL, 01H
   CALL INST_CTRL
   MOV AL, 06H
   CALL INST_CTRL
   MOV AL, 0CH
   CALL INST_CTRL
   RET
INIT_LCD ENDP

DISP_STR PROC ;LABEL TO DISPLAY A SINGLE STRING
DISP_LOOP:
   MOV AL, [SI]
   CMP AL, '$'
   JE DISP_END
   CALL DATA_CTRL
   INC SI
   JMP DISP_LOOP
DISP_END:
   RET
DISP_STR ENDP

DISPLAY PROC  ;LABEL TO DISPLAY 4 STANDARD LINES ON LCD
   CALL READ_ADC_AND_COMPARE  ;Read ADC and display temperature
   LEA SI, DISP_SWING_DISEN  ;Initially display "Swing Disabled"
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
   LEA SI, DISP_MODE ;Display the Current Mode
   MOV AL, 094H
   CALL INST_CTRL
   CALL DISP_STR
   LEA SI, DISP_SUBMODE ;Display the Current Sub-Mode
   MOV AL, 0D4H
   CALL INST_CTRL
   CALL DISP_STR
   RET
DISPLAY ENDP

;===================== MODIFIED SWING MOTOR CONTROL =====================

SWING_MOTOR PROC
   ; Check if system is shutdown OR powered off
   CMP [SYSTEM_SHUTDOWN], 1
   JE SWING_MOTOR_STOP
   CMP [SYSTEM_POWERED_ON], 0     ; *** NEW CHECK ***
   JE SWING_MOTOR_STOP            ; Stop if system is powered off
   
   CMP [SWING_ACTIVE], 1  	  ;Check if the Motor Swing flag is enabled
   JNE SWING_MOTOR_STOP		  ;If it isn't, stop the motor
   
   PUSH BX
   PUSH AX
   PUSH DX
   
   ; Get next step pattern
   LEA BX, STEP_SEQUENCE
   MOV AL, [STEP_INDEX]
   XLAT
   MOV BL, AL
   
   ; Read current PORTC1 state
   MOV DX, PORTC1
   IN AL, DX
   AND AL, 11110000B
   
   ; Combine fan motor (upper) with swing motor (lower)
   OR AL, BL
   OUT DX, AL
   
   CALL DELAY_SWING_STEP
   
   ; Increment step index
   INC [STEP_INDEX]
   CMP [STEP_INDEX], 8
   JL SWING_CONTINUE
   MOV [STEP_INDEX], 0
   
SWING_CONTINUE: 
   ; Handle step counter and direction
   INC [STEP_COUNTER]	;Increment the step counter  by 1
   MOV AL, [STEP_COUNTER] ;Load in the new step counter value
   CMP AL, [SWING_RANGE]  ;Check if it falls within swing range
   JL SWING_EXIT	;If it's larger, get out of swing state
   MOV [STEP_COUNTER], 0	
   XOR [SWING_DIRECTION], 1
   
SWING_EXIT: ;Exit from the Swing State
   POP DX
   POP AX
   POP BX
   RET
   
SWING_MOTOR_STOP: ;Stop the motor from swinging
   PUSH AX
   PUSH DX
   
   ; Turn off swing motor while preserving fan motor
   MOV DX, PORTC1
   IN AL, DX
   AND AL, 11110000B      ; Keep fan motor, clear swing motor
   OUT DX, AL
   
   ; Reset swing motor state
   MOV [STEP_COUNTER], 0
   MOV [SWING_DIRECTION], 1
   MOV [STEP_INDEX], 0
   
   POP DX
   POP AX
   RET
SWING_MOTOR ENDP

;===================== MODIFIED MOTOR SPEED CONTROL =====================

UPDATE_MOTOR_SPEED PROC
   ;Push in general puspose registers
   PUSH AX
   PUSH BX
   
   CMP [SYSTEM_SHUTDOWN], 1 	;Check if the system shut down flag is enabled
   JE UPDATE_MOTOR_EXIT		;If it is, update to exit the motor control algorithm
   CMP [SYSTEM_POWERED_ON], 0	;Same logic if the powered on flag is disabled
   JE UPDATE_MOTOR_EXIT
   
   MOV BL, 0
   
   CMP [FAN_MODE], 1		;If fan mode enabled
   JE CHECK_FAN_SUBMODE		;Check for the submode
   CMP [FAN_MODE], 2		;If cool mode enabled
   JE CHECK_COOL_SUBMODE	;Check for the submode
   JMP APPLY_SPEED		;Apply respective speed
   
CHECK_FAN_SUBMODE:
   CMP [SUBMODE], 1		;Submode = ECO
   JE FAN_ECO_SPEED		;Fan Eco Speed
   CMP [SUBMODE], 2		;Submode = TURBO
   JE FAN_TURBO_SPEED		;Fan Turbo Speed
   MOV BL, SPEED_200_RPM	;Apply regular fan speed	
   JMP APPLY_SPEED	
   
FAN_ECO_SPEED:
   MOV BL, SPEED_100_RPM	;Apply fan eco speed
   JMP APPLY_SPEED
   
FAN_TURBO_SPEED:
   MOV BL, SPEED_300_RPM	;Apply fan turbo speed
   JMP APPLY_SPEED
   
CHECK_COOL_SUBMODE:
   CMP [SUBMODE], 1		;Submode = ECO
   JE COOL_ECO_SPEED		;Cool Eco Speed
   CMP [SUBMODE], 2		;Submode = TURBO
   JE COOL_TURBO_SPEED		;Cool Turbo Speed
   MOV BL, SPEED_150_RPM	;Apply regular cool speed
   JMP APPLY_SPEED
   
COOL_ECO_SPEED:
   MOV BL, SPEED_75_RPM		;Apply cool eco speed
   JMP APPLY_SPEED
   
COOL_TURBO_SPEED:
   MOV BL, SPEED_250_RPM	;Apply cool turbo speed
   
APPLY_SPEED:
   CALL ENABLE_FAN_MOTOR	;Enable the fan motor
   CALL SET_FAN_MOTOR_SPEED	;Call upon the speed setter algorithm
   
UPDATE_MOTOR_EXIT:
   POP BX
   POP AX
   RET
UPDATE_MOTOR_SPEED ENDP

; ===================== MODIFIED FAN MOTOR SPEED SETTER ===================
SET_FAN_MOTOR_SPEED PROC
   PUSH AX
   PUSH DX
   
   ;Check for system status
   CMP [SYSTEM_SHUTDOWN], 1
   JE SET_SPEED_EXIT
   CMP [SYSTEM_POWERED_ON], 0
   JE SET_SPEED_EXIT
   
   ;Load in the Fan speed
   MOV DX, PORTC1
   IN AL, DX
   AND AL, 00001111B
   MOV AH, BL
   MOV CL, 4
   SHL AH, CL
   OR AL, AH
   OUT DX, AL
   
SET_SPEED_EXIT:
   POP DX
   POP AX
   RET
SET_FAN_MOTOR_SPEED ENDP

; ===================== FAN ENABLE / DISABLE CONTROL PROCEDURES =====================
ENABLE_FAN_MOTOR PROC
   PUSH AX
   PUSH DX
   
   ; Update shadow register
   MOV AL, [PORTB2_STATE]
   OR AL, FAN_ENABLE_MASK    ; Set PB2 and PB3 high
   MOV [PORTB2_STATE], AL    ; Save to shadow register
   
   ; Write to port
   MOV DX, PORTB2
   OUT DX, AL
   
   POP DX
   POP AX
   RET
ENABLE_FAN_MOTOR ENDP

DISABLE_FAN_MOTOR PROC
   PUSH AX
   PUSH DX
   
   ; Update shadow register
   MOV AL, [PORTB2_STATE]
   AND AL, 11110011B         ; Clear PB2 and PB3, keep LCD bits (PB0, PB1)
   MOV [PORTB2_STATE], AL    ; Save to shadow register
   
   ; Write to port
   MOV DX, PORTB2
   OUT DX, AL
   
   POP DX
   POP AX
   RET
DISABLE_FAN_MOTOR ENDP

;========================= TIMER CONTROL ========================

INIT_8253_TIMER PROC
   ; Step 1: Configure Counter 0 control word
   MOV DX, TIMER_CTRL
   MOV AL, 00110110B  ; 36H - Counter 0, LSB/MSB, Mode 3, Binary
   OUT DX, AL
   
   ; Small delay after control word
   CALL DELAY_ADC
   
   ; Step 2: Load count value for 5000 Hz input clock
   MOV DX, COUNTER0
   
   ; Load LSB first
   MOV AL, 88H        ; Low byte of 1388H (5000 decimal)
   OUT DX, AL
   CALL DELAY_ADC     ; Small delay between byte writes
   
   ; Load MSB second  
   MOV AL, 13H        ; High byte of 1388H
   OUT DX, AL
   CALL DELAY_ADC
   
   ; Counter should now start outputting square wave
   RET
INIT_8253_TIMER ENDP

CHECK_TIMER_15S PROC
   PUSH AX
   PUSH DX
   PUSH BX
   
   ; Check if timer mode is active AND timer has been started by user
   CMP [TIMER_ACTIVE], 0
   JE NO_TIMER_CHECK
   CMP [TIMER_STARTED], 0
   JE NO_TIMER_CHECK
   
   ; Read PC0 from PORTC3 to check 8253A output clock
   MOV DX, PORTC3
   IN AL, DX
   AND AL, 01H        ; Isolate PC0 bit
   MOV BL, AL         ; Current clock state in BL
   
   ; Check for rising edge (0 -> 1 transition)
   MOV AL, [PREV_CLOCK_STATE]
   CMP AL, 0
   JNE CHECK_FALLING   ; Was already high, check for falling edge
   
   ; Previous was 0, check if current is 1 (rising edge)
   CMP BL, 1
   JNE UPDATE_PREV_STATE
   
   ; Rising edge detected - increment counter
   INC [TIMER_ELAPSED_15S]
   MOV AL, [TIMER_ELAPSED_15S]
   
   CMP AL, 5         ; 60 pulses = 1 minute (for testing/faster countdown)
   JL UPDATE_PREV_STATE
   
   ; 1 minute elapsed - decrement timer
   MOV [TIMER_ELAPSED_15S], 0
   
   ; Only decrement if timer > 0
   MOV AL, [CURRENT_TIMER]
   CMP AL, 0
   JLE TIMER_EXPIRED_HANDLER
   
   DEC AL
   MOV [CURRENT_TIMER], AL
   
   ; Update display if in timer mode
   CMP [CURRENT_DISPLAY_MODE], 1
   JNE UPDATE_PREV_STATE
   CALL UPDATE_TIMER_DISPLAY
   
   ; Check if timer reached 0
   CMP AL, 0
   JE TIMER_EXPIRED_HANDLER
   JMP UPDATE_PREV_STATE

CHECK_FALLING:
   ; For more reliable detection, you can also check falling edge
   ; Current implementation focuses on rising edge only
   JMP UPDATE_PREV_STATE
   
UPDATE_PREV_STATE:
   MOV [PREV_CLOCK_STATE], BL
   JMP NO_COUNTDOWN
   
TIMER_EXPIRED_HANDLER:
   ; Timer has expired - reset everything
   MOV [TIMER_ACTIVE], 0
   MOV [TIMER_STARTED], 0
   MOV [TIMER_ELAPSED_15S], 0
   MOV [CURRENT_TIMER], 1     ; Reset to 1 hour default
   MOV [PREV_CLOCK_STATE], 0
   
   ; Display "TIMER EXPIRED" message
   PUSH SI
   LEA SI, DISP_TIMER_EXPIRED
   MOV AL, 080H
   CALL INST_CTRL
   CALL DISP_STR
   
   ; Clear second line
   LEA SI, CLEAR_LINE
   MOV AL, 0C0H
   CALL INST_CTRL
   CALL DISP_STR
   POP SI
   
   ; Wait a moment
   CALL DELAY_TIMER_EXPIRED
   
   ; Turn off LCD display
   MOV AL, 08H        ; Display OFF command
   CALL INST_CTRL
   
   ; Update display state flag
   MOV [LCD_DISPLAY_STATE], 0
   
   ; Stop all motors
   MOV DX, PORTC1
   MOV AL, 00H        ; Turn off both fan motor and swing motor
   OUT DX, AL
   
   ; Reset motor states
   MOV [FAN_MODE], 0
   MOV [SUBMODE], 0
   MOV [SWING_ACTIVE], 0
   
   ; Turn OFF compressor and fan enable on PORTA3
   MOV DX, PORTA3
   IN AL, DX
   AND AL, 11111000B  ; Clear bit 0 (compressor)
   OUT DX, AL
   MOV [COMPRESSOR_STATE], 0
   
   ; Reset to temperature mode (for when display turns back on)
   MOV [CURRENT_DISPLAY_MODE], 0
   MOV [PREV_DIP_STATE], 0FFH  ; Force refresh on next check
   
NO_COUNTDOWN:
NO_TIMER_CHECK:
   POP BX
   POP DX
   POP AX
   RET
CHECK_TIMER_15S ENDP

DELAY_TIMER_EXPIRED PROC
   PUSH CX
   PUSH BX
   MOV CX, 1000     ; Outer loop
DELAY_OUTER:
   MOV BX, 1000     ; Inner loop
DELAY_INNER:
   NOP
   DEC BX
   JNZ DELAY_INNER
   LOOP DELAY_OUTER
   POP BX
   POP CX
   RET
DELAY_TIMER_EXPIRED ENDP

CHECK_TIMER_BUTTONS PROC
   PUSH AX
   PUSH BX
   PUSH DX
   
   MOV DX, PORTB1
   IN AL, DX
   MOV BL, AL
   
   ; Check if we're in timer mode (bit 4 of DIP switch = 1)
   AND AL, 00110000B
   MOV CL, 4
   SHR AL, CL
   TEST AL, 01B        ; Check if timer mode is active
   JZ SKIP_TIMER_BUTTONS
   
   ; Check timer buttons (bits 6-7)
   MOV AL, BL
   AND AL, 11000000B
   CMP AL, [PREV_TIMER_BUTTONS]
   JE SKIP_TIMER_BUTTONS
   MOV [PREV_TIMER_BUTTONS], AL
   
   ; Check which button was pressed
   TEST AL, 01000000B  ; Increment button (bit 6)
   JNZ TIMER_INCREMENT
   TEST AL, 10000000B  ; Decrement button (bit 7)
   JNZ TIMER_DECREMENT
   JMP SKIP_TIMER_BUTTONS
   
TIMER_INCREMENT:
   MOV AL, [CURRENT_TIMER]
   CMP AL, 8           ; Max 8 hours
   JGE SKIP_TIMER_BUTTONS
   INC AL
   MOV [CURRENT_TIMER], AL
   MOV [TIMER_STARTED], 1    ; Mark timer as user-configured
   MOV [TIMER_ELAPSED_15S], 0 ; Reset elapsed counter
   CALL UPDATE_TIMER_DISPLAY
   JMP SKIP_TIMER_BUTTONS
   
TIMER_DECREMENT:
   MOV AL, [CURRENT_TIMER]
   CMP AL, 1           ; Min 1 hour
   JLE SKIP_TIMER_BUTTONS
   DEC AL
   MOV [CURRENT_TIMER], AL
   MOV [TIMER_STARTED], 1    ; Mark timer as user-configured
   MOV [TIMER_ELAPSED_15S], 0 ; Reset elapsed counter
   CALL UPDATE_TIMER_DISPLAY
   
SKIP_TIMER_BUTTONS:
   POP DX
   POP BX
   POP AX
   RET
CHECK_TIMER_BUTTONS ENDP

; ===================== POWER BUTTON CONTROL =====================

CHECK_DISPLAY_TOGGLE PROC
   PUSH AX
   PUSH DX
   
   ; Read PB0 from PORTB3 (PPI3)
   MOV DX, PORTB3
   IN AL, DX
   AND AL, 01H        ; Isolate PB0 bit
   
   ; Check for button press (rising edge: 0 -> 1)
   CMP AL, [PREV_DISPLAY_BUTTON]
   JE NO_TOGGLE       ; No change, exit
   
   ; Save current button state
   MOV [PREV_DISPLAY_BUTTON], AL
   
   ; Only toggle on rising edge (button pressed)
   CMP AL, 1
   JNE NO_TOGGLE
   
   ; Toggle power state
   MOV AL, [SYSTEM_POWERED_ON]
   XOR AL, 1          ; Toggle between 0 and 1
   MOV [SYSTEM_POWERED_ON], AL
   
   ; Apply the toggle
   CMP AL, 0
   JE TURN_SYSTEM_OFF
   
   ; ===== TURN SYSTEM ON =====
   MOV AL, 0CH        ; Display ON, Cursor OFF
   CALL INST_CTRL
   MOV [LCD_DISPLAY_STATE], 1
   
   ; Refresh current display based on mode
   MOV [PREV_DIP_STATE], 0FFH  ; Force refresh
   
   ; Turn ON compressor on PORTA3
   MOV DX, PORTA3
   IN AL, DX
   OR AL, 07H         ; Set bit 0 (compressor)
   OUT DX, AL
   MOV [COMPRESSOR_STATE], 1
   
   JMP NO_TOGGLE
   
   ; ===== TURN SYSTEM OFF =====
TURN_SYSTEM_OFF:
   ; Turn display OFF
   MOV AL, 08H        ; Display OFF command
   CALL INST_CTRL
   MOV [LCD_DISPLAY_STATE], 0
   
   ; Turn OFF all motors
   MOV DX, PORTC1
   MOV AL, 00H        ; Turn off both fan and swing motors
   OUT DX, AL
   
   ; Turn OFF compressor on PORTA3
   MOV DX, PORTA3
   IN AL, DX
   AND AL, 11111110B  ; Clear bit 0 (compressor)
   OUT DX, AL
   MOV [COMPRESSOR_STATE], 0
   
   ; Reset motor states
   MOV [FAN_MODE], 0
   MOV [SUBMODE], 0
   MOV [SWING_ACTIVE], 0
   
NO_TOGGLE:
   POP DX
   POP AX
   RET
CHECK_DISPLAY_TOGGLE ENDP

UPDATE_TIMER_DISPLAY PROC
   PUSH AX
   PUSH SI
   
   MOV AL, 093H
   CALL INST_CTRL
   MOV AL, [CURRENT_TIMER]
   ADD AL, 30H
   MOV DX, PORTA2
   OUT DX, AL
   CALL DATA_CTRL
   
   POP SI
   POP AX
   RET
UPDATE_TIMER_DISPLAY ENDP

READ_TIMER PROC
   PUSH AX
   
   MOV AL, [CURRENT_TIMER]
   ADD AL, 30H
   MOV [TIMER_ASCII], AL
   MOV BYTE PTR [TIMER_ASCII + 1], '$'
   
   POP AX
   RET
READ_TIMER ENDP

; ===================== DELAY ROUTINES =====================

DELAY_ADC PROC
   PUSH CX
   MOV CX, 0010H
   LOOP_DELAY_ADC:
   NOP
   LOOP LOOP_DELAY_ADC
   POP CX
   RET
DELAY_ADC ENDP

DELAY_CONVERSION PROC
   PUSH CX
   MOV CX, 0100H
   LOOP_DELAY_CONVERSION:
   NOP
   LOOP LOOP_DELAY_CONVERSION
   POP CX
   RET
DELAY_CONVERSION ENDP

DELAY_1MS PROC
   MOV BX, 02CAH
L1:
   DEC BX
   NOP
   JNZ L1
   RET
DELAY_1MS ENDP

; ===================== SWING MOTOR DELAY =====================

DELAY_SWING_STEP PROC
   PUSH CX
   PUSH BX
   MOV CX, 0050H     ; Adjust this value for optimal swing speed
DELAY_SWING_OUTER:
   MOV BX, 0020H
DELAY_SWING_INNER:
   NOP
   DEC BX
   JNZ DELAY_SWING_INNER
   LOOP DELAY_SWING_OUTER
   POP BX
   POP CX
   RET
DELAY_SWING_STEP ENDP


CODE ENDS
END START