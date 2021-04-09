// -----------------------------------------------------------------
// Звук
// -----------------------------------------------------------------

// Получение тональности канала 0,1,2
int Z80Spectrum::ay_get_tone(int channel) { return ay_regs[2*channel] + 256*(ay_regs[2*channel+1]&15); }
int Z80Spectrum::ay_get_noise_period()    { return ay_regs[6] & 0x1f; }
int Z80Spectrum::at_get_env_period()      { return ay_regs[11] + (ay_regs[12]<<8); }

void Z80Spectrum::ay_write_data(int data) {

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
void Z80Spectrum::ay_tick() {

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
void Z80Spectrum::ay_amp_adder(int& left, int& right) {

    left  += ay_amp[0] + ay_amp[1];
    right += ay_amp[2] + ay_amp[1];

    if (left  > 255) left  = 255; else if (left  < 0) left  = 0;
    if (right > 255) right = 255; else if (right < 0) right = 0;
}
