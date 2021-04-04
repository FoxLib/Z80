CC=gcc
CFLAGS=-Wall -O2

all:
	./bas2tap -q test.bas ../test.tap
	cd .. && ./main basic.z80 test.tap

build:
	$(CC) $(CFLAGS) bas2tap.c -o bas2tap -lm

clean:

	rm -f bas2tap
