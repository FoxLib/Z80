
`define CMD_NOPE    3'b000
`define CMD_EXDEHL  3'b001
`define CMD_EXAF    3'b010
`define CMD_EXX     3'b011
`define CMD_INC     3'b100 // LDI, CPI...
`define CMD_DEC     3'b101 // LDD, CPD...

module regs(

    input   wire         pin_clk,   // Тактовый сигнал
    input   wire [ 7:0]  opcode,    // Опкод
    input   wire         reg_b,     // Сигнал на запись 8 битного регистра
    input   wire         reg_w,     // Сигнал на запись 16 битного регистра (reg_u:reg_v)
    input   wire         flg_w,     // Сигнал на запись флагов
    input   wire [ 2:0]  reg_n,     // Номер регистра
    input   wire [ 7:0]  reg_l,     // Что писать
    input   wire [ 7:0]  reg_u,     // Что писать
    input   wire [ 7:0]  flag,      // Что писать
    output  reg  [ 7:0]  reg_r8,    // reg_r8  = regs8 [ reg_n ]
    output  reg  [15:0]  reg_r16,   // reg_r16 = regs16[ reg_n ]
    input   wire [2:0]   cmd,        // Особая инструкция для регистров

    input   wire         pe,        // Префиксы включены
    input   wire         pem,       // 0=IX, 1=IY

    output  reg  [7:0]   a,
    output  reg  [7:0]   f,
    output  reg  [15:0]  bc,
    output  reg  [15:0]  de,
    output  wire [15:0]  hl,
    output  reg  [15:0]  sp,

    output  wire         cc,
    output  wire         ccc
);

/* Дополнительные регистры */
reg  [15:0] HL  = 16'h0000;
reg  [15:0] bc_ = 16'h0000;
reg  [15:0] de_ = 16'h0000;
reg  [15:0] hl_ = 16'h0000;

reg  [ 7:0] a_  =  8'h00;
reg  [ 7:0] f_ = 8'h81;
reg  [15:0] ix = 16'h0508;
reg  [15:0] iy = 16'h0304;

/* Регистры общего назначения */
initial begin

    a  =  8'h00;
    f  =  8'h00;
    bc = 16'h80FF;
    de = 16'h0002;
    sp = 16'hDFF0;
    HL = 16'h0104;

end

/* Регистр, зависимый от префикса */
assign hl  = pe ? (pem ? iy : ix) : HL;

/* JR */
assign cc  = (opcode[4] == 1'b0 && (f[`ZERO]   == opcode[3])) |
             (opcode[4] == 1'b1 && (f[`CARRY]  == opcode[3])) |
              opcode == 8'b00_011_000;

/* JP, CALL, RET */
assign ccc = (opcode[5:4] == 2'b00) & (f[`ZERO]   == opcode[3]) | // NZ, Z,
             (opcode[5:4] == 2'b01) & (f[`CARRY]  == opcode[3]) | // NC, C,
             (opcode[5:4] == 2'b10) & (f[`PARITY] == opcode[3]) | // PO, PE
             (opcode[5:4] == 2'b11) & (f[`SIGN]   == opcode[3]) | // P, M
              opcode == 8'b11_001_001 | // RET
              opcode == 8'b11_000_011 | // JP
              opcode == 8'b11_001_101;  // CALL


/* Чтение из регистров */
always @* begin

    case (reg_n)

        3'h0: reg_r8 = bc[15:8];
        3'h1: reg_r8 = bc[ 7:0];
        3'h2: reg_r8 = de[15:8];
        3'h3: reg_r8 = de[ 7:0];
        3'h4: reg_r8 = pe ? (pem ? iy[15:8] : ix[15:8]) : HL[15:8];
        3'h5: reg_r8 = pe ? (pem ? iy[ 7:0] : ix[ 7:0]) : HL[ 7:0];
        3'h6: reg_r8 = f;
        3'h7: reg_r8 = a;

    endcase

    case (reg_n)

        3'h0: reg_r16 = bc;
        3'h1: reg_r16 = de;
        3'h2: reg_r16 = pe ? (pem ? iy : ix) : HL;
        3'h3: reg_r16 = sp;
        3'h4: reg_r16 = {a, f};
        default: reg_r16 = 0;

    endcase

end

/* Запись в регистры */
always @(negedge pin_clk) begin

    case (cmd)

        `CMD_EXAF: begin {a, f} <= {a_, f_}; {a_, f_} <= {a, f}; end
        `CMD_EXX:  begin

            bc <= bc_; bc_ <= bc;
            de <= de_; de_ <= de;
            HL <= hl_; hl_ <= HL;

        end

        // Обмен HL/IX/IY
        `CMD_EXDEHL: begin de <= HL; HL <= de; end

        // LDIR
        `CMD_INC: begin bc <= bc - 1; de <= de + 1; HL <= HL + 1; end

        // LDDR
        `CMD_DEC: begin bc <= bc - 1; de <= de - 1; HL <= HL - 1; end

        // Запись в 8/16 bit
        default: begin

            // 16 bit
            if (reg_w) begin

                case (reg_n)

                    `REG_BC: bc <= {reg_u, reg_l};
                    `REG_DE: de <= {reg_u, reg_l};
                    `REG_HL: begin

                        if (pe)
                             case (pem) 1'b0: ix <= {reg_u, reg_l}; 1'b1: iy <= {reg_u, reg_l}; endcase
                        else HL <= {reg_u, reg_l};

                    end
                    `REG_SP: sp    <= {reg_u, reg_l};
                    `REG_AF: {a,f} <= {reg_u, reg_l};

                endcase

            end

            // 8 bit
            else if (reg_b) begin

                case (reg_n)

                    /* B */ 3'h0: bc[15:8] <= reg_l;
                    /* C */ 3'h1: bc[ 7:0] <= reg_l;
                    /* D */ 3'h2: de[15:8] <= reg_l;
                    /* E */ 3'h3: de[ 7:0] <= reg_l;
                    /* H */ 3'h4: begin

                        if (pe)
                             case (pem) 1'b0: ix[15:8] <= reg_l; 1'b1: iy[15:8] <= reg_l; endcase
                        else HL[15:8] <= reg_l;

                    end
                    /* L */ 3'h5: begin

                        if (pe)
                             case (pem) 1'b0: ix[ 7:0] <= reg_l; 1'b1: iy[ 7:0] <= reg_l; endcase
                        else HL[7:0] <= reg_l;

                    end
                    /* (hl) */
                    /* A */ 3'h7: a <= reg_l;

                endcase

            end

            // Разрешение записи флагов
            if (flg_w) f <= flag;
            
        end
        
    endcase

    
    
end

endmodule
