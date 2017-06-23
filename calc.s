%define newline 10
%define BufferSize 80
stackSize  equ 5

%macro jmp_if_in_between 4
	cmp %1, %2
	jl %%no_match
	cmp %1, %3
	jle %4
	%%no_match:
%endmacro


%macro debug_op 1
    ;sneek and print
    cmp byte[size],0
    je .noNumbers
    mov byte [firstZero],0 ;clear
    mov %1,[edi-4] ; get the top of the stack- address of the head
    
    push string_format00
    call printf
    add esp,4
    
    push %1
    call printTopWithoutPop
    add esp,4 ; for the function
    ;dont overwrite!
    
    mov byte[firstZero],0 ;back to old state
 %endmacro   


section	.rodata

section .bss
    buffer:   resb    BufferSize
    stack:    resb    stackSize*4 
    LC1:      resb    1
    retval:   resb    4

section .data
    opNum: dd 0 
    pairVar: db -1
    size :dd 0
    odd: db 0
    firstZero: dd 0 ;for printing the first number without leading zeroes
    mallocret: DD 0
    sizefirst: DD 1
    sizesecond: DD 1
    stackpointer: DD 0
    LC2: DD 0
    numOfShiftL: DW 0
    numShifted: DW 0
    sumShift:   DW 0
    newCarry: DW 0
    align 16
    oldCarry: DW 0 
    add_five: DW 0
    align 16
    del_flag: DD 0
    align 16
    counter: DD 0 
    dflag: DD 0
    align 16
    d:  DD  "-d", 0
    align 16
    debug_counter: DD 0 
    align 16
    carry: DW 0
    align 16
    lastCarry: DW 0

    
ERROR_format1:
	db ">>Error: Operand Stack Overflow",0
ERROR_format2:
	db ">>Error: Insufficient Number of Arguments on Stack", 0
ERROR_format3:
	db ">>Error: Illegal Input",0
ERROR_format4:
	db ">>Error: exponent too large",0
string_format0:
	db ">>calc: ",0	
string_format00:
	db ">>",0	
string_format:
	DB   "%s", newline, 0	; Format string
string_format1:
	DB   "%x", newline, 0	; Format string
string_format2:
	DB   "%d", newline, 0	; Format string
string_format_for_pop:
    DB   "%x", "",0 ; Format string


section .text
    align 16
    global main
    global my_calc
	
	extern putchar
    extern printf
    extern fprintf
    extern malloc
    extern free
    extern fgets
    extern stderr
    extern stdin
    extern stdout 
    extern exit
         
main:

    push ebp
    mov ebp, esp
    cmp dword [ebp+8], 1
    JE .aftherdebug          ;no arguments
    mov eax, dword[ebp+12]  ;**argv to eax
    mov ebx, dword[eax+4]   ;argv[1] to ebx
    mov al, byte[ebx]       ;argv[1][0] to eax
    cmp al, byte[d]
    JNE .aftherdebug         ;there is no '-'
    mov al, byte[ebx+1]     ; argv[1][0] to eax
    cmp al, byte[d+1]
    JNE .aftherdebug         ;there is no 'd'
    mov byte[dflag], 1      ;argv[1]=="-d"

.aftherdebug:
    pushad
    call my_calc
    mov ecx ,[opNum]
    
    push ecx ; printing number of OP
    push dword string_format2
    call printf   
    add esp,8

    popad
    push 0
    call exit
    add esp,4


my_calc:
	push	ebp
	mov	ebp, esp	; Entry code - set up ebp and esp
	pushad	 ; Save registers
	mov edi,stack ; permanent register that will be the stackPointer
.loop:
        
        
        push string_format0
        call printf
        add esp,4
        
        push dword [stdin] ; argunments for fgets
        push dword BufferSize
        push dword buffer
        call fgets
        add esp,12

        cmp eax,0; eax now contain pointer to buffer
        je .IllegalInput
        
       
        
        call checkInput ; after that line if (eax=0)-> legal else->illegal
        cmp eax,1 ;
        je .IllegalInput
        ;the input is Legal
        mov ebx,0
        mov ebx,buffer
        
        jmp_if_in_between byte[ebx],'0','9',.IgotNumber
        jmp .IgotOp

.IgotNumber:
        sub ebx,1 ; for next loop
