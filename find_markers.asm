%define WIDTH 320
%define HEIGHT 240

;=============================================================

    section .text
    global find_markers

find_markers: 
    ; function prolog
    push ebp
    mov ebp, esp

    ; alocate memory for local variables
    sub esp, 4                  ; local variable at[ebp-4] - stores calculated length of horizontal line
    sub esp, 4                  ; local variable at[ebp-8] - counter of found markers 
    sub esp, 4                  ; local variable at[ebp-12] - stores pointer to pixel of coordinates[i,j], where i is row idx and j is column idx
    sub esp, 4                  ; local variable at[ebp-16] - currentIdx, pointer to top left pixel of currently checked L-shape
    sub esp, 4                  ; local varaible at[ebp-20] - length of currently check L-shape
    sub esp, 4                  ; local varaible at[ebp-24] - height  of currently check L-shape
    
    ; store saved registers 
    push edi 
    push esi 
    push ebx

    mov DWORD[ebp-8], 0              ; set  counter of found markers to 0 

processBMP:
    mov edx, HEIGHT         
    sub edx, 1                  ; edx is iterator over rows ; i

rowLoop: 
    xor ecx, ecx                ; load 0 to ecx ; iterator over columns ; j
columnLoop:
    ; calculated pointer to this pixel and store in EAX
    mov eax, edx                ; eax == rowIdx
    imul eax, WIDTH              ; eax == WIDTH*rowIdx
    add eax, ecx                ; eax == WIDTH*rowIdx + columnIdx
    imul eax, 3
    add eax, DWORD[ebp+8]       ; now eax pointer to pixel in image 

    ; store result on stack 
    mov DWORD[ebp-12], eax      ; store calculated pointer on stack
    mov DWORD[ebp-16], eax      ; store current pointer on stack

checkIfBlack:                   ; check if current pixel is black, if not continue with loops
    cmp BYTE[eax], 0           ; test [eax], [eax] does not work and might have not been faster
    jne continueLoops
    inc eax
    cmp BYTE[eax], 0
    jne continueLoops
    inc eax
    cmp BYTE[eax], 0
    jne continueLoops
    inc eax

calcLength:                     ; calculate horizontal black line length
    ; if this point is reached pixel must be black, pointer is already incemenented and counter set to one
    mov edi, 1               ; set counter of horizontal black line length to 1
    
    mov ebx, WIDTH              ; ebx hold how many iterations left till end of line
    sub ebx, ecx                ; ebx == WIDTH - currentColumn
    sub ebx, 1                  ; ebx == WIDTH - currentColumn - 1

calcLengthLoop:
    cmp ebx,0
    je exitCalcLengthLoop        ; quit if is zero 
    
    cmp BYTE[eax], 0           ; check if pixel is black, if not quit
    jne exitCalcLengthLoop
    inc eax
    cmp BYTE[eax], 0
    jne exitCalcLengthLoop
    inc eax
    cmp BYTE[eax], 0
    jne exitCalcLengthLoop
    inc eax

    inc edi                  ; increment counter of black pixel
    dec ebx                 ; decrement counter of how many iterations left in this row 

    jmp calcLengthLoop
    
exitCalcLengthLoop:             ; length of horizontal black line has been calculated
    ; check if end of line has been reached - nie trzeba, wtedy odrazu przeskakjemy do endOfChecking
    
    ; store on stack calculated lengths
    mov DWORD[ebp-4], edi                    ; store length on stack 
    mov DWORD[ebp-20], edi  

    ; check if end of line has been reached
    cmp ebx,0
    je endOfChecking

    ; check parity
    test edi, 1
    jnz endOfChecking                        ; jump if length of horizontal line is odd - marker is not correct 

    
    mov esi, edi                             
    shr esi, 1                              ; divide length by 2, now edi has anticipate length fof vertical line
    mov DWORD[ebp-24], esi                  ; store legnth of vertical line on stack 

    ; check if vertical line will fit (we must have at least esi+1 rows left to bottom) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

checkNonWhiteLOuter:                        ; check if L-shape above marker does not have black pixels 
    ; adjust it, so it point to pixel to the top and left from found black pixel 
    mov eax, DWORD[ebp-12]                  ; load previous pointer from stack to eax 
    sub eax, 3                              ; adjust pointer ; pointer = pointer -3  + 3*WIDHT
    add eax, 3*WIDTH                        ; lea is not right instruction, because we use multiplication of 2 instant arguments
    
    ; load anticipated length of horizontal nonBlack line to register
    ; wanted length is already in edi, just need to add 2 to it
    add edi, 2

