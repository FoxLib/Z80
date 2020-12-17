
module alu(

    input wire  [ 4:0] alu_m,       // Команда АЛУ
    input wire  [ 7:0] a,           // Входящий A
    input wire  [ 7:0] f,           // Входящие флаги
    input wire  [ 7:0] op1,         // Первый операнд для АЛУ
    input wire  [ 7:0] op2,         // Второй операнд для АЛУ
    input wire  [15:0] op1w,        // Операнд-1 16 бит
    input wire  [15:0] op2w,        // Операнд-2 16 бит
    output reg  [ 8:0] alu_r,       // Результат
    output reg  [ 7:0] alu_f,       // Флаги результата
    output reg  [16:0] alu_r16,     // Результат 16 бит
    output wire [ 5:0] ldi_xy
);

wire flag_sign =   alu_r[7];     // Знак
wire flag_zero = ~|alu_r[7:0];   // Нуль
wire flag_prty = ~^alu_r[7:0];   // Четность

wire [15:0] op2c = op2w + f[`CARRY];
reg  bit_z;

// Особые флаги
assign ldi_xy = a + op1;

always @* begin

    /* 8 bit */
    case (alu_m)

        /* op1 + op2 => r */
        `ALU_ADD: begin

            alu_r = op1 + op2;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ op1[4] ^ op2[4] ^ alu_r[4],
                /* 0 */ alu_r[3],
                /* V */ (op1[7] ^ op2[7] ^ 1'b1) & (op1[7] ^ alu_r[7]),
                /* N */ 1'b0,
                /* C */ alu_r[8]

            };

        end

        /* op1 + op2 + carry => r */
        `ALU_ADC: begin

            alu_r = op1 + op2 + f[ `CARRY ];
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ op1[4] ^ op2[4] ^ alu_r[4],
                /* 0 */ alu_r[3],
                /* V */ (op1[7] ^ op2[7] ^ 1'b1) & (op1[7] ^ alu_r[7]),
                /* N */ 1'b0,
                /* C */ alu_r[8]

            };

        end

        /* op1 - op2 => r */
        `ALU_SUB: begin

            alu_r = op1 - op2;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ op1[4] ^ op2[4] ^ alu_r[4],
                /* 0 */ alu_r[3],
                /* V */ (op1[7] ^ op2[7]) & (op1[7] ^ alu_r[7]),
                /* N */ 1'b1,
                /* C */ alu_r[8]

            };

        end

        /* op1 - op2 => r: Отличие от SUB в том что X/Y ставится от op2 */
        `ALU_CP: begin

            alu_r = op1 - op2;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ op2[5],
                /* H */ op1[4] ^ op2[4] ^ alu_r[4],
                /* 0 */ op2[3],
                /* V */ (op1[7] ^ op2[7]) & (op1[7] ^ alu_r[7]),
                /* N */ 1'b1,
                /* C */ alu_r[8]

            };

        end

        /* op1 - op2 - carry => r */
        `ALU_SBC: begin

            alu_r = op1 - op2 - f[`CARRY];
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ op1[4] ^ op2[4] ^ alu_r[4],
                /* 0 */ alu_r[3],
                /* V */ (op1[7] ^ op2[7]) & (op1[7] ^ alu_r[7]),
                /* N */ 1'b1,
                /* C */ alu_r[8]

            };

        end

        /* op1 & op2 => r */
        `ALU_AND: begin

            alu_r = op1 & op2;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b1,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ 1'b0

            };

        end

        /* op1 ^ op2 => r */
        `ALU_XOR: begin

            alu_r = op1 ^ op2;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ 1'b0

            };

        end

        /* op1 | op2 */
        `ALU_OR: begin

            alu_r = op1 | op2;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ 1'b0

            };

        end

        /* Циклический влево */
        `ALU_RLC: begin

            alu_r = {op1[6:0], op1[7]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ op1[7]

            };

        end

        /* Циклический вправо */
        `ALU_RRC: begin

            alu_r = {op1[0], op1[7:1]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ op1[0]

            };

        end

        /* Влево с заемом из C */
        `ALU_RL: begin

            alu_r = {op1[6:0], f[`CARRY]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ op1[7]

            };

        end

        /* Вправо с заемом из C */
        `ALU_RR: begin

            alu_r = {f[`CARRY], op1[7:1]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ op1[0]

            };

        end

        /* Десятично-двоичная корректировка */
        `ALU_DAA: begin

            if (f[`NEG])
                alu_r = op1
                        - ((f[`AUX]   | (op1[3:0] >  4'h9)) ? 8'h06 : 0)
                        - ((f[`CARRY] | (op1[7:0] > 8'h99)) ? 8'h60 : 0);
            else
                alu_r = op1
                        + ((f[`AUX]   | (op1[3:0] >  4'h9)) ? 8'h06 : 0)
                        + ((f[`CARRY] | (op1[7:0] > 8'h99)) ? 8'h60 : 0);

            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* A */ op1[4] ^ alu_r[4],
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ f[`NEG],
                /* C */ f[`CARRY] | (op1 > 8'h99)

            };

        end

        /* a ^ $FF */
        `ALU_CPL: begin

            alu_r = ~op1;
            alu_f = {

                /* S */ f[`SIGN],
                /* Z */ f[`ZERO],
                /* 0 */ alu_r[5],
                /* A */ 1'b1,
                /* 0 */ alu_r[3],
                /* P */ f[`PARITY],
                /* N */ 1'b1,
                /* C */ f[`CARRY]

            };

        end

        /* CF=1 */
        `ALU_SCF: begin

            alu_r = op1;
            alu_f = {

                /* S */ f[`SIGN],
                /* Z */ f[`ZERO],
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ f[`PARITY],
                /* N */ 1'b0,
                /* C */ 1'b1

            };

        end

        /* CF^1 */
        `ALU_CCF: begin

            alu_r = op1;
            alu_f = {

                /* S */ f[`SIGN],
                /* Z */ f[`ZERO],
                /* 0 */ alu_r[5],
                /* H */ f[`CARRY],
                /* 0 */ alu_r[3],
                /* P */ f[`PARITY],
                /* N */ 1'b0,
                /* C */ f[`CARRY] ^ 1'b1

            };

        end

        /* Логический влево */
        `ALU_SLA: begin

            alu_r = {op1[6:0], 1'b0};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ op1[7]

            };

        end
        
        // Особый случай сдвига
        `ALU_SLL: begin

            alu_r = {op1[6:0], 1'b1};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ op1[7]

            };

        end

        /* Арифметический вправо */
        `ALU_SRA: begin

            alu_r = {op1[7], op1[7:1]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ op1[0]

            };

        end

        /* Логический вправо */
        `ALU_SRL: begin

            alu_r = {1'b0, op1[7:1]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ 1'b0,
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ op1[0]

            };

        end

        /* Проверить бит */
        `ALU_BIT: begin

            alu_r = op1;
            bit_z = !op1[ op2[2:0] ]; // Вычисленный бит
            alu_f = {

                /* S */ op2[2:0] == 3'h7 && bit_z == 0,
                /* Z */ bit_z, // Если бит = 0, ставим Z=1
                /* 0 */ op2[2:0] == 3'h5 && bit_z == 0,
                /* H */ 1'b1,
                /* 0 */ op2[2:0] == 3'h3 && bit_z == 0,
                /* P */ bit_z,
                /* N */ 1'b0,
                /* C */ op1[0]

            };

        end

        /* Проверить бит */
        `ALU_RES,
        `ALU_SET: begin

            case (op2[2:0])

                3'b000: alu_r = {op1[7:1], op2[3]};
                3'b001: alu_r = {op1[7:2], op2[3], op1[  0]};
                3'b010: alu_r = {op1[7:3], op2[3], op1[1:0]};
                3'b011: alu_r = {op1[7:4], op2[3], op1[2:0]};
                3'b100: alu_r = {op1[7:5], op2[3], op1[3:0]};
                3'b101: alu_r = {op1[7:6], op2[3], op1[4:0]};
                3'b110: alu_r = {op1[  7], op2[3], op1[5:0]};
                3'b111: alu_r = {          op2[3], op1[6:0]};

            endcase

            alu_f = f;

        end

        // Инкремент
        `ALU_INC: begin

            alu_r = op1 + 1;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ op1[3:0] == 4'hF,
                /* 0 */ alu_r[3],
                /* P */ op1[7:0] == 8'h7F,
                /* N */ 1'b0,
                /* C */ f[`CARRY]

            };

        end

        // Инкремент
        `ALU_DEC: begin

            alu_r = op1 - 1;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ alu_r[5],
                /* H */ op1[3:0] == 4'h0,
                /* 0 */ alu_r[3],
                /* P */ op1[7:0] == 8'h80,
                /* N */ 1'b1,
                /* C */ f[`CARRY]
            };

        end

        /* (16 bit) op1 + op2 => r */
        `ALU_ADDW: begin

            alu_r16 = op1w + op2w;
            alu_f = {

                /* S */ f[`SIGN],
                /* Z */ f[`ZERO],
                /* 0 */ alu_r16[13],
                /* H */ op1w[12] ^ op2w[12] ^ alu_r16[12],
                /* 0 */ alu_r16[11],
                /* V */ f[`PARITY],
                /* N */ 1'b0,
                /* C */ alu_r16[16]

            };

        end

        /* (16 bit) op1 + op2 + C => r */
        `ALU_ADCW: begin

            alu_r16 = op1w + op2c;
            alu_f = {

                /* S */ alu_r16[15],
                /* Z */ alu_r16[15:0] == 0,
                /* - */ alu_r16[13],
                /* H */ op1w[12] ^ op2c[12] ^ alu_r16[12],
                /* - */ alu_r16[11],
                /* V */ (op1w[15] ^ op2c[15] ^ 1'b1) & (alu_r16[15] ^ op1w[15]),
                /* N */ 1'b0,
                /* C */ alu_r16[16]
            };

        end

        /* (16 bit) op1 - op2 - C => r */
        `ALU_SBCW: begin

            alu_r16 = op1w - op2c;
            alu_f = {

                /* S */ alu_r16[15],
                /* Z */ alu_r16[15:0] == 0,
                /* - */ alu_r16[13],
                /* H */ op1w[12] ^ op2c[12] ^ alu_r16[12],
                /* - */ alu_r16[11],
                /* V */ (op1w[15] ^ op2c[15]) & (alu_r16[15] ^ op1w[15]),
                /* N */ 1'b1,
                /* C */ alu_r16[16]
            };

        end

        /* RLD | RRD */
        `ALU_RRLD: begin

            alu_r = op1;
            alu_f = {

                /* S */ op1[7],
                /* Z */ op1[7:0] == 0,
                /* - */ op1[5],
                /* H */ 1'b0,
                /* - */ op1[3],
                /* V */ flag_prty,
                /* N */ 1'b0,
                /* C */ f[`CARRY]
            };

        end

    endcase

end

endmodule
