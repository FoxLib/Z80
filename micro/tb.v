`timescale 10ns / 1ns
module tb;

reg clock;
reg clock_25;
reg clock_50;
reg locked = 0;

always #0.5 clock    = ~clock;
always #1.0 clock_50 = ~clock_50;
always #1.5 clock_25 = ~clock_25;

initial begin clock = 1; clock_25 = 0; clock_50 = 0; #3 locked = 1; #2000 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end

// ---------------------------------------------------------------------

reg  [ 7:0] memory[65536];

wire [15:0] address;
wire [ 7:0] o_data;
reg  [ 7:0] i_data = 8'hFF;
wire        we;

initial $readmemh("mem.hex", memory, 0);

always @(posedge clock) begin

    i_data <= memory[address];
    if (we) memory[address] <= o_data;

end

z80 CPUnit
(
    .clock      (clock_25 & locked),
    .address    (address),
    .i_data     (i_data),
    .o_data     (o_data),
    .we         (we)
);

endmodule
