FILE=01_hello
B2T=./../bas2tap/bas2tap
VMZX=cd .. && ./vmzx
all:
	make zx0
zx0:
	z80asm $(FILE).asm -o program.bin
	$(VMZX) -b asm/test.zx0 6000 -b asm/program.bin 8000 -d -p 8000
# Загрузка Бейсик-программы, автостарт (-a), загрузка бинарной программы
bas:
	z80asm $(FILE).asm -o program.bin
	$(B2T) -q $(FILE).bas start.tap
	$(VMZX) -b asm/program.bin 8000 -c -h -p 8000
	# cd .. && ./vmzx -a 48k.z80 asm/start.tap -b asm/program.bin 7000 -d -p 7000
