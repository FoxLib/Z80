#include "SDL.h"

#include <sys/timeb.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>

class Z80Spectrum : public Z80 {
protected:

    SDL_Event       event;
    SDL_Surface*    sdl_screen;
    int             width, height;
    unsigned char   memory[65536];

    // Таймер обновления экрана
    unsigned int    ms_time_diff;
    struct timeb    ms_clock;
    unsigned int    ms_clock_old;

    int   flash_state, flash_counter;
    uint  border_color;

    int t_states_cycle, millis_per_frame, max_cycles_per_frame;

public:

    // Если sdl=0 то запуск без использования SDL
    Z80Spectrum(int sdl) {

        sdl_screen  = NULL;
        width       = 320*3;
        height      = 240*3;

        t_states_cycle = 0;
        flash_state    = 0;
        flash_counter  = 0;
        ms_clock_old   = 0;

        millis_per_frame     = 20;
        max_cycles_per_frame = millis_per_frame*3500;

        // Загрузка базового ROM
        FILE* fp = fopen("zx48.bin", "rb");
        if (fp == NULL) { printf("ROM zx48.bin not exists\n"); exit(1); }
        fread(memory, 1, 16384, fp);
        fclose(fp);

        // Инициализация SDL
        if (sdl) {

            SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
            SDL_EnableUNICODE(1);

            sdl_screen = SDL_SetVideoMode(width, height, 32, SDL_HWSURFACE | SDL_DOUBLEBUF);
            SDL_WM_SetCaption("ZX Spectrum Virtual Machine", 0);
            SDL_EnableKeyRepeat(500, 30);
        }
    }

    ~Z80Spectrum() {

        if (sdl_screen) SDL_Quit();
    }

    /**
     * Основной цикл работы VM
     */
    void main() {

        while (1) {

            // Регистрация событий
            while (SDL_PollEvent(& event)) {
                switch (event.type) {
                    case SDL_QUIT: return;
                }
            }

            // Вычисление разности времени
            ftime(&ms_clock);
            int time_curr = ms_clock.millitm;
            int time_diff = time_curr - ms_clock_old;
            if (time_diff < 0) time_diff += 1000;

            // Если прошло 20 мс
            if (time_diff >= 20) {

                ms_clock_old = time_curr;

                frame();

                // Мерцающие элементы
                flash_counter++;
                if (flash_counter >= 25) {
                    flash_counter = 0;
                    flash_state   = !flash_state;
                }

                SDL_Flip(sdl_screen);
            }

            SDL_Delay(1);
        }
    }

    // Обработка одного кадрового фрейма
    void frame() {

        int   fine_x = 0;
        int   border_x = 0, border_y = 0;

        // Выполнить необходимое количество циклов
        while (t_states_cycle < max_cycles_per_frame) {

            int t_states = run_instruction();
            t_states_cycle += t_states;

            // Каждый такт добавляет x + (320*240)/(70000)
            for (int t = 0; t < t_states; t++) {

                fine_x += (320*240);

                do {

                    // Рисование только лишь в определенных пределах
                    if (border_x < 32 || border_y < 24 || border_x >= 32+256 || border_y >= 24+192)
                        pset(border_x, border_y, border_color);

                    border_x++;
                    if (border_x >= 320) {
                        border_x = 0;
                        border_y++;
                    }

                    fine_x -= max_cycles_per_frame;
                }
                while (fine_x > max_cycles_per_frame);
            }
        }

        // Вызов прерывания
        interrupt(0, 0xff);

        t_states_cycle %= max_cycles_per_frame;
    }

    /*
     * Интерфейс
     */

    // Чтение байта
    int  mem_read(int address) {
        return memory[address & 0xffff];
    }

    // Запись байта
    void mem_write(int address, int data) {

        address &= 0xffff;
        if (address < 0x4000) return;

        memory[address] = data;

        // Обновление видеопамяти
        if (address < 0x5800)      update_charline(address);
        else if (address < 0x5B00) update_attrbox (address);
    }

    // Чтение из порта
    int io_read (int port) {

        return 0xff;
    }

    // Запись в порт
    void io_write(int port, int data) {

        if ((port & 0xFF) == 0xFE) {
            border_color = get_color(data & 7);
        }
    }

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
            pset(32 + 8*x + j, 24 + y, clr);
        }
    }

    // Обновить все атрибуты
    void update_attrbox(int address) {

        address -= 0x5800;

        int addr = 0x4000 + (address & 0x0FF) + ((address & 0x0300) << 3);
        for (int i = 0; i < 8; i++) {
            update_charline(addr + (i<<8));
        }
    };

    // Установка точки
    void pset(int x, int y, uint color) {

        if (x >= 0 && y >= 0 && x < 320 && y < 240) {

            if (sdl_screen) {

                for (int k = 0; k < 9; k++)
                    ( (Uint32*)sdl_screen->pixels )[ 3*(x + width*y) + (k%3) + width*(k/3) ] = color;

            } else {

                // stub
            }
        }
    }
};
