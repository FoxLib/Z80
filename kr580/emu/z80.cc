#include <string.h>
#include "z80.h"

// Обработчик кадра
uint event_timer(uint interval, void *param) {

    SDL_Event     event;
    SDL_UserEvent userevent;

    /* Создать новый Event */
    userevent.type  = SDL_USEREVENT;
    userevent.code  = 0;
    userevent.data1 = NULL;
    userevent.data2 = NULL;

    event.type = SDL_USEREVENT;
    event.user = userevent;

    SDL_PushEvent(&event);
    return (interval);
}

int main(int argc, char** argv) {

    z80* zx = new z80("Z80-совместимый процессор");

    // Инициализацировать таймер
    SDL_AddTimer(20, event_timer, NULL);

    // Загрузка ROM
    if (argc > 1) {
        if (strstr(argv[1], ".z80")) {
            zx->loadbin("rom48.bin", 0);
            zx->loadz80(argv[1]);
        } else {
            zx->loadbin(argv[1], 0);
        }
    } else {
        zx->enable_halt = 0;
    }

    zx->repaint();
    zx->handle();

    return 0;
}
