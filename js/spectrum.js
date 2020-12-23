// http://speccy.info/Клавиатура

var core, z80;
var display_affect;
var display_cycles = 0;
var display_flash = 0;

var keyStates = [];
var keyCodes = {
    49: {row: 3, mask: 0x01}, /* 1 */
    50: {row: 3, mask: 0x02}, /* 2 */
    51: {row: 3, mask: 0x04}, /* 3 */
    52: {row: 3, mask: 0x08}, /* 4 */
    53: {row: 3, mask: 0x10}, /* 5 */

    54: {row: 4, mask: 0x10}, /* 6 */
    55: {row: 4, mask: 0x08}, /* 7 */
    56: {row: 4, mask: 0x04}, /* 8 */
    57: {row: 4, mask: 0x02}, /* 9 */
    48: {row: 4, mask: 0x01}, /* 0 */

    81: {row: 2, mask: 0x01}, /* Q */
    87: {row: 2, mask: 0x02}, /* W */
    69: {row: 2, mask: 0x04}, /* E */
    82: {row: 2, mask: 0x08}, /* R */
    84: {row: 2, mask: 0x10}, /* T */

    89: {row: 5, mask: 0x10}, /* Y */
    85: {row: 5, mask: 0x08}, /* U */
    73: {row: 5, mask: 0x04}, /* I */
    79: {row: 5, mask: 0x02}, /* O */
    80: {row: 5, mask: 0x01}, /* P */

    65: {row: 1, mask: 0x01}, /* A */
    83: {row: 1, mask: 0x02}, /* S */
    68: {row: 1, mask: 0x04}, /* D */
    70: {row: 1, mask: 0x08}, /* F */
    71: {row: 1, mask: 0x10}, /* G */

    72: {row: 6, mask: 0x10}, /* H */
    74: {row: 6, mask: 0x08}, /* J */
    75: {row: 6, mask: 0x04}, /* K */
    76: {row: 6, mask: 0x02}, /* L */
    13: {row: 6, mask: 0x01}, /* enter */

    16:  {row: 0, mask: 0x01}, /* caps */
    192: {row: 0, mask: 0x01}, /* backtick as caps - because firefox screws up a load of key codes when pressing shift [`] */
    90: {row: 0, mask: 0x02}, /* Z */
    88: {row: 0, mask: 0x04}, /* X */
    67: {row: 0, mask: 0x08}, /* C */
    86: {row: 0, mask: 0x10}, /* V */

    66: {row: 7, mask: 0x10}, /* B */
    78: {row: 7, mask: 0x08}, /* N */
    77: {row: 7, mask: 0x04}, /* M */
    17: {row: 7, mask: 0x02}, /* sym - gah, firefox screws up ctrl+key too [ctrl] */
    32: {row: 7, mask: 0x01}  /* space */
};

// Сочетания клавиш
var keyCombo = {
    8: [16, 48],         // DELETE
    186: [17, 90],       // :
    // 192: [16, 49],       // Тильда вызываем EDIT
};

// https://github.com/DrGoldfire/Z80.js
// http://speccy.info/Прерывания

// -----------------------------------------------------------

function CORE() {

    // Объявить день независимости от 12-битных адресов!
    // да здравствует 16 бит!
    this.memory = new Uint8Array(64*1024); // 48 kb RAM на самом деле
    this.saves = new Uint8Array(64*1024);  // на один слот пока что
    this.saves_state = {};

    this.canvas = null;
    this.ctx = null;
    this.i_data = null;
    this.p_data = null;

    this.do_load = 0;
    this.do_save = 0;
}

// Сохранить в слот
CORE.prototype.quick_save = function (num, reg_data) {

    for (var i = 0; i < 65536; i++) {
        this.saves[num*65536 + i] = this.memory[i];
    }

    this.saves_state[num] = reg_data;
};

// Загрузить из слота
CORE.prototype.quick_load = function (num) {

    for (var i = 0; i < 65536; i++) {
        this.memory[i] = this.saves[num*65536 + i];
    }

    return this.saves_state[num];
};

