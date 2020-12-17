#include "z80.h"

// Прочесть байт
int z80::read_byte(int addr) {
    return mem[addr & 0xffff];
}

// Прочесть слово
int z80::read_word(int addr) {
    return read_byte(addr) + 256*read_byte(addr+1);
}

// Записать байт
void z80::write_byte(int addr, int data) {

    data &= 0xff;
    addr &= 0xffff;

    mem[addr] = data;

    if (addr >= 0x4000 && addr < 0x5b00) {
        update_video_byte(addr);
    }
}

// Сохранить слово
void z80::write_word(int addr, int data) {

    write_byte(addr,     data);
    write_byte(addr + 1, data >> 8);
}

// Прочесть один байт
int z80::fetch_byte() {

    int rb = read_byte(reg.pc);
    reg.pc = (reg.pc + 1) & 0xffff;
    return rb;
}

// Прочесть слово
int z80::fetch_word() {

    int L = fetch_byte();
    int H = fetch_byte();
    return L + 256*H;
}

// Увеличение регистра R на 1
void z80::inc_r() {

    reg.r = (reg.r + 1) & 0x7f | (reg.r & 0x80);
}

// Чтение 16 бит
int z80::get_reg16(int r16) {

    switch (r16) {

        case 0: return reg.b*256 + reg.c;
        case 1: return reg.d*256 + reg.e;
        case 2:

            if (has_prefix == 1)
                return reg.ix;

            if (has_prefix == 2)
                return reg.iy;

            return reg.h*256 + reg.l;

        case 3: return reg.sp;
        case 4: return reg.a*256 + reg.f;
    }

    return 0;
}

// Положить данные в регистр R16
void z80::put_reg16(int r16, int data) {

    data &= 0xffff;

    int L = data & 0xff;
    int H = (data >> 8) & 0xff;

    switch (r16) {

        case 0: reg.b = H; reg.c = L; break;
        case 1: reg.d = H; reg.e = L; break;
        case 2:

            if (has_prefix == 1) {
                reg.ix = data;
            }
            else if (has_prefix == 2) {
                reg.iy = data;
            }
            else {
                reg.h = H;
                reg.l = L;
            }

            break;

        case 3: reg.sp = data; break;

        // Особый случай
        case 4: reg.a = H; reg.f = L; break;
    }
}

// Получение 8-битного регистра
int z80::get_reg8(int r8) {

    switch (r8 & 7) {

        case 0: return reg.b;
        case 1: return reg.c;
        case 2: return reg.d;
        case 3: return reg.e;

        // запись в H
        case 4:

            if (allow_undoc && has_prefix == 1)
                return (reg.ix & 0xff00) >> 8;
            else if (allow_undoc && has_prefix == 2)
                return (reg.iy & 0xff00) >> 8;
            else
                return reg.h;

        // запись в L
        case 5:

            if (allow_undoc && has_prefix == 1)
                return (reg.ix & 0x00ff);
            else if (allow_undoc && has_prefix == 2)
                return (reg.iy & 0x00ff);
            else
                return reg.l;

        case 6: return read_byte(address_hl);
        case 7: return reg.a;
    }

    return 0;
}

// Сохранить данные в регистре 0..7
void z80::put_reg8(int r8, int data) {

    data &= 0xff;

    switch (r8) {

        case 0: reg.b = data; break;
        case 1: reg.c = data; break;
        case 2: reg.d = data; break;
        case 3: reg.e = data; break;

        // запись в H
        case 4:

            if (allow_undoc && has_prefix == 1)
                reg.ix = (reg.ix & 0x00ff) | (data << 8);
            else if (allow_undoc && has_prefix == 2)
                reg.iy = (reg.iy & 0x00ff) | (data << 8);
            else
                reg.h = data;

            break;

        // запись в L
        case 5:

            if (allow_undoc && has_prefix == 1)
                reg.ix = (reg.ix & 0xff00) | (data);
            else if (allow_undoc && has_prefix == 2)
                reg.iy = (reg.iy & 0xff00) | (data);
            else
                reg.l = data;

            break;

        case 6: write_byte(address_hl, data); break;
        case 7: reg.a = data; break;
    }
}

// Прочесть префиксированные данные
void z80::fetch_prefixed_hl() {

    inc_r();
    int df = fetch_byte();

    if (has_prefix == 1) {
        address_hl = reg.ix;
    } else if (has_prefix == 2) {
        address_hl = reg.iy;
    } else {
        address_hl = reg.h*256 + reg.l;
    }

    if (df & 0x80) {
        address_hl += (df - 0x100);
    } else {
        address_hl += df;
    }

    // Ограничить
    address_hl &= 0xffff;
}

// Переход по относительному
void z80::conditional_relative(int cond) {

    int df = fetch_byte();

    if (cond) {

        cycles += 5;
        if (df & 0x80) reg.pc += (df - 0x100); else reg.pc += df;
    }

}

// Установка флага по его битам
void z80::set_flag(int bitflag, int value) {

    reg.f &= ~bitflag;
    reg.f |= (value ? bitflag : 0);
}

// Получение флага 0 или 1
int z80::get_flag(int bitflag) {
    return reg.f & bitflag ? 1 : 0;
}

// Обновление флагов X/Y
int z80::update_xy_flags(int result) {

    set_flag(FLAG_X, result & FLAG_X);
    set_flag(FLAG_Y, result & FLAG_Y);

    return result;
}

