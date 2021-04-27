#include <string.h>

#include "disasm.h"

// Сформировать операнд (IX|IY+d)
void Z80Spectrum::ixy_disp(int prefix) {

    int df = ds_fetch_byte();

    if (df & 0x80) {
        sprintf(ds_prefix, "(%s-$%02x)", (prefix == 1 ? "ix" : "iy"), 1 + (df ^ 0xff));
    } else if (df) {
        sprintf(ds_prefix, "(%s+$%02x)", (prefix == 1 ? "ix" : "iy"), df);
    } else {
        sprintf(ds_prefix, "(%s)", (prefix == 1 ? "ix" : "iy"));
    }
}

// Прочитать байт дизассемблера
int Z80Spectrum::ds_fetch_byte() {

    int b = mem_read(ds_ad);
    ds_ad = (ds_ad + 1) & 0xffff;
    ds_size++;
    return b;
}

// Прочитать слово дизассемблера
int Z80Spectrum::ds_fetch_word() {

    int l = ds_fetch_byte();
    int h = ds_fetch_byte();
    return (h<<8) | l;
}

// Прочитать относительный операнд
int Z80Spectrum::ds_fetch_rel() {

    int r8 = ds_fetch_byte();
    return ((r8 & 0x80) ? r8 - 0x100 : r8) + ds_ad;
}

