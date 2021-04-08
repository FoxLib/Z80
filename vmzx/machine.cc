#ifndef NO_SDL
#include "SDL.h"
#endif

/**
 * -a Автостарт с командой RUN
 * -o <файл> Вывод серии PNG в файл (если - то stdout)
 * -c Запускать без GUI SDL
 * <file>.(z80|tap) Загрузка снашпота или TAP бейсика
 * -M <секунды> длительность записи
 * -b [последовательность символов нажатий клавиш]
 * -s Пропуск повторяющегося кадра
 * -2 Включить режим 128к
 * -w wav-файл для записи звука
 */

#include <sys/timeb.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "lodepng.cc"

#ifndef NO_SDL
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

// Для выгрузки BMP https://ru.wikipedia.org/wiki/BMP

static const int ay_levels[16] = {
    0x0000, 0x0385, 0x053D, 0x0770,
    0x0AD7, 0x0FD5, 0x15B0, 0x230C,
    0x2B4C, 0x43C1, 0x5A4B, 0x732F,
    0x9204, 0xAFF1, 0xD921, 0xFFFF
};

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

// 4x16 = 64 байта занимает таблица цветов

// Видимая область: 224 x 312 = 69888 t-states
// Общая область: 352x296

class Z80Spectrum : public Z80 {
protected:

#ifndef NO_SDL
    SDL_Event       event;
    SDL_Surface*    sdl_screen;
    SDL_AudioSpec   audio_device;
#endif
    int             sdl_enable;
    int             width, height;
    unsigned char   fb[160*240];        // Следующий кадр
    unsigned char   pb[160*240];        // Предыдущий кадр
    unsigned char   memory[128*1024];   // 128k
    unsigned char   rom[65536];         // 4 ROM

    // Таймер обновления экрана
    unsigned int    ms_time_diff;
    struct timeb    ms_clock;
    unsigned int    ms_clock_old;

    int   flash_state, flash_counter;
    uint  border_id, port_fe;
    int   key_states[8];
    int   t_states_cycle, t_states_wav;
    int   ab_cursor;

    // Консольная запись
    int   con_frame_start, con_frame_end, con_frame_fps, skip_first_frames;
    int   con_pngout;
    int   diff_prev_frame;
    FILE* png_file;
    FILE* wave_file;
    int   auto_keyb;
    int   skip_dup_frame;
    int   frame_id;
    int   first_sta;            // Досрочно обновить экран
    int   autostart;            // Автостарт при запуске
    int   frame_counter;        // Количество кадров от начала
    int   lookupfb[192];        // Для более быстрого определения адреса
    char  strbuf[256];

    // Периферия
    int   ay_register, ay_regs[16], ay_amp[3];
    int   ay_tone_tick[3], ay_tone_period[3], ay_tone_high[3];
    int   ay_tone_levels[16];
    int   ay_envelope_first, ay_noise_tick;
    int   port_7ffd;

    unsigned char audio_frame[44100];
    unsigned int  wav_cursor;

    // Обработка одного кадра
    // http://www.zxdesign.info/vidparam.shtml
    void frame() {

        unsigned char tmp[2];

        int req_int = 1;
        int audio_c = 0;

        // Sinclair ZX                Sinclair | Pentagon
        int max_tstates   = 71680; // 69888    | 71680 (или 70908)
        int rows_paper    = 64;    // 64       | 80
        int cols_paper    = 200;   // 200      | 68
        int irq_row       = 296;   // 296      | 304

        int ppu_x = 0, ppu_y = 0, max_audio_cycle = max_tstates*50, ay_state = 0;

        // Автоматическое нажимание на клавиши
        autostart_macro();

        // Выполнить необходимое количество циклов
        while (t_states_cycle < max_tstates) {

            // Вызвать прерывание именно здесь, перед инструкцией
            if (ppu_y == irq_row && req_int) { interrupt(0, 0xff); req_int = 0; }

            // Детект того, где находится луч в данный момент
            // -- mem_write | mem_read из contended memory в области рисования
            // -- io_write | io_read в области бордера

            // Исполнение инструкции
            int t_states = run_instruction();
            t_states_cycle += t_states;

            // Запись в wav звука (учитывая автостарт)
            if (autostart <= 1) {

                t_states_wav += 44100 * t_states;

                // К следующему звуковому тику
                if (t_states_wav > max_audio_cycle) {

                    t_states_wav %= max_audio_cycle;

                    // Пока что пишется порт бипера
                    int beep = !!(port_fe&0x10) ^ !!(port_fe&0x08);

                    int left  = beep ? 0xff : 0x80;
                    int right = beep ? 0xff : 0x80;

                    // Использовать AY
                    ay_amp_adder(left, right);

                    tmp[0] = left;
                    tmp[1] = right;

                    // Запись во временный буфер
                    audio_frame[audio_c++] = tmp[0];
                    audio_frame[audio_c++] = tmp[1];
#ifndef NO_SDL
                    // Запись аудиострима в буфер (с циклом)
                    AudioZXFrame = ab_cursor / 882;
                    ZXAudioBuffer[ab_cursor++] = tmp[0];
                    ZXAudioBuffer[ab_cursor++] = tmp[1];
                    ab_cursor %= MAX_AUDIOSDL_BUFFER;
#endif
                }
            }

            // 1 CPU = 2 PPU
            for (int w = 0; w < t_states; w++) {

                // Каждые 32 тика срабатывает AY-чип
                if (((ay_state++) & 0x1f) == 0) ay_tick();

                int ppu_vx = ppu_x - 72,
                    ppu_lx = ppu_x - 48;

                // Луч находится в видимой области
                if (ppu_y >= 16 && ppu_x >= 48) {

                    // Рисуется бордер [2x точки на 1 такт]
                    if (ppu_x < 72 || ppu_x >= cols_paper || ppu_y < rows_paper || ppu_y >= 256) {

                        pset(2*ppu_lx,   ppu_y-16, border_id);
                        pset(2*ppu_lx+1, ppu_y-16, border_id);
                    }
                    // Рисование знакоместа
                    else if (ppu_x >= 72 && ppu_y >= 64 && ppu_y < 256 && (ppu_vx & 3) == 0) {
                        update_charline(lookupfb[ppu_y - 64] + (ppu_vx >> 2));
                    }
                }

                ppu_x++;
                if (ppu_x >= 224) {
                    ppu_x = 0;
                    ppu_y++;
                }
            }
        }

        t_states_cycle %= max_tstates;

        // Мерцающие элементы
        flash_counter++;
        if (flash_counter >= 25 || first_sta) {

            flash_counter = 0;
            first_sta     = 0;
            flash_state   = !flash_state;
        }

        // При наличии опции автостарта не кодировать PNG
        if (autostart <= 1 && con_pngout) encodebmp(audio_c);

        frame_counter++;
    }