.zeroes:
    inc ebx
    cmp byte [ebx] ,'0' 
    je .zeroes
    cmp byte [ebx] ,newline
    je .ifZero
.continueForZero:    
    
    call checkPairity ; after that line al if(even)->al=0 else -> al=1
    mov [pairVar],al 
    cmp byte [size],stackSize          ;check exception
    je .not_enough_place
    mov edx,0               ; the next item on list
    push ebx
    call Build_List ; the head now is in eax
    add esp,4
    
    mov [edi], eax ;moving to the top of stack

	add edi,4 ; inc the stackPosition by 4
	mov ecx,0; clear register
	
	inc dword [size] ; 
    mov byte [pairVar], -1
	jmp .loop ;returning to get new commands 

.ifZero:
    dec ebx
    jmp .continueForZero
    
 
  
.IgotOp:  
        cmp byte [ebx],'q'
    je .end
        cmp byte [ebx] ,'p'
    je .popPrint
	cmp byte [ebx] ,'d'
    je .dup
    	cmp byte [ebx] ,'+'
    je .add
        cmp byte [ebx] ,'l'
    je .shiftLeft
        cmp byte [ebx] ,'r'
    je .shiftRight

.IllegalInput:	
    push ERROR_format3
    push string_format
    push dword [stdout]
    call fprintf
    add esp,12
    jmp .loop

.not_enough_place:
    push ERROR_format1
    push string_format
    push dword [stdout]
    call fprintf   
    add esp,12
    jmp .loop

.noNumbers:
    push ERROR_format2
    push string_format
    push dword [stdout]
    call fprintf   
    add esp,12
    jmp .loop
.exponent:
    push ERROR_format4
    push string_format
    push dword [stdout]
    call fprintf   
    add esp,12
    jmp .loop
    
.popPrint:
    cmp byte[size],0
    je .noNumbers
    mov byte [firstZero],0 ;clear
    mov esi,[edi-4] ; get the top of the stack- address of the head
    
    push string_format00
    call printf
    add esp,4
    
    push esi
    call printTop
    add esp,4 ; for the function
    sub edi,4   ; to overweite 
    mov byte[firstZero],0 ;back to old state
    inc dword [opNum] ;update opNum
    
    cmp dword [dflag],1
    jne .no_debug_p
    
    ;there is a debug_op

    cmp byte [size],0          ;check exception
    je .noNumbers
    cmp byte [size],stackSize          ;check exception
    je .not_enough_place
    push dword [edi-4] ;pushing the last element on stack
    call duplicate
    add esp,4
    mov [edi],eax; moving the copy
    add edi,4
    inc dword [size] 

    
	cmp byte[size],0
    je .noNumbers
    mov byte [firstZero],0 ;clear
    mov esi,[edi-4] ; get the top of the stack- address of the head
    
    push string_format00
    call printf
    add esp,4
    
    push esi
    call printTop
    add esp,4 ; for the function
    sub edi,4   ; to overweite 
    mov byte[firstZero],0 ;back to old state

    .no_debug_p:
    jmp .loop   
 
.dup:
    cmp byte [size],0          ;check exception
    je .noNumbers
    cmp byte [size],stackSize          ;check exception
    je .not_enough_place
    push dword [edi-4] ;pushing the last element on stack
    call duplicate
    add esp,4
    mov [edi],eax; moving the copy
    add edi,4
    inc dword [size] 
    inc dword [opNum] ;update opNum

    cmp dword [dflag],1
    jne .no_debug_d
    mov dword esi, 0
    debug_op esi

    .no_debug_d:
    jmp .loop   
    
    
.add:
     mov byte [sizefirst], 1
     mov byte [sizesecond], 1
     mov dword [lastCarry],  0
     mov dword [carry], 0
     cmp byte [size], 2
     jl .noNumbers		; prints error arguments if there are less than 2 arguments.
     push dword [edi-8]        ;pushing the last element on stack
     push dword [edi-4]        ;pushing the before last element on stack
     call plus
     add esp,8
     sub edi,4
     mov eax,[edi]
     mov dword [eax],0
     dec dword [size] 
     inc dword [opNum] ;update opNum

     cmp dword [dflag],1
     jne .no_debug_plus
     mov dword esi, 0
     debug_op esi

     .no_debug_plus:
     jmp .loop   
     
     
