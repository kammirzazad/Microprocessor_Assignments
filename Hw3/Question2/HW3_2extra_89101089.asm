  ;8086 PROGRAM HW3_2extra_89101089.ASM
  ;ABSTRACT  : This program draws a blue circle in graphic mode & moves it in screen
  ;REGISTERS : Uses CS , DS , SS , SP , AX , BX , CX , DX  
  ;PORTS     : ---
  ;PROCEDURES: Print (draws circle in new location with given color [blue/black])
                 
                   
                   left_dir  EQU  4bH
                  right_dir  EQU  4dH
                     up_dir  EQU  48H
                   down_dir  EQU  50H
                  max_width  EQU  630-10
                  max_height EQU  480-10
                                       
                       DATA SEGMENT
                                                                                              
                       
                ; Actual values  10 , 9.659 , 8.66 , 7.07 , 5 , 2.588 , 0 
                      
                    CircleX DW   10 ,  10 ,  9 ,  7 ,  5 ,   3 ,   0 
                            DW    0 ,  -3 , -5 , -7 , -9 , -10 , -10
                            DW  -10 , -10 , -9 , -7 , -5 ,  -3 ,   0
                            DW    0 ,   3 ,  5 ,  7 ,  9 ,  10 ,  10
                                                           
                    CircleY DW    0 ,   3 ,  5 ,  7 ,  9 ,  10 ,  10  
                            DW   10 ,  10 ,  9 ,  7 ,  5 ,   3 ,   0 
                            DW    0 ,  -3 , -5 , -7 , -9 , -10 , -10
                            DW  -10 , -10 , -9 , -7 , -5 ,  -3 ,   0
                            
                    CenterX DW   10
                    CenterY DW   10
                      
                    KeyCode DB  ?
                                                  
                       DATA ENDS
                       
                            ;-------------------------
                       
                     STACK0 SEGMENT STACK
                            
                            DW    100
                       TOS  LABEL WORD
                       
                     STACK0 ENDS
                     
                            ;-------------------------
                                             
                       CODE SEGMENT 
                        
                            ASSUME CS:CODE , DS:DATA , SS:STACK0  
                        
                     START: MOV  AX   ,  DATA          ; housekeeping stuff
                            MOV  DS   ,  AX
                            MOV  AX   ,  STACK0
                            MOV  SS   ,  AX
                            MOV  SP   ,  offset TOS
                        
                            MOV  AH   ,  0             
                            MOV  AL   ,  12H
                            INT  10H                   ; activate graphic mode
                                                        
                            MOV  AL   ,  1             ; set color to blue
                            CALL Print                 ; draw first circle
                            
                   Again:   MOV  AH   ,  7
                            INT  21H
                            
                            MOV  KeyCode , AL
                                                        
               check_left:  CMP  KeyCode , 'L'         ; left_dir
                            JE   draw_left
                            CMP  KeyCode , 'l'
                            JNE  check_right
                            
                draw_left:  CMP  CenterX , 10
                            JE   Again
                            
                            MOV  AL   ,  0             ; set color to black
                            CALL Print                 ; erase circle
                            MOV  AL   ,  1             ; set color to blue
                            
                            DEC  CenterX
                            CALL Print                 ; draw new circle
                            JMP  Again
                                                        
                            
              check_right:  CMP  KeyCode , 'R'         ; right_dir
                            JE   draw_right
                            CMP  KeyCode , 'r'
                            JNE  check_down 
                            
               draw_right:  CMP  CenterX , max_width
                            JE   Again
                            
                            MOV  AL   ,  0             ; set color to black
                            CALL Print                 ; erase circle
                            MOV  AL   ,  1             ; set color to blue
                            
                            INC  CenterX
                            CALL Print                 ; draw new circle
                            JMP  Again
                            
                            
               check_down:  CMP  KeyCode , 'D'         ; down_dir
                            JE   draw_down
                            CMP  KeyCode , 'd'                                    
                            JNE  check_up
                            
                draw_down:  CMP  CenterY , max_height
                            JE   Again
                            
                            MOV  AL   ,  0             ; set color to black
                            CALL Print                 ; erase circle
                            MOV  AL   ,  1             ; set color to blue
                                                        
                            INC  CenterY
                            CALL Print                 ; draw new circle
                            JMP  Again
                            
                            
                 check_up:  CMP  KeyCode , 'U'         ; up_dir
                            JE   draw_up
                            CMP  KeyCode , 'u' 
                            JNE  Again
                            
                  draw_up:  CMP  CenterY  , 10
                            JE   Again
                            
                            MOV  AL   ,  0             ; set color to black
                            CALL Print                 ; erase circle
                            MOV  AL   ,  1             ; set color to blue
                            
                            DEC  CenterY
                            CALL Print                 ; draw new circle
                            JMP  Again
                            
                       
                       PROC Print
                            
                            MOV AH   ,  0CH                                                        
                            MOV BX   ,  28
                            
                    Draw:   ROL BX   ,  1
                    
                            MOV CX   ,  CircleX[BX]
                            MOV DX   ,  CircleY[BX]
                            
                            ADD CX   ,  CenterX
                            ADD DX   ,  CenterY
                            
                            INT 10H
                            ROR BX   ,  1
                            
                            DEC BX
                            JNZ Draw  
                                                          
                            RET  
                        
                       ENDP Print
                                                                
                            
                       CODE ENDS
                       
                       
                        END  START