    /*
     * Симулятор нажатия на клавиши
     **/

    void autostart_macro() {

        autostart++;
        switch (autostart) {

            case 1: autostart = 0; break;
            // Выполнение макроса RUN
            case 2: key_press(2, 0x08, 1); break; // R
            case 3: key_press(2, 0x08, 0); break;
            case 4: key_press(6, 0x01, 1); break; // ENT
            case 5: key_press(6, 0x01, 0); break;
            // Выключить или продолжать?
            case 6: autostart = 0; break;
        }

        // Симулятор нажатия на кнопки (SPACE)
        if (auto_keyb) {

            switch (frame_id) {

                case 25: key_press(7, 0x01, 1); break;
                case 26: key_press(7, 0x01, 0); break;
            }
        }

        frame_id++;
    }

    // Занесение нажатия в регистры
    void key_press(int row, int mask, int press) {

        if (press) {
            key_states[ row ] &= ~mask;
        } else {
            key_states[ row ] |=  mask;
        }
    }

#ifndef NO_SDL
    // Нажатие клавиши
    // https://www.libsdl.org/release/SDL-1.2.15/docs/html/sdlkey.html
    void keyb(int press, SDL_KeyboardEvent* eventkey) {

        int key = eventkey->keysym.sym;

        switch (key) {

            // Первый ряд
            case SDLK_1: key_press(3, 0x01, press); break;
            case SDLK_2: key_press(3, 0x02, press); break;
            case SDLK_3: key_press(3, 0x04, press); break;
            case SDLK_4: key_press(3, 0x08, press); break;
            case SDLK_5: key_press(3, 0x10, press); break;
            case SDLK_6: key_press(4, 0x10, press); break;
            case SDLK_7: key_press(4, 0x08, press); break;
            case SDLK_8: key_press(4, 0x04, press); break;
            case SDLK_9: key_press(4, 0x02, press); break;
            case SDLK_0: key_press(4, 0x01, press); break;

            // Второй ряд
            case SDLK_q: key_press(2, 0x01, press); break;
            case SDLK_w: key_press(2, 0x02, press); break;
            case SDLK_e: key_press(2, 0x04, press); break;
            case SDLK_r: key_press(2, 0x08, press); break;
            case SDLK_t: key_press(2, 0x10, press); break;
            case SDLK_y: key_press(5, 0x10, press); break;
            case SDLK_u: key_press(5, 0x08, press); break;
            case SDLK_i: key_press(5, 0x04, press); break;
            case SDLK_o: key_press(5, 0x02, press); break;
            case SDLK_p: key_press(5, 0x01, press); break;

            // Третий ряд
            case SDLK_a: key_press(1, 0x01, press); break;
            case SDLK_s: key_press(1, 0x02, press); break;
            case SDLK_d: key_press(1, 0x04, press); break;
            case SDLK_f: key_press(1, 0x08, press); break;
            case SDLK_g: key_press(1, 0x10, press); break;
            case SDLK_h: key_press(6, 0x10, press); break;
            case SDLK_j: key_press(6, 0x08, press); break;
            case SDLK_k: key_press(6, 0x04, press); break;
            case SDLK_l: key_press(6, 0x02, press); break;
            case SDLK_RETURN:    key_press(6, 0x01, press); break;
            case SDLK_KP_ENTER:  key_press(6, 0x01, press); break;

            // Четвертый ряд
            case SDLK_LSHIFT:   key_press(0, 0x01, press); break;
            case SDLK_z:        key_press(0, 0x02, press); break;
            case SDLK_x:        key_press(0, 0x04, press); break;
            case SDLK_c:        key_press(0, 0x08, press); break;
            case SDLK_v:        key_press(0, 0x10, press); break;
            case SDLK_b:        key_press(7, 0x10, press); break;
            case SDLK_n:        key_press(7, 0x08, press); break;
            case SDLK_m:        key_press(7, 0x04, press); break;
            case SDLK_RSHIFT:   key_press(7, 0x02, press); break;
            case SDLK_SPACE:    key_press(7, 0x01, press); break;

            // Специальные
            case SDLK_LEFT:         key_press(0, 0x01, press); key_press(3, 0x10, press); break; // SS+5
            case SDLK_RIGHT:        key_press(0, 0x01, press); key_press(4, 0x04, press); break; // SS+8
            case SDLK_UP:           key_press(0, 0x01, press); key_press(4, 0x08, press); break; // SS+7
            case SDLK_DOWN:         key_press(0, 0x01, press); key_press(4, 0x10, press); break; // SS+6
            case SDLK_TAB:          key_press(0, 0x01, press); key_press(7, 0x02, press); break; //  SS+CS
            case SDLK_BACKQUOTE:    key_press(0, 0x01, press); key_press(3, 0x01, press); break; // SS+1 EDIT
            case SDLK_CAPSLOCK:     key_press(0, 0x01, press); key_press(3, 0x02, press); break; // SS+2 CAP (DANGER)
            case SDLK_BACKSPACE:    key_press(0, 0x01, press); key_press(4, 0x01, press); break; // SS+0 BS
            case SDLK_ESCAPE:       key_press(0, 0x01, press); key_press(7, 0x01, press); break; // SS+SPC
            case SDLK_COMMA:        key_press(7, 0x02, press); key_press(7, 0x08, press); break; // ,
            case SDLK_PERIOD:       key_press(7, 0x02, press); key_press(7, 0x04, press); break; // .
            case SDLK_MINUS:        key_press(7, 0x02, press); key_press(6, 0x08, press); break; // -
            case SDLK_EQUALS:       key_press(7, 0x02, press); key_press(6, 0x02, press); break; // =
            case SDLK_KP_PLUS:      key_press(7, 0x02, press); key_press(6, 0x04, press); break; // +
            case SDLK_KP_MINUS:     key_press(7, 0x02, press); key_press(6, 0x08, press); break; // -
            case SDLK_KP_MULTIPLY:  key_press(7, 0x02, press); key_press(7, 0x10, press); break; // *
            case SDLK_KP_DIVIDE:    key_press(7, 0x02, press); key_press(0, 0x10, press); break; // /

            // Отладка
            case SDLK_F1: if (press) { loadbin("zexall", 0x8000); printf("ZXALL LOADED\n"); } break;
            case SDLK_F2: savez80("autosave.z80"); break;
            case SDLK_F3: loadz80("autosave.z80"); break;
        }
    }
#endif

