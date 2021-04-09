
// -----------------------------------------------------------------
// Работа с видеобуфером
// -----------------------------------------------------------------

// Обработка одного кадра http://www.zxdesign.info/vidparam.shtml
void Z80Spectrum::frame() {

    int req_int = 1;
    int audio_c = 0;

    // Sinclair ZX                Sinclair | Pentagon
    int max_tstates   = 71680; // 69888    | 71680 (или 70908)
    int rows_paper    = 64;    // 64       | 80
    int cols_paper    = 200;   // 200      | 68
    int irq_row       = 296;   // 296      | 304
    int ppu_x = 0, ppu_y = 0, ay_state = 0;

    max_audio_cycle = max_tstates*50;

    // Автоматическое нажимание на клавиши
    autostart_macro();

    // Выполнить необходимое количество циклов
    while (t_states_cycle < max_tstates) {

        // Вызвать прерывание именно здесь, перед инструкцией
        if (ppu_y == irq_row && req_int) { interrupt(0, 0xff); req_int = 0; }

        // Детект того, где находится луч в данный момент
        // -- mem_write | mem_read из contended memory в области рисования
        // -- io_write | io_read в области бордера

        // Вход в TRDOS : инструкция находится в адресе 3Dh
        if      (!trdos_latch && (pc & 0xff00) == 0x3d00) { trdos_latch = 1; }
        // Выход из TRDOS
        else if ( trdos_latch && (pc & 0xc000)) { trdos_latch = 0; }

        // Исполнение инструкции
        int t_states = run_instruction();
        t_states_cycle += t_states;

        // Запись в wav звука (учитывая автостарт)
        if (autostart <= 1) ay_sound_tick(t_states, audio_c);

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

uint Z80Spectrum::get_color(int color) {

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
void Z80Spectrum::update_charline(int address) {

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
void Z80Spectrum::pset(int x, int y, uint color) {

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

// -----------------------------------------------------------------
// Сохранение звука и видео
// -----------------------------------------------------------------

void Z80Spectrum::encodebmp(int audio_c) {

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
void Z80Spectrum::waveFmtHeader() {

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
