module de0(

    // Reset
    input              RESET_N,

    // Clocks
    input              CLOCK_50,
    input              CLOCK2_50,
    input              CLOCK3_50,
    inout              CLOCK4_50,

    // DRAM
    output             DRAM_CKE,
    output             DRAM_CLK,
    output      [1:0]  DRAM_BA,
    output      [12:0] DRAM_ADDR,
    inout       [15:0] DRAM_DQ,
    output             DRAM_CAS_N,
    output             DRAM_RAS_N,
    output             DRAM_WE_N,
    output             DRAM_CS_N,
    output             DRAM_LDQM,
    output             DRAM_UDQM,

    // GPIO
    inout       [35:0] GPIO_0,
    inout       [35:0] GPIO_1,

    // 7-Segment LED
    output      [6:0]  HEX0,
    output      [6:0]  HEX1,
    output      [6:0]  HEX2,
    output      [6:0]  HEX3,
    output      [6:0]  HEX4,
    output      [6:0]  HEX5,

    // Keys
    input       [3:0]  KEY,

    // LED
    output      [9:0]  LEDR,

    // PS/2
    inout              PS2_CLK,
    inout              PS2_DAT,
    inout              PS2_CLK2,
    inout              PS2_DAT2,

    // SD-Card
    output             SD_CLK,
    inout              SD_CMD,
    inout       [3:0]  SD_DATA,

    // Switch
    input       [9:0]  SW,

    // VGA
    output      [3:0]  VGA_R,
    output      [3:0]  VGA_G,
    output      [3:0]  VGA_B,
    output             VGA_HS,
    output             VGA_VS
);

// Z-state
assign DRAM_DQ = 16'hzzzz;
assign GPIO_0  = 36'hzzzzzzzz;
assign GPIO_1  = 36'hzzzzzzzz;

// LED OFF
assign HEX0 = 7'b1111111;
assign HEX1 = 7'b1111111;
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

// ---------------------------------------------------------------------
// Генерация частот
// ---------------------------------------------------------------------

wire locked;
wire clock_25;
wire clock_100;

// Стабилизация тактов
reg [1:0] L100; always @(posedge clock_100) L100 <= {L100[0], locked};

de0pll unit_pll
(
    .clkin     (CLOCK_50),
    .m25       (clock_25),
    .m100      (clock_100),
    .locked    (locked)
);

// ---------------------------------------------------------------------
// Процессор
// ---------------------------------------------------------------------

wire [15:0] address;
wire [ 7:0] data;
wire [ 7:0] q;
wire        wren_cpu;

z80 UnitZ80(

    .CLOCK  (clock_100),
    .HOLD   (L100 == 2'b11),
    .A      (address),
    .DI     (q),
    .DO     (data),
    .W      (wren_cpu)
);

// ---------------------------------------------------------------------
// Контроллер памяти
// ---------------------------------------------------------------------

reg         wren;

// Маршрутизация памяти
always @* begin

    wren = wren_cpu;
    if (address[15:14] == 2'b00) wren = 1'b0;

end

memory UnitMemory
(
    .clock     (clock_locked),
    .address_a (address),
    .q_a       (q),
    .data_a    (data),
    .wren_a    (wren),
    // Видеопамять
    .address_b ({3'b010, address_b[12:0]}),
    .q_b       (q_b),
);

// ---------------------------------------------------------------------
// Контроллер видеоадаптера
// ---------------------------------------------------------------------

reg  [ 2:0] border = 7;
wire [15:0] address_b;
wire [ 7:0] q_b;

ula ULAUnit(

    .clk        (clock_25),
    .red        (VGA_R),
    .green      (VGA_G),
    .blue       (VGA_B),
    .hs         (VGA_HS),
    .vs         (VGA_VS),
    .video_addr (address_b),
    .video_data (q_b),
    .border     (border)
);

endmodule

`include "../z80.v"