    /*
     * Интерфейс
     */

    // 0x0000-0x3fff ROM
    // 0x4000-0x7fff BANK 2
    // 0x8000-0xbfff BANK 5
    // 0xc000-0xffff BANK 0..7

    int get_bank(int address) {

        int bank = 0;
        switch (address & 0xc000) {

            case 0x0000: bank = (port_7ffd & 0x30) ? 1 : 0; break;
            case 0x4000: bank = 5; break;
            case 0x8000: bank = 2; break;
            case 0xc000: bank = (port_7ffd & 7); break;
        }

        return bank*16384 + (address & 0x3fff);
    }

    // Чтение байта
    int mem_read(int address) {

        // Обращение к ROM 128k|48k (0 или 16384)
        if (address < 0x4000) return rom[get_bank(address)];

        return memory[get_bank(address)];
    }

    // Запись байта
    void mem_write(int address, int data) {

        address &= 0xffff;
        if (address < 0x4000) return;

        memory[get_bank(address)] = data;
    }

    // Чтение из порта
    int io_read(int port) {

        // Чтение клавиатуры
        if (port == 0x7ffd) {
            return port_7ffd;
        }
        else if (port == 0xFFFD) { return ay_register; }
        else if (port == 0xBFFD) { return ay_regs[ay_register%15]; }
        else if ((port & 1) == 0) {

            int result = 0xff;
            for (int row = 0; row < 8; row++) {
                if (!(port & (1 << (row + 8)))) {
                    result &= key_states[ row ];
                }
            }
            return result;
        }
        // Kempston Joystick
        else if ((port & 0x00e0) == 0x0000) {
            return 0x00;
        }

        return 0xff;
    }

    // Запись в порт
    void io_write(int port, int data) {

        if (port == 0x7ffd) {

            // Не менять бит D5 если он 1
            if ((port_7ffd & 0x20) && (data & 0x20) == 0)
                data |= 0x20;

            port_7ffd = data;
        }
        // AY address register
        else if (port == 0xFFFD) { ay_register = data; }
        // AY address data
        else if (port == 0xBFFD) { ay_write_data(data); }
        else if (port == 0x1FFD) { /* nothing */ }
        else if ((port & 1) == 0) {

            border_id = (data & 7);
            port_fe = data;
        }
    }

    // -----------------------------------------------------------------
    // Звук
    // -----------------------------------------------------------------

