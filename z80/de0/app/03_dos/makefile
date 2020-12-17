all:
	z80asm dos.asm -o dos.bin
	dd conv=notrunc if=dos.font of=dos.bin bs=1 seek=15616

mif:	
	php ../../makemif.php dos.bin=0  > ../../ram.mif
	hexdump -ve '/1 "%02x \n"' < dos.bin > ../../rom.hex
	cd ../.. && make

clean:
	rm dos.bin

