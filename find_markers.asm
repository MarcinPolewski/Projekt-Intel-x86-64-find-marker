
    section .text
    global find_markers

find_markers: 
    ; function prolog
    push ebp
    mov ebp, esp
    
processBMP:
    mov eax, 0


endFunction:
    mov esp, ebp
    pop ebp 
    ret