checkNonWhiteLOuterHorizontal:               ; checks horizontal line of non black L-shape above marker
    ; check if pixel is not black - at least on color must not be zero
    add eax, 3
    cmp BYTE[eax-1], 0
    jne pixelNonBlack1
    cmp BYTE[eax-2], 0
    jne pixelNonBlack1
    cmp BYTE[eax-3], 0
    jne pixelNonBlack1

    jmp endOfChecking                         ; pixel is black, end checking

pixelNonBlack1:
    dec edi                                     ; decrement how many pixels to check
    test edi, edi
    jnz checkNonWhiteLOuterHorizontal           ; jump there are still pixels left to check

endOfCheckingNonWhiteLOuterHorizontal:          ; horizontal line is non black 
    mov eax, DWORD[ebp-12]                  ; load previous pointer from stack to eax 
    sub eax, 3                              ; adjust pointer ; pointer = pointer -3  + 3*WIDHT
    add eax, 3*WIDTH                        ; lea is not right instruction, because we use multiplication of 2 instant arguments
    
    ; laod anticipated length
    mov edi, DWORD[ebp-24]
    add edi, 2      

checkNonWhiteLOuterVertical:                ; checks vertical line of non black L-shape above marker
    ; check if pixel is not black - at least on color must not be zero
    cmp BYTE[eax], 0
    jne pixelNonBlack2
    cmp BYTE[eax+1], 0
    jne pixelNonBlack2
    cmp BYTE[eax+2], 0
    jne pixelNonBlack2

    jmp endOfChecking                         ; pixel is black, end checking

pixelNonBlack2:
    sub eax, 3*WIDTH                            ; increment pointer ; pointer -= 3*width
    dec  edi                                    ; decrement counter of elements to check 

    test edi, edi
    jnz checkNonWhiteLOuterVertical

endOfCheckingOuterNonBlackL:                    ; at this point white, outer L-shape has been found - continue checking

checkBlackLLoop:                                ; at this point white, outer L-shape is correct ; checks if blackL, starting at [ebp-16] is black
    mov edi, DWORD[ebp-20]                      ; load right length to check horizontally
    mov eax, DWORD[ebp-16]                      ; load right pointer

checkBlackLHorizontal:                          ; loop that checks if horizontal line is black 
    cmp BYTE[eax], 0           ; check if pixel is black
    jne exitBlackLLoop
    inc eax
    cmp BYTE[eax], 0
    jne exitBlackLLoop
    inc eax
    cmp BYTE[eax], 0
    jne exitBlackLLoop
    inc eax

    ; pointer is already adjusted 
    dec edi                     ; adjust counter
    test edi, edi
    jnz checkBlackLHorizontal    ; jump if still there are pixels to check

checkPixelAtTheEndOfHorizontal:              ; checks if next pixel is not black
    cmp BYTE[eax], 0             
    jne endOfBlackLHorizontalLoop    
    inc eax
    cmp BYTE[eax], 0
    jne endOfBlackLHorizontalLoop    
    inc eax
    cmp BYTE[eax], 0
    jne endOfBlackLHorizontalLoop    

    jmp exitBlackLLoop                          ; jump if pixel at the end of line is black

endOfBlackLHorizontalLoop:                      ; horizontal line in black L-shape is good
    mov edi, DWORD[ebp-24]                      ; load right length to check vertically
    mov eax, DWORD[ebp-16]                      ; load right pointer

checkBlackLVertical:          ; loop that checks if vertical line is black
    cmp BYTE[eax], 0           ; check if pixel is black
    jne exitBlackLLoop
    cmp BYTE[eax+1], 0
    jne exitBlackLLoop
    cmp BYTE[eax+2], 0
    jne exitBlackLLoop

    sub eax, 3*WIDTH               ; increment pointer ; pointer -=3*WIDTH
    dec edi                         ; decrement number of elements to check
    test edi, edi 
    jnz checkBlackLVertical            ; jump if pixels left to check

checkPixelAtTheEndOfVertical:              ; checks if next pixel is not black
    cmp BYTE[eax], 0             
    jne endOfBlackLVerticalLoop    
    cmp BYTE[eax+1], 0
    jne endOfBlackLVerticalLoop    
    cmp BYTE[eax+2], 0
    jne endOfBlackLVerticalLoop    

    jmp exitBlackLLoop                          ; jump if pixel at the end of line is black

