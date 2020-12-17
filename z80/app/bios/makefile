all:
	z80asm homebrew.asm -o homebrew.bin
	cd .. && make build && ./z80 bios/homebrew.bin
