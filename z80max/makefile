all:
	z80asm test.asm -o test.bin
	php bin2hex.php test.bin memory.hex
	php bin2mif.php test.bin de0/memory.mif 65536
	iverilog -g2005-sv -DICARUS=1 -o tb.qqq tb.v z80.v
	vvp tb.qqq >> /dev/null
	# make run
run:
	cd ../vmzx && ./vmzx -r1 ../z80max/test.bin -d
vcd:
	gtkwave tb.vcd
wave:
	gtkwave tb.gtkw
clean:
	rm -rf db incremental_db simulation timing greybox_tmp *.jdi *.pof *.sld *.rpt *.summary *.sof *.done *.pin *.qws *.bak *.smsg *.qws *.vcd *.qqq *.jic *.map .qsys_edit undo_redo.txt PLLJ_PLLSPE_INFO.txt c5_pin_model_dump.txt

