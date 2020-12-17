#include "SDL.h"

#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#include "z80.h"
#include "fonts.h"

// Аудиобуфер
void audio_buffer(void* udata, unsigned char* stream, int len) {

    int vol = 32;

    // Выдача данных
    for (int i = 0; i < 882; i++) {

        int v = au_data_buffer[882*au_sdl_frame + i] ? vol : -vol;
        stream[i] = v; // L+R
    }

    // К следующему (если можно)
    if (au_sdl_frame != au_z80_frame) {
        au_sdl_frame = ((au_sdl_frame + 1) % 16);
    }
    // Если догнал - то отстать на несколько кадров
    else {
        au_sdl_frame = ((au_sdl_frame + 16) - 8) % 16;
    }
}

// Инициализация и включение окна
z80::z80(const char* caption) {

    width  = 832;
    height = 640;

    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER);
    SDL_EnableUNICODE(1);

    sdl_screen = SDL_SetVideoMode(width, height, 32, SDL_HWSURFACE | SDL_DOUBLEBUF);
    SDL_WM_SetCaption(caption, 0);

    // Количество семплов 882 x 50 = 44100
    audio_device.freq     = 44100;
    audio_device.format   = AUDIO_S8;
    audio_device.channels = 1;
    audio_device.samples  = 2*882;
    audio_device.callback = audio_buffer;
    audio_device.userdata = NULL;

    if (SDL_OpenAudio(& audio_device, NULL) < 0) {
        fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
        exit(1);
    }

    au_sdl_frame = 0;
    au_z80_frame = 0;

    SDL_PauseAudio(0);

    // Предварительные обнуления
    color_fore = 0xffffff;
    color_back = 0;

    border = 7;
    marque = 1;
    cycles = 0;
    ticker = 0;
    tstates = 0;

    ds_start = 0;
    ds_cursor = 0;

    // Процессор не запущен
    started = 0;
    rq_stop = 0;
    rq_start = 0;
    enable_halt = 1;

    ds_viewmode = 0;
    ds_dumpaddr = 0;
    bp_step_over = 0;

    // Регистры процессора
    halt = 0;
    reg.i = 0x00;
    reg.r = 0x00;
    reg.f = 0;

    iff0 = 0;
    iff1 = 0;
    delay_di = 0;
    delay_ei = 0;

    for (int i = 0; i < 8; i++) rows[i] = 0xFF;

    bp_count = 0;
    audio_out = 0;
}

void z80::stop_cpu() {

    started     = 0;
    ds_viewmode = 0;
    ds_cursor   = reg.pc;
    bp_step_over = 0;

    repaint();
}

void z80::start_cpu() {

    started     = 1;
    ds_viewmode = 1;
    repaint();
}

void z80::zx_row(int mode, int row, int mask) {

    if (mode == 0) {
        rows[ row ] &= ~mask;
    } else {
        rows[ row] |= mask;
    }
}

