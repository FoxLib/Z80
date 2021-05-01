all:
	iverilog -g2005-sv -Icontrol -Ialu -Ibus -Iregisters de0/tap.v -DICARUS=1 -o tb.qqq tb.v
	vvp tb.qqq >> /dev/null
tap:
	php bin2mif.php tb.tap de0/tapmem.mif
bas:
	bas2tap -q tb.bas tb.tap -sHELLOBENCH
	make tap
spi:
	z80asm spi.asm -o spi.bin
vcd:
	gtkwave tb.vcd
wave:
	gtkwave tb.gtkw
clean:
	rm -f *.rpt *.summary *.sof *.done *.pin *.qws *.bak *.smsg *.qws *.vcd \
		  *.qqq *.jic *.map *.qqq undo_redo.txt PLLJ_PLLSPE_INFO.txt
	rm -rf db incremental_db simulation timing output_files
%:
	php bin2mif.php $@.tap de0/tapmem.mif