// Процессинг нажатия на клавиатуру
CORE.prototype.keybProc = function(evt, action) {

    var keyCode = keyCodes[ evt.keyCode ];

    if (keyCode === null) {

        var keyCom = keyCombo[ evt.keyCode ];
        if (keyCom === null) {
            return;

        } else {

            for (var id in keyCom) {

                keyCode = keyCodes[ keyCom[ id ] ];

                if (action) {
                    keyStates[ keyCode.row ] &= ~(keyCode.mask);
                } else {
                    keyStates[ keyCode.row ] |=  (keyCode.mask);
                }
            }
        }

    } else {

        if (action) {
            keyStates[ keyCode.row ] &= ~(keyCode.mask);
        } else {
            keyStates[ keyCode.row ] |=  (keyCode.mask);
        }
    }

    evt.preventDefault();
    evt.stopPropagation();
    return false;
};

// Регистрация нажатия клавиши
CORE.prototype.keyDown = function(evt) {

    if (evt.keyCode === 113) { // F2/F5 - Quick Save

        this.do_save = 1;
        evt.preventDefault();
        evt.stopPropagation();

    } else if (evt.keyCode === 118) { // F7 - Quick Load

        this.do_load = 1;
        evt.preventDefault();
        evt.stopPropagation();
    }

    console.log(evt.keyCode);
    return this.keybProc(evt, 1);
};

// Поднятие клавиши
CORE.prototype.keyUp = function (evt)  {
    return this.keybProc(evt, 0);
};

CORE.prototype.get_color = function (color) {

    switch (color) {
        case 0: return '#000000';
        case 1: return '#0000c0';
        case 2: return '#c00000';
        case 3: return '#c000c0';
        case 4: return '#00c000';
        case 5: return '#00c0c0';
        case 6: return '#c0c000';
        case 7: return '#c0c0c0';
        case 8: return '#000000';
        case 9: return '#0000FF';
        case 10: return '#FF0000';
        case 11: return '#FF00FF';
        case 12: return '#00FF00';
        case 13: return '#00FFFF';
        case 14: return '#FFFF00';
        case 15: return '#FFFFFF';
    }

    return '#000';
};

// Получение Canvas для дальнейшей работы
CORE.prototype.get_canvas = function(Id) {

    this.canvas = document.getElementById(Id);
    this.ctx    = this.canvas.getContext('2d');

    this.ctx.webkitImageSmoothingEnabled = false;
    this.ctx.mozImageSmoothingEnabled = false;
    this.ctx.imageSmoothingEnabled = false;

};

// Скопировать данные во временный буфер
CORE.prototype.begin = function() {
    this.i_data = this.ctx.getImageData(0, 0, 256, 192);
    this.p_data = this.i_data.data;
};

// Из временного буфера сохранить на canvas
CORE.prototype.end = function() {
    this.i_data.data = this.p_data;
    this.ctx.putImageData(this.i_data, 0, 0);
};

// Установка пикселя 1x1
CORE.prototype.pixel = function(x, y, color) {
    var p = 4*(x + y * 256);

    this.p_data[p]     = (color >> 16) & 0xff;
    this.p_data[p + 1] = (color >> 8) & 0xff;
    this.p_data[p + 2] = (color & 0xff);
    this.p_data[p + 3] = 0xff;

};

// Читать байт
CORE.prototype.mem_read = function (address) {

    //if (address >= (32 + 7)*1024) { return 0xff;

    // console.log(address.toString(16), this.memory[ address ].toString(16));
    return this.memory[ address ];
};

// Алиас. Неизвестно, зачем так сделано.
CORE.prototype.read_mem_byte = function (address) {
    return this.mem_read(address);
};

// Обновить весь дисплей
CORE.prototype.update_display = function () {

    for (var addr = 0x5800; addr < 0x5B00; addr++) {
        this.update_attrbox(addr);
    }

};

// Обновить определенную линию
CORE.prototype.update_charline = function (address) {

    var byte = this.memory[ address ];

    address -= 0x4000;

    var Ya = (address & 0x0700) >> 8;
    var Yb = (address & 0x00E0) >> 5;
    var Yc = (address & 0x1800) >> 11;

    var y = Ya + Yb*8 + Yc*64;
    var x = address & 0x1F;

    var attr = this.memory[ 0x5800 + x + ((address & 0x1800) >> 3) + (address & 0xE0) ];
    var bgcolor = parseInt(this.get_color((attr & 0x38) >> 3).substr(1), 16);
    var frcolor = parseInt(this.get_color((attr & 0x07) + ((attr & 0x40) >> 3)).substr(1), 16);
    var flash = (attr & 0x80) ? 1 : 0;

    for (var j = 0; j < 8; j++) {

        var pix = (byte & (0x80 >> j)) ? 1 : 0;

        // Если есть атрибут мерация, то учитывать это
        var clr = (flash ? (pix ^ display_flash) : pix) ? frcolor : bgcolor;

        // Вывести пиксель
        this.pixel(8 * x + j, y, clr);
    }

    display_affect = 1;
};