// Инкремент на +1
int z80::inc8(int operand) {

    int result = operand + 1;

    set_flag(FLAG_S,   result & 0x80);
    set_flag(FLAG_Z, !(result & 0xFF));
    set_flag(FLAG_H,  (operand & 0x0F) == 0x0F);
    set_flag(FLAG_P,   operand == 0x7F);
    set_flag(FLAG_N,   0);

    result &= 0xff;
    update_xy_flags(result);

    return result;
}

// Декремент на -1
int z80::dec8(int operand) {

    int result = operand - 1;

    set_flag(FLAG_S,   result & 0x80);
    set_flag(FLAG_Z, !(result & 0xFF));
    set_flag(FLAG_H,  (operand & 0x0F) == 0x00);
    set_flag(FLAG_P,  (operand == 0x80));
    set_flag(FLAG_N,   1);

    result &= 0xff;
    update_xy_flags(result);

    return result;
}

// Циклический сдвиг влево
int z80::do_rlc(int operand) {

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, operand & 0x80);

    operand = ((operand << 1) | get_flag(FLAG_C));
    operand &= 0xff;

    set_flag(FLAG_Z, !operand);
    set_flag(FLAG_P, parity_bits[operand]);
    set_flag(FLAG_S, operand & 0x80);

    return update_xy_flags(operand);
};

// Циклический сдвиг вправо
int z80::do_rrc(int operand) {

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, operand & 1);

    operand = ((operand >> 1) & 0x7f) | (get_flag(FLAG_C) << 7);
    operand &= 0xff;

    set_flag(FLAG_Z, !operand);
    set_flag(FLAG_P, parity_bits[operand]);
    set_flag(FLAG_S, operand & 0x80);

    return update_xy_flags(operand);
};

// Сдвиг влево
int z80::do_rl(int operand) {

    int temp = get_flag(FLAG_C);

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, operand & 0x80);

    operand = ((operand << 1) | temp);
    operand &= 0xff;

    set_flag(FLAG_Z, !operand);
    set_flag(FLAG_P, parity_bits[operand]);
    set_flag(FLAG_S, operand & 0x80);

    return update_xy_flags(operand);
};

// Сдвиг вправо
int z80::do_rr(int operand) {

    int temp = get_flag(FLAG_C);

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, operand & 1);

    operand = ((operand >> 1) & 0x7f) | (temp << 7);
    operand &= 0xff;

    set_flag(FLAG_Z, !operand);
    set_flag(FLAG_P, parity_bits[operand]);
    set_flag(FLAG_S, operand & 0x80);

    return update_xy_flags(operand);
};

// Сдвиг влево арифметический
int z80::do_sla(int operand) {

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, operand & 0x80);

    operand = (operand << 1);
    operand &= 0xff;

    set_flag(FLAG_Z, !operand);
    set_flag(FLAG_P, parity_bits[operand]);
    set_flag(FLAG_S, operand & 0x80);

    return update_xy_flags(operand);
};

// Сдвиг вправо арифметический
int z80::do_sra(int operand) {

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, operand & 1);

    operand = ((operand >> 1) & 0x7f) | (operand & 0x80);
    operand &= 0xff;

    set_flag(FLAG_Z, !operand);
    set_flag(FLAG_P, parity_bits[operand]);
    set_flag(FLAG_S, operand & 0x80);

    return update_xy_flags(operand);
};

// Сдвиг влево логический
int z80::do_sll(int operand) {

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, operand & 0x80);

    operand = ((operand << 1) & 0xff) | 1;
    operand &= 0xff;

    set_flag(FLAG_Z, !operand);
    set_flag(FLAG_P, parity_bits[operand]);
    set_flag(FLAG_S, operand & 0x80);

    return update_xy_flags(operand);
};

// Сдвиг вправо логический
int z80::do_srl(int operand) {

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, operand & 1);

    operand = (operand >> 1);
    operand &= 0x7f;

    set_flag(FLAG_Z, !operand);
    set_flag(FLAG_P, parity_bits[operand]);
    set_flag(FLAG_S, 0);

    return update_xy_flags(operand);
};

// Десятичная коррекция после сложения и вычитания
void z80::do_daa() {

    int temp = reg.a;

    if (!get_flag(FLAG_N))
    {
        if (get_flag(FLAG_H) || ((reg.a & 0x0f) > 9))
            temp += 0x06;

        if (get_flag(FLAG_C) || (reg.a > 0x99))
            temp += 0x60;
    }
    else
    {
        if (get_flag(FLAG_H) || ((reg.a & 0x0f) > 9))
            temp -= 0x06;

        if (get_flag(FLAG_C) || (reg.a > 0x99))
            temp -= 0x60;
    }

    set_flag(FLAG_S,   temp & 0x80);
    set_flag(FLAG_Z, !(temp & 0xff));
    set_flag(FLAG_H, ((reg.a & 0x10) ^ (temp & 0x10)));
    set_flag(FLAG_P,  parity_bits[temp & 0xff]);
    set_flag(FLAG_C,  get_flag(FLAG_C) || (reg.a > 0x99));

    reg.a = temp & 0xff;
    update_xy_flags(reg.a);
}

// Инверсия битов аккумулятора
void z80::do_cpl() {

    reg.a = (~reg.a) & 0xff;
    set_flag(FLAG_N, 1);
    set_flag(FLAG_H, 1);
    update_xy_flags(reg.a);
}

// Установка флага
void z80::do_scf() {

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_C, 1);

    update_xy_flags(reg.a);
}

// Комплементация флага для интегрального мыслетела
void z80::do_ccf() {

    set_flag(FLAG_N,  0);
    set_flag(FLAG_H,  get_flag(FLAG_C));
    set_flag(FLAG_C, !get_flag(FLAG_C));

    update_xy_flags(reg.a);
}

