module z80(

    input       wire        clock,
    input       wire [7:0]  i_data,
    output      wire [15:0] address,
    output      reg         we,
    output      reg  [7:0]  o_data
);

assign address = bus ? cursor : pc;

initial begin we = 0; o_data = 0; end

localparam

    // Флаги
    CF = 8, NF = 9, PF = 10, AF = 12, ZF = 14, SF = 15,

    // Базовый набор
    ALU_ADD  = 0, ALU_ADC  = 1,
    ALU_SUB  = 2, ALU_SBC  = 3,
    ALU_AND  = 4, ALU_XOR  = 5,
    ALU_OR   = 6, ALU_CP   = 7,

    // Дополнительный набор
    ALU_RLC = 8,  ALU_RRC  = 9,
    ALU_RL  = 10, ALU_RR   = 11,
    ALU_DAA = 12, ALU_CPL  = 13,
    ALU_SCF = 14, ALU_CCF  = 15,

    // Сдвиги и биты
    ALU_SLA = 16, ALU_SRA = 17,
    ALU_SLL = 18, ALU_SRL = 19,
    ALU_BIT = 20, ALU_RES = 21,
    ALU_SET = 22,

    // Расширенные
    ALU_INC  = 24, ALU_DEC  = 25,
    ALU_ADDW = 26, ALU_SUBW = 27,
    ALU_ADCW = 28, ALU_SBCW = 29,
    ALU_RRLD = 30;


// Состяние процессора
// ---------------------------------------------------------------------
reg [ 3:0] t_state = 0;
reg [ 7:0] opcode_latch = 0;
reg        bus     = 0;

// Текущий опкод
wire [ 7:0] opcode = t_state ? opcode_latch : i_data;

// Список регистров
// ---------------------------------------------------------------------

reg [15:0] pc = 16'h0000;
reg [15:0] bc = 16'h0000;
reg [15:0] de = 16'h0000;
reg [15:0] hl = 16'h0002;
reg [15:0] af = 16'h0000;
reg [15:0] sp = 16'h0000;

// Устройство управления
// ---------------------------------------------------------------------

// Вспомогательный провод для определения что это t_state=0
wire        is_tstate0 = (t_state == 0);

// Источник данных для записи 8 бит
// =1 АЛУ
// =0 Шина данных
wire [ 7:0] data8_src = (is_source == 1) ? alu_r : i_data;

// По умолчанию курсор находится в HL
wire [15:0] cursor    = hl;

`include "alu.v"
`include "mcode.v"

// Синхронная логика
// ---------------------------------------------------------------------
always @(posedge clock) begin

    // Защелкиваем опкод, если он на t_state=0
    if (is_tstate0) opcode_latch <= i_data;

    // Работа с регистром PC
    if (is_pcinc) pc <= pc + 1;

    // Считать t_state
    t_state <= is_instr_end ? 0 : t_state + 1;

    // Инкремент или декремент
    if (is_inc16)
    case (is_reg_dst[1:0])

        2'b00: bc <= is_dec16 ? bc - 1 : bc + 1;
        2'b01: de <= is_dec16 ? de - 1 : de + 1;
        2'b10: hl <= is_dec16 ? hl - 1 : hl + 1;
        2'b11: sp <= is_dec16 ? sp - 1 : sp + 1;

    endcase
    // Запись в регистры
    else if (is_reg8_w)
    case (is_reg_dst)

        // Общие регистры
        0: bc[15:8] <= data8_src;
        1: bc[ 7:0] <= data8_src;
        2: de[15:8] <= data8_src;
        3: de[ 7:0] <= data8_src;
        4: hl[15:8] <= data8_src;
        5: hl[ 7:0] <= data8_src;
        7: af[ 7:0] <= data8_src;
        // Специальные регистры
        8: sp[15:8] <= data8_src;
        9: sp[ 7:0] <= data8_src;

    endcase

    // Запись флагов
    if (is_flag_w == 1) af[15:8] <= alu_f;

    // Запись в память
    we      <= is_we;
    bus     <= is_bus;
    o_data  <= data8_src;

end

endmodule