// Дизассемблирование 1 линии
int Z80Spectrum::disasm_line(int addr) {

    int op, df;
    int prefix = 0;

    ds_opcode[0]  = 0;
    ds_operand[0] = 0;
    ds_prefix[0]  = 0;
    ds_ad   = addr;
    ds_size = 0;

    // -----------------------------------------------------------------
    // Считывание опкода и префиксов
    // -----------------------------------------------------------------

    do {

        op = ds_fetch_byte();
        if (op == 0xDD)      prefix = 1;
        else if (op == 0xFD) prefix = 2;
    }
    while (op == 0xDD || op == 0xFD);

    // -----------------------------------------------------------------
    // Разбор опкода и операндов
    // -----------------------------------------------------------------

    if (op == 0xED) {

        op = ds_fetch_byte();

        int a = (op & 0x38) >> 3;
        int b = (op & 0x07);
        int f = (op & 0x30) >> 4;

        // 01xx x000
        if ((op & 0xc7) == 0x40)      { sprintf(ds_opcode, "in");  sprintf(ds_operand, "%s, (c)", a == 6 ? "?" : ds_reg8[a]); }
        else if ((op & 0xc7) == 0x41) { sprintf(ds_opcode, "out"); sprintf(ds_operand, "(c), %s", a == 6 ? "0" : ds_reg8[a]); }
        // 01xx x010
        else if ((op & 0xc7) == 0x42) { sprintf(ds_opcode, op & 8 ? "adc" : "sbc"); sprintf(ds_operand, "hl, %s", ds_reg16[f]); }
        // 01xx b011
        else if ((op & 0xcf) == 0x43) { sprintf(ds_opcode, "ld"); sprintf(ds_operand, "($%04x), %s", ds_fetch_word(), ds_reg16[f]); }
        else if ((op & 0xcf) == 0x4b) { sprintf(ds_opcode, "ld"); sprintf(ds_operand, "%s, ($%04x)", ds_reg16[f], ds_fetch_word()); }
        // 01xx x10b
        else if ((op & 0xc7) == 0x44) { sprintf(ds_opcode, "neg"); }
        else if (op == 0x4d) sprintf(ds_opcode, "reti");
        else if ((op & 0xc7) == 0x45) { sprintf(ds_opcode, "retn"); }
        // 01xx x110
        else if ((op & 0xc7) == 0x46) { sprintf(ds_opcode, "im"); sprintf(ds_operand, "%x", ds_im[a]); }
        else switch (op) {

            case 0x47: sprintf(ds_opcode, "ld"); sprintf(ds_operand, "i, a"); break;
            case 0x4f: sprintf(ds_opcode, "ld"); sprintf(ds_operand, "r, a"); break;
            case 0x57: sprintf(ds_opcode, "ld"); sprintf(ds_operand, "a, i"); break;
            case 0x5f: sprintf(ds_opcode, "ld"); sprintf(ds_operand, "a, r"); break;
            case 0x67: sprintf(ds_opcode, "rrd"); break;
            case 0x6f: sprintf(ds_opcode, "rld"); break;

            case 0xa0: sprintf(ds_opcode, "ldi"); break;
            case 0xa1: sprintf(ds_opcode, "cpi"); break;
            case 0xa2: sprintf(ds_opcode, "ini"); break;
            case 0xa3: sprintf(ds_opcode, "outi"); break;
            case 0xa8: sprintf(ds_opcode, "ldd"); break;
            case 0xa9: sprintf(ds_opcode, "cpd"); break;
            case 0xaa: sprintf(ds_opcode, "ind"); break;
            case 0xab: sprintf(ds_opcode, "outd"); break;

            case 0xb0: sprintf(ds_opcode, "ldir"); break;
            case 0xb1: sprintf(ds_opcode, "cpir"); break;
            case 0xb2: sprintf(ds_opcode, "inir"); break;
            case 0xb3: sprintf(ds_opcode, "otir"); break;
            case 0xb8: sprintf(ds_opcode, "lddr"); break;
            case 0xb9: sprintf(ds_opcode, "cpdr"); break;
            case 0xba: sprintf(ds_opcode, "indr"); break;
            case 0xbb: sprintf(ds_opcode, "otdr"); break;

            default:

                sprintf(ds_opcode, "undef?"); break;

        }

    }
    else if (op == 0xCB) {

        if (prefix) ixy_disp(prefix);
        op = ds_fetch_byte();

        int a = (op & 0x38) >> 3;
        int b = (op & 0x07);

        // 00xxxrrr SHIFT
        if ((op & 0xc0) == 0x00) {

            sprintf(ds_opcode, "%s", ds_bits[a]);

            if (prefix && b == 6) {
                sprintf(ds_operand, "%s", ds_prefix);
            } else {
                sprintf(ds_operand, "%s", ds_reg8[b + prefix*8]);
            }
        }
        else {

            if ((op & 0xc0) == 0x40) sprintf(ds_opcode, "bit");
            if ((op & 0xc0) == 0x80) sprintf(ds_opcode, "res");
            if ((op & 0xc0) == 0xc0) sprintf(ds_opcode, "set");

            sprintf(ds_operand, "%x, %s", a, prefix ? ds_prefix : ds_reg8[b]);
        }

    } else {

        // Имя опкода
        sprintf(ds_opcode, "%s", ds_mnemonics[op]);

        int a = (op & 0x38) >> 3;
        int b = (op & 0x07);

        // Имя HL в зависимости от префикса
        char hlname[4];
        if (prefix == 0) sprintf(hlname, "hl");
        if (prefix == 1) sprintf(hlname, "ix");
        if (prefix == 2) sprintf(hlname, "iy");

        // Инструкции перемещения LD
        if (op >= 0x40 && op < 0x80) {

            if (a == 6 && b == 6) {
                /* halt */
            }
            // Префиксированные
            else if (prefix) {

                // Прочитать +disp8
                ixy_disp(prefix);

                // Декодирование
                if (a == 6) {
                    sprintf(ds_operand, "%s, %s", ds_prefix, ds_reg8[b]);
                } else if (b == 6) {
                    sprintf(ds_operand, "%s, %s", ds_reg8[a], ds_prefix);
                } else {
                    sprintf(ds_operand, "%s, %s", ds_reg8[8*prefix + a], ds_reg8[8*prefix + b]);
                }
            }
            else { sprintf(ds_operand, "%s, %s", ds_reg8[a], ds_reg8[b]); }
        }
        // Арифметико-логика
        else if (op >= 0x80 && op < 0xc0) {

            if (prefix) {

                if (b == 6) {

                    ixy_disp(prefix);
                    sprintf(ds_operand, "%s", ds_prefix);

                } else {
                    sprintf(ds_operand, "%s", ds_reg8[8*prefix + b]);
                }
            } else {
                sprintf(ds_operand, "%s", ds_reg8[b]);
            }
        }
        // LD r16, **
        else if (op == 0x01 || op == 0x11 || op == 0x21 || op == 0x31) {

            df = ds_fetch_word();
            sprintf(ds_operand, "%s, $%04x", ds_reg16[4*prefix + ((op & 0x30) >> 4)], df);
        }
        // 00xx x110 LD r8, i8
        else if ((op & 0xc7) == 0x06) {

            if (a == 6 && prefix) {
                ixy_disp(prefix);
                sprintf(ds_operand, "%s, $%02x", ds_prefix, ds_fetch_byte());
            } else {
                sprintf(ds_operand, "%s, $%02x", ds_reg8[8*prefix + a], ds_fetch_byte());
            }
        }
        // 00_xxx_10x
        else if ((op & 0xc7) == 0x04 || (op & 0xc7) == 0x05) {

            if (a == 6 && prefix) {
                ixy_disp(prefix);
                sprintf(ds_operand, "%s", ds_prefix);
            } else {
                sprintf(ds_operand, "%s", ds_reg8[8*prefix + a]);
            }
        }
        // 00xx x011
        else if ((op & 0xc7) == 0x03) {
            sprintf(ds_operand, "%s", ds_reg16[4*prefix + ((op & 0x30) >> 4)]);
        }
        // 00xx 1001
        else if ((op & 0xcf) == 0x09) {
            sprintf(ds_operand, "%s, %s", ds_reg16[4*prefix+2], ds_reg16[4*prefix + ((op & 0x30) >> 4)]);
        }
        else if (op == 0x02) sprintf(ds_operand, "(bc), a");
        else if (op == 0x08) sprintf(ds_operand, "af, af'");
        else if (op == 0x0A) sprintf(ds_operand, "a, (bc)");
        else if (op == 0x12) sprintf(ds_operand, "(de), a");
        else if (op == 0x1A) sprintf(ds_operand, "a, (de)");
        else if (op == 0xD3) sprintf(ds_operand, "($%02x), a", ds_fetch_byte());
        else if (op == 0xDB) sprintf(ds_operand, "a, ($%02x)", ds_fetch_byte());
        else if (op == 0xE3) sprintf(ds_operand, "(sp), %s", hlname);
        else if (op == 0xE9) sprintf(ds_operand, "(%s)", hlname);
        else if (op == 0xEB) sprintf(ds_operand, "de, %s", hlname);
        else if (op == 0xF9) sprintf(ds_operand, "sp, %s", hlname);
        else if (op == 0xC3 || op == 0xCD) sprintf(ds_operand, "$%04x", ds_fetch_word());
        else if (op == 0x22) { b = ds_fetch_word(); sprintf(ds_operand, "($%04x), %s", b, hlname); }
        else if (op == 0x2A) { b = ds_fetch_word(); sprintf(ds_operand, "%s, ($%04x)", hlname, b); }
        else if (op == 0x32) { b = ds_fetch_word(); sprintf(ds_operand, "($%04x), a", b); }
        else if (op == 0x3A) { b = ds_fetch_word(); sprintf(ds_operand, "a, ($%04x)", b); }
        else if (op == 0x10 || op == 0x18) { sprintf(ds_operand, "$%04x", ds_fetch_rel()); }
        // 001x x000 JR c, *
        else if ((op & 0xe7) == 0x20) sprintf(ds_operand, "%s, $%04x", ds_cc[(op & 0x18)>>3], ds_fetch_rel());
        // 11xx x000 RET *
        else if ((op & 0xc7) == 0xc0) sprintf(ds_operand, "%s", ds_cc[a]);
        // 11xx x010 JP c, **
        // 11xx x100 CALL c, **
        else if ((op & 0xc7) == 0xc2 || (op & 0xc7) == 0xc4) sprintf(ds_operand, "%s, $%04x", ds_cc[a], ds_fetch_word());
        // 11xx x110 ALU A, *
        else if ((op & 0xc7) == 0xc6) sprintf(ds_operand, "$%02x", ds_fetch_byte());
        // 11xx x111 RST #
        else if ((op & 0xc7) == 0xc7) sprintf(ds_operand, "$%02x", op & 0x38);
        // 11xx 0x01 PUSH/POP r16
        else if ((op & 0xcb) == 0xc1) sprintf(ds_operand, "%s", ds_reg16af[ ((op & 0x30) >> 4) + prefix*4 ] );
    }

    return ds_size;
}

