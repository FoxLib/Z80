#include <string.h>

#include "z80.h"
#include "disasm.h"

// Сформировать операнд (IX|IY+d)
void z80::ixy_disp(int prefix) {

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
int z80::ds_fetch_byte() {

    int b = mem[ds_ad];
    ds_ad = (ds_ad + 1) & 0xffff;
    ds_size++;
    return b;
}

// Прочитать слово дизассемблера
int z80::ds_fetch_word() {

    int l = ds_fetch_byte();
    int h = ds_fetch_byte();
    return (h<<8) | l;
}

// Прочитать относительный операнд
int z80::ds_fetch_rel() {

    int r8 = ds_fetch_byte();
    return ((r8 & 0x80) ? r8 - 0x100 : r8) + ds_ad;
}

// Дизассемблирование 1 линии
int z80::disasm_line(int addr) {

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

// Перерисовать дизассемблер
void z80::disasm_repaint() {

    char tmp[256];

    ds_start &= 0xffff;

    int i, j, k, catched = 0;
    int bp_found;
    int ds_current = ds_start;

    ds_match_row = 0;

    // Очистка экрана
    color(0xffffff, 0)->cls();

    // Начать отрисовку сверху вниз
    for (i = 0; i < 37; i++) {

        int dsy  = i + 1;
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
        ds_rowdis[i] = ds_current;

        // Курсор находится на текущей линии
        if (ds_cursor == ds_current) {

            color(0xffffff, bp_found ? 0xc00000 : 0x0000f0);
            print(0, dsy, "                                         ");
            sprintf(tmp, "%04X", ds_current); print(1, dsy, tmp);

            ds_match_row = i;
            catched = 1;
        }
        // Либо на какой-то остальной
        else {

            color(0x00ff00, bp_found ? 0x800000 : 0);
            print(0, dsy, "                               ");

            // Выдача адреса
            sprintf(tmp, "%04X", ds_current); print(1, dsy, tmp);
            color(0x80c080, bp_found ? 0x800000 : 0);
        }

        // Текущее положение PC
        if (ds_current == reg.pc) print(0, dsy, "\x10");

        // Печатать опкод в верхнем регистре
        sprintf(tmp, "%s", ds_opcode);
        for (k = 0; k < strlen(tmp); k++) if (tmp[k] >= 'a' && tmp[k] <= 'z') tmp[k] += ('A' - 'a');
        print(7+6,  dsy, tmp); // Опкод

        // Печатать операнды в верхнем регистре
        sprintf(tmp, "%s", ds_operand);
        for (k = 0; k < strlen(tmp); k++) if (tmp[k] >= 'a' && tmp[k] <= 'z') tmp[k] += ('A' - 'a');
        print(7+12, dsy, tmp); // Операнд

        // Вывод микродампа
        if  (ds_cursor == ds_current)
             color(0xf0f0f0, bp_found ? 0xc00000 : 0x0000f0);
        else color(0xa0a0a0, bp_found ? 0x800000 : 0x000000);

        // Максимум 3 байта
        if (size == 1) { sprintf(tmp, "%02X",          mem[ds_current]);                                       print(6, dsy, tmp); }
        if (size == 2) { sprintf(tmp, "%02X%02X",      mem[ds_current], mem[ds_current+1]);                    print(6, dsy, tmp); }
        if (size == 3) { sprintf(tmp, "%02X%02X%02X",  mem[ds_current], mem[ds_current+1], mem[ds_current+2]); print(6, dsy, tmp); }
        if (size  > 3) { sprintf(tmp, "%02X%02X%02X+", mem[ds_current], mem[ds_current+1], mem[ds_current+2]); print(6, dsy, tmp); }

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

    color(0xc0c0c0, 0);

    // Вывод содержимого регистров
    sprintf(tmp, "B: %02X  B': %02X  S: %c", reg.b, reg.b_, reg.f & 0x80 ? '1' : '-'); print(42, 1, tmp);
    sprintf(tmp, "C: %02X  C': %02X  Z: %c", reg.c, reg.c_, reg.f & 0x40 ? '1' : '-'); print(42, 2, tmp);
    sprintf(tmp, "D: %02X  D': %02X  Y: %c", reg.d, reg.d_, reg.f & 0x20 ? '1' : '-'); print(42, 3, tmp);
    sprintf(tmp, "E: %02X  E': %02X  H: %c", reg.e, reg.e_, reg.f & 0x10 ? '1' : '-'); print(42, 4, tmp);
    sprintf(tmp, "H: %02X  H': %02X  X: %c", reg.h, reg.h_, reg.f & 0x08 ? '1' : '-'); print(42, 5, tmp);
    sprintf(tmp, "L: %02X  L': %02X  V: %c", reg.l, reg.l_, reg.f & 0x04 ? '1' : '-'); print(42, 6, tmp);
    sprintf(tmp, "A: %02X  A': %02X  N: %c", reg.a, reg.a_, reg.f & 0x02 ? '1' : '-'); print(42, 7, tmp);
    sprintf(tmp, "F: %02X  F': %02X  C: %c", reg.f, reg.f_, reg.f & 0x01 ? '1' : '-'); print(42, 8, tmp);
    sprintf(tmp, "F: %02X  F': %02X  C: %c", reg.f, reg.f_, reg.f & 0x01 ? '1' : '-'); print(42, 8, tmp);

    sprintf(tmp, "BC: %04X", (reg.b<<8) | reg.c); print(42, 10, tmp);
    sprintf(tmp, "DE: %04X", (reg.d<<8) | reg.e); print(42, 11, tmp);
    sprintf(tmp, "HL: %04X", (reg.h<<8) | reg.l); print(42, 12, tmp);
    sprintf(tmp, "SP: %04X", reg.sp);             print(42, 13, tmp);
    sprintf(tmp, "AF: %04X", (reg.a<<8) | reg.f); print(42, 14, tmp);

    sprintf(tmp, "(HL): %02X", mem[ (reg.h<<8) | reg.l ]); print(42, 15, tmp);
    sprintf(tmp, "(SP): %02X", mem[ reg.sp ]); print(42, 16, tmp);

    sprintf(tmp, "IX: %04X", reg.ix);  print(51, 10, tmp);
    sprintf(tmp, "IY: %04X", reg.iy);  print(51, 11, tmp);
    sprintf(tmp, "PC: %04X", reg.pc);  print(51, 12, tmp);

    sprintf(tmp, "IR: %04X", (reg.i<<8) | reg.r); print(51, 13, tmp);
    sprintf(tmp, "IM:    %01X", im);    print(51, 14, tmp);
    sprintf(tmp, "IFF0:  %01X", iff0);  print(51, 15, tmp);
    sprintf(tmp, "IFF1:  %01X", iff1);  print(51, 16, tmp);

    // Вывести дамп памяти
    for (i = 0; i < 14; i++) {

        for (k = 0; k < 8; k++) {

            sprintf(tmp, "%02X", read_byte(8*i+k+ds_dumpaddr));
            color(k % 2 ? 0x40c040 : 0xc0f0c0, 0);
            print(47 + 2*k, i + 23, tmp);
        }

        color(0x909090, 0);
        sprintf(tmp, "%04X", ds_dumpaddr + 8*i);
        print(42, i + 23, tmp);
    }
    color(0xf0f0f0, 0)->print(42, 22, "ADDR  0 1 2 3 4 5 6 7");

    // Прерывание
    color(0xffff00, 0); print(42, 18, "F2");
    color(0x00ffff, 0); print(45, 18, "Brk");

    // Один шаг с заходом
    color(0xffff00, 0); print(42, 19, "F7");
    color(0x00ffff, 0); print(45, 19, "Step");

    // Запуск программы
    color(0xffff00, 0); print(42, 20, "F9");
    color(0x00ffff, 0); print(45, 20, "Run");

    // Переключить экраны
    color(0xffff00, 0); print(50, 18, "F5");
    color(0x00ffff, 0); print(53, 18, "Swi");

    // Один шаг с заходом
    color(0xffff00, 0); print(50, 19, "F6");
    color(0x00ffff, 0); print(53, 19, "Intr");

    // Один шаг
    color(0xffff00, 0); print(50, 20, "F8");
    color(0x00ffff, 0); print(53, 20, "Over");

    // Некоторые индикаторы
    color(0x808080, 0); sprintf(tmp, "TStates: %d", cycles); print(45, 37, tmp);

    // Halted
    color(halt ? 0xffff00 : 0x707070, 0);
    print(42, 37, "H");

    // Enabled Halt
    color(enable_halt ? 0xffff00 : 0x707070, 0);
    print(43, 37, "E");
}
