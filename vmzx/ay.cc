
// Модифицикации огибающей
#define AY_ENV_CONT     8
#define AY_ENV_ATTACK   4
#define AY_ENV_ALT      2
#define AY_ENV_HOLD     1

// -----------------------------------------------------------------
// Звук
// -----------------------------------------------------------------

// Запись данных в регистр
void Z80Spectrum::ay_write_data(int data) {

    int reg_id  = ay_register & 15;
    int tone_id = reg_id >> 1;

    ay_last_data = data;

    ay_regs[reg_id] = data;

    switch (reg_id) {

        // Перенос во внутренний счетчик
        case 0: case 1:
        case 2: case 3:
        case 4: case 5:

            // Получение значения тона из регистров AY
            ay_tone_period[tone_id] = (ay_regs[reg_id&~1] + 256*(ay_regs[reg_id&~1|1] & 15));

            if (ay_tone_period[tone_id] == 0) {
                ay_tone_period[tone_id] = 1;
            }

            // Это типа чтобы звук не был такой обалдевший
            if (ay_tone_tick[tone_id] >= ay_tone_period[tone_id]*2)
                ay_tone_tick[tone_id] %= ay_tone_period[tone_id]*2;

            break;

        // Сброс шума
        case 6:

            ay_noise_tick   = 0;
            ay_noise_period = ay_regs[6] & 31;
            break;

        // Период огибающей
        case 11: case 12:

            ay_env_period = ay_regs[11] | (ay_regs[12] << 8);
            break;

        // Запись команды для огибающей
        case 13:

            ay_env_first = 1;
            ay_env_rev = 0;
            ay_env_internal_tick = ay_env_tick = ay_env_cycles = 0;
            ay_env_counter = (ay_regs[13] & AY_ENV_ATTACK) ? 0 : 15;
            break;
    }
}