// Сложение HL|IX|IY с 16-битным регистром
void z80::do_hl_add(int operand) {

    int hl     = get_reg16(2);
    int result = hl + operand;

    set_flag(FLAG_N, 0);
    set_flag(FLAG_C, result & 0x10000);
    set_flag(FLAG_H, (((hl & 0x0fff) + (operand & 0x0fff)) & 0x1000));

    result &= 0xffff;
    put_reg16(2, result);
    update_xy_flags((result & 0xff00) >> 8);
}

// Сложение A + операнд
void z80::do_add(int operand) {

   int result = reg.a + operand;

   set_flag(FLAG_S,   result & 0x80);
   set_flag(FLAG_Z, !(result & 0xff));
   set_flag(FLAG_H, ((operand & 0x0f) + (reg.a & 0x0f)) & 0x10);
   set_flag(FLAG_P, ((reg.a & 0x80) == (operand & 0x80)) && ((reg.a & 0x80) != (result & 0x80)));
   set_flag(FLAG_N,   0);
   set_flag(FLAG_C,   result & 0x100);

   reg.a = result & 0xff;
   update_xy_flags(reg.a);
}

// Сложение A + операнд с заемом
void z80::do_adc(int operand) {

    int result = reg.a + operand + get_flag(FLAG_C);

    set_flag(FLAG_S,   result & 0x80);
    set_flag(FLAG_Z, !(result & 0xff));
    set_flag(FLAG_H, ((operand & 0x0f) + (reg.a & 0x0f) + get_flag(FLAG_C)) & 0x10);
    set_flag(FLAG_P, ((reg.a & 0x80) == (operand & 0x80)) && ((reg.a & 0x80) != (result & 0x80)));
    set_flag(FLAG_N,   0);
    set_flag(FLAG_C,   result & 0x100);

    reg.a = result & 0xff;
    update_xy_flags(reg.a);
}

// Вычитание А - операнд
void z80::do_sub(int operand) {

    int result = reg.a - operand;

    set_flag(FLAG_S,   result & 0x80);
    set_flag(FLAG_Z, !(result & 0xff));
    set_flag(FLAG_H, ((reg.a & 0x0f) - (operand & 0x0f)) & 0x10);
    set_flag(FLAG_P, ((reg.a & 0x80) != (operand & 0x80)) && ((reg.a & 0x80) != (result & 0x80)));
    set_flag(FLAG_N,   1);
    set_flag(FLAG_C,   result & 0x100);

    reg.a = result & 0xff;
    update_xy_flags(reg.a);
}

// Вычитание А - операнд с заемом
void z80::do_sbc(int operand) {

    int result = reg.a - operand - get_flag(FLAG_C);

    set_flag(FLAG_S,   result & 0x80);
    set_flag(FLAG_Z, !(result & 0xff));
    set_flag(FLAG_H, ((reg.a & 0x0f) - (operand & 0x0f) - get_flag(FLAG_C)) & 0x10);
    set_flag(FLAG_P, ((reg.a & 0x80) != (operand & 0x80)) && ((reg.a & 0x80) != (result & 0x80)));
    set_flag(FLAG_N,   1);
    set_flag(FLAG_C,   result & 0x100);

    reg.a = result & 0xff;
    update_xy_flags(reg.a);
}

// Поразрядное И
void z80::do_and(int operand) {

   reg.a &= operand; reg.a &= 0xff;

   set_flag(FLAG_S,  reg.a & 0x80);
   set_flag(FLAG_Z, !reg.a);
   set_flag(FLAG_H, 1);
   set_flag(FLAG_P, parity_bits[reg.a]);
   set_flag(FLAG_N, 0);
   set_flag(FLAG_C, 0);

   update_xy_flags(reg.a);
}

// Поразрядное Исключающее ИЛИ
void z80::do_xor(int operand) {

   reg.a ^= operand; reg.a &= 0xff;

   set_flag(FLAG_S,  reg.a & 0x80);
   set_flag(FLAG_Z, !reg.a);
   set_flag(FLAG_H, 0);
   set_flag(FLAG_P, parity_bits[reg.a]);
   set_flag(FLAG_N, 0);
   set_flag(FLAG_C, 0);

   update_xy_flags(reg.a);
}

// Поразрядное ИЛИ
void z80::do_or(int operand) {

    reg.a |= operand; reg.a &= 0xff;

   set_flag(FLAG_S,  reg.a & 0x80);
   set_flag(FLAG_Z, !reg.a);
   set_flag(FLAG_H, 0);
   set_flag(FLAG_P, parity_bits[reg.a]);
   set_flag(FLAG_N, 0);
   set_flag(FLAG_C, 0);

   update_xy_flags(reg.a);
}

// Вычитание без записи результата
void z80::do_cp(int operand) {

   int temp = reg.a;
   do_sub(operand);
   reg.a = temp;
   update_xy_flags(operand);
}

// Групповая арифметическо-логическая операция
void z80::aluop(int mode, int operand) {

    switch (mode) {

        case 0: do_add(operand); break;
        case 1: do_adc(operand); break;
        case 2: do_sub(operand); break;
        case 3: do_sbc(operand); break;
        case 4: do_and(operand); break;
        case 5: do_xor(operand); break;
        case 6: do_or(operand); break;
        case 7: do_cp(operand); break;
    }
}

// Негативити
void z80::do_neg() {

    reg.a = (-reg.a) & 0xff;

    set_flag(FLAG_S,   reg.a & 0x80);
    set_flag(FLAG_Z,  !reg.a);
    set_flag(FLAG_H, ((-reg.a) & 0x0f) > 0);
    set_flag(FLAG_P,   reg.a == 0x80);
    set_flag(FLAG_N,   1);
    set_flag(FLAG_C,   reg.a);

    update_xy_flags(reg.a);
}

