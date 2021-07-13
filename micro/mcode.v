// Микрокод
reg  [ 4:0] is_alu_m;
reg         is_inc16;
reg         is_dec16;
reg         is_bus;
reg         is_we;
reg         is_pcinc;
reg         is_instr_end;
reg         is_reg8_w;
reg         is_flag_w;
reg  [1:0]  is_op1;
reg  [1:0]  is_op2;
reg  [2:0]  is_source;
reg  [3:0]  is_reg_dst;
reg  [3:0]  is_reg_src;

always @(*) begin

    is_op1      = 0;                  // =0 Acc
    is_op2      = 0;                  // =1 Регистр
    is_alu_m    = 0;                  // Режим работы АЛУ
    is_flag_w   = 0;                  // =1 Запись из АЛУ
    is_source   = 0;                  // =0 i_data; 1 alu
    is_inc16    = 0;                  // =1 Выполняется увеличение или уменьшение
    is_dec16    = 0;                  // =1 Выполняется уменьшение, если задан is_inc16=1
    is_we       = 0;                  // Записывать ли данные в память?
    is_bus      = 0;                  // Переключить шину?
    is_pcinc    = is_tstate0;         // На первом такте всегда увеличивать PC
    is_reg_src  = opcode[5:3];        // Номер регистра для записи (8 битный)
    is_reg_dst  = opcode[5:3];        // Номер регистра для чтения
    is_reg8_w   = 0;                  // Записывать ли что-то в регистр 8 бит
    is_alu_m    = opcode[5:3];
    is_instr_end = 0;                 // =1 Закончить выполнение инструкции

    casex (opcode)

        // LD sp, i16: Запись в SP осуществляется отдельно
        8'b00_110_001: case (t_state)

            1: begin is_pcinc = 1; is_reg8_w = 1; is_reg_dst = 9; end
            2: begin is_pcinc = 1; is_reg8_w = 1; is_reg_dst = 8; is_instr_end = 1; end

        endcase

        // LD r16, i16
        8'b00_xx0_001: case (t_state)

            1: begin is_pcinc = 1; is_reg8_w = 1; is_reg_dst = {opcode[5:4], 1'b1}; end
            2: begin is_pcinc = 1; is_reg8_w = 1; is_reg_dst = {opcode[5:4], 1'b0}; is_instr_end = 1; end

        endcase

        // LD (HL), i*
        8'b00_110_110: case (t_state)

            1: begin is_bus = 1; is_we = 1; is_pcinc = 1; end
            2: begin is_instr_end = 1; end

        endcase

        // LD r8, i*
        8'b00_xxx_110: case (t_state)

            1: begin

                is_reg8_w       = 1;
                is_instr_end    = 1;
                is_pcinc        = 1;

            end

        endcase

        // INC|DEC r16
        8'b00_xxx_011: case (t_state)

            0: begin

                is_inc16        = 1;
                is_dec16        = opcode[3];
                is_reg_dst      = opcode[5:4];
                is_instr_end    = 1;

            end

        endcase

        // INC|DEC (HL)
        8'b00_110_10x: case (t_state)

            0: begin is_bus = 1; end
            1: begin

                is_bus       = 1;
                is_flag_w    = 1;
                is_source    = 1;
                is_alu_m     = opcode[0] ? ALU_DEC : ALU_INC;
                is_we        = opcode[5:3] != 7;

            end
            2: begin is_instr_end = 1; end

        endcase

        // INC|DEC r8
        8'b00_xxx_10x: case (t_state)

            0: begin

                is_source    = 1;
                is_flag_w    = 1;
                is_op2       = 1;
                is_reg8_w    = 1;
                is_alu_m     = opcode[0] ? ALU_DEC : ALU_INC;
                is_instr_end = 1;

            end

        endcase

        // Остановить процессор на неизвестной инструкции
        default: begin is_pcinc = 0; is_instr_end = 1; end

    endcase

end
