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
wire locked;

de0pll u0(

    // Источник тактирования
    .clkin  (CLOCK_50),

    // Производные частоты
    .m25    (clock_25),
    .m50    (clock_50),
    .m3_5   (clock_cpu),
    .m100   (clock_100),
    .locked (locked),
);

// Интерфейс памяти
// -----------------------------------------------------------------------
wire  [ 7:0] Dout;
wire  [15:0] A;
wire  [ 7:0] D;

// Писать только если разрешено и не ROM
wire W = nIORQ==1 && nRD==1 && nWR==0 && A[15:14]!=2'b00;

// При nRD=0 - читать из памяти или порта
assign D =
    nRD   ? 8'hZZ :             // nRD=1   Чтение не производится
    nIORQ ? Dout  :             // nIORQ=1 Читать из памяти
    A[7:0] == 8'hFE ? DKbd :    // nIORQ=0 Читать из порта FEh
    8'hFF;

// 64Кб
memory UnitM
(
    .clock      (clock_100),

    // Процессор
    .address_a  (A),
    .q_a        (Dout),
    .data_a     (D),
    .wren_a     (W),

    // Видеоадаптер
    .address_b  ({3'b010, fb_addr}),
    .q_b        (fb_data),
);

// Ввод-вывод
// ---------------------------------------------------------------------
always @(posedge clock_25) begin

    if (nIORQ==0 && nRD==1 && nWR==0) begin

        // Обновление бордюра
        if (A[7:0] == 8'hFE) fb_border[2:0] <= D[2:0];

    end

end

// Видеоадаптер
// ---------------------------------------------------------------------
wire  [12:0] fb_addr;
wire  [ 7:0] fb_data;
reg   [ 2:0] fb_border = 3'b000;
wire         nvblank;

video UnitV(

    .clk        (clock_25),
    .red        (VGA_R),
    .green      (VGA_G),
    .blue       (VGA_B),
    .hs         (VGA_HS),
    .vs         (VGA_VS),
    .video_addr (fb_addr),
    .video_data (fb_data),
    .border     (fb_border),
    .nvblank    (nvblank)
);

// Модуль клавиатуры
// ---------------------------------------------------------------------
wire [7:0]  ps2_data;
wire        ps2_data_clk;
wire [7:0]  DKbd;

// Физический интерфейс
ps2_keyboard UnitPS(

    .CLOCK_50           (CLOCK_50),
    .PS2_CLK            (PS2_CLK),
    .PS2_DAT            (PS2_DAT),
    .received_data      (ps2_data),
    .received_data_en   (ps2_data_clk)
);

// Клавиатура ZX
keyboard UnitKBD(

    .CLOCK_50       (CLOCK2_50),
    .ps2_data_clk   (ps2_data_clk),
    .ps2_data       (ps2_data),
    .A              (A),
    .D              (DKbd)
);

// ---------------------------------------------------------------------
// Интерфейс оригинала процессора Z80
// ---------------------------------------------------------------------

wire nM1;       // Машинный цикл
wire nMREQ;     // Сигнал инициализации устройств памяти (ОЗУ или ПЗУ);
wire nIORQ;     // Сигнал инициализации портов ввода-вывода.
wire nRD;       // Запрос чтения (RD=0)
wire nWR;       // Запрос записи (WR=0)
wire nRFSH;     // Refresh (регистр R)
wire nHALT;     // Останов процессора
wire nBUSACK;   // Запрос шины

// Срабатывает при 0, вызывается при каждом кадре VGA (50 Гц)
wire nINT       = (~nRESET) | nvblank;
wire nNMI       = 1; // NMI активируется при 0
wire nBUSRQ     = 1; // Всегда 1
wire nWAIT      = 1;    // Всегда 1
wire nRESET     = locked & RESET_N;     // Сброс, пока не сконфигурирован выход PLL
wire CLOCK      = clock_cpu & locked;   // Заблокировать такты

z80_top_direct_n Z80Unit
(
    // Тактирование
    .CLK        (CLOCK),    // Тактовая частота 3.5 Мгц

    // Выход
    .nM1        (nM1),      // Машинный цикл
    .nMREQ      (nMREQ),    // Сигнал запроса к памяти RAM/ROM
    .nIORQ      (nIORQ),    // Сигнал запроса к портам
    .nRD        (nRD),      // Сигнал чтения из памяти
    .nWR        (nWR),      // Запись в память
    .nRFSH      (nRFSH),    // Запрос обновления DRAM (не требуется)
    .nHALT      (nHALT),    // Сигнал остановки процессора
    .nBUSACK    (nBUSACK),  // Запрос шины

    // Вход
    .nWAIT      (nWAIT),    // Ожидание разблокировки процессора (1)
    .nINT       (nINT),     // Запрос Interrupt с VBlank
    .nNMI       (nNMI),     // Запрос NMI
    .nRESET     (nRESET),   // Сброс процессора
    .nBUSRQ     (nBUSRQ),   // Запрос на шину данных

    // Ввод-вывод
    .A          (A),        // Адрес 64к
    .D          (D)         // Данные 8 бит
);

endmodule

`include "../z80_top_direct_n.v"
