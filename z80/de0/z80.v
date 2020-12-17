module z80(

    input   wire         pin_reset,

    /* Шина данных */
    input   wire         pin_clk,
    input   wire [ 7:0]  pin_i,
    output  wire [15:0]  pin_a,         // Указатель на адрес
    output  reg          pin_enw,       // Разрешить запись ы(высокий уровень)
    output  reg  [ 7:0]  pin_o,

    /* Порты */
    output  reg  [15:0]  pin_pa,
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

// Сдвиги и биты
`define ALU_SLA     5'h10
`define ALU_SRA     5'h11
`define ALU_SLL     5'h12
`define ALU_SRL     5'h13
// ..
`define ALU_BIT     5'h15       // 1|0101
`define ALU_RES     5'h16       // 1|0110
`define ALU_SET     5'h17       // 1|0111

// Расширенные
`define ALU_INC     5'h18
`define ALU_DEC     5'h19
`define ALU_ADDW    5'h1A
`define ALU_SUBW    5'h1B
`define ALU_ADCW    5'h1C
`define ALU_SBCW    5'h1D
`define ALU_RRLD    5'h1E

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
`define REG_AF      4

`define CMD_NOPE    3'b000
`define CMD_EXDEHL  3'b001
`define CMD_EXAF    3'b010
`define CMD_EXX     3'b011
`define CMD_INC     3'b100 // LDI, CPI...
`define CMD_DEC     3'b101 // LDD, CPD...

initial begin

    pin_enw = 0;
    pin_o   = 0;
    pin_pa  = 0;
    pin_po  = 0;

end

/* Указатель на необходимые данные */
assign pin_a = alt ? cursor : pc;

/* Управляющие регистры */
reg  [ 2:0] t       = 0;        // Это t-state
reg  [ 2:0] m       = 0;        // Это t-state
reg         halt    = 0;        // Процессор остановлен
reg  [ 4:0] Z80_Delay = 0;      // Задержки

/* Прерывания */
reg         ei      = 0;        // Enabled Interrupt
reg         di      = 0;        // Disabled Interrupt
reg         iff1    = 0;
reg         iff2    = 0;
reg         iff1_   = 0;
reg         iff2_   = 0;
reg  [ 2:0] irq     = 0;

reg  [15:0] cursor    = 0;
reg         alt       = 1'b0;     // =0 pc  =1 cursor

/* Регенерация */
reg  [ 7:0] r  = 8'h00;         // Регистр регенерации
wire [ 6:0] rl = r[6:0] + 1;
wire [ 7:0] rh = {r[7], rl};

/* +disp8 для префикса */
wire [15:0] xof     = cursor + {{8{pin_i[7]}}, pin_i[7:0]};
wire        cbhl    = (opcode_ext[2:0] == 3'b110);

/* Сохраненный опкод */
reg  [ 7:0] latch      = 8'h00;
wire [ 7:0] opcode     = t ? latch : pin_i;
reg  [ 7:0] opcode_ext = 8'h00;
reg         prev_intr  = 1'b0;
wire [15:0] pc8rel     = pc + 1 + {{8{pin_i[7]}}, pin_i[7:0]};

/* Управляющие регистры */
reg  [15:0] pc = 16'h0000;
reg  [ 7:0] i  = 8'h00;     // Вектор пользовательского прерывания
reg  [ 1:0] im = 2'b01;     // Interrupt Mode (IM 1)
wire        cc;             // Исполнение условия NZ,Z,NC,C
wire        ccc;

// ---------------------------------------------------------------------
// Управление записью в регистры
// ---------------------------------------------------------------------

/* Префиксы IX, IY */
reg         pe      = 1'b0;     // Наличие префикса
reg         pe_     = 1'b0;     // Защелка префикса
reg         pex     = 1'b0;     // Временно
reg         pem     = 1'b0;     // 0=IX, 1=IY

/* Регистры */
reg   [2:0] cmd     = 3'b000;   // Особая инструкция для регистров
reg         reg_b   = 1'b0;     // Сигнал на запись 8 битного регистра
reg         reg_w   = 1'b0;     // Сигнал на запись 16 битного регистра (reg_u:reg_v)
reg         flg_w   = 1'b0;     // Сигнал записи флагов
reg  [ 2:0] reg_n   = 3'h0;     // Номер регистра
reg  [ 7:0] reg_l   = 8'h00;    // Что писать в [ 7:0]
reg  [ 7:0] reg_u   = 8'h00;    // Что писать в [15:8]
reg  [ 7:0] fw      = 8'h00;    // Что писать во флаги
wire [ 7:0] r8;                 // reg_r8  = regs8 [ reg_n ]
wire [15:0] r16;                // reg_r16 = regs16[ reg_n ]

/* Регистры общего назначения */
wire [ 7:0] a;
wire [ 7:0] f;
wire [15:0] bc; wire [15:0] de;
wire [15:0] hl; wire [15:0] sp;

regs REGS
(
    // Управление
    pin_clk, opcode,
    // Регистры и флаги
    reg_b, reg_w, flg_w, reg_n, reg_l, reg_u, fw, r8, r16, cmd,
    // Префиксы
    pe, pem,
    // Данные
    a, f, bc, de, hl, sp,
    // Результирующие условия
    cc, ccc
);

// ---------------------------------------------------------------------
// Арифметическое-логическое устройство
// ---------------------------------------------------------------------

reg  [ 4:0] alu_m = 0;      // Режим работы АЛУ
wire [ 8:0] alu_r;          // Результат вычислений
wire [ 7:0] alu_f;          // Результат флагов
wire [16:0] alu_r16;        // Результат 16-битный
reg  [ 7:0] op1 = 0;        // Первый операнд
reg  [ 7:0] op2 = 0;        // Второй операнд
reg  [15:0] op1w = 0;       // 16-битный операнд 1
reg  [15:0] op2w = 0;       // 16-битный операнд 2
wire [ 5:0] ldi_xy;         // Для LDxx инструкции

alu  ALU(alu_m, a, f, op1, op2, op1w, op2w, alu_r, alu_f, alu_r16, ldi_xy);

// Прерывания
// ---------------------------------------------------------------------
reg  pend_require = 0;
reg  pend_reset   = 0;
wire pend_int     = (pend_require ^ pend_reset);

/* Исполнение инструкции */
// ---------------------------------------------------------------------
always @(posedge pin_clk) begin

    /* Регистрация позитивного фронта intr (прерывания) */
    if ({prev_intr, pin_intr} == 2'b01) begin

        // Если прерывание есть, то если pend_int=1; pend_int=0 -> 1
        if (iff1)
             pend_require <= (pend_int ? pend_require : pend_require ^ 1);
        /* А надо ли? Процессор все равно снимет флаг pend_int
        else pend_require <= (pend_int ? pend_require ^ 1 : pend_require);
        */

    end

    /* Сброс процессора */
    if (pin_reset) begin

        pc  <= 0;
        im  <= 2'b01;
        t   <= 0;
        pe_ <= 0;
        irq <= 0;
        halt <= 0;

        iff1 <= 0; iff1_ <= 0;
        iff2 <= 0; iff2_ <= 0;

        // Сброс PEND_INT -> 0
        pend_reset <= pend_int ? (pend_reset ^ 1) : pend_reset;
        Z80_Delay  <= 3;

    end

    /* Исполнительная логика */
    else begin

        /* Подготовка управляющих сигналов */
        alt     <= 1'b0;
        reg_b   <= 1'b0;
        reg_w   <= 1'b0;
        flg_w   <= 1'b0;
        pin_enw <= 1'b0;
        pin_pw  <= 1'b0;
        cmd     <= 3'b000;

        /* Задержка для совместимости с Z80 по тактам */
        if (Z80_Delay) Z80_Delay <= Z80_Delay - 1;

        /* Обработка IRQ: IM=0,1,2 */
        else if (irq) begin

            iff1 <= 0; iff1_ <= 0;
            iff2 <= 0; iff2_ <= 0;

            case (irq)

                1: begin irq <= 2; cursor <= sp; if (im == 0) pc <= pc + 1; r <= rh; end
                2: begin irq <= 3; cursor <= cursor - 1; pin_o <= pc[15:8]; pin_enw <= 1; alt <= 1; end
                3: begin irq <= 4; cursor <= cursor - 1; pin_o <= pc[ 7:0]; pin_enw <= 1; alt <= 1; end
                4: begin irq <= 5; /* Сброс ALT=1 */ end
                5: begin irq <= (im == 2) ? 6 : 0;

                    reg_w  <= 1;
                    reg_n  <= `REG_SP;
                    pc     <= 8'h38;
                    {reg_u, reg_l} <= cursor;

                    alt    <= im == 2 ? 1 : 0;
                    cursor <= {i[7:0], 8'hFF};

                    if (im != 2) Z80_Delay <= (13-5);

                end
                6: begin irq <= 7; pc[7:0]  <= pin_i; cursor <= cursor + 1; alt <= 1; end
                7: begin irq <= 0; pc[15:8] <= pin_i; Z80_Delay <= 4; end

            endcase

        end

        /* Чтение опкода или префикса */
        else if (t == 0) begin

            /** Есть запрос прерывания?
             * - идет этап чтения опкода
             * - нет префикса у опкода
             * - Запуск RST #38 */

            if (pend_int && (pe_ == 0 || halt)) begin

                // Сброс pend_int=1->0, 0->0
                pend_reset <= pend_int ? (pend_reset ^ 1) : pend_reset;
                halt       <= 0;
                irq        <= 1; /* Вызов IRQ */

            end

            /* Первый такт инструкции */
            else if (halt == 0) begin

                r <= rh; // +1 регенерация

                case (pin_i)

                /* Обработка префиксов IX, IY занимает +4T */
                8'hDD: begin pe_ <= 1; pem <= 0; pc <= pc + 1; Z80_Delay <= 3; end
                8'hFD: begin pe_ <= 1; pem <= 1; pc <= pc + 1; Z80_Delay <= 3; end

                /* Запуск исполнения новой инструкции */
                default: begin

                    // Вынести в защелку
                    {pe, pe_} <= {pe_, 1'b0};
                    latch     <= pin_i;
                    pc        <= pc + 1;

                    // Переброс прерывания
                    iff1  <= iff1_; iff1_ <= ei ? 1'b1 : (di ? 1'b0 : iff1_);
                    iff2  <= iff2_; iff2_ <= ei ? 1'b1 : (di ? 1'b0 : iff2_);
                    ei    <= 1'b0;
                    di    <= 1'b0;
                    t     <= 1;

                end

                endcase

            end

        end

        /* Дополнительные такты */
        else casex (opcode)

            /* NOP */
            8'b00_000_000: begin t <= 0; Z80_Delay <= (4-1-1); end

            /* DJNZ * */
            8'b00_010_000: case (t)

                1: begin t <= 2; reg_b <= 1; reg_n <= `REG_B; reg_l <= bc[15:8] - 1; end
                2: begin t <= 0; pc <= bc[15:8] ? pc8rel : (pc + 1); Z80_Delay <= bc[15:8] ? (13-2-1) : (8-2-1); end

            endcase

            /* JR cc, * | JR * */
            8'b00_011_000,
            8'b00_1xx_000: begin t <= 0; pc <= cc ? pc8rel : (pc + 1); Z80_Delay <= cc ? (12-1-1) : (7-1-1); end

            /* EX AF, AF' */
            8'b00_001_000: begin t <= 0; cmd <= `CMD_EXAF; Z80_Delay <= 2; end

            /* LD r, i16 */
            8'b00_xx0_001: case (t)

                1: begin t <= 2; reg_l <= pin_i; pc <= pc + 1; reg_n <= opcode[5:4]; end
                2: begin t <= 3; reg_u <= pin_i; pc <= pc + 1; end
                3: begin t <= 0; reg_w <= 1'b1;  Z80_Delay <= (10-3-1); end

            endcase

            /* ADD HL|IX|IY, r16 */
            8'b00_xx1_001: case (t)

                1: begin t <= 2; op1w <= hl;  reg_n <= opcode[5:4]; end
                2: begin t <= 3; op2w <= r16; alu_m <= `ALU_ADDW; end
                3: begin t <= 0;

                    {fw, reg_u, reg_l} <= {alu_f[7:0], alu_r16[15:0]};

                    reg_w <= 1;
                    flg_w <= 1;
                    reg_n <= `REG_HL;

                    Z80_Delay <= (11-3-1);

                end

            endcase

            /* LD (BC|DE), A */
            8'b00_0x0_010: case (t)

                1: begin t <= 2; cursor <= opcode[4] ? de : bc; alt <= 1; pin_o <= a; pin_enw <= 1; end
                2: begin t <= 0; Z80_Delay <= (7-2-1); end

            endcase

            /* LD A, (BC|DE) */
            8'b00_0x1_010: case (t)

                1: begin t <= 2; cursor <= opcode[4] ? de : bc; alt <= 1; end
                2: begin t <= 0; reg_b <= 1; reg_l <= pin_i; reg_n <= `REG_A; Z80_Delay <= (7-2-1); end

            endcase

            /* LD (**), HL|IX|IY */
            8'b00_100_010: case (t)

                1: begin t <= 2; pc <= pc + 1; cursor[7:0]  <= pin_i;    end
                2: begin t <= 3; pin_enw <= 1; cursor[15:8] <= pin_i;    alt <= 1; pin_o <= hl[ 7:0]; end
                3: begin t <= 4; pin_enw <= 1; cursor       <= cursor+1; alt <= 1; pin_o <= hl[15:8]; end
                4: begin t <= 0; pc <= pc + 1; Z80_Delay    <= (16-4-1); end

            endcase

            /* LD HL|IX|IY, (**) */
            8'b00_101_010: case (t)

                1: begin t <= 2; pc <= pc + 1; cursor[ 7:0] <= pin_i; end
                2: begin t <= 3; pc <= pc + 1; cursor[15:8] <= pin_i;         alt <= 1; end
                3: begin t <= 4; reg_b <= 1; reg_n <= `REG_L; reg_l <= pin_i; alt <= 1; cursor <= cursor+1; end
                4: begin t <= 0; reg_b <= 1; reg_n <= `REG_H; reg_l <= pin_i; Z80_Delay <= (16-4-1); end

            endcase

            /* LD (**), A */
            8'b00_110_010: case (t)

                1: begin t <= 2; cursor[7:0]  <= pin_i; pc <= pc + 1; end
                2: begin t <= 3; cursor[15:8] <= pin_i; {alt, pin_enw, pin_o} <= {2'b11, a[7:0]}; end
                3: begin t <= 0; pc <= pc + 1; Z80_Delay <= (13-3-1); end

            endcase

            /* LD A, (**) */
            8'b00_111_010: case (t)

                1: begin t <= 2; pc <= pc + 1; cursor[ 7:0] <= pin_i; end
                2: begin t <= 3; pc <= pc + 1; cursor[15:8] <= pin_i; alt <= 1; end
                3: begin t <= 0; reg_b <= 1; reg_n <= `REG_A; reg_l <= pin_i; Z80_Delay <= (13-3-1); end

            endcase

            /* INC|DEC r16 */
            8'b00_xxx_011: case (t)

                1: begin t <= 2; reg_n <= opcode[5:4]; end
                2: begin t <= 0; /* Инкремент-декремент и запись */

                    {reg_u, reg_l} <= opcode[3] ? r16 - 1 : r16 + 1;
                    reg_w     <= 1;
                    Z80_Delay <= (6-2-1);

                end

            endcase

            /* INC|DEC (HL|IX|IY) */
            8'b00_110_10x: case (t)

                /* Загрузка курсора и активация номера регистра */
                1: begin t <= pe ? 2 : 3; cursor <= hl; alt <= !pe; end
                /* Прибавление `+d` при IX/IY */
                2: begin t <= 3;

                    pc     <= pc + 1;
                    cursor <= xof;
                    alt    <= 1;
                    r      <= rh;

                end
                /* Загрузка значения из (HL|IX+d|IY+d) */
                3: begin t <= 4;

                    op1   <= pin_i;
                    alu_m <= opcode[0] ? `ALU_DEC : `ALU_INC;

                end
                /* Запись либо в память, либо в регистр */
                4: begin t <= 5;

                    alt     <= 1;       // Выбрать cursor
                    pin_enw <= 1;       // Пишется в память, если выбран HL
                    flg_w   <= 1;       // Запись во флаги
                    pin_o   <= alu_r;   // Для записи в память
                    fw      <= alu_f;   // Для записи во флаги

                end
                /* Завершение */
                5: begin t <= 0; Z80_Delay <= pe ? (18-4-1) : (11-4-1); end

            endcase

            /* INC|DEC r8 */
            8'b00_xxx_10x: case (t)

                1: begin t <= 2; reg_n <= opcode[5:3]; end
                2: begin t <= 3; op1   <= r8; alu_m <= opcode[0] ? `ALU_DEC : `ALU_INC; end
                3: begin t <= 0; reg_b <= 1;  flg_w <= 1; reg_l <= alu_r; fw <= alu_f; end

            endcase

            /* LD (HL|IX|IY), i8 */
            8'b00_110_110: case (t)

                1: begin t <= pe ? 2 : 3; cursor <= hl; end
                2: begin t <= 3; pc <= pc + 1; cursor <= xof; end
                3: begin t <= 4; pc <= pc + 1; pin_enw <= 1; pin_o <= pin_i; alt <= 1; end
                4: begin t <= 0; Z80_Delay <= pe ? (16-5-1) : (10-3-1); end

            endcase

            /* LD r8, i8 */
            8'b00_xxx_110: case (t)

                1: begin t <= 2; reg_n <= opcode[5:3]; end
                2: begin t <= 0; reg_b <= 1; reg_l <= pin_i; pc <= pc + 1; Z80_Delay <= (7-2-1); end

            endcase

            /* RLCA, RRCA, RLA, RRA, DAA, CPL, SCF, CCF */
            8'b00_xxx_111: case (t)

                1: begin t <= 2; alu_m <= {1'b1, opcode[5:3]}; op1 <= a; end
                2: begin t <= 0; Z80_Delay <= (4-2-1);

                    reg_b <= 1;
                    flg_w <= 1;
                    reg_n <= `REG_A;
                    reg_l <= alu_r;

                    // Особая логика в RLCA | RRCA | RLA | RRA
                    /*  S Z       P
                        S Z Y H X P N C
                        7 6 5 4 3 2 1 0
                    */
                    if (opcode[5] == 1'b0)
                         fw <= {f[7:6], alu_f[5:3], f[2], alu_f[1:0]};
                    else fw <= alu_f;


                end

            endcase

            /** === СЕКЦИЯ LD r8, r8 и <ALU> A, r8 === */

            /* HALT */
            8'b01_110_110: begin t <= 0; halt <= 1; Z80_Delay <= (4-1-1); end

            /* LD r8, (HL|IX|IY) */
            8'b01_xxx_110: case (t)

                // Выбор источника hl,ix,iy
                1: begin t <= pe ? 2 : 3;

                    cursor <=  hl;
                    alt    <= !pe;

                end
                // Прочитать +d8
                2: begin t <= 3;

                    cursor <= xof;
                    alt    <= 1;
                    pc     <= pc + 1;
                    r      <= rh;

                end
                // Запись в регистр
                3: begin t <= 0;

                    pe    <= 0;     // Не записывать в IXH/IXL/IYH/IYL
                    reg_b <= 1;
                    reg_n <= opcode[5:3];
                    reg_l <= pin_i;

                    Z80_Delay <= pe ? (15-3-1) : (7-3);

                end

            endcase

            /* LD (HL|IX|IY), r8 */
            8'b01_110_xxx: case (t)

                // Если есть префикс, то прочитать +d8
                1: begin t <= pe ? 2 : 3;

                    pex    <= pe;
                    cursor <= hl;
                    reg_n  <= opcode[2:0];

                end
                // Читать +d8 и выключить префикс
                2: begin t <= 3;

                    cursor <= xof;
                    pc     <= pc + 1;
                    r      <= rh;
                    pe     <= 0;

                end
                // Запись в память и выход
                3: begin t <= 0;

                    alt       <= 1;
                    pin_o     <= r8;
                    pin_enw   <= 1;
                    pe        <= pex;
                    Z80_Delay <= pex ? (15-3-1) : (7-4);

                end

            endcase

            /* LD r8, r8 */
            8'b01_xxx_xxx: case (t)

                1: begin t <= 2; reg_n <= opcode[2:0]; end
                2: begin t <= 0; reg_n <= opcode[5:3]; reg_b <= 1; reg_l <= r8; Z80_Delay <= (4-2-1); end

            endcase

            /* <ALU> A, (HL) */
            8'b10_xxx_110: case (t)

                // Выбор памяти и номера функции
                1: begin t <= pe ? 2 : 3;

                    cursor  <=  hl;
                    alt     <= !pe;
                    op1     <= a;
                    alu_m   <= opcode[5:3];

                end
                // Прочитать +d8
                2: begin t <= 3;

                    cursor <= xof;
                    pc     <= pc + 1;
                    r      <= rh;
                    alt    <= 1;

                end
                // Чтение второго операнда
                3: begin t <= 4; op2 <= pin_i; end
                // Запись в регистр
                4: begin t <= 0;

                    reg_n <= `REG_A;
                    reg_b <= (alu_m != `ALU_CP);
                    flg_w <= 1;
                    reg_l <= alu_r;
                    fw    <= alu_f;

                    Z80_Delay <= pe ? (15-4-1) : (7-4);

                end

            endcase

            /* <ALU> A, r */
            8'b10_xxx_xxx: case (t)

                1: begin t <= 2; op1 <= a;  reg_n <= opcode[2:0]; end
                2: begin t <= 3; op2 <= r8; alu_m <= opcode[5:3]; end
                3: begin t <= 0;

                    reg_n <= `REG_A;
                    reg_b <= (alu_m != `ALU_CP);
                    flg_w <= 1;
                    reg_l <= alu_r;
                    fw    <= alu_f;

                end

            endcase

            // === УПРАВЛЯЮЩИЕ ИНСТРУКЦИИ ===

            /* RET c | RET */
            8'b11_001_001,
            8'b11_xxx_000: case (t)

                1: begin t <= ccc ? 2 : 0; /* Либо переход либо пропуск */

                    alt       <= ccc;
                    cursor    <= sp;
                    Z80_Delay <= ccc ? 0 : (5-1-1);

                end
                2: begin t <= 3; /* Указатель PCL */

                    alt      <= 1;
                    pc[ 7:0] <= pin_i;
                    cursor   <= cursor + 1;

                end
                3: begin t <= 0; /* Указатель PCH */

                    pc[15:8] <= pin_i;
                    reg_n    <= `REG_SP;
                    reg_w    <= 1;

                    {reg_u, reg_l} <= cursor + 1;
                    Z80_Delay <= (11-3-1);

                end

            endcase

            /* POP r16 */
            8'b11_xx0_001: case (t)

                1: begin t <= 2; cursor <= sp; alt <= 1; end
                2: begin t <= 3; /* Чтение L */

                    alt    <= 1;
                    cursor <= cursor + 1;
                    reg_l  <= pin_i;

                end
                3: begin t <= 4; /* Чтение H и запись в регистр 16-бит */

                    cursor <= cursor + 1;
                    reg_u  <= pin_i;
                    reg_w  <= 1;
                    reg_n  <= opcode[5:4] == 2'b11 ? `REG_AF : opcode[5:4];

                end
                4: begin t <= 0; /* Установка SP */

                    reg_n <= `REG_SP;
                    reg_w <= 1;
                    {reg_u, reg_l} <= cursor;

                    Z80_Delay <= (10-4-1);

                end

            endcase

            /* JP c, ** | JP ** */
            8'b11_000_011,
            8'b11_xxx_010: case (t)

                1: begin t <= 2; reg_l <= pin_i; pc <= pc + 1'b1; end
                2: begin t <= 3; reg_u <= pin_i; pc <= pc + 1'b1; end
                3: begin t <= 0; if (ccc) pc <= {reg_u, reg_l}; Z80_Delay <= (10-3-1); end

            endcase

            /* OUT (*), A */
            8'b11_010_011: begin t <= 0;

                pin_pa <= pin_i;
                pin_po <= a;
                pin_pw <= 1;
                pc     <= pc + 1;
                Z80_Delay <= (11-1-1);

            end

            /* IN  A, (*) */
            8'b11_011_011: case (t)

                1: begin t <= 2; pin_pa <= pin_i;  pc <= pc + 1; end
                2: begin t <= 0;

                    reg_b <= 1;
                    reg_n <= `REG_A;
                    reg_l <= pin_pi;

                    Z80_Delay <= (11-2-1);

                end

            endcase

            /* EX (SP), HL */
            8'b11_100_011: case (t)

                1: begin t <= 2; alt <= 1; cursor <= sp; end
                2: begin t <= 3; alt <= 1; reg_l  <= pin_i; pin_o <= hl[7:0]; pin_enw <= 1; end
                3: begin t <= 4; alt <= 1; cursor <= cursor + 1; end
                4: begin t <= 5;

                    alt     <= 1;
                    reg_w   <= 1;
                    reg_u   <= pin_i;
                    reg_n   <= `REG_HL;
                    pin_o   <= hl[15:8];
                    pin_enw <= 1;

                end

                5: begin t <= 0; Z80_Delay <= (19-5-1); end

            endcase

            /* CALL c, ** */
            8'b11_001_101,
            8'b11_xxx_100: case (t)

                1: begin t <= 2; /* Читать L */

                    reg_l <= pin_i;
                    pc    <= pc + 1;

                end
                2: begin t <= ccc ? 3 : 0; /* Читать H */

                    reg_u     <= pin_i;
                    pc        <= pc + 1;
                    cursor    <= sp;
                    Z80_Delay <= ccc ? 0 : (10-2-1);

                end

                /* Записать адрес PC в стек. Писать будет в SP-1=H, SP-2=L */
                3: begin t <= 4; cursor <= cursor - 1; pin_o <= pc[15:8]; pin_enw <= 1; alt <= 1; end
                4: begin t <= 5; cursor <= cursor - 1; pin_o <= pc[ 7:0]; pin_enw <= 1; alt <= 1; end
                5: begin t <= 0; /* Переход по адресу и SP=SP-2 */

                    pc <= {reg_u, reg_l};

                    reg_w <= 1;
                    reg_n <= `REG_SP;

                    {reg_u, reg_l} <= cursor;
                    Z80_Delay      <= (17-5-1);

                end

            endcase

            /* PUSH r16 */
            8'b11_xx0_101: case (t)

                1: begin t <= 2; /* Выбор 16-битного регистра */

                    reg_n  <= opcode[5:4] == 2'b11 ? `REG_AF : opcode[5:4];
                    cursor <= sp;

                end
                /* Запись в стек */
                2: begin t <= 3; cursor <= cursor - 1; pin_o <= r16[15:8]; pin_enw <= 1; alt <= 1; end
                3: begin t <= 4; cursor <= cursor - 1; pin_o <= r16[ 7:0]; pin_enw <= 1; alt <= 1; end
                4: begin t <= 0; /* SP = SP - 2 */

                    reg_w <= 1;
                    reg_n <= `REG_SP;
                    {reg_u, reg_l} <= cursor;
                    Z80_Delay      <= (11-4-1);

                end

            endcase

            /* <alu> A, i8 */
            8'b11_xxx_110: case (t)

                1: begin t <= 2; /* Инициализация операндов */

                    op1   <= a;
                    op2   <= pin_i;
                    alu_m <= opcode[5:3];
                    pc    <= pc + 1;

                end
                2: begin t <= 0; /* Запись в A и флаги */

                    reg_n <= `REG_A;
                    reg_b <= (alu_m != `ALU_CP);
                    flg_w <= 1;
                    reg_l <= alu_r;
                    fw    <= alu_f;

                    Z80_Delay <= (7-2-1);

                end

            endcase

            /* RST #FF */
            8'b11_xxx_111: case (t)

                1: begin t <= 2; cursor <= sp; end
                2: begin t <= 3; cursor <= cursor - 1; pin_o <= pc[15:8]; pin_enw <= 1; alt <= 1; end
                3: begin t <= 4; cursor <= cursor - 1; pin_o <= pc[ 7:0]; pin_enw <= 1; alt <= 1; end
                4: begin t <= 0; /* SP = SP-2 и переход по адресу прерывания */

                    reg_w  <= 1;
                    reg_n  <= `REG_SP;
                    pc     <= {opcode[5:3], 3'b000};

                    {reg_u, reg_l} <= cursor;
                    Z80_Delay      <= (11-4-1);

                end

            endcase

            /* === Специальные инструкции === */

            /* DI, EI */
            8'b11_11x_011: begin t <= 0; ei <= opcode[3]; di <= !opcode[3]; Z80_Delay <= (4-1-1); end

            /* EX DE, HL */
            8'b11_101_011: begin t <= 0; cmd <= `CMD_EXDEHL; Z80_Delay <= (4-1-1); end

            /* EXX */
            8'b11_011_001: begin t <= 0; cmd <= `CMD_EXX; Z80_Delay <= (4-1-1); end

            /* JP (HL) */
            8'b11_101_001: begin t <= 0; pc <= hl; Z80_Delay <= (4-1-1); end

            /* LD SP, HL */
            8'b11_111_001: begin t <= 0; reg_n <= `REG_SP; reg_w <= 1; {reg_u, reg_l} <= hl; Z80_Delay <= (6-1-1); end

            /* === ПРЕФИКСЫ РАСШИРЕНИЯ === */

            /* CB: Битовые операции */
            8'b11_001_011: case (t)

                1: begin t <= pe ? 2 : 3; cursor <= hl;  r <= rh; end
                2: begin t <= 3; r <= rh; cursor <= xof; pc <= pc + 1; end
                3: begin t <= 4; /* Запись расширенного опкода */

                     alt        <= pe || (pin_i[2:0] == 3'b110);
                     reg_n      <= pin_i[2:0];   // Номер регистра 8 бит
                     opcode_ext <= pin_i;
                     pc         <= pc + 1;

                end
                4: begin t <= 5; /* Запрос к АЛУ для вычисления */

                    // Операнд может идти из памяти (IX+d) или из (HL) или из reg
                    op1 <= (pe || cbhl) ? pin_i : r8;

                    // [5:3] Для bit, res[6]=0, set[6]=1
                    op2 <= {opcode_ext[6:3]};

                    // Выбор режима
                    casex (opcode_ext)

                        // Инструкции RLC, RRC, RL, RR
                        8'b00_0xx_xxx: alu_m <= {3'b010, opcode_ext[4:3]};

                        // Инструкции SLA, SRA, SLL, SRL
                        8'b00_1xx_xxx: alu_m <= {3'b100, opcode_ext[4:3]};

                        // Инструкции 101xx: 101[01]=BIT, 101[10]=RES, 101[11]=SET
                              default: alu_m <= {3'b101, opcode_ext[7:6]};

                    endcase

                end
                5: begin t <= 6; /* Запись результата */

                     flg_w <= 1;
                     fw    <= alu_f;

                     // Результат не писать, если это BIT
                     if (alu_m != `ALU_BIT) begin

                         pex     <= pe;
                         pe      <= 0; /* Записать в валидный 8-бит */
                         reg_b   <= !(cbhl);
                         pin_enw <=  (cbhl);
                         alt     <=  (cbhl);
                         pin_o   <= alu_r;
                         reg_l   <= alu_r;

                     end

                end
                6: begin t <= 0; alt <= 0; /* Вычисление задержки в тактах */

                    // iXY | HL  | R8
                    // 20T | 12T | 8T => Если BIT
                    // 23T | 15T | 8T => Все остальные

                    if (alu_m == `ALU_BIT)
                         Z80_Delay <= pex ? (16-6-1) : (cbhl ? (12-6) : (8-6));
                    else Z80_Delay <= pex ? (19-6-1) : (cbhl ? (15-6) : (8-6));


                end

            endcase

            /* ED: Расширения не используют префиксы */
            8'b11_101_101: case (t)

                1: begin t <= 2; r <= rh; opcode_ext <= pin_i; m <= 0; pe <= 0; pc <= pc + 1; end
                2: casex (opcode_ext)

                    /* IN r8, (C) */
                    8'b01_xxx_000: case (m)

                        0: begin m <= 1; pin_pa <= bc; end
                        1: begin t <= 0;

                            fw = { // Подготовка флагов на запись

                                /* S */ pin_pi[7],
                                /* Z */ pin_pi == 0,
                                /* 0 */ pin_pi[5],
                                /* H */ 1'b0,
                                /* 0 */ pin_pi[3],
                                /* P */ ~^pin_pi,
                                /* N */ 1'b0,
                                /* C */ op1[7]
                            };

                            flg_w <= 1;

                            // Писать в регистр, только если не (HL)
                            reg_b <= opcode_ext[5:3] != 3'b110;
                            reg_n <= opcode_ext[5:3];
                            reg_l <= pin_pi;

                            Z80_Delay <= (12-4);

                        end

                    endcase

                    /* OUT (C), r8 */
                    8'b01_xxx_001: case (m)

                        0: begin m <= 1; pin_pa <= bc; reg_n <= opcode_ext[5:3]; end
                        1: begin t <= 0;

                            pin_po    <= (reg_n == 3'b110) ? 0 : r8;
                            pin_pw    <= 1;
                            Z80_Delay <= (12-4);

                        end

                    endcase

                    /* ADC|SBC HL, r16 */
                    8'b01_xxx_010: case (m)

                        0: begin m <= 1; op1w <= hl;  reg_n <= opcode_ext[5:4]; end
                        1: begin m <= 2; op2w <= r16; alu_m <= opcode_ext[3] ? `ALU_ADCW : `ALU_SBCW; end
                        2: begin t <= 0;

                            reg_n <= `REG_HL;
                            reg_w <= 1;
                            flg_w <= 1;

                            {reg_u, reg_l} <= alu_r16;
                            fw <= alu_f;

                            Z80_Delay <= (15 - 5);

                        end

                    endcase

                    /* LD I/R/A */
                    8'b0100_0111: begin t <= 0; i <= a; Z80_Delay <= (9-3); end
                    8'b0100_1111: begin t <= 0; r <= a; Z80_Delay <= (9-3); end
                    8'b0101_0111: begin t <= 0; reg_b <= 1; reg_n <= `REG_A; reg_l <= i; Z80_Delay <= (9-3); end
                    8'b0101_1111: begin t <= 0; reg_b <= 1; reg_n <= `REG_A; reg_l <= r; Z80_Delay <= (9-3); end

                    /* IM n */
                    8'b01_xxx_110: begin t <= 0; im <= opcode_ext[3] ? (opcode_ext[4] ? 2 : a[0]) : opcode_ext[4]; Z80_Delay <= (8-3); end

                    /* NEG */
                    8'b01_xxx_100: case (m)

                        0: begin m <= 1; op1 <= 0; op2 <= a; alu_m <= `ALU_SUB; end
                        1: begin t <= 0;

                            reg_b <= 1;
                            flg_w <= 1;
                            reg_n <= `REG_A;
                            reg_l <= alu_r;
                            fw    <= alu_f;

                            Z80_Delay <= (8-3-1);

                        end

                    endcase

                    /* RETN */
                    8'b01_xxx_101: case (m)

                        0: begin m <= 1; alt <= 1;                    cursor <= sp; end
                        1: begin m <= 2; alt <= 1; pc[ 7:0] <= pin_i; cursor <= cursor + 1; end
                        2: begin t <= 0;           pc[15:8] <= pin_i; {reg_u, reg_l} <= cursor + 1;

                            reg_n <= `REG_SP;
                            reg_w <= 1;

                            // Только если это - RETN
                            if (opcode_ext[5:3] != 3'b001) begin

                                iff1  <= iff2;
                                iff1_ <= iff2_;

                            end

                            Z80_Delay <= (14-5);

                        end

                    endcase

                    /* LD (**), r16 */
                    8'b01_xx0_011: case (m)

                        0: begin m <= 1; // Читать L

                            cursor[7:0] <= pin_i;
                            reg_n <= opcode_ext[5:4];
                            pc    <= pc + 1;

                        end
                        1: begin m <= 2; // Читать H, писать L

                            cursor[15:8] <= pin_i;
                            pc      <= pc + 1;
                            pin_o   <= r16[7:0];
                            pin_enw <= 1;
                            alt     <= 1;

                        end

                        2: begin t <= 0; // Писать H

                            cursor  <= cursor + 1;
                            pin_o   <= r16[15:8];
                            pin_enw <= 1;
                            alt     <= 1;
                            Z80_Delay <= (20-5);

                        end

                    endcase

                    /* LD r16, (**) */
                    8'b01_xx1_011: case (m)

                        0: begin m <= 1; cursor[7:0]  <= pin_i; pc <= pc + 1;   reg_n <= opcode_ext[5:4]; end
                        1: begin m <= 2; cursor[15:8] <= pin_i; pc <= pc + 1;   alt   <= 1; end
                        2: begin m <= 3; cursor <= cursor + 1;  reg_l <= pin_i; alt   <= 1; end
                        3: begin t <= 0; Z80_Delay <= (20-6);   reg_u <= pin_i; reg_w <= 1;  end

                    endcase

                    /* RRD | RLD */
                    8'b01_10x_111: case (m)

                        0: begin m <= 1; cursor <= hl; alt <= 1; end
                        1: begin m <= 2;

                            // 1=RLD, 0=RRD
                            reg_b <= 1;
                            reg_n <= `REG_A;               // RLD          RRD
                            reg_l <= {a[7:4], opcode_ext[3] ? pin_i[7:4] : pin_i[3:0]};

                            // На выход на запись
                            alt     <= 1;
                            pin_enw <= 1;
                            pin_o   <= opcode_ext[3] ? {pin_i[3:0],     a[3:0]} : // RLD
                                                       {    a[3:0], pin_i[7:4]};  // RRD

                        end

                        // Вычислить из записать флаги
                        2: begin m <= 3; op1 <= a; alu_m <= `ALU_RRLD; end
                        3: begin t <= 0; flg_w <= 1; fw <= alu_f; Z80_Delay <= (18-6); end

                    endcase

                    /* LDI | LDIR | LDD | LDDR */
                    8'b101x_x000: case (m)

                        0: begin m <= 1; cursor <= hl; alt <= 1; end
                        1: begin m <= 2; cursor <= de; alt <= 1; pin_o <= pin_i; pin_enw <= 1; op1 <= pin_i; end
                        2: begin m <= 3; cmd <= opcode_ext[3] ? `CMD_DEC : `CMD_INC; end
                        3: begin t <= 0;

                            // Если есть REP и (BC != 0) ==> PC -= 2
                            if (opcode_ext[4] && bc) begin

                                pc        <= pc - 2;
                                Z80_Delay <= (21-6);

                            end else Z80_Delay <= (16-6);

                            /* Обновление флагов после LD(I|IR|D|DR) */
                            flg_w <= 1;
                            fw    <= {

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

                    default: begin /* ERROR */ end

                endcase

            endcase

        endcase

    end

    /* Сохранить предыдущее значение pin_intr для теста __/ сигнала */
    prev_intr <= pin_intr;

end

endmodule
