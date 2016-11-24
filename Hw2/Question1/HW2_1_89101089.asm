   ;8086 PROGRAM HW2_1_89101089.ASM
   ;ABSTRACT  : This program guesses 8 bit number selected by user 
   ;            by considering user feedback 
   ;REGISTERS : Uses CS , DS , SS , SP , AX , BX , CX , DX   
   ;PORTS     : ---
   ;PROCEDURES: CAL_PRINT
   ;                            
                               
  DATA   SEGMENT
     
     Guess_MIN DB 0
     Guess_MAX DB 255
     Guess_BIN DB 128
     Guess_ASC DB 0DH,0AH,3 DUP(?) , '$'
    
     Input     DB ?
     
     MESS1     DB 0DH,0AH,'Enter Statement: (l:less , e:equal , m:major) $'
     MESS2     DB 0DH,0AH,'Error: Unexpected statement $'
     MESS3     DB 0DH,0AH,'Value Found! $'
         
  DATA   ENDS
  
  
  STACK  SEGMENT STACK
    
               DW 50 DUP(?)
     TOP_STACK Label Word 
     
  STACK  ENDS             
  
  
  CODE   SEGMENT
    
   ASSUME CS:CODE , DS:DATA , SS:STACK
                
  START: MOV AX , DATA
         MOV DS , AX
         MOV AX , STACK
         MOV SS , AX
         MOV SP , offset TOP_STACK
                
 START2: SUB AH , AH
         MOV AL , Guess_MIN
         
         SUB BH , BH
         MOV BL , Guess_MAX
         ADD AX , BX
         
         MOV CL , 02H
         DIV CL
         
         MOV Guess_BIN , AL
  
         CALL CAL_PRINT 
         
         MOV DX , offset MESS1
         MOV AH , 09H
         INT 21H
         
         MOV AH , 01H
         INT 21H
         
         CMP AL , 'e'
         JE  Match
         
   try0: CMP AL , 'l'
         JNE try1
         MOV AL , Guess_BIN
         MOV Guess_MAX , AL
         JMP START2
         
   try1: CMP AL , 'm'
         JNE try2
         MOV AL , Guess_BIN
         MOV Guess_MIN , AL
         JMP START2 
         
   try2: MOV DX , offset MESS2
         MOV AH , 09H
         INT 21H
         HLT
   
  Match: MOV DX , offset MESS3
         MOV AH , 09H
         INT 21H
         HLT      
         
         
          
   CAL_PRINT PROC NEAR 
         
         ; AH=0 AL=213
         
         SUB AH , AH
         MOV AL , Guess_BIN
         MOV BL , 10
         DIV BL                  ; AL contaisn Guess_BIN / 10
         MOV Guess_ASC[4] , AH   ; AH contains Guess_BIN % 10
         
         ; AH=3 AL=21
         
         SUB AH , AH             
         MOV BL , 10
         DIV BL                  ; AL contains ( Guess_BIN/10 ) / 10 
         MOV Guess_ASC[3] , AH   ; AH contains ( Guess_BIN/10 ) % 10
         
         ; AH=1 AL=2
         
         SUB AH , AH             
         MOV BL , 10
         DIV BL                  ; AL contains ( ( Guess_BIN/10 ) / 10 ) / 10
         MOV Guess_ASC[2] , AH   ; AH contains ( ( Guess_BIN/10 ) / 10 ) % 10
         
         ; AH=2 AL=0
         
         OR Guess_ASC[4] , 30H
         OR Guess_ASC[3] , 30H
         OR Guess_ASC[2] , 30H
         
         MOV DX , offset Guess_ASC
         MOV AH , 09H
         INT 21H
         
         RET
    
   CAL_PRINT ENDP
   
   
   
  CODE ENDS
  
       END START