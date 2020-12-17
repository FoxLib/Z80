all:
	iverilog -g2005-sv -DICARUS=1 main.v kr580.v -o main.qqq
	vvp main.qqq >> /dev/null
vcd:
	gtkwave main.vcd
wave:
	gtkwave main.gtkw
mif:
	date
	quartus_cdb de0 -c de0 --update_mif
	quartus_asm --read_settings_files=on --write_settings_files=off de0 -c de0
	date
