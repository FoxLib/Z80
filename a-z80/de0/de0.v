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

// MISO: Input Port
assign SD_DATA[0] = 1'bZ;

// Z-state
assign DRAM_DQ = 16'hzzzz;
assign GPIO_0  = 36'hzzzzzzzz;

// D35-GND, D34-SPKR
assign GPIO_1  = {~speaker, 1'bz, speaker, 33'hzzzzzzzz};

// LED OFF
assign HEX0 = 7'b1111111;
assign HEX1 = 7'b1111111;
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

// ---------------------------------------------------------------------
wire clock_25;
wire clock_3_5;
wire clock_7;
wire clock_14;
wire clock_100;

// ???????????????????? TURBO-????????????
wire clock_cpu = SW[1] ? clock_25 : clock_3_5;
wire locked;

de0pll u0
(
    // ???????????????? ????????????????????????
    .clkin  (CLOCK_50),

    // ?????????????????????? ??????????????
    .m3_5   (clock_3_5),
    .m7     (clock_7),
    .m14    (clock_14),
    .m25    (clock_25),
    .m100   (clock_100),
    .locked (locked),
);

// -----------------------------------------------------------------------
// ?????????????????? ????????????
// -----------------------------------------------------------------------

reg   [ 7:0] Data;              // ???????????? ???? ???????????????? ????????
wire  [ 7:0] Dout;              // ?????????????????????? ???????????? 128k
wire  [ 7:0] Drom;              // ?????????????????? ?? ROM
wire  [ 7:0] Trom;              // ?????????????????? ?? ROM TrDOS
wire  [15:0] A;
wire  [ 7:0] D;
reg   [16:0] address;
reg   [ 7:0] membank = 8'b00000000;
reg          trdoslatch = 1'b0;

// ???????????? ???????????? ???????? ??????????????????, ?? ???? ?????????????????? ???? ROM
wire W = (nIORQ == 1 && nRD == 1 && nWR == 0 && A[15:14] != 2'b00);

// ?????? nRD=0 - ???????????? ???? ???????????? ?????? ??????????
// ?????? nWR=0   ???????????? ?? ???????????? ?????? ????????
assign D =

    // ?????? ???????? ??????????????????
    nRD && nWR && nMREQ ? 8'hFF :

    // ???????????? ???? ????????????????????????
    nRD   ? 8'hZZ :

    // ???????????? ???? ????????????
    nIORQ ? Data :
    // @TODO ???????????? ???? AY
    // ???????????? ???? ?????????? FEh
    A[0] == 1'b0 ? {1'b1, /*D6*/ mic, 1'b1, /*D4..D0*/ DKbd[4:0]} :
    // ?????? ??????????????????
    8'hFF;

// Dout - ?????????????????????????? ?? ?????????????????????? ???? ?????????????????? ???????????????? ????????????
always @* begin

    address = A;
    Data    = Dout;

    case (A[15:14])

        // ?????????? ?????????? ???????????? ROM; 1-48k, 0-128k. ???????? membank[5]=1, ???? ?????????? ???????????? 48k
        /* 0000-3FFF */ 2'b00: begin address = {membank[4] | membank[5], A[13:0]}; Data = (trdoslatch ? Trom : Drom); end

        // ???????????? 16?? ???????? ???????????? ???????????????????? bank 5
        /* 4000-7FFF */ 2'b01: begin address = {3'b101, A[13:0]}; end

        // ?????????????? ????????????: ???????????? bank 2
        /* 8000-BFFF */ 2'b10: begin address = {3'b010, A[13:0]}; end

        // ?????????????? ????????????; ?????????????????????????? ???????????????????????? ???????????? ???????? membank[5]=1
        /* C000-FFFF */ 2'b11: begin address = {membank[5] ? 3'b000 : membank[2:0], A[13:0]}; end

    endcase

end

