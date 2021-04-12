FILE=01_hello
B2T=./../bas2tap/bas2tap
all:
	z80asm $(FILE).asm -o program.bin
	$(B2T) -q $(FILE).bas start.tap
	# Загрузка Бейсик-программы, автостарт (-a), загрузка бинарной программы
	cd .. && ./vmzx 48k.z80 asm/start.tap -a -b asm/program.bin 8000
