   ;8086 PROGRAM HW2_2_89101089.ASM
   ;ABSTRACT  : This program sends 5 bit codes at 1kbps rate using infrared
   ;            transmitter to motor controller.Program uses IC-MHA to measure 
   ;            centrifuge speed and ADC0804 to convert analog output signal 
   ;            from ic-MHA to digital 8-bit value
   ;REGISTERS : Uses CS , DS , ES , SS , SP , AX , BX , DX   
   ;PORTS     : Uses Ports 10-12-14-16 for 8255 #PPI
   ;                 Ports 40-42-44-46 for 8253 #Timer
   ;                 Ports 80-82 for 8259 #Interrupt Controller
   ;PROCEDURES: Calls TRANS as type 32H interrupt ISR
   ;                  CONVR as type 33H interrupt ISR 
   ;---------------------------------------      
   ;Port Assignments
   ;---------------------------------------   
   ;PortA[7:0] <= ADC[7:0]
   ;
   ;PortC[7]   => Unassigned
   ;PortC[6]   => Unassigned
   ;PortC[5]   => Unassigned
   ;PortC[4]   => Transmitter
   ;PortC[3]   => ADC    ~RD
   ;PortC[2]   => ADC    ~WR 
   ;PortC[1]   => Timer1 Gate
   ;PortC[0]   => Timer0 Gate
   ;
   ;PortB[7:0] => Unassigned 
   ;---------------------------------------            
   ;8259 Pin Assignments
   ;---------------------------------------   
   ;IR[0] <= ADC ! ~INTR  (Type 32)
   ;IR[1] <= Timer1 Out   (Type 33)        
   ;---------------------------------------          
       PortA EQU 10H
       PortB EQU 12H
       PortC EQU 14H
    PortCont EQU 16H   
   ;---------------------------------------
      Timer0 EQU 40H
      Timer1 EQU 42H
      Timer2 EQU 44H
   TimerCont EQU 46H
   ;--------------------------------------- 
   Port8259A EQU 80H
   Port8259B EQU 82H
   ;--------------------------------------- 
      WR_0   EQU 00000100B         
      WR_1   EQU 00000101B          
      RD_0   EQU 00000110B
      RD_1   EQU 00000111B       
   Trans_On  EQU 00001001B
   Trans_Off EQU 00001000B
   Time0_On  EQU 00000001B
   Time0_Off EQU 00000000B
   Time1_On  EQU 00000011B
   Time1_Off EQU 00000010B
   ;---------------------------------------          
                     ;xxx
       code0 EQU 10000000B 
       code1 EQU 10001000B
       code2 EQU 10010000B
       code3 EQU 10011000B
       code4 EQU 10100000B
   ;---------------------------------------    
      speed0 EQU 12000
      speed1 EQU 14100
      speed2 EQU 14820
      speed3 EQU 15180
   ;---------------------------------------   
                     
  DATA SEGMENT
    
  bit_count DB 5
  tot_count DB 5
 send_code  DB ?
 
 ntot_count DB ?                    ; next total count
nsend_code  DB ?                    ; next sent_code
 
 
     IsRead DB 0
  ValueRead DB ?
   TimeRead DW 0
    
  DATA ENDS
  
  
 STACK SEGMENT
            DW 100 DUP(0)
        TOS Label Word    
 STACK ENDS  


  CODE SEGMENT
       ASSUME CS:CODE , DS:DATA
     
        ;******************
        
 start: MOV AX , DATA               ; initialize DS , SS , SP
        MOV DS , AX
        
        MOV AX , STACK
        MOV SS , AX
        
        MOV SP , offset TOS
        
        ;*****************
        
        MOV AL , 10010000B          ; initialize 8255 : both A & B are in mode 0 , PortA  is input 
        OUT PortCont  , AL          ;                   PortB & PortC are output
        
        MOV AL , WR_1
        OUT PortCont  , AL
        MOV AL , RD_1
        OUT PortCont  , AL                   
                                    
        ;*****************
        
        MOV AL , 00110100B          ; initialize Timer0  --> used as 16 bit counter
        OUT TimerCont , AL
        MOV AL , 0FFH
        OUT Timer0    , AL
        OUT Timer0    , AL
        
        ;*****************
        
        MOV AL , 01110100B          ; initialize Timer1  --> generates 1kHZ pulse (1ms interval)
        OUT TimerCont , AL
        MOV AL , 0E8H
        OUT Timer0    , AL
        MOV AL , 03H
        OUT Timer0    , AL
        
        ;*****************          ; initialize 8259 to handle two interrupt sources
        
        MOV AL , 00010011B          ; ICW1
        OUT Port8259A , AL
        MOV AL , 00100000B          ; ICW2
        OUT Port8259B , AL       
        MOV AL , 00000001B          ; ICW4
        OUT Port8259B , AL     
        MOV AL , 11111100B          ; OCW1
        OUT Port8259B , AL     
        
        ;*****************   
        
        MOV AX , 0000H              ; initialize interrupt-vector table
        MOV ES , AX
        MOV WORD PTR ES:0080H , offset CONVR  ; INT 32H
        MOV WORD PTR ES:0082H , seg    CONVR
        MOV WORD PTR ES:0084H , offset TRANS  ; INT 33H
        MOV WORD PTR ES:0086H , seg    TRANS 
           
        ;****************
                                    
        MOV AL    , WR_0            ; start first conversion
        OUT PortCont , AL
        MOV AL    , WR_1
        OUT PortCont , AL
        STI
        
  HERE: JMP HERE                    ; keep waiting by wasting time
  
  ;----------------------------------      
         
  TRANS PROC NEAR                   ; fired by timer1
        
        CMP bit_count , 00H         ; are all bits sent?
        JE  sent
        
        RCL send_code , 1           ; send next bit
        DEC bit_count               ; decrement bit counter 
        JNC trnoff
        MOV AL , Trans_On           ; load control word for turning on  transmitter
        OUT PortCont , AL           ; turn on  transmitter
