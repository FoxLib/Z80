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
// Небольшой контроллер памяти
// ---------------------------------------------------------------------

wire [15:0] A;
reg  [7:0]  DI;
wire [7:0]  DO;
wire        W;
reg  [7:0]  memory[65536];

initial $readmemh("memory.hex", memory, 16'h0000);

always @(posedge clock) begin

    DI <= memory[A];
    if (W) memory[A] <= DO;

end

// ---------------------------------------------------------------------
// Процессор
// ---------------------------------------------------------------------

z80 Z80Core
(
    .CLOCK  (clock),
    .RESETn (1'b1),
    .A      (A),
    .DI     (DI),
    .DO     (DO),
    .W      (W)
);

endmodule
