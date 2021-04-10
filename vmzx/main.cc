/**
 * -a Автостарт с командой RUN
 * -o <файл> Вывод серии PNG в файл (если - то stdout)
 * -c Запускать без GUI SDL
 * -x Disable sound
 * <file>.(z80|tap) Загрузка снашпота или TAP бейсика
 * -M <секунды> длительность записи
 * -b [последовательность символов нажатий клавиш]
 * -s Пропуск повторяющегося кадра
 * -2 Включить режим 128к
 * -w wav-файл для записи звука
 * <file>.(z80|tap|sna)
 */

#include "z80.cc"
#include "machine.h"
#include "machine.cc"
#include "constructor.cc"
#include "video.cc"
#include "ay.cc"
#include "io.cc"
#include "snapshot.cc"
#include "disasm.cc"

int main(int argc, char* argv[]) {

    Z80Spectrum speccy;

    speccy.args(argc, argv);
    speccy.main();

    return 0;
}