// Сложение с заемом
void z80::adc_hl(int operand) {

    operand += get_flag(FLAG_C);

    int hl = reg.h*256 | reg.l;
    int result = hl + operand;

    set_flag(FLAG_S, result & 0x8000);
    set_flag(FLAG_Z, !(result & 0xffff));
    set_flag(FLAG_H, (((hl & 0x0fff) + (operand & 0x0fff)) & 0x1000));
    set_flag(FLAG_P, ((hl & 0x8000) == (operand & 0x8000)) && ((result & 0x8000) != (hl & 0x8000)));
    set_flag(FLAG_N, 0);
    set_flag(FLAG_C, (result & 0x10000));

    reg.l = result & 0xff;
    reg.h = (result >> 8) & 0xff;

    update_xy_flags(reg.h);
}

// Вычитание с заемом из HL
void z80::sbc_hl(int operand) {

    operand += get_flag(FLAG_C);

    int hl = reg.h*256 | reg.l;
    int result = hl - operand;

    set_flag(FLAG_S, result & 0x8000);
    set_flag(FLAG_Z, !(result & 0xffff));
    set_flag(FLAG_H, (((hl & 0x0fff) - (operand & 0x0fff)) & 0x1000));
    set_flag(FLAG_P, ((hl & 0x8000) != (operand & 0x8000)) && ((result & 0x8000) != (hl & 0x8000)));
    set_flag(FLAG_N, 1);
    set_flag(FLAG_C, result & 0x10000);

    reg.l = result & 0xff;
    reg.h = (result >> 8) & 0xff;

    update_xy_flags(reg.h);
}

// Записать в стек
void z80::push_word(int operand) {

    reg.sp = (reg.sp - 1) & 0xffff;
    write_byte(reg.sp, (operand & 0xff00) >> 8);

    reg.sp = (reg.sp - 1) & 0xffff;
    write_byte(reg.sp, operand & 0x00ff);
}

// Извлечь из стека
int z80::pop_word() {

    int retval = read_byte(reg.sp) & 0xff;
    reg.sp = (reg.sp + 1) & 0xffff;

    retval |= read_byte(reg.sp) << 8;
    reg.sp  = (reg.sp + 1) & 0xffff;

    return retval;
}

// mode=0-nz, 1-z, 2-nc, 3-c, 4-po, 5-pe, 6-p, 7-m
int z80::check_cond(int mode) {

    switch (mode) {

        case 0: return !get_flag(FLAG_Z); // NZ
        case 1: return  get_flag(FLAG_Z); //  Z
        case 2: return !get_flag(FLAG_C); // NC
        case 3: return  get_flag(FLAG_C); //  C
        case 4: return !get_flag(FLAG_P); // PO
        case 5: return  get_flag(FLAG_P); // PE
        case 6: return !get_flag(FLAG_S); //  P
        case 7: return  get_flag(FLAG_S); //  M
    }

    return 0;
}

// Чтение из порта
int z80::ioread(int port) {

    // Читать с клавиатуры или магнитолы
    int result = 0xFF;

    // Чтение из порта
    switch (port) {

        case 0xF0: result = spi_data; break;    // Данные с порта
        case 0xF1: result = 0x00;     break;    // Порт всегда готов BSY=0
        case 0xFE: result = port_kbd; break;
        case 0xFF: result = port_kbc; break;
    }

    return result & 0xff;
}

// Прочитать из порта
int z80::do_in(int port) {

    int result = ioread(port);

    set_flag(FLAG_S, result & 0x80);
    set_flag(FLAG_Z, !result);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_P, parity_bits[result]);
    set_flag(FLAG_N, 0);

    return update_xy_flags(result);
};

// Вывод
void z80::do_out(int port, int data) {

    switch (port & 0xFF) {

        case 0xF0: spi_write_data(data); break;
        case 0xF1: spi_write_cmd(data); break;
        // 0xF2: -- защелка, обязательна --

        case 0xFE:

            border    = data & 7;
            audio_out = (data & 0x10) ^ ((data & 0x08)<<1) ? 1 : 0;

            update_border();
            break;
    }
}

// A[3:0] -> (HL)[7:4], (HL)[3..0] -> A[3:0]
void z80::rrd() {

    int hl_value = read_byte(reg.l | 256*reg.h);
    int temp1 = hl_value & 0x0f, // Hv[3:0]
        temp2 = reg.a & 0x0f;    //  A[3:0]

    // Hv = {a[3:0], Hv[7:4]} Предыдущий контент A[3:0] в старшем ниббле, а старший сместился в младший
    hl_value = ((hl_value & 0xf0) >> 4) | (temp2 << 4);

    //  A = {a[7:4], Hv[3:0]} Скопированы (HL)[3:0] в A[3:0]
    reg.a = (reg.a & 0xf0) | temp1;
    write_byte(reg.l | 256*reg.h, hl_value);

    // Как я понял, это для BCD сделано
    set_flag(FLAG_S, reg.a & 0x80);
    set_flag(FLAG_Z, reg.a);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_P, parity_bits[reg.a & 0xff]);
    set_flag(FLAG_N, 0);

    update_xy_flags(reg.a);
}

