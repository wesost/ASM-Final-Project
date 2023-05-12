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
; Used to get Neopixel ring up and running
;
; Resources:
; ----------
;  https://whitgit.whitworth.edu/2023/spring/CS-278-1/in_class/-/blob/main/Directives_EEPROM_class/source/mem_testing_solution.asm
;  Scott Office Hours
;  https://cdn-shop.adafruit.com/product-files/1138/SK6812+LED+datasheet+.pdf
;  https://whitgit.whitworth.edu/2023/spring/CS-278-1/in_class/-/blob/main/servoTest/source/servoTest.asm - used for the wait subroutine
;
; Notes:
; ------
; Data sheet for neopixels 
; Neo pixel libraries (.h files)
; Guess and check
; 800 khz data transmit
; GRB instead of RGB
; How many nops = enough time 
; .3 - about 5 nops
; .9 - about 15 nops
; 6 = about 10 nops


.DEVICE ATmega328p ;Define the correct device

.EQU ARRAY_START = $0100
.EQU ARRAY_END = $016B
.EQU ARRAY_SIZE = 72


Main:
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


    ldi r24, 2
    call resetPixels
    call storeLEDValue
    call setNeoWeather

motherloop:
    rjmp motherloop

storeLEDValue:
    push r16
    push r17
    push r18
    ldi r17, 0

    cpi r17, 72
    brsh done

    lds r18, ARRAY_START  ; Initialize the pointer to the start of the array
    add r18, r17          ; Add the index offset to the array pointer

    ldi ZH, HIGH(clear*2) ; 'Times two' to align with the lpm command
    ldi ZL, LOW(clear*2)

    lpm r16, z+

    sts ARRAY_START, r16

    inc r17

done:
    pop r18
    pop r17
    pop r16
    ret




;--------------------------------------------------------------------------------------------
setNeoWeather:
    dec r24   

    lds r16, ARRAY_START
    call sendByte
    lds r16, ARRAY_START
    call sendByte
    lds r16, ARRAY_START
    call sendByte


    cpi r24, 0
    brne setNeoWeather
    rjmp motherloop
    

;--------------------------------------------------------------------------------------------
; SEND COLOR FUNCTION:
; ---------------------
sendByte:
    push r17
    ldi r17, 9

bitSend:
    dec r17
    cpi r17, $00
    breq endSend
    lsl r16 
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
;--------------------------------------------------------------------------------------------

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

;--------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------
; nop delay for approx 1ms
;
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

clear: .db $11, $00, $00    ; Neopixel color value for clear weather type 0026E6 or blue use lpm to access - lpm indexes into a half memory location program memory in word chunks 
overcast: .db $8C, $99, $9C	; Neopixel color value for overcast weather type 8C999C or gray
showers: .db $00, $FF, $2A  ; Neopixel color value for showers 8C999C or electric green!
tstorms: .db $FF, $66, $19  ; Neopixel color value for thunderstorms 8C999C or pumpkin orage!