all:
	iverilog -g2005-sv -DICARUS=1 tb.v kr580.v -o main.qqq
	vvp main.qqq >> /dev/null
vcd:
	gtkwave tb.vcd
wave:
	gtkwave tb.gtkw
