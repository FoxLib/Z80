/**
 * -a Автостарт с командой RUN
 * -b <file> <offset> Загрузка любого бинарного файла в память
 * -c Запускать без GUI SDL
 * -d Включить отладчик при загрузке
 * -o <файл> Вывод серии PNG в файл (если - то stdout)
 * -p <address> Установка адреса PC после запуска
 * -2 Включить режим 128к
 * -M <секунды> длительность записи
 * -k "последовательность символов нажатий клавиш" (под вопросом)
 * -x Отключить звук
 * -s Пропуск повторяющегося кадра
 * -x Отключить звук SDL
 * -w wav-файл для записи звука
 * <file>.(z80|tap|sna) Загрузка снашпота или TAP бейсика
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