    // Получение тональности канала 0,1,2
    int ay_get_tone(int channel) { return ay_regs[2*channel] + 256*(ay_regs[2*channel+1]&15); }
    int ay_get_noise_period()    { return ay_regs[6] & 0x1f; }
    int at_get_env_period()      { return ay_regs[11] + (ay_regs[12]<<8); }

    void ay_write_data(int data) {

        int reg_id  = ay_register & 15;
        int tone_id = reg_id >> 1;

        ay_regs[reg_id] = data;

        switch (reg_id) {

            // Перенос во внутренний счетчик
            case 0: case 1:
            case 2: case 3:
            case 4: case 5:

                ay_tone_period[tone_id] = ay_get_tone(tone_id);

                if (ay_tone_period[tone_id] == 0) {
                    ay_tone_period[tone_id] = 1;
                }

                // Это типа чтобы звук не был такой обалдевший
                if (ay_tone_tick[tone_id] >= ay_tone_period[tone_id]*2)
                    ay_tone_tick[tone_id] %= ay_tone_period[tone_id]*2;

                break;

            // Сброс шума
            case 6:  ay_noise_tick = 0; break;
            case 13: ay_envelope_first = 1; break;
        }
    }

    // Тикер каждые 1/44100 секунды
    void ay_tick() {

        int mixer = ay_regs[7];

        // К периоду тона +2
        for (int _tone = 0; _tone < 3; _tone++) {

            int level = ay_tone_levels[ay_regs[8 + _tone] & 15];

            // Счетчик следующей частоты
            ay_tone_tick[_tone] += 2;

            // Тикер сработал
            if (ay_tone_tick[_tone] >= ay_tone_period[_tone]) {
                ay_tone_tick[_tone] %= ay_tone_period[_tone];

                // Переброска состояния 0->1
                ay_tone_high[_tone] = !ay_tone_high[_tone];

                // Канал разрешен -1..1
                if (!(mixer & (1 << _tone))) {
                    ay_amp[_tone] = level * ay_tone_high[_tone];
                }
            }
        }
    }

    // Добавить уровень
    void ay_amp_adder(int& left, int& right) {

        left  += ay_amp[0] + ay_amp[1];
        right += ay_amp[2] + ay_amp[1];

        if (left  > 255) left  = 255; else if (left  < 0) left  = 0;
        if (right > 255) right = 255; else if (right < 0) right = 0;
    }

    // -----------------------------------------------------------------
    // Работа с видеобуфером
    // -----------------------------------------------------------------

    uint get_color(int color) {

        switch (color) {
            case 0:  return 0x000000;
            case 1:  return 0x0000c0;
            case 2:  return 0xc00000;
            case 3:  return 0xc000c0;
            case 4:  return 0x00c000;
            case 5:  return 0x00c0c0;
            case 6:  return 0xc0c000;
            case 7:  return 0xc0c0c0;
            case 8:  return 0x000000;
            case 9:  return 0x0000FF;
            case 10: return 0xFF0000;
            case 11: return 0xFF00FF;
            case 12: return 0x00FF00;
            case 13: return 0x00FFFF;
            case 14: return 0xFFFF00;
            case 15: return 0xFFFFFF;
        }

        return 0;
    };

    // Обновить 8 бит
    void update_charline(int address) {

        address -= 0x4000;

        int Ya = (address & 0x0700) >> 8;
        int Yb = (address & 0x00E0) >> 5;
        int Yc = (address & 0x1800) >> 11;
        int MemBase = 0x4000*(port_7ffd & 0x08 ? 7 : 5);

        int y = Ya + Yb*8 + Yc*64;
        int x = address & 0x1F;

        int byte    = memory[ MemBase + address ];
        int attr    = memory[ MemBase + 0x1800 + x + ((address & 0x1800) >> 3) + (address & 0xE0) ];
        int bgcolor = (attr & 0x38) >> 3;
        int frcolor = (attr & 0x07) + ((attr & 0x40) >> 3);
        int flash   = (attr & 0x80) ? 1 : 0;
        int bright  = (attr & 0x40) ? 8 : 0;

        for (int j = 0; j < 8; j++) {

            int  pix = (byte & (0x80 >> j)) ? 1 : 0;

            // Если есть атрибут мерация, то учитывать это
            uint clr = bright | ((flash ? (pix ^ flash_state) : pix) ? frcolor : bgcolor);

            // Вывести пиксель
            pset(48 + 8*x + j, 48 + y, clr);
        }
    }

    // Установка точки
    void pset(int x, int y, uint color) {

        color &= 15;

        x -= 16;
        y -= 24;
        if (x >= 0 && y >= 0 && x < 320 && y < 240) {

#ifndef NO_SDL
            if (sdl_enable && sdl_screen) {
                for (int k = 0; k < 9; k++)
                    ( (Uint32*)sdl_screen->pixels )[ 3*(x + 3*320*y) + (k%3) + 3*320*(k/3) ] = get_color(color);
            }
#endif

            // Запись фреймбуфера
            unsigned int ptr = (239-y)*160+(x>>1);
            if (x&1) {
                fb[ptr] = (fb[ptr] & 0xf0) | (color);
            } else {
                fb[ptr] = (fb[ptr] & 0x0f) | (color<<4);
            }

            // Тест повторного кадра: если есть какое-то отличие, то ставить diff
            if (skip_dup_frame && pb[ptr] != fb[ptr]) diff_prev_frame = 1;
        }
    }

public:

