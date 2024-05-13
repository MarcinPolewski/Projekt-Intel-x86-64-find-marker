CC=g++
ASMBIN=nasm

all : asm cc link
asm :
	$(ASMBIN) -o find_markers.o -f elf -g -l find_markers.lst find_markers.asm
cc :
	$(CC) -m32 -c -g -O0 main.cpp &> errors.txt
link :
	$(CC) -m32 -g -o test main.o find_markers.o
clean :
	rm *.o
	rm test
	rm errors.txt
	rm find_markers.lst