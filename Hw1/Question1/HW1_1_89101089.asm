;8086 PROGRAM HW1_1_89101089.ASM
;ABSTRACT  : This program records voice at two rates (8 & 12 KHZ) selectable by user ,
;            then plays recorded voice. 
;REGISTERS : Uses CS , DS , ES , AX , CX , SI   
;PORTS     : Uses Ports 10-13H for 8255 #PPI
;                 Ports 40-43H for 8253 #Timer               
;PROCEDURES: ---
;-----------------------------------------------------------------------
;   8086 is operating with 6 MHZ clock 
;   0808 is used as A/D converter that interfaces through PortA of 8255
; AD7523 is used as D/A converter that interfaces through PortB of 8255
;   Timer0 of 8254 is used in Mode2 (pulse generator)
;   Gate input of timer is tied to high
;   64 KByte extra memory is mapped at 40000H-4FFFFH   
;-----------------------------------------------------------------------

PortADC   EQU 10H ; PortA Input
PortDAC   EQU 11H ; PortB Output
PortSig   EQU 12H ; Upper Part of PortC is used as input / Lower Part as output
PortCon   EQU 13H 

Timer0    EQU 40H
;Timer1   is unused
;Timer2   is unused
TimerCon  EQU 43H 

;Port Assignments 
;
;PortSig [7] : button   
;PortSig [6] : switch                                             Upper Part of PortC ( Input  )
;PortSig [5] : timer 0 out
;PortSig [4] : ADC end of conversion (EOC)
             ;
             ; 
             ;PortSig [3] : Led                                   Lower Part of PortC ( Output )
             ;PortSig [2] : -
             ;PortSig [1] : -
             ;PortSig [0] : ADC start of conversion (SOC)
   

But_Mask  EQU 10000000B
Swh_Mask  EQU 01000000B
Tim_Mask  EQU 00100000B
ADC_Mask  EQU 00010000B

LED_on    EQU 00000111B
LED_off   EQU 00000110B
ADC_on    EQU 00000001B
ADC_off   EQU 00000000B
 
                              
code         SEGMENT    
    
ASSUME CS:code  ES:4000H

             
                              
             ;initialize ports
      Start: MOV  AL       , 98H
             OUT  PortCon  , AL
             MOV  AX       , 4000H      ; initialize extra segment base
             MOV  ES       , AX    
             MOV  DI       , 0000H      ; initialize DI to first byte of memory                          

   CheckREC: IN   AL       , PortSig
             TEST AL       , But_Mask
             JZ   CheckREC              ; check record request
             TEST AL       , 0FDH
             JZ   Rec_Rate_8            ; initialize timer 0 to  8 KHZ
             JMP  Rec_Rate_12           ; initialize timer 0 to 12 KHZ
             
             
 Rec_Rate_8: MOV  AL       , 00110101B  ; select timer 0 to r/w LSB first , then MSB  in mode 2 as 16 bit binary counter
             OUT  TimerCon , AL
             MOV  AX       , 750        ; 6000/ 8=750
             OUT  Timer0   , AL         ; out least significant byte
             MOV  AL       , AH
             OUT  Timer0   , AL         ; out  most significant byte  
             JMP  Record
            

Rec_Rate_12: MOV  AL       , 00110101B  ; select timer 0 to r/w LSB first , then MSB  in mode 2 as 16 bit binary counter
             OUT  TimerCon , AL
             MOV  AX       , 500        ; 6000/12=500
             OUT  Timer0   , AL         ; out least significant byte
             MOV  AL       , AH
             OUT  Timer0   , AL         ; out  most significant byte  
             JMP  Record
            

     Record: MOV  AL      , LED_on      ; turn on led 
             OUT  PortCon , AL          ;   set corresponding bit in PortC
             MOV  CX      , 0FFFFH      ; initialize CX to read 64KByte  
             
  CheckPUL1: IN   AL      , PortSig
             AND  AL      , Tim_Mask    ;  mask timer out
             JNZ  CheckPUL1             ; check timer out
             
             MOV  AL      , ADC_off     ; generate pulse to start conversion
             OUT  PortCon , AL          ; reset corresponding bit in PortC
             MOV  AL      , ADC_on    
             OUT  PortCon , AL          ;   set corresponding bit in PortC
             MOV  AL      , ADC_off   
             OUT  PortCon , AL          ; reset corresponding bit in PortC
                                      
   CheckEOC: IN   AL      , PortSig
             AND  AL      , ADC_Mask    ;  mask end of conversion (ADC)
             JZ   CheckEOC              ; check end of conversion (ADC)
             
             IN   AL      , PortADC     ; read value from port
             MOV  [DI]    , AL          ; store read value in memory
             INC  DI                    ; move DI to next byte
             LOOP CheckPUL1             ; repeat until 64KByte is read
                  
             MOV  AL      , LED_off     ; turn off led 
             OUT  PortCon , AL          ; reset corresponding bit in PortC

   CheckPLY: IN   AL      , PortSig
             TEST AL      , But_Mask
             JZ   CheckPLY              ; check play request 
             
                              
       Play: MOV  CX      , 0FFFFH      ; initialize CX to move play 64KByte from memory 
             MOV  DI      , 0000H       ; initialize DI to first byte of memory
                                        ; timer is generating pulse with selected rate so there
                                        ; is no need to reinitialize it
             
  CheckPUL2: IN   AL      , PortSig
             AND  AL      , Tim_Mask    ; mask  timer out
             JNZ  CheckPUL2             ; check timer out 
             
             MOV  AL      , [DI]        ; read value from memory
             OUT  PortDAC , AL          ; send value to port 
             INC  DI                    ; move DI to next byte
             LOOP CheckPUL2             ; repeat until 64KByte is played
             
             JMP  Start

code         ENDS

             END