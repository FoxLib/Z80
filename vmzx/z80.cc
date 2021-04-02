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

    // @TODO реализовать!
    int mem_read(int address) {
    }

    void mem_write(int address, int value) {
    }

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
            //  before returning it to the emulator core.
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

            /*
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
            */
        }
        else
        {
            // This is one of the less formulaic instructions;
            //  we'll get the specific function for it from our array.
            // @TODO          var func = instructions[opcode];
            // @TODO          func();
        }

        // Update the cycle counter with however many cycles
        //  the base instruction took.
        // If this was a prefixed instruction, then
        //  the prefix handler has added its extra cycles already.

        cycle_counter += cycle_counts[opcode];
    }

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
};
