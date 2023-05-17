; CS 278-1 Final Project
;
; Created: 4/27/2023
; Author : Wes and Cade
;
; compile with:
; gavrasm.exe -b main.asm
; 
; upload with:
; avrdude -c arduino -p atmega328p -P COM4 -U main.hex
;
; Resources:
; ----------
;  https://whitgit.whitworth.edu/2023/spring/CS-278-1/in_class/-/blob/main/Directives_EEPROM_class/source/mem_testing_solution.asm
;  Scott Office Hours
;  https://cdn-shop.adafruit.com/product-files/1138/SK6812+LED+datasheet+.pdf
;
; Project Demo Links:
; -------------------
;  -VIDEO LINKS: https://www.youtube.com/shorts/U3yyU9lK8Zc | https://www.youtube.com/shorts/CwkMbfWHXT4


.DEVICE ATmega328p ;Define the correct device
;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt Vectors ;;
;;;;;;;;;;;;;;;;;;;;;;;

.DEF LED_COUNT = r24        ; Defines a register to use for LED count used throughout the program
.DEF WEATHER_TYPE = r23     ; Defines a register to use for the weather type throughout the program


; Runs the code at the memory location
; reti / nop is to simply 'return' from the interrupt if it triggers (i.e. the default is to do nothing)
.cseg
.org 000000 ; Start at memory location 0
	rjmp ChipSetUp ; Reset vector
	nop
	reti ; INT0
	nop
	reti ; INT1
	nop
	reti ; PCI0
	nop
	reti ; PCI1
	nop
	reti ; PCI2
	nop
	reti ; WDT
	nop
	reti ; OC2A
	nop
	reti ; OC2B
	nop
	reti ; OVF2
	nop
	reti ; ICP1
	nop
	reti ; OC1A
	nop
	reti ; OC1B
	nop
	reti ; OVF1
	nop
	reti ; OC0A
	nop
	reti ; OC0B
	nop
	reti ; OVF0
	nop
	reti ; SPI
	nop
	rjmp int_usart_rx ; URXC
	nop
	reti ; UDRE
	nop
	reti ; UTXC
	nop
	reti ; ADCC
	nop
	reti ; ERDY
	nop
	reti ; ACI
	nop
	reti ; TWI
	nop
	reti ; SPMR
	nop 


;--------------------------------------------------------------------------------------
; USART RX INTERRUPT HANDLER:
; ---------------------------
int_usart_rx:
	push r16			; Push r16 onto the stack - this register is used to store from UDR0	
	push r17			; Push r17 onto the stack
	push r18            ; Push r18 onto the stack

	call resetPixels    ; Call the resetPixel subroutine, this will clear the ring of all color - just used to ensure the only color showing is the correct one from run to run

	lds r16, UDR0		; Load the first bit of information being sent to board
	cpi r16, $00		; Compare the first part of the message to $00 to see if it is a correct message type
	breq processMsg		; If message from script starts with the proper value begin processing the message
	rjmp endRx			; If message from python script does not start with $00 then exit the interrupt 

; processMsg:
; -> Acts as sort of a filter
; -> Checks the type of weather it is today
; -> Based off that it branches to the correct way to process that information
; -> First few lines are crucial - it waits for the 
processMsg:
	lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp processMsg		; If the receive buffer is empty, continue waiting

	lds r16, UDR0		; Load the next byte from the receive buffer

	cpi r16, $10		; Check if the value is $10 (clear weather)
	breq setClear		; If the value is $10, set the weather to clear

	cpi r16, $20		; Check if the value is $20 (gray weather)
	breq setOvercast	; If the value is $20, set the weather to gray

	cpi r16, $30		; Check if the value is $30 (showers)
	breq setShowers		; If the value is $30, set the weather to showers
		
	cpi r16, $40		; Check if the value is $40 (thunderstorms)
	breq setTstorms		; If the value is $40, set the weather to thunderstorms

setClear:
    ; The next few lines of code are used to wait for the USART receive buffer to clear before we load more messages
	lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp setClear		; If the receive buffer is empty, continue waiting

	mov r18, r16        ; Move the value of r16 into r18 - Moves the weather type part of sript message into 18 - clears r16 sp it can be used to store more messages
	
	lds r16, UDR0		; Load the next byte from the receive buffer
	mov LED_COUNT, r16  ; Move the value received from scrapy, just moving the count into LED_COUNT
    cpi LED_COUNT, 0    ; Compare the LED count received from the python sript
    breq zeroTemp       ; If it is zero we dont want to print out anything so jump to zeroTemp
	call setNeoWeather  ; Call subroutine to print out to LEDs
	rjmp endRx			; Return from the interrupt