endOfBlackLVerticalLoop:                ; at this point black L has been checked and it was correct

    dec DWORD[ebp-20]                   ; adjust lenght of next L-shape
    dec DWORD[ebp-24]                   ; adjust height of next L-shpa 
    
    ; adjust pointer
    add DWORD[ebp-16], 3
    sub DWORD[ebp-16],3*WIDTH           ; pointer = pointer + 3 - 3*WDITH - now points to pixel to the right and down 

    ; quit chekcing if vertical lenght == 0 <- that's rectangle
    cmp DWORD[ebp-24], 0 
    je endOfChecking            

    jmp checkBlackLLoop

exitBlackLLoop:
    ; check if at least one black l was found ; if wasn't found [ebp-12] == [ebp-16], because pointer was not incremented
    mov ebx, [ebp-16]              ; ebx is used as temporary register here
    cmp [ebp-12], ebx
    je endOfChecking

checkNonBlackInnerL:                    ; check if inner L-shape does not have black pixels
    mov eax, DWORD[ebp-16]              ; load pointer
    mov edi, DWORD[ebp-20]              ; load lenght
    add edi, 1                          ; we need to check one more pixel than if it would be black L

checkNonBlackInnerHorizontal:
    ; check if pixel is not black 
    add eax, 3
    cmp BYTE[eax-1], 0
    jne pixelNonBlack3
    cmp BYTE[eax-2], 0
    jne pixelNonBlack3
    cmp BYTE[eax-3], 0
    jne pixelNonBlack3

    jmp endOfChecking                         ; pixel is black, end checking
pixelNonBlack3:
    dec edi                                     ; decrement number of pixels to check
    test edi, edi
    jnz checkNonBlackInnerHorizontal            ; jump if there are pixels left to check

endOfNonBlackInnerHorizontal:                   ; at this point horizontal, inner white line is good
    mov eax, DWORD[ebp-16]              ; load pointer
    mov edi, DWORD[ebp-24]              ; load lenght
    add edi, 1                          ; we need to check one more pixel than if it would be black L

checkNonBlackInnerVertical:
    cmp BYTE[eax], 0                         ; check if pixel is not black
    jne pixelNonBlack4
    cmp BYTE[eax+1], 0
    jne pixelNonBlack4
    cmp BYTE[eax+2], 0
    jne pixelNonBlack4

    jmp endOfChecking                         ; pixel is black, end checking

pixelNonBlack4:                                 ; at this point pixel is definitelly  not black
    sub eax, 3*WIDTH                            ; increment pointer ; pointer -= 3*width
    dec  edi                                    ; decrement counter of elements to check 

    test edi, edi                               ; jump if there are pixels left to check
    jnz checkNonBlackInnerVertical

answerFound:                                    
    ; add column to list
    ; obliczyć przesunięcie w ebx, potem dodać je do ebp+12
    mov eax, DWORD[ebp+12]                           ; load pointer to x positions
    mov ebx, DWORD[ebp-8]                            ; count of markers
    mov DWORD[eax + 4*ebx], ecx                          ; [baseAddressOfArray + 4*countOfMarkers]

    ; add row to list
    ; esi - calculate row here 
    mov esi, HEIGHT - 1
    sub esi, edx                                    ; row(esi) = HEIGHT - rowIdx - 1
    mov eax, DWORD[ebp+16]                          ; load pointer to y_positions
    mov DWORD[eax + 4*ebx], esi                     ; add to array calualted row
    
    inc DWORD[ebp-8]                            ; increment counter of markers 

endOfChecking:
    add ecx,DWORD[ebp-4]                                    ; adjust column pointer, by adding lenght of found horizontal line
    dec ecx                                        ; -1, because in next step +1 will be added
continueLoops:
    inc ecx

    cmp ecx, WIDTH                                      ; check if pointer over column is smaller than width after incrementation
    jl columnLoop                                       ; if so, continue iteration over columns

    dec edx
    test edx, edx                                       ; test if edx is zero
    jnz rowLoop

endFunction:

    mov eax, DWORD[ebp-8]                  ; return result to eax

    ; restore saved registers 
    pop ebx
    pop esi
    pop edi

    ; function epilog 
    mov esp, ebp                ; delete local variables from stack 
    pop ebp 
    ret