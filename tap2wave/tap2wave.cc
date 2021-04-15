#include <stdio.h>

#define HI 1
#define LO 0
#define PULSELEN_ZERO 855
#define PULSELEN_ONE  1710

FILE *tap_file,
     *wave_file;

unsigned int wavesize, tstate_current, tap_size;

// 44 байта https://audiocoding.ru/articles/2008-05-22-wav-file-structure/
struct __attribute__((__packed__)) WAVEFMTHEADER {

    unsigned int    chunkId;        // RIFF 0x52494646
    unsigned int    chunkSize;      // Размер чанка-8
    unsigned int    format;         // WAVE 0x57415645
    unsigned int    subchunk1Id;    // fmt (0x666d7420)
    unsigned int    subchunk1Size;  // 16
    unsigned short  audioFormat;    // 1
    unsigned short  numChannels;    // 1
    unsigned int    sampleRate;     // 44100
    unsigned int    byteRate;       // Байт в секунду 44100
    unsigned short  blockAlign;     // Байт на семпл (1)
    unsigned short  bitsPerSample;  // Бит на семпл (8)
    unsigned int    subchunk2Id;    // data 0x64617461
    unsigned int    subchunk2Size;  // Количество байт в области данных.
};

// Запись WAV-заголовка
void write_wave_header() {

    struct WAVEFMTHEADER head = {
        0x46464952, // RIFF
        (wavesize + 0x24),
        0x45564157, // WAVE
        0x20746d66, // fmt
        16,         // 16=PCM
        1,          // Тип
        1,          // Каналы
        44100,      // Частота дискретизации
        44100,      // Байт в секунду
        1,          // Байт на семпл (1+1)
        8,          // Бит на семпл
        0x61746164, // "data"
        wavesize
    };

    fseek(wave_file, 0, SEEK_SET);
    fwrite(&head, 1, sizeof(WAVEFMTHEADER), wave_file);
}

// Записать тон длительностью t_state
void push_tstates(int t_state, int tone) {

    unsigned char tb = tone ? 0xc0 : 0x40;
    unsigned char buf[1] = {tb};

    // Всякие хардовые вычисления
    tstate_current += 44100*t_state;
    int tcount      = tstate_current / 3500000;
    tstate_current %= 3500000;

    // Количество семплов для добавления
    for (int i = 0; i < tcount; i++) { fwrite(buf, 1, 1, wave_file); wavesize++; }
}

// Записать байт
void push_byte(unsigned char data) {

    unsigned char mask = 0x80;

    while (mask) {

        int len = data & mask ? PULSELEN_ONE : PULSELEN_ZERO;
        push_tstates(len, HI);
        push_tstates(len, LO);
        mask >>= 1;
    }
}

void processing() {

    int cursor;
    int tap_cursor = 0;

    unsigned char buf[65536];

    while (tap_cursor < tap_size) {

        cursor = 0;
        fread(buf, 1, 2, tap_file);

        // Размер данных в блоке
        int block_size = buf[0] + buf[1]*256;

        // К следующему блоку
        tap_cursor += (2 + block_size);

        // Загрузка данных
        fread(buf, 1, block_size, tap_file);

        // Первый байт: 00 заголовок FF данные
        int pilot_len = buf[cursor] & 0x80 ? 3224 : 8064;

        // LEADER
        for (int i = 0; i < (pilot_len>>1); i++) {
            push_tstates(2168, HI);
            push_tstates(2168, LO);
        }

        // Сигнал синхронизации
        push_tstates(667, HI);
        push_tstates(735, LO);

        // Запись оставшихся байтов вместе с checksum
        for (int i = 0; i < block_size; i++) {
            push_byte(buf[cursor++]);
        }

        // Сигнал синхронизации
        push_tstates(954, HI);

        // Промежутки
        for (int i = 0; i < 1000; i++) push_tstates(3500, LO);
    }
}

// Отсюда и будет все запускаться
int main(int argc, char** argv) {

    if (argc < 3) { printf("USAGE: tap2wave file.tap file.wav\n"); return 1; }

    wavesize       = 0;
    tstate_current = 0;

    tap_file  = fopen(argv[1], "rb+");
    wave_file = fopen(argv[2], "wb+");

    fseek(wave_file, 44, SEEK_SET);
    fseek(tap_file, 0, SEEK_END);
    tap_size = ftell(tap_file);
    fseek(tap_file, 0, SEEK_SET);

    processing();

    write_wave_header();

    fclose(tap_file);
    fclose(wave_file);

    return 0;
}
