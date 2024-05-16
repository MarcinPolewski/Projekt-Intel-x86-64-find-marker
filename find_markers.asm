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
    sub rsp, 4                              ; local variable at[rbp-4] - stores calculated length of horizontal line
    sub rsp, 4                              ; local variable at[rbp-8] - counter of found markers 
    sub rsp, 4                              ; local variable at[rbp-12] - stores pointer to pixel of coordinates[i,j], where i is row idx and j is column idx
    sub rsp, 4                              ; local variable at[rbp-16] - currentIdx, pointer to top left pixel of currently checked L-shape
    sub rsp, 4                              ; local varaible at[rbp-20] - length of currently check L-shape
    sub rsp, 4                              ; local varaible at[rbp-24] - height  of currently check L-shape
    
    ; store saved registers 
    push rbx
    push r12
    push r13

    mov r9, 0                     ; set  counter of found markers to 0 

processBMP:
    mov rdx, HEIGHT         
    sub rdx, 1                              ; rdx is iterator over rows ; i

rowLoop: 
    xor rcx, rcx                            ; load 0 to rcx ; iterator over columns ; j
columnLoop:
    ; calculated pointer to this pixel and store in rax
    mov rax, rdx                            ; rax == rowIdx
    imul rax, WIDTH                         ; rax == WIDTH*rowIdx
    add rax, rcx                            ; rax == WIDTH*rowIdx + columnIdx
    imul rax, 3
    add rax, qword[rbp+8]                   ; now rax pointer to pixel in image 

    ; store result on stack 
    mov r10, rax                  ; store calculated pointer on stack
    mov r11, rax                  ; store current pointer on stack

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
    mov rdi, 1                              ; set counter of horizontal black line length to 1
    
    mov rbx, WIDTH                          ; rbx hold how many iterations left till end of line
    sub rbx, rcx                            ; rbx == WIDTH - currentColumn
    sub rbx, 1                              ; rbx == WIDTH - currentColumn - 1

calcLengthLoop:
    cmp rbx,0
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

    inc rdi                                 ; increment counter of black pixel
    dec rbx                                 ; decrement counter of how many iterations left in this row 

    jmp calcLengthLoop
    
exitCalcLengthLoop:                         ; length of horizontal black line has been calculated
    ; check if end of line has been reached - nie trzeba, wtedy odrazu przeskakjemy do endOfChecking
    
    ; store on stack calculated lengths
    mov r8, rdi                   ; store length on stack 
    mov r12, rdi  

    ; check if end of line has been reached
    cmp rbx,0
    je endOfChecking

    ; check parity
    test rdi, 1
    jnz endOfChecking                       ; jump if length of horizontal line is odd - marker is not correct 

    
    mov rsi, rdi                             
    shr rsi, 1                              ; divide length by 2, now rdi has anticipate length fof vertical line
    mov r13, rsi                  ; store legnth of vertical line on stack 

    ; check if vertical line will fit (we must have at least rsi+1 rows left to bottom) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

checkNonWhiteLOuter:                        ; check if L-shape above marker does not have black pixels 
    ; adjust it, so it point to pixel to the top and left from found black pixel 
    mov rax, r10                  ; load previous pointer from stack to rax 
    sub rax, 3                              ; adjust pointer ; pointer = pointer -3  + 3*WIDHT
    add rax, 3*WIDTH                        ; lea is not right instruction, because we use multiplication of 2 instant arguments
    
    ; load anticipated length of horizontal nonBlack line to register
    ; wanted length is already in rdi, just need to add 2 to it
    add rdi, 2

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
    dec rdi                                 ; decrement how many pixels to check
    test rdi, rdi
    jnz checkNonWhiteLOuterHorizontal       ; jump there are still pixels left to check

endOfCheckingNonWhiteLOuterHorizontal:      ; horizontal line is non black 
    mov rax, r10                  ; load previous pointer from stack to rax 
    sub rax, 3                              ; adjust pointer ; pointer = pointer -3  + 3*WIDHT
    add rax, 3*WIDTH                        ; lea is not right instruction, because we use multiplication of 2 instant arguments
    
    ; laod anticipated length
    mov rdi, r13
    add rdi, 2      

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
    dec  rdi                                ; decrement counter of elements to check 

    test rdi, rdi
    jnz checkNonWhiteLOuterVertical

