all:
	z80asm unit.asm -o unit.bin
	dd conv=notrunc if=dos.font of=unit.bin bs=1 seek=15616
	make de0
	cd .. && make build && ./z80 unit/unit.bin
zex:
	cd ../ && ./z80 unit/zexall.com

de0:
	php ../../de0/makemif.php unit.bin=0 > ../../de0/ram.mif
