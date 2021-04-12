ASMFILE=01_hello
all:
	z80asm $(ASMFILE).asm -o program.bin
	cd .. && ./vmzx 48k.z80 -d -b asm/program.bin 8000