trnoff: MOV AL , Trans_Off          ; load control word for turning off transmitter 
        OUT PortCont , AL           ; turn off transmitter
        JMP fin                   
        
  sent: CMP tot_count , 00H         ; is waiting period spent?
        JE  ref
        
        DEC tot_count               ; decrement total counter
        MOV AL , Trans_Off          ; load control word for turning off transmitter
        OUT PortCont , AL           ; turn off transmitter
        JMP fin 
               
   ref: MOV AL        , ntot_count
        MOV tot_count , AL          ; load new tot_count
        MOV AL        , nsend_code
        MOV send_code , AL          ; load new send_code
        MOV bit_count , 05H   
        
        MOV AL        , 20H         ; OCW2 for manual end of interrupt
        OUT Port8259A , AL
        
   fin: IRET
        
  TRANS ENDP
  
  ;---------------------------------
  
  CONVR PROC NEAR
        
        MOV AL , RD_0               ; reset INTR output of ADC
        OUT PortCont , AL
        MOV AL , RD_1
        OUT PortCont , AL
        
        MOV AL , Time0_Off          ; load control word for stopping Timer0 
        OUT PortCont , AL           ; stop Timer0
        
        IN  AL , Timer0
        MOV BL , AL                 ; move LSB from AL to BL
        IN  AL , Timer0
        MOV BH , AL                 ; move MSB from AL to BH 
        
        IN  AL , PortA              ; read value of sine-cosine
        CMP IsRead , 01H            ; is this one , second read?
        JE  comp
        
        MOV TimeRead  , BX          ; store time interval between two read
        MOV ValueRead , AL          ; store value read
        MOV IsRead , 01H            ; first value is read
        
  comp: CMP ValueRead , AL          ; is read value equal with first value?
        JNE ende
        
        MOV IsRead , 00H
        SUB BX , TimeRead           ; find corresponding code
        MOV AX , 0C6C0H             ; 3 M : 3000000 [dec] : 2DC6C0 [hex]
        MOV DX ,  002DH             ; (6MHZ) / Period = (3MHZ) / (Period/2) = (3MHZ) / Calculated Time Interval
        DIV BX                      ;                                                                            gives RPM
        
  try0: CMP AX , speed0             ;      0 - speed0 interval
        JA  try1
        
        MOV nsend_code , code0      ; load corresponding code
        MOV ntot_count , 5          ; load total count
        JMP ende
        
  try1: CMP AX , speed1             ; speed0 - speed1 interval
        JA  try2
        
        MOV nsend_code , code1      ; load corresponding code
        MOV ntot_count , 5          ; load total count
        JMP ende
                
  try2: CMP AX , speed2             ; speed1 - speed2 interval
        JA  try3
        
        MOV nsend_code , code2      ; load corresponding code
        MOV ntot_count , 5          ; load total count
        JMP ende
        
   
  try3: CMP AX , speed3             ; speed2 - speed3 interval
        JA  try4
        
        MOV nsend_code , code3      ; load corresponding code
        MOV ntot_count , 95         ; load total count
        JMP ende                    
                                    ; speed3 - Inf    interval
                                    
  try4: MOV nsend_code , code4      ; load corresponding code
        MOV ntot_count , 5          ; load total count
        
        
  ende: MOV AL , Time0_On           ; load control word for restarting Timer0
        OUT TimerCont , AL          ; restart Timer0 
         
        MOV AL    , WR_0            ; start next conversion
        OUT PortCont , AL
        MOV AL    , WR_1
        OUT PortCont , AL
    
        IRET
    
  CONVR ENDP
  
  ;----------------------------------
    
  CODE  ENDS
  
        END start