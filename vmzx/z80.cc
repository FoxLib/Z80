struct Tflags {
    char S, Z, Y, H, X, P, N, C;
};

static const int parity_bits[256] = {
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


///////////////////////////////////////////////////////////////////////////////
/// These tables contain the number of T cycles used for each instruction.
/// In a few special cases, such as conditional control flow instructions,
///  additional cycles might be added to these values.
/// The total number of cycles is the return value of run_instruction().
///////////////////////////////////////////////////////////////////////////////

static const int cycle_counts[256] = {
    4, 10,  7,  6,  4,  4,  7,  4,  4, 11,  7,  6,  4,  4,  7,  4,
    8, 10,  7,  6,  4,  4,  7,  4, 12, 11,  7,  6,  4,  4,  7,  4,
    7, 10, 16,  6,  4,  4,  7,  4,  7, 11, 16,  6,  4,  4,  7,  4,
    7, 10, 13,  6, 11, 11, 10,  4,  7, 11, 13,  6,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    7,  7,  7,  7,  7,  7,  4,  7,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    4,  4,  4,  4,  4,  4,  7,  4,  4,  4,  4,  4,  4,  4,  7,  4,
    5, 10, 10, 10, 10, 11,  7, 11,  5, 10, 10,  0, 10, 17,  7, 11,
    5, 10, 10, 11, 10, 11,  7, 11,  5,  4, 10, 11, 10,  0,  7, 11,
    5, 10, 10, 19, 10, 11,  7, 11,  5,  4, 10,  4, 10,  0,  7, 11,
    5, 10, 10,  4, 10, 11,  7, 11,  5,  6, 10,  4, 10,  0,  7, 11
};

static const int cycle_counts_ed[256] = {
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   12, 12, 15, 20,  8, 14,  8,  9, 12, 12, 15, 20,  8, 14,  8,  9,
   12, 12, 15, 20,  8, 14,  8,  9, 12, 12, 15, 20,  8, 14,  8,  9,
   12, 12, 15, 20,  8, 14,  8, 18, 12, 12, 15, 20,  8, 14,  8, 18,
   12, 12, 15, 20,  8, 14,  8,  0, 12, 12, 15, 20,  8, 14,  8,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   16, 16, 16, 16,  0,  0,  0,  0, 16, 16, 16, 16,  0,  0,  0,  0,
   16, 16, 16, 16,  0,  0,  0,  0, 16, 16, 16, 16,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
};

static const int cycle_counts_cb[256] = {
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 12,  8,  8,  8,  8,  8,  8,  8, 12,  8,
    8,  8,  8,  8,  8,  8, 12,  8,  8,  8,  8,  8,  8,  8, 12,  8,
    8,  8,  8,  8,  8,  8, 12,  8,  8,  8,  8,  8,  8,  8, 12,  8,
    8,  8,  8,  8,  8,  8, 12,  8,  8,  8,  8,  8,  8,  8, 12,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8,
    8,  8,  8,  8,  8,  8, 15,  8,  8,  8,  8,  8,  8,  8, 15,  8
};

static const int cycle_counts_dd[256] = {
    0,  0,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,
    0, 14, 20, 10,  8,  8, 11,  0,  0, 15, 20, 10,  8,  8, 11,  0,
    0,  0,  0,  0, 23, 23, 19,  0,  0, 15,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
    0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
    8,  8,  8,  8,  8,  8, 19,  8,  8,  8,  8,  8,  8,  8, 19,  8,
   19, 19, 19, 19, 19, 19,  0, 19,  0,  0,  0,  0,  8,  8, 19,  0,
    0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
    0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
    0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
    0,  0,  0,  0,  8,  8, 19,  0,  0,  0,  0,  0,  8,  8, 19,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0, 14,  0, 23,  0, 15,  0,  0,  0,  8,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0, 10,  0,  0,  0,  0,  0,  0
};

class Z80 {
protected:

    // All right, let's initialize the registers.
    // First, the standard 8080 registers.
    int a, b, c, d, e, h, l;

    // Now the special Z80 copies of the 8080 registers
    //  (the ones used for the SWAP instruction and such).
    int a_prime, b_prime, c_prime, d_prime, e_prime, h_prime, l_prime;

    // And now the Z80 index registers.
    int ix, iy;

    // Then the "utility" registers: the interrupt vector,
    //  the memory refresh, the stack pointer (dff0), and the program counter.
    int i, r, sp, pc;

    // We don't keep an F register for the flags,
    //  because most of the time we're only accessing a single flag,
    //  so we optimize for that case and use utility functions
    //  for the rarer occasions when we need to access the whole register.
    struct Tflags flags, flags_prime;

    // And finally we have the interrupt mode and flip-flop registers.
    int imode, iff1, iff2;

    // These are all specific to this implementation, not Z80 features.
    // Keep track of whether we've had a HALT instruction called.
    int halted;

    // EI and DI wait one instruction before they take effect;
    //  these flags tell us when we're in that wait state.
    int do_delayed_di;
    int do_delayed_ei;

    // This tracks the number of cycles spent in a single instruction run,
    //  including processing any prefixes and handling interrupts.
    int cycle_counter;

public:

    Z80() { reset(); }

    // Сброс процессора
    void reset() {

        a = b = c = d = e = h = l = 0x00;
        a_prime = b_prime = c_prime = d_prime = e_prime = h_prime = l_prime = 0x00;
        ix = iy = i = r = pc = 0x0000;
        sp = 0xdff0;
        imode = iff1 = iff2 = 0;
        halted = 0;
        do_delayed_di = do_delayed_ei = 0;
        cycle_counter = 0;
    }

    // Интерфейс
    virtual int  mem_read(int address) { return 0xff; }
    virtual int  io_read (int port)    { return 0xff; }
    virtual void mem_write(int address, int data) { }
    virtual void io_write (int port,    int data) { }

    ///////////////////////////////////////////////////////////////////////////////
    /// @public run_instruction
    ///
    /// @brief Runs a single instruction
    ///
    /// @return The number of T cycles the instruction took to run,
    ///          plus any time that went into handling interrupts that fired
    ///          while this instruction was executing
    ///////////////////////////////////////////////////////////////////////////////

    int run_instruction()
    {
        if (!halted)
        {
            // If the previous instruction was a DI or an EI,
            //  we'll need to disable or enable interrupts
            //  after whatever instruction we're about to run is finished.
            int doing_delayed_di = 0,
                doing_delayed_ei = 0;

            if      (do_delayed_di) { do_delayed_di = 0; doing_delayed_di = 1; }
            else if (do_delayed_ei) { do_delayed_ei = 0; doing_delayed_ei = 1; }

            // R is incremented at the start of every instruction cycle,
            //  before the instruction actually runs.
            // The high bit of R is not affected by this increment,
            //  it can only be changed using the LD R, A instruction.
            r = (r & 0x80) | (((r & 0x7f) + 1) & 0x7f);

            // Read the byte at the PC and run the instruction it encodes.
            int opcode = mem_read(pc);
            decode_instruction(opcode);

            pc = (pc + 1) & 0xffff;

            // Actually do the delayed interrupt disable/enable if we have one.
            if      (doing_delayed_di) { iff1 = 0; iff2 = 0; }
            else if (doing_delayed_ei) { iff1 = 1; iff2 = 1; }

            // And finally clear out the cycle counter for the next instruction
            //  before returning it to the emulator
            int retval = cycle_counter;
            cycle_counter = 0;

            return retval;
        }
        else
        {
            // While we're halted, claim that we spent a cycle doing nothing,
            //  so that the rest of the emulator can still proceed.
            return 1;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    /// @public interrupt
    ///
    /// @brief Simulates pulsing the processor's INT (or NMI) pin
    ///
    /// @param non_maskable - true if this is a non-maskable interrupt
    /// @param data - the value to be placed on the data bus, if needed
    ///////////////////////////////////////////////////////////////////////////////

    void interrupt(int non_maskable, int data)
    {
        if (non_maskable)
        {
            // The high bit of R is not affected by this increment,
            //  it can only be changed using the LD R, A instruction.
            r = (r & 0x80) | (((r & 0x7f) + 1) & 0x7f);

            // Non-maskable interrupts are always handled the same way;
            //  clear IFF1 and then do a CALL 0x0066.
            // Also, all interrupts reset the HALT state.
            halted = 0;
            iff2 = iff1;
            iff1 = 0;
            push_word(pc);
            pc = 0x66;
            cycle_counter += 11;
        }
        else if (iff1)
        {
            // The high bit of R is not affected by this increment,
            //  it can only be changed using the LD R, A instruction.
            r = (r & 0x80) | (((r & 0x7f) + 1) & 0x7f);

            halted = 0;
            iff1 = 0;
            iff2 = 0;

            if (imode == 0)
            {
                // In the 8080-compatible interrupt mode,
                //  decode the content of the data bus as an instruction and run it.
                // it's probably a RST instruction, which pushes (PC+1) onto the stack
                // so we should decrement PC before we decode the instruction
                pc = (pc - 1) & 0xffff;
                decode_instruction(data);
                pc = (pc + 1) & 0xffff; // increment PC upon return
                cycle_counter += 2;
            }
            else if (imode == 1)
            {
                // Mode 1 is always just RST 0x38.
                push_word(pc);
                pc = 0x38;
                cycle_counter += 13;
            }
            else if (imode == 2)
            {
                // Mode 2 uses the value on the data bus as in index
                //  into the vector table pointer to by the I register.
                push_word(pc);

                // The Z80 manual says that this address must be 2-byte aligned,
                //  but it doesn't appear that this is actually the case on the hardware,
                //  so we don't attempt to enforce that here.
                int vector_address = ((i << 8) | data);
                pc = mem_read(vector_address) |
                    (mem_read((vector_address + 1) & 0xffff) << 8);

                cycle_counter += 19;
            }
        }
    }

    // The register-to-register loads and ALU instructions
    //  are all so uniform that we can decode them directly
    //  instead of going into the instruction array for them.
    // This function gets the operand for all of these instructions.

    int get_operand(int opcode)
    {
        return  ((opcode & 0x07) == 0) ? b :
                ((opcode & 0x07) == 1) ? c :
                ((opcode & 0x07) == 2) ? d :
                ((opcode & 0x07) == 3) ? e :
                ((opcode & 0x07) == 4) ? h :
                ((opcode & 0x07) == 5) ? l :
                ((opcode & 0x07) == 6) ? mem_read(l | (h << 8)) : a;
    };

    // Декодирование инструкции
    void decode_instruction(int opcode) {

        // Handle HALT right up front, because it fouls up our LD decoding
        //  by falling where LD (HL), (HL) ought to be.
        if (opcode == 0x76)
        {
            halted = 1;
        }
        // This entire range is all 8-bit register loads.
        // Get the operand and assign it to the correct destination.
        else if ((opcode >= 0x40) && (opcode < 0x80))
        {
            int operand = get_operand(opcode);

            switch ((opcode & 0x38) >> 3) {

                case 0: b = operand; break;
                case 1: c = operand; break;
                case 2: d = operand; break;
                case 3: e = operand; break;
                case 4: h = operand; break;
                case 5: l = operand; break;
                case 6: mem_write(l | (h << 8), operand); break;
                case 7: a = operand; break;
            }
        }
        // These are the 8-bit register ALU instructions.
        // We'll get the operand and then use this "jump table"
        //  to call the correct utility function for the instruction.
        else if ((opcode >= 0x80) && (opcode < 0xc0))
        {
            int operand = get_operand(opcode);

            switch ((opcode & 0x38) >> 3) {
                case 0: do_add(operand); break;
                case 1: do_adc(operand); break;
                case 2: do_sub(operand); break;
                case 3: do_sbc(operand); break;
                case 4: do_and(operand); break;
                case 5: do_xor(operand); break;
                case 6: do_or (operand); break;
                case 7: do_cp (operand); break;
            }
        }
        else
        {
            // This is one of the less formulaic instructions;
            //  we'll get the specific function for it from our array.

            switch (opcode) {

                // 0x00 : NOP
                case 0x00:
                {
                    break;
                }
                // 0x01 : LD BC, nn
                case 0x01:
                {
                    pc = (pc + 1) & 0xffff;
                    c = mem_read(pc);

                    pc = (pc + 1) & 0xffff;
                    b = mem_read(pc);
                    break;
                };
                // 0x02 : LD (BC), A
                case 0x02:
                {
                    mem_write(c | (b << 8), a);
                    break;
                };
                // 0x03 : INC BC
                case 0x03:
                {
                    int result = (c | (b << 8));
                    result += 1;
                    c = result & 0xff;
                    b = (result & 0xff00) >> 8;
                    break;
                };
                // 0x04 : INC B
                case 0x04:
                {
                    b = do_inc(b);
                    break;
                };
                // 0x05 : DEC B
                case 0x05:
                {
                    b = do_dec(b);
                    break;
                };
                // 0x06 : LD B, n
                case 0x06:
                {
                    pc = (pc + 1) & 0xffff;
                    b = mem_read(pc);
                    break;
                };
                // 0x07 : RLCA
                case 0x07:
                {
                    // This instruction is implemented as a special case of the
                    //  more general Z80-specific RLC instruction.
                    // Specifially, RLCA is a version of RLC A that affects fewer flags.
                    // The same applies to RRCA, RLA, and RRA.
                    int temp_s = flags.S, temp_z = flags.Z, temp_p = flags.P;
                    a = do_rlc(a);
                    flags.S = temp_s;
                    flags.Z = temp_z;
                    flags.P = temp_p;
                    break;
                };
                // 0x08 : EX AF, AF'
                case 0x08:
                {
                    int temp = a;
                    a = a_prime;
                    a_prime = temp;

                    temp = get_flags_register();
                    set_flags_register(get_flags_prime());
                    set_flags_prime(temp);
                    break;
                };
                // 0x09 : ADD HL, BC
                case 0x09:
                {
                    do_hl_add(c | (b << 8));
                    break;
                };
                // 0x0a : LD A, (BC)
                case 0x0a:
                {
                    a = mem_read(c | (b << 8));
                    break;
                };
                // 0x0b : DEC BC
                case 0x0b:
                {
                    int result = (c | (b << 8));
                    result -= 1;
                    c = result & 0xff;
                    b = (result & 0xff00) >> 8;
                    break;
                };
                // 0x0c : INC C
                case 0x0c:
                {
                    c = do_inc(c);
                    break;
                };
                // 0x0d : DEC C
                case 0x0d:
                {
                    c = do_dec(c);
                    break;
                };
                // 0x0e : LD C, n
                case 0x0e:
                {
                    pc = (pc + 1) & 0xffff;
                    c = mem_read(pc);
                    break;
                };
                // 0x0f : RRCA
                case 0x0f:
                {
                    int temp_s = flags.S, temp_z = flags.Z, temp_p = flags.P;
                    a = do_rrc(a);
                    flags.S = temp_s;
                    flags.Z = temp_z;
                    flags.P = temp_p;
                    break;
                };
                // 0x10 : DJNZ nn
                case 0x10:
                {
                    b = (b - 1) & 0xff;
                    do_conditional_relative_jump(b != 0);
                    break;
                };
                // 0x11 : LD DE, nn
                case 0x11:
                {
                    pc = (pc + 1) & 0xffff;
                    e = mem_read(pc);
                    pc = (pc + 1) & 0xffff;
                    d = mem_read(pc);
                    break;
                };
                // 0x12 : LD (DE), A
                case 0x12:
                {
                    mem_write(e | (d << 8), a);
                    break;
                };
                // 0x13 : INC DE
                case 0x13:
                {
                    int result = (e | (d << 8));
                    result += 1;
                    e = result & 0xff;
                    d = (result & 0xff00) >> 8;
                    break;
                };
                // 0x14 : INC D
                case 0x14:
                {
                    d = do_inc(d);
                    break;
                };
                // 0x15 : DEC D
                case 0x15:
                {
                    d = do_dec(d);
                    break;
                };
                // 0x16 : LD D, n
                case 0x16:
                {
                    pc = (pc + 1) & 0xffff;
                    d = mem_read(pc);
                    break;
                };
                // 0x17 : RLA
                case 0x17:
                {
                    int temp_s = flags.S, temp_z = flags.Z, temp_p = flags.P;
                    a = do_rl(a);
                    flags.S = temp_s;
                    flags.Z = temp_z;
                    flags.P = temp_p;
                    break;
                };
                // 0x18 : JR n
                case 0x18:
                {
                    int offset = get_signed_offset_byte(mem_read((pc + 1) & 0xffff));
                    pc = (pc + offset + 1) & 0xffff;
                    break;
                };
                // 0x19 : ADD HL, DE
                case 0x19:
                {
                    do_hl_add(e | (d << 8));
                    break;
                };
                // 0x1a : LD A, (DE)
                case 0x1a:
                {
                    a = mem_read(e | (d << 8));
                    break;
                };
                // 0x1b : DEC DE
                case 0x1b:
                {
                    int result = (e | (d << 8));
                    result -= 1;
                    e = result & 0xff;
                    d = (result & 0xff00) >> 8;
                    break;
                };
                // 0x1c : INC E
                case 0x1c:
                {
                    e = do_inc(e);
                    break;
                };
                // 0x1d : DEC E
                case 0x1d:
                {
                    e = do_dec(e);
                    break;
                };
                // 0x1e : LD E, n
                case 0x1e:
                {
                    pc = (pc + 1) & 0xffff;
                    e = mem_read(pc);
                    break;
                };
                // 0x1f : RRA
                case 0x1f:
                {
                    int temp_s = flags.S, temp_z = flags.Z, temp_p = flags.P;
                    a = do_rr(a);
                    flags.S = temp_s;
                    flags.Z = temp_z;
                    flags.P = temp_p;
                    break;
                };
                // 0x20 : JR NZ, n
                case 0x20:
                {
                    do_conditional_relative_jump(!flags.Z);
                    break;
                };
                // 0x21 : LD HL, nn
                case 0x21:
                {
                    pc = (pc + 1) & 0xffff;
                    l = mem_read(pc);
                    pc = (pc + 1) & 0xffff;
                    h = mem_read(pc);
                    break;
                };
                // 0x22 : LD (nn), HL
                case 0x22:
                {
                    pc = (pc + 1) & 0xffff;
                    int address = mem_read(pc);
                    pc = (pc + 1) & 0xffff;
                    address |= mem_read(pc) << 8;

                    mem_write(address, l);
                    mem_write((address + 1) & 0xffff, h);
                    break;
                };
                // 0x23 : INC HL
                case 0x23:
                {
                    int result = (l | (h << 8));
                    result += 1;
                    l = result & 0xff;
                    h = (result & 0xff00) >> 8;
                    break;
                };
                // 0x24 : INC H
                case 0x24:
                {
                    h = do_inc(h);
                    break;
                };
                // 0x25 : DEC H
                case 0x25:
                {
                    h = do_dec(h);
                    break;
                };
                // 0x26 : LD H, n
                case 0x26:
                {
                    pc = (pc + 1) & 0xffff;
                    h = mem_read(pc);
                    break;
                };
                // 0x27 : DAA
                case 0x27:
                {
                    int temp = a;
                    if (!flags.N)
                    {
                        if (flags.H || ((a & 0x0f) > 9))
                            temp += 0x06;
                        if (flags.C || (a > 0x99))
                            temp += 0x60;
                    }
                    else
                    {
                        if (flags.H || ((a & 0x0f) > 9))
                            temp -= 0x06;
                        if (flags.C || (a > 0x99))
                            temp -= 0x60;
                    }

                    flags.S = (temp & 0x80) ? 1 : 0;
                    flags.Z = !(temp & 0xff) ? 1 : 0;
                    flags.H = ((a & 0x10) ^ (temp & 0x10)) ? 1 : 0;
                    flags.P = get_parity(temp & 0xff);
                    // DAA never clears the carry flag if it was already set,
                    //  but it is able to set the carry flag if it was clear.
                    // Don't ask me, I don't know.
                    // Note also that we check for a BCD carry, instead of the usual.
                    flags.C = (flags.C || (a > 0x99)) ? 1 : 0;

                    a = temp & 0xff;

                    update_xy_flags(a);
                    break;
                };
                // 0x28 : JR Z, n
                case 0x28:
                {
                    do_conditional_relative_jump(!!flags.Z);
                    break;
                };
                // 0x29 : ADD HL, HL
                case 0x29:
                {
                    do_hl_add(l | (h << 8));
                    break;
                };
                // 0x2a : LD HL, (nn)
                case 0x2a:
                {
                    pc = (pc + 1) & 0xffff;
                    int address = mem_read(pc);
                    pc = (pc + 1) & 0xffff;
                    address |= mem_read(pc) << 8;

                    l = mem_read(address);
                    h = mem_read((address + 1) & 0xffff);
                    break;
                };
                // 0x2b : DEC HL
                case 0x2b:
                {
                    int result = (l | (h << 8));
                    result -= 1;
                    l = result & 0xff;
                    h = (result & 0xff00) >> 8;
                    break;
                };
                // 0x2c : INC L
                case 0x2c:
                {
                    l = do_inc(l);
                    break;
                };
                // 0x2d : DEC L
                case 0x2d:
                {
                    l = do_dec(l);
                    break;
                };
                // 0x2e : LD L, n
                case 0x2e:
                {
                    pc = (pc + 1) & 0xffff;
                    l = mem_read(pc);
                    break;
                };
                // 0x2f : CPL
                case 0x2f:
                {
                    a = (~a) & 0xff;
                    flags.N = 1;
                    flags.H = 1;
                    update_xy_flags(a);
                    break;
                };
                // 0x30 : JR NC, n
                case 0x30:
                {
                    do_conditional_relative_jump(!flags.C);
                    break;
                };
                // 0x31 : LD SP, nn
                case 0x31:
                {
                    sp =  mem_read((pc + 1) & 0xffff) |
                    (mem_read((pc + 2) & 0xffff) << 8);
                    pc = (pc + 2) & 0xffff;
                    break;
                };
                // 0x32 : LD (nn), A
                case 0x32:
                {
                    pc = (pc + 1) & 0xffff;
                    int address = mem_read(pc);
                    pc = (pc + 1) & 0xffff;
                    address |= mem_read(pc) << 8;

                    mem_write(address, a);
                    break;
                };
                // 0x33 : INC SP
                case 0x33:
                {
                    sp = (sp + 1) & 0xffff;
                    break;
                };
                // 0x34 : INC (HL)
                case 0x34:
                {
                    int address = l | (h << 8);
                    mem_write(address, do_inc(mem_read(address)));
                    break;
                };
                // 0x35 : DEC (HL)
                case 0x35:
                {
                    int address = l | (h << 8);
                    mem_write(address, do_dec(mem_read(address)));
                    break;
                };
                // 0x36 : LD (HL), n
                case 0x36:
                {
                    pc = (pc + 1) & 0xffff;
                    mem_write(l | (h << 8), mem_read(pc));
                    break;
                };
                // 0x37 : SCF
                case 0x37:
                {
                    flags.N = 0;
                    flags.H = 0;
                    flags.C = 1;
                    update_xy_flags(a);
                    break;
                };
                // 0x38 : JR C, n
                case 0x38:
                {
                    do_conditional_relative_jump(!!flags.C);
                    break;
                };
                // 0x39 : ADD HL, SP
                case 0x39:
                {
                    do_hl_add(sp);
                    break;
                };
                // 0x3a : LD A, (nn)
                case 0x3a:
                {
                    pc = (pc + 1) & 0xffff;
                    int address = mem_read(pc);
                    pc = (pc + 1) & 0xffff;
                    address |= mem_read(pc) << 8;

                    a = mem_read(address);
                    break;
                };
                // 0x3b : DEC SP
                case 0x3b:
                {
                    sp = (sp - 1) & 0xffff;
                    break;
                };
                // 0x3c : INC A
                case 0x3c:
                {
                    a = do_inc(a);
                    break;
                };
                // 0x3d : DEC A
                case 0x3d:
                {
                    a = do_dec(a);
                    break;
                };
                // 0x3e : LD A, n
                case 0x3e:
                {
                    a = mem_read((pc + 1) & 0xffff);
                    pc = (pc + 1) & 0xffff;
                    break;
                };
                // 0x3f : CCF
                case 0x3f:
                {
                    flags.N = 0;
                    flags.H = flags.C;
                    flags.C = flags.C ? 0 : 1;
                    update_xy_flags(a);
                    break;
                };

                // 0xc0 : RET NZ
                case 0xc0:
                {
                    do_conditional_return(!flags.Z);
                    break;
                };
                // 0xc1 : POP BC
                case 0xc1:
                {
                    int result = pop_word();
                    c = result & 0xff;
                    b = (result & 0xff00) >> 8;
                    break;
                };
                // 0xc2 : JP NZ, nn
                case 0xc2:
                {
                    do_conditional_absolute_jump(!flags.Z);
                    break;
                };
                // 0xc3 : JP nn
                case 0xc3:
                {
                    pc =  mem_read((pc + 1) & 0xffff) |
                    (mem_read((pc + 2) & 0xffff) << 8);
                    pc = (pc - 1) & 0xffff;
                    break;
                };
                // 0xc4 : CALL NZ, nn
                case 0xc4:
                {
                    do_conditional_call(!flags.Z);
                    break;
                };
                // 0xc5 : PUSH BC
                case 0xc5:
                {
                    push_word(c | (b << 8));
                    break;
                };
                // 0xc6 : ADD A, n
                case 0xc6:
                {
                    pc = (pc + 1) & 0xffff;
                    do_add(mem_read(pc));
                    break;
                };
                // 0xc7 : RST 00h
                case 0xc7:
                {
                    do_reset(0x00);
                    break;
                };
                // 0xc8 : RET Z
                case 0xc8:
                {
                    do_conditional_return(!!flags.Z);
                    break;
                };
                // 0xc9 : RET
                case 0xc9:
                {
                    pc = (pop_word() - 1) & 0xffff;
                    break;
                };
                // 0xca : JP Z, nn
                case 0xca:
                {
                    do_conditional_absolute_jump(!!flags.Z);
                    break;
                };
                // 0xcb : CB Prefix
                case 0xcb:
                {
                    // R is incremented at the start of the second instruction cycle,
                    //  before the instruction actually runs.
                    // The high bit of R is not affected by this increment,
                    //  it can only be changed using the LD R, A instruction.
                    r = (r & 0x80) | (((r & 0x7f) + 1) & 0x7f);

                    // We don't have a table for this prefix,
                    //  the instructions are all so uniform that we can directly decode them.
                    pc = (pc + 1) & 0xffff;
                    int opcode = mem_read(pc),
                    bit_number = (opcode & 0x38) >> 3,
                    reg_code = opcode & 0x07;

                    if (opcode < 0x40)
                    {
                        int operand;
                        switch (reg_code) {

                            case 0: operand = b; break;
                            case 1: operand = c; break;
                            case 2: operand = d; break;
                            case 3: operand = e; break;
                            case 4: operand = h; break;
                            case 5: operand = l; break;
                            case 6: operand = mem_read(l | (h << 8)); break;
                            case 7: operand = a; break;
                        }

                        // Shift/rotate instructions
                        switch (bit_number) {

                            case 0: operand = do_rlc(operand); break;
                            case 1: operand = do_rrc(operand); break;
                            case 2: operand = do_rl (operand); break;
                            case 3: operand = do_rr (operand); break;
                            case 4: operand = do_sla(operand); break;
                            case 5: operand = do_sra(operand); break;
                            case 6: operand = do_sll(operand); break;
                            case 7: operand = do_srl(operand); break;
                        }

                        switch (reg_code) {

                            case 0: b = operand; break;
                            case 1: c = operand; break;
                            case 2: d = operand; break;
                            case 3: e = operand; break;
                            case 4: h = operand; break;
                            case 5: l = operand; break;
                            case 6: mem_write(l | (h << 8), operand); break;
                            case 7: a = operand; break;
                        }

                    }
                    else if (opcode < 0x80)
                    {
                        // BIT instructions
                        if (reg_code == 0)
                            flags.Z = !(b & (1 << bit_number)) ? 1 : 0;
                        else if (reg_code == 1)
                            flags.Z = !(c & (1 << bit_number)) ? 1 : 0;
                        else if (reg_code == 2)
                            flags.Z = !(d & (1 << bit_number)) ? 1 : 0;
                        else if (reg_code == 3)
                            flags.Z = !(e & (1 << bit_number)) ? 1 : 0;
                        else if (reg_code == 4)
                            flags.Z = !(h & (1 << bit_number)) ? 1 : 0;
                        else if (reg_code == 5)
                            flags.Z = !(l & (1 << bit_number)) ? 1 : 0;
                        else if (reg_code == 6)
                            flags.Z = !((mem_read(l | (h << 8))) & (1 << bit_number)) ? 1 : 0;
                        else if (reg_code == 7)
                            flags.Z = !(a & (1 << bit_number)) ? 1 : 0;

                        flags.N = 0;
                        flags.H = 1;
                        flags.P = flags.Z;
                        flags.S = ((bit_number == 7) && !flags.Z) ? 1 : 0;
                        // For the BIT n, (HL) instruction, the X and Y flags are obtained
                        //  from what is apparently an internal temporary register used for
                        //  some of the 16-bit arithmetic instructions.
                        // I haven't implemented that register here,
                        //  so for now we'll set X and Y the same way for every BIT opcode,
                        //  which means that they will usually be wrong for BIT n, (HL).
                        flags.Y = ((bit_number == 5) && !flags.Z) ? 1 : 0;
                        flags.X = ((bit_number == 3) && !flags.Z) ? 1 : 0;
                    }
                    else if (opcode < 0xc0)
                    {
                        // RES instructions
                        if (reg_code == 0)
                            b &= (0xff & ~(1 << bit_number));
                        else if (reg_code == 1)
                            c &= (0xff & ~(1 << bit_number));
                        else if (reg_code == 2)
                            d &= (0xff & ~(1 << bit_number));
                        else if (reg_code == 3)
                            e &= (0xff & ~(1 << bit_number));
                        else if (reg_code == 4)
                            h &= (0xff & ~(1 << bit_number));
                        else if (reg_code == 5)
                            l &= (0xff & ~(1 << bit_number));
                        else if (reg_code == 6)
                            mem_write(l | (h << 8), mem_read(l | (h << 8)) & ~(1 << bit_number));
                        else if (reg_code == 7)
                            a &= (0xff & ~(1 << bit_number));
                    }
                    else
                    {
                        // SET instructions
                        if (reg_code == 0)
                            b |= (1 << bit_number);
                        else if (reg_code == 1)
                            c |= (1 << bit_number);
                        else if (reg_code == 2)
                            d |= (1 << bit_number);
                        else if (reg_code == 3)
                            e |= (1 << bit_number);
                        else if (reg_code == 4)
                            h |= (1 << bit_number);
                        else if (reg_code == 5)
                            l |= (1 << bit_number);
                        else if (reg_code == 6)
                            mem_write(l | (h << 8), mem_read(l | (h << 8)) | (1 << bit_number));
                        else if (reg_code == 7)
                            a |= (1 << bit_number);
                    }

                    cycle_counter += cycle_counts_cb[opcode];
                    break;
                };
                // 0xcc : CALL Z, nn
                case 0xcc:
                {
                    do_conditional_call(!!flags.Z);
                    break;
                };
                // 0xcd : CALL nn
                case 0xcd:
                {
                    push_word((pc + 3) & 0xffff);
                    pc =  mem_read((pc + 1) & 0xffff) |
                    (mem_read((pc + 2) & 0xffff) << 8);
                    pc = (pc - 1) & 0xffff;
                    break;
                };
                // 0xce : ADC A, n
                case 0xce:
                {
                    pc = (pc + 1) & 0xffff;
                    do_adc(mem_read(pc));
                    break;
                };
                // 0xcf : RST 08h
                case 0xcf:
                {
                    do_reset(0x08);
                    break;
                };
                // 0xd0 : RET NC
                case 0xd0:
                {
                    do_conditional_return(!flags.C);
                    break;
                };
                // 0xd1 : POP DE
                case 0xd1:
                {
                    int result = pop_word();
                    e = result & 0xff;
                    d = (result & 0xff00) >> 8;
                    break;
                };
                // 0xd2 : JP NC, nn
                case 0xd2:
                {
                    do_conditional_absolute_jump(!flags.C);
                    break;
                };
                // 0xd3 : OUT (n), A
                case 0xd3:
                {
                    pc = (pc + 1) & 0xffff;
                    io_write((a << 8) | mem_read(pc), a);
                    break;
                };
                // 0xd4 : CALL NC, nn
                case 0xd4:
                {
                    do_conditional_call(!flags.C);
                    break;
                };
                // 0xd5 : PUSH DE
                case 0xd5:
                {
                    push_word(e | (d << 8));
                    break;
                };
                // 0xd6 : SUB n
                case 0xd6:
                {
                    pc = (pc + 1) & 0xffff;
                    do_sub(mem_read(pc));
                    break;
                };
                // 0xd7 : RST 10h
                case 0xd7:
                {
                    do_reset(0x10);
                    break;
                };
                // 0xd8 : RET C
                case 0xd8:
                {
                    do_conditional_return(!!flags.C);
                    break;
                };
                // 0xd9 : EXX
                case 0xd9:
                {
                    int temp = b;
                    b = b_prime;
                    b_prime = temp;
                    temp = c;
                    c = c_prime;
                    c_prime = temp;
                    temp = d;
                    d = d_prime;
                    d_prime = temp;
                    temp = e;
                    e = e_prime;
                    e_prime = temp;
                    temp = h;
                    h = h_prime;
                    h_prime = temp;
                    temp = l;
                    l = l_prime;
                    l_prime = temp;
                    break;
                };
                // 0xda : JP C, nn
                case 0xda:
                {
                    do_conditional_absolute_jump(!!flags.C);
                    break;
                };
                // 0xdb : IN A, (n)
                case 0xdb:
                {
                    pc = (pc + 1) & 0xffff;
                    a = io_read((a << 8) | mem_read(pc));
                    break;
                };
                // 0xdc : CALL C, nn
                case 0xdc:
                {
                    do_conditional_call(!!flags.C);
                    break;
                };
                // 0xdd : DD Prefix (IX instructions)
/* @TODO
                case 0xdd:
                {
                    // R is incremented at the start of the second instruction cycle,
                    //  before the instruction actually runs.
                    // The high bit of R is not affected by this increment,
                    //  it can only be changed using the LD R, A instruction.
                    r = (r & 0x80) | (((r & 0x7f) + 1) & 0x7f);

                    pc = (pc + 1) & 0xffff;
                    int opcode = mem_read(pc),
                    func = dd_instructions[opcode];

                    if (func)
                    {
                        func();
                        cycle_counter += cycle_counts_dd[opcode];
                    }
                    else
                    {
                        // Apparently if a DD opcode doesn't exist,
                        //  it gets treated as an unprefixed opcode.
                        // What we'll do to handle that is just back up the
                        //  program counter, so that this byte gets decoded
                        //  as a normal instruction.
                        pc = (pc - 1) & 0xffff;
                        // And we'll add in the cycle count for a NOP.
                        cycle_counter += cycle_counts[0];
                    }
                    break;
                };
*/
                // 0xde : SBC n
                case 0xde:
                {
                    pc = (pc + 1) & 0xffff;
                    do_sbc(mem_read(pc));
                    break;
                };
                // 0xdf : RST 18h
                case 0xdf:
                {
                    do_reset(0x18);
                    break;
                };
                // 0xe0 : RET PO
                case 0xe0:
                {
                    do_conditional_return(!flags.P);
                    break;
                };
                // 0xe1 : POP HL
                case 0xe1:
                {
                    int result = pop_word();
                    l = result & 0xff;
                    h = (result & 0xff00) >> 8;
                    break;
                };
                // 0xe2 : JP PO, (nn)
                case 0xe2:
                {
                    do_conditional_absolute_jump(!flags.P);
                    break;
                };
                // 0xe3 : EX (SP), HL
                case 0xe3:
                {
                    int temp = mem_read(sp);
                    mem_write(sp, l);
                    l = temp;
                    temp = mem_read((sp + 1) & 0xffff);
                    mem_write((sp + 1) & 0xffff, h);
                    h = temp;
                    break;
                };
                // 0xe4 : CALL PO, nn
                case 0xe4:
                {
                    do_conditional_call(!flags.P);
                    break;
                };
                // 0xe5 : PUSH HL
                case 0xe5:
                {
                    push_word(l | (h << 8));
                    break;
                };
                // 0xe6 : AND n
                case 0xe6:
                {
                    pc = (pc + 1) & 0xffff;
                    do_and(mem_read(pc));
                    break;
                };
                // 0xe7 : RST 20h
                case 0xe7:
                {
                    do_reset(0x20);
                    break;
                };
                // 0xe8 : RET PE
                case 0xe8:
                {
                    do_conditional_return(!!flags.P);
                    break;
                };
                // 0xe9 : JP (HL)
                case 0xe9:
                {
                    pc = l | (h << 8);
                    pc = (pc - 1) & 0xffff;
                    break;
                };
                // 0xea : JP PE, nn
                case 0xea:
                {
                    do_conditional_absolute_jump(!!flags.P);
                    break;
                };
                // 0xeb : EX DE, HL
                case 0xeb:
                {
                    int temp = d;
                    d = h;
                    h = temp;
                    temp = e;
                    e = l;
                    l = temp;
                    break;
                };
                // 0xec : CALL PE, nn
                case 0xec:
                {
                    do_conditional_call(!!flags.P);
                    break;
                };
                // 0xed : ED Prefix
                case 0xed:
                {
                    // R is incremented at the start of the second instruction cycle,
                    //  before the instruction actually runs.
                    // The high bit of R is not affected by this increment,
                    //  it can only be changed using the LD R, A instruction.
                    r = (r & 0x80) | (((r & 0x7f) + 1) & 0x7f);

                    pc = (pc + 1) & 0xffff;
                    int opcode = mem_read(pc);

                    if (ed_instructions(opcode))
                    {
                        cycle_counter += cycle_counts_ed[opcode];
                    }
                    else
                    {
                        // If the opcode didn't exist, the whole thing is a two-byte NOP.
                        cycle_counter += cycle_counts[0];
                    }
                    break;
                };

                // 0xee : XOR n
                case 0xee:
                {
                    pc = (pc + 1) & 0xffff;
                    do_xor(mem_read(pc));
                    break;
                };
                // 0xef : RST 28h
                case 0xef:
                {
                    do_reset(0x28);
                    break;
                };
                // 0xf0 : RET P
                case 0xf0:
                {
                    do_conditional_return(!flags.S);
                    break;
                };
                // 0xf1 : POP AF
                case 0xf1:
                {
                    int result = pop_word();
                    set_flags_register(result & 0xff);
                    a = (result & 0xff00) >> 8;
                    break;
                };
                // 0xf2 : JP P, nn
                case 0xf2:
                {
                    do_conditional_absolute_jump(!flags.S);
                    break;
                };
                // 0xf3 : DI
                case 0xf3:
                {
                    // DI doesn't actually take effect until after the next instruction.
                    do_delayed_di = true;
                    break;
                };
                // 0xf4 : CALL P, nn
                case 0xf4:
                {
                    do_conditional_call(!flags.S);
                    break;
                };
                // 0xf5 : PUSH AF
                case 0xf5:
                {
                    push_word(get_flags_register() | (a << 8));
                    break;
                };
                // 0xf6 : OR n
                case 0xf6:
                {
                    pc = (pc + 1) & 0xffff;
                    do_or(mem_read(pc));
                    break;
                };
                // 0xf7 : RST 30h
                case 0xf7:
                {
                    do_reset(0x30);
                    break;
                };
                // 0xf8 : RET M
                case 0xf8:
                {
                    do_conditional_return(!!flags.S);
                    break;
                };
                // 0xf9 : LD SP, HL
                case 0xf9:
                {
                    sp = l | (h << 8);
                    break;
                };
                // 0xfa : JP M, nn
                case 0xfa:
                {
                    do_conditional_absolute_jump(!!flags.S);
                    break;
                };
                // 0xfb : EI
                case 0xfb:
                {
                    // EI doesn't actually take effect until after the next instruction.
                    do_delayed_ei = true;
                    break;
                };
                // 0xfc : CALL M, nn
                case 0xfc:
                {
                    do_conditional_call(!!flags.S);
                    break;
                };
                // 0xfd : FD Prefix (IY instructions)
/* @TODO
                case 0xfd:
                {
                    // R is incremented at the start of the second instruction cycle,
                    //  before the instruction actually runs.
                    // The high bit of R is not affected by this increment,
                    //  it can only be changed using the LD R, A instruction.
                    r = (r & 0x80) | (((r & 0x7f) + 1) & 0x7f);

                    pc = (pc + 1) & 0xffff;
                    int opcode = mem_read(pc),
                    func = dd_instructions[opcode];

                    if (func)
                    {
                        // Rather than copy and paste all the IX instructions into IY instructions,
                        //  what we'll do is sneakily copy IY into IX, run the IX instruction,
                        //  and then copy the result into IY and restore the old IX.
                        int temp = ix;
                        ix = iy;
                        //func = func.bind(this);
                        func();
                        iy = ix;
                        ix = temp;

                        cycle_counter += cycle_counts_dd[opcode];
                    }
                    else
                    {
                        // Apparently if an FD opcode doesn't exist,
                        //  it gets treated as an unprefixed opcode.
                        // What we'll do to handle that is just back up the
                        //  program counter, so that this byte gets decoded
                        //  as a normal instruction.
                        pc = (pc - 1) & 0xffff;
                        // And we'll add in the cycle count for a NOP.
                        cycle_counter += cycle_counts[0];
                    }
                    break;
                };
*/
                // 0xfe : CP n
                case 0xfe:
                {
                    pc = (pc + 1) & 0xffff;
                    do_cp(mem_read(pc));
                    break;
                };
                // 0xff : RST 38h
                case 0xff:
                {
                    do_reset(0x38);
                    break;
                };
            }
        }

        // Update the cycle counter with however many cycles
        //  the base instruction took.
        // If this was a prefixed instruction, then
        //  the prefix handler has added its extra cycles already.

        cycle_counter += cycle_counts[opcode];
    }

    ///////////////////////////////////////////////////////////////////////////////
    /// This table of ED opcodes is pretty sparse;
    ///  there are not very many valid ED-prefixed opcodes in the Z80,
    ///  and many of the ones that are valid are not documented.
    ///////////////////////////////////////////////////////////////////////////////

    // Исполнение инструкции EDh
    int ed_instructions(int opcode) {

        switch (opcode) {

            // 0x40 : IN B, (C)
            case 0x40:
            {
                b = do_in((b << 8) | c);
                return 1;
            };
            // 0x41 : OUT (C), B
            case 0x41:
            {
                io_write((b << 8) | c, b);
                return 1;
            };
            // 0x42 : SBC HL, BC
            case 0x42:
            {
                do_hl_sbc(c | (b << 8));
                return 1;
            };
            // 0x43 : LD (nn), BC
            case 0x43:
            {
                pc = (pc + 1) & 0xffff;
                int address = mem_read(pc);
                pc = (pc + 1) & 0xffff;
                address |= mem_read(pc) << 8;

                mem_write(address, c);
                mem_write((address + 1) & 0xffff, b);
                return 1;
            };
            // 0x44 : NEG
            case 0x44:
            {
                do_neg();
                return 1;
            };
            // 0x45 : RETN
            case 0x45:
            {
                pc = (pop_word() - 1) & 0xffff;
                iff1 = iff2;
                return 1;
            };
            // 0x46 : IM 0
            case 0x46:
            {
                imode = 0;
                return 1;
            };
            // 0x47 : LD I, A
            case 0x47:
            {
                i = a;
                return 1;
            };
            // 0x48 : IN C, (C)
            case 0x48:
            {
                c = do_in((b << 8) | c);
                return 1;
            };
            // 0x49 : OUT (C), C
            case 0x49:
            {
                io_write((b << 8) | c, c);
                return 1;
            };
            // 0x4a : ADC HL, BC
            case 0x4a:
            {
                do_hl_adc(c | (b << 8));
                return 1;
            };
            // 0x4b : LD BC, (nn)
            case 0x4b:
            {
                pc = (pc + 1) & 0xffff;
                int address = mem_read(pc);
                pc = (pc + 1) & 0xffff;
                address |= mem_read(pc) << 8;

                c = mem_read(address);
                b = mem_read((address + 1) & 0xffff);
                return 1;
            };
            // 0x4c : NEG (Undocumented)
            case 0x4c:
            {
                do_neg();
                return 1;
            };
            // 0x4d : RETI
            case 0x4d:
            {
                pc = (pop_word() - 1) & 0xffff;
                return 1;
            };
            // 0x4e : IM 0 (Undocumented)
            case 0x4e:
            {
                imode = 0;
                return 1;
            };
            // 0x4f : LD R, A
            case 0x4f:
            {
                r = a;
                return 1;
            };
            // 0x50 : IN D, (C)
            case 0x50:
            {
                d = do_in((b << 8) | c);
                return 1;
            };
            // 0x51 : OUT (C), D
            case 0x51:
            {
                io_write((b << 8) | c, d);
                return 1;
            };
            // 0x52 : SBC HL, DE
            case 0x52:
            {
                do_hl_sbc(e | (d << 8));
                return 1;
            };
            // 0x53 : LD (nn), DE
            case 0x53:
            {
                pc = (pc + 1) & 0xffff;
                int address = mem_read(pc);
                pc = (pc + 1) & 0xffff;
                address |= mem_read(pc) << 8;

                mem_write(address, e);
                mem_write((address + 1) & 0xffff, d);
                return 1;
            };
            // 0x54 : NEG (Undocumented)
            case 0x54:
            {
                do_neg();
                return 1;
            };
            // 0x55 : RETN
            case 0x55:
            {
                pc = (pop_word() - 1) & 0xffff;
                iff1 = iff2;
                return 1;
            };
            // 0x56 : IM 1
            case 0x56:
            {
                imode = 1;
                return 1;
            };
            // 0x57 : LD A, I
            case 0x57:
            {
                a = i;
                flags.S = a & 0x80 ? 1 : 0;
                flags.Z = a ? 0 : 1;
                flags.H = 0;
                flags.P = iff2;
                flags.N = 0;
                update_xy_flags(a);
                return 1;
            };
            // 0x58 : IN E, (C)
            case 0x58:
            {
                e = do_in((b << 8) | c);
                return 1;
            };
            // 0x59 : OUT (C), E
            case 0x59:
            {
                io_write((b << 8) | c, e);
                return 1;
            };
            // 0x5a : ADC HL, DE
            case 0x5a:
            {
                do_hl_adc(e | (d << 8));
                return 1;
            };
            // 0x5b : LD DE, (nn)
            case 0x5b:
            {
                pc = (pc + 1) & 0xffff;
                int address = mem_read(pc);
                pc = (pc + 1) & 0xffff;
                address |= mem_read(pc) << 8;

                e = mem_read(address);
                d = mem_read((address + 1) & 0xffff);
                return 1;
            };
            // 0x5c : NEG (Undocumented)
            case 0x5c:
            {
                do_neg();
                return 1;
            };
            // 0x5d : RETN
            case 0x5d:
            {
                pc = (pop_word() - 1) & 0xffff;
                iff1 = iff2;
                return 1;
            };
            // 0x5e : IM 2
            case 0x5e:
            {
                imode = 2;
                return 1;
            };
            // 0x5f : LD A, R
            case 0x5f:
            {
                a = r;
                flags.S = a & 0x80 ? 1 : 0;
                flags.Z = a ? 0 : 1;
                flags.H = 0;
                flags.P = iff2;
                flags.N = 0;
                update_xy_flags(a);
                return 1;
            };
            // 0x60 : IN H, (C)
            case 0x60:
            {
                h = do_in((b << 8) | c);
                return 1;
            };
            // 0x61 : OUT (C), H
            case 0x61:
            {
                io_write((b << 8) | c, h);
                return 1;
            };
            // 0x62 : SBC HL, HL
            case 0x62:
            {
                do_hl_sbc(l | (h << 8));
                return 1;
            };
            // 0x63 : LD (nn), HL (Undocumented)
            case 0x63:
            {
                pc = (pc + 1) & 0xffff;
                int address = mem_read(pc);
                pc = (pc + 1) & 0xffff;
                address |= mem_read(pc) << 8;

                mem_write(address, l);
                mem_write((address + 1) & 0xffff, h);
                return 1;
            };
            // 0x64 : NEG (Undocumented)
            case 0x64:
            {
                do_neg();
                return 1;
            };
            // 0x65 : RETN
            case 0x65:
            {
                pc = (pop_word() - 1) & 0xffff;
                iff1 = iff2;
                return 1;
            };
            // 0x66 : IM 0
            case 0x66:
            {
                imode = 0;
                return 1;
            };
            // 0x67 : RRD
            case 0x67:
            {
                int hl_value = mem_read(l | (h << 8));
                int temp1 = hl_value & 0x0f,
                    temp2 = a & 0x0f;

                hl_value = ((hl_value & 0xf0) >> 4) | (temp2 << 4);
                a = (a & 0xf0) | temp1;
                mem_write(l | (h << 8), hl_value);

                flags.S = (a & 0x80) ? 1 : 0;
                flags.Z = a ? 0 : 1;
                flags.H = 0;
                flags.P = get_parity(a) ? 1 : 0;
                flags.N = 0;
                update_xy_flags(a);
                return 1;
            };
            // 0x68 : IN L, (C)
            case 0x68:
            {
                l = do_in((b << 8) | c);
                return 1;
            };
            // 0x69 : OUT (C), L
            case 0x69:
            {
                io_write((b << 8) | c, l);
                return 1;
            };
            // 0x6a : ADC HL, HL
            case 0x6a:
            {
                do_hl_adc(l | (h << 8));
                return 1;
            };
            // 0x6b : LD HL, (nn) (Undocumented)
            case 0x6b:
            {
                pc = (pc + 1) & 0xffff;
                int address = mem_read(pc);
                pc = (pc + 1) & 0xffff;
                address |= mem_read(pc) << 8;

                l = mem_read(address);
                h = mem_read((address + 1) & 0xffff);
                return 1;
            };
            // 0x6c : NEG (Undocumented)
            case 0x6c:
            {
                do_neg();
                return 1;
            };
            // 0x6d : RETN
            case 0x6d:
            {
                pc = (pop_word() - 1) & 0xffff;
                iff1 = iff2;
                return 1;
            };
            // 0x6e : IM 0 (Undocumented)
            case 0x6e:
            {
                imode = 0;
                return 1;
            };
            // 0x6f : RLD
            case 0x6f:
            {
                int hl_value = mem_read(l | (h << 8));
                int temp1 = hl_value & 0xf0, temp2 = a & 0x0f;
                hl_value = ((hl_value & 0x0f) << 4) | temp2;
                a = (a & 0xf0) | (temp1 >> 4);
                mem_write(l | (h << 8), hl_value);

                flags.S = (a & 0x80) ? 1 : 0;
                flags.Z = a ? 0 : 1;
                flags.H = 0;
                flags.P = get_parity(a) ? 1 : 0;
                flags.N = 0;
                update_xy_flags(a);
                return 1;
            };
            // 0x70 : IN (C) (Undocumented)
            case 0x70:
            {
                do_in((b << 8) | c);
                return 1;
            };
            // 0x71 : OUT (C), 0 (Undocumented)
            case 0x71:
            {
                io_write((b << 8) | c, 0);
                return 1;
            };
            // 0x72 : SBC HL, SP
            case 0x72:
            {
                do_hl_sbc(sp);
                return 1;
            };
            // 0x73 : LD (nn), SP
            case 0x73:
            {
                pc = (pc + 1) & 0xffff;
                int address = mem_read(pc);
                pc = (pc + 1) & 0xffff;
                address |= mem_read(pc) << 8;

                mem_write(address, sp & 0xff);
                mem_write((address + 1) & 0xffff, (sp >> 8) & 0xff);
                return 1;
            };
            // 0x74 : NEG (Undocumented)
            case 0x74:
            {
                do_neg();
                return 1;
            };
            // 0x75 : RETN
            case 0x75:
            {
                pc = (pop_word() - 1) & 0xffff;
                iff1 = iff2;
                return 1;
            };
            // 0x76 : IM 1
            case 0x76:
            {
                imode = 1;
                return 1;
            };
            // 0x78 : IN A, (C)
            case 0x78:
            {
                a = do_in((b << 8) | c);
                return 1;
            };
            // 0x79 : OUT (C), A
            case 0x79:
            {
                io_write((b << 8) | c, a);
                return 1;
            };
            // 0x7a : ADC HL, SP
            case 0x7a:
            {
                do_hl_adc(sp);
                return 1;
            };
            // 0x7b : LD SP, (nn)
            case 0x7b:
            {
                pc = (pc + 1) & 0xffff;
                int address = mem_read(pc);
                pc = (pc + 1) & 0xffff;
                address |= mem_read(pc) << 8;

                sp  = mem_read(address);
                sp |= mem_read((address + 1) & 0xffff) << 8;
                return 1;
            };
            // 0x7c : NEG (Undocumented)
            case 0x7c:
            {
                do_neg();
                return 1;
            };
            // 0x7d : RETN
            case 0x7d:
            {
                pc = (pop_word() - 1) & 0xffff;
                iff1 = iff2;
                return 1;
            };
            // 0x7e : IM 2
            case 0x7e:
            {
                imode = 2;
                return 1;
            };
            // 0xa0 : LDI
            case 0xa0:
            {
                do_ldi();
                return 1;
            };
            // 0xa1 : CPI
            case 0xa1:
            {
                do_cpi();
                return 1;
            };
            // 0xa2 : INI
            case 0xa2:
            {
                do_ini();
                return 1;
            };
            // 0xa3 : OUTI
            case 0xa3:
            {
                do_outi();
                return 1;
            };
            // 0xa8 : LDD
            case 0xa8:
            {
                do_ldd();
                return 1;
            };
            // 0xa9 : CPD
            case 0xa9:
            {
                do_cpd();
                return 1;
            };
            // 0xaa : IND
            case 0xaa:
            {
                do_ind();
                return 1;
            };
            // 0xab : OUTD
            case 0xab:
            {
                do_outd();
                return 1;
            };
            // 0xb0 : LDIR
            case 0xb0:
            {
                do_ldi();
                if (b || c)
                {
                    cycle_counter += 5;
                    pc = (pc - 2) & 0xffff;
                }
                return 1;
            };
            // 0xb1 : CPIR
            case 0xb1:
            {
                do_cpi();
                if (!flags.Z && (b || c))
                {
                    cycle_counter += 5;
                    pc = (pc - 2) & 0xffff;
                }
                return 1;
            };
            // 0xb2 : INIR
            case 0xb2:
            {
                do_ini();
                if (b)
                {
                    cycle_counter += 5;
                    pc = (pc - 2) & 0xffff;
                }
                return 1;
            };
            // 0xb3 : OTIR
            case 0xb3:
            {
                do_outi();
                if (b)
                {
                    cycle_counter += 5;
                    pc = (pc - 2) & 0xffff;
                }
                return 1;
            };
            // 0xb8 : LDDR
            case 0xb8:
            {
                do_ldd();
                if (b || c)
                {
                    cycle_counter += 5;
                    pc = (pc - 2) & 0xffff;
                }
                return 1;
            };
            // 0xb9 : CPDR
            case 0xb9:
            {
                do_cpd();
                if (!flags.Z && (b || c))
                {
                    cycle_counter += 5;
                    pc = (pc - 2) & 0xffff;
                }
                return 1;
            };
            // 0xba : INDR
            case 0xba:
            {
                do_ind();
                if (b)
                {
                    cycle_counter += 5;
                    pc = (pc - 2) & 0xffff;
                }
                return 1;
            };
            // 0xbb : OTDR
            case 0xbb:
            {
                do_outd();
                if (b)
                {
                    cycle_counter += 5;
                    pc = (pc - 2) & 0xffff;
                }
                return 1;
            };
        }

        return 0;
    }

    ///////////////////////////////////////////////////////////////////////////////
    /// Like ED, this table is quite sparse,
    ///  and many of the opcodes here are also undocumented.
    /// The undocumented instructions here are those that deal with only one byte
    ///  of the two-byte IX register; the bytes are designed IXH and IXL here.
    ///////////////////////////////////////////////////////////////////////////////

    // Исполнение инструкции DDh
    void dd_instructions(int opcode) {
    }

    // -----------------------------------------------------------------

    // Pretty obvious what this function does; given a 16-bit value,
    //  decrement the stack pointer, write the high byte to the new
    //  stack pointer location, then repeat for the low byte.
    void push_word(int operand)
    {
        sp = (sp - 1) & 0xffff;
        mem_write(sp, (operand & 0xff00) >> 8);

        sp = (sp - 1) & 0xffff;
        mem_write(sp, operand & 0x00ff);
    }

    // Again, not complicated; read a byte off the top of the stack,
    //  increment the stack pointer, rinse and repeat.
    int pop_word()
    {
        int retval = mem_read(sp) & 0xff;
        sp = (sp + 1) & 0xffff;

        retval |= mem_read(sp) << 8;
        sp = (sp + 1) & 0xffff;
        return retval;
    };

    // We could try to actually calculate the parity every time,
    //  but why calculate what you can pre-calculate?
    int get_parity(int value) { return parity_bits[value & 0xff]; };

    // Most of the time, the undocumented flags
    //  (sometimes called X and Y, or 3 and 5),
    //  take their values from the corresponding bits
    //  of the result of the instruction,
    //  or from some other related value.
    // This is a utility function to set those flags based on those bits.
    void update_xy_flags(int result)
    {
        flags.Y = (result & 0x20) >> 5;
        flags.X = (result & 0x08) >> 3;
    };

    int get_signed_offset_byte(int value)
    {
        // This function requires some explanation.
        // We just use JavaScript Number variables for our registers,
        //  not like a typed array or anything.
        // That means that, when we have a byte value that's supposed
        //  to represent a signed offset, the value we actually see
        //  isn't signed at all, it's just a small integer.
        // So, this function converts that byte into something JavaScript
        //  will recognize as signed, so we can easily do arithmetic with it.
        // First, we clamp the value to a single byte, just in case.
        value &= 0xff;

        // We don't have to do anything if the value is positive.
        if (value & 0x80)
        {
            // But if the value is negative, we need to manually un-two's-compliment it.
            // I'm going to assume you can figure out what I meant by that,
            //  because I don't know how else to explain it.
            // We could also just do value |= 0xffffff00, but I prefer
            //  not caring how many bits are in the integer representation
            //  of a JavaScript number in the currently running browser.
            //  value = -((0xff & ~value) + 1);
            value -= 256;
        }

        return value;
    };

    // We need the whole F register for some reason.
    //  probably a PUSH AF instruction,
    //  so make the F register out of our separate flags.
    int get_flags_register()
    {
        return  (flags.S << 7) |
                (flags.Z << 6) |
                (flags.Y << 5) |
                (flags.H << 4) |
                (flags.X << 3) |
                (flags.P << 2) |
                (flags.N << 1) |
                (flags.C);
    };

    // This is the same as the above for the F' register.
    int get_flags_prime()
    {
        return  (flags_prime.S << 7) |
                (flags_prime.Z << 6) |
                (flags_prime.Y << 5) |
                (flags_prime.H << 4) |
                (flags_prime.X << 3) |
                (flags_prime.P << 2) |
                (flags_prime.N << 1) |
                (flags_prime.C);
    };

    // We need to set the F register, probably for a POP AF,
    //  so break out the given value into our separate flags.
    void set_flags_register(int operand)
    {
        flags.S = (operand & 0x80) >> 7;
        flags.Z = (operand & 0x40) >> 6;
        flags.Y = (operand & 0x20) >> 5;
        flags.H = (operand & 0x10) >> 4;
        flags.X = (operand & 0x08) >> 3;
        flags.P = (operand & 0x04) >> 2;
        flags.N = (operand & 0x02) >> 1;
        flags.C = (operand & 0x01);
    };

    // Again, this is the same as the above for F'.
    void set_flags_prime(int operand)
    {
        flags_prime.S = (operand & 0x80) >> 7;
        flags_prime.Z = (operand & 0x40) >> 6;
        flags_prime.Y = (operand & 0x20) >> 5;
        flags_prime.H = (operand & 0x10) >> 4;
        flags_prime.X = (operand & 0x08) >> 3;
        flags_prime.P = (operand & 0x04) >> 2;
        flags_prime.N = (operand & 0x02) >> 1;
        flags_prime.C = (operand & 0x01);
    };

    ///////////////////////////////////////////////////////////////////////////////
    /// Now, the way most instructions work in this emulator is that they set up
    ///  their operands according to their addressing mode, and then they call a
    ///  utility function that handles all variations of that instruction.
    /// Those utility functions begin here.
    ///////////////////////////////////////////////////////////////////////////////
    void do_conditional_absolute_jump(int condition)
    {
        // This function implements the JP [condition],nn instructions.
        if (condition)
        {
            // We're taking this jump, so write the new PC,
            //  and then decrement the thing we just wrote,
            //  because the instruction decoder increments the PC
            //  unconditionally at the end of every instruction
            //  and we need to counteract that so we end up at the jump target.
            pc =  mem_read((pc + 1) & 0xffff) |
                 (mem_read((pc + 2) & 0xffff) << 8);
            pc = (pc - 1) & 0xffff;
        }
        else
        {
            // We're not taking this jump, just move the PC past the operand.
            pc = (pc + 2) & 0xffff;
        }
    };

    void do_conditional_relative_jump(int condition)
    {
        // This function implements the JR [condition],n instructions.
        if (condition)
        {
            // We need a few more cycles to actually take the jump.
            cycle_counter += 5;

            // Calculate the offset specified by our operand.
            int offset = get_signed_offset_byte(mem_read((pc + 1) & 0xffff));

            // Add the offset to the PC, also skipping past this instruction.
            pc = (pc + offset + 1) & 0xffff;
        }
        else
        {
            // No jump happening, just skip the operand.
            pc = (pc + 1) & 0xffff;
        }
    };

    // This function is the CALL [condition],nn instructions.
    // If you've seen the previous functions, you know this drill.
    void do_conditional_call(int condition)
    {
        if (condition)
        {
            cycle_counter += 7;
            push_word((pc + 3) & 0xffff);
            pc = mem_read((pc + 1) & 0xffff) |
                (mem_read((pc + 2) & 0xffff) << 8);
            pc = (pc - 1) & 0xffff;
        }
        else
        {
            pc = (pc + 2) & 0xffff;
        }
    };

    void do_conditional_return(int condition)
    {
        if (condition)
        {
            cycle_counter += 6;
            pc = (pop_word() - 1) & 0xffff;
        }
    };

    // The RST [address] instructions go through here.
    void do_reset(int address)
    {
        push_word((pc + 1) & 0xffff);
        pc = (address - 1) & 0xffff;
    };

    // This is the ADD A, [operand] instructions.
    // We'll do the literal addition, which includes any overflow,
    //  so that we can more easily figure out whether we had
    //  an overflow or a carry and set the flags accordingly.
    void do_add(int operand)
    {
        int result = a + operand;

        // The great majority of the work for the arithmetic instructions
        //  turns out to be setting the flags rather than the actual operation.
        flags.S = (result & 0x80) ? 1 : 0;
        flags.Z = !(result & 0xff) ? 1 : 0;
        flags.H = (((operand & 0x0f) + (a & 0x0f)) & 0x10) ? 1 : 0;

        // An overflow has happened if the sign bits of the accumulator and the operand
        //  don't match the sign bit of the result value.
        flags.P = ((a & 0x80) == (operand & 0x80)) && ((a & 0x80) != (result & 0x80)) ? 1 : 0;
        flags.N = 0;
        flags.C = (result & 0x100) ? 1 : 0;

        a = result & 0xff;
        update_xy_flags(a);
    }

    void do_adc(int operand)
    {
        int result = a + operand + flags.C;

        flags.S = (result & 0x80) ? 1 : 0;
        flags.Z = !(result & 0xff) ? 1 : 0;
        flags.H = (((operand & 0x0f) + (a & 0x0f) + flags.C) & 0x10) ? 1 : 0;
        flags.P = ((a & 0x80) == (operand & 0x80)) && ((a & 0x80) != (result & 0x80)) ? 1 : 0;
        flags.N = 0;
        flags.C = (result & 0x100) ? 1 : 0;

        a = result & 0xff;
        update_xy_flags(a);
    }

    void do_sub(int operand)
    {
        int result = a - operand;

        flags.S = (result & 0x80) ? 1 : 0;
        flags.Z = !(result & 0xff) ? 1 : 0;
        flags.H = (((a & 0x0f) - (operand & 0x0f)) & 0x10) ? 1 : 0;
        flags.P = ((a & 0x80) != (operand & 0x80)) && ((a & 0x80) != (result & 0x80)) ? 1 : 0;
        flags.N = 1;
        flags.C = (result & 0x100) ? 1 : 0;

        a = result & 0xff;
        update_xy_flags(a);
    }

    void do_sbc(int operand)
    {
        int result = a - operand - flags.C;

        flags.S = (result & 0x80) ? 1 : 0;
        flags.Z = !(result & 0xff) ? 1 : 0;
        flags.H = (((a & 0x0f) - (operand & 0x0f) - flags.C) & 0x10) ? 1 : 0;
        flags.P = ((a & 0x80) != (operand & 0x80)) && ((a & 0x80) != (result & 0x80)) ? 1 : 0;
        flags.N = 1;
        flags.C = (result & 0x100) ? 1 : 0;

        a = result & 0xff;
        update_xy_flags(a);
    }

    void do_cp(int operand)
    {
        // A compare instruction is just a subtraction that doesn't save the value,
        //  so we implement it as... a subtraction that doesn't save the value.
        int temp = a;
        do_sub(operand);
        a = temp;
        // Since this instruction has no "result" value, the undocumented flags
        //  are set based on the operand instead.
        update_xy_flags(operand);
    }

    // The logic instructions are all pretty straightforward.
    void do_and(int operand)
    {
        a &= operand & 0xff;
        flags.S = (a & 0x80) ? 1 : 0;
        flags.Z = !a ? 1 : 0;
        flags.H = 1;
        flags.P = get_parity(a);
        flags.N = 0;
        flags.C = 0;
        update_xy_flags(a);
    }

    void do_or(int operand)
    {
        a = (operand | a) & 0xff;
        flags.S = (a & 0x80) ? 1 : 0;
        flags.Z = !a ? 1 : 0;
        flags.H = 0;
        flags.P = get_parity(a);
        flags.N = 0;
        flags.C = 0;
        update_xy_flags(a);
    }

    void do_xor(int operand)
    {
        a = (operand ^ a) & 0xff;
        flags.S = (a & 0x80) ? 1 : 0;
        flags.Z = !a ? 1 : 0;
        flags.H = 0;
        flags.P = get_parity(a);
        flags.N = 0;
        flags.C = 0;
        update_xy_flags(a);
    }

    int do_inc(int operand)
    {
        int result = operand + 1;

        flags.S = (result & 0x80) ? 1 : 0;
        flags.Z = !(result & 0xff) ? 1 : 0;
        flags.H = ((operand & 0x0f) == 0x0f) ? 1 : 0;
        // It's a good deal easier to detect overflow for an increment/decrement.
        flags.P = (operand == 0x7f) ? 1 : 0;
        flags.N = 0;

        result &= 0xff;
        update_xy_flags(result);

        return result;
    }

    int do_dec(int operand)
    {
        int result = operand - 1;

        flags.S = (result & 0x80) ? 1 : 0;
        flags.Z = !(result & 0xff) ? 1 : 0;
        flags.H = ((operand & 0x0f) == 0x00) ? 1 : 0;
        flags.P = (operand == 0x80) ? 1 : 0;
        flags.N = 1;

        result &= 0xff;
        update_xy_flags(result);

        return result;
    }

    // The HL arithmetic instructions are the same as the A ones,
    //  just with twice as many bits happening.
    void do_hl_add(int operand)
    {
        int hl = l | (h << 8);
        int result = hl + operand;

        flags.N = 0;
        flags.C = (result & 0x10000) ? 1 : 0;
        flags.H = (((hl & 0x0fff) + (operand & 0x0fff)) & 0x1000) ? 1 : 0;

        l = result & 0xff;
        h = (result & 0xff00) >> 8;

        update_xy_flags(h);
    };

    void do_hl_adc(int operand)
    {
        operand += flags.C;
        int hl = l | (h << 8);
        int result = hl + operand;

        flags.S = (result & 0x8000) ? 1 : 0;
        flags.Z = !(result & 0xffff) ? 1 : 0;
        flags.H = (((hl & 0x0fff) + (operand & 0x0fff)) & 0x1000) ? 1 : 0;
        flags.P = ((hl & 0x8000) == (operand & 0x8000)) && ((result & 0x8000) != (hl & 0x8000)) ? 1 : 0;
        flags.N = 0;
        flags.C = (result & 0x10000) ? 1 : 0;

        l = result & 0xff;
        h = (result >> 8) & 0xff;

        update_xy_flags(h);
    };

    void do_hl_sbc(int operand)
    {
        operand += flags.C;
        int hl = l | (h << 8);
        int result = hl - operand;

        flags.S = (result & 0x8000) ? 1 : 0;
        flags.Z = !(result & 0xffff) ? 1 : 0;
        flags.H = (((hl & 0x0fff) - (operand & 0x0fff)) & 0x1000) ? 1 : 0;
        flags.P = ((hl & 0x8000) != (operand & 0x8000)) && ((result & 0x8000) != (hl & 0x8000)) ? 1 : 0;
        flags.N = 1;
        flags.C = (result & 0x10000) ? 1 : 0;

        l = result & 0xff;
        h = (result >> 8) & 0xff;

        update_xy_flags(h);
    };

    int do_in(int port)
    {
        int result = io_read(port);

        flags.S = (result & 0x80) ? 1 : 0;
        flags.Z = result ? 0 : 1;
        flags.H = 0;
        flags.P = get_parity(result) ? 1 : 0;
        flags.N = 0;
        update_xy_flags(result);

        return result;
    };

    void do_neg()
    {
        // This instruction is defined to not alter the register if it == 0x80.
        if (a != 0x80)
        {
            // This is a signed operation, so convert A to a signed value.
            a = get_signed_offset_byte(a);
            a = (-a) & 0xff;
        }

        flags.S = (a & 0x80) ? 1 : 0;
        flags.Z = !a ? 1 : 0;
        flags.H = (((-a) & 0x0f) > 0) ? 1 : 0;
        flags.P = (a == 0x80) ? 1 : 0;
        flags.N = 1;
        flags.C = a ? 1 : 0;
        update_xy_flags(a);
    };

    void do_ldi()
    {
        // Copy the value that we're supposed to copy.
        int read_value = mem_read(l | (h << 8));
        mem_write(e | (d << 8), read_value);

        // Increment DE and HL, and decrement BC.
        int result = (e | (d << 8)) + 1;
        e = result & 0xff;
        d = (result & 0xff00) >> 8;
        result = (l | (h << 8)) + 1;

        l = result & 0xff;
        h = (result & 0xff00) >> 8;
        result = (c | (b << 8)) - 1;

        c = result & 0xff;
        b = (result & 0xff00) >> 8;

        flags.H = 0;
        flags.P = (c || b) ? 1 : 0;
        flags.N = 0;
        flags.Y = ((a + read_value) & 0x02) >> 1;
        flags.X = ((a + read_value) & 0x08) >> 3;
    };

    void do_cpi()
    {
        int temp_carry = flags.C;
        int read_value = mem_read(l | (h << 8));
        do_cp(read_value);

        flags.C = temp_carry;
        flags.Y = ((a - read_value - flags.H) & 0x02) >> 1;
        flags.X = ((a - read_value - flags.H) & 0x08) >> 3;

        int result = (l | (h << 8)) + 1;
        l = result & 0xff;
        h = (result & 0xff00) >> 8;

        result = (c | (b << 8)) - 1;
        c = result & 0xff;
        b = (result & 0xff00) >> 8;

        flags.P = result ? 1 : 0;
    };

    void do_ini()
    {
        b = do_dec(b);

        mem_write(l | (h << 8), io_read((b << 8) | c));

        int result = (l | (h << 8)) + 1;
        l = result & 0xff;
        h = (result & 0xff00) >> 8;

        flags.N = 1;
    };

    void do_outi()
    {
        io_write((b << 8) | c, mem_read(l | (h << 8)));

        int result = (l | (h << 8)) + 1;
        l = result & 0xff;
        h = (result & 0xff00) >> 8;

        b = do_dec(b);
        flags.N = 1;
    };

    void do_ldd()
    {
        flags.N = 0;
        flags.H = 0;

        int read_value = mem_read(l | (h << 8));
        mem_write(e | (d << 8), read_value);

        int result = (e | (d << 8)) - 1;
        e = result & 0xff;
        d = (result & 0xff00) >> 8;
        result = (l | (h << 8)) - 1;

        l = result & 0xff;
        h = (result & 0xff00) >> 8;
        result = (c | (b << 8)) - 1;

        c = result & 0xff;
        b = (result & 0xff00) >> 8;

        flags.P = (c || b) ? 1 : 0;
        flags.Y = ((a + read_value) & 0x02) >> 1;
        flags.X = ((a + read_value) & 0x08) >> 3;
    };

    void do_cpd()
    {
        int temp_carry = flags.C;
        int read_value = mem_read(l | (h << 8));

        do_cp(read_value);
        flags.C = temp_carry;
        flags.Y = ((a - read_value - flags.H) & 0x02) >> 1;
        flags.X = ((a - read_value - flags.H) & 0x08) >> 3;

        int result = (l | (h << 8)) - 1;
        l = result & 0xff;
        h = (result & 0xff00) >> 8;

        result = (c | (b << 8)) - 1;
        c = result & 0xff;
        b = (result & 0xff00) >> 8;

        flags.P = result ? 1 : 0;
    };

    void do_ind()
    {
        b = do_dec(b);

        mem_write(l | (h << 8), io_read((b << 8) | c));

        int result = (l | (h << 8)) - 1;
        l = result & 0xff;
        h = (result & 0xff00) >> 8;

        flags.N = 1;
    };

    void do_outd()
    {
        io_write((b << 8) | c, mem_read(l | (h << 8)));

        int result = (l | (h << 8)) - 1;
        l = result & 0xff;
        h = (result & 0xff00) >> 8;

        b = do_dec(b);
        flags.N = 1;
    };

    int do_rlc(int operand)
    {
        flags.N = 0;
        flags.H = 0;

        flags.C = (operand & 0x80) >> 7;
        operand = ((operand << 1) | flags.C) & 0xff;

        flags.Z = !operand ? 1 : 0;
        flags.P = get_parity(operand);
        flags.S = (operand & 0x80) ? 1 : 0;
        update_xy_flags(operand);

        return operand;
    };

    int do_rrc(int operand)
    {
        flags.N = 0;
        flags.H = 0;

        flags.C = operand & 1;
        operand = ((operand >> 1) & 0x7f) | (flags.C << 7);

        flags.Z = !(operand & 0xff) ? 1 : 0;
        flags.P = get_parity(operand);
        flags.S = (operand & 0x80) ? 1 : 0;
        update_xy_flags(operand);

        return operand & 0xff;
    };

    int do_rl(int operand)
    {
        flags.N = 0;
        flags.H = 0;

        int temp = flags.C;
        flags.C = (operand & 0x80) >> 7;
        operand = ((operand << 1) | temp) & 0xff;

        flags.Z = !operand ? 1 : 0;
        flags.P = get_parity(operand);
        flags.S = (operand & 0x80) ? 1 : 0;
        update_xy_flags(operand);

        return operand;
    };

    int do_rr(int operand)
    {
        flags.N = 0;
        flags.H = 0;

        int temp = flags.C;
        flags.C = operand & 1;
        operand = ((operand >> 1) & 0x7f) | (temp << 7);

        flags.Z = !operand ? 1 : 0;
        flags.P = get_parity(operand);
        flags.S = (operand & 0x80) ? 1 : 0;
        update_xy_flags(operand);

        return operand;
    };

    int do_sla(int operand)
    {
        flags.N = 0;
        flags.H = 0;

        flags.C = (operand & 0x80) >> 7;
        operand = (operand << 1) & 0xff;

        flags.Z = !operand ? 1 : 0;
        flags.P = get_parity(operand);
        flags.S = (operand & 0x80) ? 1 : 0;
        update_xy_flags(operand);

        return operand;
    };

    int do_sra(int operand)
    {
        flags.N = 0;
        flags.H = 0;

        flags.C = operand & 1;
        operand = ((operand >> 1) & 0x7f) | (operand & 0x80);

        flags.Z = !operand ? 1 : 0;
        flags.P = get_parity(operand);
        flags.S = (operand & 0x80) ? 1 : 0;
        update_xy_flags(operand);

        return operand;
    };

    int do_sll(int operand)
    {
        flags.N = 0;
        flags.H = 0;

        flags.C = (operand & 0x80) >> 7;
        operand = ((operand << 1) & 0xff) | 1;

        flags.Z = !operand ? 1 : 0;
        flags.P = get_parity(operand);
        flags.S = (operand & 0x80) ? 1 : 0;
        update_xy_flags(operand);

        return operand;
    };

    int do_srl(int operand)
    {
        flags.N = 0;
        flags.H = 0;

        flags.C = operand & 1;
        operand = (operand >> 1) & 0x7f;

        flags.Z = !operand ? 1 : 0;
        flags.P = get_parity(operand);
        flags.S = 0;
        update_xy_flags(operand);

        return operand;
    };

    void do_ix_add(int operand)
    {
        flags.N = 0;

        int result = ix + operand;

        flags.C = (result & 0x10000) ? 1 : 0;
        flags.H = (((ix & 0xfff) + (operand & 0xfff)) & 0x1000) ? 1 : 0;
        update_xy_flags((result & 0xff00) >> 8);

        ix = result;
    };
};