.shiftLeft:
     cmp byte [size], 2
     jl .noNumbers		; prints error arguments if there are less than 2 arguments.
     mov dword [numOfShiftL],  0

     ;update sumShift with muscing
     mov dword eax, 0
     mov dword edx, 0
     mov dword ebx, 0
     
     mov esi,[edi-4]
     cmp byte [esi +4],0
     jne .exponent
     mov dl,[esi]       ; this is for the LSB
     mov al, [esi]      ; for the MSB
     shl dl, 4          ; from xxxxxxxx get xxxx0000
     shr dl, 4          ; from xxxx0000 get 0000xxxx and it will be the LSB 
     mov bl, 10         ; initialize multiplication
     shr al, 4          ; from xxxxxxxx get 0000xxxx and it will be the MSB
     mul bl             ; to get the *10 number
     add al, dl 
     
     
     mov dl, al
     sub edi,4; pop the numOfShiftL argument 
     
.loopShifts:
        cmp dl, 0
        jle .finishLoopShifts
        
        ;duplicate
        push edx 
        push edi
        push dword [edi-4] ;pushing the last element on stack
 	call duplicate
 	add esp,4
 	pop edi 
 	pop edx

 	mov [edi],eax; moving the copy
 	add edi,4
 	inc dword [size] 
        
        ;plus
        mov byte [oldCarry],  0
        push dword [edi-8]        ;pushing the last element on stack
        push dword [edi-4]        ;pushing the before last element on stack
        call plus
        add esp,8
        sub edi,4
        mov eax,[edi]
        mov dword [eax],0
        dec dword [size] 
        
        sub dl,1
        jmp .loopShifts
        
.finishLoopShifts:   
     dec dword [size] 
     inc dword [opNum] ;update opNum
     
     cmp dword [dflag],1
     jne .no_debug_l
     mov dword esi, 0
     debug_op esi

     .no_debug_l:
     jmp .loop   

.shiftRight:
    cmp byte [size], 2
    jl .noNumbers
    mov esi,[edi-4]
    cmp byte [esi +4],0
    jne .exponent
    
    mov byte [del_flag], 0
    mov dword [oldCarry], 0
    mov dword [add_five], 0
    mov dword [counter], 0
    mov dword [newCarry], 0
    mov byte [sizefirst], 0
     ;update sumShift with muscing
     mov dword eax, 0
     mov dword edx, 0
     mov dword ebx, 0
     mov dword esi, 0
     
     mov esi,[edi-4]
     cmp byte [esi +4],0
     jne .exponent
     mov dl,[esi]       ; this is for the LSB
     mov al, [esi]      ; for the MSB
     shl dl, 4          ; from xxxxxxxx get xxxx0000
     shr dl, 4          ; from xxxx0000 get 0000xxxx and it will be the LSB 
     mov bl, 10         ; initialize multiplication
     shr al, 4          ; from xxxxxxxx get 0000xxxx and it will be the MSB
     mul bl             ; to get the *10 number
     add al, dl 
     
     mov [counter], al 
     sub edi, 8
     mov esi ,[edi]
     add edi, 4

     ;insertion to assembly stack
     .loop_insert:
	cmp dword [counter], 0
        jle .finishLoopShiftRight
        cmp dword esi,0
        je .loop_shift_right
        push esi
        inc byte [sizefirst]
        mov esi, [esi+4]
        jmp .loop_insert

.loop_shift_right:
	
		dec byte [counter]
        mov byte [del_flag], 0
        mov dword [oldCarry], 0
        mov dword [add_five], 0
        mov dword [newCarry], 0
	     ; /2 operation
.loop_shift_r:
		cmp [sizefirst],byte 0
		je .loop_insert
		pop esi ; to get the MSB each time
		
		cmp [esi+4],dword 0
		je .isMSB
		
		cmp byte [del_flag],1
		je .del_MSB
		
		.continue1:
		mov bl, byte [esi]
		AND bl , 16 ; 00010000 get the 5th bit
		JNZ .add_five
		
		.continue2:
		mov bl, byte [esi]
		AND bl , 1 ; 00000001
		JNZ .update_carry
		
		.continue3:
		mov ecx, dword 0
		mov eax, dword 0
		
		;dev 2 BCDs
		mov cl,[esi]  ; this is for the LSB
		mov al, [esi] ; for the MSB
		shl cl, 4          ; from xxxxxxxx get xxxx0000
		shr cl, 5          ; from xxxx0000 get 00000xxx and it will be the LSB/2  
		shr al, 5          ; from xxxxxxxx get 00000xxx and it will be the MSB/2
		shl al, 4          ; 00000xxx to 0xxx0000
		add al, cl 
		
		add al, [add_five]
		add al,[oldCarry]
		
		mov byte [esi], al
		
		mov dword [add_five], 0
		mov ecx, dword 0
		mov ecx, [newCarry]  
		mov [oldCarry], ecx
		mov [newCarry], byte 0
		dec byte [sizefirst]
		jmp .loop_shift_r
     
    
