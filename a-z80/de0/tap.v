module tap
(
    input   wire        clock,      // 3.5 Mhz
    input   wire        play,       // Сигнал запуска ленты =1
    output  reg         mic,
    output  reg [15:0]  tap_address,
    input   wire [7:0]  tap_data
);

reg [ 3:0] state  = 0;
reg [11:0] cnt    = 0; // 2^12=4096
reg [15:0] length = 0;
reg [12:0] pilot  = 0; // 8064 | 3224
reg [10:0] ldata  = 0;
reg [ 3:0] bitn   = 0;

initial tap_address = 0;

always @(posedge clock) begin

    case (state)

        // Ожидание "включения магнитофона"
        0: begin state <= play ? 1 : 0; cnt <= 0; mic <= 1; bitn <= 7; end
        // Считывание длины блока.
        1: begin state <= 2; length[7:0]  <= tap_data; tap_address <= tap_address + 1; end
        2: begin state <= 3; length[15:8] <= tap_data; tap_address <= tap_address + 1; end
        // Запись длины блока
        3: begin state <= length ? 4 : 15; pilot <= tap_data[7] ? 3224 : 8064; end
        // Запись пилотного сигнала
        // for (i = 0; i < pilot; i++) for (j = 0; j < cnt; j++) mic ^= 1;
        4: begin

            cnt <= cnt + 1;

            // Если достиг своего периода
            if (cnt == 2167)
            begin

                cnt   <= 0;
                mic   <= ~mic;
                pilot <= pilot - 1;

                if (pilot == 1) begin state <= 5; cnt <= 667; end

            end

        end
        // Запись синхросигнала (высокий уровень)
        5: begin mic <= 1; state <= (cnt ==   1) ? 6 : 5; cnt <= cnt - 1; end
        6: begin mic <= 0; state <= (cnt == 733) ? 7 : 6; cnt <= cnt + 1; end
        // Считывание бита
        7: begin

            mic   <= 1;
            state <= 8;

            // Вычисление длительности
            pilot <= tap_data[ bitn ] ? 1710 : 855;
            ldata <= tap_data[ bitn ] ? 1710 : 855;

            // Если это младший бит, то следующий будет старший
            if (bitn == 0) begin

                bitn        <= 7;
                length      <= length - 1;
                tap_address <= tap_address + 1;

                // Это последний байт в потоке
                if (length == 1) state <= 0;

            end

            bitn <= bitn - 1;

        end
        // Подача сигнала 1710 или 855
        8: begin mic <= 1; state <= pilot == 2 ? 9 : 8; pilot <= pilot - 1; end
        9: begin mic <= 0; state <= ldata == 1 ? 7 : 9; ldata <= ldata - 1; end

        // STOP
        15: begin state <= 15; end

    endcase

end

endmodule
