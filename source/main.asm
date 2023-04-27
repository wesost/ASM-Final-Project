; CS 278-1 Final Project
;
; Created: 4/27/2023
; Author : Wed and Cade
;
; compile with:
; gavrasm.exe -b main.asm
; 
; upload with:
; avrdude -c arduino -p atmega328p -P COM4 -U main.hex
;

.DEVICE ATmega328p ;Define the correct device

;;;;;;;;;;;;;;;;;;;;;;;
;; Interrupt Vectors ;;
;;;;;;;;;;;;;;;;;;;;;;;
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
int_usart_rx:
    push r16
    ; Read the received byte
    lds r16, UDR0
    ; Output the byte to PORTD
    out PORTD, r16
    pop r16
    reti

ChipSetUp:
    ; Set up the stack pointer (for calling subroutines / interrupts)
    ldi r31, $08 ; Set high part of stack pointer
    out SPH, r31
    ldi r31, $ff ; set low part of stack pointer
    out SPL, r31

	; PortD set up
	; set up port D:7-4 as output
	;ldi r20, $00 ; PORTD - 'data' in portd (every other)
	ldi r21, $f0 ; DDRD - data direction (Upper 5 output)
	out DDRD, r21 ; Send configuration

    ;USART set up
    call USART_Init

    sei ; Turn on interrupts!


;---------------------------------------------------------------------------------
motherLoop:
	nop
	rjmp motherLoop
;---------------------------------------------------------------------------------
; USART Initialization
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
    ldi r16, (1<<USBS0)|(3<<UCSZ00)
    sts UCSR0C, r16

    pop r17 ; Restore r17 and r16
    pop r16
    ret     ; go back to where this was called
;---------------------------------------------------------------------------------




