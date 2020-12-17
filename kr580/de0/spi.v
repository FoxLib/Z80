/*  Модуль SPI

Top Level Schema:

    .spi_miso   (SD_DATA[0]),       // Входящие данные
    .spi_mosi   (SD_CMD),           // Исходящие
    .spi_sclk   (SD_CLK),           // Тактовая частота
    .spi_cs     (SD_DATA[3]),       // Выбор чипа

COMMAND
------------------
00  INIT
01  TRANSMIT
02  CS=0
03  CS=1
------------------
*/

module spi(

    // 50 Mhz
    input  wire         clock50,

    // SPI
    output reg          spi_cs,
    output reg          spi_sclk,
    input  wire         spi_miso,
    output reg          spi_mosi,

    // Интерфейс
    input  wire         spi_sent,    // =1 Сообщение отослано на spi
    input  wire [ 1:0]  spi_cmd,     // Команда
    output reg  [ 7:0]  spi_din,     // Принятое сообщение
    input  wire [ 7:0]  spi_out,     // Сообщение на отправку
    output wire [ 1:0]  spi_st       // bit 1: timeout (1); bit 0: busy
);

`define SPI_TIMEOUT_CNT     5000000     // 0.1 s

initial begin

    spi_cs   = 1'b1;
    spi_sclk = 1'b0;
    spi_mosi = 1'b0;
    spi_din  = 8'h00;

end

// ---------------------------------------------------------------------
// SPI SdCard
// ---------------------------------------------------------------------

// Сигналы нейтрализации (сброс активации команды)
reg  [1:0]  spi_latch   = 2'b00;

// Сигнал о том, занято ли устройство
assign      spi_st      = {spi_timeout == `SPI_TIMEOUT_CNT, spi_busy};
reg         spi_busy    = 1'b0;

reg  [2:0]  spi_process = 0;
reg  [3:0]  spi_cycle   = 0;
reg  [7:0]  spi_data_w  = 0;

// INIT SPI MODE
reg  [7:0]  spi_counter   = 0;
reg  [7:0]  spi_slow_tick = 0;
reg  [24:0] spi_timeout   = `SPI_TIMEOUT_CNT;

always @(posedge clock50) begin

    // Счетчик таймаута. Дойдя для
    if (spi_timeout < `SPI_TIMEOUT_CNT && spi_process == 0) spi_timeout <= spi_timeout + 1;

    case (spi_process)

        // Инициировать процессинг
        0: if (spi_latch == 2'b01) begin

            spi_process <= 1 + spi_cmd;
            spi_busy    <= 1;
            spi_counter <= 0;
            spi_cycle   <= 0;
            spi_data_w  <= spi_out;
            spi_timeout <= 0;

        end

        // Command-1: 80 тактов в slow-режиме
        1: begin

            spi_cs   <= 1;
            spi_mosi <= 1;

            // 250*100`000
            if (spi_slow_tick == (250 - 1)) begin

                spi_slow_tick <= 0;
                spi_sclk      <= ~spi_sclk;
                spi_counter   <= spi_counter + 1;

                // 80 ticks
                if (spi_counter == (2*80 - 1)) begin

                    spi_process <= 0;
                    spi_sclk    <= 0;
                    spi_busy    <= 0;

                end

            end
            // Оттикивание таймера
            else begin spi_slow_tick <= spi_slow_tick + 1;  end

        end

        // Command 1: Read/Write SPI
        2: case (spi_cycle)

            // CLK-DN
            0: begin spi_cycle <= 1; spi_sclk    <= 0; end
            1: begin spi_cycle <= 2; spi_mosi    <= 0; end
            2: begin spi_cycle <= 3; spi_mosi    <=  spi_data_w[7]; end
            3: begin spi_cycle <= 4; spi_data_w  <= {spi_data_w[6:0], 1'b0}; end
            // CLK-UP
            4: begin spi_cycle <= 5; spi_sclk    <= 1; end
            5: begin spi_cycle <= 6; spi_counter <= spi_counter + 1; end
            6: begin spi_cycle <= 7; end
            7: begin

                spi_cycle <= 0;
                spi_din   <= {spi_din[6:0], spi_miso};

                if (spi_counter == 8) begin

                    spi_sclk    <= 0;
                    spi_busy    <= 0;
                    spi_counter <= 0;
                    spi_process <= 0;
                    spi_mosi    <= 0;

                end
            end

        endcase

        // Переключиться за 2 такта, чтобы среагировал CPU
        3: case (spi_cycle)

            0: spi_cycle <= 1;
            1: spi_cycle <= 2;
            2: begin spi_cs <= 1'b0; spi_process <= 0; spi_busy <= 0; end

        endcase

        4: case (spi_cycle)

            0: spi_cycle <= 1;
            1: spi_cycle <= 2;
            2: begin spi_cs <= 1'b1; spi_process <= 0; spi_busy <= 0; end

        endcase

    endcase

    // Активизация работы устройства
    spi_latch <= {spi_latch[0], spi_sent};

end

endmodule
