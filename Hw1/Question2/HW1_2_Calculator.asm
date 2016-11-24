
   ;***********************
   
   DATA       SEGMENT
   
   Sen_Max    DB 127
   Sen_Real   DB ?
   Sentence   DB 127 DUP(?)
   
   ; stack pointer backup
   
   bcup_op_t  DW ?
   
   ;charachter read part
   
   char_fnd   DB 0
   char_buff  DB 5 DUP(0)
   char_coun  DB 0
   char_sum   DW 0
   
   ;calculation part
              
     operandL DW ?
     operandH DW ?
     
      Divisor DW 10
     ResWord0 DW 0
     ResWord1 DW 0
     TempWord DW 0
              
        queue DW 200 DUP(0)                            ; queue of double words
    ptr_queue DW offset queue                          ; pointer to current double word in queue
   calc_queue DW offset queue                          ; pointer used in calculating result
            
   MESS1      DB 0DH , 0AH , 'Error In Statement $' 
   MESS2      DB 0DH , 0AH , 10 DUP(0) , '$'
    
   DATA       ENDS
   
   ;************************
   
   STACK      SEGMENT Stack
    
    DW        100   DUP(0)
    sp_func   Label Word
    
    DW        100   DUP(0)                             ; stack of 100        words for ascii code of operators (+ , * , / , -)
    sp_op_t   Label Word   
    
    DW        100   DUP(0)                             ;  "       "   double words for operands during evaluation
    sp_oprnd  Label Word
       
   STACK      ENDS
   
   ;************************
 
   CODE       SEGMENT
    
    ASSUME    CS:CODE , DS:DATA , ES:DATA , SS:STACK
             
    
      START:  MOV  AX , DATA
              MOV  DS , AX                              ; initialize segments
              MOV  ES , AX
             
              MOV  AX , STACK
              MOV  SS , AX
              MOV  SP , offset sp_func
              
       read:  MOV  DX , offset Sen_Max
              MOV  AH , 0AH
              INT  21H                                  ; read input
              
              SUB  BH , BH
              MOV  BL , Sen_Real
              MOV  Sentence[BX] , '$'                   ; specify end of input
              
              MOV  AL , '$'                             ; specify first element in temporary operator stack
              CALL push_op_t
              
              SUB  CH , CH
              MOV  CL , Sen_Real
              INC  CL
              ADC  CH , 00H
              MOV  BX , offset Sentence                 ; point BX to start of input
              
   evaluate:  MOV  AL , [BX]
                                                        ; is read character number?
       char:  AND  AL , 0F0H
              CMP  AL , 30H
              JNE  not_char
              CALL ins_char
              JMP  next
              
   not_char:  CMP  char_fnd , 0
              JE   peek_op 
              CALL push_var
   
    peek_op:  MOV  BP , bcup_op_t                       ; peek from temporary operand stack to AX
              MOV  AX , [BP]
              MOV  AH , AL                              ; AH holds operand at top of temporary operand stack
                                                    
              MOV  AL , [BX]                            ; read character is not number , find operator          
   
       ;-------------------------------------------------check for $
       
       try0:  CMP  AL , '$'
              JNE  try1
              
       nxt0:  CMP  AH , '$'
              JNE  nxt1  
              JMP  next
              
       nxt1:  CMP  AH , '('
              JNE  nxt2
              MOV  AH , 09H
              MOV  DX , offset MESS1
              INT  21H                                  ; report error
              HLT
              
       nxt2:  CALL move_stck                               
              JMP  nxt0                                 ; recursive 
              
       ;-------------------------------------------------check for + and -
              
       try1:  CMP  AL , '+'
              JE   nxt3
              CMP  AL , '-'
              JNE  try2
              
       nxt3:  CMP  AH , '$'
              JNE  nxt4
              CALL push_op_t
              JMP  next
              
       nxt4:  CMP  AH , '('
              JNE  nxt5
              CALL push_op_t
              JMP  next
              
       nxt5:  CALL move_stck
              JMP  nxt3 
               
       ;-------------------------------------------------check for * and - 
             
       try2:  CMP  AL , '*'
              JE   nxt6
              CMP  AL , '/'
              JNE  try3
              
       nxt6:  CMP  AH , '*'
              JNE  nxt7
              CALL move_stck
              JMP  nxt6
              
       nxt7:  CMP  AH , '/'
              JNE  nxt8
              CALL move_stck     
              JMP  nxt6
              
       nxt8:  CALL push_op_t
              JMP  next
 
       ;-------------------------------------------------check for (
              
       try3:  CMP  AL , '('
              JNE  try4
              CALL push_op_t
              JMP  next
       
       ;-------------------------------------------------check for )       
       
       try4:  CMP  AH , '$'
              JNE  nxt9
              
              MOV  DX , offset MESS1
              MOV  AH , 09H
              INT  21H          ; report error
              HLT                  
       
       nxt9:  CMP  AH , '('
              JNE  nxt10
              ADD  bcup_op_t , 02H
              JMP  next      
       
       nxt10: CALL move_stck
              JMP  try4  
                     
       ;-------------------------------------------------
                                              
       next:  INC  BX           ; read next
              LOOP evaluate
              
              CALL GetRes       ; calculate result
              CALL DispRes      ; display result
              
              
              HLT
              
                          
    ;functions************************************************
    
    ins_char  PROC NEAR
              
              PUSH BX
              
              MOV char_fnd , 31H                            ; some random none-zero number : set char_fnd
               
              MOV AL , [BX]
              AND AL , 0FH
              
              SUB BH , BH
              MOV BL , char_coun
              MOV char_buff[BX] , AL
              INC char_coun
              
              POP  BX
              RET
        
    ins_char  ENDP
    
    
    ;********************************************************
    
    ;define   ins_char_hex
    ;         push_var_hex
    ;         DispRes_hex
    
    ;********************************************************
           
    push_var  PROC NEAR
              
              PUSH BX
              PUSH DX                                       ; reset char_fnd
              
              MOV  char_fnd , 0
              
              CMP char_coun , 1
              JNE two_char
              
   one_char:  MOV AL , char_buff[0]
              SUB AH , AH
              MOV char_sum , AX
              
              JMP ENDE 
              ;-----------------------
              
   two_char:  CMP char_coun , 2
              JNE three_char
  
              MOV AL , char_buff[1]
              SUB AH , AH
              MOV char_sum , AX
              
              MOV AL , char_buff[0]
              MOV AH , 10
              MUL AH
              ADD char_sum , AX
              
              JMP ENDE 
              ;----------------------
                       
 three_char:  CMP char_coun , 3
              JNE four_char
             
              MOV AL , char_buff[2]
              SUB AH , AH
              MOV char_sum , AX
              
              MOV AL , char_buff[1]
              MOV AH , 10
              MUL AH
              ADD char_sum , AX
              
              MOV AL , char_buff[0]
              MOV AH , 100
              MUL AH
              ADD char_sum , AX
              
              JMP ENDE 
              ;----------------------
              
  four_char:  CMP char_coun , 4
              JNE five_char
              
              MOV AL , char_buff[3]
              SUB AH , AH
              MOV char_sum , AX
              
              MOV AL , char_buff[2]
              MOV AH , 10
              MUL AH
              ADD char_sum , AX
              
              MOV AL , char_buff[1]
              MOV AH , 100
              MUL AH
              ADD char_sum , AX
              
              MOV AL , char_buff[0]
              SUB AH , AH
              MOV DX , 1000                       ; caution:destroys DX
              MUL DX                              ; multiply AX by DX :first_digit*1000
              ADD char_sum , AX                   ; since result can't exceed 9000 , we don't need high word
              
              JMP ENDE 
              ;-----------------------
              
  five_char:  MOV AL , char_buff[4]
              SUB AH , AH
              MOV char_sum , AX
              
              MOV AL , char_buff[3]
              MOV AH , 10
              MUL AH
              ADD char_sum , AX
              
              MOV AL , char_buff[2]
              MOV AH , 100
              MUL AH
              ADD char_sum , AX
              
              MOV AL , char_buff[1]
              SUB AH , AH
              MOV DX , 1000                       ; caution:destroys DX
              MUL DX                              ; multiply AX by DX :second_digit*1000
              ADD char_sum , AX                   ; since input is assumed to be 16 bit , we don't need high word
              
              MOV AL , char_buff[0]
              SUB AH , AH 
              MOV DX , 10000
              MUL DX                              ; multiply AX by DX :first_digit*10000
              ADD char_sum , AX                   ; since input is assumed to be 16 bit , we don't need high word
              
              ;------------------------------------
              
      ENDE:   MOV  char_coun    , 0
              MOV  char_buff[0] , 0
              MOV  char_buff[1] , 0
              MOV  char_buff[2] , 0
              MOV  char_buff[3] , 0
              MOV  char_buff[4] , 0
                                                                                            
              MOV  AX           , char_sum        ;                                            Byte0 : charsumL
              MOV  BX           , ptr_queue       ;                                            Byte1 : charsumH
              MOV  [BX]         , AX              ; enqueue number to queue                    Byte2 : 00H
              ADD  ptr_queue    , 0004H           ; point ptr_queue to next double word        Byte3 : 00H
               
              POP  DX
              POP  BX           
              
              RET
    push_var  ENDP 
    
      ;**********************************************
    
    push_op_t PROC NEAR              
              
              SUB  bcup_op_t , 02H
              MOV  BP   , bcup_op_t
              
              SUB  AH   , AH                
              MOV  [BP] , AX                      ; push AX to temporary operand stack
              
              RET
    push_op_t ENDP
    
      ;**********************************************
    
    move_stck PROC NEAR                           ; pops temporary operand stack & enqueues result to operand queue
              
              PUSH BX
                                          
              MOV  BP , bcup_op_t                 ; pop operand from temporary operand stack
              MOV  AX , [BP]
              ADD  bcup_op_t   , 02H
              
              ADD  ptr_queue   , 0002H            ; point   ptr_queue to upper   word          Byte0 : 00H
              MOV  BX          , ptr_queue        ;                                            Byte1 : 00H
              MOV  [BX]        , AX               ; enqueue operand   to operand queue         Byte2 : operator (AL)
              ADD  ptr_queue   , 0002H            ;                                            Byte3 : 00H      (AH)
             
              MOV  BP , bcup_op_t                 ; peek operand from temporary operand stack
              MOV  AX , [BP]
              MOV  AH , AL
              
              POP  BX
                            
              RET              
    move_stck ENDP
    
      ;**********************************************
    
      GetRes  PROC NEAR
              
              MOV  BP   , offset sp_oprnd
              
       begin: MOV  AX   , calc_queue
              CMP  AX   ,  ptr_queue
              JNE  calc                           ; calc_queue <= ptr_queue
                           
              RET
              
        calc: ADD  calc_queue , 0002H             ; point calc_queue to upper word
              MOV  BX   , calc_queue
              MOV  CX   , [BX]                    ; load upper word to AX
              CMP  CX   , 0
              JE   num_fnd                        ; numbers are in lower words
              
      op_fnd: CALL GetOp
              ADD  calc_queue , 0002H             ; point calc_queue to next double word
              JMP  begin
              
     num_fnd: SUB  calc_queue , 0002H             ; point calc_queue to lower word
              MOV  BX         , calc_queue
              MOV  AX         , [BX]
              
              SUB  BP         , 0004H             ; decrement stack pointer (BP)
              MOV  [BP+0]     , AX                ; push number to operand stack
              MOV  [BP+2]     , 0000H             ; since inputs are assumed to be 16 bit , upper word is zero
              
              ADD  calc_queue , 0004H             ; point calc_queue to next double word
              JMP  begin
                
      GetRes  ENDP
    
      ;**********************************************
    
      GetOp   PROC NEAR                           ; use BP as operand stack SP
              
              
              MOV AX       , [BP+0]
              MOV operandL , AX                   ; load first  operand to ( operandH operandL ) pair
              MOV AX       , [BP+2]
              MOV operandH , AX
              
              MOV AX       , [BP+4]               ; load second operand to ( DX       AX       ) pair
              MOV DX       , [BP+6] 
              
      ;------------------------------        
              
      tryadd: CMP CL       , '+'
              JNE trysub
              
              ADD AX       , operandL
              ADC DX       , operandH
              JMP push_res
              
      ;------------------------------        
              
      trysub: CMP CL       , '-'
              JNE trymul
              
              SUB AX       , operandL
              SBB DX       , operandH 
              JMP push_res
               
      ;------------------------------ 
               
      trymul: CMP CL     , '*'
              JNE trydiv
              
      ;[(256*DX)+AX]*[(256*High)+Low]= (16^4)*DX*High + (16^2)*[(DX*Low)+(AX*High)] + [AX*Low] =>result is limited to 32 bits so we omit term with 16^4 
                             
               MUL  operandL                       ; form AX*Low
              
               PUSH DX                             ; save    DX (1)
               PUSH AX                             ; save    AX (1)
              
               MOV  AX , [BP+4]                    ; form AX*operandH
               MUL  operandH
                                                   ; save    DX (2)
               PUSH DX                             ; save    AX (2)
               PUSH AX
              
               MOV  AX , [BP+6]
               MUL  operandL                       ; form DX*operandL
                                                   ; restore AX (2)
               POP  BX                             ; restore DX (2)
               POP  CX
              
               ADD  AX , BX
               ADC  DX , CX                        ; form (AX*High)+(DX*Low)
               
               MOV  CX , 8
        mult:  CLC 
               RCL  AX , 1
               RCL  DX , 1 
               LOOP mult                           ; form (16^2)*[(DX*Low) + (AX*High)] by shifting (DX AX) pair 8 times
              
              
               POP  BX                             ; restore AX (1)
               POP  CX                             ; restore DX (1)
              
               ADD  AX , BX
               ADC  DX , CX                        ; form final result             
               JMP  push_res
      
      ;------------------------------
              
      trydiv:  CMP  CL     , '/'
               JNE  tryerr
              
               CMP  operandH , 0000H
               JNE  ex_div
              
       ; (DX AX) / Low 
               MOV  AX , DX                        ; divide high word (DX) first 
               SUB  DX , DX                        ; convert word to double word
               DIV  operandL
               PUSH AX                             ; store   high word of quotient 
               MOV  AX , [BP+4]
               DIV  operandL              
                                                   ; low  word of quotient is in AX 
               POP  DX                             ; restore high word of quotient
               JMP push_res   
              
             
      ; (DX AX) / (High Low) =~ DX / High 
        
       ex_div: MOV DX , AX
               SUB DX , DX
               DIV operandH
               SUB DX , DX                         ; destroy remainder                                                  
               JMP push_res
               
              
      tryerr:  MOV DX , offset MESS1
               MOV AH , 09H
               INT 21H
               HLT         
        
                                            
     push_res: ADD BP     , 0004H                 ; push result back to operands stack
               MOV [BP+0] , AX
               MOV [BP+2] , DX
               
               RET
        
      GetOp    ENDP
      
      ;***********************************
    
      DispRes  PROC NEAR
               
               
               MOV  AX        , [BP+0]
               MOV  ResWord0  , AX
               MOV  AX        , [BP+2]
               MOV  ResWord1  , AX
               
               MOV  CX        , 10
               MOV  BX        , 11
      ;------------------------------
                            
      again:   SUB  DX        , DX
               MOV  AX        , ResWord1
               DIV  Divisor
                                                        
               MOV  ResWord1  , AX                       ; store AX (high word of new dividend)              
               MOV  AX        , ResWord0  
                                                         ; DX already contains correct value                             
               DIV  Divisor                              ; Move High word of new dividend to ResWord1
               MOV  ResWord0  , AX 
               
               OR   DL        , 30H                      ; DX contains decimal number
               MOV  MESS2[BX] , DL
               
               DEC  BX
               LOOP again
               
      ;------------------------------
               
               MOV DX , offset MESS2
               MOV AH , 09H
               INT 21H
               RET
               
      DispRes  ENDP
      
      ;********************************
                
    CODE      ENDS            
              END START
    
    