.isMSB:
     cmp byte [esi], 1
     jne .continue1
     mov byte [del_flag], 1
     jmp .continue1
     
.del_MSB:
     mov dword [esi+4],0
     mov byte [del_flag], 0
     jmp .continue1
     
.add_five:
     mov dword [add_five], 5
     jmp .continue2
     
.update_carry:
     mov [newCarry], byte 80 ; this is 50 in BCD (0101 0000) 
     jmp .continue3
    
.finishLoopShiftRight:
     dec dword [size] 
     inc dword [opNum] ;update opNum

     cmp dword [dflag],1
     jne .no_debug_r
     mov dword esi, 0
     debug_op esi

.no_debug_r:
     jmp .loop  
   	
     
.end:
    popad          ; Restore registers
    mov esp, ebp    ; Function exit code
    pop ebp
    ret 

    
    
    
    
    
    
    
checkPairity:
    push	ebp
	mov	ebp, esp	; Entry code - set up ebp and esp
	push ebx
    push ecx   
    sub ebx,1  ; for parity loop
    mov ecx,-1  ;clear register -counter
    .loop1:      
        inc byte [pairVar]
        inc ebx
        cmp byte [ebx],newline
        jne .loop1
     mov eax,[pairVar]; moving to perform the and operation
     and eax,1

.end:
    pop ecx
    pop ebx			; Restore registers
    mov	esp, ebp	; Function exit code
    pop	ebp
    ret 
    
    
    
    
    
    
checkInput:
    push    ebp
    mov	ebp, esp	; Entry code - set up ebp and esp
    pushad	 ; Save registers
    mov ebx,buffer
    
    
    cmp byte [ebx],'+'
    je .checkOp
    cmp byte [ebx],'p'
    je .checkOp
    cmp byte [ebx],'r'
    je .checkOp
    cmp byte [ebx],'q'
    je .checkOp
    cmp byte [ebx],'d'
    je .checkOp
    cmp byte [ebx],'l'
    je .checkOp
    sub ebx,1
    jmp .checkNumber
    
.checkOp:
    cmp byte [ebx+1],newline
    jne .end2
    jmp .end1

.checkNumber:
        inc ebx
        jmp_if_in_between byte [ebx], '0', '9', .checkNumber
        sub ebx,1
        jmp .checkOp; just to check if the next char is newline(illegal) or not (illegal)
        
.end1: ;end with succes
    popad			; Restore registers
    mov	esp, ebp	; Function exit code
    pop	ebp
    mov eax ,0
    ret  
.end2: ;end with failure
    popad			; Restore registers
    mov	esp, ebp	; Function exit code
    pop	ebp
    mov eax,1
    ret  

    
    
    
    
    
my_func:
	push	ebp
	mov	ebp, esp	; Entry code - set up ebp and esp
	
	mov ecx, dword [ebp+8]	; Get argument (pointer to string)	
	push ecx			; Save registers
	push esi
	push ebx
	push edx
	push esi
	push edi

	mov esi,0
	mov ebx,0
	mov eax,0
	mov edx,0
	mov esi,LC1
	mov edi,3
.loop:
                sub edi,1
		cmp edi,0
		jz .continue
		mov bl,[ecx]
		sub bl, 48
		mov al,16
		mul bl
		inc ecx
		mov dl,[ecx]
		cmp dl,'9'
		jle  .SecNum
		cmp dl,'Z'
		jle .UpperCase
		jmp .LowerCase
		
.SecNum:
		sub dl,48
		add al,dl
		mov [esi],al
		inc ecx
		inc esi
		jmp .continue
.UpperCase:
		sub dl,55
		add al,dl
		mov [esi],al
		inc ecx
		inc esi
		jmp .continue
