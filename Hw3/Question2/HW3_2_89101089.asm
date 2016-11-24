   ;8086 PROGRAM HW3_2_89101089.ASM
   ;ABSTRACT  : This program draws a red square in graphic mode 
   ;REGISTERS : Uses CS , DS , SS , SP , AX , BX , CX , DX  
   ;PORTS     : ---
   ;PROCEDURES: ---

                       DATA SEGMENT
                            
                         Up DB  10                  ; maximum value for y
                       Down DB  20                  ; minimum value for y
                       Left DB  10                  ; minimum value for x
                      Right DB  20                  ; maximum value for x
                            
                       DATA ENDS                       
                       
                       
                      STACK SEGMENT STACK
                        
                            DW    30
                       TOS  LABEL WORD     
                        
                        
                      STACK ENDS
                      
                      
                       CODE SEGMENT 
                        
                            ASSUME CS:CODE , DS:DATA , SS:STACK 
                        
                     START: MOV AX   ,  DATA        ; initialize segment base registers
                            MOV DS   ,  AX
                            MOV ES   ,  AX
                            MOV AX   ,  STACK
                            MOV SS   ,  AX
                            MOV SP   ,  offset TOS
                        
                            MOV AH   ,  0
                            MOV AL   ,  12H         ; set resolution to 720*400
                            INT 10H                 ; activate vga mode
                            
                            XOR CH   ,  CH          ; make CH zero
                            XOR DH   ,  DH          ; make DH zero
                            
                            MOV AL   ,  00000100B   ; set color to red
                            MOV AH   ,  0CH         ; use function 0CH in INT21
                            
                            MOV CL   ,  Up
                            MOV DL   ,  Left
                            
                upper_edge: INT 10H                 ; change color of pixel pointed by (CX , DX)
                            CMP CL   ,  Right
                            JE  right_edge          ; drawing upper edge is finished , go to right edge
                            INC CL
                            JMP upper_edge
                            
                right_edge: INT 10H                 ; change color of pixel pointed by (CX , DX)
                            CMP DL   ,  Down
                            JE  lower_edge          ; drawing right edge is finished , go to lower edge
                            INC DL
                            JMP right_edge
                
                lower_edge: INT 10H                 ; change color of pixel pointed by (CX , DX)
                            CMP CL   ,  Left
                            JE  left_edge           ; drawing lower edge is finished , go to left edge
                            DEC CL
                            JMP lower_edge
                                                    ; change color of pixel pointed by (CX , DX)
                 left_edge: INT 10H
                            CMP DL   ,  Up
                            JE  end                 ; drawing is finished , halt processor 
                            DEC DL
                            JMP left_edge
                            
                            
                       end: HLT                  
                            
                       CODE ENDS
                       
                       
                            END  START