// Тикер каждые 32 такта
void Z80Spectrum::ay_tick() {

    int mixer       = ay_regs[7];
    int envshape    = ay_regs[13];
    int noise_count = 1;

    // Задание уровней звука для тонов
    int levels[3];

    // Огибающая
    int env_level = ay_tone_levels[ ay_env_counter ];

    // Генерация начальных значений громкости
    for (int n = 0; n < 3; n++) {

        int g = ay_regs[8 + n];

        // Если 4-м бите громкости тона стоит единица, то взять громкость огибающей
        levels[n] = ay_tone_levels[(g & 16 ? ay_env_counter : g) & 15];
    }

    // Обработчик "огибающей" (envelope)
    ay_env_tick++;
    while (ay_env_tick >= ay_env_period) {

        ay_env_tick -= ay_env_period;

        // Выполнить первые 1/16 периодический INC/DEC если нужно
        // 1. Это первая запись в регистр r13
        // 2. Или это Cont=1 и Hold=0
        if (ay_env_first || ((envshape & AY_ENV_CONT) && !(envshape & AY_ENV_HOLD))) {

            // Направление движения: вниз (ATTACK=1) или вверх
            if (ay_env_rev)
                 ay_env_counter -= (envshape & AY_ENV_ATTACK) ? 1 : -1;
            else ay_env_counter += (envshape & AY_ENV_ATTACK) ? 1 : -1;

            // Проверка на достижения предела
            if      (ay_env_counter <  0) ay_env_counter = 0;
            else if (ay_env_counter > 15) ay_env_counter = 15;
        }

        ay_env_internal_tick++;

        // Срабатывает каждые 16 циклов AY
        while (ay_env_internal_tick >= 16) {

            ay_env_internal_tick -= 16;

            // Конец цикла для CONT, если CONT=0, то остановка счетчика
            if ((envshape & AY_ENV_CONT) == 0) {
                ay_env_counter = 0;
            }
            else {

                // Опция HOLD=1
                if (envshape & AY_ENV_HOLD) {

                    // Пилообразная фигура
                    if (ay_env_first && (envshape & AY_ENV_ALT))
                        ay_env_counter = (ay_env_counter ? 0 : 15);
                }
                // Опция HOLD=0
                else {

                    if (envshape & AY_ENV_ALT)
                         ay_env_rev     = !ay_env_rev;
                    else ay_env_counter = (envshape & AY_ENV_ATTACK) ? 0 : 15;
                }
            }

            ay_env_first = 0;
        }

        // Выход, если период нулевой
        if (!ay_env_period)
            break;
    }

    // Просмотреть все тоны
    for (int _tone = 0; _tone < 3; _tone++) {

        int level = levels[_tone];

        // При деактивированном тоне тут будет либо огибающая,
        // либо уровень, указанный в регистре тона
        ay_amp[_tone] = level;

        // Тон активирован
        if ((mixer & (1 << _tone)) == 0) {

            // Счетчик следующей частоты
            ay_tone_tick[_tone] += 2;

            // Переброска состояния 0->1,1->0
            if (ay_tone_tick[_tone] >= ay_tone_period[_tone]) {
                ay_tone_tick[_tone] %= ay_tone_period[_tone];
                ay_tone_high[_tone] = !ay_tone_high[_tone];
            }

            // Генерация меандра
            ay_amp[_tone] = ay_tone_high[_tone] ? level : 0;
        }

        // Включен шум на этом канале. Он работает по принципу
        // что если включен тон, и есть шум, то он притягивает к нулю
        if ((mixer & (8 << (_tone))) == 0 && ay_noise_toggle)
            ay_amp[_tone] = 0;
    }

    // Обновление noise-фильтра
    ay_noise_tick += noise_count;

    // Использовать генератор шума пока не будет достигнут нужный период
    while (ay_noise_tick >= ay_noise_period) {

        // Если тут 0, то все равно учитывать, чтобы не пропускать шум
        ay_noise_tick -= ay_noise_period;

        // Это псевдогенератор случайных чисел на регистре 17 бит
        // Бит 0: выход; вход: биты 0 xor 3.
        if ((ay_rng & 1) ^ ((ay_rng & 2) ? 1 : 0))
            ay_noise_toggle = !ay_noise_toggle;

        // Обновление значения
        if (ay_rng & 1) ay_rng ^= 0x24000; /* и сдвиг */ ay_rng >>= 1;

        // Если период нулевой, то этот цикл не закончится
        if (!ay_noise_period) break;
    }
}

// Добавить уровень
void Z80Spectrum::ay_amp_adder(int& left, int& right) {

    // Каналы A-слева; B-посередине; C-справа
    left  += (ay_amp[0] + ay_amp[1]) / 4;
    right += (ay_amp[2] + ay_amp[1]) / 4;

    // Потому что уши режет такой звук, сделал моно
    int center = (left + right) / 2;
    left  = center;
    right = center;

    if (left  > 255) left  = 255; else if (left  < 0) left  = 0;
    if (right > 255) right = 255; else if (right < 0) right = 0;
}

// Вызывается каждую 1/44100 секунду
void Z80Spectrum::ay_sound_tick(int t_states, int& audio_c) {

    // Гарантированное 44100 за max_audio_cycle (1 секунда)
    t_states_wav += 44100 * t_states;

    // К следующему звуковому тику
    if (t_states_wav > max_audio_cycle) {

        // Для аккуратного перекидывания остатков
        t_states_wav %= max_audio_cycle;

        // Порт бипера берется за основу тона
        int beep  = !!(port_fe & 0x10) ^ !!(port_fe & 0x08);
        int left  = 0x80 + (beep ? 0 : 32);
        int right = 0x80 + (beep ? 0 : 32);

        // Использовать AY
        ay_amp_adder(left, right);

        // Запись во временный буфер
        audio_frame[audio_c++] = left;
        audio_frame[audio_c++] = right;

#ifndef NO_SDL
        // Запись аудиострима в буфер (с циклом)
        AudioZXFrame = ab_cursor / 882;
        ZXAudioBuffer[ab_cursor++] = left;
        ZXAudioBuffer[ab_cursor++] = right;
        ab_cursor %= MAX_AUDIOSDL_BUFFER;
#endif
    }
}
