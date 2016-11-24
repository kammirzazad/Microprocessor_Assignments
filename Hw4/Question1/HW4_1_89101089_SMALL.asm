  ;8086 PROGRAM HW4_1_89101089.ASM
  ;ABSTRACT  : Paint program with 8 colors and airbrush
  ;REGISTERS : Uses CS , DS , ES , SS , SP , BP , AX , BX , CX , DX , SI  
  ;PORTS     : ---
  ;PROCEDURES:    AIR : Apply air brush to current point
  ;              DRAW : Apply current brush to current point
  ;              INIT : Initializes display & mouse
  ;             BRUSH : Changes color of single pixel pointed by (CX,DX) to CUR_COLOR
  ;             CLEAR : Changes color of current point to BLACK                       
  ;             COLOR : Chooses new color based on the value of CX
  ;            CHOOSE : Chooses new brush mode based on the value of CX                             
                
        Y_BRUSH EQU  20
        Y_COLOR EQU 300
      
       X_WHITE  EQU   0 ; 0
       X_YELLOW EQU  40 ; 1
       X_MAGEN  EQU  80 ; 2
       X_RED    EQU 120 ; 3 
       X_BLUE   EQU 160 ; 4
       X_GREEN  EQU 200 ; 5 
       X_GRAY   EQU 240 ; 6
       X_BROWN  EQU 280 ; 7
         
         BLACK  EQU 0
         
         WHITE  EQU 0FH
         YELLOW EQU 0EH
         MAGEN  EQU 05H
         RED    EQU 04H
         BLUE   EQU 01H
         GREEN  EQU 02H
         GRAY   EQU 07H
         BROWN  EQU 06H
                
                ;--------------
           
           DATA SEGMENT
                
      CUR_COLOR DB 0 ; 0-7 Values
      CUR_STATE DB 0 ; 0->Brush / 1->Eraser
      
         COLORS DW 000FH   , 000EH    , 0005H   , 0004H , 0001H  , 0002H   , 0007H  , 0006H   , ?            
         STARTS DW X_WHITE , X_YELLOW , X_MAGEN , X_RED , X_BLUE , X_GREEN , X_GRAY , X_BROWN , 320
         
         COLOR2 DW 0003H , 000AH , 000DH ,    ?
         START2 DW    0  ,  100  ,  200  ,  320
                      
          MESS1 DB ' BRUSH '
          LENG1 DW $ - MESS1
          
          MESS2 DB ' AIR '
          LENG2 DW $ - MESS2
          
          MESS3 DB ' ERASE '
          LENG3 DW $ -  MESS3 
            
           DATA ENDS
                
                ;--------------
           
         STACK0 SEGMENT STACK
            
            DW  50 DUP(?)
           TOS  LABEL WORD
           
         STACK0 ENDS
          
                ;--------------
          
           CODE SEGMENT  
                
                ASSUME CS:CODE , DS:DATA , ES:DATA , SS:STACK0
               
         START: MOV  AX , DATA             ; initialize segment registers
                MOV  DS , AX
                MOV  ES , AX
                MOV  AX , STACK0
                MOV  SS , AX
                MOV  SP , offset TOS
                
                CALL INIT
                
         CHECK: MOV  AX , 3                ; get mouse status
                INT  33H
                
                ;*********
                
                CMP  BX , 1
                JNE  CHECK
                
                ;*********
                
       LCHOOSE: CMP  DX , Y_BRUSH
                JA   LDRAW                 ; if DX > Y_BRUSH then go to DRAW
                
                CALL CHOOSE
                JMP  CHECK
                
                ;*********       
                
         LDRAW: CMP  DX , Y_COLOR
                JA   LCOLOR                ; if DX > Y_COLOR then go to COLOR
                
                CALL DRAW
                JMP  CHECK
                 
                ;*********  
                
        LCOLOR: CALL COLOR
                JMP  CHECK 
                
                ;*********         
              
                ;-------------------
           
           INIT PROC NEAR
                
                ;initialize in video mode
                MOV  AH , 0
                MOV  AL , 12H
                INT  10H
                
                ;initialize mouse
                MOV  AX , 0
           TRY: INT  33H
                CMP  AX , 0
                JE   TRY
                
                MOV  AX , 1                  ; display mouse
                INT  33H
                
                ;draw color boxes
                MOV  SI , 0                 
                
       AGAIN3:  MOV  AX , COLORS[SI]
                MOV  AH , 0CH
                MOV  DX , 300
           
       AGAIN1:  MOV  CX , STARTS[SI]      
       AGAIN2:  INT  10H
                INC  CX
                CMP  CX , STARTS[SI+2]
                JNE  AGAIN2
                
                INC  DX 
                CMP  DX , 320
                JNE  AGAIN1
                
                ADD  SI , 2
                CMP  SI , 16                 ; check for end
                JNE  AGAIN3
                
                ;draw option boxes
                MOV  SI , 0                 
                
       AGAIN4:  MOV  AX , COLOR2[SI]
                MOV  AH , 0CH
                MOV  DX , 0
           
       AGAIN5:  MOV  CX , START2[SI]      
       AGAIN6:  INT  10H
                INC  CX
                CMP  CX , START2[SI+2]
                JNE  AGAIN6
                
                INC  DX 
                CMP  DX , 20
                JNE  AGAIN5
                
                ADD  SI , 2
                CMP  SI , 6 
                JNE  AGAIN4                  ; check for end
                
                MOV  AL , 1
                MOV  AH , 13H
                MOV  BH , 0
                MOV  BL , 15    
                MOV  DH , 0
                                             ; Display "BRUSH"
                MOV  CX , LENG1
                MOV  BP , offset MESS1
                MOV  DL , 3                
                INT  10H
                
                MOV  CX , LENG2              ; Display "AIR"
                MOV  BP , offset MESS2
                MOV  DL , 16
                INT  10H
                
                MOV  CX , LENG3              ; Display "ERASE"
                MOV  BP , offset MESS3
                MOV  DL , 29
                INT  10H               
                                  
                RET
           INIT ENDP
           
                ;-------------------
                
           DRAW PROC NEAR
                
          CHK0: CMP  CUR_STATE , 0
                JNE  CHK1
                
                CALL BRUSH
                RET
                ;********
                
          CHK1: CMP  CUR_STATE , 1
                JNE  CHK2
                
                CALL AIR
                RET
                ;*********
                
          CHK2: CALL CLEAR           
                RET
                ;*********
                
           DRAW ENDP
           
                ;-------------------
                
          CLEAR PROC NEAR
                
                MOV  AL , BLACK
                MOV  AH , 0CH          
                          
             M: INT  10H
              
             N: ADD  DX , 1 
                INT  10H
                
            NW: SUB  CX , 1
                INT  10H
                
             W: SUB  DX , 1
                INT  10H
                
            SW: SUB  DX , 1
                INT  10H
           
             S: ADD  CX , 1
                INT  10H
             
            ES: ADD  CX , 1
                INT  10H
                
             E: ADD  DX , 1
                INT  10H
                
            NE: ADD  DX , 1  
                INT  10H
                      
                RET
          CLEAR ENDP
                
                ;-------------------
                
          BRUSH PROC NEAR
                
                MOV  AH , 0CH
                MOV  AL , CUR_COLOR
                INT  10H
                
                MOV  CX , 5
                LOOP $
                ; Column is in CX
                ; Row    is in DX
                
                RET                
          BRUSH ENDP
          
                ;-------------------
                
            AIR PROC NEAR
                
                MOV  AL , CUR_COLOR
                MOV  AH , 0CH          
                          
        CENTER: INT  10H
                
          LEFT: SUB  CX , 1
                INT  10H
                
         RIGHT: ADD  CX , 2
                INT  10H
                
           TOP: SUB  CX , 1
                ADD  DX , 1
                INT  10H
          
          DOWN: SUB  DX , 2
                INT  10H
                      
                RET                
            AIR ENDP
                
                ;-------------------
           
          COLOR PROC NEAR
                
        CHECK0: CMP  CX ,  X_YELLOW
                JA   CHECK1
                MOV  CUR_COLOR , WHITE
                RET 
                
                ;***********
                
        CHECK1: CMP  CX ,  X_MAGEN
                JA   CHECK2
                MOV  CUR_COLOR , YELLOW        
                RET 
                
                ;***********
                
        CHECK2: CMP  CX , X_RED
                JA   CHECK3
                MOV  CUR_COLOR , MAGEN        
                RET 
                
                ;***********
                
        CHECK3: CMP  CX , X_BLUE
                JA   CHECK4
                MOV  CUR_COLOR , RED        
                RET 
                
                ;***********
                
        CHECK4: CMP  CX , X_GREEN
                JA   CHECK5
                MOV  CUR_COLOR , BLUE        
                RET 
                
                ;***********
                
        CHECK5: CMP  CX , X_GRAY
                JA   CHECK6
                MOV  CUR_COLOR , GREEN      
                RET
                
                ;***********
                
        CHECK6: CMP  CX , X_BROWN
                JA   CHECK7
                MOV  CUR_COLOR , GRAY        
                RET
                
                ;***********
                
        CHECK7: MOV  CUR_COLOR , BROWN
                RET
        
                ;***********                     
                
          COLOR ENDP
                
                ;-------------------
                
         CHOOSE PROC NEAR
                
        B_NORM: CMP  CX , 100
                JA   B_AIR
                
                MOV  CUR_STATE , 0
                RET
                
                ;************
                
         B_AIR: CMP  CX , 200
                JA   B_ERASE
                
                MOV  CUR_STATE , 1
                RET
                
                ;************
                
       B_ERASE: MOV  CUR_STATE , 2                       
                RET
                
                ;************
                
         CHOOSE ENDP
          
                ;------------------- 
           CODE ENDS
              
                END  START