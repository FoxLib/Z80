/**
 * Видимая область: 224 x 312 = 69888 t-states
 * Общая область: 352x296
 */

#include <sys/timeb.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifndef NO_SDL

#include "SDL.h"
#define MAX_AUDIOSDL_BUFFER 882*16

// Циклический буфер
int           AudioSDLFrame;
int           AudioZXFrame;
unsigned char ZXAudioBuffer[MAX_AUDIOSDL_BUFFER];

// Аудиобуфер
void sdl_audio_buffer(void* udata, unsigned char* stream, int len) {

    // Выдача данных
    for (int i = 0; i < 882; i++) {

        int v = ZXAudioBuffer[882*AudioSDLFrame + i];
        stream[i] = v;
    }

    // К следующему (если можно)
    if (AudioSDLFrame != AudioZXFrame) {
        AudioSDLFrame = (AudioSDLFrame + 1) % 16;
    }
    // Если догнал - то отстать на несколько кадров
    else {
        AudioSDLFrame = ((AudioZXFrame + 16) - 8) % 16;
    }
}
#endif

// AY-3-8910 Уровни
static const int ay_levels[16] = {
    0x0000, 0x0385, 0x053D, 0x0770,
    0x0AD7, 0x0FD5, 0x15B0, 0x230C,
    0x2B4C, 0x43C1, 0x5A4B, 0x732F,
    0x9204, 0xAFF1, 0xD921, 0xFFFF
};

// Для выгрузки BMP https://ru.wikipedia.org/wiki/BMP

// 14 байт
struct __attribute__((__packed__)) BITMAPFILEHEADER {
    unsigned short bfType;      // BM
    unsigned int   bfSize;      // 38518
    unsigned short bfReserved1; // 0
    unsigned short bfReserved2; // 0
    unsigned int   bfOffBits;   // 0x76
};

// 40 байт
struct __attribute__((__packed__)) BITMAPINFOHEADER {
    unsigned int   biSize;          // 0x28 (40)
    unsigned int   biWidth;         // 320
    unsigned int   biHeight;        // 240
    unsigned short biPlanes;        // 1
    unsigned short biBitCount;      // 4
    unsigned int   biCompression;   // 0
    unsigned int   biSizeImage;     // 0x9600 (38400)
    unsigned int   biXPelsPerMeter; // 0x0B13
    unsigned int   biYPelsPerMeter; // 0x0B13
    unsigned int   biClrUsed;       // 0x10 (16)
    unsigned int   biClrImportant;  // 0
};

// 44 байта https://audiocoding.ru/articles/2008-05-22-wav-file-structure/
struct __attribute__((__packed__)) WAVEFMTHEADER {

    unsigned int    chunkId;        // RIFF 0x52494646
    unsigned int    chunkSize;
    unsigned int    format;         // WAVE 0x57415645
    unsigned int    subchunk1Id;    // fmt (0x666d7420)
    unsigned int    subchunk1Size;  // 16
    unsigned short  audioFormat;    // 1
    unsigned short  numChannels;    // 2
    unsigned int    sampleRate;     // 44100
    unsigned int    byteRate;       //
    unsigned short  blockAlign;     //
    unsigned short  bitsPerSample;  //
    unsigned int    subchunk2Id;    // data 0x64617461
    unsigned int    subchunk2Size;  // Количество байт в области данных.
};

class Z80Spectrum : public Z80 {
protected:

#ifndef NO_SDL
    SDL_Event       event;
    SDL_Surface*    sdl_screen;
    SDL_AudioSpec   audio_device;
#endif

// -----------------------------------------------------------------
// Свойства: Процессор
// -----------------------------------------------------------------

    unsigned char   memory[128*1024];
    unsigned char   rom[65536];         // 0 128k; 1 48k
    unsigned char   trdos[16384];

    int     t_states_cycle;
    int     port_7ffd;
    int     trdos_latch;

// -----------------------------------------------------------------
// Свойства: Видеоадаптер
// -----------------------------------------------------------------

    int             sdl_enable;
    int             width, height;
    unsigned char   fb[160*240];        // Следующий кадр
    unsigned char   pb[160*240];        // Предыдущий кадр

    // Таймер обновления экрана
    unsigned int    ms_time_diff;
    struct timeb    ms_clock;
    unsigned int    ms_clock_old;

    int     flash_state, flash_counter;
    uint    border_id, port_fe;
    int     diff_prev_frame;

// -----------------------------------------------------------------
// Свойства: Эмуляция
// -----------------------------------------------------------------

    int     key_states[8];
    int     con_frame_start, con_frame_end, con_frame_fps, skip_first_frames;
    int     auto_keyb, skip_dup_frame;
    int     con_pngout;
    FILE*   png_file;
    int     frame_id;
    int     first_sta;            // Досрочно обновить экран
    int     autostart;            // Автостарт при запуске
    int     frame_counter;        // Количество кадров от начала
    int     lookupfb[192];        // Для более быстрого определения адреса
    char    strbuf[256];

// -----------------------------------------------------------------
// Свойства: Звук
// -----------------------------------------------------------------

    int     ab_cursor;
    int     t_states_wav, max_audio_cycle;
    FILE*   wave_file;
    int     ay_register, ay_regs[16], ay_amp[3];
    int     ay_tone_tick[3], ay_tone_period[3], ay_tone_high[3];
    int     ay_tone_levels[16];
    int     ay_envelope_first, ay_noise_tick;

    unsigned char audio_frame[44100];
    unsigned int  wav_cursor;

// -----------------------------------------------------------------
// Методы: Эмуляция и память
// -----------------------------------------------------------------

    void    frame();
    void    autostart_macro();
    void    key_press(int row, int mask, int press);

    int     get_bank    (int address);
    int     c48k_address(int address, int mode);
    int     z80file_bankmap(int mode, int bank);

    int     mem_read    (int address);
    void    mem_write   (int address, int data);
    int     io_read     (int port);
    void    io_write    (int port, int data);

// -----------------------------------------------------------------
// Методы: Звук
// -----------------------------------------------------------------

    int     ay_get_tone(int channel);
    int     ay_get_noise_period();
    int     at_get_env_period();
    void    ay_write_data(int data);
    void    ay_tick();
    void    ay_amp_adder(int& left, int& right);
    void    ay_sound_tick(int t_states, int& audio_c);

// -----------------------------------------------------------------
// Методы: Работа с видеобуфером
// -----------------------------------------------------------------

    unsigned int get_color(int color);
    void    update_charline(int address);
    void    pset(int x, int y, uint color);

// -----------------------------------------------------------------
// Методы: Сохранение и загрузка
// -----------------------------------------------------------------

    void    loadbin(const char* filename, int address);
    void    loadtap(const char* filename);
    void    loadrom(const char* filename, int bank);
    void    loadz80(const char* filename);
    void    loadz80block(int mode, int& cursor, int &addr, unsigned char* data, int top, int rle);
    void    savez80(const char* filename);
    void    encodebmp(int audio_c);
    void    waveFmtHeader();

// -----------------------------------------------------------------
// Методы: SDL-ориентированные
// -----------------------------------------------------------------

#ifndef NO_SDL
    void    keyb(int press, SDL_KeyboardEvent* eventkey);
#endif

public:

    Z80Spectrum();
    ~Z80Spectrum();

    void    args(int argc, char** argv);
    void    main();
};