    // Если sdl=0 то запуск без использования SDL
    Z80Spectrum(int sdl) {

#ifndef NO_SDL
        sdl_screen = NULL;
#endif
        width      = 320*3;
        height     = 240*3;
        sdl_enable = 1;
        first_sta  = 1;
        auto_keyb  = 0;
        frame_id   = 0;
        diff_prev_frame = 1; // Первый кадр всегда отличается

        t_states_cycle  = 0;
        flash_state     = 0;
        flash_counter   = 0;
        ms_clock_old    = 0;
        autostart       = 0;
        frame_counter   = 0;
        skip_dup_frame  = 0;

        port_7ffd       = 0x0010; // Первично указывает на 48k ROM
        border_id       = 0;
        port_fe         = 0;
        ay_envelope_first = 1;
        ay_noise_tick   = 0;
        skip_first_frames = 0;

        // Настройки записи фреймов
        con_frame_start = 0;
        con_frame_end   = 150;
        con_frame_fps   = 30;
        con_pngout      = 0;
        wav_cursor      = 0;
        t_states_wav    = 0;
        ab_cursor       = 0;
        png_file        = NULL;
        wave_file       = NULL;
#ifndef NO_SDL
        AudioSDLFrame   = 0; // SDL-фрейм позади основного
        AudioZXFrame    = 8; // Генеральный фрейм
#endif
        // Заполнение таблицы адресов
        for (int y = 0; y < 192; y++)
            lookupfb[y] = 0x4000 + 32*((y & 0x38)>>3) + 256*(y&7) + 2048*(y>>6);

        loadrom("48k.rom",  1);
        loadrom("128k.rom", 0);

        // Коррекция уровня
        for (int _f = 0; _f < 16; _f++) {
            ay_tone_levels[_f] = (ay_levels[_f]*256 + 0x8000) / 0xffff;
        }

        for (int _f = 0; _f < 3; _f++) {

            ay_tone_high[_f]   = 0;
            ay_tone_tick[_f]   = 0;
            ay_tone_period[_f] = 1;
        }

        // Все кнопки вначале отпущены
        for (int _i = 0; _i < 8; _i++)
            key_states[_i] = 0xff;
    }

    ~Z80Spectrum() {

#ifndef NO_SDL
        if (sdl_enable) SDL_Quit();
#endif

        // Финализация видеопотока
        if (png_file) fclose(png_file);

        // Финализация WAV
        if (wave_file) {
            waveFmtHeader();
            fclose(wave_file);
        }
    }

    // Разбор аргументов
    void args(int argc, char** argv) {

        for (int u = 1; u < argc; u++) {

            // Параметр
            if (argv[u][0] == '-') {

                switch (argv[u][1]) {

                    // Отключение SDL
                    case 'c': sdl_enable = 0; break;

                    // Включение последовательности автостарта (RUN ENT)
                    case 'a': autostart = 1; break;

                    // Файл для записи видео
                    case 'o':

                        con_pngout = 1;
                        if (strcmp(argv[u+1],"-") == 0) {
                            png_file = stdout;
                        } else {
                            png_file = fopen(argv[u+1], "w+");
                        }
                        u++;
                        break;

                    // Нажатие на пробел через некоторое время
                    case 'b':

                        auto_keyb = 1;
                        break;

                    // Пропуск кадров
                    case 'm':

                        sscanf(argv[u+1], "%d", &skip_first_frames); u++;
                        break;

                    // Длительность
                    case 'M':

                        sscanf(argv[u+1], "%d", &con_frame_end); u++;
                        con_frame_end *= 50;
                        break;

                    // Скип дублирующийся фреймов
                    case 's': skip_dup_frame = 1; break;

                    // 128k режим
                    case '2': port_7ffd = 0; break;

                    // Файл для записи звука
                    case 'w':

                        wave_file = fopen(argv[u+1], "wb");
                        if (wave_file == NULL) { printf("Can't open file %s for writing\n", argv[u+1]); exit(1); }
                        fseek(wave_file, 44, SEEK_SET);
                        u++;
                        break;
                }

            }
            // Загрузка файла
            else if (strstr(argv[u], ".z80") != NULL) {
                loadz80(argv[u]);
            }
            // Загрузка файла BAS с ленты
            else if (strstr(argv[u], ".tap") != NULL) {
                loadtap(argv[u]);
            }
        }
    }

