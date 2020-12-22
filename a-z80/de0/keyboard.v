module keyboard(

    input wire        CLOCK_50,
    input wire        ps2_data_clk,
    input wire [7:0]  ps2_data,
    input wire [15:0] A,
    output reg [7:0]  D
);

reg  released = 1'b0;
reg  [5:0] zx_keys[8];

initial begin

    //                           0 1 2 3 4
    zx_keys[0] = 5'b11111; // Symb Z X C V
    zx_keys[1] = 5'b11111; //    A S D F G
    zx_keys[2] = 5'b11111; //    Q W E R T
    zx_keys[3] = 5'b11111; //    1 2 3 4 5
    zx_keys[4] = 5'b11111; //    0 9 8 7 6
    zx_keys[5] = 5'b11111; //    P O I U Y
    zx_keys[6] = 5'b11111; // Ent  L K J H
    zx_keys[7] = 5'b11111; // Spc Cs M N B

end

/* Чтение из портов */
always @(*) begin

    D[0] =  (zx_keys[0][0] & !A[ 8]) |
            (zx_keys[1][0] & !A[ 9]) |
            (zx_keys[2][0] & !A[10]) |
            (zx_keys[3][0] & !A[11]) |
            (zx_keys[4][0] & !A[12]) |
            (zx_keys[5][0] & !A[13]) |
            (zx_keys[6][0] & !A[14]) |
            (zx_keys[7][0] & !A[15]);
    D[1] =  (zx_keys[0][1] & !A[ 8]) |
            (zx_keys[1][1] & !A[ 9]) |
            (zx_keys[2][1] & !A[10]) |
            (zx_keys[3][1] & !A[11]) |
            (zx_keys[4][1] & !A[12]) |
            (zx_keys[5][1] & !A[13]) |
            (zx_keys[6][1] & !A[14]) |
            (zx_keys[7][1] & !A[15]);
    D[2] =  (zx_keys[0][2] & !A[ 8]) |
            (zx_keys[1][2] & !A[ 9]) |
            (zx_keys[2][2] & !A[10]) |
            (zx_keys[3][2] & !A[11]) |
            (zx_keys[4][2] & !A[12]) |
            (zx_keys[5][2] & !A[13]) |
            (zx_keys[6][2] & !A[14]) |
            (zx_keys[7][2] & !A[15]);
    D[3] =  (zx_keys[0][3] & !A[ 8]) |
            (zx_keys[1][3] & !A[ 9]) |
            (zx_keys[2][3] & !A[10]) |
            (zx_keys[3][3] & !A[11]) |
            (zx_keys[4][3] & !A[12]) |
            (zx_keys[5][3] & !A[13]) |
            (zx_keys[6][3] & !A[14]) |
            (zx_keys[7][3] & !A[15]);
    D[4] =  (zx_keys[0][4] & !A[ 8]) |
            (zx_keys[1][4] & !A[ 9]) |
            (zx_keys[2][4] & !A[10]) |
            (zx_keys[3][4] & !A[11]) |
            (zx_keys[4][4] & !A[12]) |
            (zx_keys[5][4] & !A[13]) |
            (zx_keys[6][4] & !A[14]) |
            (zx_keys[7][4] & !A[15]);
    D[5]    = 1'b1;
    D[6]    = 1'b1;
    D[7]    = 1'b1;

end

