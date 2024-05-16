%define WIDTH 320
%define HEIGHT 240

;=============================================================

    section .text
    global find_markers

find_markers: 
    ; function prolog
    push rbp
    mov rbp, rsp

    ; alocate memory for local variables
    sub rsp, 8                              ; local variable height  of currently check L-shape

    
    ; store saved registers 
    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r13, 0                     ; set  counter of found markers to 0 

processBMP:
    mov r8, HEIGHT         
    sub r8, 1                              ; r8 is iterator over rows ; i

rowLoop: 
    xor rcx, rcx                            ; load 0 to rcx ; iterator over columns ; j
columnLoop:
    ; calculated pointer to this pixel and store in rax
    mov rax, r8                            ; rax == rowIdx
    imul rax, WIDTH                         ; rax == WIDTH*rowIdx
    add rax, rcx                            ; rax == WIDTH*rowIdx + columnIdx
    imul rax, 3
    add rax, rdi                   ; now rax pointer to pixel in image 

    ; store result on stack 
    mov r14, rax                  ; store calculated pointer on stack
    mov r15, rax                  ; store current pointer on stack

checkIfBlack:                               ; check if current pixel is black, if not continue with loops
    cmp BYTE[rax], 0                        ; test [rax], [rax] does not work and might have not been faster
    jne continueLoops
    inc rax
    cmp BYTE[rax], 0
    jne continueLoops
    inc rax
    cmp BYTE[rax], 0
    jne continueLoops
    inc rax

calcLength:                                 ; calculate horizontal black line length
    ; if this point is reached pixel must be black, pointer is already incemenented and counter set to one
    mov r11, 1                              ; set counter of horizontal black line length to 1
    
    mov r9, WIDTH                          ; r9 hold how many iterations left till end of line
    sub r9, rcx                            ; r9 == WIDTH - currentColumn
    sub r9, 1                              ; r9 == WIDTH - currentColumn - 1

calcLengthLoop:
    cmp r9,0
    je exitCalcLengthLoop                   ; quit if is zero 
    
    cmp BYTE[rax], 0                        ; check if pixel is black, if not quit
    jne exitCalcLengthLoop
    inc rax
    cmp BYTE[rax], 0
    jne exitCalcLengthLoop
    inc rax
    cmp BYTE[rax], 0
    jne exitCalcLengthLoop
    inc rax

    inc r11                                 ; increment counter of black pixel
    dec r9                                 ; decrement counter of how many iterations left in this row 

    jmp calcLengthLoop
    
exitCalcLengthLoop:                         ; length of horizontal black line has been calculated
    ; check if end of line has been reached - nie trzeba, wtedy odrazu przeskakjemy do endOfChecking
    
    ; store on stack calculated lengths
    mov r12, r11                   ; store length on stack 
    mov r9, r11  

    ; check if end of line has been reached
    cmp r9,0
    je endOfChecking

    ; check parity
    test r11, 1
    jnz endOfChecking                       ; jump if length of horizontal line is odd - marker is not correct 

    
    mov r10, r11                             
    shr r10, 1                              ; divide length by 2, now r11 has anticipate length fof vertical line
    mov qword[rbp-8], r10                  ; store legnth of vertical line on stack 

    ; check if vertical line will fit (we must have at least r10+1 rows left to bottom) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

checkNonWhiteLOuter:                        ; check if L-shape above marker does not have black pixels 
    ; adjust it, so it point to pixel to the top and left from found black pixel 
    mov rax, r14                  ; load previous pointer from stack to rax 
    sub rax, 3                              ; adjust pointer ; pointer = pointer -3  + 3*WIDHT
    add rax, 3*WIDTH                        ; lea is not right instruction, because we use multiplication of 2 instant arguments
    
    ; load anticipated length of horizontal nonBlack line to register
    ; wanted length is already in r11, just need to add 2 to it
    add r11, 2

