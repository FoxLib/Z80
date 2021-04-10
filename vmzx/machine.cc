/**
 * Основной цикл работы VM
 */
void Z80Spectrum::main() {

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
        audio_device.format   = AUDIO_U8;
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

// Разбор аргументов
void Z80Spectrum::args(int argc, char** argv) {

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

                    if (strcmp(argv[u+1],"-") == 0) {
                        record_file = stdout;
                    } else {
                        record_file = fopen(argv[u+1], "w+");
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
        // Загрузка файла SNA
        else if (strstr(argv[u], ".sna") != NULL) {
            loadsna(argv[u]);
        }
    }
}

// Симулятор автоматического нажатия на клавиши
void Z80Spectrum::autostart_macro() {

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
void Z80Spectrum::key_press(int row, int mask, int press) {

    if (press) {
        key_states[ row ] &= ~mask;
    } else {
        key_states[ row ] |=  mask;
    }
}

#ifndef NO_SDL
// Нажатие клавиши SDL
// https://www.libsdl.org/release/SDL-1.2.15/docs/html/sdlkey.html
void Z80Spectrum::keyb(int press, SDL_KeyboardEvent* eventkey) {

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
        case SDLK_F2: if (press) savesna("autosave.sna"); break;
        case SDLK_F3: if (press) loadsna("autosave.sna"); break;
    }
}
#endif