// ???????????????????????? ?? TRDOS
always @(posedge CLOCK) begin

    if (RESET_N == 1'b0) trdoslatch <= 1'b0;

    // Trdos ?????????? ???????????????? ???????????? ?? 48k
    // ?????????? ???? Trdos ?????????? ???????????? ?????????? ???? ROM
    if (!nM1 && (membank[4] | membank[5])) begin

        if (A[15:8] == 8'h3D)
            trdoslatch <= 1'b1;
        else if (trdoslatch && A[15:14])
            trdoslatch <= 1'b0;

    end

end

// 128k
memory UnitM
(
    .clock      (clock_100),

    // ??????????????????
    .address_a  (address),
    .q_a        (Dout),
    .data_a     (D),
    .wren_a     (W),

    // ???????????????????????? (5-?? ?????? 7-?? ????????)
    // ???????? membank[5]=1, ???????????????????????? ???? 5-?? ??????????
    .address_b  ({1'b1, membank[5] ? membank[3] : 1'b0, 2'b10, fb_addr}),
    .q_b        (fb_data),
);

// 32k ROM 128/48k
rom UnitR
(
    .clock      (clock_100),
    .address_a  (address[14:0]),
    .q_a        (Drom),

);

trdos TrDOSROM
(
    .clock      (clock_100),
    .address_a  (address[13:0]),
    .q_a        (Trom)
);

// ---------------------------------------------------------------------
// ????????-??????????
// ---------------------------------------------------------------------

wire mic;
reg  speaker;

always @(posedge clock_25) begin

    // ???????????????? ?????????????????? ?????? ????????????
    if (RESET_N == 1'b0) begin membank <= 1'b0; end

    // ???????????????????? ???????????? ?? ????????
    if (nIORQ == 0 && nRD == 1 && nWR == 0) begin

        // ?????????? ?????????? ?? ???????????????? ???????????????? ???????????? ?????? ???????? 5, ?????????????? 0
        if (A == 16'h7FFD && !membank[5]) membank <= D;

        // AY-3-8910
        else if (A == 18'hFFFD || A == 18'hBFFD) begin /* ???????????? ?????? */ end

        // ???????????????????? ?????????????? https://speccy.info/????????_FE
        else if (A[0] == 1'b0) begin

            fb_border[2:0]  <= D[2:0];         // D3-???????????????????? ?????????????? ???? ????????????????????
            speaker         <= D[4] ^ D[3];    // ?????????? ???????????????? (?? ??????????????????)

        end

    end

end

// ---------------------------------------------------------------------
// ????????????????????????
// ---------------------------------------------------------------------

wire  [11:0] ch_address;
wire  [11:0] fn_address;
wire  [ 7:0] fn_data;
wire  [ 7:0] ch_data1;
wire  [ 7:0] ch_data2;

wire  [12:0] fb_addr;
wire  [ 7:0] fb_data;
reg   [ 2:0] fb_border = 3'b000;
wire         nvblank;
wire         f1_screen;
wire         f2_screen;

video UnitV
(
    .clk        (clock_25),
    .red        (VGA_R),
    .green      (VGA_G),
    .blue       (VGA_B),
    .hs         (VGA_HS),
    .vs         (VGA_VS),

    // ????????????
    .video_addr (fb_addr),
    .video_data (fb_data),
    .border     (fb_border),
    .nvblank    (nvblank),          // IRQ

    // ???????????????????????????? ??????????
    .f1_screen  (f1_screen),
    .f2_screen  (SW[0]),
    .ch_address (ch_address),
    .fn_address (fn_address),
    .fn_data    (fn_data),
    .ch_data1   (ch_data1),
    .ch_data2   (ch_data2),
);

// ---------------------------------------------------------------------
// ?????????????????????? ???????????? ?? ???????????????? ?????????????????? ?? ????????????????????
// ---------------------------------------------------------------------

// ???????????? 8x16 (4k)
font UnitFnt
(
    .clock      (clock_100),
    .address_a  (fn_address),
    .q_a        (fn_data)
);

// ?????????? ?????????????????? (4k)
srcdata #(.MIF_FILE("screen1.mif")) UnitSrc1
(
    .clock      (clock_100),
    .address_a  (ch_address),
    .q_a        (ch_data1)
);

// ?????????? ?????????????? ?? ?????????????????? (4k)
srcdata #(.MIF_FILE("screen2.mif")) UnitSrc2
(
    .clock      (clock_100),
    .address_a  (ch_address),
    .q_a        (ch_data2)
);

// ---------------------------------------------------------------------
// ???????????? ????????????????????
// ---------------------------------------------------------------------

wire [7:0]  ps2_data;
wire        ps2_data_clk;
wire [7:0]  DKbd;

// ???????????????????? ??????????????????
ps2_keyboard UnitPS
(
    .CLOCK_50           (CLOCK_50),
    .PS2_CLK            (PS2_CLK),
    .PS2_DAT            (PS2_DAT),
    .received_data      (ps2_data),
    .received_data_en   (ps2_data_clk)
);

// ???????????????????? ZX
keyboard UnitKBD
(
    .CLOCK_50       (CLOCK2_50),
    .ps2_data_clk   (ps2_data_clk),
    .ps2_data       (ps2_data),
    .A              (A),
    .D              (DKbd),
    .f1_screen      (f1_screen),
);

// ---------------------------------------------------------------------
// ???????????????? ??????????????????????
// ---------------------------------------------------------------------

wire [15:0] tap_address;
wire [ 7:0] tap_data;

tap TAPLoader
(
    .reset_n        (nRESET),
    .clock          (CLOCK),
    .mic            (mic),
    .play           (~KEY[0]),      // ?????? ?????????????? ???????????? ???????????????????? PLAY
    .tap_address    (tap_address),
    .tap_data       (tap_data),
);

// ???????????? ???????????? ?? tap-????????????
tapmem UnitTapmem
(
    .clock     (clock_100),
    .address_a (tap_address),
    .q_a       (tap_data),
);

// ---------------------------------------------------------------------
// ?????????????????? SPI
// ---------------------------------------------------------------------

wire [1:0]  sd_cmd;
wire [7:0]  sd_din;
wire [7:0]  sd_out;
wire        sd_signal;
wire        sd_busy;
wire        sd_timeout;

sd UnitSD(

    // 50 Mhz
    .clock50    (CLOCK_50),

    // ???????????????????? ??????????????????
    .SPI_CS     (SD_DATA[3]),   // ?????????? ????????
    .SPI_SCLK   (SD_CLK),       // ???????????????? ??????????????
    .SPI_MISO   (SD_DATA[0]),   // ???????????????? ????????????
    .SPI_MOSI   (SD_CMD),       // ??????????????????

    // ??????????????????
    .sd_signal  (sd_signal),   // In   =1 ?????????????????? ???????????????? ???? spi
    .sd_cmd     (sd_cmd),      // In      ??????????????
    .sd_din     (sd_din),      // Out     ???????????????? ?????????????????? ???? ??????????
    .sd_out     (sd_out),      // In      ?????????????????? ???? ???????????????? ?? ??????????
    .sd_busy    (sd_busy),     // Out  =1 ????????????
    .sd_timeout (sd_timeout),  // Out  =1 ??????????????
);

// ---------------------------------------------------------------------
// ?????????????????? ?????????????????? ???????????????????? Z80
// ---------------------------------------------------------------------

wire nM1;       // ???????????????? ????????
wire nMREQ;     // ???????????? ?????????????????????????? ?????????????????? ???????????? (?????? ?????? ??????);
wire nIORQ;     // ???????????? ?????????????????????????? ???????????? ??????????-????????????.
wire nRD;       // ???????????? ???????????? (RD=0)
wire nWR;       // ???????????? ???????????? (WR=0)
wire nRFSH;     // Refresh (?????????????? R)
wire nHALT;     // ?????????????? ????????????????????
wire nBUSACK;   // ???????????? ????????

// ?????????????????????? ?????? 0, ???????????????????? ?????? ???????????? ?????????? VGA (50 ????)
wire nINT       = (~nRESET) | nvblank;
wire nNMI       = 1;    // NMI ???????????????????????? ?????? 0
wire nBUSRQ     = 1;    // ???????????? 1
wire nWAIT      = 1;    // ???????????? 1
wire nRESET     = locked & RESET_N;     // ??????????, ???????? ???? ?????????????????????????????? ?????????? PLL
wire CLOCK      = clock_cpu & locked;   // ?????????????????????????? ??????????

z80_top_direct_n Z80Unit
(
    // ????????????????????????
    .CLK        (CLOCK),    // ???????????????? ?????????????? 3.5 ??????

    // ??????????
    .nM1        (nM1),      // ???????????????? ????????
    .nMREQ      (nMREQ),    // ???????????? ?????????????? ?? ???????????? RAM/ROM
    .nIORQ      (nIORQ),    // ???????????? ?????????????? ?? ????????????
    .nRD        (nRD),      // ???????????? ???????????? ???? ????????????
    .nWR        (nWR),      // ???????????? ?? ????????????
    .nRFSH      (nRFSH),    // ???????????? ???????????????????? DRAM (???? ??????????????????)
    .nHALT      (nHALT),    // ???????????? ?????????????????? ????????????????????
    .nBUSACK    (nBUSACK),  // ???????????? ????????

    // ????????
    .nWAIT      (nWAIT),    // ???????????????? ?????????????????????????? ???????????????????? (1)
    .nINT       (nINT),     // ???????????? Interrupt ?? VBlank
    .nNMI       (nNMI),     // ???????????? NMI
    .nRESET     (nRESET),   // ?????????? ????????????????????
    .nBUSRQ     (nBUSRQ),   // ???????????? ???? ???????? ????????????

    // ????????-??????????
    .A          (A),        // ?????????? 64??
    .D          (D)         // ???????????? 8 ??????
);

endmodule

`include "../sd.v"
`include "../z80_top_direct_n.v"
