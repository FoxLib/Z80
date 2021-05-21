`timescale 10ns / 1ns
module tb;

reg clock;
reg clock_25;
reg clock_50;

always #0.5 clock    = ~clock;
always #1.0 clock_50 = ~clock_50;
always #1.5 clock_25 = ~clock_25;

initial begin clock = 0; clock_25 = 0; clock_50 = 0; #2000 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end

// ---------------------------------------------------------------------

reg  [ 7:0] memory[65536];

wire [15:0] address;
wire [ 7:0] data_o;
reg  [ 7:0] data_i = 8'hFF;
wire        we;

initial $readmemh("mem.hex", memory, 0);

always @(posedge clock) begin

    data_i <= memory[address];
    if (we) memory[address] <= data_o;

end

z80 CPUnit
(
    .clock      (clock_25),
    .address    (address),
    .data_i     (data_i),
    .data_o     (data_o),
    .we         (we)
);

endmodule
