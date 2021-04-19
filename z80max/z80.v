module z80
(
    input  wire         CLOCK,  // 100 Mhz
    input  wire         HOLD,   // =1 Процессор работает
    output wire [15:0]  A,      // Адрес в памяти
    input  wire [7:0]   DI,     // Данные на вход
    output reg  [7:0]   DO,     // Данные на выход
    output reg          W       // Разрешение записи
);

assign A = bus ? cc : pc;

// Считывание опкода
wire M0 = (t_state == 0 && latency == 0);

`include "decl.v"

// Обработка инструкции
always @(posedge CLOCK) begin

    // Для обеспечения конвейера
    pc <= pc + 1;

    // Сохранение входящих данных в конвейере
    d0 <= DI;

    // Сброс записи на любом такте
    W   <= 1'b0;
    bus <= 1'b0;

    // Ожидание получения валидных данных на шине
    if (latency) begin latency <= latency - 1; end
    // Декодирование инструкции
    else if (t_state == 0) begin

        t_state <= 1;
        opcode  <= d0;
        r[6:0]  <= r[6:0] + 1'b1;

        casex (d0)

            // 1T | NOP:
            8'b00000000: t_state <= 0;

            // 3T | LD r16, i16
            8'b00xx0001: begin

                if (d0[5:4] == 2'b11)
                     sp[7:0] <= DI;
                else r8[ {d0[5:4],1'b1} ] <= DI; // Регистры 0=C, 1=E, 2=L

            end

            // 4T | LD (HL), *
            8'b00xxx110: begin

                t_state <= 0;
                bus     <= 1'b1;
                cc      <= {h, l};
                W       <= 1'b1;
                DO      <= DI;
                latency <= 3;
                pc      <= pc - 2;

            end

            // 1T | LD r8, i8: Загрузка данных в регистр
            8'b00xxx110: begin

                r8[d0[5:3]]  <= DI; // Загрузка данных в регистр
                t_state      <= 0;  // Не требуется второй фазы
                latency      <= 1;  // Пропуск следующего байта

            end

            // 3T | HALT: Остановка работы процессора
            8'b01110110: begin t_state <= 0; latency <= 2; pc <= pc-2; end

            // LD r8, (HL)
            8'b01xxx110: begin bus <= 1'b1; cc <= {h, l}; pc <= pc-2; end

            // 4T | LD (HL), r8: Загрузка регистра в (HL)
            8'b01110xxx: begin

                t_state <= 0;
                bus     <= 1'b1;
                cc      <= {h, l};
                W       <= 1'b1;
                DO      <= r8[ d0[5:3] ];
                latency <= 3;
                pc      <= pc - 2;

            end

            // Команды перемещения данных
            8'b01xxxxxx: begin r8[ d0[5:3] ] <= r8[ d0[2:0] ]; t_state <= 0; end

        endcase

    end
    // Разбор остальных тактов для опкода
    else casex (opcode)

        // 3T | LD r16, i16
        8'b00xx0001: begin

            if (opcode[5:4] == 2'b11)
                 sp[15:8] <= DI;
            else r8[ {opcode[5:4],1'b0} ] <= DI;

            t_state <= 0;
            latency <= 1;

        end

        // 4T | LD r8, (HL)
        8'b01xxx110: case (t_state)

            1: begin t_state <= 2; /* чтение данных из памяти */ end
            2: begin t_state <= 0; r8[ opcode[5:3] ] <= DI; bus <= 0; latency <= 1; end

        endcase


    endcase

end

endmodule