// Печать одного символа на хосте (символ размером 8x10)
void Z80Spectrum::print_char(int x, int y, unsigned char ch) {

    x *= 8;
    y *= 8;
    for (int _i = 0; _i < 8; _i++) {

        int mask = sysfont[8*ch + _i];
        for (int _j = 0; _j < 8; _j++) {

            int color = (mask & (1<<(7-_j))) ? ds_color_fore : ds_color_back;

            if (color >= 0) {
                for (int _a = 0; _a < 4; _a++)
                    pixel(2*(x + _j) + (_a&1), 2*(y+_i) + (_a>>1), color);
            }
        }
    }
}

// Печать строки с переносом по Y
void Z80Spectrum::print(int x, int y, const char* s) {

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

// Перерисовать экран
void Z80Spectrum::redraw_fb() {

    // Сохранение бордера
    for (int y = 0; y < 240; y++)
    for (int x = 0; x < 320; x++) {

        if (x < 32 || y < 24 || x >= 288 || y >= 216) {

            unsigned int ptr = (239-y)*160 + (x>>1);
            int cl = (x & 1 ? fb[ptr] : fb[ptr]>>4) & 15;
            for (int _a = 0; _a < 9; _a++) pixel(3*x+(_a%3), 3*y+(_a/3), get_color(cl));
        }
    }

    // Обновление текущей области PAPER
    for (int _a = 0x4000; _a < 0x5800; _a++)
        update_charline(_a);

    ds_showfb = 1;
}

void Z80Spectrum::ds_color(int fore, int back) {

    ds_color_fore = fore;
    ds_color_back = back;
}

void Z80Spectrum::z80state_dump() {

    printf("BC:  %04X | DE:  %04X | HL:  %04X | AF:  %04X\n", b*256 + c, d*256 + e, h*256 + l, a*256 + get_flags_register());
    printf("BC`: %04X | DE`: %04X | HL`: %04X | AF`: %04X\n", b_prime*256 + c_prime, d_prime*256 + e_prime, h_prime*256 + l_prime, a_prime*256 + get_flags_prime());
    printf("IMODE: %d | IFF1: %d | IFF2: %d\n", imode, iff1, iff2);
    printf("I:  %02x   | R: %02x\n", i, r);
    printf("IX: %04x | IY: %04x\n", ix, iy);
    printf("SP: %04x\n", sp);
    printf("PC: %04x\n", pc);

    FILE* fp = fopen("debug_memory_dump.bin", "wb+");
    if (fp == NULL) { printf("Can't open file debug_memory_dump.bin for writing\n"); exit(1); }
    fwrite(memory, 1, 128*1024, fp);
    fclose(fp);
}

// Перерисовать дизассемблер
void Z80Spectrum::disasm_repaint() {

    char tmp[256];

    beam_drawing = 0;
    ds_start &= 0xffff;
    ds_showfb = 0;

    int j, k, catched = 0;
    int bp_found;
    int ds_current = ds_start;

    ds_match_row = 0;

    cls(0);
    ds_color(0xffffff, 0);

    // Начать отрисовку сверху вниз
    for (int _a = 0; _a < 43; _a++) {

        int dsy  = _a + 1;
        int size = disasm_line(ds_current);

        // Поиск прерывания
        bp_found = 0;
        for (j = 0; j < bp_count; j++) {
            if (bp_rows[j] == ds_current) {
                bp_found = 1;
                break;
            }
        }

        // Запись номера строки
        ds_rowdis[_a] = ds_current;

        // Курсор находится на текущей линии
        if (ds_cursor == ds_current) {

            ds_color(0xffffff, bp_found ? 0xc00000 : 0x0000f0);
            print(0, dsy, "                                     ");
            sprintf(tmp, "%04X", ds_current);
            print(1, dsy, tmp);

            ds_match_row = _a;
            catched = 1;
        }
        // Либо на какой-то остальной
        else {

            ds_color(0x00ff00, bp_found ? 0x800000 : 0);
            print(0, dsy, "                               ");

            // Выдача адреса
            sprintf(tmp, "%04X", ds_current);
            print(1, dsy, tmp);

            ds_color(0x80c080, bp_found ? 0x800000 : 0);
        }

        // Текущее положение PC
        if (ds_current == pc)
            print(0, dsy, "\x10");

        // Печатать опкод в верхнем регистре
        sprintf(tmp, "%s", ds_opcode);

        for (k = 0; k < strlen(tmp); k++)
            if (tmp[k] >= 'a' && tmp[k] <= 'z')
                tmp[k] += ('A' - 'a');

        print(7+6,  dsy, tmp); // Опкод

        // Печатать операнды в верхнем регистре
        sprintf(tmp, "%s", ds_operand);
        for (k = 0; k < strlen(tmp); k++) if (tmp[k] >= 'a' && tmp[k] <= 'z') tmp[k] += ('A' - 'a');
        print(7+12, dsy, tmp); // Операнд

        // Вывод микродампа
        if  (ds_cursor == ds_current)
             ds_color(0xffffff, bp_found ? 0xffffff : 0x0000f0);
        else ds_color(0xc0c0c0, bp_found ? 0xc0c0c0 : 0);

        // Максимум 3 байта
        if (size == 1) {

            sprintf(tmp, "%02X", mem_read(ds_current));
            print(6, dsy, tmp);
        }
        else if (size == 2) {

            sprintf(tmp, "%02X%02X", mem_read(ds_current), mem_read(ds_current+1));
            print(6, dsy, tmp);
        }
        else if (size == 3) {

            sprintf(tmp, "%02X%02X%02X", mem_read(ds_current), mem_read(ds_current+1), mem_read(ds_current+2));
            print(6, dsy, tmp);
        }
        else if (size  > 3) {

            sprintf(tmp, "%02X%02X%02X+", mem_read(ds_current), mem_read(ds_current+1), mem_read(ds_current+2));
            print(6, dsy, tmp);
        }

        // Следующий адрес
        ds_current = (ds_current + size) & 0xffff;
    }

    // В последней строке будет новая страница
    ds_rowdis[37] = ds_current;

    // Проверка на "вылет"
    // Сдвиг старта на текущий курсор
    if (catched == 0) {

        ds_start = ds_cursor;
        disasm_repaint();
    }

    ds_color(0xc0c0c0, 0);

    int f       = get_flags_register();
    int f_prime = get_flags_prime();

    // Вывод содержимого регистров
    sprintf(tmp, "B %02X   B' %02X   S %c", b, b_prime, f & 0x80 ? '1' : '-'); print(38, 1, tmp);
    sprintf(tmp, "C %02X   C' %02X   Z %c", c, c_prime, f & 0x40 ? '1' : '-'); print(38, 2, tmp);
    sprintf(tmp, "D %02X   D' %02X   Y %c", d, d_prime, f & 0x20 ? '1' : '-'); print(38, 3, tmp);
    sprintf(tmp, "E %02X   E' %02X   H %c", e, e_prime, f & 0x10 ? '1' : '-'); print(38, 4, tmp);
    sprintf(tmp, "H %02X   H' %02X   X %c", h, h_prime, f & 0x08 ? '1' : '-'); print(38, 5, tmp);
    sprintf(tmp, "L %02X   L' %02X   V %c", l, l_prime, f & 0x04 ? '1' : '-'); print(38, 6, tmp);
    sprintf(tmp, "A %02X   A' %02X   N %c", a, a_prime, f & 0x02 ? '1' : '-'); print(38, 7, tmp);
    sprintf(tmp, "F %02X   F' %02X   C %c", f, f_prime, f & 0x01 ? '1' : '-'); print(38, 8, tmp);

    sprintf(tmp, "BC: %04X", (b<<8) | c); print(38, 10, tmp);
    sprintf(tmp, "DE: %04X", (d<<8) | e); print(38, 11, tmp);
    sprintf(tmp, "HL: %04X", (h<<8) | l); print(38, 12, tmp);
    sprintf(tmp, "SP: %04X", sp);         print(38, 13, tmp);
    sprintf(tmp, "AF: %04X", (a<<8) | f); print(38, 14, tmp);

    int _hl = (h<<8) | l;
    int _vc = (i<<8) + 0xff; _vc = mem_read(_vc) + 256*mem_read((_vc+1) & 0xffff);
    sprintf(tmp, "(HL): %04X", mem_read(_hl) | 256*mem_read((_hl+1)&0xffff)); print(38, 15, tmp);
    sprintf(tmp, "(SP): %04X", mem_read(sp)  | 256*mem_read(( sp+1)&0xffff)); print(38, 16, tmp);
    sprintf(tmp, "VECT: %04X", _vc); print(38, 17, tmp);

    sprintf(tmp, "IX: %04X", ix);  print(49, 10, tmp);
    sprintf(tmp, "IY: %04X", iy);  print(49, 11, tmp);
    sprintf(tmp, "PC: %04X", pc);  print(49, 12, tmp);

    sprintf(tmp, "IR: %04X", (i<<8) | r);   print(49, 13, tmp);
    sprintf(tmp, "IM:    %01X", imode);     print(49, 14, tmp);
    sprintf(tmp, "IFF1:  %01X", iff1);      print(49, 15, tmp);
    sprintf(tmp, "IFF2:  %01X", iff2);      print(49, 16, tmp);

    // Вывести дамп памяти
    for (int _a = 0; _a < 14; _a++) {

        for (k = 0; k < 8; k++) {

            sprintf(tmp, "%02X", mem_read(8*_a+k+ds_dumpaddr));
            ds_color(k % 2 ? 0x40c040 : 0xc0f0c0, 0);
            print(43 + 2*k, _a + 23, tmp);
        }

        ds_color(0x909090, 0);
        sprintf(tmp, "%04X", ds_dumpaddr + 8*_a);
        print(38, _a + 23, tmp);
    }

    ds_color(0xf0f0f0, 0); print(38, 22, "ADDR  0 1 2 3 4 5 6 7");

    // Некоторые индикаторы
    ds_color(0x808080, 0);
    sprintf(tmp, "VStates: %d",  t_states_cycle); print(38, 38, tmp);
    sprintf(tmp, "AStates: %li", t_states_all);   print(38, 39, tmp);
}
