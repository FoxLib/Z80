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

        opcode  <= d0;
        r[6:0]  <= r[6:0] + 1'b1;

        casex (d0)

            // 1T | NOP:
            8'b00000000: begin /* nope */ end

            // 1T | EX AF,AF'
            8'b00001000: begin r8[7] <= prime[63:56]; prime[63:56] <= r8[7]; end

            // 4T | LD (BC|DE), A
            8'b000x0010: begin

                bus <= 1'b1;
                cc  <= d0[4] ? {d,e} : {b,c};
                W   <= 1'b1;
                DO  <= r8[7];
                latency <= 3;
                pc      <= pc-2;

            end

            // 3T | LD r16, **
            8'b00xx0001: begin

                t_state <= 1;
                if (d0[5:4] == 2'b11) sp[7:0] <= DI;
                else r8[ {d0[5:4],1'b1} ] <= DI; // Регистры 0=C, 1=E, 2=L

            end

            // 1T | INC/DEC r16
            8'b00000011: begin {r8[0],r8[1]} <= {b,c} + 1'b1; end
            8'b00001011: begin {r8[0],r8[1]} <= {b,c} - 1'b1; end
            8'b00010011: begin {r8[2],r8[3]} <= {d,e} + 1'b1; end
            8'b00011011: begin {r8[2],r8[3]} <= {d,e} - 1'b1; end
            8'b00100011: begin {r8[4],r8[5]} <= {h,l} + 1'b1; end
            8'b00101011: begin {r8[4],r8[5]} <= {h,l} - 1'b1; end
            8'b00110011: begin sp <= sp + 1'b1; end
            8'b00111011: begin sp <= sp - 1'b1; end

            // 4T | LD (HL), *
            8'b00110110: begin

                bus     <= 1'b1;
                cc      <= {h, l};
                W       <= 1'b1;
                DO      <= DI;
                latency <= 3;
                pc      <= pc-2;

            end

            // 1T | LD r8, *
            8'b00xxx110: begin

                latency <= 1;
                r8[ d0[5:3] ]<= DI;

            end

            // 3T | HALT
            8'b01110110: begin latency <= 2; pc <= pc-2; end

            // 4T | LD r8, (HL)
            8'b01xxx110: begin t_state <= 1; bus <= 1'b1; cc <= {h, l}; pc <= pc-2; end

            // 4T | LD (HL), r8
            8'b01110xxx: begin

                bus     <= 1'b1;
                cc      <= {h, l};
                W       <= 1'b1;
                DO      <= r8[ d0[5:3] ];
                latency <= 3;
                pc      <= pc-2;

            end

            // Команды перемещения данных
            8'b01xxxxxx: begin r8[ d0[5:3] ] <= r8[ d0[2:0] ]; end

        endcase

    end
    // Разбор остальных тактов для опкода
    else casex (opcode)

        // 3T | LD r16, **
        8'b00xx0001: begin

            if (opcode[5:4] == 2'b11) sp[15:8] <= DI;
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
