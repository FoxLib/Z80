NAME=01_hello
all:
	./../bas2tap/bas2tap -q $(NAME).bas ../program.tap
	cd .. && ./vmzx -c -o record.png -a basic.z80 program.tap
