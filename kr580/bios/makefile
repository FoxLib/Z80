all:
	z80asm mon.asm -o mon.bin
	hexdump -ve '/1 "%02x \n"' < mon.bin > mon.hex
	php initram.php > ../de0/ram.mif
	cd ../de0 && make
	../emu/z80 mon.bin
