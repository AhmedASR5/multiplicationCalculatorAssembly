PROCESSOR 16F877A
INCLUDE "P16F877A.INC"

__CONFIG 0x3731




Char EQU 0x25
DelayCount EQU 0x30 ; General-purpose register for delay count


high_nibble   EQU 0x40 ; used in send and recive 
low_nibble    EQU 0x41  ; used in send and recive 
full_byte     EQU 0x42  ; used in send and recive 



flag_num1_done  EQU 0x45 ; uesd in recive 


num1_tenth_hex EQU 0x46 ; value of hex of tenth of num 1
num1_unit_hex EQU 0x49 ; same above 

unit_digit_number2_in_hex EQU 0x47 ; unit two above .
 
temp EQU 0x48 ; uesd in diffrent function 
 
 counter EQU 0x51 ; used in multiplication 
 multiplicand EQU 0x52 ; for multiplication function 
 result_high  EQU 0x53 ; save the resutl of multiplication from unit digit with num1
 result_low   EQU 0x54 ; save the resutl of multiplication from unit digit with num1
  result      EQU 0x56 ; used in  multiplicatoin 
  swap        EQU 0x57 ; used in diffrent function for high and low nibbles. 
  
code_to_send  EQU 0x58 ; used in send data.



; Begin the program at the reset vector.
ORG 0x00
GOTO init

; Interrupt vector handling.
ORG 0x04
GOTO ISR

; Initialization routine.
init: 
    BANKSEL INTCON
    BSF INTCON, GIE ; Global interrupt enable
    BSF INTCON, INTE ; Enable RB0 interrupt

    
    BANKSEL TRISD ;
    CLRF TRISD ; Set PORTD as output for LCD

    BANKSEL PORTD
    CLRF PORTD ; Clear PORTD
         ; Configure PORTC to receive data (if not already configured)
	 
	 
    BANKSEL TRISC
    MOVLW   0xF0    ; Set higher 4 bits as input (1) and lower 4 bits output (0)
    MOVWF   TRISC
	; Set RB1 as input and RB2 as output on the slave
	
	
    BANKSEL TRISB       ; Select bank for TRISB register
    MOVLW   b'11111011' ; Set RB1 defult (0 ) as input (1) and RB2 defult (1 ) as output (0), leave others unchanged
    ANDWF   TRISB, F    ; Apply changes to TRISB
    
 
    BANKSEL TRISD
    CLRF TRISD   ;define Port d as output	
    BANKSEL PORTD
		
    MOVLW 'A'
    MOVWF Char ; for displying on screen
    CALL inid   ;initialize LCD

    GOTO start

; Interrupt service routine.
ISR:
    retfie

; Main program loop.
start:
   
    BANKSEL PORTB
    
    BTFSC PORTB,1 ; is we want to recive data ? 
    call choose_which_recive ; YES ! then choose which type function to use.
    

    ; no ! continue checking.

    GOTO start ; Stay here until interrupt

; 1-second delay subroutine.
Delay1Sec:
    MOVLW D'1' ; 5 x 200 ms = 1000 ms (1 seconds)
    MOVWF DelayCount
DelayLoop:
    MOVLW D'200'
    CALL xms
    DECFSZ DelayCount, F
    GOTO DelayLoop
    RETURN
    

INCLUDE "LCDIS_PORTD.INC" ; Include the LCD library


; Subroutine to send a character to the LCD.
send_char:
    MOVWF Char ; Move the character into Char variable.
    BSF Select, RS ; Select the data register.
    CALL send ; Call the send subroutine from the LCD library.
    BCF Select, RS ; Deselect the data register.
    RETURN ; Return from subroutine.

; here we recive the first number in one shot. 
    ; we can by this function recive the whole number in shot , no need to send it digit by digit. 
     ;45  ->  34  35 
RECEIVE_DATA:

             BANKSEL PORTC
	     MOVF    PORTC, W       ; Read PORTC
	 
	     MOVWF   high_nibble
	     SWAPF high_nibble 
	     
	     MOVF high_nibble ,w
	     ANDLW 0x0F
	     ADDLW 0x30
	     MOVWF   high_nibble    ; Save the high nibble
	     
	     	  	     	     	        	  	    				    
	     CALL    Delay1Sec      ; Placeholder for delay or synchronization
	     CALL    Delay1Sec  
	     ;CALL    Delay1Sec 
	     ; Receive the low nibble
	     MOVF    PORTC, W       ; Read PORTC again

	     
	     MOVWF   low_nibble
	     SWAPF low_nibble 
	     
	     MOVF low_nibble ,w
	     ANDLW 0x0F
	     ADDLW 0x30
	     MOVWF   low_nibble    ; Save the high nibble
	     
	     
	  	    
		       ;;;;;;;;;convert ascii code which we get to it's  value of hex ;;;;;;;;;;;;;
			 
			 ;exampe -> input  0x34  ->  output 0x04
		    
	     ;;;;;;;;;convert the num1_tenth to hex ;;;;;;;;;;;;;
	     
	     
	     movf high_nibble,w 
	     call funtion_to_get_value_of_hex
	     movf temp , w 
	     movwf num1_tenth_hex
	     
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 
	    ;;;;;;;;;convert the num1_unit to hex ;;;;;;;;;;;;;
	     
	     
	     movf low_nibble,w 
	     call funtion_to_get_value_of_hex
	     movf temp , w 
	     movwf num1_unit_hex
	     
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	 
	     
	     call printNumber1
	     
	     CALL    Delay1Sec
	     
	     MOVF    high_nibble, W 
	     call send_char 	     
	     
	     MOVF    low_nibble, W 
	     call send_char 
	   
	   BSF flag_num1_done ,0 
	   
	   BANKSEL PORTB 
	   BCF  PORTB ,2 
	   
	   CALL    Delay1Sec 
	   ;CALL    Delay1Sec
	   
	   BANKSEL PORTB 
	   BSF  PORTB ,2  ; return the value of RB2 to it defult to use it again .  
	   
	        
      
    RETURN
	     
	    