// mode: 0=press, 1=release
void z80::zx_kbd(int kp, int mode) {

    int row = 0, mask = 0;

    switch (kp) {

        /* 1 */   case 10: row = 3; mask = 0x01; break;
        /* 2 */   case 11: row = 3; mask = 0x02; break;
        /* 3 */   case 12: row = 3; mask = 0x04; break;
        /* 4 */   case 13: row = 3; mask = 0x08; break;
        /* 5 */   case 14: row = 3; mask = 0x10; break;

        /* 6 */   case 15: row = 4; mask = 0x10; break;
        /* 7 */   case 16: row = 4; mask = 0x08; break;
        /* 8 */   case 17: row = 4; mask = 0x04; break;
        /* 9 */   case 18: row = 4; mask = 0x02; break;
        /* 0 */   case 19: row = 4; mask = 0x01; break;

        /* Q */   case 24: row = 2; mask = 0x01; break;
        /* W */   case 25: row = 2; mask = 0x02; break;
        /* E */   case 26: row = 2; mask = 0x04; break;
        /* R */   case 27: row = 2; mask = 0x08; break;
        /* T */   case 28: row = 2; mask = 0x10; break;

        /* Y */   case 29: row = 5; mask = 0x10; break;
        /* U */   case 30: row = 5; mask = 0x08; break;
        /* I */   case 31: row = 5; mask = 0x04; break;
        /* O */   case 32: row = 5; mask = 0x02; break;
        /* P */   case 33: row = 5; mask = 0x01; break;

        /* A */   case 38: row = 1; mask = 0x01; break;
        /* S */   case 39: row = 1; mask = 0x02; break;
        /* D */   case 40: row = 1; mask = 0x04; break;
        /* F */   case 41: row = 1; mask = 0x08; break;
        /* G */   case 42: row = 1; mask = 0x10; break;

        /* H */   case 43: row = 6; mask = 0x10; break;
        /* J */   case 44: row = 6; mask = 0x08; break;
        /* K */   case 45: row = 6; mask = 0x04; break;
        /* L */   case 46: row = 6; mask = 0x02; break;
        /* Ent */ case 36: row = 6; mask = 0x01; break;

        /* Cap */ case 50: row = 0; mask = 0x01; break;
        /* Z */   case 52: row = 0; mask = 0x02; break;
        /* X */   case 53: row = 0; mask = 0x04; break;
        /* C */   case 54: row = 0; mask = 0x08; break;
        /* V */   case 55: row = 0; mask = 0x10; break;

        /* B  */  case 56: row = 7; mask = 0x10; break;
        /* N */   case 57: row = 7; mask = 0x08; break;
        /* M */   case 58: row = 7; mask = 0x04; break;
        /* Sym */ case 62: row = 7; mask = 0x02; break;
        /* Spc */ case 65: row = 7; mask = 0x01; break;

        // ------------------
        // SPECIAL KEYS
        // ------------------

        /* BKS */ case 22: zx_row(mode, 0, 0x01); zx_row(mode, 4, 0x01); return;
        /* ,   */ case 59: zx_row(mode, 7, 0x08); zx_row(mode, 7, 0x02); return;
        /* .   */ case 60: zx_row(mode, 7, 0x04); zx_row(mode, 7, 0x02); return;
        /* /   */ case 61: zx_row(mode, 0, 0x10); zx_row(mode, 7, 0x02); return;

        default:

            return;
    }

    zx_row(mode, row, mask);
}

