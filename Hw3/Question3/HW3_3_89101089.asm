  ; 8086 PROGRAM HW3_2b_89101089.ASM
  ; ABSTRACT  : This program controls pressure , reading pressure through sensors & controlling with actuators
  ;
  ; REGISTERS : Uses CS , DS , SS , SP , AX , BX , CX , DX
  ;  
  ; PORTS     : 20H-22H-24H-26H for 1st PPI
  ;             40H-42H-44H-46H for 2nd PPI
  ;             80H-82H         for     PIC
  ;
  ; PROCEDURES: Uses NoAlert , Display , Average , Sensor in mainline
  ;             Uses ROW0_ISR as type 64 ISR
  ;                  ROW1_ISR as type 65 ISR
  ;                  ROW2_ISR as type 66 ISR
  ;                  ROW3_ISR as type 67 ISR
                              
                 ;--------------------------- Bit set/reset control words for Lower PortC 
                 
       InjectON  EQU  00000001B
       InjectOFF EQU  00000000B
       
      ReleaseON  EQU  00000011B
      ReleaseOFF EQU  00000010B
      
      ConvertON  EQU  00000101B
      ConvertOFF EQU  00000100B
                 
                 ;--------------------------- 
                                    
          PortA1 EQU  20H   
          PortB1 EQU  22H   
          PortC1 EQU  24H 
          Contl1 EQU  26H
          
          PortA2 EQU  40H   
          PortB2 EQU  42H   
          PortC2 EQU  44H 
          Contl2 EQU  46H
          
            PIC0 EQU  80H
            PIC1 EQU  82H
                    
                 ;---------------------------
          
           DATA  SEGMENT
            
       READ_KEY  DB  0AH       
       READ_VAL  DW  8DUP(0)
       PORT_VAL  DB  0 , 1 , 2 , 3 , 4 , 5 , 6 , 7 
       
                 ;  - g f e d c b a   ; for common cathode
       SEGM_VAL  DB  00111111B        ;0
                 DB  00000110B        ;1
                 DB  01011011B        ;2
                 DB  01001111B        ;3
                 DB  01100110B        ;4
                 DB  01101101B        ;5
                 DB  01111101B        ;6
                 DB  00000111B        ;7
                 DB  01111111B        ;8
                 DB  01101111B        ;9
        
        LOW_VAL  DW   950 , 1900 , 2850 , 3800 , 4560 , 5320 , 6080 , 6840 , 7600 , 8075 
       HIGH_VAL  DW  1050 , 2100 , 3150 , 4200 , 5040 , 5880 , 6720 , 7560 , 8400 , 8925
           
           DATA  ENDS
                 
                 ;---------------------------
           
          STACK  SEGMENT STACK
            
                 DW 30
           TOS   LABEL  WORD                  
           
          STACK  ENDS 
                 
                 ;---------------------------
          
           CODE  SEGMENT
            
                 ASSUME CS:CODE , DS:DATA , SS:STACK
                 
         START:  MOV  AX , DATA    
                 MOV  DS , AX
                 MOV  AX , STACK
                 MOV  SS , AX
                 MOV  SP , offset TOS
                 
                 ;----------------------- initialize interrupt vector table
                 
                 MOV  AX , 00H
                 MOV  ES , AX
                 
                 MOV  WORD PTR ES:100H  , OFFSET ROW0_ISR
                 MOV  WORD PTR ES:102H  ,    SEG ROW0_ISR
                 
                 MOV  WORD PTR ES:104H  , OFFSET ROW1_ISR
                 MOV  WORD PTR ES:106H  ,    SEG ROW1_ISR
                 
                 MOV  WORD PTR ES:108H  , OFFSET ROW2_ISR
                 MOV  WORD PTR ES:10AH  ,    SEG ROW2_ISR
                 
                 MOV  WORD PTR ES:10CH  , OFFSET ROW3_ISR
                 MOV  WORD PTR ES:10EH  ,    SEG ROW3_ISR
                 
                 ;-----------------------
                 
                 ;initialize 8255 (1)
                 MOV  AL       , 10011000B
                 OUT  Contl1   , AL
                 
                 ;initialize 8255 (2)
                 MOV  AL       , 10001001B
                 OUT  Contl2   , AL
                 
                 ;initialize 8259
                 MOV  AL       , 00010011B
                 OUT  PIC0     , AL
                 
                 MOV  AL       , 64
                 OUT  PIC1     , AL
                 
                 MOV  AL       , 1
                 OUT  PIC1     , AL
                 
                 MOV  AL       , 11110000B 
                 OUT  PIC1     , AL
                 
                 STI
                 ;----------------------------- 
                 
          check: CMP  READ_KEY , 0AH
                 JNE  check
                 
          sense: CALL Sensor                  ; read sensors
                 CALL Average                 ; calculate average
                
                 XOR  BH       , BH
                 MOV  BL       , READ_KEY
                 ROL  BX       , 1
                  
            low: CMP  AX       , LOW_VAL[BX]  ; compare key with lower bound
                 JAE  high
                                   
                 MOV  AL       , InjectON
                 OUT  Contl1   , AL
                 JMP  sense
                 
           high: CMP  AX       , HIGH_VAL[BX] ; compare key with upper bound
                 JLE  ok
                 
                 MOV  AL       , ReleaseON
                 OUT  Contl1   , AL
                 JMP  sense
                 
             ok: CALL NoAlert
                 JMP  sense    
                 
                 ;---------------------------- Keyboard Interrupt
                 
           PROC  ROW0_ISR FAR
            
        next01:  MOV  AL       , 00000110B
                 OUT  PortB2   , AL
                 IN   AL       , PortC2
                 TEST AL       , 00000001B
                 JZ   next02
                 
                 MOV  READ_KEY , 3 
                 
        next02:  MOV  AL       , 00000101B
                 OUT  PortB2   , AL
                 IN   AL       , PortC2
                 TEST AL       , 00000001B
                 JZ   next03
                 
                 MOV  READ_KEY , 2 
                 
        next03:  MOV  AL       , 00000011B
                 OUT  PortB2   , AL
                 IN   AL       , PortC2
                 TEST AL       , 00000001B
                 JZ   exit0        
                                 
                 MOV  READ_KEY , 1
                 
         exit0:  MOV  AL       , 20H
                 OUT  PIC0     , AL
                 IRET
            
           ENDP  ROW0_ISR
                 
                 ;---------------------------    
                     
           PROC  ROW1_ISR FAR
            
        next11:  MOV  AL       , 00000110B
                 OUT  PortB2   , AL
                 IN   AL       , PortC2
                 TEST AL       , 00000010B
                 JZ   next12
                 
                 MOV  READ_KEY , 6 
                 
        next12:  MOV  AL       , 00000101B
                 OUT  PortB2   , AL
                 IN   AL       , PortC2
                 TEST AL       , 00000010B
                 JZ   next13
                 
                 MOV  READ_KEY , 5 
                 
        next13:  MOV  AL       , 00000011B
                 OUT  PortB2   , AL
                 IN   AL       , PortC2
                 TEST AL       , 00000010B
                 JZ   exit1        
                                 
                 MOV  READ_KEY , 4
                 
         exit1:  MOV  AL       , 20H
                 OUT  PIC0     , AL
                 IRET
            
           ENDP  ROW1_ISR
                 
                 ;---------------------------
                 
           PROC  ROW2_ISR FAR
            
        next21:  MOV  AL     , 00000110B
                 OUT  PortB2 , AL
                 IN   AL     , PortC2
                 TEST AL     , 00000100B
                 JZ   next22
                 
                 MOV  READ_KEY , 9 
                 
        next22:  MOV  AL     , 00000101B
                 OUT  PortB2 , AL
                 IN   AL     , PortC2
                 TEST AL     , 00000100B
                 JZ   next23
                 
                 MOV  READ_KEY , 8 
                 
        next23:  MOV  AL     , 00000011B
                 OUT  PortB2 , AL
                 IN   AL     , PortC2
                 TEST AL     , 00000100B
                 JZ   exit2        
                                 
                 MOV  READ_KEY , 7
                 
         exit2:  MOV  AL     , 20H
                 OUT  PIC0   , AL
                 IRET                  
            
           ENDP  ROW2_ISR
                 
                 ;---------------------------
                 
           PROC  ROW3_ISR FAR
                  
                 MOV  AL     , 00000101B
                 OUT  PortB2 , AL
                 IN   AL     , PortC2
                 TEST AL     , 00001000B
                 JZ   exit3
                 
                 MOV  READ_KEY , 0 
                 
         exit3:  MOV  AL     , 20H
                 OUT  PIC0   , AL
                 IRET
            
           ENDP  ROW3_ISR
                            
                 ;---------------------------
                 
           PROC  NoAlert  NEAR
                 
                 MOV AL     , ReleaseOFF
                 OUT Contl1 , AL
                 
                 MOV AL     , InjectOFF
                 OUT Contl1 , AL
                  
                 RET
                 
           ENDP  NoAlert       
                                                              
                 ;--------------------------- Display Subroutine
                 
           PROC  Display  NEAR
                                  
                 MOV  AL     , SEGM_VAL[BX]
                 OUT  PortA2 , AL 
                 RET
                                              
           ENDP  Display 
           
                 ;----------------------------
                 
           PROC  Average
                 
                 MOV  CX , 8
                 MOV  SI , 0
                 
          Again: ADD  AX , READ_VAL[SI]
                 INC  SI   
                 LOOP Again
                 
                 XOR  DX , DX
                 MOV  CL , 8
                 DIV  CL
                 
                 ;quotient is in AX
                 
                 RET
                 
           ENDP  Average 
           
                 ;----------------------------
                 
            PROC Sensor
                 
                 MOV  CX , 8
                 MOV  SI , 0
                 MOV  AH , 0                 
                 
         Again2: MOV  AL , PORT_VAL[SI]
                 OUT  PortB1 , AL
                 
                 MOV  AL , ConvertOFF
                 OUT  Contl1 , AL
                 MOV  AL , ConvertON
                 OUT  Contl1 , AL
                 
         Check2: IN   AL    , PortC1
                 TEST AL    , 16
                 JNZ  Check2
                 
                 IN   AL    , PortA1
                 
                 ROL  SI    , 1
                 MOV  READ_VAL[SI] , AX
                 ROR  SI    , 1
                                    
                 INC  SI
                 LOOP Again2
                 
                 RET
                 
            ENDP Sensor         
           
            
           CODE  ENDS
           
                 END  START