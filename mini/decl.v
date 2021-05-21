
// Регистры
reg [15:0]  pc = 0;
reg [15:0]  sp = 0;

reg [15:0]  bc = 0; reg [15:0]  bc_ = 0;
reg [15:0]  de = 0; reg [15:0]  de_ = 0;
reg [15:0]  hl = 0; reg [15:0]  hl_ = 0;
reg [15:0]  af = 0; reg [15:0]  af_ = 0;

// Состояние процессора
reg         sel = 0;

reg [15:0]  cursor = 0;
reg [ 7:0]  opcode = 0;
reg [ 7:0]  s1 = 0;
reg [ 2:0]  s2 = 0;

reg         alum = 0;       // Режим подключения АЛУ
reg [ 8:0]  alu_r;
reg [ 7:0]  alu_f;

initial begin

    data_o = 0;
    we     = 0;

end
