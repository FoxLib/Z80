`timescale 10ns / 1ns

/*
 * Эмулятор КР580*** какого-то там компа
 */

module main;

// ---------------------------------------------------------------------

reg         clk;
always #0.5 clk         = ~clk;

initial begin clk = 1; #20 pin_intr = 1'b1; #2000 $finish; end
initial begin $dumpfile("main.vcd"); $dumpvars(0, main); end

// ---------------------------------------------------------------------

reg  [ 1:0] clock_divider = 0;
wire        clock_cpu = clock_divider[1];

reg  [ 7:0] memory[65536];            // 64 kb памяти
reg  [ 7:0] bus_data_i = 8'h00;       // То, что читается из памяти
wire [ 7:0] bus_data_o;               // То, что пишется в память
wire [15:0] bus_addr;

initial $readmemh("../bios/mon.hex", memory, 16'h0000);

/* Формируется логика чтения и записи в память */
always @(posedge clk) begin

    bus_data_i <= memory[ bus_addr ];

    if (ena_wrmem) begin
        memory[ bus_addr ] <= bus_data_o;
    end

end

/* Тактовая частота в 25 мгц -- стандарт */
always @(posedge clk) begin

    clock_divider <= clock_divider + 1'b1;

end

wire [7:0] pin_pa;
wire [7:0] pin_pi = 0;
wire [7:0] pin_po;
wire       pin_pw;
reg        pin_intr = 1'b0;

// ---------------------------------------------------------------------

kr580 cpu(

    clock_cpu,
    bus_data_i,
    bus_addr,
    ena_wrmem,
    bus_data_o,

    pin_pa,
    pin_pi,
    pin_po,
    pin_pw,

    pin_intr
);

endmodule
