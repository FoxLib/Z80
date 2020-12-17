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

// -----------------------------------------------------------------------

wire        locked;
wire        clk_cpu;
reg  [1:0]  locked_rst = 2'b00;

// Ожидание реальной стабилизации данных
always @(posedge CLOCK_50) locked_rst <= {locked_rst[0], locked};

pll u0(
    .clkin      (CLOCK_50),     // BASE
    .m25        (clk25),        // VGA
    .m20        (clk_cpu),      // CPU LOWSPEED
    .m100       (clk),          // MEMORY
    .locked     (locked)
);

// ROM + RAM
// -----------------------------------------------------------------------

// Определение переднего фронта CPU CLOCK и запись только на 1 такте
reg [3:0] wren = 4'b0000;
always @(posedge clk) wren <= {wren[2:0], clock_cpu};

ram u1(

    .clock      (clk),

    /* Процессор */
    .address_a  (pin_a),
    .q_a        (pin_i),
    .data_a     (pin_o),
    .wren_a     (pin_enw && (pin_a >= 16'h4000) && wren == 4'b0011),

    /* Видео */
    .address_b  ({3'b010, video_addr}),
    .q_b        (video_data),

);

// Центральный процессор
// -----------------------------------------------------------------------

reg  [19:0] irq50    = 0;
wire        pin_intr = irq50 == 62500;
wire        pin_enw;
wire [15:0] pin_a;
wire [ 7:0] pin_i;
wire [ 7:0] pin_o;
wire [15:0] pin_pa;
reg  [ 7:0] pin_pi;
wire [ 7:0] pin_po;
wire        pin_pw;
wire        clock_cpu = (clk_cpu) & (locked_rst == 2'b11);

// Генератор 50 Гц IRQ для частоты 3.125 Мгц : 3`125`000 / 50 = 62500
always @(posedge clock_cpu) irq50 <= (irq50 == 62500) ? 0 : (irq50 + 1);  

z80 u3(

    .pin_reset  (~RESET_N),

    /* Шина данных */
    .pin_clk    (clock_cpu),
    .pin_i      (pin_i),
    .pin_a      (pin_a),
    .pin_enw    (pin_enw),
    .pin_o      (pin_o),

    /* Порты */
    .pin_pa     (pin_pa),
    .pin_pi     (pin_pi),
    .pin_po     (pin_po),
    .pin_pw     (pin_pw),

    /* Interrupt */
    .pin_intr   (pin_intr & 1)
);


// Контроллер порта
// --------------------------------------------------------------------

/* Запись в порты */
always @(negedge clock_cpu) begin

    // Запись разрешена
    if (pin_pw) begin

        if (pin_pa[7:0] == 8'hFE)
            border_color <= pin_po[2:0];

    end

end

/* Чтение из портов */
always @(*) begin

    case (pin_pa[7:0])

        /* Прием с клавиатуры по маске */
        8'hFE: begin

            // Бит N принимает сигнал с 8 возможных рядов
            // Каждый ряд активизируется обнулением битов от 8 до 15
            // То есть, если бит 8 равен 0, то активируется ряд 0 и т.д.

            pin_pi[0] = (zx_keys[0][0] & !pin_pa[ 8]) |
                        (zx_keys[1][0] & !pin_pa[ 9]) |
                        (zx_keys[2][0] & !pin_pa[10]) |
                        (zx_keys[3][0] & !pin_pa[11]) |
                        (zx_keys[4][0] & !pin_pa[12]) |
                        (zx_keys[5][0] & !pin_pa[13]) |
                        (zx_keys[6][0] & !pin_pa[14]) |
                        (zx_keys[7][0] & !pin_pa[15]);

            pin_pi[1] = (zx_keys[0][1] & !pin_pa[ 8]) |
                        (zx_keys[1][1] & !pin_pa[ 9]) |
                        (zx_keys[2][1] & !pin_pa[10]) |
                        (zx_keys[3][1] & !pin_pa[11]) |
                        (zx_keys[4][1] & !pin_pa[12]) |
                        (zx_keys[5][1] & !pin_pa[13]) |
                        (zx_keys[6][1] & !pin_pa[14]) |
                        (zx_keys[7][1] & !pin_pa[15]);

            pin_pi[2] = (zx_keys[0][2] & !pin_pa[ 8]) |
                        (zx_keys[1][2] & !pin_pa[ 9]) |
                        (zx_keys[2][2] & !pin_pa[10]) |
                        (zx_keys[3][2] & !pin_pa[11]) |
                        (zx_keys[4][2] & !pin_pa[12]) |
                        (zx_keys[5][2] & !pin_pa[13]) |
                        (zx_keys[6][2] & !pin_pa[14]) |
                        (zx_keys[7][2] & !pin_pa[15]);

            pin_pi[3] = (zx_keys[0][3] & !pin_pa[ 8]) |
                        (zx_keys[1][3] & !pin_pa[ 9]) |
                        (zx_keys[2][3] & !pin_pa[10]) |
                        (zx_keys[3][3] & !pin_pa[11]) |
                        (zx_keys[4][3] & !pin_pa[12]) |
                        (zx_keys[5][3] & !pin_pa[13]) |
                        (zx_keys[6][3] & !pin_pa[14]) |
                        (zx_keys[7][3] & !pin_pa[15]);

            pin_pi[4] = (zx_keys[0][4] & !pin_pa[ 8]) |
                        (zx_keys[1][4] & !pin_pa[ 9]) |
                        (zx_keys[2][4] & !pin_pa[10]) |
                        (zx_keys[3][4] & !pin_pa[11]) |
                        (zx_keys[4][4] & !pin_pa[12]) |
                        (zx_keys[5][4] & !pin_pa[13]) |
                        (zx_keys[6][4] & !pin_pa[14]) |
                        (zx_keys[7][4] & !pin_pa[15]);

        end

        /* Другое не реализовано сейчас */
        default: pin_pi = 8'hFF;

    endcase

end

// Видеоадаптер
// ---------------------------------------------------------------------

wire [12:0] video_addr;
wire [ 7:0] video_data;
reg  [ 2:0] border_color = 3'b111;

z80vid u4(

    .clk        (clk25),
    .red        (VGA_R),
    .green      (VGA_G),
    .blue       (VGA_B),
    .hs         (VGA_HS),
    .vs         (VGA_VS),
    .video_addr (video_addr),
    .video_data (video_data),
    .border     (border_color)

);


// Клавиатура
// ---------------------------------------------------------------------

reg         kbd_reset = 1'b0;
reg  [7:0]  ps2_command = 1'b0;
reg         ps2_command_send = 1'b0;
wire        ps2_command_was_sent;
wire        ps2_error_communication_timed_out;
wire [7:0]  ps2_data;
wire        ps2_data_clk;
reg         key_unpressed = 1'b0;

reg  [5:0]  zx_keys[8];

initial begin

    //                           0 1 2 3 4
    zx_keys[0] = 5'b11111; // Symb Z X C V
    zx_keys[1] = 5'b11111; //    A S D F G
    zx_keys[2] = 5'b11111; //    Q W E R T
    zx_keys[3] = 5'b11111; //    1 2 3 4 5
    zx_keys[4] = 5'b11111; //    0 9 8 7 6
    zx_keys[5] = 5'b11111; //    P O I U Y
    zx_keys[6] = 5'b11111; // Ent  L K J H
    zx_keys[7] = 5'b11111; // Spc Cs M N B

end

ps2_keyboard kdb0(

    /* Вход */
    .CLOCK_50       (CLOCK_50),
    .reset          (kbd_reset),
    .the_command    (ps2_command),
    .send_command   (ps2_command_send),

    /* Ввод-вывод */
    .PS2_CLK        (PS2_CLK),
    .PS2_DAT        (PS2_DAT),

    /* Статус команды */
    .command_was_sent               (ps2_command_was_sent),
    .error_communication_timed_out  (ps2_error_communication_timed_out),

    /* Выход полученных */
    .received_data      (ps2_data),
    .received_data_en   (ps2_data_clk)
);

/* Данные принимаются только по тактовому сигналу и при наличии ps2_data_clk */
always @(posedge CLOCK_50) begin

    if (ps2_data_clk) begin

        /* Принят сигнал отпускания клавиши */
        if (ps2_data == 8'hF0) begin
            key_unpressed <= 1'b1;

        end else begin

            case (ps2_data)

                /* РЯД 0 */
                /* SS */ 8'h12: zx_keys[0][0] <= key_unpressed; // CAPS
                /*  Z */ 8'h1A: zx_keys[0][1] <= key_unpressed;
                /*  X */ 8'h22: zx_keys[0][2] <= key_unpressed;
                /*  C */ 8'h21: zx_keys[0][3] <= key_unpressed;
                /*  V */ 8'h2A: zx_keys[0][4] <= key_unpressed;

                /* РЯД 1 */
                /*  A */ 8'h1C: zx_keys[1][0] <= key_unpressed;
                /*  S */ 8'h1B: zx_keys[1][1] <= key_unpressed;
                /*  D */ 8'h23: zx_keys[1][2] <= key_unpressed;
                /*  F */ 8'h2B: zx_keys[1][3] <= key_unpressed;
                /*  G */ 8'h34: zx_keys[1][4] <= key_unpressed;

                /* РЯД 2 */
                /*  Q */ 8'h15: zx_keys[2][0] <= key_unpressed;
                /*  W */ 8'h1D: zx_keys[2][1] <= key_unpressed;
                /*  E */ 8'h24: zx_keys[2][2] <= key_unpressed;
                /*  R */ 8'h2D: zx_keys[2][3] <= key_unpressed;
                /*  T */ 8'h2C: zx_keys[2][4] <= key_unpressed;

                /* РЯД 3 */
                /*  1 */ 8'h16: zx_keys[3][0] <= key_unpressed;
                /*  2 */ 8'h1E: zx_keys[3][1] <= key_unpressed;
                /*  3 */ 8'h26: zx_keys[3][2] <= key_unpressed;
                /*  4 */ 8'h25: zx_keys[3][3] <= key_unpressed;
                /*  5 */ 8'h2E: zx_keys[3][4] <= key_unpressed;

                /* РЯД 4 */
                /*  0 */ 8'h45: zx_keys[4][0] <= key_unpressed;
                /*  9 */ 8'h46: zx_keys[4][1] <= key_unpressed;
                /*  8 */ 8'h3E: zx_keys[4][2] <= key_unpressed;
                /*  7 */ 8'h3D: zx_keys[4][3] <= key_unpressed;
                /*  6 */ 8'h36: zx_keys[4][4] <= key_unpressed;

                /* РЯД 5 */
                /*  P */ 8'h4D: zx_keys[5][0] <= key_unpressed;
                /*  O */ 8'h44: zx_keys[5][1] <= key_unpressed;
                /*  I */ 8'h43: zx_keys[5][2] <= key_unpressed;
                /*  U */ 8'h3C: zx_keys[5][3] <= key_unpressed;
                /*  Y */ 8'h35: zx_keys[5][4] <= key_unpressed;

                /* РЯД 6 */
                /* EN */ 8'h5A: zx_keys[6][0] <= key_unpressed; // ENTER
                /*  L */ 8'h4B: zx_keys[6][1] <= key_unpressed;
                /*  K */ 8'h42: zx_keys[6][2] <= key_unpressed;
                /*  J */ 8'h3B: zx_keys[6][3] <= key_unpressed;
                /*  H */ 8'h33: zx_keys[6][4] <= key_unpressed;

                /* РЯД 7 */
                /* SP */ 8'h29: zx_keys[7][0] <= key_unpressed; // SPACE
                /* CS */ 8'h59: zx_keys[7][1] <= key_unpressed; // SYMBOL
                /*  M */ 8'h3A: zx_keys[7][2] <= key_unpressed;
                /*  N */ 8'h31: zx_keys[7][3] <= key_unpressed;
                /*  B */ 8'h32: zx_keys[7][4] <= key_unpressed;
                
                /* СПЕЦИАЛЬНЫЕ КНОПКИ */
                /* ,  */ 8'h41: begin zx_keys[7][1] <= key_unpressed; zx_keys[7][3] <= key_unpressed; end
                /* .  */ 8'h49: begin zx_keys[7][1] <= key_unpressed; zx_keys[7][2] <= key_unpressed; end
                /* /  */ 8'h4A: begin zx_keys[7][1] <= key_unpressed; zx_keys[7][4] <= key_unpressed; end                
                /* ;  */ 8'h4C: begin zx_keys[7][1] <= key_unpressed; zx_keys[6][2] <= key_unpressed; end
                /* '  */ 8'h52: begin zx_keys[7][1] <= key_unpressed; zx_keys[6][1] <= key_unpressed; end
                /* ]  */ 8'h5B: begin zx_keys[7][1] <= key_unpressed; zx_keys[5][0] <= key_unpressed; end
                /* [  */ 8'h54: begin zx_keys[7][1] <= key_unpressed; zx_keys[5][1] <= key_unpressed; end
                /* \  */ 8'h5D: begin zx_keys[7][1] <= key_unpressed; zx_keys[5][2] <= key_unpressed; end
                /* =  */ 8'h55: begin zx_keys[7][1] <= key_unpressed; zx_keys[5][3] <= key_unpressed; end
                /* -  */ 8'h4E: begin zx_keys[7][1] <= key_unpressed; zx_keys[5][4] <= key_unpressed; end
                /* ~  */ 8'h0E: begin zx_keys[7][1] <= key_unpressed; zx_keys[2][0] <= key_unpressed; end
                /* TB */ 8'h0D: begin zx_keys[7][1] <= key_unpressed; zx_keys[2][1] <= key_unpressed; end
                /* DL */ 8'h66: begin zx_keys[7][1] <= key_unpressed; zx_keys[2][2] <= key_unpressed; end

            endcase

            key_unpressed <= 1'b0;

        end
    end
end


endmodule