// Тоже самое, только налево
void z80::rld() {

    int hl_value = read_byte(reg.l | 256*reg.h);

    int temp1 = hl_value & 0xf0, // Hv[7:4]
        temp2 = reg.a & 0x0f;   //  A[3:0]

    // Hv = {Hv[3:0], A[3:0]}
    hl_value = ((hl_value & 0x0f) << 4) | temp2;

    //  A = {A[7:4], Hv[7:4]}
    reg.a = (reg.a & 0xf0) | (temp1 >> 4);
    write_byte(reg.l | 256*reg.h, hl_value);

    set_flag(FLAG_S, reg.a & 0x80);
    set_flag(FLAG_Z, reg.a);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_P, parity_bits[reg.a & 0xff]);
    set_flag(FLAG_N, 0);

    update_xy_flags(reg.a);
}

// Прерывание 1/50
void z80::do_interrupt() {

    inc_r();

    halt = 0;
    iff0 = 0;
    iff1 = 0;

    // 8080 совместимый
    if (im == 0) {

        push_word(reg.pc); reg.pc = 0x38; // data=0xFF RST #38
        cycles += (7+2);
    }
    // Нормальный режим
    else if (im == 1) {

        push_word(reg.pc);
        reg.pc = 0x38;
        cycles += 13;
    }
    // Пользовательское прерывание
    else if (im == 2) {

        push_word(reg.pc);
        int vector_address = ((reg.i << 8) | 0xFF);
        reg.pc = read_word(vector_address);
        cycles += 19;
    }
}

// Перемещение (HL++) => (DE++)
void z80::do_ldi() {

    int read_value = read_byte(reg.l | (reg.h << 8));
    write_byte(reg.e | (reg.d << 8), read_value);

    // DE++
    int result = (reg.e | (reg.d << 8)) + 1;
    reg.e = result & 0xff;
    reg.d = (result & 0xff00) >> 8;

    // HL++
    result = (reg.l | (reg.h << 8)) + 1;
    reg.l = result & 0xff;
    reg.h = (result & 0xff00) >> 8;

    // BC--
    result = (reg.c | (reg.b << 8)) - 1;
    reg.c = result & 0xff;
    reg.b = (result & 0xff00) >> 8;

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_P, reg.c || reg.b);
    set_flag(FLAG_X, (reg.a + read_value) & 0x08);
    set_flag(FLAG_Y, (reg.a + read_value) & 0x02);
};

// Перемещение (HL--) => (DE--)
void z80::do_ldd() {

    int read_value = read_byte(reg.l | (reg.h << 8));
    write_byte(reg.e | (reg.d << 8), read_value);

    // DE--
    int result = (reg.e | (reg.d << 8)) - 1;
    reg.e = result & 0xff;
    reg.d = (result & 0xff00) >> 8;

    // HL--
    result = (reg.l | (reg.h << 8)) - 1;
    reg.l = result & 0xff;
    reg.h = (result & 0xff00) >> 8;

    // BC--
    result = (reg.c | (reg.b << 8)) - 1;
    reg.c = result & 0xff;
    reg.b = (result & 0xff00) >> 8;

    set_flag(FLAG_N, 0);
    set_flag(FLAG_H, 0);
    set_flag(FLAG_P, reg.c || reg.b);
    set_flag(FLAG_Y, (reg.a + read_value) & 0x02);
    set_flag(FLAG_X, (reg.a + read_value) & 0x08);
}

// Сравнение строк
void z80::do_cpid(int dir) {

    int temp_carry = get_flag(FLAG_C);
    int read_value = read_byte(reg.l | (reg.h << 8));

    do_cp(read_value);

    set_flag(FLAG_C, temp_carry);
    set_flag(FLAG_Y, (reg.a - read_value - get_flag(FLAG_H)) & 0x02);
    set_flag(FLAG_X, (reg.a - read_value - get_flag(FLAG_H)) & 0x08);

    // HL++ | HL--
    int result = (reg.l | (reg.h << 8)) + dir;
    reg.l = result & 0xff;
    reg.h = (result & 0xff00) >> 8;

    // BC--
    result = (reg.c | (reg.b << 8)) - 1;
    reg.c = result & 0xff;
    reg.b = (result & 0xff00) >> 8;

    set_flag(FLAG_P, result);
}

void z80::do_inid(int dir) {

    reg.b = dec8(reg.b);
    write_byte(reg.l | (reg.h << 8), ioread((reg.b << 8) | reg.c));

    int result = (reg.l | (reg.h << 8)) + dir;
    reg.l = result & 0xff;
    reg.h = (result & 0xff00) >> 8;

    set_flag(FLAG_N, 1);
}

// Вывод в порт
void z80::do_outid(int dir) {

    do_out((reg.b << 8) | reg.c, read_byte(reg.l | (reg.h << 8)));

    int result = (reg.l | (reg.h << 8)) + dir;
    reg.l = result & 0xff;
    reg.h = (result & 0xff00) >> 8;

    reg.b = dec8(reg.b);
    set_flag(FLAG_N, 1);
}

