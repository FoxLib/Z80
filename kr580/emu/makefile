CC=g++
LB=spi.o basic.o disasm.o cpu.o z80.o
SDL=`sdl-config --cflags --libs` -g -Wno-unused-result -Os

all: $(LB)
	$(CC) $(LB) -lSDL -o z80
	./z80

build: $(LB)
	$(CC) $(LB) -lSDL -o z80

z80.o: z80.cc z80.h
	$(CC) $(SDL) -c z80.cc -o z80.o

basic.o: basic.cc z80.h
	$(CC) $(SDL) -c basic.cc -o basic.o

cpu.o: cpu.cc z80.h
	$(CC) $(SDL) -c cpu.cc -o cpu.o

spi.o: spi.cc z80.h
	$(CC) $(SDL) -c spi.cc -o spi.o

disasm.o: disasm.cc disasm.h z80.h
	$(CC) $(SDL) -c disasm.cc -o disasm.o

clean:
	rm -f *.o