.LowerCase:
		sub dl,87
		add al,dl
		mov [esi],al
		inc ecx
		inc esi
		jmp .continue


.continue:
	mov bl,0
	mov ax,0	
            
	mov eax,LC1
	
	pop edi
	pop esi
	pop edx
	pop ebx
	pop esi
	pop ecx			; Restore registers
	mov	esp, ebp	; Function exit code
	pop	ebp
	ret

	
	
	
	
	
	
	
	
Build_List:
	push	ebp
	mov	ebp, esp	; Entry code - set up ebp and esp
	
	mov ebx,dword [ebp+8]	; Get argument (pointer to head of number)

	push ecx
	push edi
	push esi
	push edx
	mov edx,0; this is the next element initilized to NULL

	cmp byte [pairVar],0
    je .loop
    jmp .loop1

.loop:	
    cmp byte [ebx], newline         ; the end of input
    je .getTheHead          ; get it into stack  
    push ebx                  ; push buffer
    call my_func           ; after this line : eax-> two first digits on decimal
    add esp,4
    mov ecx,eax           ;save the number before malloc
   
    cmp byte [dflag], 1
    jne .dont_debug_num

    ;print trial
    push ecx ;printf dirts
    push edx
    mov eax,[eax]; get the number and not the address
    push eax
    push string_format1
    push dword [stdout]
    call fprintf
    add esp, 12
    pop edx
    pop ecx

    .dont_debug_num:
	push ecx ; before malloc
	push edi
	push esi
	push edx
	push ebx
    
    push dword 5 
    call malloc            ; now eax contain the address for the specified memory
    add esp,4
    
    pop ebx ; after malloc
    pop edx
    pop esi
    pop edi
    pop ecx

    mov ecx,[ecx] ; getting the number instead of the address
   	mov dword [eax] ,ecx; moving the  number inside the malloc address

    mov [eax+4],edx          ;get the next element
              
    mov edx,eax              ; now eax (the cuurrent node) considered as next item
    add ebx,2              ; next two letters in buffer
    jmp .loop

 .loop1:
 		mov byte[odd],'0'
 		mov ecx ,[ebx]
 		mov byte[odd+1], cl

 		mov ecx,0

 		push odd                  ; push buffer
    call my_func           ; after this line : eax-> two first digits on decimal
    add esp,4
    mov ecx,eax           ;save the number before malloc
    ;print trial
	
    cmp byte [dflag], 1
    jne .dont_debug_num1

    push ecx ;printf dirts
    push edx
    mov eax,[eax]; get the number and not the address
    push eax
    push string_format1
    push dword [stdout]
    call fprintf
    add esp, 12
    pop edx
    pop ecx

 .dont_debug_num1:
	push ecx ; before malloc
	push edi
	push esi
	push edx
	push ebx
    
    push dword 5 
    call malloc            ; now eax contain the address for the specified memory
    add esp,4
    
    pop ebx ; after malloc
    pop edx
    pop esi
    pop edi
    pop ecx

    mov ecx,[ecx] ; getting the number instead of the
    mov dword [eax] ,ecx; moving the  number inside the malloc address

    mov [eax+4],edx          ;get the next element
              
    mov edx,eax              ; now eax (the cuurrent node) considered as next item
    inc  ebx           ; next two letters in buffer
    jmp .loop

.getTheHead:
	mov eax,edx ; head is in return value- the last link

.end:
	pop edx
	pop esi
	pop edi
	pop ecx         ; Restore registers
    mov esp, ebp    ; Function exit code
    pop ebp
    ret 

    
    

    
    
printTop:
    push  ebp
    mov ebp, esp    ; Entry code - set up ebp and esp
    pushad
    mov ecx, dword [ebp+8] ;the head
    mov ebx ,ecx ; moving pointer
 
.loop:
    cmp ebx,0 ;stop condition
    je .end
    cmp dword [ebx+4] ,0 ; im the last
    je .printMe
    mov edi,ebx; the element who pointed me -save the previous element
    mov ebx,[ebx+4]
    jmp .loop
 
.printMe:
    push ebx
    push ecx
    mov edx,ebx ; for free purposes
    mov ebx,[ebx]; print the number
    push edx

 .printNow:

 	jmp_if_in_between ebx,0x0,0x9,.printZero ;check it sole letter
   	
   	jmp .printActualNumber 
 
