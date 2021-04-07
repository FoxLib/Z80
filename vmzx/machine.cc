#ifndef NO_SDL
#include "SDL.h"
#endif

/**
 * -a Автостарт с командой RUN
 * -o <файл> Вывод серии PNG в файл (если - то stdout)
 * -c Запускать без GUI SDL
 * <file>.(z80|tap) Загрузка снашпота или TAP бейсика
 * -M <секунды> длительность записи
 */

#include <sys/timeb.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "lodepng.cc"

// Видимая область: 224 x 312 = 69888 t-states
// Общая область: 352x296

class Z80Spectrum : public Z80 {
protected:

#ifndef NO_SDL
    SDL_Event       event;
    SDL_Surface*    sdl_screen;
#endif
    int             sdl_enable;
    int             width, height;
    unsigned int    fb[320*240];
    unsigned char   memory[65536];

    // Таймер обновления экрана
    unsigned int    ms_time_diff;
    struct timeb    ms_clock;
    unsigned int    ms_clock_old;

    int   flash_state, flash_counter;
    uint  border_color, border_id;
    int   key_states[8];
    int   t_states_cycle;

    // Консольная запись
    int   con_frame_start, con_frame_end, con_frame_fps;
    int   con_pngout;
    char* filename_pngout;
    FILE* png_file;
    int   first_sta;            // Досрочно обновить экран
    int   autostart;            // Автостарт при запуске
    int   frame_counter;        // Количество кадров от начала
    int   lookupfb[192];        // Для более быстрого определения адреса