setOvercast:
    ; The next few lines of code are used to wait for the USART receive buffer to clear before we load more messages
	lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp setOvercast	; If the receive buffer is empty, continue waiting

	mov r18, r16        ; Move the value of r16 into r18 - Moves the weather type part of sript message into 18 - clears r16 sp it can be used to store more messages

	lds r16, UDR0		; Load the next byte from the receive buffer
	mov LED_COUNT, r16  ; Move the value received from scrapy, just moving the count into LED_COUNT
    cpi LED_COUNT, 0    ; Compare the LED count received from the python sript
    breq zeroTemp       ; If it is zero we dont want to print out anything so jump to zeroTemp
	call setNeoWeather  ; Call subroutine to print out to LEDs
	rjmp endRx			; Return from the interrupt

setShowers:
	; The next few lines of code are used to wait for the USART receive buffer to clear before we load more messages
    lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp setShowers		; If the receive buffer is empty, continue waiting

	mov r18, r16        ; Move the value of r16 into r18 - Moves the weather type part of sript message into 18 - clears r16 sp it can be used to store more messages

	lds r16, UDR0		; Load the next byte from the receive buffer
	mov LED_COUNT, r16  ; Move the value received from scrapy, just moving the count into LED_COUNT
    cpi LED_COUNT, 0    ; Compare the LED count received from the python sript
    breq zeroTemp       ; If it is zero we dont want to print out anything so jump to zeroTemp
	call setNeoWeather  ; Call subroutine to print out to LEDs
	rjmp endRx			; Return from the interrupt

setTstorms:
    ; The next few lines of code are used to wait for the USART receive buffer to clear before we load more messages
	lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp setTstorms		; If the receive buffer is empty, continue waiting

	mov r18, r16        ; Move the value of r16 into r18 - Moves the weather type part of sript message into 18 - clears r16 sp it can be used to store more messages

	lds r16, UDR0		; Load the next byte from the receive buffer
	mov LED_COUNT, r16  ; Move the value received from scrapy, just moving the count into LED_COUNT
    cpi LED_COUNT, 0    ; Compare the LED count received from the python sript
    breq zeroTemp       ; If it is zero we dont want to print out anything so jump to zeroTemp
	call setNeoWeather  ; Call subroutine to print out to LEDs
	rjmp endRx			; Return from the interrupt

zeroTemp:
    call resetPixels    ; Call the reset pixel subroutine if LED count is zero
    rjmp endRx          ; Jump to the end of receive interrut

endRx:
	pop r18             ; Pop r18 from the stack
	pop r17				; Pop r17 from the stack
	pop r16				; Pop r16 from the stack
	reti				; Return from the interrupt


;---------------------------------------------------------------------------------
; CONFIGURES CHIP:
; ---------------
ChipSetUp:
    ; Set up the stack pointer (for calling subroutines / interrupts)
    ldi r31, $08 ; Set high part of stack pointer
    out SPH, r31
    ldi r31, $ff ; set low part of stack pointer
    out SPL, r31

	; PortD set up
	; set up port D:7-4 as output
	;ldi r20, $A0 ; PORTD - 'data' in portd (every other)
	ldi r21, $ff ; DDRD - data direction (Upper 5 output)
	out DDRD, r21 ; Send configuration

    ;USART set up
    call USART_Init

    sei ; Turn on interrupts!


;==================================================================================
; MAIN LOOP:
; ----------
motherLoop:
	rjmp motherLoop
;==================================================================================


;-----------------------------------------------------------------------------------
; SEND WEATHER REPORT:
; --------------------
setNeoWeather:
    push r16                ; Push the value of register r16 onto the stack

    dec LED_COUNT           ; Decrement the value of LED_COUNT by 1

	cpi r18, $10            ; Compare the value in register r18 with 10
	breq setTypeClear       ; Branch to setTypeClear if they are equal

	cpi r18, $20            ; Compare the value in register r18 with 20
	breq setTypeOvercast    ; Branch to setTypeOvercast if they are equal

	cpi r18, $30            ; Compare the value in register r18 with 30
	breq setTypeShower      ; Branch to setTypeShower if they are equal

	cpi r18, $40            ; Compare the value in register r18 with 40
	breq setTypeTstorms     ; Branch to setTypeTstorms if they are equal