; here we recive the second number, as acsii for unit digt , or any one digit.	     
RECEIVE_DATA2:

             BANKSEL PORTC
	     MOVF    PORTC, W       ; Read PORTC
	 
	     MOVWF   high_nibble
	     
	     MOVF high_nibble ,w
	     ANDLW 0xF0
	     
	     MOVWF   high_nibble    ; Save the high nibble
	     
	  	     		     
	     	     	  	    				    
	     CALL    Delay1Sec      ; Placeholder for delay or synchronization
	     CALL    Delay1Sec  
	    ; CALL    Delay1Sec 
	     ; Receive the low nibble
	     MOVF    PORTC, W       ; Read PORTC again

	 
	     
	
	     
	     MOVWF   low_nibble
	     SWAPF low_nibble 
	     
	     MOVF low_nibble ,w
	     ANDLW 0x0F
	     
	     MOVWF   low_nibble    ; Save the high nibble
	     
	     IORWF high_nibble ;
	     
	     MOVF high_nibble ,w
	     movwf full_byte
	     
	     ;;;;;;;;;convert the value to hex ;;;;;;;;;;;;;
	     
	     
	     movf full_byte,w 
	     call funtion_to_get_value_of_hex
	     movf temp , w 
	     movwf unit_digit_number2_in_hex
	     
	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     
 	    
	     call printNumber2
	     
	   
	     
	     CALL    Delay1Sec
	     
	     MOVF    full_byte, W  
 	     call send_char 	     
	     
	   	  	   
	   BANKSEL PORTB 
	   BCF  PORTB ,2  ; singal the master to tell him , i am done. reciveing 
	  
	 
	    
	   CALL    Delay1Sec 
	 
	   
	   BANKSEL PORTB 
	   BSF  PORTB ,2  ; return the value of RB2 to it defult to use it again .  
	  
	   CALL send_to_multiplicaition  
	        
      
    RETURN
	     
	     
	     
	     
	     
funtion_to_get_value_of_hex: 
			     MOVWF temp
			     ANDLW 0x0F
			     MOVWF temp 
			     RETURN
			     
			    
			    
				     
choose_which_recive:

		      BTFSC flag_num1_done,0 ; are you done number 1 send ? 
		      CALL  RECEIVE_DATA2 ; YES! then go the recive the unit digit of the number 2
		      
		      
		      
		      BTFSS flag_num1_done,0
		      CALL RECEIVE_DATA  ; NO! then go recive the first number.
		      
		      RETURN
		      



		      
		      
send_to_multiplicaition:
				
			
			  CLRF  result  
			
			   
			  MOVLW 0x0A       ; Load constant 10 into W

			 ; Perform the multiplication using a loop
			  multiply_loop:
			  ADDWF result, F ; Add num to the result

			  ; Decrease the loop counter (you might need to adjust the count based on your specific requirements)
			  DECFSZ num1_tenth_hex, F   ; Decrease num and skip if zero
			  GOTO multiply_loop ; Continue the loop if num is not zero
			  
			  movf num1_unit_hex,w 
			  
			  ADDWF result , w 
			  
			  MOVWF result
	
		
			
			 movf unit_digit_number2_in_hex , w 
			 MOVWF counter    ; Move W to counter for loop control
			 

			 MOVF  result, W  
			 
			 MOVWF multiplicand ; Store the multiplicand
			
			
   



multiply_loop2:

	  MOVF    counter, W  ; Move the value of num2_tenth_digit into the W register
	  BTFSC   STATUS, Z            ; Test if Zero flag is set (which means num2_tenth_digit is zero)
	  goto counter0 
			   
    ; Add multiplicand to result_low, consider carry to result_high
    MOVF multiplicand, W    ; Get multiplicand
    ADDWF result_low, F     ; Add to result_low
    BTFSC STATUS, C         ; Check if there was a carry
    INCF result_high, F     ; Increment result_high if carry occurred

    DECF counter, F         ; Decrement the counter
    MOVF counter, W         ; Check if counter is zero
    BZ end_multiply         ; If zero, multiplication is done
    GOTO multiply_loop2      ; Else, continue loop
    