.afterPrinting:
    mov byte[firstZero],1 ; first number didnt get zero
    mov dword[edi+4],0; also the addres is 0 for cmp purposes
 	cmp ebx,ecx ; we are at the last item
 	je 	.repair
.getBack:
 	mov ebx,ecx
    jmp .loop
.printZero:
    cmp	byte[firstZero],0 ; if it does its the first letter=> dont need adding zero
    je .printActualNumber
	pushad ; print zero befor sole letter
	push 48
    call putchar
   	add esp,4
    popad

.printActualNumber:  
    push ebx
    push string_format_for_pop
    push dword [stdout]
    call fprintf
    add esp,12
    pop edx
    pop ecx
    pop ebx
    jmp .afterPrinting

.repair:
	mov dword [ecx],0 ; make adjusments
	mov ecx,0
	jmp .getBack
	


.end:   
    push ebx
    push ecx
    
    push 10 ; printing the new line
    call putchar
    add esp,4
    pop ecx
    pop ebx
 
    mov esi,[size] ; inc size of stack
    sub esi,1
    mov [size], esi
 
    popad
    mov esp, ebp    ; Function exit code
    pop ebp
    ret

    
 printTopWithoutPop:
    push  ebp
    mov ebp, esp    ; Entry code - set up ebp and esp
    pushad
    mov ecx, dword [ebp+8] ;the head
    mov ebx ,ecx ; moving pointer
 
.loop:
    cmp ebx,0 ;stop condition
    je .end
    cmp dword [ebx+4] ,0 ; im the last
    je .printMe

    
    mov edi,ebx; the element who pointed me -save the previous element
    mov ebx,[ebx+4]
    jmp .loop
 
.printMe:
    push ebx
    push ecx
    mov edx,ebx ; for free purposes
    mov ebx,[ebx]; print the number
    push edx

 .printNow:

 	jmp_if_in_between ebx,0x0,0x9,.printZero ;check it sole letter
   	
   	jmp .printActualNumber 
 
.afterPrinting:
    mov byte[firstZero],1 ; first number didnt get zero
    mov dword[edi+4],0; also the address is 0 for cmp purposes
 	cmp ebx,ecx ; we are at the last item
 	je 	.repair
.getBack:
 	mov ebx,ecx
    jmp .loop
.printZero:
    cmp	byte[firstZero],0 ; if it does its the first letter=> dont need adding zero
    je .printActualNumber
	pushad ; print zero befor sole letter
	push 48
    call putchar
   	add esp,4
    popad

.printActualNumber:  
    push ebx
    push string_format_for_pop
    push dword [stdout]
    call fprintf
    add esp,12
    pop edx
    pop ecx
    pop ebx
    jmp .afterPrinting

.repair:

	jmp .end
	


.end:   
    push ebx
    push ecx
    
    push 10 ; printing the new line
    call putchar
    add esp,4
    pop ecx
    pop ebx
 
 
    popad
    mov esp, ebp    ; Function exit code
    pop ebp
    ret


    
duplicate:
	push	ebp
	mov	ebp, esp	; Entry code - set up ebp and esp
	push ecx
	push edi
	push ebx	 ; Save registers    
 	push esi 

 	mov ebx, dword [ebp+8] ; my duplication
.first_link:
	
	push esi
	push ecx
	push edi
	push ebx
	push dword 5 
    call malloc ;  eax=> address for first link
    add esp,4
    pop ebx
    pop edi
    pop ecx
    pop esi

    mov edi,eax ; the address of first node of copied list
    mov ecx,eax ; pointer for new list

    mov esi, ebx ; =>mov [ecx],[ebx]
    mov ebx ,[ebx]
    mov dword [ecx] ,ebx
    mov ebx ,esi 
    
    add ebx,4
    mov ebx ,[ebx]
    

.loop:
	cmp ebx ,0
	je .end

	push esi
	push ecx
	push edi
	push ebx
	push dword 5 
    call malloc            ; malloc for next
    add esp,4
    pop ebx
    pop edi
    pop ecx
 	pop esi

 	add ecx,4 ; here i put the new address
 	mov dword[ecx], eax ; the address from malloc
 	mov ecx,[ecx]; the new link
    
    mov esi, ebx ; =>mov [ecx],[ebx]
    mov ebx ,[ebx]
 
    mov dword [ecx] ,ebx
    mov ebx ,esi 

    
    add ebx,4
    mov ebx ,[ebx]

    mov eax,0
    jmp .loop
