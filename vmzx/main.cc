/**
 * -2 Включить режим 128к
 * -a Автостарт с командой RUN
 * -b <file> <offset> Загрузка любого бинарного файла в память
 * -c Запускать без GUI SDL
 * -d Включить отладчик при загрузке
 * -h Останавливать выполнение на halt для консольного режима
 * -k "последовательность символов нажатий клавиш" (под вопросом)
 * -m <кадры> Пропуск кадров
 * -M <секунды> длительность записи
 * -o <файл> Вывод серии PNG в файл (если - то stdout)
 * -p <address> Установка адреса PC после запуска
 * -r<0,1> <rom-файл> Загрузка ROM 0/1
 * -s Пропуск повторяющегося кадра
 * -w wav-файл для записи звука
 * -x Отключить звук
 * -z включение моно-звука
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
