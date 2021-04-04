NAME=01_hello
all:
	./../bas2tap/bas2tap -q $(NAME).bas ../program.tap
	cd .. && ./vmzx -a basic.z80 program.tap