    /**
     * Основной цикл работы VM
     */
    void main() {

#ifndef NO_SDL
        // Инициализация SDL
        if (sdl_enable) {

            SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
            SDL_EnableUNICODE(1);

            sdl_screen = SDL_SetVideoMode(3*320, 3*240, 32, SDL_HWSURFACE | SDL_DOUBLEBUF);
            SDL_WM_SetCaption("ZX Spectrum Virtual Machine", 0);
            SDL_EnableKeyRepeat(500, 30);

            // Количество семплов 882 x 50 = 44100
            audio_device.freq     = 44100;
            audio_device.format   = AUDIO_S8;
            audio_device.channels = 2;
            audio_device.samples  = 882;
            audio_device.callback = sdl_audio_buffer;
            audio_device.userdata = NULL;

            if (SDL_OpenAudio(& audio_device, NULL) < 0) {
                fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
                exit(1);
            }

            SDL_PauseAudio(0);

            while (1) {

                // Регистрация событий
                while (SDL_PollEvent(& event)) {
                    switch (event.type) {

                        case SDL_QUIT: return;
                        case SDL_KEYDOWN: keyb(1, & event.key); break;
                        case SDL_KEYUP:   keyb(0, & event.key); break;
                    }
                }

                // Вычисление разности времени
                ftime(&ms_clock);
                int time_curr = ms_clock.millitm;
                int time_diff = time_curr - ms_clock_old;
                if (time_diff < 0) time_diff += 1000;

                // Если прошло 20 мс
                if (time_diff >= 20) {

                    frame();

                    ms_clock_old = time_curr;
                    SDL_Flip(sdl_screen);
                }

                SDL_Delay(1);
            }
        }
        // Выполнение спектрума из консоли
        else
#endif
        {

            if (con_frame_end == 0) con_frame_end = 150; // 3 sec
            while (frame_counter < con_frame_end) frame();
        }
    }

    // Загрузка бинарника
    void loadbin(const char* filename, int address) {

        FILE* fp = fopen(filename, "rb");
        if (fp == NULL) { printf("BINARY %s not exists\n", filename); exit(1); }
        fseek(fp, 0, SEEK_END);
        int fsize = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        fread(memory + address, 1, fsize, fp);
        fclose(fp);
    }

    // Загрузка базового ROM
    void loadrom(const char* filename, int bank) {

        FILE* fp = fopen(filename, "rb");
        if (fp == NULL) { printf("ROM %s not exists\n", filename); exit(1); }
        fread(rom + 16384*bank, 1, 16384, fp);
        fclose(fp);
    }

    // Загрузка снапшота
    // https://worldofspectrum.org/faq/reference/z80format.htm
    // https://worldofspectrum.org/faq/reference/128kreference.htm
    void loadz80(const char* filename) {

        unsigned char data[128*1024];

        FILE* fp = fopen(filename, "rb");
        if (fp == NULL) { printf("Can't load file %s\n", filename); exit(1); }
        fseek(fp, 0, SEEK_END);
        int fsize = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        fread(data, 1, fsize, fp);
        fclose(fp);

        // Установка регистров
        a  = data[0];
        set_flags_register(data[1]);
        c  = data[2];
        b  = data[3];
        l  = data[4];
        h  = data[5];
        pc = data[6] + 256*data[7];
        sp = data[8] + 256*data[9];
        i  = data[10];
        r  = data[11];
        e  = data[13];
        d  = data[14];

        c_prime = data[15];
        b_prime = data[16];
        e_prime = data[17];
        d_prime = data[18];
        l_prime = data[19];
        h_prime = data[20];
        a_prime = data[21];
        set_flags_prime(data[22]);

        iy      = data[23] + 256*data[24];
        ix      = data[25] + 256*data[26];
        iff1    = data[27] ? 1 : 0;
        iff2    = data[28] ? 1 : 0;
        imode   = data[29] & 3;

        // старший бит R
        r |= ((data[12] & 1) << 7);

        // цвет бордюда
        io_write(0xFE, (data[12] & 0x0E) >> 1);

        int rle     = (data[12] & 0x20) == 0x20 ? 1 : 0;
        int address = 0x4000;
        int cursor  = 30;
        int version = 1;

        if (pc == 0) {

            int _len   = data[30] + 256*data[31];
            int _hmode = data[34];

            pc        = data[32] + 256*data[33];
            port_7ffd = data[35]; // 128k режим

            // AY данные
            ay_register = data[38];
            for (int _a = 0; _a < 16; _a++) ay_regs[_a] = data[39+_a];

            if (_len == 23)      { cursor = 55; version = 2; }
            else if (_len == 54) { cursor = 86; version = 3; }
            else if (_len == 55) { cursor = 87; version = 3; }

            if (version > 2) {

                sprintf(strbuf, "ZXCORE: Z80 file has %d version\n", version);
                fputs(strbuf, stderr);
                exit(1);
            }

            // Поддерживаемые режимы: 3,4(128k) 0,1(48k)
            if (_hmode != 0 && _hmode != 1 && _hmode != 3 && _hmode != 4) {

                sprintf(strbuf, "ZXCORE: Hardware mode is not 128k (mode=%d, pc=%x, cursor=%x)\n", _hmode, pc, cursor);
                fputs(strbuf, stderr);
                exit(1);
            }

            // Для 48k будет всегда регистр памяти равен 10h
            if (_hmode < 2) port_7ffd = 0x0010;

            // Следующий блок
            while (cursor < fsize) {

                int data_size = data[cursor] + data[cursor+1]*256;

                // Для 128k данные в [3..11]
                int data_bank = z80file_bankmap(_hmode, data[cursor + 2]);

                // Переход к данным
                cursor += 3;

                // Не скомпрессированные данные
                if (data_size == 0xffff) { rle = 0; data_size = 0x4000; } else rle = 1;

                // Вычислить следующий адрес
                address = (data_bank) * 0x4000;

                // Явно указать окончание данных
                int next = cursor + data_size;
                if (next > fsize) next = fsize;

                // Загрузка блока
                loadz80block(0, cursor, address, data, cursor + data_size, rle);
            }
        }
        // Обычная загрузка блока 48к (v1)
        else {

            loadz80block(1, cursor, address, data, fsize, rle);
        }
    }

