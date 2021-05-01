/*  Модуль SPI

Top Level Schema:

    .SPI_MISO   (SD_DATA[0]),       // Входящие данные
    .SPI_MOSI   (SD_CMD),           // Исходящие
    .SPI_SCLK   (SD_CLK),           // Тактовая частота
    .SPI_CS     (SD_DATA[3]),       // Выбор чипа

COMMAND
------------------
00  INIT
01  TRANSMIT
02  CS=0
03  CS=1
------------------
*/

module sd(

    // 50 Mhz
    input  wire         clock50,

    // SPI
    output reg          SPI_CS,
    output reg          SPI_SCLK,
    input  wire         SPI_MISO,
    output reg          SPI_MOSI,

    // Интерфейс
    input  wire         sd_signal,  // 0->1 Команда на позитивном фронте
    input  wire [ 1:0]  sd_cmd,     // ID команды
    output reg  [ 7:0]  sd_din,     // Исходящие данные в процессор
    input  wire [ 7:0]  sd_out,     // Входящие данные из процессора
    output reg          sd_busy,    // =1 Устройство занято
    output wire         sd_timeout  // =1 Вышел таймаут
);

`define SPI_TIMEOUT_CNT     5000000     // 0.1 s

initial begin

    SPI_CS   = 1'b1;
    SPI_SCLK = 1'b0;
    SPI_MOSI = 1'b0;
    sd_din  = 8'h00;

end

// ---------------------------------------------------------------------
// SPI SdCard
// ---------------------------------------------------------------------

// Сигналы нейтрализации (сброс активации команды)
reg  [1:0]  spi_latch   = 2'b00;

// Сигнал о том, занято ли устройство
assign      sd_timeout = (sd_timeout_cnt == `SPI_TIMEOUT_CNT);

reg  [2:0]  spi_process = 0;
reg  [3:0]  spi_cycle   = 0;
reg  [7:0]  spi_data_w  = 0;

// INIT SPI MODE
reg  [7:0]  spi_counter   = 0;
reg  [7:0]  spi_slow_tick = 0;
reg  [24:0] sd_timeout_cnt = `SPI_TIMEOUT_CNT;

always @(posedge clock50) begin

    // Счетчик таймаута. Дойдя для
    if (sd_timeout_cnt < `SPI_TIMEOUT_CNT && spi_process == 0)
        sd_timeout_cnt <= sd_timeout_cnt + 1;

    case (spi_process)

        // Инициировать процессинг
        0: if (spi_latch == 2'b01) begin

            spi_process <= 1 + sd_cmd;
            spi_counter <= 0;
            spi_cycle   <= 0;
            spi_data_w  <= sd_out;
            sd_busy     <= 1;
            sd_timeout_cnt <= 0;

        end

        // Command-1: 80 тактов в slow-режиме
        1: begin

            SPI_CS   <= 1;
            SPI_MOSI <= 1;

            // 250*100`000
            if (spi_slow_tick == (250 - 1)) begin

                SPI_SCLK      <= ~SPI_SCLK;
                spi_slow_tick <= 0;
                spi_counter   <= spi_counter + 1;

                // 80 ticks
                if (spi_counter == (2*80 - 1)) begin

                    SPI_SCLK    <= 0;
                    spi_process <= 0;
                    sd_busy     <= 0;

                end

            end
            // Оттикивание таймера
            else begin spi_slow_tick <= spi_slow_tick + 1;  end

        end

        // Command 1: Read/Write SPI
        2: case (spi_cycle)

            // CLK-DN
            0: begin spi_cycle <= 1; SPI_SCLK <= 0; SPI_MOSI <= 0; end
            1: begin spi_cycle <= 2; SPI_MOSI <= spi_data_w[7]; end
            // CLK-UP
            2: begin spi_cycle <= 3; SPI_SCLK <= 1; spi_counter <= spi_counter + 1; end
            3: begin

                spi_cycle  <= 0;
                sd_din     <= {sd_din[6:0], SPI_MISO};
                spi_data_w <= {spi_data_w[6:0], 1'b0};

                if (spi_counter == 8) begin

                    SPI_SCLK    <= 0;
                    sd_busy     <= 0;
                    spi_counter <= 0;
                    spi_process <= 0;
                    SPI_MOSI    <= 0;

                end
            end

        endcase

        // Переключиться за 2 такта, чтобы среагировал CPU
        3: case (spi_cycle)

            0: spi_cycle <= 1;
            1: spi_cycle <= 2;
            2: begin SPI_CS <= 1'b0; spi_process <= 0; sd_busy <= 0; end

        endcase

        4: case (spi_cycle)

            0: spi_cycle <= 1;
            1: spi_cycle <= 2;
            2: begin SPI_CS <= 1'b1; spi_process <= 0; sd_busy <= 0; end

        endcase

    endcase

    // Активизация работы устройства
    spi_latch <= {spi_latch[0], sd_signal};

end

endmodule