// Обновить все атрибуты
CORE.prototype.update_attrbox = function (address) {

    address -= 0x5800;

    var addr = 0x4000 + (address & 0x0FF) + ((address & 0x0300) << 3);
    for (var i = 0; i < 8; i++) {
        this.update_charline(addr + (i<<8));
    }
};

// Писать байт, что нехило само по себе...
CORE.prototype.mem_write = function (address, value) {

    if (address >= 0x4000) {

        this.memory[ address ] = value;

        // Обновить дисплей в определенной точке (8x1)
        if (address < 0x5800) {
            this.update_charline(address);
        }
        // Обновить атрибут (8x8)
        else if (address < 0x5B00) {
            this.update_attrbox(address);
        }
    }
};

// http://speccy.info/Карта_портов_ZX_Spectrum
// http://speccy.info/%D0%9F%D0%BE%D1%80%D1%82_FE
CORE.prototype.io_read = function (port) {

    // Чтение клавиатуры
    if ((port & 0x0001) === 0x0000) {

        var result = 0xff;
        for (var row = 0; row < 8; row++) {

            if (!(port & (1 << (row + 8)))) {

                /* bit held low, so scan this row */
                result &= keyStates[ row ];
            }
        }
        return result;
    }
    else if ((port & 0x00e0) === 0x0000) {

        /* kempston joystick: treat this as attached but unused
         (for the benefit of Manic Miner) */
        return 0x00;

    } else {
        return 0xff; /* ой-ей */
    }

};

// Запись в порт
CORE.prototype.io_write = function (port, byte) {

    // Поддерживается только смена бордюда
    if ((port & 0xFF) === 0xFE) {
        $('#bgcolor').css('backgroundColor', this.get_color(byte & 7));
    }

    // console.log(port.toString(16), byte.toString(16));
};

// -----------------------------------------------------------

// Обновление 1 фрейма
function frameUpdate() {

    var t_states = 0;


    if (core.do_load) {

        z80.quick_load(core.do_load - 1);
        core.do_load = 0;

    } else if (core.do_save) {

        z80.quick_save(core.do_save - 1);
        core.do_save = 0;

    }

    // Ровно 70000 t-states x 50 = 3.5 Mhz
    setTimeout('frameUpdate()', 20);

    // Если ничего на дисплее не поменяется - не обновлять
    display_affect = 0;

    core.begin();
    while (t_states < 70000) {

        // console.log(z80.get_pc().toString(16));
        t_states += z80.run_instruction();
    }

    // Вызов происходит на VBlank
    z80.interrupt(0, 0xFF);

    if (display_cycles >= 15) {

        core.begin();
        core.update_display();

        display_cycles = 0;
        display_flash = 1 - display_flash;
        display_affect = 1;

    } else {
        display_cycles++;
    }

    if (display_affect) {
        core.end();
    }

}

// Загрузка ROM-48 из памяти
function load_rom(image_file) {

    var xhr = new XMLHttpRequest();
    xhr.open('GET', image_file + '?' + Math.random().toString().substr(2), true);
    xhr.responseType = 'arraybuffer';
    xhr.onload = function() {

        core = new CORE();
        var arr = new Uint8Array(this.response);

        // Инициализация keyStates
        for (var row = 0; row < 8; row++) {
            keyStates[row] = 0xFF;
        }

        window.onkeydown = core.keyDown.bind(core);
        window.onkeyup   = core.keyUp.bind(core);

        // Инициализация экрана
        core.get_canvas('screen');

        for (var i = 0; i < 16384; i++) {
            core.memory[i] = arr[i];
        }

        z80 = new Z80( core );
        z80.reset();

        frameUpdate();
    };

    xhr.send();
}

// Загрузка файла Z80
function load_z80(z80_file) {

    var xhr = new XMLHttpRequest();
    xhr.open('GET', z80_file + '?' + Math.random().toString().substr(2), true);
    xhr.responseType = 'arraybuffer';
    xhr.onload = function() {

        // Загрузить z80-файл в память
        z80.load_z80( new Uint8Array(this.response) );
    };

    xhr.send();
    return false;
}
