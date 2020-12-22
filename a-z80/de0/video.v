module video(

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
    input   wire [ 2:0] border,

    // Генерация сигнала для INT
    output  reg         nvblank,

    // -----------------------------------------------------------------

    // Запрос
    input   wire        f1_screen,

    // Доступ к памяти
    output  reg  [11:0] ch_address, // 4k Видеоданные
    output  reg  [11:0] fn_address, // Шрифты
    input   wire [ 7:0] ch_data1,
    input   wire [ 7:0] ch_data2,
    input   wire [ 7:0] fn_data,

    // Внешний интерфейс
    input   wire [10:0] cursor   // Положение курсора от 0 до 2047
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

// Чтобы правильно начинались данные, нужно их выровнять
wire [7:0] X = x[9:1] - 24;
wire [7:0] Y = y[9:1] - 4;
wire [9:0] tx = x + 8;

// ---------------------------------------------------------------------

reg [7:0] current_char;
reg [7:0] current_attr;
reg [7:0] tmp_current_char;

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
    border[1] ? 4'hC : 4'h1,
    border[2] ? 4'hC : 4'h1,
    border[0] ? 4'hC : 4'h1
};

reg         flash;
reg [23:0]  timer;
reg [18:0]  t50hz;
initial     nvblank = 1'b1;

always @(posedge clk) begin

    if (timer == 24'd12500000) begin /* полсекунды */
        timer <= 1'b0;
        flash <= flash ^ 1'b1; // мигать каждые 0.5 секунд
    end else begin
        timer <= timer + 1'b1;
    end

    // Генератор 50 Гц сигнала
    if (t50hz == 499999) t50hz <= 0;
    else begin

        // INT продолжается ровно 1 линию
        nvblank <= t50hz > 499999-800 ? 1'b0 : 1'b1;
        t50hz   <= t50hz + 1;

    end

end

// Когда бит 1 переходит из состояния 0 в состояние 1, это значит, что
// будет осциллироваться на частоте 25 мгц (в 4 раза медленее, чем 100 мгц)
always @(posedge clk) begin

    x <= x == (horiz_whole - 1) ? 1'b0 : (x + 1'b1);
    if (x == (horiz_whole - 1)) y <= y == (vert_whole - 1) ? 1'b0 : (y + 1'b1);

    // Обязательно надо тут использовать попиксельный выход, а то пиксели наполовину съезжают
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

        if (f1_screen) begin
            {red, green, blue} <= maskbit ? (attr[7] & flash80 ? bgcolor80 : frcolor80) : bgcolor80;
        end
        else begin

            // Цвет вычисляется выше и зависит от: атрибута, это пиксель или нет
            if (x >= 64 && x < (64 + 512) && y >= 8 && y < (8 + 384)) begin

                {red, green, blue} <= color;

            // Тут будет бордюр
            end else begin
                {red, green, blue} <= bgcolor;
            end

        end

    // В невидимой области мы ДОЛЖНЫ очищать в черный цвет
    // иначе видеоадаптер работать будет неправильно
    end else {red, green, blue} <= 12'h000;

end

// ---------------------------------------------------------------------
// Текстовый видеоадаптер
// ---------------------------------------------------------------------
reg  [ 7:0] char;  reg [7:0] tchar; // Битовая маска
reg  [ 7:0] attr;  reg [7:0] tattr; // Атрибут
reg  [23:0] timer80; // Мерцание курсора
reg         flash80;
// ---------------------------------------------------------------------

// Текущая позиция курсора
wire [10:0] id = tx[9:3] + (y[8:4] * 80);

// Если появляется курсор [1..4000], то он использует нижние 2 строки у линии
wire maskbit = (char[ 3'h7 ^ tx[2:0] ]) | (flash80 && (id == cursor+1) && y[3:0] >= 14);

// Разбираем цветовую компоненту (нижние 4 бита отвечают за цвет символа)
wire [15:0] frcolor80 =

    attr[3:0] == 4'h0 ? 12'h111 : // 0 Черный (почти)
    attr[3:0] == 4'h1 ? 12'h008 : // 1 Синий (темный)
    attr[3:0] == 4'h2 ? 12'h080 : // 2 Зеленый (темный)
    attr[3:0] == 4'h3 ? 12'h088 : // 3 Бирюзовый (темный)
    attr[3:0] == 4'h4 ? 12'h800 : // 4 Красный (темный)
    attr[3:0] == 4'h5 ? 12'h808 : // 5 Фиолетовый (темный)
    attr[3:0] == 4'h6 ? 12'h880 : // 6 Коричневый
    attr[3:0] == 4'h7 ? 12'hccc : // 7 Серый -- тут что-то не то
    attr[3:0] == 4'h8 ? 12'h888 : // 8 Темно-серый
    attr[3:0] == 4'h9 ? 12'h00f : // 9 Синий (темный)
    attr[3:0] == 4'hA ? 12'h0f0 : // 10 Зеленый
    attr[3:0] == 4'hB ? 12'h0ff : // 11 Бирюзовый
    attr[3:0] == 4'hC ? 12'hf00 : // 12 Красный
    attr[3:0] == 4'hD ? 12'hf0f : // 13 Фиолетовый
    attr[3:0] == 4'hE ? 12'hff0 : // 14 Желтый
                        12'hfff;  // 15 Белый

// Цветовая компонента фона (только 8 цветов)
wire [15:0] bgcolor80 =

    attr[6:4] == 3'd0 ? 12'h111 : // 0 Черный (почти)
    attr[6:4] == 3'd1 ? 12'h008 : // 1 Синий (темный)
    attr[6:4] == 3'd2 ? 12'h080 : // 2 Зеленый (темный)
    attr[6:4] == 3'd3 ? 12'h088 : // 3 Бирюзовый (темный)
    attr[6:4] == 3'd4 ? 12'h800 : // 4 Красный (темный)
    attr[6:4] == 3'd5 ? 12'h808 : // 5 Фиолетовый (темный)
    attr[6:4] == 3'd6 ? 12'h880 : // 6 Коричневый
                        12'hccc;  // 7 Серый

// Источник данных (фрейм)
wire [7:0] ch_data = ch_data2;

// Извлечение битовой маски и атрибутов для генерации шрифта
always @(posedge clk) begin

    case (tx[2:0])

        // Запрос на ASCII-символ
        0: begin ch_address <= {id[10:0], 1'b0}; end

        // Сохранить ASCII -> tchar, запрос на атрибут
        1: begin tchar <= ch_data; ch_address[0] <= 1'b1; end

        // Сохранить атрибут, запрос на знакогенератор
        2: begin tattr <= ch_data; fn_address <= {tchar[7:0], y[3:0]}; end

        // Сохранить значение битовой маски
        3: begin tchar <= fn_data; end

        // Обновить данные для рисования символа
        7: begin attr  <= tattr; char <= tchar; end

    endcase

end

// Каждые 0,5 секунды перебрасывается регистр flash
always @(posedge clk) begin

    if (timer80 == 12500000) begin
        flash80 <= ~flash80;
        timer80 <= 0;
    end else
        timer80 <= timer80 + 1;
end

endmodule
