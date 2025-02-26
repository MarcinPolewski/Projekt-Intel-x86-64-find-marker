# Task
Find a bitmap a marker of given proportions using x86-64 assembly language. Print to console row and column of the point, where lines cross. Marker is an "L", rotatet by 90 degrees to the right.

### Bitmap parameters:
- height: 240px
- width: 320px
- file name: "source.bmp"
### Marker parameters: 
- When marker's height==x, then marker's width==2x
- Must have 

# Implementation/algorith 
- iterate over image untill black pixel is found
- get length of horizontal, black line starting at found pixel
- check parity, if length is odd - continue with loop(increment pointer, by one pixel and start point 1)
- divide length by 2 and store - it is height of an L-shape that we are looking for
- check if L-shape above found black pixel is white(if not continue with loop)
- iteratate over black L-shapes(two lines, which are 1px wide and cross at one point),starting from found pixel and lengths. In every step:
    - check if horizontal line is black 
    - check if vertical line is black 
    - move pointer by one to the right and down.
    - decrement variables(in fact registers) responsible for storing wanted length and height for next black L
- check if L-shape below last black L-shape is  white, if it's not continue with the loop 
- print found result

# What was replaced to make it compatible with x86-64 in comparison to x86-32
x86_location x86-64_location 

ebp rbp
esp rsp

eax rax
ecx rcx
edx r8
ebx r9
esi r10
edi r11

DWORD[ebp-4] r12    <- to push
DWORD[ebp-8] r13     <- to push
DWORD[ebp-12] r14   <- to push
DWORD[ebp-16] r15   <- to push
DWORD[ebp-20] ebx   <- to push
DWORD[ebp-24] qword[ebp-8]

DWORD[rbp+8] rdi
DWORD[rbp+12] rsi
DWORD[rbp+16] rdx

# What is stored in registeres:
iteracja pentli:
- EAX - do liczenia idx, potem idx ląduje na stosie, potem uzywany jako current pointer
- ECX - iterator j(over columns)  
- EDX - iterator i(over rows) 

iteracja wewnątrz pętli
- EBX - used for how many iterations left till the end of line / temporary value
- ESI - aktualne długość pion / na początku do patrzenia ile zostało iteracji w danej linii -  
- EDI aktualna długość do sprawdzenia  

potrzebujemy dwa rejestry a current pointer aktualny początek, aktualna pozycja 
    - jeden trzymać na stosie 
- powinniśmy jeszcze trzymać ile zostało do końca linii 
- zapisać rejestr na stosie!! 

do iteracji poziomej: 
- ile do konca linii 
- aktualny pointer 


# stack 
    ## arguments
    mov edx, DWORD[ebp+8]           ; first argument - pointer to image
    mov eax, DWORD[ebp+12]          ; second argument - pointer to x_positions
    mov ecx, DWORD[ebp+16]          ; third argument - pointer to y_positions

    ## local variables 
    local variable at[ebp-4] - stores calculated length of horizontal line
    local variable at[ebp-8] - counter of found markers 
    local variable at[ebp-12] - stores pointer to pixel of coordinates[i,j], where i is row idx and j is column idx
    local variable at[ebp-16] - currentIdx, pointer to top left pixel of currently checked L-shape
    local varaible at[ebp-20] - length of currently check L-shape
    local varaible at[ebp-24] - height  of currently check L-shape

# ENCOUNTERED PROBLEMS
- used DWORD instead of BYTE while working with bytes 

- wszystko działa oprócz sprawdzania wewnetrznej L-ki
