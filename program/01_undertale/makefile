all:
	cd data/event && make
	z80asm main.asm -o undertale.bin
	vmzx -b undertale.bin 6600 -p 6600
