
// Конструктор
Z80Spectrum::Z80Spectrum() {

#ifndef NO_SDL
    sdl_screen = NULL;
#endif
    width               = 320*3;
    height              = 240*3;
    sdl_enable          = 1;
    first_sta           = 1;
    auto_keyb           = 0;
    frame_id            = 0;
    diff_prev_frame     = 1; // Первый кадр всегда отличается

    t_states_cycle      = 0;
    t_states_all        = 0;
    flash_state         = 0;
    flash_counter       = 0;
    ms_clock_old        = 0;
    autostart           = 0;
    frame_counter       = 0;
    skip_dup_frame      = 0;
    max_audio_cycle     = 0;
    sdl_disable_sound   = 0;

    port_7ffd           = 0x0010; // Первично указывает на 48k ROM
    border_id           = 0;
    port_fe             = 0;
    skip_first_frames   = 0;
    trdos_latch         = 0;

    wav_cursor          = 0;
    t_states_wav        = 0;
    ay_rng              = 1;
    ab_cursor           = 0;
    ay_noise_tick       = 0;
    ay_noise_period     = 0;
    ay_noise_toggle     = 0;
    ay_env_first        = 1;
    ay_env_rev          = 0;
    ay_env_period       = 0;

    // Настройки записи фреймов
    con_frame_start     = 0;
    con_frame_end       = 150;
    con_frame_fps       = 30;
    record_file         = NULL;
    wave_file           = NULL;

    ds_ad               = 0;
    ds_size             = 0;
    bp_count            = 0;
    ds_start            = 0;
    ds_cursor           = 0;
    ds_viewmode         = 1;
    ds_dumpaddr         = 0;
    ds_match_row        = 0;
    bp_step_over        = 0;
    bp_step_sp          = 0;
    bp_step_pc          = 0;
    ds_showfb           = 0;
    ds_halt_dump        = 0;

#ifndef NO_SDL
    AudioSDLFrame       = 0; // SDL-фрейм позади основного
    AudioZXFrame        = 8; // Генеральный фрейм
#endif

    // Заполнение таблицы адресов
    for (int y = 0; y < 192; y++) {
        lookupfb[y] = 0x4000 + 32*((y & 0x38)>>3) + 256*(y&7) + 2048*(y>>6);
    }

    // Обязательные ROM
    loadrom("48k.rom",   1);
    loadrom("128k.rom",  0);
    loadrom("trdos.rom", 4);

    // Коррекция уровня
    for (int _f = 0; _f < 16; _f++) {
        ay_tone_levels[_f] = (ay_levels[_f]*256 + 0x8000) / 0xffff;
    }

    for (int _f = 0; _f < 3; _f++) {
        ay_tone_high[_f]   = 0;
        ay_tone_tick[_f]   = 0;
        ay_tone_period[_f] = 1;
    }

    ay_regs[7] = 0xff;

    // Все кнопки вначале отпущены
    for (int _i = 0; _i < 8; _i++) {
        key_states[_i] = 0xff;
    }
}

// Деструктор при выходе
Z80Spectrum::~Z80Spectrum() {

#ifndef NO_SDL
    if (sdl_enable) SDL_Quit();
#endif

    // Финализация видеопотока
    if (record_file) {
        fclose(record_file);
    }

    // Финализация WAV
    if (wave_file) {
        waveFmtHeader();
        fclose(wave_file);
    }
}
