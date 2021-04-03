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

public:

    // Если sdl=0 то запуск без использования SDL
    Z80Spectrum(int sdl) {

        sdl_screen  = NULL;
        width       = 320*3;
        height      = 240*3;

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
            if (time_diff >= ms_time_diff) {

                SDL_Flip(sdl_screen);
                ms_clock_old = time_curr;
            }

            SDL_Delay(1);
        }
    }

    // Установка точки
    void pset(int x, int y, uint color) {

        if (x >= 0 && y >= 0 && x < width && y < height) {
            ( (Uint32*)sdl_screen->pixels )[ x + width*y ] = color;
        }
    }
};
