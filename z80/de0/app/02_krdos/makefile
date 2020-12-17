all:
	z80asm main.asm -o dos.bin
	php ../../makemif.php dos.bin=0  > ../../ram.mif
	hexdump -ve '/1 "%02x \n"' < dos.bin > ../../rom.hex
	cd ../.. && make
	../../../app/z80 dos.bin