.end:
	add ecx ,4
	mov dword[ecx],0

	mov eax, edi

	pop esi
	pop ebx
        pop edi
        pop ecx          ; Restore registers
        mov esp, ebp    ; Function exit code
        pop ebp
        ret 
    


plus:
    clc ; zeros the carry flag
    push	ebp
    mov	ebp, esp	; Entry code - set up ebp and esp
    pushad

    mov ecx, dword [ebp+8] ; first number
    mov ebx, dword [ebp+12] ; second number
    mov dword [retval], ebx ; for return matters
    mov byte [lastCarry],0

.checkSizeFirst:
        mov esi, [ecx+4]
        cmp  esi, 0 
        je .checkSizeSecond
         
        mov ecx, [ecx+4]
        inc byte [sizefirst]
        jmp .checkSizeFirst

.checkSizeSecond:
        mov esi, [ebx+4]
        cmp  esi, 0 
        je .fixsize

        mov ebx, [ebx+4]
        inc byte [sizesecond]
        jmp .checkSizeSecond  

.fixsize:
        
        mov eax, [sizefirst]
        mov edx, [sizesecond]
        ;print1 ERROR_format1, string_format
        ;mov eax, 234
        ;print2 eax
        ;print2 edx
        cmp eax, edx ; first is bigger
        je .equal
        JG .fixsecond


.fixfirst:
        
        mov esi, [sizefirst];change
        mov edx, [sizesecond]
        cmp esi,edx;change
        je .equal

        pushad
        mov eax, 5
        push eax
        call malloc
        add     esp, 4                         ; Clean up stack after call
        mov [mallocret], eax
        popad

        mov eax, [mallocret] 
        mov byte [eax], 0   ; the first byte will be 0
        add ecx,4             ;mov ecx+4, eax		
        mov [ecx], eax        ;put the allocation (4 bytes)
        mov ecx,[ecx]         ; go to next location (eax new location)
        ;add ecx,4             
        ;mov dword[ecx],0
        inc byte [sizefirst]
        jmp .fixfirst


.fixsecond:
        mov esi, [sizefirst];change
        mov edx, [sizesecond]
        cmp esi,edx;change
        je .equal

        pushad
        mov eax, 5
        push eax
        call malloc
        add     esp, 4                       ; Clean up stack after call
        mov [mallocret], eax
        popad
        
        ;change
        mov eax, [mallocret] 
        mov byte [eax], 0   ; the first byte will be 0
        add ebx,4             ;mov ebx+4, eax		
        mov [ebx], eax        ;put the allocation (4 bytes)
        mov ebx,[ebx]         ; go to next location (eax new location)
        ;add ebx,4             
        inc byte [sizesecond]
        jmp .fixsecond


.equal:        
        mov ecx, dword [ebp+8] 
        mov ebx, dword [ebp+12] 
        pushfd

    .plusloop:
	    
            cmp  ecx, 0 
            je .endPlusLoop

            cmp  ebx, 0 
            je .endPlusLoop

            mov al, [ecx]
            mov ah, [ebx] 
            
	    popfd
            adc al, ah
            daa
	    pushfd
            mov byte [ebx], al		 ; use the nodes of the first argument for the solution number 
            mov ecx, [ecx+4]
            mov edx,ebx         ;for the new node of carry if we will need
            mov ebx, [ebx+4]
            
            jmp .plusloop


.endPlusLoop:
	popfd
	adc [lastCarry], dword 0
        cmp byte [lastCarry], 0			; if the addition caused carry
        je .endPlusAfTherCarry
            
        mov ebx,edx ; get the last link
        pushad
        push dword 5
        call malloc
        add  esp, 4                       ; Clean up stack after call
        mov [mallocret], eax
        popad   

        mov eax, [mallocret]
        mov byte [eax], 1
        add ebx,4             ;mov ebx+4, eax		
        mov [ebx], eax
        mov ebx,[ebx]
        add ebx,4
        mov dword[ebx],0
        
.endPlusAfTherCarry:
        mov byte [lastCarry],0
        
        popad          ; Restore registers
        mov eax, [retval]
        mov dword[retval],0
        mov esp, ebp    ; Function exit code
        pop ebp
        ret 

        
          
 	
