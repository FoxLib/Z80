all: main.bin
	php ../../makemif.php main.bin=0 dizzy3.scr=4000 > ../../ram.mif
	hexdump -ve '/1 "%02x \n"' < main.bin > ../../rom.hex
	cd ../.. && make

main.bin: main.asm 
	z80asm main.asm -o main.bin
	dd conv=notrunc if=../font/dos.bin of=main.bin bs=1 seek=15616
	
clean:
	rm *.bin
