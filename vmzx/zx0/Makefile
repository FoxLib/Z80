CC = g++
CFLAGS  = -ox -ob -ol+ -onatx -oh -g0 -O3 -oe -ot -Wall -xc -s
RM = rm

all: zx0 dzx0

zx0: zx0.o optimize.o compress.o memory.o zx0.h
	$(CC) zx0.o optimize.o compress.o memory.o -o zx0

zx0.o:
	$(CC) $(CFLAGS) -c zx0.c -o zx0.o
optimize.o:
	$(CC) $(CFLAGS) -c optimize.c -o zx0.o
compress.o:
	$(CC) $(CFLAGS) -c compress.c -o zx0.o
memory.o:
	$(CC) $(CFLAGS) -c memory.c -o zx0.o

dzx0: dzx0.c
	$(CC) $(CFLAGS) -o dzx0 dzx0.c

clean:
	$(RM) -f *.o dzx0 zx0
