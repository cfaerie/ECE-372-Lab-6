;*****************************************************************
;* ClockASM.ASM
;
;Code Entry, Assembly, and Execution 
;(Put your name and date here) 
;--------------------------------------- 
;* -this is the sample code for Lab1
;* -for Full Chip Simulation or Board -- select your target
;* DO NOT DELETE ANY LINES IN THIS TEMPLATE
;* --ONLY FILL IN SECTIONS
;*****************************************************************
; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point

; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 
		
;-------------------------------------------------- 
; Equates Section  
;----------------------------------------------------  
ROMStart    EQU  $2000  ; absolute address to place my code
TEN     EQU   $80
TOF     EQU   %10000000
OC2VEC  EQU   $3E6A  ; vector under D-bug12 (board)
OC2VECSIM EQU $FFEA  ; simulation uses actual vector
C2F     EQU   $04
C2I     EQU   $04
IOS2    EQU   $04
;---------------------------------------------------- 
; Variable/Data Section
;----------------------------------------------------  
            ORG RAMStart   ; loc $1000  (RAMEnd = $3FFF)
; Insert here your data definitions here

COUNT       DS   1
NUMTICKS    DS   1
SECONDS     DS   1   ;keeps track of seconds
MINUTES     DS   1   ;keeps track of minutes
HOURS       DS   1   ;keeps track of hours
COUNT1      DS   1    ;Keep Track of LED Counter
 

       INCLUDE 'utilities.inc'
       INCLUDE 'LCD.inc'

;---------------------------------------------------- 
; Code Section
;---------------------------------------------------- 
            ORG   ROMStart  ; loc $2000
Entry:
_Startup:
            ; remap the RAM &amp; EEPROM here. See EB386.pdf
 ifdef _HCS12_SERIALMON
            ; set registers at $0000
            CLR   $11                  ; INITRG= $0
            ; set ram to end at $3FFF
            LDAB  #$39
            STAB  $10                  ; INITRM= $39

            ; set eeprom to end at $0FFF
            LDAA  #$9
            STAA  $12                  ; INITEE= $9
            JSR   PLL_init      ; initialize PLL  
  endif

;---------------------------------------------------- 
; Insert your code here
;---------------------------------------------------- 
        CLR   COUNT1
        
MAIN
*SET UP THE (interrupt) SERVICE & INITIALIZE
        SEI             ; turn off interrupts while initializing intr.
        JSR   TermInit  ; Initialize Serial Port when not
                       ; ...using built-in DBUG12 utilities
      	CLR   COUNT
        CLR   SECONDS
        CLR   MINUTES
        CLR   HOURS
        MOVB  #100,NUMTICKS  ; number of ticks (interrupts) for 1 second
        
*SET UP THE SERVICE (ISR) & INITIALIZE -continued
     
       bset    DDRT,%00100000   ; PT5 (spkr) is output
       movb    #$80,TSCR1     ; enable TCNT
       bset    TIOS,IOS2      ; choose OC2 for timer ch. 2
       movb    #$03,TSCR2     ; set prescaler to 8
       movb    #C2F,TFLG1    ; clear  C2F flag initially
       bset    TIE,C2I     ; arm OC2
       cli                   ; allow interupts
       
       BSET   TSCR1,TEN   ;timer enable in TSCR Register
       jsr    led_enable
       
L1
      MOVB  #TOF,TFLG2
L2    BRCLR TFLG2,TOF,L2
      LDAA  PTT
      EORA  #%00100000
      STAA  PTT
      BRA   L1
       
       
       

       BRA     *
*====END OF MAIN ROUTINE

*============= SERVICE PROCESS
OC2ISR
        MOVB   #C2F,TFLG1   ; clear flag
        LDD    TC2  ; schedule next interrupt
        ADDD   #30000  ; 30000 cycles = 10ms
        STD    TC2
        INC    COUNT   ; one more interrupt interval counted
        LDAB   COUNT
        CMPB   NUMTICKS
        BNE    DONE  ; not one second yet so return
        
        
        
        
        
        CLR    COUNT
        JSR    ONE.SECOND  ; one second has elapsed
DONE    RTI
*============= END OF SERVICE ROUTINE
ONE.SECOND    ; what to do every second
        JSR   DISPLAY
        
        LDAA  PORTB   ;load what is on LEDs
        CMPA  #%00001111  ;is it at 1111
        BNE   SKIP         ;if not, jump to SKIP label
        CLR   COUNT1     ;if is 1111, reset count to 0000
        CLR   PORTB
        jmp next
        
        
SKIP  
        INC   COUNT1 
        LDAA  COUNT1
        STAA  PORTB
        
next        INC   SECONDS
        LDAA  SECONDS
        CMPA  #60
        BEQ   ONE.MINUTE
        RTS

ONE.MINUTE
        CLR   SECONDS
        INC   MINUTES
        LDAA  MINUTES
        CMPA  #60
        BEQ   ONE.HOUR
        RTS
ONE.HOUR
        CLR   MINUTES
        INC   HOURS
        LDAA  HOURS
        CMPA  #24
        BEQ   ONE.DAY
        RTS
ONE.DAY
        CLR   HOURS
        RTS

DISPLAY  ; DISPLAY THE TIME AS HH:MM:SS
        PSHB
Simulation  EQU  1
      ifndef  Simulation
; Simulation--cannot interpret backspace character
        LDAB  #8  ; backpace to beginning of display line
        JSR   putchar
        JSR   putchar
        JSR   putchar
        JSR   putchar
        JSR   putchar
        JSR   putchar  
        LDAB   #$0D
        JSR   putchar
       endif  
   
        LDAB   HOURS
        JSR    OUTDEC
        LDAB   #':'
        JSR    putchar
        LDAB   MINUTES
        JSR    OUTDEC
        LDAB   #':'
        JSR    putchar
        
        LDAB   SECONDS
        JSR    OUTDEC
        LDAB   #$0D
        JSR   putchar
        LDAB   #$0A
        JSR   putchar
        PULB
        RTS
        
HEX2BCD  ; assumes value to be converted is in ACC A and result in A
        TFR    A,B   ; make copy in B
UP      CMPB   #10
        BLO    DONE2
        SUBB   #10
        ADDA   #6
        BRA    UP
DONE2
       RTS

OUTDEC
        TFR    B,A   ; HEX2BCD takes input from A
        JSR    HEX2BCD
        TFR    A,B     ; putchar needs value in B
        LDX   #0  ;
        JSR   out2hex   ; output B as 2 hex digits
        RTS
        
                         
;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   Vreset
            DC.W  Entry         ; Reset Vector

	          ORG   Vtimch2       ; setup  OC2 Vector
            DC.W  OC2ISR

 