    int z80file_bankmap(int mode, int bank) {

        // page0..7
        if (mode == 3 || mode == 4) {
            return bank - 3;
        }
        else if (mode == 0 || mode == 1) {

            switch (bank) {

                case 4: return 2; // 8000-bfff
                case 5: return 0; // c000-ffff
                case 8: return 5; // 4000-7fff
                default:

                    printf("Z80 loader: can't recognize bank %d for hmode=%d ", bank, mode);
                    exit(1);
            }
        }
    }

    // Загрузка блока в память
    void loadz80block(int mode, int& cursor, int &addr, unsigned char* data, int top, int rle) {

        if (rle) {

            while (cursor < top) {

                // EOF
                if (data[cursor]   == 0x00 &&
                    data[cursor+1] == 0xED &&
                    data[cursor+2] == 0xED &&
                    data[cursor+3] == 0x00) {
                    break;
                }

                // Процедура декомпрессии
                if (data[cursor]   == 0xED &&
                    data[cursor+1] == 0xED) {

                    for (int t_ = 0; t_ < data[cursor+2]; t_++) {

                        memory[c48k_address(addr, mode)] = data[cursor+3];
                        addr++;
                    }

                    cursor += 4;

                } else {

                    memory[c48k_address(addr, mode)] = data[cursor];

                    addr++;
                    cursor++;
                }
            }

        } else {

            while (cursor < top) {

                memory[c48k_address(addr, mode)] = data[cursor];
                addr++;
                cursor++;
            }
        }
    }

    // Для нормальной загрузки 48k z80 снапшотов (mode=1)
    int c48k_address(int address, int mode) {

        if (mode) {

            switch (address & 0xc000) {

                case 0x4000: return (address&0x3fff) + 5*0x4000; break;
                case 0x8000: return (address&0x3fff) + 2*0x4000; break;
                case 0xc000: return (address&0x3fff) + 0*0x4000; break;
            }
        }

        return address;
    }

    // https://sinclair.wiki.zxnet.co.uk/wiki/TAP_format
    void loadtap(const char* filename) {

        unsigned char tapfile[64*1024];

        FILE* fp = fopen(filename, "rb");
        if (fp == NULL) { printf("No file %s\n", filename); exit(1); }
        fseek(fp, 0, SEEK_END);
        int fsize = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        fread(tapfile, 1, fsize, fp);
        fclose(fp);

        if (tapfile[0x17] != 0xff) {
            printf("No BASIC program\n"); exit(1);
        }

        // Размер бейсик-программы
        int bsize = tapfile[0x15] + tapfile[0x16]*256 - 2;

        // Запись в программную область
        for (int q = 0; q < bsize; q++) memory[c48k_address(0x5ccb+q, 1)] = tapfile[0x18 + q];

        int endp = 0x5ccb + bsize;
        int next = endp;

        // END OF PROGRAM
        memory[c48k_address(endp, 1)]  = 0x80;
        memory[c48k_address(endp+1, 1)] = 0x0D; // Линия 1 (next+0)
        memory[c48k_address(endp+2, 1)] = 0x80; //         (next+1)
        memory[c48k_address(endp+3, 1)] = 0x22; //         (next+2)
        memory[c48k_address(endp+4, 1)] = 0x0D; // Линия 2 (next+3)
        memory[c48k_address(endp+5, 1)] = 0x80; //         (next+4)

        // VARS
        memory[c48k_address(0x5C4B, 1)] =  next & 255;
        memory[c48k_address(0x5C4C, 1)] = (next>>8) & 255;

        next++;

        // E-LINE :: https://skoolkid.github.io/rom/asm/5C59.html
        memory[c48k_address(0x5C59, 1)] =  next & 255;
        memory[c48k_address(0x5C5A, 1)] = (next>>8) & 255;

        // K-CUR - Address of cursor :: https://skoolkid.github.io/rom/asm/5C5B.html
        memory[c48k_address(0x5C5B, 1)] =  next & 255;
        memory[c48k_address(0x5C5C, 1)] = (next>>8) & 255;

        next += 2;

        // https://skoolkid.github.io/rom/asm/5C61.html
        memory[c48k_address(0x5C61, 1)] =  next & 255;
        memory[c48k_address(0x5C62, 1)] = (next>>8) & 255;

        // https://skoolkid.github.io/rom/asm/5C63.html
        memory[c48k_address(0x5C63, 1)] =  next & 255;
        memory[c48k_address(0x5C64, 1)] = (next>>8) & 255;

        // https://skoolkid.github.io/rom/asm/5C65.html
        memory[c48k_address(0x5C65, 1)] =  next & 255;
        memory[c48k_address(0x5C66, 1)] = (next>>8) & 255;

        next++;

        // https://skoolkid.github.io/rom/asm/5C5D.html
        memory[c48k_address(0x5C5D, 1)] =  next & 255;
        memory[c48k_address(0x5C5E, 1)] = (next>>8) & 255;

        next++;

        // NXTLIN :: https://skoolkid.github.io/rom/asm/5C55.html
        memory[c48k_address(0x5C55, 1)] =  next & 255;
        memory[c48k_address(0x5C56, 1)] = (next>>8) & 255;

/*
        // Всякие непонятные параметры. Оставлю на всякий случай
        memory[0x5C3B] = 0x84;

        memory[0x5C44] = 0xFF;
        memory[0x5C45] = 0xFE;

        memory[0x5C46] = 0xFF;
        memory[0x5C47] = 0x01;

        memory[0x5C5F] = 0xF8;
        memory[0x5C67] = 0x1B; // CALC B reg

        memory[0x5C74] = 0x01;
        memory[0x5C75] = 0x1A;
*/
        /*
        for (int _a = 0; _a < 21; _a++) {

            printf("%04X: ", 0x5c00 + _a*8);
            for (int _b = 0; _b < 8; _b++) {
                printf("%02X ", memory[0x5c00 + _a*8 + _b]);
            }
            printf("\n");
        }
        */
    }

