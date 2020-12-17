module kr580(

    /* Шина данных */
    input   wire         pin_clk,
    input   wire [ 7:0]  pin_i,
    output  wire [15:0]  pin_a,         // Указатель на адрес
    output  reg          pin_enw,       // Разрешить запись (высокий уровень)
    output  reg  [ 7:0]  pin_o,

    /* Порты */
    output  reg  [ 7:0]  pin_pa,
    input   wire [ 7:0]  pin_pi,
    output  reg  [ 7:0]  pin_po,
    output  reg          pin_pw,

    /* Interrupt */
    input   wire         pin_intr

);

// Базовый набор
`define ALU_ADD     4'h0
`define ALU_ADC     4'h1
`define ALU_SUB     4'h2
`define ALU_SBC     4'h3
`define ALU_AND     4'h4
`define ALU_XOR     4'h5
`define ALU_OR      4'h6
`define ALU_CP      4'h7

// Дополнительный набор
`define ALU_RLC     4'h8
`define ALU_RRC     4'h9
`define ALU_RL      4'hA
`define ALU_RR      4'hB
`define ALU_DAA     4'hC
`define ALU_CPL     4'hD
`define ALU_SCF     4'hE
`define ALU_CCF     4'hF

// Набор CBh
`define ALU_SLA     5'h10
`define ALU_SRA     5'h11
`define ALU_SLL     5'h12
`define ALU_SRL     5'h13
`define ALU_BIT     5'h14
`define ALU_RES     5'h15
`define ALU_SET     5'h16
`define ALU_RRLD    5'h17
`define ALU_ADCW    5'h18
`define ALU_SBCW    5'h19

`define CARRY       0
`define NEG         1
`define PARITY      2
`define AUX         4
`define ZERO        6
`define SIGN        7

`define REG_B       0
`define REG_C       1
`define REG_D       2
`define REG_E       3
`define REG_H       4
`define REG_L       5
`define REG_F       6
`define REG_A       7

`define REG_BC      0
`define REG_DE      1
`define REG_HL      2
`define REG_SP      3

`define LDI         1
`define LDD         2

initial begin

    pin_enw = 0;
    pin_o   = 0;
    pin_pa  = 0;
    pin_po  = 0;

end

/* Указатель на необходимые данные */
assign pin_a = alt_a ? cursor : pc;

/* Управляющие регистры */
reg  [ 3:0] t       = 0;        // Это t-state
reg  [ 2:0] m       = 0;        // Это m-state для префиксов
reg         halt    = 0;        // Процессор остановлен
reg         ei      = 0;        // Enabled Interrupt
reg         ei_     = 0;        // Это необходимо для EI+RET конструкции
reg  [15:0] cursor  = 0;
reg         alt_a   = 1'b0;     // =0 pc  =1 cursor

/* Регистры общего назначения */
reg  [15:0] bc = 16'h0000;      reg [15:0] bc_ = 16'h0000;
reg  [15:0] de = 16'h0000;      reg [15:0] de_ = 16'h0000;
reg  [15:0] hl = 16'h0000;      reg [15:0] hl_ = 16'h0000;
reg  [15:0] pc = 16'h0000;
reg  [15:0] sp = 16'h0000;
reg  [1:0]  im = 2'b00;
reg  [ 7:0] i  = 8'h00;
reg  [ 7:0] r  = 8'h00;
reg  [ 7:0] a  = 8'h00;         reg [ 7:0] a_ = 8'h00;
reg  [ 7:0] f  = 8'b01000000;   reg [ 7:0] f_ = 8'h00;
                //  SZ A P C

/* Сохраненный опкод */
wire [ 7:0] opcode          = t ? latch : pin_i;
reg  [ 7:0] latch           = 8'h00;
reg         prev_intr       = 1'b0;
reg         irq             = 1'b0;     // Исполнение запроса IRQ
reg  [ 2:0] irq_t           = 1'b0;     // Шаг исполнения
reg  [ 7:0] ed              = 8'h00;

/* Управление записью в регистры */
reg         reg_b = 1'b0;       // Сигнал на запись 8 битного регистра
reg         reg_w = 1'b0;       // Сигнал на запись 16 битного регистра (reg_u:reg_v)
reg  [ 2:0] reg_n = 3'h0;       // Номер регистра
reg  [ 7:0] reg_l = 8'h00;      // Что писать
reg  [ 7:0] reg_u = 8'h00;      // Что писать
reg  [ 7:0] reg_f = 8'h00;      // Сохранение флага
reg  [ 7:0] reg_r8;             // reg_r8  = regs8 [ reg_n ]
reg  [15:0] reg_r16;            // reg_r16 = regs16[ reg_n ]
reg  [ 1:0] reg_ldir;           // 1=DE++, HL++; 2=DE--, HL--;
reg         fw;                 // Писать флаги
reg         exx;
reg         ex_af;
reg         ex_de_hl;