    // Обработка одного кадра
    // http://www.zxdesign.info/vidparam.shtml
    void frame() {

        int req_int = 1;

        // Sinclair ZX                Sinclair | Pentagon
        int max_tstates   = 69888; // 69888    | 71680
        int rows_paper    = 64;    // 64       | 80
        int cols_paper    = 200;   // 200      | 68
        int irq_row       = 296;   // 296      | 304

        int ppu_x = 0,
            ppu_y = 0;

        // Автоматическое нажимание на клавиши
        autostart_macro();

        // Выполнить необходимое количество циклов
        while (t_states_cycle < max_tstates) {

            // Вызвать прерывание именно здесь, перед инструкцией
            if (ppu_y == irq_row && req_int) { interrupt(0, 0xff); req_int = 0; }

            // Исполнение инструкции
            int t_states = run_instruction();
            t_states_cycle += t_states;

            // 1 CPU = 2 PPU
            for (int w = 0; w < t_states; w++) {

                int ppu_vx = ppu_x - 72,
                    ppu_lx = ppu_x - 48;

                // Луч находится в видимой области
                if (ppu_y >= 16 && ppu_x >= 48) {

                    // Рисуется бордер [2x точки на 1 такт]
                    if (ppu_x < 72 || ppu_x >= cols_paper || ppu_y < rows_paper || ppu_y >= 256) {

                        pset(2*ppu_lx,   ppu_y-16, border_color);
                        pset(2*ppu_lx+1, ppu_y-16, border_color);
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

        // Включить вывод в PNG
        encodepng();

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
            case 6: autostart = 0; break;
        }
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

    // Чтение байта
    int mem_read(int address) {
        return memory[address & 0xffff];
    }

    // Запись байта
    void mem_write(int address, int data) {

        address &= 0xffff;
        if (address < 0x4000) return;
        memory[address] = data;
    }

    // Чтение из порта
    int io_read (int port) {

        // Чтение клавиатуры
        if ((port & 1) == 0) {

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

        if ((port & 1) == 0) {

            border_id    = data & 7;
            border_color = get_color(data & 7);
        }
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

        int byte = memory[ address ];

        address -= 0x4000;

        int Ya = (address & 0x0700) >> 8;
        int Yb = (address & 0x00E0) >> 5;
        int Yc = (address & 0x1800) >> 11;

        int y = Ya + Yb*8 + Yc*64;
        int x = address & 0x1F;

        int attr    = memory[ 0x5800 + x + ((address & 0x1800) >> 3) + (address & 0xE0) ];
        int bgcolor = get_color((attr & 0x38) >> 3);
        int frcolor = get_color((attr & 0x07) + ((attr & 0x40) >> 3));
        int flash   = (attr & 0x80) ? 1 : 0;

        for (int j = 0; j < 8; j++) {

            int  pix = (byte & (0x80 >> j)) ? 1 : 0;

            // Если есть атрибут мерация, то учитывать это
            uint clr = (flash ? (pix ^ flash_state) : pix) ? frcolor : bgcolor;

            // Вывести пиксель
            pset(48 + 8*x + j, 48 + y, clr);
        }
    }

    // Обновить все атрибуты
    void update_attrbox(int address) {

        address -= 0x5800;

        int addr = 0x4000 + (address & 0x0FF) + ((address & 0x0300) << 3);
        for (int _i = 0; _i < 8; _i++) {
            update_charline(addr + (_i<<8));
        }
    };

    // Установка точки
    void pset(int x, int y, uint color) {

        x -= 16;
        y -= 24;
        if (x >= 0 && y >= 0 && x < 320 && y < 240) {

#ifndef NO_SDL
            if (sdl_enable && sdl_screen) {
                for (int k = 0; k < 9; k++)
                    ( (Uint32*)sdl_screen->pixels )[ 3*(x + 3*320*y) + (k%3) + 3*320*(k/3) ] = color;
            }
#endif
            // Поменять цвета местами для PNG
            fb[y*320+x] = (color>>16)&255 | color & 0xff00 | ((color&255)<<16) | 0xff000000;
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

        t_states_cycle  = 0;
        flash_state     = 0;
        flash_counter   = 0;
        ms_clock_old    = 0;
        autostart       = 0;
        frame_counter   = 0;

        // Настройки записи фреймов
        con_frame_start = 0;
        con_frame_end   = 150;
        con_frame_fps   = 30;
        con_pngout      = 0;
        filename_pngout = NULL;
        png_file        = NULL;

        // Заполнение таблицы адресов
        for (int y = 0; y < 192; y++)
            lookupfb[y] = 0x4000 + 32*((y & 0x38)>>3) + 256*(y&7) + 2048*(y>>6);

        loadbin("basic48.rom", 0);

        // Все кнопки вначале отпущены
        for (int _i = 0; _i < 8; _i++) key_states[_i] = 0xff;
    }

    ~Z80Spectrum() {

#ifndef NO_SDL
        if (sdl_enable) SDL_Quit();
#endif
        if (png_file) fclose(png_file);
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

                        filename_pngout = argv[u+1];
                        con_pngout = 1;
                        if (strcmp(filename_pngout,"-") == 0) {
                            png_file = stdout;
                        } else {
                            png_file = fopen(filename_pngout, "w+");
                        }
                        u++;
                        break;

                    // Длительность
                    case 'M':

                        sscanf(argv[u+1], "%d", &con_frame_end);
                        con_frame_end *= 50;
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

        // Загрузка базового ROM
        FILE* fp = fopen(filename, "rb");
        if (fp == NULL) { printf("ROM %s not exists\n", filename); exit(1); }
        fseek(fp, 0, SEEK_END);
        int fsize = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        fread(memory + address, 1, fsize, fp);
        fclose(fp);
    }

    // Загрузка снапшота
    // https://worldofspectrum.org/faq/reference/z80format.htm
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

        if (pc == 0) {
            printf("Non 48k valid snapshot\n");
            exit(1);
        }

        // старший бит R
        r |= ((data[12] & 1) << 7);

        // цвет бордюда
        io_write(0xFE, (data[12] & 0x0E) >> 1);

        int rle    = (data[12] & 0x20) == 0x20 ? 1 : 0;
        int addr   = 0x4000;
        int cursor = 30;

        if (rle) {

            while (cursor < fsize) {

                // EOF
                if (data[cursor] == 0x00 && data[cursor+1] == 0xED && data[cursor+2] == 0xED && data[cursor+3] == 0x00) {
                    break;
                }

                // Процедура декомпрессии
                if (data[cursor] == 0xED && data[cursor+1] == 0xED) {

                    for (int t_ = 0; t_ < data[cursor+2]; t_++) {

                        if (addr >= 0x4000 && addr <= 0xFFFF) {
                            memory[addr] = data[cursor+3];
                        }

                        addr++;
                    }

                    cursor += 4;

                } else {

                    if (addr >= 0x4000 && addr <= 0xFFFF)
                        memory[addr] = data[cursor];

                    addr++;
                    cursor++;
                }
            }

        } else {

            while (addr < 65536 && cursor < fsize) {

                if (addr >= 0x4000 && addr <= 0xFFFF)
                    mem_write(addr, data[cursor]);

                addr++;
                cursor++;
            }
        }
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
        for (int q = 0; q < bsize; q++) memory[0x5ccb + q] = tapfile[0x18 + q];

        int endp = 0x5ccb + bsize;
        int next = endp;

        // END OF PROGRAM
        memory[endp ]  = 0x80;
        memory[endp+1] = 0x0D; // Линия 1 (next+0)
        memory[endp+2] = 0x80; //         (next+1)
        memory[endp+3] = 0x22; //         (next+2)
        memory[endp+4] = 0x0D; // Линия 2 (next+3)
        memory[endp+5] = 0x80; //         (next+4)

        // VARS
        memory[0x5C4B] =  next & 255;
        memory[0x5C4C] = (next>>8) & 255;

        next++;

        // E-LINE :: https://skoolkid.github.io/rom/asm/5C59.html
        memory[0x5C59] =  next & 255;
        memory[0x5C5A] = (next>>8) & 255;

        // K-CUR - Address of cursor :: https://skoolkid.github.io/rom/asm/5C5B.html
        memory[0x5C5B] =  next & 255;
        memory[0x5C5C] = (next>>8) & 255;

        next += 2;

        // https://skoolkid.github.io/rom/asm/5C61.html
        memory[0x5C61] =  next & 255;
        memory[0x5C62] = (next>>8) & 255;

        // https://skoolkid.github.io/rom/asm/5C63.html
        memory[0x5C63] =  next & 255;
        memory[0x5C64] = (next>>8) & 255;

        // https://skoolkid.github.io/rom/asm/5C65.html
        memory[0x5C65] =  next & 255;
        memory[0x5C66] = (next>>8) & 255;

        next++;

        // https://skoolkid.github.io/rom/asm/5C5D.html
        memory[0x5C5D] =  next & 255;
        memory[0x5C5E] = (next>>8) & 255;

        next++;

        // NXTLIN :: https://skoolkid.github.io/rom/asm/5C55.html
        memory[0x5C55] =  next & 255;
        memory[0x5C56] = (next>>8) & 255;

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

    // Сохранение снапшота в файл (не RLE)
    void savez80(const char* filename) {

        unsigned char data[64];

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
        fwrite(memory + 0x4000, 1, 0xc000, fp);
        fclose(fp);
    }

    // Кодировать в PNG-файл
    void encodepng() {

        unsigned       error;
        unsigned char* png;
        size_t         pngsize;
        LodePNGState   state;

        // При наличии опции автостарта не кодировать PNG
        if (autostart > 1)
            return;

        if (con_pngout) {

            lodepng_state_init(&state);
            error = lodepng_encode(&png, &pngsize, (const unsigned char*)fb, 320, 240, &state);

            // Пока что так сохраняется (!)
            if (!error) { fwrite(png, 1, pngsize, png_file); }

            /*if there's an error, display it*/
            if (error) printf("error %u: %s\n", error, lodepng_error_text(error));

            lodepng_state_cleanup(&state);
            free(png);
        }
    }
};