setTypeClear:
    ldi ZH, HIGH(clear*2)   ; Load the high byte of the memory address of 'clear' multiplied by 2 into ZH
    ldi ZL, LOW(clear*2)    ; Load the low byte of the memory address of 'clear' multiplied by 2 into ZL
	rjmp outColor           ; Jump to the outColor label

setTypeOvercast:
    ldi ZH, HIGH(overcast*2) ; Load the high byte of the memory address of 'overcast' multiplied by 2 into ZH
    ldi ZL, LOW(overcast*2)  ; Load the low byte of the memory address of 'overcast' multiplied by 2 into ZL
	rjmp outColor            ; Jump to the outColor label

setTypeShower:
    ldi ZH, HIGH(showers*2)  ; Load the high byte of the memory address of 'showers' multiplied by 2 into ZH
    ldi ZL, LOW(showers*2)   ; Load the low byte of the memory address of 'showers' multiplied by 2 into ZL
	rjmp outColor            ; Jump to the outColor label

setTypeTstorms:
    ldi ZH, HIGH(tstorms*2)  ; Load the high byte of the memory address of 'tstorms' multiplied by 2 into ZH
    ldi ZL, LOW(tstorms*2)   ; Load the low byte of the memory address of 'tstorms' multiplied by 2 into ZL
	rjmp outColor            ; Jump to the outColor label

outColor:
    ; Load color values from program memory
    lpm WEATHER_TYPE, Z+     ; Load the green component from the program memory into WEATHER_TYPE and increment the Z register
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1 - This line and the ones like it that follow act as a way to lessen the brightness so it doesnt blind people  
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    call sendByte            ; Call the sendByte subroutine

    lpm WEATHER_TYPE, Z+     ; Load the red component from the program memory into WEATHER_TYPE and increment the Z register
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE
    call sendByte
    
    lpm WEATHER_TYPE, Z+     ; Load the blue component from the program memory into WEATHER_TYPE and increment the Z register
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    lsr WEATHER_TYPE         ; Logical shift right WEATHER_TYPE by 1
    call sendByte            ; Call the sendByte subroutine

    cpi LED_COUNT, 0         ; Compare the value of LED_COUNT with 0
    brne setNeoWeather       ; Branch to setNeoWeather if LED_COUNT is not equal to 0
    rjmp endSet              ; Jump to the endSet label

endSet:
    pop r16                  ; Pop the value from the stack into register r16
    ret                      ; Return from the subroutine

;-----------------------------------------------------------------------------------
; SEND COLOR SUBROUTINE:
; ----------------------
sendByte:
    push r17               ; Push the value of register r17 onto the stack
    ldi r17, 9             ; Load the value 9 into register r17 acts as the count - Needs to be 9 because G, R, and B each need one byte to represent their color

bitSend:
    dec r17                ; Decrement the value of register r17 by 1
    cpi r17, $00           ; Compare the value in register r17 with 0
    breq endSend           ; Branch to endSend if they are equal

    lsl WEATHER_TYPE       ; Logical shift left WEATHER_TYPE by 1
    brcs sendOne           ; Branch to sendOne if the carry flag is set
    rjmp sendZero          ; Jump to sendZero


sendOne:
    sbi PORTD, 2           ; Set bit 2 of PORTD 
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    cbi PORTD, 2           ; Clear bit 2 of PORTD
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rjmp bitSend           ; Jump back to bitSend

sendZero:
    sbi PORTD, 2           ; Set bit 2 of PORTD
    nop
    nop
    nop
    nop
    nop
    cbi PORTD, 2           ; Clear bit 2 of PORTD
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rjmp bitSend           ; Jump back to bitSend

endSend:
    pop r17                ; Pop the value from the stack into register r17
    ret                    ; Return from the subroutine

;----------------------------------------------------------------------------------
; NEOPIXEL RESET SUBROUTINE:
; --------------------------
resetPixels:
    push r16               ; Push the value of register r16 onto the stack
    push r17               ; Push the value of register r17 onto the stack

    ldi r17, 24            ; Load the value 24 into register r17

