FILE=01_hello
B2T=./../bas2tap/bas2tap
all:
	z80asm $(FILE).asm -o program.bin
	$(B2T) -q $(FILE).bas start.tap
	# Загрузка Бейсик-программы, автостарт (-a), загрузка бинарной программы
	cd .. && ./vmzx -b asm/program.bin 8000 -c -h -p 8000
	# cd .. && ./vmzx -a 48k.z80 asm/start.tap -b asm/program.bin 7000 -d -p 7000
