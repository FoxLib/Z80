// https://ru.wikipedia.org/wiki/Скан-код
module ps2at2ascii
(
    input  wire [7:0] at,
    output reg  [7:0] xt
);

always @(*) begin

    case (at)

        /* A   */ 8'h1C: xt = 8'h41;
        /* B   */ 8'h32: xt = 8'h42;
        /* C   */ 8'h21: xt = 8'h43;
        /* D   */ 8'h23: xt = 8'h44;
        /* E   */ 8'h24: xt = 8'h45;
        /* F   */ 8'h2B: xt = 8'h46;
        /* G   */ 8'h34: xt = 8'h47;
        /* H   */ 8'h33: xt = 8'h48;
        /* I   */ 8'h43: xt = 8'h49;
        /* J   */ 8'h3B: xt = 8'h4A;
        /* K   */ 8'h42: xt = 8'h4B;
        /* L   */ 8'h4B: xt = 8'h4C;
        /* M   */ 8'h3A: xt = 8'h4D;
        /* N   */ 8'h31: xt = 8'h4E;
        /* O   */ 8'h44: xt = 8'h4F;
        /* P   */ 8'h4D: xt = 8'h50;
        /* Q   */ 8'h15: xt = 8'h51;
        /* R   */ 8'h2D: xt = 8'h52;
        /* S   */ 8'h1B: xt = 8'h53;
        /* T   */ 8'h2C: xt = 8'h54;
        /* U   */ 8'h3C: xt = 8'h55;
        /* V   */ 8'h2A: xt = 8'h56;
        /* W   */ 8'h1D: xt = 8'h57;
        /* X   */ 8'h22: xt = 8'h58;
        /* Y   */ 8'h35: xt = 8'h59;
        /* Z   */ 8'h1A: xt = 8'h5A;

        /* 0   */ 8'h45: xt = 8'h30;
        /* 1   */ 8'h16: xt = 8'h31;
        /* 2   */ 8'h1E: xt = 8'h32;
        /* 3   */ 8'h26: xt = 8'h33;
        /* 4   */ 8'h25: xt = 8'h34;
        /* 5   */ 8'h2E: xt = 8'h35;
        /* 6   */ 8'h36: xt = 8'h36;
        /* 7   */ 8'h3D: xt = 8'h37;
        /* 8   */ 8'h3E: xt = 8'h38;
        /* 9   */ 8'h46: xt = 8'h39;

        /* `   */ 8'h0E: xt = 8'h60;
        /* -   */ 8'h4E: xt = 8'h2D;
        /* =   */ 8'h55: xt = 8'h3D;
        /* \   */ 8'h5D: xt = 8'h5C;
        /* [   */ 8'h54: xt = 8'h5B;
        /* ]   */ 8'h5B: xt = 8'h5D;
        /* ;   */ 8'h4C: xt = 8'h3B;
        /* '   */ 8'h52: xt = 8'h27;
        /* ,   */ 8'h41: xt = 8'h2C;
        /* .   */ 8'h49: xt = 8'h2E;
        /* /   */ 8'h4A: xt = 8'h2F;
        /* SPC */ 8'h29: xt = 8'h20; /* SPACE */

        // Специальные кнопки
        /* F1  */ 8'h05: xt = 8'h01;
        /* F2  */ 8'h06: xt = 8'h02;
        /* F3  */ 8'h04: xt = 8'h03;
        /* F4  */ 8'h0C: xt = 8'h04;
        /* F5  */ 8'h03: xt = 8'h05;
        /* F6  */ 8'h0B: xt = 8'h06;
        /* F7  */ 8'h83: xt = 8'h07;
        /* BS  */ 8'h66: xt = 8'h08; /* BACKSPACE */
        /* TAB */ 8'h0D: xt = 8'h09; /* TAB */
        /* F8  */ 8'h0A: xt = 8'h0A;
        /* F9  */ 8'h01: xt = 8'h0B;
        /* F10 */ 8'h09: xt = 8'h0C;
        /* ENT */ 8'h5A: xt = 8'h0D; /* ENTER */
        /* F11 */ 8'h78: xt = 8'h0E;
        /* F12 */ 8'h07: xt = 8'h0F;

        /* CAP */ 8'h58: xt = 8'h10; /* CAPS LOCK */
        /* LSH */ 8'h12: xt = 8'h11; /* LEFT SHIFT */
        /* LCT */ 8'h14: xt = 8'h12; /* LEFT CTRL */
        /* LAT */ 8'h11: xt = 8'h13; /* LEFT ALT */
        /* LWI */ 8'h1F: xt = 8'h14; /* LEFT WIN */
        /* RSH */ 8'h59: xt = 8'h15; /* RIGHT SHIFT */
        /* RWI */ 8'h27: xt = 8'h16; /* RIGHT WIN */
        /* MNU */ 8'h2F: xt = 8'h17; /* MENU */
        /* SCL */ 8'h7E: xt = 8'h18; /* SCROLL LOCK */
        /* NUM */ 8'h77: xt = 8'h19;
        /* ESC */ 8'h76: xt = 8'h1B;

        /* Цифровая клавиатура */
        /* *   */ 8'h7C: xt = 8'h2A;
        /* -   */ 8'h7B: xt = 8'h2D;
        /* +   */ 8'h79: xt = 8'h2B;
        /* .   */ 8'h71: xt = 8'h2E; /* Del */
        /* 0   */ 8'h70: xt = 8'h30; /* Ins */
        /* 1   */ 8'h69: xt = 8'h31; /* End */
        /* 2   */ 8'h72: xt = 8'h32;
        /* 3   */ 8'h7A: xt = 8'h33; /* PgDn */
        /* 4   */ 8'h6B: xt = 8'h34;
        /* 5   */ 8'h73: xt = 8'h35;
        /* 6   */ 8'h74: xt = 8'h36;
        /* 7   */ 8'h6C: xt = 8'h37; /* Home */
        /* 8   */ 8'h75: xt = 8'h38;
        /* 9   */ 8'h7D: xt = 8'h39; /* PgUp */

        /* F0 (Unpressed Signal), E0, E1, ... */
        default: xt = at;

    endcase

end

endmodule
