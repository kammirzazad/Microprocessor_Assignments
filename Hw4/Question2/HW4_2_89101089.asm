; 8086 PROGRAM HW4_2_89101089.ASM
;
; ABSTRACT  : Assembly program for module connecting serial port of computer to wireless module (wireless modem)
;
; REGISTERS : Uses CS , DS , ES , SS , SP , BP , AX , BX , SI, DI 
;                 
;             SI     > Pointer to  serial   buffer                     : RECV_S
;             DI     >   "     for sending  data in serial   buffer    : SEND_W
;             BX     >   "     to  wireless buffer                     : RECV_W
;             BP     >   "     for sending  data in wireless buffer    : SEND_S
;
; PORTS     : Uses 20H-22H-24H-26H > 8255 PPI
;                  40H-.......-4EH > 8250 UART
;
; PROCEDURES: INIT   > Initializes peripheral ICs 
;             SEND_W > Sends    next data to   Wireless Module through 8255
;             RECV_W > Receives  "    "   from   "        "       "     "  
;             SEND_S > Sends     "    "   to   Serial   Port      "    8250
;             RECV_S > Receives  "    "   from   "        "       "     "
;
;-----------------------------------------------------------------------------------
        
     PA EQU  20H
     PB EQU  22H    
     PC EQU  24H
    CON EQU  26H
   
    SR0 EQU  40H                  ; RX-TX     Buffer         Register
    SR1 EQU  42H                  ; Interrupt Enable            "
    SR2 EQU  44H                  ; Interrupt Identification    "
    SR3 EQU  46H                  ; Line      Control           "
    SR4 EQU  48H                  ; Modem     Control           "
    SR5 EQU  4AH                  ; Line      Status            "
    SR6 EQU  4CH                  ; Modem     Status            "
    SR7 EQU  4EH                  ; Stratch                     "
    
        ;****************     
                            
   DATA SEGMENT
    
  BUFF1 DB 100 DUP(?)             ; For data read from serial 
  BUFF2 DB 100 DUP(?)             ; For data read from wireless module 
    
   DATA ENDS
   
        ;----------------
  
  STACK SEGMENT STACK                        
                            
        DW    50 DUP(?)        
    TOS LABEL WORD                        
                            
  STACK ENDS                          
                            
        ;----------------                    
                            
   CODE SEGMENT
        
        ASSUME CS:CODE , DS:DATA , ES:DATA , SS:STACK
        
 START: MOV  AX   , DATA          ; initialize segment registers         
        MOV  DS   , AX
        MOV  ES   , AX
        
        MOV  AX   , STACK
        MOV  SS   , AX
        MOV  SP   , offset TOS
         
        CALL INIT        
        
S_RECV: IN   AL   , SR5           ; Read line status
        TEST AL   , 01H           ; check for data receive
        JZ   S_SEND
        
        CALL RECV_S
        JMP  W_RECV
        
        ;^^^^^^^^^^^^^^
        
S_SEND: TEST AL   , 20H           ; check for end of transmission
        JZ   W_RECV
        
        CALL SEND_S
        
        ;^^^^^^^^^^^^^^
        
W_RECV: IN   AL   , PC            ; read interrupts status
        TEST AL   , 00001000B
        JZ   W_SEND
        
        CALL RECV_W
        JMP  S_RECV
        
        ;^^^^^^^^^^^^^^
               
W_SEND: TEST AL   , 00000001B
        JZ   S_RECV
        
        CALL SEND_W
        JMP  S_RECV
        
        ;^^^^^^^^^^^^^^
        
   INIT PROC NEAR
        
        MOV  SI  , offset BUFF1
        MOV  DI  , SI
        
        MOV  BX  , offset BUFF2
        MOV  BP  , BX
        
        MOV  AL  , 3
        OUT  SR4 , AL             ; Initialize modem control register 
        
        MOV  AL  , 10011011B      ; Even parity - 1 stop bit - DLAB=1
        OUT  SR3 , AL             ; Initialize line control register
        
        MOV  AL  , 39
        OUT  SR0 , AL             ; Initialize divisor latch LSB
        MOV  AL  , 0
        OUT  SR1 , AL             ; Initialize divisor latch MSB
        
        MOV  AL  , 00011011B      ; DLAB=0
        OUT  SR3 , AL
        
        MOV  AL  , 10100111B      ; PortA in mode1 & output - PortB in mode1 & input
        OUT  CON , AL
        MOV  AL  , 00001101B      ; Enable output interrupt
        OUT  CON , AL
        MOV  AL  , 00000101B      ; Enable  input interrupt
        OUT  CON , AL
        
        RET        
   INIT ENDP  
        
        ;--------
        
 RECV_W PROC NEAR
                                  ; Save character received from wireless module 
        IN  AL   , PA
        MOV [BX] , AL
        INC BX  
        
        RET
 RECV_W ENDP
        
        ;-------- 
        
 RECV_S PROC NEAR
        
        IN   AL   , SR0           ; Read  character from 8250
        MOV  [SI] , AL            ; Store character read from serial port          
        INC  SI
        
        RET
 RECV_S ENDP        
        
        ;--------
        
 SEND_W PROC NEAR
        
        CMP  SI  , offset BUFF1
        JNE  DO
        RET
      
    DO: MOV  AL  , [DI]           ; Send character to wireless module
        OUT  PA  , AL
        INC  DI
        
        CMP  SI  , DI             ; Are all characters sent?
        JE   DO2
        RET
          
   DO2: MOV  SI  , offset BUFF1   ; Reset buffer1 pointers
        MOV  DI  , SI              
        RET
                
 SEND_W ENDP
 
        ;--------
        
 SEND_S PROC NEAR       
        
        CMP  BP  , offset BUFF2   ; If any character is received 
        JNE  L1                   ;              do nothing
        RET
        
    L1: MOV  AL  , [BP]
        OUT  SR0 , AL             ; Send next character to 8250
        INC  BP
        
        CMP  BP  , BX             ; Are all characters sent ?
        JE   L2
        RET
        
    L2: MOV  BX  , offset BUFF2   ; Reset buffer2 pointers
        MOV  BP  , BX
        RET
        
 SEND_S ENDP
 
        ;--------
                            
   CODE ENDS                         
                            
        END START                    
                              