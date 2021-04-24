module tap
(
    input   wire        reset_n,
    input   wire        clock,      // 3.5 Mhz
    input   wire        play,       // Сигнал запуска ленты =1
    output  reg         mic,
    output  reg [15:0]  tap_address,
    input   wire [7:0]  tap_data,

    output  wire [3:0] __debug
);

assign __debug  = state;




`ifdef ICARUS
parameter
    PILOT_PERIOD = 4,
    PILOT_HEADER = 6,
    PILOT_DATA   = 3,
    SYNC_HI      = 4,
    SYNC_LO      = 3,
    SIGNAL_0     = 2,
    SIGNAL_1     = 4;
`else
parameter
    PILOT_PERIOD = 2168,
    PILOT_HEADER = 8064,
    PILOT_DATA   = 3224,
    SYNC_HI      = 667,
    SYNC_LO      = 735,
    SIGNAL_0     = 855,
    SIGNAL_1     = 1710;
`endif

reg [ 3:0] state  = 0;
reg [11:0] cnt    = 0; // 2^12=4096
reg [15:0] length = 0;
reg [12:0] pilot  = 0; // 8064 | 3224
reg [10:0] hdata  = 0;
reg [10:0] ldata  = 0;
reg [ 2:0] bitn   = 0;

initial tap_address = 0;

always @(posedge clock) begin

    if (!reset_n)
    begin

        state <= 0;
        mic   <= 1;
        tap_address <= 0;

    end
    else case (state)

        // Ожидание "включения магнитофона"
        0: begin state <= play ? 1 : 0; cnt <= 0; mic <= 1; bitn <= 7; end
        // Считывание длины блока
        1: begin state <= 2; length[ 7:0] <= tap_data; tap_address <= tap_address + 1; end
        2: begin state <= 3; length[15:8] <= tap_data; tap_address <= tap_address + 1; end
        // Запись длины блока
        3: begin state <= length ? 4 : 15; pilot <= tap_data[7] ? PILOT_DATA : PILOT_HEADER; end
        // Запись пилотного сигнала
        // for (i = 0; i < pilot; i++) for (j = 0; j < cnt; j++) mic ^= 1;
        4: begin

            cnt <= cnt + 1;

            // Если достиг своего периода
            if (cnt == PILOT_PERIOD-1)
            begin

                cnt   <= 0;
                mic   <= ~mic;
                pilot <= pilot - 1;

                if (pilot == 1) begin state <= 5; cnt <= SYNC_HI; end

            end

        end
        // Запись синхросигнала TTTT\___
        5: begin mic <= 1; cnt <= cnt - 1; state <= (cnt == 2) ? 6 : 5; end
        6: begin mic <= 0; cnt <= cnt + 1; state <= (cnt == SYNC_LO) ? 7 : 6; end
        // Считывание бита
        7: begin

            mic   <= 1;
            bitn  <= bitn - 1;
            state <= 8;

            // Вычисление длительности
            hdata <= tap_data[ bitn ] ? SIGNAL_1 : SIGNAL_0;
            ldata <= tap_data[ bitn ] ? SIGNAL_1 : SIGNAL_0;

            // Это последний байт в потоке
            if (bitn == 7 && length == 0)
                state <= 0;

            // Если это младший бит, то следующий будет старший
            if (bitn == 0) begin

                length      <= length - 1;
                tap_address <= tap_address + 1;

            end

        end
        // Подача сигнала 1710 или 855
        8: begin mic <= 1; state <= hdata == 2 ? 9 : 8; hdata <= hdata - 1; end
        9: begin mic <= 0; state <= ldata == 1 ? 7 : 9; ldata <= ldata - 1; end

        // STOP
        15: begin state <= 15; end

    endcase

end

endmodule