loopPixels:
    dec r17                ; Decrement the value of register r17 by 1

    ldi r16, $00           ; Load the value $00 into register r16
    call sendByte          ; Call the sendByte subroutine
    ldi r16, $00           ; Load the value $00 into register r16
    call sendByte          ; Call the sendByte subroutine
    ldi r16, $00           ; Load the value $00 into register r16
    call sendByte          ; Call the sendByte subroutine

    cpi r17, 0             ; Compare the value in register r17 with 0
    brne loopPixels        ; Branch to loopPixels if they are not equal

    ldi r16, 1             ; Load the value 1 into register r16
    call wait_xms          ; Call the wait_xms subroutine
    rjmp endReset          ; Jump to the endReset label

endReset:
    pop r17                ; Pop the value from the stack into register r17
    pop r16                ; Pop the value from the stack into register r16
    ret                    ; Return from the subroutine

;----------------------------------------------------------------------------------
; USART INITIALZATION:
; --------------------
; Pulled from pg. 149 of ATmega328P data sheet
; Sets USART to 9600 baud, Tx/Rx, 8bit, 2stop bit
; Interupts enabled!
; Baud rate: this is how fast the serial connection 'talks' 
;            both sides need to know ahead of time this number
;            a higher baud rate results in 'faster' communication
; UBRR0H/L : USART Baud Rate Register 19.10.5 (see table 19-12, for 16MHz baud calc)
; UCSR0B   : USART Control and Status Register 0 B 19.10.3
;            this enables / disables RX/TX (kind of like setting DDRn)
; UCSR0C   : USART Control and Status Register 0 C 19.10.3
;            sets the 'shape' of the signal (how many bits / stop bits / pairity)
; Need to use sts / lds because USART registers are in 'extended' I/O range (in / out is too restrictive)
USART_Init:
    push r16 ; Save r16 / r17 just in case
    push r17

    ; Set baud rate
    ldi r17, $00 ; High baud (aiming for 9600bps)
    ldi r16, $67 ; Low baud
    sts UBRR0H, r17
    sts UBRR0L, r16

    ; Enable receiver and transmitter
    ldi r16, (1<<RXEN0)|(1<<RXCIE0) ; Turn on RX/TX and set up Receive interrupt
    sts UCSR0B, r16

    ; Set frame format: 8data, 2stop bit
    ldi r16, (1<<USBS0)|(0<<UPM00)|(3<<UCSZ00)
    sts UCSR0C, r16

    pop r17 ; Restore r17 and r16
    pop r16
    ret     ; go back to where this was called


;---------------------------------------------------------------------------------
; DELAY SUBROUTINE:
; -----------------
; nop delay for approx 1ms
; target:     0.001
; one cycle  ~0.0000000625
; 0.001 / x = 0.0000000625
; x = 16,000
; 16,000 / 256 = ~62
; If we loop through 256 nop loops 62 times, we should be good
wait_1ms:
    push r16
    push r17

    clr r16
    clr r17

wait_1ms_outerLoop:
wait_1ms_inner: ; This should run 256 times taking aprox 1 + 1 cycles
    inc r16
    brne wait_1ms_inner

    inc r17
    cpi r17, 30 ; Only need to loop 30 times because inner loop is two cycles (thus twice as long as expected)
    brne wait_1ms_outerLoop


    pop r17
    pop r16
    ret

;---------------------------------------------------------------------------------
; Wait x ms, where r16 is holding x
wait_xms:
    push r16 ;Save state of r16

wait_xms_loop:
    call wait_1ms ; should wait 1 ms per call
    dec r16 ; Loop r16 times
    brne wait_xms_loop

    pop r16 ; restore
    ret
;---------------------------------------------------------------------------------
; Program Memory setup for Weather
; Values that represent the color of each weather type 
; Will be saved as a constant and used to output to NeoPixel Ring
; Colors on ring are reveived as Green bits - Red bits - Blue bits
; EX: g7 - g6 - g5 - g4 - g3 - g2 - g1 - g0 ... then red, then blue 
clear: .db $26, $00, $E6    ; Neopixel color value for clear weather type 0026E6 or blue use lpm to access - lpm indexes into a half memory location program memory in word chunks 
overcast: .db $99, $8C,  $9C	; Neopixel color value for overcast weather type 8C999C or gray
showers: .db $FF, $00,  $2A  ; Neopixel color value for showers 8C999C or electric green!
tstorms: .db $66, $FF,  $19  ; Neopixel color value for thunderstorms 8C999C or pumpkin orage!

; Data sheet for neopixels 
; Neo pixel libraries (.h files)
; Guess and check
; 800 khz data transmit
; GRB instead of RGB
; How many nops = enough time 
; .3 0 about 5 nops
; .9 - about 15 nops
; 6 = about 10 nops