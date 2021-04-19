module z80
(
    input  wire         CLOCK,  // 100 Mhz
    input  wire         HOLD,   // =1 Процессор работает
    output wire [15:0]  A,      // Адрес в памяти
    input  wire [7:0]   DI,     // Данные на вход
    output reg  [7:0]   DO,     // Данные на выход
    output reg          W       // Разрешение записи
);

assign A = bus ? cc : pc;

`include "decl.v"

// Обработка инструкции
always @(posedge CLOCK) begin

    // Для обеспечения конвейера
    pc <= pc + 1;

    // Ожидание получения валидных данных на шине
    if (latency) begin latency <= latency - 1; end
    // Начало исполнения очередной инструкции
    else begin if (t_state == 0)

        opcode <= d0;

    end

    // Сохранение входящих данных в конвейере
    d1 <= d0; d0 <= DI;


end

endmodule