// Обработка событий
void z80::handle() {

    int kp = 0;
    int i, j, k;
    int bp_delete, bp_found;
    int bdx = 0, bdy = 0, cstates;
    int bx, by, a, b;
    int auid, auip;

    char tmps[128];

    // Логирование инструкции
    #ifdef DEBUGLOG
    FILE* fp = fopen("cpu.log", "a+");
    #endif

    while (1) {

        // Каждые 1/50 сек вызов обработчика
        while (SDL_PollEvent(& event)) {

            switch (event.type) {

                // Если нажато на крестик, то приложение будет закрыто
                case SDL_QUIT: exit(0);

                // Нажата мышь
                case SDL_MOUSEBUTTONDOWN: break;

                // Кнопка мыши отжата
                case SDL_MOUSEBUTTONUP: break;

                // Нажата какая-то клавиша
                case SDL_KEYDOWN: {

                    kp = get_key(event);

                    //printf("%d ", kp);

                    // F7 Выполнение шага, если не запущен процессор
                    if (kp == 73) {

                        if (started == 0) {

                            step();                 // Шаг
                            ds_cursor = reg.pc;     // Курсор на PC
                            halt = 0;               // Отмена HALT
                            repaint();              // Перерисовка
                        }
                        // Остановка процессора (при завершении кадра)
                        else {
                            rq_stop = 1;
                        }
                    }
                    // F2 Установка прерывания
                    else if (kp == 68) {

                        // Ставить и удалить прерывания
                        if (started == 0 && ds_viewmode == 0) {

                            bp_delete = 0;

                            // Удалить
                            for (i = 0; i < bp_count; i++) {

                                if (bp_rows[i] == ds_cursor) {
                                    for (j = i; j < bp_count; j++) {
                                        bp_rows[j] = bp_rows[j + 1];
                                    }
                                    bp_delete = 1;
                                    bp_count--;
                                    break;
                                }
                            }

                            // Добавить
                            if (bp_delete == 0) {
                                bp_rows[bp_count++] = ds_cursor;
                            }

                            repaint();
                        }
                        // Сохранение, если мы находимся на экране ZXSpectrum
                        else if (ds_viewmode == 1) {
                            // ..
                        }
                    }
                    // F5 переключение режима
                    else if (kp == 71) {

                        ds_viewmode = 1 - ds_viewmode;
                        repaint();
                    }
                    // Ручной вызов прерывания
                    else if (kp == 72) {

                        if (started == 0) { do_interrupt(); ds_cursor = reg.pc; halt = 0; repaint(); }
                    }
                    else if (ds_viewmode == 0 && kp == 26) { enable_halt = 1 - enable_halt; repaint(); }
                    // F8 Step over
                    else if (kp == 74) { if (started) { rq_stop = 1; } else { rq_start = 1; bp_step_over = 1; bp_step_sp = reg.sp; bp_step_pc = reg.pc; } }
                    // F9 запуск
                    else if (kp == 75) { if (started) { rq_stop = 1; } else { rq_start = 1; } }
                    // Клавиша "вниз" в режиме дизассемблера
                    else if (kp == 116 && started == 0 && ds_viewmode == 0) {

                        if (ds_match_row < 29) {

                            ds_match_row++;
                            ds_cursor = ds_rowdis[ds_match_row];

                        } else {

                            ds_start  = ds_rowdis[30];
                            ds_cursor = ds_start;
                        }

                        repaint();
                    }
                    // Клавиша "вверх"
                    else if (kp == 111 && started == 0 && ds_viewmode == 0) {

                        if (ds_match_row > 0) {

                            ds_match_row--;
                            ds_cursor = ds_rowdis[ds_match_row];
                        }
                        else {

                            ds_cursor = (ds_cursor - 1) & 0xffff;
                            ds_start  = ds_cursor;
                        }

                        repaint();
                    }
                    // PGDN: Промотать вниз
                    else if (kp == 117 && started == 0 && ds_viewmode == 0) {

                        ds_cursor = ds_rowdis[30];
                        ds_start  = ds_cursor;
                        repaint();
                    }
                    // PGUP: Приблизительно перемотать наверх
                    else if (kp == 112 && started == 0 && ds_viewmode == 0) {

                        ds_cursor = (ds_cursor - (ds_rowdis[30] - ds_rowdis[0])) & 0xffff;
                        ds_start  = ds_cursor;
                        repaint();
                    }

                    // Прод
                    else if (ds_viewmode == 1 && started) zx_kbd(kp, 0);

                    break;
                }
                case SDL_KEYUP: {

                    kp = get_key(event);
                    if (ds_viewmode == 1) zx_kbd(kp, 1);

                    break;
                }

                // Вызывается по таймеру
                case SDL_USEREVENT: {

                    // Запрошена остановка процессора
                    if (rq_stop)       { stop_cpu();  }
                    // Запуск в работу
                    else if (rq_start) { start_cpu(); }

                    // Процессор работает
                    if (started) {

                        // Поиск прерываний
                        bp_found = 0;

                        // Вызов прерывания RST #38
                        if (iff0) { do_interrupt(); }

                        // Процессор работает, если HALT=0
                        if (halt == 0) {

                            // Рисование бордюра
                            bdx = bdy = 0;

                            while (tstates < 70000) {

                                // Поиск точки останова
                                for (j = 0; j < bp_count; j++) if (bp_rows[j] == reg.pc) { stop_cpu(); break; }

                                // Остановка процессора на следующем опкоде
                                if (bp_step_over) { if (bp_step_sp == reg.sp && bp_step_pc != reg.pc) { stop_cpu(); break; } }

                                // Если запрошен STOP CPU
                                if (started == 0) break;

                                // Выполнение шага
                                cstates  = step();
                                tstates += cstates;

                                // Запись данных в циклический буфер
                                auid = ((tstates % 70000) * 882) / 70000;

                                // Определить переход
                                if (auid != auip) {

                                    au_data_buffer[ 882*au_z80_frame + au_z80_id ] = audio_out;

                                    auip = auid;
                                    au_z80_id++;

                                    // Последовательная запись в буфер без обрыва потока
                                    if (au_z80_id == 882) {
                                        au_z80_id = 0;
                                        au_z80_frame = (au_z80_frame + 1) % 16;
                                    }

                                    #ifdef DEBUGLOG
                                    fprintf(fp, "%d = %d\n", auid, audio_out);
                                    #endif
                                }

                                // Аппаратная реализация "плавающих полос" на бордере
                                for (j = 0; j < cstates; j++) {

                                    bx = 3*bdx; by = 3*bdy;

                                    // Первичная проверка
                                    if (bx <= 32 || bx >= 796 || by <= 32 || by > 604) {

                                        // Рисование точки
                                        for (a = 0; a < 3; a++)
                                        for (b = 0; b < 3; b++) {

                                            bx = 3*bdx + a;
                                            by = 3*bdy + b;

                                            if (bx < 32 || bx >= 800 || by < 32 || by >= 608) {
                                                pset(bx, by, get_color(border));
                                            }
                                        }
                                    }

                                    // К следующей точке
                                    bdx++; if (bdx > 277) { bdx = 0; bdy++; }
                                }

                                // Остановка на HALT (если разрешен)
                                if (halt) {

                                    // Выход в дизассемблер
                                    if (enable_halt) { stop_cpu(); break; }

                                    // Досрочный выход, чтобы остановить CPU
                                    else break;
                                }
                            }

                            tstates %= 70000;
                        }
                        // Включение прерываний, если был запрос
                        else if (delay_ei) { iff0 = iff1 = 1; delay_ei = 0; }
                    }

                    // Обновление экрана каждые 25 кадров
                    if (++ticker == 25) {

                        ticker = 0;
                        marque = 1 - marque;

                        // Обновление только в режиме показа экрана
                        if (ds_viewmode == 1) {

                            // В случае если остановка процессора, то обновлять border все равно
                            if (halt == 1 && started) update_border();

                            repaint();
                        }

                        // На остановке очистить весь буфер
                        if (halt || ds_viewmode == 0) { for (i = 0; i < 16*882; i++) au_data_buffer[i] = audio_out; }
                    }

                    // Обнуление запросов на старт и стоп
                    rq_stop  = 0;
                    rq_start = 0;

                    flip();
                    break;
                }
            }
        }

        SDL_Delay(1);
    }
}

