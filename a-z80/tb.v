`timescale 10ns / 1ns
module tb;
// ---------------------------------------------------------------------
reg clock;
reg clock_25;
reg clock_50;

always #0.5 clock    = ~clock;
always #1.0 clock_50 = ~clock_50;
always #1.5 clock_25 = ~clock_25;

initial begin clock = 1; clock_25 = 0; clock_50 = 0; #2000 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
// ---------------------------------------------------------------------
endmodule

`include "clk_delay.v"
`include "decode_state.v"
`include "execute.v"
`include "interrupts.v"
`include "ir.v"
`include "pin_control.v"
`include "pla_decode.v"
`include "resets.v"
`include "memory_ifc.v"
`include "sequencer.v"
`include "address_latch.v"
`include "address_mux.v"
`include "bus_control.v"
`include "bus_switch.v"
`include "data_switch.v"
`include "address_pins.v"
`include "data_pins.v"
`include "data_switch_mask.v"
`include "control_pins_n.v"
`include "inc_dec_2bit.v"
`include "inc_dec.v"
`include "alu_prep_daa.v"
`include "alu_control.v"
`include "alu_mux_2.v"
`include "alu_mux_4.v"
`include "alu_mux_8.v"
`include "alu_mux_2z.v"
`include "alu_mux_3z.v"
`include "alu_select.v"
`include "alu_flags.v"
`include "alu_core.v"
`include "alu_slice.v"
`include "alu_shifter_core.v"
`include "alu_bit_select.v"
`include "alu.v"
`include "reg_latch.v"
`include "reg_file.v"
`include "reg_control.v"
// ---------------------------------------------------------------------
`include "z80_top_direct_n.v"