// Выполнить один шаг
int z80::step() {

    int tmp;
    int cycles_init = cycles;

    // Есть ли префикс?
    has_prefix  = 0;

    // Разрешение недокументированных чтения и записи IXH, IYH
    allow_undoc = 1;

    // Адрес по умолчанию. Может заменяться на IX|IY+d
    address_hl  = 256*reg.h | reg.l;

    // -----------------------------------------------------------------
    // Читать опкод и префиксы
    // -----------------------------------------------------------------

    do {

        inc_r();
        cycles += 4;
        opcode = fetch_byte();

        // Детектед префиксарни
        if (opcode == 0xDD) has_prefix = 1;
        if (opcode == 0xFD) has_prefix = 2;
    }
    while (opcode == 0xDD || opcode == 0xFD);

    // -----------------------------------------------------------------
    // Выполнение опкодов
    // -----------------------------------------------------------------

    // Битовые
    if (opcode == 0xCB) {

        // Считывание префикса, если он есть
        if (has_prefix) fetch_prefixed_hl(); else inc_r();

        cycles += 4;
        opcode = fetch_byte();

        int a8 = (opcode & 0x38) >> 3;
        int b8 = (opcode & 0x07);
        int bitz;

        // 00 xxx xxx | Сдвиговые
        if ((opcode & 0xc0) == 0x00) {

            if (has_prefix) cycles += 11; else if (b8 == 6) { cycles += 7; }
            tmp = get_reg8(has_prefix ? 6 : b8);

            switch (a8) {

                case 0: tmp = do_rlc(tmp); break;
                case 1: tmp = do_rrc(tmp); break;
                case 2: tmp = do_rl(tmp); break;
                case 3: tmp = do_rr(tmp); break;
                case 4: tmp = do_sla(tmp); break;
                case 5: tmp = do_sra(tmp); break;
                case 6: tmp = do_sll(tmp); break;
                case 7: tmp = do_srl(tmp); break;
            }

            // Запись в память или регистр
            put_reg8(b8, tmp);
        }
        // 01 xxx xxx | BIT n, r8
        else if ((opcode & 0xc0) == 0x40) {

            // Вычисление циклов
            if (has_prefix) cycles += 8; else if (b8 == 6) cycles += 4;
            tmp = get_reg8(has_prefix ? 6 : b8);

            set_flag(FLAG_Z, tmp & (1 << a8) ? 0 : 1);
            bitz = get_flag(FLAG_Z);

            set_flag(FLAG_N, 0);
            set_flag(FLAG_H, 1);
            set_flag(FLAG_P, bitz);
            set_flag(FLAG_S, (a8 == 7) && !bitz);
            set_flag(FLAG_Y, (a8 == 5) && !bitz);
            set_flag(FLAG_X, (a8 == 3) && !bitz);
        }
        // 10 xxx xxx | RES n, r8
        // 11 xxx xxx | SET n, r8
        else if ((opcode & 0xc0) == 0x80 || (opcode & 0xc0) == 0xc0) {

            // Вычисление циклов
            if (has_prefix) cycles += 11; else if (b8 == 6) cycles += 7;
            tmp = get_reg8(has_prefix ? 6 : b8);

            if ((opcode & 0xc0) == 0x80)
                tmp &= (~(1 << a8)); // RES
            else
                tmp |= (1 << a8);    // SET

            put_reg8(b8, tmp);
        }
    }
    // Специальные
    else if (opcode == 0xED) {

        inc_r(); cycles += 4;   // R++ C+=4
        opcode = fetch_byte();  // Прочесть опкод
        has_prefix = 0;         // EDh не поддерживает префиксы

        int a8   = (opcode & 0x38) >> 3;
        int b8   = (opcode & 0x07);
        int a16  = (opcode & 0x30) >> 4;
        int opc7 = (opcode & 0xc7);
        int opcf = (opcode & 0xcf);

        // 01 xxx 000 | IN r8, (c)
        if (opc7 == 0x40) {

            cycles += 4;
            tmp = do_in(256*reg.b | reg.c);
            if (a8 != 6) put_reg8(a8, tmp);
        }
        // 01 xxx 001 | OUT (c), r8
        else if (opc7 == 0x41) {

            cycles += 4;
            do_out(256*reg.b | reg.c, a8 == 6 ? 0 : get_reg8(a8));
        }
        // 01 xx0 011 | LD (**), r16
        else if (opcf == 0x43) {

            cycles += 12;
            write_word(fetch_word(), get_reg16(a16));
        }
        // 01 xxx 100 | NEG
        else if (opc7 == 0x44) { do_neg(); }
        // 01 xx1 011 | LD r16, (**)
        else if (opcf == 0x4b) {

            cycles += 12;
            put_reg16(a16, read_word(fetch_word()));
        }
        // 01 xxx 110 | IM n
        else if (opc7 == 0x46) { im = imid[a8]; }
        // 01 xxx 101 | RETN
        else if (opc7 == 0x45) {

            cycles += 6;
            reg.pc = pop_word();
            if (opcode != 0x4D) iff0 = iff1; // Кроме RETI
        }
        // 01 xx0 010 | SBC HL, r16
        // 01 xx1 010 | ADC HL, r16
        else if (opcf == 0x42) { cycles += 7; sbc_hl(get_reg16(a16)); }
        else if (opcf == 0x4A) { cycles += 7; adc_hl(get_reg16(a16)); }
        // Строковые
        else if (opcode == 0xA0) { cycles += 8; do_ldi(); }
        else if (opcode == 0xA8) { cycles += 8; do_ldd(); }
        else if (opcode == 0xA1) { cycles += 8; do_cpid(1); }
        else if (opcode == 0xA2) { cycles += 8; do_inid(1); }
        else if (opcode == 0xA3) { cycles += 8; do_outid(1); }
        else if (opcode == 0xA9) { cycles += 8; do_cpid(-1); }
        else if (opcode == 0xAA) { cycles += 8; do_inid(-1); }
        else if (opcode == 0xAB) { cycles += 8; do_outid(-1); }
        // Строки с повтором
        else if (opcode == 0xB0) { // LDIR

            cycles += 8; do_ldi();
            if (reg.b || reg.c) { cycles += 5; reg.pc = (reg.pc - 2) & 0xffff; }
        }
        else if (opcode == 0xB1) { // CPIR

            cycles += 8; do_cpid(1);
            if (!get_flag(FLAG_Z) && (reg.b || reg.c)) { cycles += 5; reg.pc = (reg.pc - 2) & 0xffff; }
        }
        else if (opcode == 0xB2) { // INIR

            cycles += 8; do_inid(1);
            if (reg.b) { cycles += 5; reg.pc = (reg.pc - 2) & 0xffff; }
        }
        else if (opcode == 0xB3) { // OTIR

            cycles += 8; do_outid(1);
            if (reg.b) { cycles += 5; reg.pc = (reg.pc - 2) & 0xffff; }
        }
        else if (opcode == 0xB8) { // LDDR

            cycles += 8; do_ldd();
            if (reg.b || reg.c) { cycles += 5; reg.pc = (reg.pc - 2) & 0xffff; }
        }
        else if (opcode == 0xB9) { // CPDR

            cycles += 8; do_cpid(-1);
            if (!get_flag(FLAG_Z) && (reg.b || reg.c)) { cycles += 5; reg.pc = (reg.pc - 2) & 0xffff; }
        }
        else if (opcode == 0xBA) { // INDR

            cycles += 8; do_inid(-1);
            if (reg.b) { cycles += 5; reg.pc = (reg.pc - 2) & 0xffff; }
        }
        else if (opcode == 0xBB) { // OTDR

            cycles += 8; do_outid(-1);
            if (reg.b) { cycles += 5; reg.pc = (reg.pc - 2) & 0xffff; }
        }
        // MISC
        else if (opcode == 0x47) { cycles += 1; reg.i = reg.a; }
        else if (opcode == 0x4F) { cycles += 1; reg.r = reg.a; }
        else if (opcode == 0x57) { cycles += 1; reg.a = reg.i; }
        else if (opcode == 0x5F) { cycles += 1; reg.a = reg.r; }
        else if (opcode == 0x67) { cycles += 10; rrd(); }
        else if (opcode == 0x6F) { cycles += 10; rld(); }
        else {

            printf("Undefined opcode ED %02X at PC=%04X\n", opcode, reg.pc-2);
            exit(1);
        }
    }
    // Стандартные
    else {

        int a8   = (opcode & 0x38) >> 3;
        int a16  = (opcode & 0x30) >> 4;
        int b8   = (opcode & 0x07);
        int opc7 = (opcode & 0xc7);
        int opcf = (opcode & 0xcf);

        // Первый блок
        if ((opcode & 0xc0) == 0x00) {

            // 00 xx0 001 | LD r16, **
            if (opcf == 0x01) { cycles += 6; put_reg16(a16, fetch_word()); }
            // 00 xxx 110 | LD r8, *
            else if (opc7 == 0x06) {

                cycles += 3;
                if (a8 == 6) { cycles += 3; if (has_prefix) { cycles += 5; fetch_prefixed_hl(); } }
                put_reg8(a8, fetch_byte());
            }
            // 00 xx0 011 | INC r16
            else if (opcf == 0x03) {

                cycles += 2;
                put_reg16(a16, get_reg16(a16) + 1);
            }
            // 00 xx1 011 | DEC r16
            else if (opcf == 0x0B) {

                cycles += 2;
                put_reg16(a16, get_reg16(a16) - 1);
            }
            // 10 DJNZ * | 18 JR *
            else if (opcode == 0x10) {

                cycles += 4;
                reg.b = (reg.b - 1) & 0xff;
                conditional_relative(reg.b);
            }
            else if (opcode == 0x18) { cycles += 3; conditional_relative(1); }
            // JR cc, *
            else if (opcode == 0x20) { cycles += 3; conditional_relative(!(reg.f & FLAG_Z)); }
            else if (opcode == 0x28) { cycles += 3; conditional_relative( (reg.f & FLAG_Z)); }
            else if (opcode == 0x30) { cycles += 3; conditional_relative(!(reg.f & FLAG_C)); }
            else if (opcode == 0x38) { cycles += 3; conditional_relative( (reg.f & FLAG_C)); }
            // 00 xxx 100 | INC r8
            else if (opc7 == 0x04) {

                if (a8 == 6) { cycles += 7; if (has_prefix) { cycles += 8; fetch_prefixed_hl(); } }
                put_reg8(a8, inc8(get_reg8(a8)));
            }
            // 00 xxx 101 | DEC r8
            else if (opc7 == 0x05) {

                if (a8 == 6) { cycles += 7; if (has_prefix) { cycles += 8; fetch_prefixed_hl(); } }
                put_reg8(a8, dec8(get_reg8(a8)));
            }
            // 00 xx1 001 | ADD HL, r16
            else if (opcf == 0x09) { do_hl_add(get_reg16(a16)); cycles += 7; }
            // MISC
            else if (opcode == 0x02) { write_byte(reg.b*256 + reg.c, reg.a); cycles += 3; }     // LD (BC), A
            else if (opcode == 0x12) { write_byte(reg.d*256 + reg.e, reg.a); cycles += 3; }     // LD (DE), A
            else if (opcode == 0x0A) { reg.a = read_byte(reg.b*256 + reg.c); cycles += 3; }     // LD A, (BC)
            else if (opcode == 0x1A) { reg.a = read_byte(reg.d*256 + reg.e); cycles += 3; }     // LD A, (DE)
            else if (opcode == 0x08) { // EX AF, AF'

                tmp = reg.a; reg.a = reg.a_; reg.a_ = tmp;
                tmp = reg.f; reg.f = reg.f_; reg.f_ = tmp;
            }
            else if (opcode == 0x22) { write_word(fetch_word(), get_reg16(2)); cycles += 12; }  // LD (**), HL
            else if (opcode == 0x32) { write_byte(fetch_word(), reg.a); cycles += 9; }          // LD (**), A
            else if (opcode == 0x2A) { put_reg16(2, read_word(fetch_word())); cycles += 12; }   // LD HL, (**)
            else if (opcode == 0x3A) { reg.a = read_byte(fetch_word()); cycles += 9; }          // LD A, (**)
            else if (opcode == 0x07) { reg.a = do_rlc(reg.a); }         // RLCA
            else if (opcode == 0x0F) { reg.a = do_rrc(reg.a); }         // RRCA
            else if (opcode == 0x17) { reg.a = do_rl(reg.a); }          // RLA
            else if (opcode == 0x1F) { reg.a = do_rr(reg.a); }          // RRA
            else if (opcode == 0x27) { do_daa(); }                      // DAA
            else if (opcode == 0x2F) { do_cpl(); }                      // CPL
            else if (opcode == 0x37) { do_scf(); }                      // SCF
            else if (opcode == 0x3F) { do_ccf(); }                      // CCF
        }
        // Второй блок: перемещения
        else if ((opcode & 0xc0) == 0x40) {

            if (opcode == 0x76) {
                halt = 1;

            } else {

                // Считывание HL, (IX|IY+d)
                if (a8 == 6 || b8 == 6) { cycles += 3; if (has_prefix) { fetch_prefixed_hl(); cycles += 8; } }

                // Чтение и запись из регистра в регистр 8 бит
                allow_undoc = 0; put_reg8(a8, get_reg8(b8));
            }
        }
        // Третий блок
        else if ((opcode & 0xc0) == 0x80) {

            // Считывание HL, (IX|IY+d)
            if (b8 == 6) { cycles += 3; if (has_prefix) { fetch_prefixed_hl(); cycles += 8; } }

            // Исполнение опкода
            aluop(a8, get_reg8(b8));
        }
        // Четвертый блок
        else if ((opcode & 0xc0) == 0xc0) {

            // 11 xxx 000 | RET ccc
            if (opc7 == 0xc0) {

                cycles += 1;
                if (check_cond(a8)) {

                    cycles += 6;
                    reg.pc = pop_word();
                }
            }
            // 11 xxx 010 | JP c, **
            else if (opc7 == 0xc2) {

                cycles += 6;
                tmp = fetch_word();
                if (check_cond(a8)) reg.pc = tmp;
            }
            // 11 xxx 100 | CALL c, **
            else if (opc7 == 0xc4) {

                cycles += 6;
                tmp = fetch_word();
                if (check_cond(a8)) { cycles += 7; push_word(reg.pc); reg.pc = tmp; }
            }
            // 11 xxx 110 | ALU A, *
            else if (opc7 == 0xc6) {

                cycles += 3;
                aluop(a8, fetch_byte());
            }
            // 11 xxx 111 | RST #
            else if (opc7 == 0xc7) {

                cycles += 7;
                push_word(reg.pc);
                reg.pc = opcode & 0x38;
            }
            // 11 xx0 101 | PUSH r16
            // 11 xx0 001 | POP  r16
            else if (opcf == 0xc5) { cycles += 7; if (a16 == 3) a16 = 4; push_word(get_reg16(a16)); }
            else if (opcf == 0xc1) { cycles += 6; if (a16 == 3) a16 = 4; put_reg16(a16, pop_word()); }
            // MISC
            else if (opcode == 0xF3) { delay_di = 2; }
            else if (opcode == 0xFB) { delay_ei = 2; }
            else if (opcode == 0xC3) { cycles += 6; reg.pc = fetch_word(); } // JP **
            else if (opcode == 0xCD) { cycles += 13; tmp = fetch_word(); push_word(reg.pc); reg.pc = tmp; } // CALL **
            else if (opcode == 0xC9) { cycles += 6; reg.pc = pop_word(); } // RET
            else if (opcode == 0xE9) { reg.pc = get_reg16(2); } // JP (HL)
            // EX DE, HL
            else if (opcode == 0xEB) {

                tmp = 256*reg.h | reg.l;
                reg.h = reg.d;
                reg.l = reg.e;
                reg.d = (tmp & 0xff00)>>8;
                reg.e = tmp & 0xff;
            }
            // EXX
            else if (opcode == 0xD9) {

                tmp = reg.b; reg.b = reg.b_; reg.b_ = tmp;
                tmp = reg.c; reg.c = reg.c_; reg.c_ = tmp;
                tmp = reg.d; reg.d = reg.d_; reg.d_ = tmp;
                tmp = reg.e; reg.e = reg.e_; reg.e_ = tmp;
                tmp = reg.h; reg.h = reg.h_; reg.h_ = tmp;
                tmp = reg.l; reg.l = reg.l_; reg.l_ = tmp;
            }
            // EX (SP), HL
            else if (opcode == 0xE3) {

                cycles += 15;
                tmp = read_word(reg.sp);
                write_word(reg.sp, get_reg16(2));
                put_reg16(2, tmp);
            }
            // LD SP, HL
            else if (opcode == 0xF9) { cycles += 2; put_reg16(3, get_reg16(2)); }
            // IN A, (*) | OUT (*), A
            else if (opcode == 0xD3) { cycles += 7; tmp = fetch_byte(); do_out((reg.a<<8) | tmp, reg.a); }
            else if (opcode == 0xDB) { cycles += 7; reg.a = do_in(fetch_byte()); }
        }
    }

    // Особый случай для включения и выключения прерываний
    if (delay_di)      { delay_di--; if (delay_di == 0) { iff0 = 0; iff1 = 0; } }
    else if (delay_ei) { delay_ei--; if (delay_ei == 0) { iff0 = 1; iff1 = 1; } }

    // Количество циклов, которые были затрачены на инструкцию
    return (cycles - cycles_init);
}