// Получение кода клавиши
int z80::get_key(SDL_Event event) {

    /* Получение ссылки на структуру с данными о нажатой клавише */
    SDL_KeyboardEvent * eventkey = & event.key;

    /* Получить скан-код клавиш */
    return eventkey->keysym.scancode;;
}

// Загрузка rom48.bin
void z80::loadbin(const char* filename, int addr) {

    FILE* fp = fopen(filename, "rb");

    if (fp) {

        fseek(fp, 0, SEEK_END);
        int fsize = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        fread(mem + addr, 1, fsize, fp);
        fclose(fp);

    } else {

        printf("%s not found\n", filename);
        exit(1);
    }
}

void z80::loadz80(const char* filename) {

    // Загрузка данных сюда
    unsigned char data[100*1024];
    int fsize = 0;

    FILE* fp = fopen(filename, "rb");

    if (fp) {

        fseek(fp, 0, SEEK_END);
        fsize = ftell(fp);
        fseek(fp, 0, SEEK_SET);
        fread(data, 1, fsize, fp);
        fclose(fp);

    } else {

        printf("%s not found\n", filename);
        exit(1);
    }

    reg.a  = data[0];
    reg.f  = data[1];
    reg.c  = data[2];
    reg.b  = data[3];
    reg.l  = data[4];
    reg.h  = data[5];
    reg.pc = data[6] + 256*data[7];
    reg.sp = data[8] + 256*data[9];
    reg.i  = data[10];
    reg.r  = data[11];
    reg.e  = data[13];
    reg.d  = data[14];

    reg.c_ = data[15];
    reg.b_ = data[16];
    reg.e_ = data[17];
    reg.d_ = data[18];
    reg.l_ = data[19];
    reg.h_ = data[20];
    reg.a_ = data[21];
    reg.f_ = data[22];

    reg.iy = data[23] + 256*data[24];
    reg.ix = data[25] + 256*data[26];
    iff0   = data[27] ? 1 : 0;
    iff1   = data[28] ? 1 : 0;
    im     = data[29] & 3;

    reg.r |= ((data[12] & 1) << 7);
    do_out(0xFE, (data[12] & 0x0E) >> 1);

    int rle = (data[12] & 0x20) ? 1 : 0;
    int addr   = 0x4000;
    int cursor = 30;

    // Подвести курсор
    ds_start  = reg.pc;
    ds_cursor = reg.pc;

    if (rle) {

        while (cursor < fsize) {

            // EOF
            if (data[cursor] == 0x00 && data[cursor+1] == 0xED && data[cursor+2] == 0xED && data[cursor+3] == 0x00) {
                break;
            }

            // Повторы
            if (data[cursor] == 0xED && data[cursor+1] == 0xED) {

                for (int i = 0; i < data[cursor+2]; i++) {

                    write_byte(addr, data[cursor+3]);
                    addr++;
                }

                cursor += 4;

            } else {

                write_byte(addr, data[cursor]);

                cursor++;
                addr++;
            }
        }

    } else {

        while (addr < 65536 && cursor < fsize) {

            write_byte(addr, data[cursor]);
            addr++;
            cursor++;
        }
    }


}

