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
always @(posedge CLOCK)
if (HOLD) begin

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

            // ============ CODEBANK 0 =================================

            // 1T | EX AF,AF'
            8'b00001000: begin r8[`REG_A] <= prime[63:56]; prime[63:56] <= r8[`REG_A]; end

            // 2T/3T | DJNZ *
            8'b00010000: begin

                latency <= 1;
                if (r8[`REG_B] != 1) begin latency <= 2; pc <= pc + {{8{DI[7]}}, DI[7:0]}; end
                r8[`REG_B] <= r8[`REG_B] - 1;

            end

            // 3T | JR *
            8'b00011000: begin latency <= 2; pc <= pc + {{8{DI[7]}}, DI[7:0]}; end

            // 2T/3T | JR cc, *
            8'b001xx000: begin

                // Условие подошло
                if (condition[d0[4]] == d0[3]) begin

                    latency <= 2;
                    pc <= pc + {{8{DI[7]}}, DI[7:0]};

                end else begin

                    latency <= 1;
                end

            end

            // 3T | LD r16, **
            8'b00xx0001: begin

                t_state <= 1;
                if (d0[5:4] == 2'b11) sp[7:0] <= DI;
                else r8[ {d0[5:4],1'b1} ] <= DI; // Регистры 0=C, 1=E, 2=L

            end

            // 4T | ADD HL, r16
            8'b00xx1001: begin

                t_state <= 1;
                alu     <= `ALU_ADDW;
                op1w    <= {h,l};
                op2w    <= d0[5:4] == 2'b11 ? sp : {r8[ {d0[5:4],1'b0} ], r8[ {d0[5:4],1'b1} ]};

            end

            // 4T | LD (BC|DE), A
            8'b000x0010: begin

                bus     <= 1'b1;
                cc      <= d0[4] ? {d,e} : {b,c};
                W       <= 1'b1;
                DO      <= r8[7];
                latency <= 3;
                pc      <= pc-2;

            end

            // 5T/6T | LD (**) <--> A|HL
            8'b001xx010: begin t_state <= 1; cc[7:0] <= DI; end

            // 5T | LD A,(BC|DE)
            8'b000x1010: begin t_state <= 1; bus <= 1'b1; cc  <= d0[4] ? {d,e} : {b,c}; end

            // 1T | INC/DEC r16
            8'b00000011: begin {r8[`REG_B], r8[`REG_C]} <= {b,c} + 1'b1; end
            8'b00001011: begin {r8[`REG_B], r8[`REG_C]} <= {b,c} - 1'b1; end
            8'b00010011: begin {r8[`REG_D], r8[`REG_E]} <= {d,e} + 1'b1; end
            8'b00011011: begin {r8[`REG_D], r8[`REG_E]} <= {d,e} - 1'b1; end
            8'b00100011: begin {r8[`REG_H], r8[`REG_L]} <= {h,l} + 1'b1; end
            8'b00101011: begin {r8[`REG_H], r8[`REG_L]} <= {h,l} - 1'b1; end
            8'b00110011: begin sp <= sp + 1'b1; end
            8'b00111011: begin sp <= sp - 1'b1; end

            // 7T | INC/DEC (HL)
            8'b0011010x: begin

                t_state <= 1;
                bus     <= 1;
                cc      <= {h, l};
                alu     <= d0[0] ? `ALU_SUB : `ALU_ADD;
                op2     <= 1;

            end

            // 3T | INC/DEC r8
            8'b00xxx10x: begin

                op1 <= r8[ d0[5:3] ];
                op2 <= 1;
                alu <= d0[0] ? `ALU_SUB : `ALU_ADD;
                t_state <= 1;
                pc  <= pc-1;

            end

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
            8'b00xxx110: begin latency <= 1; r8[ d0[5:3] ]<= DI; end

            // 3T | <shift> A
            8'b00xxx111: begin t_state <= 1; alu <= {1'b1, d0[5:3]}; op1 <= a; pc <= pc-2; end

            // ============ CODEBANK 1/2 =================================

            // 3T | HALT
            8'b01110110: begin latency <= 2; pc <= pc-2; end

            // 4T | LD r8, (HL)
            8'b01xxx110: begin t_state <= 1; bus <= 1'b1; cc <= {h, l}; pc <= pc-2; end

            // 4T | LD (HL), r8
            8'b01110xxx: begin

                bus     <= 1'b1;
                W       <= 1'b1;
                cc      <= {h, l};
                DO      <= r8[ d0[2:0] ];
                latency <= 3;
                pc      <= pc-2;

            end

            // 1T | LD r8, r8
            8'b01xxxxxx: begin r8[ d0[5:3] ] <= r8[ d0[2:0] ]; end

            // 6T | <alu> (HL); 4T <alu> r8
            8'b10xxx110: begin t_state <= 1; alu <= d0[5:3]; op1 <= a; bus <= 1; cc <= {h, l}; end
            8'b10xxxxxx: begin t_state <= 1; alu <= d0[5:3]; op1 <= a; op2 <= r8[d0[2:0]]; end

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

        // 5T | LD (**), A
        8'b00110010: begin

            cc[15:8] <= DI;
            bus <= 1;
            W   <= 1;
            DO  <= a;
            t_state <= 0; latency <= 3; pc <= pc - 3;

        end

        // 6T | LD (**), HL
        8'b00100010: case (t_state)

            1: begin t_state <= 2; cc[15:8] <= DI; bus <= 1; W <= 1; DO <= l; end
            2: begin t_state <= 0; cc <= cc + 1;   bus <= 1; W <= 1; DO <= h; latency <= 3; pc <= pc-2; end

        endcase

        // LD A|HL, (**)
        8'b001x1010: case (t_state)

            1: begin t_state <= 2; bus <= 1; cc[15:8] <= DI; end
            2: begin t_state <= 3; bus <= 1; cc <= cc + 1; end
            3: begin

                if (opcode[4]) begin r8[`REG_A] <= DI; t_state <= 0; latency <= 2; pc <= pc-2; end
                else begin r8[`REG_L] <= DI; t_state <= 4; bus <= 1; end

            end
            4: begin r8[`REG_H] <= DI; t_state <= 0; latency <= 2; pc <= pc - 3; end

        endcase

        // 4T | LD r8, (HL)
        8'b01xxx110: case (t_state)

            1: begin t_state <= 2; /* чтение данных из памяти */ end
            2: begin t_state <= 0; r8[ opcode[5:3] ] <= DI; bus <= 0; latency <= 1; end

        endcase

        // 6T | <ALU> A, (HL)
        8'b10xxx110: case (t_state)

            1: begin t_state <= 2; end
            2: begin t_state <= 3; op2 <= DI; bus <= 0; end
            3: begin

                t_state <= 0;
                latency <= 2;
                pc <= pc - 4;

                r8[6] <= alu_f;
                if (alu != 3'b111) r8[7] <= alu_r; // Все кроме CP

            end

        endcase

        // 4T | <ALU> A, r8
        8'b10xxxxxx: case (t_state)

            1: begin

                t_state <= 0;
                latency <= 2;
                pc <= pc - 2;

                r8[6] <= alu_f;
                if (alu != 3'b111) r8[7] <= alu_r; // Все кроме CP

            end

        endcase

        // 4T | ADD HL, r16
        8'b00xx1001: begin

            {r8[`REG_H], r8[`REG_L]} <= alu_r16[15:0];
            r8[`REG_F] <= alu_f;
            t_state <= 0; latency <= 2; pc <= pc - 2;

        end

        // 3T | <shift> A
        8'b00xxx111: begin

            r8[`REG_A] <= alu_r;
            r8[`REG_F] <= alu_f;
            latency <= 1; t_state <= 0;

        end

        // 5T | LD A,(BC|DE)
        8'b000x1010: case (t_state)

            1: t_state <= 2;
            2: begin r8[`REG_A] <= DI; bus <= 0; t_state <= 0; latency <= 2; pc <= pc-3; end

        endcase

        // 7T | INC/DEC (HL)
        8'b0011010x: case (t_state)

            1: begin t_state <= 2; pc <= pc - 5; end
            2: begin t_state <= 3; op1 <= DI; end
            3: begin t_state <= 0; bus <= 1; W <= 1; DO <= alu_r; r8[6] <= alu_f; latency <= 3; end

        endcase

        // 3T | INC/DEC r8
        8'b00xxx10x: begin r8[ opcode[5:3] ] <= alu_r; r8[6] <= alu_f; latency <= 1; t_state <= 0; end

    endcase

end
else begin

    latency <= 2;
    sp <= 16'hdffe;

end

endmodule

`include "alu.v"