/* Определение условий */
wire        reg_hl  = (reg_n == 3'b110);
wire [15:0] signext = {{8{pin_i[7]}}, pin_i[7:0]};
wire [3:0]  cc      = {f[`CARRY], ~f[`CARRY], f[`ZERO], ~f[`ZERO]};
wire        ccc     = (opcode[5:4] == 2'b00) & (f[`ZERO]   == opcode[3]) | // NZ, Z,
                      (opcode[5:4] == 2'b01) & (f[`CARRY]  == opcode[3]) | // NC, C,
                      (opcode[5:4] == 2'b10) & (f[`PARITY] == opcode[3]) | // PO, PE
                      (opcode[5:4] == 2'b11) & (f[`SIGN]   == opcode[3]) | // P, M
                       opcode == 8'b11_001_001 | // RET
                       opcode == 8'b11_000_011 | // JP
                       opcode == 8'b11_001_101;  // CALL

/* Арифметическое-логическое устройство */
reg  [ 4:0] alu_m = 0;
reg  [ 8:0] alu_r;
reg  [16:0] alu_r16;
reg  [ 7:0] alu_f;
reg  [ 7:0] op1 = 0;        // Первый операнд для АЛУ
reg  [15:0] op1w = 0;
reg  [ 7:0] op2 = 0;        // Второй операнд для АЛУ
reg  [15:0] op2w = 0;

/* Исполнение инструкции */
always @(posedge pin_clk) begin

    /* Определение позитивного фронта intr */
    prev_intr <= pin_intr;

    /* Получение запроса внешнего interrupt */
    if ({prev_intr, pin_intr} == 2'b01) begin irq <= ei; end

    /* Выполнение запроса IRQ */
    else if (irq_t) begin

        case (irq_t)

            // Деактивация прерываний. Если halt, то PC = PC + 1
            1: begin irq_t <= 2; ei <= 0; ei_ <= 0; if (halt) pc <= pc + 1; end

        endcase

    end

    /* Исполнение опкодов */
    else begin

        /* Запись опкода на первом такте */
        if (t == 0) begin

            // Запуск IRQ
            if (irq) irq_t <= 1;

            irq   <= 1'b0;
            latch <= pin_i;
            ei    <= ei_;
            r     <= r + 1;

        end

        /* Подготовка управляющих сигналов */
        alt_a    <= 1'b0;
        reg_b    <= 1'b0;
        reg_w    <= 1'b0;
        pin_enw  <= 1'b0;
        pin_pw   <= 1'b0;
        halt     <= 1'b0;
        fw       <= 1'b0;
        exx      <= 1'b0;
        ex_de_hl <= 1'b0;
        ex_af    <= 1'b0;
        reg_ldir <= 1'b0;

        // Выполнять инструкции можно только при отсутствии IRQ
        if ((irq == 0 && t == 0) || t)
        casex (opcode)

            // 1 NOP
            8'b00_000_000: pc <= pc + 1;

            // 1 EX AF, AF'
            // 1 EXX
            8'b00_001_000: begin pc <= pc + 1; ex_af <= 1'b1; end
            8'b11_011_001: begin pc <= pc + 1; exx   <= 1'b1; end

            // 1/2 DJNZ *
            8'b00_010_000: case (t)

                0: begin

                    reg_b <= 1'b1;
                    reg_n <= `REG_B;
                    reg_l <= bc[15:8] - 1;

                    if (bc[15:8] == 8'h01) pc <= pc + 2;
                    else begin t <= 1;     pc <= pc + 1; end

                end
                1: begin t <= 0; pc <= pc + 1 + signext; end

            endcase

            // 2 JR *
            8'b00_011_000: case (t)

                0: begin t <= 1; pc <= pc + 1; end
                1: begin t <= 0; pc <= pc + 1 + signext; end

            endcase

            // 1|2 JR cc, *
            8'b00_1xx_000: case (t)

                0: begin if (cc[ opcode[4:3] ]) begin pc <= pc + 1; t <= 1; end
                                           else begin pc <= pc + 2; end end
                1: begin t <= 0; pc <= pc + 1 + signext; end

            endcase

            // 3 LD r, i16
            8'b00_xx0_001: case (t)

                0: begin pc <= pc + 1; t <= 1; reg_n <= opcode[5:4]; end
                1: begin pc <= pc + 1; t <= 2; reg_l <= pin_i; end
                2: begin pc <= pc + 1; t <= 0; reg_u <= pin_i; reg_w <= 1'b1; end

            endcase

            // 4 ADD HL, r
            8'b00_xx1_001: case (t)

                0: begin t <= 1;
                    reg_n     <= {opcode[5:4], 1'b1};
                    pc        <= pc + 1;
                end
                1: begin t <= 2;
                    reg_f     <= f;
                    reg_n     <= {opcode[5:4], 1'b0};
                    op1       <= hl[ 7:0];
                    op2       <= reg_r8;
                    alu_m     <= `ALU_ADD;
                end
                2: begin t <= 3;
                    op1       <= hl[15:8];
                    op2       <= reg_r8;
                    reg_n     <= `REG_L;
                    reg_b     <= 1'b1;
                    reg_l     <= alu_r[7:0];
                    alu_m     <= `ALU_ADC;
                    reg_f[0]  <= alu_f[`CARRY];
                    fw        <= 1'b1;
                end
                3: begin t <= 0;
                    reg_n     <= `REG_H;
                    reg_l     <= alu_r[7:0];
                    reg_b     <= 1'b1;
                    fw        <= 1'b1;
                    reg_f[`AUX]   <= alu_f[`AUX];
                    reg_f[`CARRY] <= alu_f[`CARRY];
                    reg_f[`SIGN]  <= alu_f[`SIGN];
                end

            endcase

            // 2 LD (r16), A
            8'b00_0x0_010: case (t)

                0: begin t <= 1; pc <= pc + 1; cursor <= opcode[4] ? de : bc; alt_a <= 1; pin_o <= a; pin_enw <= 1; end
                1: begin t <= 0; alt_a <= 0; end

            endcase

            // 2 LD A, (r16)
            8'b00_0x1_010: case (t)

                0: begin t <= 1; pc <= pc + 1; cursor <= opcode[4] ? de : bc; alt_a <= 1; end
                1: begin t <= 0; reg_b <= 1; reg_l <= pin_i; reg_n <= `REG_A; end

            endcase

            // 4 LD (**), HL
            8'b00_100_010: case (t)

                0: begin t <= 1; pc <= pc + 1; end
                1: begin t <= 2; pc <= pc + 1; cursor[7:0] <= pin_i; end
                2: begin t <= 3; pin_enw <= 1; alt_a <= 1; pin_o <= hl[ 7:0]; cursor[15:8] <= pin_i; end
                3: begin t <= 4; pin_enw <= 1; alt_a <= 1; pin_o <= hl[15:8]; cursor <= cursor + 1;  end
                4: begin t <= 0; pc <= pc + 1; end

            endcase

            // 5 LD HL, (**)
            8'b00_101_010: case (t)

                0: begin t <= 1; pc <= pc + 1; end
                1: begin t <= 2; pc <= pc + 1; cursor[ 7:0] <= pin_i; end
                2: begin t <= 3; pc <= pc + 1; cursor[15:8] <= pin_i; alt_a <= 1; end
                3: begin t <= 4; reg_n <= `REG_L; reg_b <= 1; reg_l <= pin_i; alt_a <= 1; cursor <= cursor + 1; end
                4: begin t <= 0; reg_n <= `REG_H; reg_b <= 1; reg_l <= pin_i; end

            endcase

            // 4 LD (**), A
            8'b00_110_010: case (t)

                0: begin t <= 1; pc <= pc + 1; end
                1: begin t <= 2; pc <= pc + 1; cursor[7:0] <= pin_i; end
                2: begin t <= 3; pin_enw <= 1; alt_a <= 1; pin_o <= a[7:0]; cursor[15:8] <= pin_i; end
                3: begin t <= 0; pc <= pc + 1; end

            endcase

            // 4 LD A, (**)
            8'b00_111_010: case (t)

                0: begin t <= 1; pc <= pc + 1; end
                1: begin t <= 2; pc <= pc + 1; cursor[ 7:0] <= pin_i; end
                2: begin t <= 3; pc <= pc + 1; cursor[15:8] <= pin_i; alt_a <= 1; end
                3: begin t <= 0; reg_b <= 1; reg_n <= `REG_A; reg_l <= pin_i; end

            endcase

            // 2 INC r16
            8'b00_xx0_011: case (t)

                0: begin t <= 1; pc <= pc + 1; reg_n <= opcode[5:4]; end
                1: begin t <= 0; {reg_u, reg_l} <= reg_r16 + 1; reg_w <= 1; end

            endcase

            // 2 DEC r16
            8'b00_xx1_011: case (t)

                0: begin t <= 1; pc <= pc + 1; reg_n <= opcode[5:4]; end
                1: begin t <= 0; {reg_u, reg_l} <= reg_r16 - 1; reg_w <= 1; end

            endcase

            // 4 INC r8
            // 4 DEC r8
            8'b00_xxx_10x: case (t)

                0: begin t <= 1;
                    pc     <= pc + 1;
                    reg_n  <= opcode[5:3];
                    cursor <= hl;
                    alt_a  <= 1; end
                1: begin t <= 2;
                    op1    <= reg_hl ? pin_i : reg_r8;
                    op2    <= 1;
                    alu_m  <= opcode[0] ? `ALU_SUB : `ALU_ADD; end
                2: begin t <= 3;
                    pin_enw <=  reg_hl;
                    reg_b   <= ~reg_hl;
                    reg_f   <= alu_f;
                    reg_l   <= alu_r;
                    pin_o   <= alu_r;
                    fw      <= 1'b1;
                    alt_a   <= 1'b1; end
                3: begin t <= 0; end

            endcase

            // 3 LD r, i8
            8'b00_xxx_110: case (t)

                0: begin t <= 1; pc <= pc + 1; reg_n <= opcode[5:3]; cursor <= hl; end
                1: begin t <= 2; pc <= pc + 1; reg_b <= ~reg_hl; pin_enw <= reg_hl; reg_l <= pin_i; pin_o <= pin_i; alt_a <= 1; end
                2: begin t <= 0; end

            endcase

            // 2 RLCA, RRCA, RLA, RRA, DAA, CPL, SCF, CCF
            8'b00_xxx_111: case (t)

                0: begin t <= 1; pc <= pc + 1; op1 <= a; alu_m <= {1'b1, opcode[5:3]}; end
                1: begin t <= 0; reg_b <= 1; reg_l <= alu_r; reg_n <= `REG_A; fw <= 1'b1; reg_f <= alu_f; end

            endcase

            // 4 LD r, r
            8'b01_110_110: halt <= 1;
            8'b01_xxx_xxx: case (t)

                0: begin t <= 1; pc <= pc + 1; reg_n <= opcode[2:0]; alt_a <= 1; cursor <= hl; end
                1: begin t <= 2; reg_l <= reg_hl ? pin_i : reg_r8; reg_n <= opcode[5:3]; end
                2: begin t <= 3; reg_b <= ~reg_hl; pin_enw <= reg_hl; pin_o <= reg_l; alt_a <= 1; end
                3: begin t <= 0; end

            endcase

            // 3 <alu> A, r
            8'b10_xxx_xxx: case (t)

                0: begin t <= 1; op1   <= a; pc <= pc + 1; reg_n <= opcode[2:0]; alt_a <= 1; cursor <= hl; end
                1: begin t <= 2; op2   <= reg_hl ? pin_i : reg_r8; alu_m <= opcode[5:3]; end
                2: begin t <= 0; reg_b <= (alu_m != 3'b111); reg_n <= `REG_A; reg_l <= alu_r; fw <= 1'b1; reg_f <= alu_f; end

            endcase

            // 2/3 RET c | RET
            8'b11_001_001,
            8'b11_xxx_000: case (t)

                0: begin t <= ccc; alt_a <= ccc; pc <= pc + 1; cursor <= sp; end
                1: begin t <= 2; pc[ 7:0] <= pin_i; alt_a <= 1; cursor <= cursor + 1; end
                2: begin t <= 0; pc[15:8] <= pin_i; {reg_u, reg_l} <= cursor + 1; reg_n <= `REG_SP; reg_w <= 1; end

            endcase

            // 4 POP r16
            8'b11_xx0_001: case (t)

                0: begin t <= 1; cursor <= sp;         alt_a <= 1;  pc    <= pc + 1; end
                1: begin t <= 2; cursor <= cursor + 1; alt_a <= 1;  reg_l <= pin_i; end
                2: begin t <= 3; cursor <= cursor + 1;              reg_u <= pin_i;

                         if (opcode[5:4] == 2'b11) /* POP AF */
                              begin reg_n <= `REG_A;      reg_b <= 1; reg_l <= pin_i; fw <= 1'b1; reg_f <= reg_l; end
                         else begin reg_n <= opcode[5:4]; reg_w <= 1; end
                end
                3: begin t <= 0; reg_n <= `REG_SP; reg_w <= 1; {reg_u, reg_l} <= cursor; end

            endcase

            // 1 JP (HL)
            8'b11_101_001: case (t)

                0: begin pc <= hl; end

            endcase

            // 1 LD SP, HL
            8'b11_111_001: case (t)

                0: begin pc <= pc + 1; reg_n <= `REG_SP; reg_w <= 1; {reg_u, reg_l} <= hl; end

            endcase

            // 4 JP c, ** | JP **
            8'b11_000_011,
            8'b11_xxx_010: case (t)

                0: begin t <= 1; pc <= pc + 1'b1; end
                1: begin t <= 2; pc <= pc + 1'b1; reg_l <= pin_i; end
                2: begin t <= 3; pc <= pc + 1'b1; reg_u <= pin_i; end
                3: begin t <= 0; if (ccc) pc <= {reg_u, reg_l}; end

            endcase

            // 2 OUT (*), A
            8'b11_010_011: case (t)

                0: begin t <= 1; pc <= pc + 1; end
                1: begin t <= 0; pc <= pc + 1; pin_pa <= pin_i; pin_po <= a; pin_pw <= 1; end

            endcase

            // 3 IN  A, (*)
            8'b11_011_011: case (t)

                0: begin t <= 1; pc <= pc + 1; end
                1: begin t <= 2; pc <= pc + 1; pin_pa <= pin_i; end
                2: begin t <= 0; reg_l <= pin_pi; reg_b <= 1; reg_n <= `REG_A; end

            endcase

            // 5 EX (SP), HL
            8'b11_100_011: case (t)

                0: begin t <= 1; alt_a <= 1; cursor <= sp; pc <= pc + 1;  end
                1: begin t <= 2; alt_a <= 1; reg_l <= pin_i; pin_o <= hl[7:0]; pin_enw <= 1; end
                2: begin t <= 3; alt_a <= 1; cursor <= cursor + 1; end
                3: begin t <= 4; alt_a <= 1; reg_u <= pin_i; reg_w <= 1; reg_n <= `REG_HL; pin_o <= hl[15:8]; pin_enw <= 1; end
                4: begin t <= 0; end

            endcase

            // 1 EX DE, HL
            8'b11_101_011: case (t)

                0: begin pc <= pc + 1; ex_de_hl <= 1; end

            endcase

            // 1 DI, EI
            8'b11_11x_011: case (t)

                0: begin pc <= pc + 1; ei_ <= opcode[3]; end

            endcase

            // 3/6 CALL c, **
            8'b11_001_101,
            8'b11_xxx_100: case (t)

                0: begin t <= 1; pc <= pc + 1; end
                1: begin t <= 2; pc <= pc + 1; reg_l <= pin_i; end
                2: begin         pc <= pc + 1; reg_u <= pin_i; cursor <= sp;
                         t <= ccc ? 3 : 0; end
                3: begin t <= 4; pin_o <= pc[15:8]; pin_enw <= 1; alt_a <= 1; cursor <= cursor - 1; end
                4: begin t <= 5; pin_o <= pc[ 7:0]; pin_enw <= 1; alt_a <= 1; cursor <= cursor - 1; end
                5: begin t <= 0; reg_w <= 1; reg_n <= `REG_SP; pc <= {reg_u, reg_l}; {reg_u, reg_l} <= cursor; end

            endcase

            // 4 PUSH r16
            8'b11_xx0_101: case (t)

                0: begin t <= 1; pc <= pc + 1; reg_n <= opcode[5:4]; cursor <= sp; end
                1: begin t <= 2; alt_a <= 1; pin_o <= (reg_n == 2'b11) ? a : reg_r16[15:8]; pin_enw <= 1; cursor <= cursor - 1; end
                2: begin t <= 3; alt_a <= 1; pin_o <= (reg_n == 2'b11) ? f : reg_r16[ 7:0]; pin_enw <= 1; cursor <= cursor - 1; end
                3: begin t <= 0; reg_w <= 1; reg_n <= `REG_SP; {reg_u, reg_l} <= cursor; end

            endcase

            // 3 <alu> A, i8
            8'b11_xxx_110: case (t)

                0: begin t <= 1; pc <= pc + 1; alu_m <= opcode[5:3]; op1 <= a; end
                1: begin t <= 2; pc <= pc + 1; op2 <= pin_i; end
                2: begin t <= 0; reg_l <= alu_r; fw <= 1'b1; reg_f <= alu_f; reg_n <= `REG_A; reg_b <= (alu_m != 3'b111); end

            endcase

            // 4 RST #
            8'b11_xxx_111: case (t)

                0: begin t <= 1; pc    <= pc + 1; cursor <= sp; end
                1: begin t <= 2; pin_o <= pc[15:8]; pin_enw <= 1; cursor <= cursor - 1; alt_a <= 1; end
                2: begin t <= 3; pin_o <= pc[ 7:0]; pin_enw <= 1; cursor <= cursor - 1; alt_a <= 1; end
                3: begin t <= 0; reg_w <= 1; reg_n <= `REG_SP; {reg_u, reg_l} <= cursor; pc <= {opcode[5:3], 3'b000}; end

            endcase

            // 3+ Префикс EDh
            8'b11_101_101: case (t)

                0: begin t <= 1; pc <= pc + 1; m  <= 0; end
                1: begin t <= 2; pc <= pc + 1; ed <= pin_i; end
                2: casex (ed)

                    // 4 IN r8, (C)
                    8'b01_xxx_000: case (m)

                        0: begin m <= 1; pin_pa <= bc[7:0]; end
                        1: begin t <= 0;

                            // Подготовка флагов на запись
                            reg_f = {

                                /* S */ pin_pi[7],
                                /* Z */ pin_pi == 0,
                                /* 0 */ pin_pi[5],
                                /* H */ 1'b0,
                                /* 0 */ pin_pi[3],
                                /* P */ ~^pin_pi,
                                /* N */ 1'b0,
                                /* C */ op1[7]
                            };


                            // Писать в регистр, только если не (HL)
                            reg_b <= ed[5:3] != 3'b110;
                            reg_n <= ed[5:3];
                            reg_l <= pin_pi;
                            fw    <= 1;

                        end

                    endcase

                    // 4 OUT (C), r8
                    8'b01_xxx_001: case (m)

                        0: begin m <= 1; pin_pa <= bc[7:0]; reg_n <= ed[5:3]; end
                        1: begin t <= 0;

                            pin_po <= (reg_n == 3'b110) ? 0 : reg_r8;
                            pin_pw <= 1;

                        end

                    endcase

                    // 5 ADC|SBC HL, r16
                    8'b01_xxx_010: case (m)

                        0: begin m <= 1; op1w <= hl;      reg_n <= ed[5:4]; end
                        1: begin m <= 2; op2w <= reg_r16; alu_m <= ed[3] ? `ALU_ADCW : `ALU_SBCW; end
                        2: begin t <= 0;

                            fw    <= 1;
                            reg_w <= 1;
                            reg_n <= `REG_HL;
                            reg_f <= alu_f;

                            {reg_u, reg_l} <= alu_r16;

                        end

                    endcase

                    // 3 LD I/R/A
                    8'b0100_0111: begin t <= 0; i <= a; end
                    8'b0100_1111: begin t <= 0; r <= a; end
                    8'b0101_0111: begin t <= 0; reg_b <= 1; reg_n <= `REG_A; reg_l <= i; end
                    8'b0101_1111: begin t <= 0; reg_b <= 1; reg_n <= `REG_A; reg_l <= r; end

                    // 5 RETN (Алиас RET)
                    8'b01_xxx_101: case (m)

                        0: begin m <= 1; alt_a <= 1;                    cursor <= sp; end
                        1: begin m <= 2; alt_a <= 1; pc[ 7:0] <= pin_i; cursor <= cursor + 1; end
                        2: begin t <= 0;             pc[15:8] <= pin_i; {reg_u, reg_l} <= cursor + 1;

                            reg_w <= 1;
                            reg_n <= `REG_SP;

                            // RETI: Выставляет обратно прерывания
                            if (ed[5:3] == 3'b001) begin

                                ei  <= 1'b1;
                                ei_ <= 1'b1;

                            end

                        end

                    endcase

                    // 3 IM n
                    8'b01_xxx_110: begin t <= 0; im <= ed[3] ? (ed[4] ? 2 : a[0]) : ed[4]; end

                    // 4 NEG
                    8'b01_xxx_100: case (m)

                        0: begin m <= 1; op1 <= 0; op2 <= a; alu_m <= `ALU_SUB; end
                        1: begin t <= 0;

                            fw    <= 1;
                            reg_b <= 1;
                            reg_n <= `REG_A;
                            reg_l <= alu_r;
                            reg_f <= alu_f;

                        end

                    endcase

                    // 6 RRD | RLD
                    8'b01_10x_111: case (m)

                        0: begin m <= 1; cursor <= hl; alt_a <= 1; end
                        1: begin m <= 2;

                            // 1=RLD, 0=RRD
                            reg_b <= 1;
                            reg_n <= `REG_A;       // RLD          RRD
                            reg_l <= {a[7:4], ed[3] ? pin_i[7:4] : pin_i[3:0]};

                            // На выход на запись
                            alt_a   <= 1;
                            pin_enw <= 1;
                            pin_o   <= ed[3] ? {pin_i[3:0],     a[3:0]} : // RLD
                                               {    a[3:0], pin_i[7:4]};  // RRD

                        end

                        // Вычислить из записать флаги
                        2: begin m <= 3; op1 <= a; alu_m <= `ALU_RRLD; end
                        3: begin t <= 0; fw  <= 1; reg_f <= alu_f; end

                    endcase

                    // 5 LD(I|IR|D|DR)
                    8'b101x_x000: case (m)

                        0: begin cursor <= hl; alt_a <= 1'b1; m <= 1; end
                        1: begin cursor <= de; alt_a <= 1'b1; m <= 2;
                                 pin_enw  <= 1'b1;
                                 pin_o    <= pin_i;
                                 op1      <= pin_i;
                                 reg_ldir <= ed[3] ? `LDD : `LDI;
                        end
                        2: begin t <= 0;

                            if (ed[4] && bc) pc <= pc - 2;

                            // Обновление флагов после LD(I|IR|D|DR)
                            fw    <= 1;
                            reg_f <= {

                                /* S */ f[`SIGN],
                                /* Z */ f[`ZERO],
                                /* 0 */ ldi_xy[1],
                                /* H */ 1'b0,
                                /* 0 */ ldi_xy[3],
                                /* V */ |bc[15:0],
                                /* 1 */ 1'b0,
                                /* C */ f[`CARRY]
                            };

                        end

                    endcase

                    // 6 LD (**), r16
                    8'b01_xx0_011: case (m)

                        0: begin m <= 1; // Читать L

                            cursor[7:0] <= pin_i;
                            reg_n <= ed[5:4];
                            pc    <= pc + 1;

                        end
                        1: begin m <= 2; // Читать H, писать L

                            cursor[15:8] <= pin_i;
                            pc      <= pc + 1;
                            pin_o   <= reg_r16[7:0];
                            pin_enw <= 1;
                            alt_a   <= 1;

                        end

                        2: begin m <= 3; // Писать H

                            cursor  <= cursor + 1;
                            pin_o   <= reg_r16[15:8];
                            pin_enw <= 1;
                            alt_a   <= 1;

                        end
                        3: begin t <= 0; end // Отключить запись

                    endcase

                    // 6 LD r16, (**)
                    8'b01_xx1_011: case (m)

                        0: begin m <= 1; cursor[7:0]  <= pin_i; pc <= pc + 1;   reg_n <= ed[5:4]; end
                        1: begin m <= 2; cursor[15:8] <= pin_i; pc <= pc + 1;   alt_a <= 1; end
                        2: begin m <= 3; reg_l <= pin_i; cursor <= cursor + 1;  alt_a <= 1; end
                        3: begin t <= 0; reg_u <= pin_i; reg_w <= 1;  end

                    endcase

                endcase

            endcase

            // Префикс CBh
            8'b11_001_011: case (t)

                0: begin t <= 1; pc <= pc + 1; cursor <= hl; end
                1: begin t <= 2; pc <= pc + 1; ed <= pin_i; reg_n <= pin_i[2:0]; alt_a <= (pin_i[2:0] == 3'b110); end
                2: begin t <= 3;

                    // Операнд может идти из памяти (HL) или из Reg8
                    op1 <= reg_hl ? pin_i : reg_r8;

                    // Второй операнд [5:3] для bit | res[6]=0, set[6]=1
                    op2 <= ed[6:3];

                    // Выбор режима
                    casex (ed)

                        // Инструкции RLC, RRC, RL, RR
                        8'b00_0xx_xxx: alu_m <= `ALU_RLC + ed[4:3];

                        // Инструкции SLA, SRA, SLL, SRL
                        8'b00_1xx_xxx: alu_m <= `ALU_SLA + ed[4:3];

                        // Инструкции 101xx: 101[01]=BIT, 101[10]=RES, 101[11]=SET
                              default: alu_m <= `ALU_BIT + (ed[7:6] - 1);

                    endcase

                end
                3: begin t <= 4;

                    fw    <= 1'b1;
                    reg_f <= alu_f;

                    if (alu_m != `ALU_BIT) begin

                         pin_enw <=  reg_hl;
                         alt_a   <=  reg_hl;
                         pin_o   <=  alu_r;
                         reg_l   <=  alu_r;
                         reg_b   <= !reg_hl;

                    end

                end
                4: begin t <= 0; alt_a <= 0; end

            endcase

        endcase

    end

end

// ---------------------------------------------------------------------
// Арифметико-логическое устройство
// ---------------------------------------------------------------------

wire flag_sign =   alu_r[7];    // Знак
wire flag_zero = ~|alu_r[7:0];  // Нуль
wire flag_prty = ~^alu_r[7:0];  // Четность

wire [5:0]  ldi_xy = a + op1;
wire [15:0] op2c   = op2w + f[`CARRY];
reg         bit_z;

always @* begin

    case (alu_m)

        /* op1 + op2 => r */
        `ALU_ADD: begin

            alu_r = op1 + op2;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ 1'b0,
                /* A */ op1[3:0] + op2[3:0] > 5'hF,
                /* 0 */ 1'b0,
                /* P */ (op1[7] == op2[7]) && (op1[7] != alu_r[7]),
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
                /* 0 */ 1'b0,
                /* A */ op1[3:0] + op2[3:0] + f[`CARRY] > 5'hF,
                /* 0 */ 1'b0,
                /* P */ (op1[7] == op2[7]) && (op1[7] != alu_r[7]),
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
                /* 0 */ 1'b0,
                /* A */ op1[3:0] < op2[3:0],
                /* 0 */ 1'b0,
                /* P */ (op1[7] != op2[7]) && (op1[7] != alu_r[7]),
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
                /* 0 */ 1'b0,
                /* A */ op1[3:0] < op2[3:0] + f[`CARRY],
                /* 0 */ 1'b0,
                /* P */ (op1[7] != op2[7]) && (op1[7] != alu_r[7]),
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
                /* 0 */ 1'b0,
                /* A */ 1'b0,
                /* 0 */ 1'b0,
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
                /* 0 */ 1'b0,
                /* A */ 1'b0,
                /* 0 */ 1'b0,
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
                /* 0 */ 1'b0,
                /* A */ 1'b0,
                /* 0 */ 1'b0,
                /* P */ flag_prty,
                /* N */ 1'b0,
                /* C */ 1'b0

            };

        end

        /* op1 - op2 */
        `ALU_CP: begin

            alu_r = op1 - op2;
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ 1'b0,
                /* A */ op1[3:0] < op2[3:0],
                /* 0 */ 1'b0,
                /* P */ flag_prty,
                /* N */ 1'b1,
                /* C */ alu_r[8]

            };

        end

        /* Циклический сдвиг налево */
        `ALU_RLC: begin

            alu_r = {op1[6:0], op1[7]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ 1'b0,
                /* A */ 1'b0,
                /* 0 */ 1'b0,
                /* P */ flag_prty,
                /* 1 */ 1'b1,
                /* C */ op1[7]

            };

        end

        /* Циклический сдвиг направо */
        `ALU_RRC: begin

            alu_r = {op1[0], op1[7:1]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ 1'b0,
                /* A */ 1'b0,
                /* 0 */ 1'b0,
                /* P */ flag_prty,
                /* 1 */ 1'b1,
                /* C */ op1[0]

            };

        end

        /* Сдвиг с заемом C влево */
        `ALU_RL: begin

            alu_r = {op1[6:0], f[`CARRY]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ 1'b0,
                /* A */ 1'b0,
                /* 0 */ 1'b0,
                /* P */ flag_prty,
                /* 1 */ 1'b1,
                /* C */ op1[7]

            };

        end

        /* Сдвиг с заемом C вправо */
        `ALU_RR: begin

            alu_r = {f[`CARRY], op1[7:1]};
            alu_f = {

                /* S */ flag_sign,
                /* Z */ flag_zero,
                /* 0 */ 1'b0,
                /* A */ 1'b0,
                /* 0 */ 1'b0,
                /* P */ flag_prty,
                /* 1 */ 1'b1,
                /* C */ op1[0]

            };

        end

        /* Десятичная коррекция */
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
                /* A */ a[4] ^ alu_r[4],
                /* 0 */ alu_r[3],
                /* P */ flag_prty,
                /* N */ f[`NEG],
                /* C */ f[`CARRY] | (a > 8'h99)

            };

        end

        /* A ^ $FF */
        `ALU_CPL: begin

            alu_r = ~a;
            alu_f = {

                /* S */ f[`SIGN],
                /* Z */ f[`ZERO],
                /* 0 */ 1'b0,
                /* A */ 1'b1,
                /* 0 */ 1'b0,
                /* P */ f[`PARITY],
                /* 1 */ 1'b1,
                /* C */ f[`CARRY]

            };

        end

        /* CF = 1 */
        `ALU_SCF: begin

            alu_r = a;
            alu_f = {

                /* S */ f[`SIGN],
                /* Z */ f[`ZERO],
                /* 0 */ 1'b0,
                /* A */ f[`AUX],
                /* 0 */ 1'b0,
                /* P */ f[`PARITY],
                /* 1 */ 1'b1,
                /* C */ 1'b1

            };

        end

        /* CF ^= 1 */
        `ALU_CCF: begin

            alu_r = a;
            alu_f = {

                /* S */ f[`SIGN],
                /* Z */ f[`ZERO],
                /* 0 */ 1'b0,
                /* A */ f[`AUX],
                /* 0 */ 1'b0,
                /* P */ f[`PARITY],
                /* 1 */ 1'b1,
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

        /* Проверить бит op1, op2[2:0] номер бита */
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

        /* Проверить бит op1, op2[2:0] номер бита, op[3] какой ставить */
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

// ---------------------------------------------------------------------
// Работа с регистрами
// ---------------------------------------------------------------------

// Чтение
always @* begin

    reg_r8  = 8'h00;
    reg_r16 = 16'h0000;

    case (reg_n)

        3'h0: reg_r8 = bc[15:8];
        3'h1: reg_r8 = bc[ 7:0];
        3'h2: reg_r8 = de[15:8];
        3'h3: reg_r8 = de[ 7:0];
        3'h4: reg_r8 = hl[15:8];
        3'h5: reg_r8 = hl[ 7:0];
        3'h6: reg_r8 = f;
        3'h7: reg_r8 = a;

    endcase

    case (reg_n)

        3'h0:   reg_r16 = bc;
        3'h1:   reg_r16 = de;
        3'h2:   reg_r16 = hl;
        3'h3:   reg_r16 = sp;
        3'h4:   reg_r16 = {a, f};

    endcase

end

// Запись в регистры
always @(negedge pin_clk) begin

    if      (ex_de_hl)         begin de <= hl;     hl <= de; end
    else if (reg_ldir == `LDI) begin de <= de + 1; hl <= hl + 1; bc <= bc - 1; end
    else if (reg_ldir == `LDD) begin de <= de - 1; hl <= hl - 1; bc <= bc - 1; end
    else if (ex_af) begin {a, f} <= {a_, f_}; {a_, f_} <= {a, f}; end
    else if (exx)   begin {bc, de, hl} <= {bc_, de_, hl_}; {bc_, de_, hl_} <= {bc, de, hl}; end
    else if (reg_w) begin

        case (reg_n)

            3'h0: bc <= {reg_u, reg_l};
            3'h1: de <= {reg_u, reg_l};
            3'h2: hl <= {reg_u, reg_l};
            3'h3: sp <= {reg_u, reg_l};

        endcase

    end
    else if (reg_b) begin

        case (reg_n)

            3'h0: bc[15:8] <= reg_l;
            3'h1: bc[ 7:0] <= reg_l;
            3'h2: de[15:8] <= reg_l;
            3'h3: de[ 7:0] <= reg_l;
            3'h4: hl[15:8] <= reg_l;
            3'h5: hl[ 7:0] <= reg_l;
            /* (hl) */
            3'h7: a <= reg_l;

        endcase

    end

    // Сохранение флагов
    if (fw) f <= reg_f;

end

endmodule
