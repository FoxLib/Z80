module de0(

      /* Reset */
      input              RESET_N,

      /* Clocks */
      input              CLOCK_50,
      input              CLOCK2_50,
      input              CLOCK3_50,
      inout              CLOCK4_50,

      /* DRAM */
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

      /* GPIO */
      inout       [35:0] GPIO_0,
      inout       [35:0] GPIO_1,

      /* 7-Segment LED */
      output      [6:0]  HEX0,
      output      [6:0]  HEX1,
      output      [6:0]  HEX2,
      output      [6:0]  HEX3,
      output      [6:0]  HEX4,
      output      [6:0]  HEX5,

      /* Keys */
      input       [3:0]  KEY,

      /* LED */
      output      [9:0]  LEDR,

      /* PS/2 */
      inout              PS2_CLK,
      inout              PS2_DAT,
      inout              PS2_CLK2,
      inout              PS2_DAT2,

      /* SD-Card */
      output             SD_CLK,
      inout              SD_CMD,
      inout       [3:0]  SD_DATA,

      /* Switch */
      input       [9:0]  SW,

      /* VGA */
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
wire clock_25;
wire clock_cpu;
wire clock_100;

de0pll u0(

    // Источник тактирования
    .clkin (CLOCK_50),

    // Производные частоты
    .m25   (clock_25),
    .m50   (clock_50),
    .m3_5  (clock_cpu),
    .m100  (clock_100),
);

// 64К Памяти
// -----------------------------------------------------------------------
memory UnitM(

    .clock      (clock_100),

    /* Процессор */
    /*
    .address_a  (pin_a),
    .q_a        (ram_i),
    .data_a     (pin_o),
    .wren_a     (ram_enw),
    */

    /* Видеоадаптер */
    .address_b  ({3'b010, fb_addr}),
    .q_b        (fb_data),
);

// Видеоадаптер
// -----------------------------------------------------------------------
wire [12:0] fb_addr;
wire [ 7:0] fb_data;
reg  [ 2:0] fb_border = 3'b000;

video UnitV(

    .clk        (clock_25),
    .red        (VGA_R),
    .green      (VGA_G),
    .blue       (VGA_B),
    .hs         (VGA_HS),
    .vs         (VGA_VS),
    .video_addr (fb_addr),
    .video_data (fb_data),
    .border     (fb_border)
);

endmodule
