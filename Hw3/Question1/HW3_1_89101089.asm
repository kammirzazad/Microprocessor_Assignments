   ;8086 PROGRAM HW3_1_89101089.ASM
   ;ABSTRACT  : This program creates text file named by user than searches it for entered string 
   ;REGISTERS : Uses CS , DS , SS , SP , AX , BX , CX , DX , DI , SI  
   ;PORTS     : ---
   ;PROCEDURES: ---
                      
                      
                      DATA SEGMENT 
                                                                
                String_Max DB    127
                     Real2 DB    ?
                    String DB    127 DUP(?)
                    
                      Max1 DB    8
                     Real1 DB    ?
                  FileName DB    11 DUP(0)  
                          
                    Length DB    ?                    
                   NameExt DB    ".txt" , 0                    
                DataBuffer DB    255 DUP(?)
                FileHandle DW    ?
                  
                     MESS1 DB    "Input file name: $" 
                     MESS2 DB    0DH , 0AH , "input text: $"
                     MESS3 DB    0DH , 0AH , "Input search string: $"
                     
                     MESS4 DB    0DH , 0AH , "Entered string found $"
                     MESS5 DB    0DH , 0AH , "Entered string not found $"
                                                
                        
                      DATA ENDS   
                           
                           ;-------------------------------------
                      
                     STACK SEGMENT STACK
                        
                           DW    15 DUP(?)
                       TOS LABEL WORD     
                        
                     STACK ENDS 
                        
                           ;-------------------------------------
                                               
                      CODE SEGMENT
                           ASSUME CS:CODE , DS:DATA , ES:DATA , SS:STACK
                      
                    START: MOV   AX   , DATA
                           MOV   DS   , AX
                           MOV   ES   , AX
                           MOV   AX   , STACK
                           MOV   SS   , AX
                           MOV   SP   , offset TOS
                           
                           ;----------------------------------------------------
         
                           MOV   DX   , offset MESS1    ; Display 1st message
                           MOV   AH   , 09
                           INT   21H
                           
                           MOV   DX   , offset Max1     ; Get filename
                           MOV   AH   , 0AH
                           INT   21H
                           
                           MOV   CX   , offset FileName
                           ADD   CL   , Real1
                           MOV   DI   , CX
                           MOV   SI   , offset NameExt
                           MOV   CX   , 5               ; 4(.txt) + 1(0) = 5
                           CLD 
                           REP   MOVSB                  ; append file extension to filename 
                           
                           MOV   CX   , 0
                           MOV   DX   , offset FileName                                  
                           MOV   AH   , 3CH
                           INT   21H                    ; create file 
                           
                           ;----------------------------------------------------
                           
                           MOV   DX   , offset MESS2    ; Display 2nd message
                           MOV   AH   , 09H
                           INT   21H
                           
                           MOV   DX   , offset String_Max  ; Get input text
                           MOV   AH   , 0AH
                           INT   21H
                                                                                                            
                           MOV   DX   , offset FileName
                           MOV   AH   , 3DH
                           MOV   AL   , 02              ; Read / Write
                           INT   21H                    ; Get handle to file
                           MOV   FileHandle , AX
                           
                           
                           MOV   BX   , FileHandle
                           MOV   CL   , Real2
                           MOV   Length , CL            ; Back up length of input text
                           XOR   CH   , CH                           
                           MOV   DX   , offset String
                           MOV   AH   , 40H
                           INT   21H                    ; Write input text to file 
                           
                           ;----------------------------------------------------
                           
                           MOV   DX   , offset MESS3    ; Display 3rd message
                           MOV   AH   , 09H
                           INT   21H
                           
                           MOV   DX   , offset String_Max  ; Get search string
                           MOV   AH   , 0AH
                           INT   21H
                           
                           
                           MOV   AH   , 42H
                           MOV   AL   , 0
                           MOV   BX   , FileHandle
                           MOV   CX   , 0
                           MOV   DX   , 0
                           INT   21H                           
                           
                           MOV   CL   , Length 
                           XOR   CH   , CH
                           MOV   DX   , offset DataBuffer
                           MOV   AH   , 3FH
                           INT   21H                    ; Read text from file
                           
                           ;----------------------------------------------------
                           
                           CLD
                           MOV   SI   , offset String
                           MOV   DI   , offset DataBuffer
                           MOV   CL   , Length
                           XOR   CH   , CH                          
                           
                   Again:  MOV   AL   , [SI]                            
                           REPNE SCASB                  ; Repeat until two characters are not equal
                           
                           CMP   CX , 0
                           JNE   check
                           JMP   Not_Found              ; Display 5th message+
                           
                   check:  PUSH  SI                     ; Store   SI
                           PUSH  DI                     ; Store   DI
                           PUSH  CX                     ; Store   CX
                                   
                           MOV   CL   , Real2
                           XOR   CH   , CH
                           DEC   DI
                           REPE  CMPSB                  ; Compare two strings
                           
                           JE    Found                  
                           
                           POP   CX                     ; Restore CX
                           POP   DI                     ; Restore DI
                           POP   SI                     ; Restore SI
                           JMP   Again 
                           
                           ;----------------------------------------------------
                           
                   Found:  MOV   DX   , offset MESS4    ; Display 4th message
                           MOV   AH   , 09H
                           INT   21H
                           HLT
                                                         
               Not_Found:  MOV   DX   , offset MESS5    ; Display 5th message
                           MOV   AH   , 09H
                           INT   21H      
                           HLT
                           
                           ;----------------------------------------------------
                           
                      CODE ENDS
                      
                           END START 
                           