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
    sub esp, 4                  ; local variable at[ebp-12] - currentIdx, pointer to top left pixel of currently checked L-shape
    
    ; store saved registers 
    push edi 
    push esi 
    push ebx

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

checkIfBlack:                   ; check if current pixel is black, if not continue with loops
    test [eax], [eax]
    jnz continueLoops
    inc eax
    test [eax], [eax]
    jnz continueLoops
    inc eax
    test [eax], [eax]
    jnz continueLoops
    inc eax

calcLength:                     ; calculate horizontal black line length
    ; if this point is reached pixel must be black, pointer is already incemenented and counter set to one
    mov edi, 1               ; increment counter of horizontal black line length




continueLoops:


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