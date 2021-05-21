// Для 01_xxx_xxx (операнд-источник)
wire [7:0] ldreg_src =
    data_i[2:0] == 0 ? bc[15:8] :
    data_i[2:0] == 1 ? bc[ 7:0] :
    data_i[2:0] == 2 ? de[15:8] :
    data_i[2:0] == 3 ? de[ 7:0] :
    data_i[2:0] == 4 ? hl[15:8] :
    data_i[2:0] == 5 ? hl[ 7:0] :
    data_i[2:0] == 6 ? 8'hFF : af[7:0];

// При alum=1 подключение к памяти вместо регистра
wire [7:0] alu_op2  = alum ? data_i : ldreg_src;
wire [2:0] alu_mode = alum ? opcode[5:3] : data_i[5:3];

// Арифметико-логика #1
always @* begin

    case (alu_mode)

        0:    alu_r = af[7:0] + alu_op2; // ad
        1:    alu_r = af[7:0] + alu_op2 + af[8]; // carry flug
        2, 7: alu_r = af[7:0] - alu_op2; // sub, cp
        3:    alu_r = af[7:0] - alu_op2 - af[8];
        4:    alu_r = af[7:0] & alu_op2;
        5:    alu_r = af[7:0] ^ alu_op2;
        6:    alu_r = af[7:0] | alu_op2;

    endcase

end