    // Сохранение снапшота в файл (не RLE) 48k
    void savez80(const char* filename) {

        unsigned char data[48*1024];

        FILE* fp = fopen(filename, "wb+");

        // Установка регистров
        data[0] = a;
        data[1] = get_flags_register();
        data[2] = c;
        data[3] = b;
        data[4] = l;
        data[5] = h;
        data[6] = pc & 0xff;
        data[7] = (pc >> 8) & 0xff;
        data[8] = sp & 0xff;
        data[9] = (sp >> 8) & 0xff;
        data[10] = i;
        data[11] = (r & 0x7f);
        data[12] = (r >> 7) | ((border_id&7)<<1) | 0x00; // старший бит R, RLE=0
        data[13] = e;
        data[14] = d;
        data[15] = c_prime;
        data[16] = b_prime;
        data[17] = e_prime;
        data[18] = d_prime;
        data[19] = l_prime;
        data[20] = h_prime;
        data[21] = a_prime;
        data[22] = get_flags_prime();

        data[23] = iy & 0xff;
        data[24] = (iy >> 8) & 0xff;

        data[25] = ix & 0xff;
        data[26] = (ix >> 8) & 0xff;

        data[27] = iff1 ? 1 : 0;
        data[28] = iff2 ? 1 : 0;
        data[29] = imode;

        fwrite(data, 1, 30, fp);

        // Преобразовать память
        for (int _a = 0x4000; _a < 0x10000; _a++)
            data[_a - 0x4000] = memory[c48k_address(_a, 1)];

        fwrite(data, 1, 0xc000, fp);
        fclose(fp);
    }

    void encodebmp(int audio_c) {

        // Пропуск первых кадров
        if (skip_first_frames) {
            skip_first_frames--;
            return;
        }

        // Предыдущий кадр не отличается
        if (skip_dup_frame && diff_prev_frame == 0)
            return;

        struct BITMAPFILEHEADER head = {0x4D42, 38518, 0, 0, 0x76};
        struct BITMAPINFOHEADER info = {0x28, 320, 240, 1, 4, 0, 0x9600, 0xb13, 0xb13, 16, 0};
        unsigned char colors[64] = {
            0x00, 0x00, 0x00, 0x00, // 0
            0xc0, 0x00, 0x00, 0x00, // 1
            0x00, 0x00, 0xc0, 0x00, // 2
            0xc0, 0x00, 0xc0, 0x00, // 3
            0x00, 0xc0, 0x00, 0x00, // 4
            0xc0, 0xc0, 0x00, 0x00, // 5
            0x00, 0xc0, 0xc0, 0x00, // 6
            0xc0, 0xc0, 0xc0, 0x00, // 7
            0x00, 0x00, 0x00, 0x00, // 8
            0xff, 0x00, 0x00, 0x00, // 9
            0x00, 0x00, 0xff, 0x00, // 10
            0xff, 0x00, 0xff, 0x00, // 11
            0x00, 0xff, 0x00, 0x00, // 12
            0xff, 0xff, 0x00, 0x00, // 13
            0x00, 0xff, 0xff, 0x00, // 14
            0xff, 0xff, 0xff, 0x00  // 15
        };

        fwrite(&head, 1, sizeof(struct BITMAPFILEHEADER), png_file);
        fwrite(&info, 1, sizeof(struct BITMAPINFOHEADER), png_file);
        fwrite(&colors, 1, 64, png_file);
        fwrite(fb, 1, 160*240, png_file);

        // Запись некоторого количества фреймов в аудиобуфер
        if (audio_c && wave_file) {

            fwrite(audio_frame, 1, audio_c, wave_file);
            wav_cursor += audio_c;
        }

        // Копировать предыдущий кадр
        if (skip_dup_frame) {

            memcpy(pb, fb, 160*240);
            diff_prev_frame = 0;
        }
    }

    // Запись заголовка
    void waveFmtHeader() {

        struct WAVEFMTHEADER head = {
            0x46464952,
            (wav_cursor + 0x24),
            0x45564157,
            0x20746d66,
            16,     // 16=PCM
            1,      // Тип
            2,      // Каналы
            44100,  // Частота дискретизации
            88200,  // Байт в секунду
            2,      // Байт на семпл (1+1)
            8,      // Бит на семпл
            0x61746164, // "data"
            wav_cursor
        };

        fseek(wave_file, 0, SEEK_SET);
        fwrite(&head, 1, sizeof(WAVEFMTHEADER), wave_file);

    }
};
