CC=g++
ASMBIN=nasm

all : asm cc link
asm :
	$(ASMBIN) -o find_markers.o -f elf64 find_markers.asm
cc :
	$(CC) -c -g -O0 main.cpp &> errors.txt
link :
	$(CC) -o test main.o find_markers.o
clean :
	rm *.o
	rm test
	rm errors.txt
