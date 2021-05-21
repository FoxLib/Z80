module z80(

    input       wire        clock,
    input       wire [7:0]  data_i,
    output      wire [15:0] address,
    output      reg         we,
    output      reg  [7:0]  data_o
);

wire _m0 = s1 == 0;

`include "decl.v"
`include "prepare.v"

assign address = sel ? cursor : pc;

always @(posedge clock) begin
case (s1)

    // Запись нового опкода, декодирование инструкции
    0: begin

        s1 <= 1;
        s2 <= 0;
        we <= 0;
        alum <= 0;
        pc <= pc + 1;
        opcode <= data_i;
        cursor <= 0;

        casex (data_i)

            // 1t: inc|dec r16
            8'b00xx_x011: begin

                s1 <= 0;
                case (opcode[5:4])
                    2'b00: bc <= data_i[3] ? bc-1 : bc+1;
                    2'b01: de <= data_i[3] ? de-1 : de+1;
                    2'b10: hl <= data_i[3] ? hl-1 : hl+1;
                    2'b11: sp <= data_i[3] ? sp-1 : sp+1;
                endcase

            end

            // 1/2t: ld r,r
            8'b01_xxx_110: begin sel <= 1; cursor <= hl; end
            8'b01_110_110: begin s1 <= 0; pc <= pc; end
            8'b01_xxx_xxx: begin

                data_o <= ldreg_src;
                cursor <= hl;
                s1     <= 0;

                case (data_i[5:3])

                    0: bc[15:8] <= ldreg_src;
                    1: bc[ 7:0] <= ldreg_src;
                    2: de[15:8] <= ldreg_src;
                    3: de[ 7:0] <= ldreg_src;
                    4: hl[15:8] <= ldreg_src;
                    5: hl[ 7:0] <= ldreg_src;
                    6: begin sel <= 1; we <= 1; s1 <= 1; end // Запись в память
                    7: af[ 7:0] <= ldreg_src;

                endcase

            end

            // <alu> a,(hl)
            8'b10_xxx_110: begin sel <= 1; cursor <= hl; alum <= 1; end

            // <alu> a,r
            8'b10_xxx_xxx: begin

                s1 <= 0;
                alum <= 1;
                if (data_i[5:3] != 3'b111) af[7:0] <= alu_r[7:0]; // cp

            end

        endcase

    end

    // Такт второй, исполнение инструкции
    1: casex (opcode)

        // 3T: ld r16, i16
        8'b00xx_0001: case (s2)

            0: begin s2 <= 1; pc <= pc + 1; cursor[7:0] <= data_i; end
            1: begin s1 <= 0; pc <= pc + 1;

                case (opcode[5:4])
                    2'b00: bc <= {data_i, cursor[7:0]};
                    2'b01: de <= {data_i, cursor[7:0]};
                    2'b10: hl <= {data_i, cursor[7:0]};
                    2'b11: sp <= {data_i, cursor[7:0]};
                endcase

            end

        endcase

        // 2/3T: ld r, i; ld r, (hl)
        8'b00_xxx_110,
        8'b01_xxx_110: case (s2)

            0: begin

                data_o <= data_i;
                cursor <= hl;
                sel    <= 0;

                s1 <= 0;
                s2 <= 1;

                // Если это ld r,i => pc++
                if (opcode[6] == 0) pc <= pc + 1;

                case (opcode[5:3])

                    0: bc[15:8] <= data_i;
                    1: bc[ 7:0] <= data_i;
                    2: de[15:8] <= data_i;
                    3: de[ 7:0] <= data_i;
                    4: hl[15:8] <= data_i;
                    5: hl[ 7:0] <= data_i;
                    6: begin sel <= 1; we <= 1; s1 <= 1; end // Запись в память
                    7: af[ 7:0] <= data_i;

                endcase

            end
            1: begin sel <= 0; we <= 0; s1 <= 0; end

        endcase

        // 1/2t: ld r,r
        8'b01_xxx_xxx: begin s1 <= 0; sel <= 0; we <= 0; end

        // <alu> a,(hl)
        8'b10_xxx_110: begin

            s1  <= 0;
            sel <= 0;
            if (opcode[5:3] != 3'b111) af[7:0] <= alu_r[7:0];

        end

    endcase

endcase
end

endmodule
