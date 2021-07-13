// =====================================================================
// Арифметико-логическое устройство
// =====================================================================

// Выбор источника операнда 1
wire [ 7:0] op1 =

    // 0: Аккумулятор
    is_op1 == 0 ? af[7:0] :
    0;

// Выбор источника операнда 2
wire [ 7:0] op2 =

    is_op2 == 0 ? i_data :
    // 1: Регистр
    is_op2 == 1 ? (
        is_reg_src == 0 ? bc[15:8] :
        is_reg_src == 1 ? bc[ 7:0] :
        is_reg_src == 2 ? de[15:8] :
        is_reg_src == 3 ? de[ 7:0] :
        is_reg_src == 4 ? hl[15:8] :
        is_reg_src == 5 ? hl[ 7:0] :
        is_reg_src == 6 ? i_data : af[ 7:0]
    ) : 0;

// 16-битные операнды
wire [15:0] op1w = 0;
wire [15:0] op1c = 0;
wire [15:0] op2w = 0;

// Результаты
reg  [7:0]  alu_r;
reg  [7:0]  alu_f;
reg  [15:0] alu_r16;

wire [15:0] op2c = op2w + af[CF];
assign ldi_xy = af[7:0] + op1;

// ---------------------------------------------------------------------

wire flag_sign =   alu_r[7];     // Знак
wire flag_zero = ~|alu_r[7:0];   // Нуль
wire flag_prty = ~^alu_r[7:0];   // Четность
reg  bit_z;

always @(*) begin

case (is_alu_m)

    /* op1 + op2 => r */
    ALU_ADD: begin

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
    ALU_ADC: begin

        alu_r = op1 + op2 + af[ CF ];
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
    ALU_SUB: begin

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
    ALU_CP: begin

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
    ALU_SBC: begin

        alu_r = op1 - op2 - af[CF];
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
    ALU_AND: begin

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
    ALU_XOR: begin

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
    ALU_OR: begin

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
    ALU_RLC: begin

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
    ALU_RRC: begin

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
    ALU_RL: begin

        alu_r = {op1[6:0], af[CF]};
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
    ALU_RR: begin

        alu_r = {af[CF], op1[7:1]};
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
    ALU_DAA: begin

        if (af[NF])
            alu_r = op1
                    - ((af[AF]   | (op1[3:0] >  4'h9)) ? 8'h06 : 0)
                    - ((af[CF] | (op1[7:0] > 8'h99)) ? 8'h60 : 0);
        else
            alu_r = op1
                    + ((af[AF]   | (op1[3:0] >  4'h9)) ? 8'h06 : 0)
                    + ((af[CF] | (op1[7:0] > 8'h99)) ? 8'h60 : 0);

        alu_f = {

            /* S */ flag_sign,
            /* Z */ flag_zero,
            /* 0 */ alu_r[5],
            /* A */ op1[4] ^ alu_r[4],
            /* 0 */ alu_r[3],
            /* P */ flag_prty,
            /* N */ af[NF],
            /* C */ af[CF] | (op1 > 8'h99)
        };

    end

    /* a ^ $FF */
    ALU_CPL: begin

        alu_r = ~op1;
        alu_f = {

            /* S */ af[SF],
            /* Z */ af[ZF],
            /* 0 */ alu_r[5],
            /* A */ 1'b1,
            /* 0 */ alu_r[3],
            /* P */ af[PF],
            /* N */ 1'b1,
            /* C */ af[CF]
        };

    end

    /* CF=1 */
    ALU_SCF: begin

        alu_r = op1;
        alu_f = {

            /* S */ af[SF],
            /* Z */ af[ZF],
            /* 0 */ alu_r[5],
            /* H */ 1'b0,
            /* 0 */ alu_r[3],
            /* P */ af[PF],
            /* N */ 1'b0,
            /* C */ 1'b1
        };

    end

    /* CF^1 */
    ALU_CCF: begin

        alu_r = op1;
        alu_f = {

            /* S */ af[SF],
            /* Z */ af[ZF],
            /* 0 */ alu_r[5],
            /* H */ af[CF],
            /* 0 */ alu_r[3],
            /* P */ af[PF],
            /* N */ 1'b0,
            /* C */ af[CF] ^ 1'b1
        };

    end

    /* Логический влево */
    ALU_SLA: begin

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
    ALU_SLL: begin

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
    ALU_SRA: begin

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
    ALU_SRL: begin

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
    ALU_BIT: begin

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

    /* Проверить бит op1 */
    ALU_RES,
    ALU_SET: begin

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

        alu_f = af;

    end

    // Инкремент
    ALU_INC: begin

        alu_r = op2 + 1;
        alu_f = {

            /* S */ flag_sign,
            /* Z */ flag_zero,
            /* 0 */ alu_r[5],
            /* H */ op1[3:0] == 4'hF,
            /* 0 */ alu_r[3],
            /* P */ op1[7:0] == 8'h7F,
            /* N */ 1'b0,
            /* C */ af[CF]
        };

    end

    // Инкремент
    ALU_DEC: begin

        alu_r = op2 - 1;
        alu_f = {

            /* S */ flag_sign,
            /* Z */ flag_zero,
            /* 0 */ alu_r[5],
            /* H */ op1[3:0] == 4'h0,
            /* 0 */ alu_r[3],
            /* P */ op1[7:0] == 8'h80,
            /* N */ 1'b1,
            /* C */ af[CF]
        };

    end

    /* (16 bit) op1 + op2 + C => r */
    ALU_ADCW: begin

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
    ALU_SBCW: begin

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
    ALU_RRLD: begin

        alu_r = op1;
        alu_f = {

            /* S */ op1[7],
            /* Z */ op1[7:0] == 0,
            /* - */ op1[5],
            /* H */ 1'b0,
            /* - */ op1[3],
            /* V */ flag_prty,
            /* N */ 1'b0,
            /* C */ af[CF]
        };

    end

endcase

end