// Нарисовать точку
void z80::pset(int x, int y, uint color) {

    if (x >= 0 && y >= 0 && x < width && y < height) {
        ( (Uint32*)sdl_screen->pixels )[ x + width*y ] = color;
    }
}

// Обменять буфер
void z80::flip() {

    SDL_Flip(sdl_screen);
}

// ZX-spectrum цвет
int z80::get_color(int color) {

    switch (color) {

        case 1: return 0x0000c0;
        case 2: return 0xc00000;
        case 3: return 0xc000c0;
        case 4: return 0x00c000;
        case 5: return 0x00c0c0;
        case 6: return 0xc0c000;
        case 7: return 0xc0c0c0;
        case 9: return 0x0000ff;
        case 10: return 0xff0000;
        case 11: return 0xff00ff;
        case 12: return 0x00ff00;
        case 13: return 0x00ffff;
        case 14: return 0xffff00;
        case 15: return 0xffffff;
    }

    return 0;
}

// Обновление бордюра
void z80::update_border() {

    int i, j;

    // Левая и правая граница
    for (i = 0; i < height; i++)
    for (j = 0; j < 32; j++) {
        pset(j, i, get_color(border));
        pset(j+768+32, i, get_color(border));
    }

    // Верхняя и нижняя граница
    for (j = 32; j < width - 32; j++)
    for (i = 0; i < 32; i++) {
        pset(j, i, get_color(border));
        pset(j, i+576+32, get_color(border));
    }
}

