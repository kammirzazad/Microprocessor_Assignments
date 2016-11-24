  ;8086 PROGRAM HW3_2b_89101089.ASM
  ;ABSTRACT  : This program draws a red square in graphic mode & moves it in screen
  ;REGISTERS : Uses CS , DS , SS , SP , AX , BX , CX , DX  
  ;PORTS     : ---
  ;PROCEDURES: Print (draws square in new location with given color [red/black])
                 
                   
                   left_dir  EQU  4bH
                  right_dir  EQU  4dH
                     up_dir  EQU  48H
                   down_dir  EQU  50H
                  max_width  EQU  630
                  max_height EQU  480
                                       
                       DATA SEGMENT
                                                                                              
                         Up DW  10   
                       Down DW  40
                       Left DW  10
                      Right DW  40
                      
                    KeyCode DB  ?
                                                  
                       DATA ENDS                       
                       
                       
                     STACK0 SEGMENT  STACK
                      
                            DW    100
                       TOS  LABEL WORD     
                                               
                     STACK0 ENDS
                      
                      
                       CODE SEGMENT 
                        
                            ASSUME CS:CODE , DS:DATA , SS:STACK0 
                        
                     START: MOV  AX   ,  DATA        ; housekeeping stuff
                            MOV  DS   ,  AX
                            MOV  AX   ,  STACK0
                            MOV  SS   ,  AX
                            MOV  SP   ,  offset TOS
                        
                            MOV  AH   ,  0
                            MOV  AL   ,  12H
                            INT  10H                 ; activate graphic mode
                            
                            XOR  CH   ,  CH
                            XOR  DH   ,  DH
                            
                            MOV  AL   ,  00000100B 
                            CALL Print
                            
                    Again:  MOV  AH   ,  07H
                            INT  21H
                            
                            MOV  KeyCode , AL ;AH
   
                                                        
               check_left:  CMP  KeyCode , 'L'       ; left_dir
                            JE   draw_left
                            CMP  KeyCode , 'l'
                            JNE  check_right                            
                            
                draw_left:  CMP  Left , 0
                            JE   Again
                            
                            MOV  AL   ,  00000000B   ; set color to black
                            CALL Print               ; erase square
                            MOV  AL   ,  00000100B   ; set color to red
                            
                            DEC  Left
                            DEC  Right
                            CALL Print               ; draw new square
                            JMP  Again
                                                        
                            
              check_right:  CMP  KeyCode , 'R'       ; right_dir
                            JE   draw_rigth
                            CMP  KeyCode , 'r'
                            JNE  check_down                              
                            
               draw_rigth:  CMP  Right , max_width
                            JE   Again
                            
                            MOV  AL   ,  00000000B   ; set color to black
                            CALL Print               ; erase square
                            MOV  AL   ,  00000100B   ; set color to red
                            
                            INC  Left
                            INC  Right
                            CALL Print               ; draw new square
                            JMP  Again
                            
                                               
               check_down:  CMP  KeyCode , 'D'       ; down_dir
                            JE   draw_down
                            CMP  KeyCode , 'd'
                            JNE  check_up
                            
                draw_down:  CMP  Down , max_height
                            JE   Again
                            
                            MOV  AL   ,  00000000B   ; set color to black
                            CALL Print               ; erase square
                            MOV  AL   ,  00000100B   ; set color to red
                                                        
                            INC  Up
                            INC  Down
                            CALL Print               ; draw new square
                            JMP  Again
                            
                            
                 check_up:  CMP  KeyCode , 'U'       ; up_dir
                            JE   draw_up
                            CMP  KeyCode , 'u'
                            JNE  Again
                           
                  draw_up:  CMP  Up   , 0
                            JE   Again
                            
                            MOV  AL   ,  00000000B   ; set color to black 
                            CALL Print               ; erase square
                            MOV  AL   ,  00000100B   ; set color to red
                                                     
                            DEC  Up
                            DEC  Down
                            CALL Print               ; draw new square
                            JMP  Again
                            
                       
                       PROC Print
                            
                            MOV AH   ,  0CH
                              
                            MOV CX   ,  Left
                            MOV DX   ,  Up
                            
                upper_edge: INT 10H                  ; draw upper edge
                            CMP CX   ,  Right
                            JE  right_edge
                            INC CX
                            JMP upper_edge
                            
                right_edge: INT 10H                  ; draw rigth edge
                            CMP DX   ,  Down
                            JE  lower_edge
                            INC DX
                            JMP right_edge
                
                lower_edge: INT 10H                  ; draw lower edge
                            CMP CX   ,  Left
                            JE  left_edge
                            DEC CX
                            JMP lower_edge
                            
                 left_edge: INT 10H                  ; draw left  edge
                            CMP DX   ,  Up
                            JE  End
                            DEC DX
                            JMP left_edge
                            
                      End:  RET  
                        
                        
                       ENDP Print
                                                                
                            
                       CODE ENDS
                       
                       
                        END  START