module z80vid(

    // 25 мегагерц
    input   wire        clk,

    // Выходные данные
    output  reg  [3:0]  red,        // 5 бит на красный (4,3,2,1,0)
    output  reg  [3:0]  green,      // 6 бит на зеленый (5,4,3,2,1,0)
    output  reg  [3:0]  blue,       // 5 бит на синий (4,3,2,1,0)
    output  wire        hs,         // синхросигнал горизонтальной развертки
    output  wire        vs,          // синхросигнал вертикальной развертки

    // Данные для вывода
    output  reg  [12:0] video_addr,
    input   wire [ 7:0] video_data,
    input   wire [ 2:0] border

);

// Тайминги для горизонтальной развертки (640)
parameter horiz_visible = 640;
parameter horiz_back    = 48;
parameter horiz_sync    = 96;
parameter horiz_front   = 16;
parameter horiz_whole   = 800;

// Тайминги для вертикальной развертки (400)
//                              // 400  480
parameter vert_visible = 400;   // 400  480
parameter vert_back    = 35;    // 35   33
parameter vert_sync    = 2;     // 2    2
parameter vert_front   = 12;    // 12   10
parameter vert_whole   = 449;   // 449  525

// 640 (видимая область) + 16 (задний порожек) + 96 (синхронизация) + 48 (задний порожек)
assign hs = x >= (horiz_visible + horiz_front) && x < (horiz_visible + horiz_front + horiz_sync);
assign vs = y >= (vert_visible  + vert_front)  && y < (vert_visible  + vert_front  + vert_sync);

// В этих регистрах мы будем хранить текущее положение луча на экране
reg [9:0] x = 1'b0; // 2^10 = 1024 точек возможно
reg [9:0] y = 1'b0;

reg [7:0] current_char;
reg [7:0] current_attr;
reg [7:0] tmp_current_char;

// Чтобы правильно начинались данные, нужно их выровнять
wire [7:0] X = x[9:1] - 24;
wire [7:0] Y = y[9:1] - 4;

// Получаем текущий бит
wire current_bit = current_char[ 7 ^ X[2:0] ];

// Если бит атрибута 7 = 1, то бит flash будет менять current_bit каждые 0.5 секунд
wire flashed_bit = (current_attr[7] & flash) ^ current_bit;

// Текущий цвет точки
// Если сейчас рисуется бит - то нарисовать цвет из атрибута (FrColor), иначе - BgColor
wire [2:0] src_color = flashed_bit ? current_attr[2:0] : current_attr[5:3];

// Вычисляем цвет. Если бит 3=1, то цвет яркий, иначе обычного оттенка (половинной яркости)
wire [11:0] color = {

    // Если current_attr[6] = 1, то переходим в повышенную яркость (в 2 раза)
    /* Красный цвет - это бит 1 */ src_color[1] ? (current_attr[6] ? 4'hF : 4'hC) : 4'h01,
    /* Зеленый цвет - это бит 2 */ src_color[2] ? (current_attr[6] ? 4'hF : 4'hC) : 4'h01,
    /* Синий цвет   - это бит 0 */ src_color[0] ? (current_attr[6] ? 4'hF : 4'hC) : 4'h01

};

// Регистр border(3 бита) будет задаваться извне, например записью в порты какие-нибудь
wire [11:0] bgcolor = {
    border[1] ? 4'h7 : 4'h1,
    border[2] ? 4'h7 : 4'h1,
    border[0] ? 4'h7 : 4'h1
};

reg        flash;
reg [23:0] timer;

always @(posedge clk) begin

    if (timer == 24'd12500000) begin /* полсекунды */
        timer <= 1'b0;
        flash <= flash ^ 1'b1; // мигать каждые 0.5 секунд
    end else begin
        timer <= timer + 1'b1;
    end

end

// Когда бит 1 переходит из состояния 0 в состояние 1, это значит, что
// будет осциллироваться на частоте 25 мгц (в 4 раза медленее, чем 100 мгц)
always @(posedge clk) begin

    // аналогично этой конструции на C
    // if (x == 799) x = 0; else x += 1;
    x <= x == (horiz_whole - 1) ? 1'b0 : (x + 1'b1);

    // Когда достигаем конца горизонтальной линии, переходим к Y+1
    if (x == (horiz_whole - 1)) begin

        // if (x == 524) y = 0; else y += 1;
        y <= y == (vert_whole - 1) ? 1'b0 : (y + 1'b1);

    end

    // Обязательно надо тут использовать попиксельный выход, а то пиксели
    // наполовину съезжают

    case (x[3:0])

        // Видеоадрес в ZX Spectrum непросто вычислить
        //         FEDC BA98 7654 3210
        // Адрес =    Y Yzzz yyyx xxxx

                               // БанкY  СмещениеY ПолубанкY СмещениеX
        4'b0000: video_addr <= { Y[7:6], Y[2:0],   Y[5:3],   X[7:3] };

        // Запись временного значения, чтобы на 16-м такте его обновить
        4'b0001: tmp_current_char <= video_data;

        // Запрос атрибута по x=0..31, y=0..23
        // [110] [yyyyy] [xxxxx]
        4'b0010: video_addr <= { 3'b110, Y[7:3], X[7:3] };

        // Подготовка к выводу символа
        4'b1111: begin

            // Записать в текущий регистр выбранную "маску" битов
            current_char <= tmp_current_char;

            // И атрибутов
            // Атрибут в спектруме представляет собой битовую маску
            //  7     6      5 4 3    2 1 0
            // [Flash Bright BgColor  FrColor]

            // Flash   - мерцание
            // Bright  - яркость
            // BgColor - цвет фона
            // FrColor - цвет пикселей

            current_attr <= video_data;

        end

    endcase

    // Мы находимся в видимой области рисования
    if (x < horiz_visible && y < vert_visible) begin

        if (x >= 64 && x < (64 + 512) && y >= 8 && y < (8 + 384)) begin

            // Цвет вычисляется выше и зависит от
            // 1. Атрибута
            // 2. Это пиксель или нет
            {red, green, blue} <= color;

        // Тут будет бордюр
        end else begin

            {red, green, blue} <= bgcolor;

        end

    // В невидимой области мы ДОЛЖНЫ очищать в черный цвет
    // иначе видеоадаптер работать будет неправильно
    end else {red, green, blue} <= 12'h000;

end

endmodule