checkNonWhiteLOuterHorizontal:               ; checks horizontal line of non black L-shape above marker
    ; check if pixel is not black - at least on color must not be zero
    add rax, 3
    cmp BYTE[rax-1], 0
    jne pixelNonBlack1
    cmp BYTE[rax-2], 0
    jne pixelNonBlack1
    cmp BYTE[rax-3], 0
    jne pixelNonBlack1

    jmp endOfChecking                       ; pixel is black, end checking

pixelNonBlack1:
    dec r11                                 ; decrement how many pixels to check
    test r11, r11
    jnz checkNonWhiteLOuterHorizontal       ; jump there are still pixels left to check

endOfCheckingNonWhiteLOuterHorizontal:      ; horizontal line is non black 
    mov rax, r14                  ; load previous pointer from stack to rax 
    sub rax, 3                              ; adjust pointer ; pointer = pointer -3  + 3*WIDHT
    add rax, 3*WIDTH                        ; lea is not right instruction, because we use multiplication of 2 instant arguments
    
    ; laod anticipated length
    mov r11, qword[rbp-8]
    add r11, 2      

checkNonWhiteLOuterVertical:                ; checks vertical line of non black L-shape above marker
    ; check if pixel is not black - at least on color must not be zero
    cmp BYTE[rax], 0
    jne pixelNonBlack2
    cmp BYTE[rax+1], 0
    jne pixelNonBlack2
    cmp BYTE[rax+2], 0
    jne pixelNonBlack2

    jmp endOfChecking                       ; pixel is black, end checking

pixelNonBlack2:
    sub rax, 3*WIDTH                        ; increment pointer ; pointer -= 3*width
    dec  r11                                ; decrement counter of elements to check 

    test r11, r11
    jnz checkNonWhiteLOuterVertical

endOfCheckingOuterNonBlackL:                ; at this point white, outer L-shape has been found - continue checking

checkBlackLLoop:                            ; at this point white, outer L-shape is correct ; checks if blackL, starting at [rbp-16] is black
    mov r11, r9                  ; load right length to check horizontally
    mov rax, r15                  ; load right pointer

checkBlackLHorizontal:                      ; loop that checks if horizontal line is black 
    cmp BYTE[rax], 0                        ; check if pixel is black
    jne exitBlackLLoop
    inc rax
    cmp BYTE[rax], 0
    jne exitBlackLLoop
    inc rax
    cmp BYTE[rax], 0
    jne exitBlackLLoop
    inc rax

    ; pointer is already adjusted 
    dec r11                                 ; adjust counter
    test r11, r11
    jnz checkBlackLHorizontal               ; jump if still there are pixels to check

checkPixelAtTheEndOfHorizontal:             ; checks if next pixel is not black
    cmp BYTE[rax], 0             
    jne endOfBlackLHorizontalLoop    
    inc rax
    cmp BYTE[rax], 0
    jne endOfBlackLHorizontalLoop    
    inc rax
    cmp BYTE[rax], 0
    jne endOfBlackLHorizontalLoop    

    jmp exitBlackLLoop                      ; jump if pixel at the end of line is black

endOfBlackLHorizontalLoop:                  ; horizontal line in black L-shape is good
    mov r11, qword[rbp-8]                  ; load right length to check vertically
    mov rax, r15                  ; load right pointer

checkBlackLVertical:                        ; loop that checks if vertical line is black
    cmp BYTE[rax], 0                        ; check if pixel is black
    jne exitBlackLLoop
    cmp BYTE[rax+1], 0
    jne exitBlackLLoop
    cmp BYTE[rax+2], 0
    jne exitBlackLLoop

    sub rax, 3*WIDTH                        ; increment pointer ; pointer -=3*WIDTH
    dec r11                                 ; decrement number of elements to check
    test r11, r11 
    jnz checkBlackLVertical                 ; jump if pixels left to check

checkPixelAtTheEndOfVertical:               ; checks if next pixel is not black
    cmp BYTE[rax], 0             
    jne endOfBlackLVerticalLoop    
    cmp BYTE[rax+1], 0
    jne endOfBlackLVerticalLoop    
    cmp BYTE[rax+2], 0
    jne endOfBlackLVerticalLoop    

    jmp exitBlackLLoop                      ; jump if pixel at the end of line is black

