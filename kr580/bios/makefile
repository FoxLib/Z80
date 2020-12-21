all:
	z80asm mon.asm -o mon.bin
	php initram.php > ../de0/ram.mif
	cd ../de0 && make
	../emu/z80 mon.bin