end_multiply:


	    ; send the 2 most significant digits in 1 shot
	    
	    
	    
	    ; 0x175   0x01 high , low 0x75 -> w -> and -> 0x70 -> 0x07 -> 0x10 ->  high 0x10 or 0x07  ->0x17 
	    
	    
	    ;; getting the most high two digits
	    movf result_high, W 
	    MOVWF code_to_send	  
	    call SEND_DATA
	    CALL    Delay1Sec 
	    CALL    Delay1Sec
	    
	    BANKSEL PORTB
	    BSF PORTB,2 ; rest portb2 to make the master able to wait the low bits 
	  
	    
	    movf result_low, W 
	    MOVWF code_to_send	    
	    call SEND_DATA
	    CALL    Delay1Sec 
	    CALL    Delay1Sec 
	    
	    BANKSEL PORTB
	    BSF PORTB,2 ; rest portb2 to make the master able to wait the low bits 
	    
	    bcf flag_num1_done ,0
	    
	    clrf result_low
	    clrf result_high
	    
	    goto start
	    
	    RETURN
    

  
counter0:
	 clrf result_low
	 clrf result_high
	 goto end_multiply



SEND_DATA:
	  	 	  
	  BANKSEL TRISC
	  MOVLW   0xF0    ; Set lower 4 bits as input (1) and upper 4 bits output (1)
	  MOVWF   TRISC
	  
	  BANKSEL PORTC
	   
	 ;0x43  ; 0x40 -> 0x04
	   
	   
	  ; Output the high nybble (3) to PORTC
	  MOVF    code_to_send, W    ; Move temp_code back to W
	     
	  ANDLW   0xF0            
	  
	  MOVWF swap
	  SWAPF swap
	  MOVF swap ,w 	  
	  MOVWF   PORTC           ; Output high nybble to PORTC
	  
	  BANKSEL PORTB
	  BCF PORTB,2 ; signaling the master. defult 1 
	  
	  
	  CALL    Delay1Sec
	  CALL    Delay1Sec

	  BANKSEL PORTC
	  
	  MOVF    code_to_send, W    ; Move temp_code back to W
	  
	  ; Output the low nybble (1) to PORTC
	 
	  
	  MOVF code_to_send ,w
	  
	  ANDLW   0x0F     
	  MOVWF   PORTC          
	  
	  wait_until_master_done:
	  
	
	  btfsc PORTB ,1 ; is the master done ? defult zero 
	  RETURN ; yes return back
	  
	
	  
	  goto wait_until_master_done ; No! wait until it done.
	  
	  
	  
    RETURN	       
    
    
          
printNumber1:
			
			CALL ClearLCD 
			
			MOVLW 'N'
			BSF Select, RS
			CALL send
			
			MOVLW 'U'
			BSF Select, RS
			CALL send
			
			MOVLW 'M'
			BSF Select, RS
			CALL send
			
			MOVLW 'B'
			BSF Select, RS
			CALL send
			
			MOVLW 'E'
			BSF Select, RS
			CALL send
			
			MOVLW 'R'
			BSF Select, RS
			CALL send
			
			MOVLW 0x20
			BSF Select, RS
			CALL send
			
			MOVLW 0x31
			BSF Select, RS
			CALL send
			
			BCF 	Select, RS
			MOVLW 	0xC0 ; second row
			CALL 	send
			



RETURN

printNumber2:

			        CALL ClearLCD       ; Clear the LCD
				 
				MOVLW 'N'
				BSF Select, RS
				CALL send
				
				MOVLW 'U'
				BSF Select, RS
				CALL send
				
				MOVLW 'M'
				BSF Select, RS
				CALL send
				
				MOVLW 'B'
				BSF Select, RS
				CALL send
				
				MOVLW 'E'
				BSF Select, RS
				CALL send
				
				MOVLW 'R'
				BSF Select, RS
				CALL send
				
				MOVLW 0x20
				BSF Select, RS
				CALL send
				
				MOVLW 0x32
				BSF Select, RS
				CALL send
				
			       BCF 	Select, RS
			       MOVLW 	0xC0 ; second row
			       CALL 	send
			       
			MOVLW 0x20
			BSF Select, RS
			CALL send
			
			MOVLW 'U'
			BSF Select, RS
			CALL send
			
			MOVLW 'N'
			BSF Select, RS
			CALL send
			
			MOVLW 'I'
			BSF Select, RS
			CALL send
			
			MOVLW 'T'
			BSF Select, RS
			CALL send
			
			MOVLW 0x20
			BSF Select, RS
			CALL send
			
			MOVLW 'D'
			BSF Select, RS
			CALL send
			
			MOVLW 'I'
			BSF Select, RS
			CALL send
			
			MOVLW 'G'
			BSF Select, RS
			CALL send
			
			MOVLW 'I'
			BSF Select, RS
			CALL send
			
			MOVLW 'T'
			BSF Select, RS
			CALL send
			
			MOVLW 0x20
			BSF Select, RS
			CALL send
			
		


RETURN
  



  
ClearLCD:
	    BCF Select, RS ; Deselect the data register.
	    MOVLW 0x01 ; Command to move cursor to second row
	    CALL send
	    RETURN

  
END