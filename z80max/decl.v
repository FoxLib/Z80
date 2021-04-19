// ---------------------------------------------------------------------
// Декларации
// ---------------------------------------------------------------------

`define CARRY       0
`define NEG         1
`define PARITY      2
`define AUX         4
`define ZERO        6
`define SIGN        7

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

`define REG_B       0
`define REG_C       1
`define REG_D       2
`define REG_E       3
`define REG_H       4
`define REG_L       5
`define REG_F       6
`define REG_A       7

// ---------------------------------------------------------------------
// Объявление регистров
// ---------------------------------------------------------------------

// Основной набор
reg  [7:0]   r8[8];

// Для отладчика
wire [ 7:0]  b = r8[0];
wire [ 7:0]  c = r8[1];
wire [ 7:0]  d = r8[2];
wire [ 7:0]  e = r8[3];
wire [ 7:0]  h = r8[4];
wire [ 7:0]  l = r8[5];
wire [ 7:0]  f = r8[6]; // Здесь обычно (HL)
wire [ 7:0]  a = r8[7];

// Специальные
reg [ 7:0]  i = 8'h00;
reg [ 7:0]  r = 8'h00;

// Управляющие регистры
reg [15:0]  pc = 16'h0000;
reg [15:0]  sp = 16'hdffe;
reg [15:0]  ix = 16'h0000;
reg [15:0]  iy = 16'h0000;
reg [ 1:0]  imode = 2'b00;
reg         iff1;
reg         iff2;

// 8x8 Дополнительный набор регистров
reg [63:0]  prime;

// ---------------------------------------------------------------------
// Внутреннее состояние процессора
// ---------------------------------------------------------------------

// Фаза исполнения инструкции
reg [ 4:0]  t_state = 1'b0;

// Указатель шины. Если =1, то указывает на `cc`, иначе на `pc`
reg         bus = 1'b0;

// `cc` current cursor, указатель на память в случае bus=1
reg [15:0]  cc  = 16'h00;

// Задержка при получении данных от шины
reg [ 2:0]  latency = 2'h2;

// Защелка для хранения последнего опкода
reg [ 7:0]  opcode  = 8'hFF;

// Конвейер
reg [ 7:0]  d0;

// ---------------------------------------------------------------------
// Вычисления
// ---------------------------------------------------------------------

wire [3:0] condition = {
    r8[`REG_F][`SIGN],      // P,  M
    r8[`REG_F][`PARITY],    // PO, PE
    r8[`REG_F][`CARRY],     // C,  NC
    r8[`REG_F][`ZERO]       // Z,  NZ
};

// ---------------------------------------------------------------------
// Арифметическо-логическое устройство
// ---------------------------------------------------------------------

reg  [ 4:0] alu  = 8'h00;
reg  [ 7:0] op1  = 8'hFF;
reg  [ 7:0] op2  = 8'hFF;
reg  [15:0] op1w = 16'hFF;
reg  [15:0] op2w = 16'hFF;
wire [ 8:0] alu_r;
wire [16:0] alu_r16;
wire [ 7:0] alu_f;
wire [ 5:0] ldi_xy;

alu UnitALU(

    .alu_m  (alu),
    .a      (a),
    .f      (r8[6]),
    .op1    (op1),
    .op2    (op2),
    .op1w   (op1w),
    .op2w   (op2w),
    .alu_r  (alu_r),
    .alu_f  (alu_f),
    .alu_r16(alu_r16),
    .ldi_xy (ldi_xy)
);


// ---------------------------------------------------------------------
// Инициализация
// ---------------------------------------------------------------------

initial begin

    W  = 1'b0;
    DO = 8'h00;

    /* B */ r8[0] = 8'h00;
    /* C */ r8[1] = 8'h00;
    /* D */ r8[2] = 8'h00;
    /* E */ r8[3] = 8'h00;
    /* H */ r8[4] = 8'h00;
    /* L */ r8[5] = 8'h00;
    /* F */ r8[6] = 8'h00;
    /* A */ r8[7] = 8'h00;

    //           A  F  L  H  E  D  C  B
    prime = 64'hEE_00_00_00_00_00_00_00;

end
