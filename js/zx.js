class zx {

    constructor() {

        this.mem = new Uint8Array(128*1024); // 128k  RAM
        this.rom = new Uint8Array(32*1024);  // 2x16k ROM

        this.rombank = 0;
        this.rambank = 0;
        this.vidpage = 0;
        this.mlocked = 0;

        this.tstates = 0;
        this.started = 0;
        this.display_affect = 0;
        this.frame_num = 0;
        this.display_flash = 0;

        this.z80 = new Z80({

            // Чтение из памяти
            // ---------------------------------------------------------
            mem_read: function(address) {

                let A = address & 0x3FFF;

                // Чтение из ROM
                if (address < 0x4000) return this.rom[ this.rombank*0x4000 + A ];
                // Запись в RAM
                else if (address < 0x8000) return this.mem[ 5*0x4000 + A ];
                else if (address < 0xc000) return this.mem[ 2*0x4000 + A ];
                else return this.mem[ this.rambank*0x4000 + A ];

            }.bind(this),

            // Запись в память
            // ---------------------------------------------------------
            mem_write: function(address, data) {

                let A = address & 0x3FFF

                // Запись в ROM невозможна
                if (address < 0x4000) return;
                else if (address < 0x8000) {

                    // Запись в видеопамять
                    this.mem[ 5*0x4000 + A ] = data;

                    // Обновление данных на странице
                    if      (A < 0x1800) this.update_charline(A);
                    else if (A < 0x1B00) this.update_attrbox(A);
                }
                else if (address < 0xc000) this.mem[ 2*0x4000 + A ] = data;
                else this.mem[ this.rambank*0x4000 + A ] = data;

            }.bind(this),

            // Чтение из порта
            // ---------------------------------------------------------
            io_read: function(port) {

                let result = 0xff;

                // Чтение клавиатуры
                if ((port & 0xFF) == 0xFE) {

                    for (let row = 0; row < 8; row++) {

                        // bit held low, so scan this row
                        if (!(port & (1 << (row + 8)))) {
                            result &= this.keyStates[ row ];
                        }
                    }

                }

                return result;

            }.bind(this),

            // Запись в порт
            // ---------------------------------------------------------
            io_write: function(address, data) {

                // Управление памятью
                if (address == 0x7ffd && this.mlocked == 0) {

                    this.rambank = data & 0x07;
                    this.vidpage = data & 0x08 ? 1 : 0;
                    this.rombank = data & 0x10 ? 1 : 0;
                    this.mlocked = data & 0x20 ? 1 : 0;
                }

            }.bind(this),
        });

        this.el  = document.getElementById('viewport');
        this.ctx = this.el.getContext('2d');
        this.img = this.ctx.getImageData(0, 0, this.el.width, this.el.height);

        this.keyStates = [];
        this.keyCodes = {
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
        this.keyCombo = {
            8:      [16, 48],       // DELETE
            186:    [17, 90],       // :
            // 192: [16, 49],       // Тильда вызываем EDIT
        };

        // Инициализация keyStates
        for (let row = 0; row < 8; row++) this.keyStates[row] = 0xFF;

        // Регистрируе событие клавиатуры
        window.onkeydown = function(e) { return this.keypress(e, 1); }.bind(this);
        window.onkeyup   = function(e) { return this.keypress(e, 0); }.bind(this);

        // Загрузка ROM в память
        this.load("rom/zx128.bin", function(data) {

            for (let i = 0; i < 16384; i++) this.rom[i] = data[i];
            this.load("rom/zx48.bin", function(data) {

                for (let i = 0; i < 16384; i++) this.rom[16384 + i] = data[i];
                this.reset();

            }.bind(this));
        }.bind(this));
    }

    // Сброс процессора и старт
    reset() {

        this.z80.reset();

        // Запуск только если реально запущено
        if (this.started == 0) { this.frame(); this.started = 1; }
    }

    // Загрузка бинарных данных
    load(url, callback) {

        let xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.responseType = "arraybuffer";
        xhr.send();
        xhr.onload = function() {

            if (xhr.status !== 200) {
                alert(`Ошибка ${xhr.status}: ${xhr.statusText}`);
            } else {
                callback(new Uint8Array(xhr.response));
            }
        }
    }

    // Вычисление размера экрана
    windowsize() {

        let win  = window, doc = document, docelem = doc.documentElement,
            body = doc.getElementsByTagName('body')[0],
            wx = win.innerWidth  || docelem.clientWidth || body.clientWidth,
            wy = win.innerHeight || docelem.clientHeight|| body.clientHeight;

        return {w: wx, h: wy};
    }

    // Рисование пикселя на экране
    pset(x, y, k) {

        if (x < this.el.width && y < this.el.height && x >= 0 && y >= 0) {

            let p = 4*(x + y * this.el.width);
            this.img.data[p    ] =  (k >> 16) & 0xff;
            this.img.data[p + 1] =  (k >>  8) & 0xff;
            this.img.data[p + 2] =  (k      ) & 0xff;
            this.img.data[p + 3] = ((k >> 24) & 0xff) ^ 0xff;
        }
    }

    // Обновление экрана
    flush() { this.ctx.putImageData(this.img, 0, 0); }

    // ------------------- РАБОТА С КЛАВИАТУРОЙ ------------------------

    // Процессинг нажатия на клавиатуру
    keypress(evt, action) {

        let keyCode = this.keyCodes[ evt.keyCode ];
        if (keyCode === null) {

            let keyCom = this.keyCombo[ evt.keyCode ];
            if (keyCom === null) {
                return;

            } else {

                for (let id in keyCom) {

                    keyCode = this.keyCodes[ keyCom[ id ] ];

                    if (action) {
                        this.keyStates[ keyCode.row ] &= ~(keyCode.mask);
                    } else {
                        this.keyStates[ keyCode.row ] |=  (keyCode.mask);
                    }
                }
            }

        } else {

            if (action) {
                this.keyStates[ keyCode.row ] &= ~(keyCode.mask);
            } else {
                this.keyStates[ keyCode.row ] |=  (keyCode.mask);
            }
        }

        evt.preventDefault();
        evt.stopPropagation();
        return false;
    }

    // ------------------- РАБОТА С ЭКРАНОМ ----------------------------

    get_color(color) {

        switch (color) {

            // Lo
            case 0: return 0x000000;
            case 1: return 0x0000c0;
            case 2: return 0xc00000;
            case 3: return 0xc000c0;
            case 4: return 0x00c000;
            case 5: return 0x00c0c0;
            case 6: return 0xc0c000;
            case 7: return 0xc0c0c0;
            // Hi
            case 8: return 0x000000;
            case 9: return 0x0000FF;
            case 10: return 0xFF0000;
            case 11: return 0xFF00FF;
            case 12: return 0x00FF00;
            case 13: return 0x00FFFF;
            case 14: return 0xFFFF00;
            case 15: return 0xFFFFFF;
        }

        return 0;
    };

    // Обновить определенную линию
    update_charline(address) {

        address &= 0x3FFF;

        let base = (this.vidpage ? 7 : 5) * 0x4000;
        let byte = this.mem[base + address];

        let Ya = (address & 0x0700) >> 8;
        let Yb = (address & 0x00E0) >> 5;
        let Yc = (address & 0x1800) >> 11;

        let y = Ya + Yb*8 + Yc*64;
        let x = address & 0x1F;

        let attr    = this.mem[base + 0x1800 + x + ((address & 0x1800) >> 3) + (address & 0xE0)];
        let bgcolor = this.get_color((attr & 0x38) >> 3);
        let frcolor = this.get_color((attr & 0x07) + ((attr & 0x40) >> 3));
        let flash   = (attr & 0x80) ? 1 : 0;

        for (let j = 0; j < 8; j++) {

            let pix = (byte & (0x80 >> j)) ? 1 : 0;
            let clr = (flash ? (pix ^ this.display_flash) : pix) ? frcolor : bgcolor;
            this.pset(8 * x + j, y, clr);
        }

        this.display_affect = 1;
    };

    // Обновить все атрибуты
    update_attrbox(address) {

        address -= 0x1800;
        let addr = (address & 0x0FF) + ((address & 0x0300) << 3);
        for (let i = 0; i < 8; i++)
            this.update_charline(addr + (i<<8));
    };

    // Обновить весь дисплей
    update_display() {

        for (let addr = 0x1800; addr < 0x1B00; addr++)
            this.update_attrbox(addr);
    };

    // ------------------- RUN INSTRUCTIONS ----------------------------
    frame() {

        let time = (new Date()).getTime();
        this.display_affect = 0;

        // Выполнить фрейм
        while (this.tstates < 70000) {
            this.tstates += this.z80.run_instruction();
        }
        this.tstates %= 70000;

        // Вызвать видео прерывание
        this.z80.interrupt(0, 0xFF);

        // Каждые 25 кадров перерисовка всего экрана
        this.frame_num++;

        // Обновить экран раз в 0.5 секунд
        if (this.frame_num == 25) {
            this.frame_num = 0;
            this.update_display();
            this.display_flash = 1 - this.display_flash;
            this.flush();

        } else if (this.display_affect) {
            this.flush();
        }

        // Расчет следующего кадра
        time = (new Date()).getTime() - time;

        if (time < 20) time = 20 - time;
        else time = 1;

        // Request new frame
        setTimeout(function() { this.frame(); }.bind(this), time);
    }
}