// Обновить байт по адресу ADDR
void z80::update_video_byte(int addr) {

    // В режиме дизассемблера нельзя рисовать
    if (ds_viewmode == 0)
        return;

    // Обновление байта
    if (addr >= 0x4000 && addr < 0x5800) {

        // YY|yyy|YYY.xxxxx
        int x = addr & 31;
        int y = (addr >> 8) & 7 |
               ((addr >> 5) & 7) << 3 |
               ((addr >> 11) & 3) << 6;

        for (int k = 0; k < 8; k++) {

            int cx    = 8*x + k;
            int color = get_video_pixel(cx, y);

            for (int i = 0; i < 3; i++)
            for (int j = 0; j < 3; j++)
                pset(32+3*cx+j, 32+3*y+i, color);
        }
    }
    // Обновление атрибутов
    else if (addr >= 0x5800 && addr < 0x5B00) {

        addr -= 0x5800;

        int x = (addr & 31) * 8;
        int y = (addr >> 5) * 8;

        for (int i = 0; i < 24; i++)
        for (int j = 0; j < 24; j++) {
            pset(32+3*x+j, 32+3*y+i, get_video_pixel(x+j/3, y+i/3));
        }
    }
}

// Обновление одного пикселя x=0..255, y=0..191
int z80::get_video_pixel(int x, int y) {

    int color;
    int k = x & 7;

    // Вычисление видеоадреса
    int ad = (x>>3)
     |  ((y & 7) << 8)       // Y[0..2] в биты 8..10
     | (((y>>3) & 7) << 5)   // Y[3..5] в биты 5..7
     | (((y>>6) & 3) << 11); // Y[6..7] в биты 11..12

    int ch = mem[ 0x4000 + ad ];
    int at = mem[ 0x5800 + (x>>3) | ((y & 0xF8) << 2) ];

    int fr = (at & 7)      | ((at & 0x40) >> 3);
    int bg = (at >> 3) & 7 | ((at & 0x40) >> 3);

    // Мерцание
    if ((at & 0x80) && marque) { fr ^= bg; bg ^= fr; fr ^= bg;  }

    // Получение итогового цвета в заданной точке
    return get_color((ch & (1 << (7-k))) ? fr : bg);
}

// Обновить полностью весь дисплей (кратность 3x3 точки)
void z80::redraw() {

    int i, j;

    for (i = 0; i < 640; i++)
    for (j = 0; j < 832; j++) {

        if (j >= 32 && j < 800 && i >= 32 && i < 608) {

            int x = (j - 32) / 3,
                y = (i - 32) / 3;

            pset(j, i, get_video_pixel(x, y));

        }
        // Здесь бордер можно перерисовывать только в режиме отладки
        else if (started == 0) {
            pset(j, i, get_color(border));
        }

    }

    flip();
}

// Общий репаинт
void z80::repaint() {

    if (ds_viewmode == 0)
        disasm_repaint();
    else
        redraw();
}

// Очистка экрана в задний цвет
z80* z80::cls() {

    for (int i = 0; i < height; i++)
    for (int j = 0; j < width; j++)
        pset(j, i, color_back);

    return this;
}

// Установка цвета
z80* z80::color(int fore, int back) {

    color_fore = fore;
    color_back = back;

    return this;
}

// Печать одного символа на хосте (символ размером 8x10)
void z80::print_char(int x, int y, unsigned char ch) {

    int i, j;
    for (i = 0; i < 8; i++) {

        int mask = sysfont[8*ch + i];
        for (j = 0; j < 8; j++) {

            int color = (mask & (1<<(7-j))) ? color_fore : color_back;

            if (color >= 0) {
                for (int a = 0; a < 4; a++)
                    pset(16*x + 2*j + (a&1), 20*y + 2*i + (a>>1), color);
            }
        }
    }
}

// Печать строки с переносом по Y
void z80::print(int x, int y, const char* s) {

    int i = 0;
    while (s[i]) {

        print_char(x, y, s[i]);

        x++;
        if (8*x >= width) {
            x = 0;
            y++;
        }

        i++;
    }
}