endOfCheckingOuterNonBlackL:                ; at this point white, outer L-shape has been found - continue checking

checkBlackLLoop:                            ; at this point white, outer L-shape is correct ; checks if blackL, starting at [rbp-16] is black
    mov rdi, r12                  ; load right length to check horizontally
    mov rax, r11                  ; load right pointer

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
    dec rdi                                 ; adjust counter
    test rdi, rdi
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
    mov rdi, r13                  ; load right length to check vertically
    mov rax, r11                  ; load right pointer

checkBlackLVertical:                        ; loop that checks if vertical line is black
    cmp BYTE[rax], 0                        ; check if pixel is black
    jne exitBlackLLoop
    cmp BYTE[rax+1], 0
    jne exitBlackLLoop
    cmp BYTE[rax+2], 0
    jne exitBlackLLoop

    sub rax, 3*WIDTH                        ; increment pointer ; pointer -=3*WIDTH
    dec rdi                                 ; decrement number of elements to check
    test rdi, rdi 
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

    dec r12                       ; adjust lenght of next L-shape
    dec r13                       ; adjust height of next L-shpa 
    
    ; adjust pointer
    add r11, 3
    sub r11,3*WIDTH               ; pointer = pointer + 3 - 3*WDITH - now points to pixel to the right and down 

    ; quit chekcing if vertical lenght == 0 <- that's rectangle
    cmp r13, 0 
    je endOfChecking            

    jmp checkBlackLLoop

exitBlackLLoop:
    ; check if at least one black l was found ; if wasn't found [rbp-12] == [rbp-16], because pointer was not incremented
    mov rbx, [rbp-16]                       ; rbx is used as temporary register here
    cmp [rbp-12], rbx
    je endOfChecking

checkNonBlackInnerL:                        ; check if inner L-shape does not have black pixels
    mov rax, r11                  ; load pointer
    mov rdi, r12                  ; load lenght
    add rdi, 1                              ; we need to check one more pixel than if it would be black L

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
    dec rdi                                 ; decrement number of pixels to check
    test rdi, rdi
    jnz checkNonBlackInnerHorizontal        ; jump if there are pixels left to check

endOfNonBlackInnerHorizontal:               ; at this point horizontal, inner white line is good
    mov rax, r11                  ; load pointer
    mov rdi, r13                  ; load lenght
    add rdi, 1                              ; we need to check one more pixel than if it would be black L

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
    dec  rdi                                ; decrement counter of elements to check 

    test rdi, rdi                           ; jump if there are pixels left to check
    jnz checkNonBlackInnerVertical

answerFound:                                    
    ; add column to list
    ; obliczyć przesunięcie w rbx, potem dodać je do rbp+12
    mov rax, qword[rbp+12]                  ; load pointer to x positions
    mov rbx, r9                   ; count of markers
    mov qword[rax + 4*rbx], rcx             ; [baseAddressOfArray + 4*countOfMarkers]

    ; add row to list
    ; rsi - calculate row here 
    mov rsi, HEIGHT - 1
    sub rsi, rdx                            ; row(rsi) = HEIGHT - rowIdx - 1
    mov rax, qword[rbp+16]                  ; load pointer to y_positions
    mov qword[rax + 4*rbx], rsi             ; add to array calualted row
    
    inc r9                        ; increment counter of markers 

endOfChecking:
    add rcx,r8                    ; adjust column pointer, by adding lenght of found horizontal line
    dec rcx                                 ; -1, because in next step +1 will be added
continueLoops:
    inc rcx

    cmp rcx, WIDTH                          ; check if pointer over column is smaller than width after incrementation
    jl columnLoop                           ; if so, continue iteration over columns

    dec rdx
    test rdx, rdx                           ; test if rdx is zero
    jnz rowLoop

endFunction:

    mov rax, r9                   ; return result to rax

    ; restore saved registers 
    pop r13
    pop r12
    pop rbx



    ; function epilog 
    mov rsp, rbp                            ; delete local variables from stack 
    pop rbp 
    ret