endOfBlackLVerticalLoop:                    ; at this point black L has been checked and it was correct

    dec r9                       ; adjust lenght of next L-shape
    dec qword[rbp-8]                       ; adjust height of next L-shpa 
    
    ; adjust pointer
    add r15, 3
    sub r15,3*WIDTH               ; pointer = pointer + 3 - 3*WDITH - now points to pixel to the right and down 

    ; quit chekcing if vertical lenght == 0 <- that's rectangle
    cmp qword[rbp-8], 0 
    je endOfChecking            

    jmp checkBlackLLoop

exitBlackLLoop:
    ; check if at least one black l was found ; if wasn't found [rbp-12] == [rbp-16], because pointer was not incremented
    mov r9, [rbp-16]                       ; r9 is used as temporary register here
    cmp [rbp-12], r9
    je endOfChecking

checkNonBlackInnerL:                        ; check if inner L-shape does not have black pixels
    mov rax, r15                  ; load pointer
    mov r11, r9                  ; load lenght
    add r11, 1                              ; we need to check one more pixel than if it would be black L

checkNonBlackInnerHorizontal:
    ; check if pixel is not black 
    add rax, 3
    cmp BYTE[rax-1], 0
    jne pixelNonBlack3
    cmp BYTE[rax-2], 0
    jne pixelNonBlack3
    cmp BYTE[rax-3], 0
    jne pixelNonBlack3

    jmp endOfChecking                       ; pixel is black, end checking
pixelNonBlack3:
    dec r11                                 ; decrement number of pixels to check
    test r11, r11
    jnz checkNonBlackInnerHorizontal        ; jump if there are pixels left to check

endOfNonBlackInnerHorizontal:               ; at this point horizontal, inner white line is good
    mov rax, r15                  ; load pointer
    mov r11, qword[rbp-8]                  ; load lenght
    add r11, 1                              ; we need to check one more pixel than if it would be black L

checkNonBlackInnerVertical:
    cmp BYTE[rax], 0                        ; check if pixel is not black
    jne pixelNonBlack4
    cmp BYTE[rax+1], 0
    jne pixelNonBlack4
    cmp BYTE[rax+2], 0
    jne pixelNonBlack4

    jmp endOfChecking                       ; pixel is black, end checking

pixelNonBlack4:                             ; at this point pixel is definitelly  not black
    sub rax, 3*WIDTH                        ; increment pointer ; pointer -= 3*width
    dec  r11                                ; decrement counter of elements to check 

    test r11, r11                           ; jump if there are pixels left to check
    jnz checkNonBlackInnerVertical

answerFound:                                    
    ; add column to list
    ; obliczyć przesunięcie w r9, potem dodać je do rbp+12
    mov rax, rsi                  ; load pointer to x positions
    mov r9, r13                   ; count of markers
    mov r10, rcx
    mov DWORD[rax + 4*r9], r10d             ; [baseAddressOfArray + 4*countOfMarkers]

    ; add row to list
    ; r10 - calculate row here 
    mov r10, HEIGHT - 1
    sub r10, r8                            ; row(r10) = HEIGHT - rowIdx - 1
    mov rax, rdx                  ; load pointer to y_positions
    mov DWORD[rax + 4*r9], r10d             ; add to array calualted row ( taking lower half of r10 register)
    
    inc r13                        ; increment counter of markers 

endOfChecking:
    add rcx,r12                    ; adjust column pointer, by adding lenght of found horizontal line
    dec rcx                                 ; -1, because in next step +1 will be added
continueLoops:
    inc rcx

    cmp rcx, WIDTH                          ; check if pointer over column is smaller than width after incrementation
    jl columnLoop                           ; if so, continue iteration over columns

    dec r8
    test r8, r8                           ; test if r8 is zero
    jnz rowLoop

endFunction:

    mov rax, r13                   ; return result to rax

    ; restore saved registers 
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12 

    ; function epilog 
    mov rsp, rbp                            ; delete local variables from stack 
    pop rbp 
    ret