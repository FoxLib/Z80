#include "SDL.h"

// ds_viewmode
#define DSVM_DISASM  0
#define DSVM_ZXSPECT 1

enum FLAGS_BIT {

    FLAG_S = 0x80,
    FLAG_Z = 0x40,
    FLAG_Y = 0x20,
    FLAG_H = 0x10,
    FLAG_X = 0x08,
    FLAG_P = 0x04,
    FLAG_N = 0x02,
    FLAG_C = 0x01
};

// Регистры процессора
struct REGS {

    uint8_t  b,  c,  d,  e,  h,  l,  a,  f;
    uint8_t  b_, c_, d_, e_, h_, l_, a_, f_;
    uint16_t sp, pc;
    uint16_t ix, iy;
    uint8_t  i,  r;
};

// Биты четности
static const unsigned char parity_bits[256] = {
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
  1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1
};

static const int imid[8] = {0, 0, 1, 2, 0, 0, 1, 2};

// Аудиоданные
static int au_data_buffer[882*16];
static int au_sdl_frame;
static int au_z80_frame;
static int au_z80_id;

// ---------------------------------------------------------------------
// Объявление класса
// ---------------------------------------------------------------------

class z80 {

protected:

    /** Дисплей */
    int width, height;
    SDL_Event       event;
    SDL_Surface*    sdl_screen;

    int border;
    int marque;
    int ticker;
    int rows[8];    

    /** Дизассемблер */
    int color_fore;
    int color_back;

    /** Процессор */
    unsigned char mem[65536];
    struct REGS   reg;

    int  im;
    int  iff0;
    int  iff1;
    int  halt;
    int  cycles;            // Общие циклы
    int  tstates;           // Циклические

    int  has_prefix;        // Какой префикс сейчас хазный?
    int  allow_undoc;       // =1 разрешить недокументированную запись в 8 битные регистры
    int  address_hl;        // Для расчета (HL)
    int  started;           // Процессор запущен?
    int  rq_stop;           // Запрос остановки
    int  rq_start;          // Запрос запуска
    int  opcode;
    int  audio_out;

    // Включение и выключение прерываний
    int  delay_di;
    int  delay_ei;

    /** Дизассемблер */
    int  ds_ad;             // Текущая временная позиция разбора инструкции
    int  ds_size;           // Размер инструкции
    char ds_opcode[16];
    char ds_operand[32];
    char ds_prefix[16];
    int  ds_rowdis[48];     // Адреса в строках
    int  bp_rows[256];      // Точки прерываний
    int  bp_count;
    int  ds_start;          // Верхний адрес
    int  ds_cursor;         // Курсор на линии (обычно совпадает с PC)
    int  ds_viewmode;       // 0=Дизасм 1=Прод
    int  ds_dumpaddr;
    int  ds_match_row;      // Номер строки, где курсор
    int  bp_step_over;      // =1 Включена остановка на следующем PC
    int  bp_step_sp;
    int  bp_step_pc;

    /** Звук */
    SDL_AudioSpec   audio_device;

public:

    int  enable_halt;       // =1 Остановка на HALT разрешена

    // Прототипы
    z80(const char*);

    /** BASIC.CC */
    void handle();
    void loadbin(const char*, int);
    void loadz80(const char*);
    void pset(int x, int y, uint color);
    void flip();

    int  get_video_pixel(int x, int y);
    int  get_color(int color);
    void update_border();
    void update_video_byte(int addr);
    void redraw();
    void repaint();

    z80* cls();
    z80* color(int fore, int back);
    void print_char(int x, int y, unsigned char ch);
    void print(int x, int y, const char*);

    int  get_key(SDL_Event event);
    void zx_row(int mode, int row, int mask);
    void zx_kbd(int kp, int mode);

    void stop_cpu();
    void start_cpu();   

    /** DISASM.CC */
    void ixy_disp(int prefix);
    int  ds_fetch_byte();
    int  ds_fetch_word();
    int  ds_fetch_rel();
    int  disasm_line(int addr);
    void disasm_repaint();

    /** CPU.CC */
    void inc_r();
    int  read_byte(int addr);
    int  read_word(int addr);
    void write_byte(int addr, int data);
    void write_word(int addr, int data);
    int  fetch_byte();
    int  fetch_word();

    int  get_reg16(int r16);
    void put_reg16(int r16, int data);
    int  get_reg8(int r8);
    void put_reg8(int r8, int data);
    void fetch_prefixed_hl();
    void conditional_relative(int);
    int  get_flag(int bitflag);
    void set_flag(int bitflag, int value);
    int  update_xy_flags(int);

    // Сдвиговые
    int  do_rlc(int operand);
    int  do_rrc(int operand);
    int  do_rl(int operand);
    int  do_rr(int operand);
    int  do_sla(int operand);
    int  do_sra(int operand);
    int  do_sll(int operand);
    int  do_srl(int operand);

    // Специальная арифметика
    void do_daa();
    void do_cpl();
    void do_scf();
    void do_ccf();
    void do_hl_add(int operand);
    int  inc8(int operand);
    int  dec8(int operand);

    // Арифметико-логика
    void aluop(int mode, int operand);
    void do_add(int operand);
    void do_adc(int operand);
    void do_sub(int operand);
    void do_sbc(int operand);
    void do_and(int operand);
    void do_xor(int operand);
    void do_or(int operand);
    void do_cp(int operand);
    void do_neg();
    void adc_hl(int operand);
    void sbc_hl(int operand);
    void rld();
    void rrd();
    void do_ldi();
    void do_ldd();
    void do_cpid(int);
    void do_inid(int);
    void do_outid(int);

    // Помощники
    int  ioread(int port);
    int  check_cond(int mode);
    void push_word(int operand);
    int  pop_word();
    int  do_in(int port);
    void do_out(int port, int data);
    void do_interrupt();

    int  step();
};