/* Данные принимаются только по тактовому сигналу и при наличии ps2_data_clk */
always @(posedge CLOCK_50) begin

    if (ps2_data_clk) begin

        /* Принят сигнал отпускания клавиши */
        if (ps2_data == 8'hF0) begin
            released <= 1'b1;

        end else begin

            case (ps2_data)

                /* РЯД 0 */
                /* SS */ 8'h12: zx_keys[0][0] <= released; // CAPS
                /*  Z */ 8'h1A: zx_keys[0][1] <= released;
                /*  X */ 8'h22: zx_keys[0][2] <= released;
                /*  C */ 8'h21: zx_keys[0][3] <= released;
                /*  V */ 8'h2A: zx_keys[0][4] <= released;

                /* РЯД 1 */
                /*  A */ 8'h1C: zx_keys[1][0] <= released;
                /*  S */ 8'h1B: zx_keys[1][1] <= released;
                /*  D */ 8'h23: zx_keys[1][2] <= released;
                /*  F */ 8'h2B: zx_keys[1][3] <= released;
                /*  G */ 8'h34: zx_keys[1][4] <= released;

                /* РЯД 2 */
                /*  Q */ 8'h15: zx_keys[2][0] <= released;
                /*  W */ 8'h1D: zx_keys[2][1] <= released;
                /*  E */ 8'h24: zx_keys[2][2] <= released;
                /*  R */ 8'h2D: zx_keys[2][3] <= released;
                /*  T */ 8'h2C: zx_keys[2][4] <= released;

                /* РЯД 3 */
                /*  1 */ 8'h16: zx_keys[3][0] <= released;
                /*  2 */ 8'h1E: zx_keys[3][1] <= released;
                /*  3 */ 8'h26: zx_keys[3][2] <= released;
                /*  4 */ 8'h25: zx_keys[3][3] <= released;
                /*  5 */ 8'h2E: zx_keys[3][4] <= released;

                /* РЯД 4 */
                /*  0 */ 8'h45: zx_keys[4][0] <= released;
                /*  9 */ 8'h46: zx_keys[4][1] <= released;
                /*  8 */ 8'h3E: zx_keys[4][2] <= released;
                /*  7 */ 8'h3D: zx_keys[4][3] <= released;
                /*  6 */ 8'h36: zx_keys[4][4] <= released;

                /* РЯД 5 */
                /*  P */ 8'h4D: zx_keys[5][0] <= released;
                /*  O */ 8'h44: zx_keys[5][1] <= released;
                /*  I */ 8'h43: zx_keys[5][2] <= released;
                /*  U */ 8'h3C: zx_keys[5][3] <= released;
                /*  Y */ 8'h35: zx_keys[5][4] <= released;

                /* РЯД 6 */
                /* EN */ 8'h5A: zx_keys[6][0] <= released; // ENTER
                /*  L */ 8'h4B: zx_keys[6][1] <= released;
                /*  K */ 8'h42: zx_keys[6][2] <= released;
                /*  J */ 8'h3B: zx_keys[6][3] <= released;
                /*  H */ 8'h33: zx_keys[6][4] <= released;

                /* РЯД 7 */
                /* SP */ 8'h29: zx_keys[7][0] <= released; // SPACE
                /* CS */ 8'h59: zx_keys[7][1] <= released; // SYMBOL
                /*  M */ 8'h3A: zx_keys[7][2] <= released;
                /*  N */ 8'h31: zx_keys[7][3] <= released;
                /*  B */ 8'h32: zx_keys[7][4] <= released;

                /* СПЕЦИАЛЬНЫЕ КНОПКИ */
                /* ,  */ 8'h41: begin zx_keys[7][1] <= released; zx_keys[7][3] <= released; end
                /* .  */ 8'h49: begin zx_keys[7][1] <= released; zx_keys[7][2] <= released; end
                /* /  */ 8'h4A: begin zx_keys[7][1] <= released; zx_keys[7][4] <= released; end
                /* ;  */ 8'h4C: begin zx_keys[7][1] <= released; zx_keys[6][2] <= released; end
                /* '  */ 8'h52: begin zx_keys[7][1] <= released; zx_keys[6][1] <= released; end
                /* ]  */ 8'h5B: begin zx_keys[7][1] <= released; zx_keys[5][0] <= released; end
                /* [  */ 8'h54: begin zx_keys[7][1] <= released; zx_keys[5][1] <= released; end
                /* \  */ 8'h5D: begin zx_keys[7][1] <= released; zx_keys[5][2] <= released; end
                /* =  */ 8'h55: begin zx_keys[7][1] <= released; zx_keys[5][3] <= released; end
                /* -  */ 8'h4E: begin zx_keys[7][1] <= released; zx_keys[5][4] <= released; end
                /* ~  */ 8'h0E: begin zx_keys[7][1] <= released; zx_keys[2][0] <= released; end
                /* TB */ 8'h0D: begin zx_keys[7][1] <= released; zx_keys[2][1] <= released; end
                /* DL */ 8'h66: begin zx_keys[7][1] <= released; zx_keys[2][2] <= released; end

            endcase

            released <= 1'b0;

        end
    end
end


endmodule
