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

.DEVICE ATmega328p ;Define the correct device
;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt Vectors ;;
;;;;;;;;;;;;;;;;;;;;;;;

.DEF LED_COUNT = r24
.DEF WEATHER_TYPE = r23

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
	push r16			; Push r16 onto the stack	
	push r17			; Push r17 onto the stack
	push r18

	call resetPixels

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
	lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp setClear		; If the receive buffer is empty, continue waiting

	mov r18, r16
	
	lds r16, UDR0		; Load the next byte from the receive buffer
	mov LED_COUNT, r16
	call setNeoWeather
	rjmp endRx			; Return from the interrupt

setOvercast:
	lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp setOvercast	; If the receive buffer is empty, continue waiting

	mov r18, r16

	lds r16, UDR0		; Load the next byte from the receive buffer
	mov LED_COUNT, r16
	call setNeoWeather
	rjmp endRx			; Return from the interrupt

setShowers:
	lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp setShowers		; If the receive buffer is empty, continue waiting

	mov r18, r16

	lds r16, UDR0		; Load the next byte from the receive buffer
	mov LED_COUNT, r16
	call setNeoWeather
	rjmp endRx			; Return from the interrupt

setTstorms:
	lds r17, UCSR0A		; Load data from UCSR0A into r17
	sbrs r17, RXC0		; Check if the receive buffer is empty
	rjmp setTstorms		; If the receive buffer is empty, continue waiting

	mov r18, r16

	lds r16, UDR0		; Load the next byte from the receive buffer
	mov LED_COUNT, r16
	call setNeoWeather
	rjmp endRx			; Return from the interrupt

endRx:
	pop r18
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
    dec LED_COUNT   
	

	cpi r18, $10
	breq setTypeClear

	cpi r18, $20
	breq setTypeOvercast

	cpi r18, $30
	breq setTypeShower

	cpi r18, $40
	breq setTypeTstorms

setTypeClear:
    ldi ZH, HIGH(clear*2) ; 'Times two' to align with the lpm command
    ldi ZL, LOW(clear*2)
	rjmp outColor
setTypeOvercast:
    ldi ZH, HIGH(overcast*2) ; 'Times two' to align with the lpm command
    ldi ZL, LOW(overcast*2)
	rjmp outColor
setTypeShower:
    ldi ZH, HIGH(showers*2) ; 'Times two' to align with the lpm command
    ldi ZL, LOW(showers*2)
	rjmp outColor
setTypeTstorms:
    ldi ZH, HIGH(tstorms*2) ; 'Times two' to align with the lpm command
    ldi ZL, LOW(tstorms*2)
	rjmp outColor

outColor:
    ; Load color values from program memory
    lpm WEATHER_TYPE, Z+ ; Load red component
    call sendByte
    lpm WEATHER_TYPE, Z+ ; Load red component
    call sendByte
    lpm WEATHER_TYPE, Z+ ; Load red component
    call sendByte

    cpi LED_COUNT, 0
    brne setNeoWeather
    rjmp motherLoop


;-----------------------------------------------------------------------------------
; SEND COLOR SUBROUTINE:
; ----------------------
sendByte:
    push r17
    ldi r17, 9

bitSend:
    dec r17
    cpi r17, $00
    breq endSend
    lsl WEATHER_TYPE
    brcs sendOne
    rjmp sendZero


sendOne:
    sbi PORTD, 2
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
    cbi PORTD, 2
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
    rjmp bitSend

sendZero:
    sbi PORTD, 2
    nop
    nop
    nop
    nop
    nop
    cbi PORTD, 2
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
    rjmp bitSend

endSend:
    pop r17
    ret


;----------------------------------------------------------------------------------
; NEOPIXEL RESET SUBROUTINE:
; --------------------------
resetPixels:
    push r16
    push r17

    ldi r17, 24

loopPixels:
    dec r17

    ldi r16, $00
    call sendByte
    ldi r16, $00
    call sendByte
    ldi r16, $00
    call sendByte

    cpi r17, 0
    brne loopPixels

    ldi r16, 1
    call wait_xms
    rjmp endReset

endReset:
    pop r17
    pop r16
    ret

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