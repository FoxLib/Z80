/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_PS2                                               *
 * Description:                                                              *
 *      This module communicates with the PS2 core.                          *
 *                                                                           *
 * www.eecg.toronto.edu/~jayar/ece241_08F/AudioVideoCores/ps2/ps2.html       *
 *****************************************************************************/

// https://www.chipverify.com/verilog/verilog-parameters
module ps2keyboard #(parameter INITIALIZE_MOUSE = 0)
(
    // Inputs
    CLOCK_50,
    reset,

    the_command,
    send_command,

    // Bidirectionals
    PS2_CLK,                    // PS2 Clock
    PS2_DAT,                    // PS2 Data

    // Outputs
    command_was_sent,
    error_communication_timed_out,

    received_data,
    received_data_en            // If 1 - new data has been received
);

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input           CLOCK_50;
input           reset;
input    [7:0]  the_command;
input           send_command;

// Bidirectionals
inout           PS2_CLK;
inout           PS2_DAT;

// Outputs
output          command_was_sent;
output          error_communication_timed_out;

output   [7:0]  received_data;
output          received_data_en;

// ---------------------------------------------------------------------
wire     [7:0]  the_command_w;
wire            send_command_w,
                command_was_sent_w,
                error_communication_timed_out_w;

generate

    if (INITIALIZE_MOUSE) begin

        assign the_command_w        = init_done ? the_command : 8'hf4;
        assign send_command_w       = init_done ? send_command : (!command_was_sent_w && !error_communication_timed_out_w);
        assign command_was_sent     = init_done ? command_was_sent_w : 0;
        assign error_communication_timed_out = init_done ? error_communication_timed_out_w : 1;

        reg init_done = 0;

        always @(posedge CLOCK_50)

            if (reset) init_done <= 0;
            else if (command_was_sent_w) init_done <= 1;

    end else
    begin

        assign the_command_w    = the_command;
        assign send_command_w   = send_command;
        assign command_was_sent = command_was_sent_w;
        assign error_communication_timed_out = error_communication_timed_out_w;

    end

endgenerate

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
// states
localparam
    PS2_STATE_0_IDLE                = 3'h0,
    PS2_STATE_1_DATA_IN             = 3'h1,
    PS2_STATE_2_COMMAND_OUT         = 3'h2,
    PS2_STATE_3_END_TRANSFER        = 3'h3,
    PS2_STATE_4_END_DELAYED         = 3'h4;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire    ps2_clk_posedge;
wire    ps2_clk_negedge;
wire    start_receiving_data;
wire    wait_for_incoming_data;

// Internal Registers
reg        [7:0]    idle_counter;

reg                 ps2_clk_reg;
reg                 ps2_data_reg;
reg                 last_ps2_clk;

// State Machine Registers
reg        [2:0]    ns_ps2_transceiver;
reg        [2:0]    s_ps2_transceiver;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

always @(posedge CLOCK_50)
begin

    if (reset == 1'b1)
        s_ps2_transceiver <= PS2_STATE_0_IDLE;
    else
        s_ps2_transceiver <= ns_ps2_transceiver;
end

always @(*)
begin

    // Defaults
    ns_ps2_transceiver = PS2_STATE_0_IDLE;

    case (s_ps2_transceiver)

        /* Ожидание */
        PS2_STATE_0_IDLE:

            begin

                if ((idle_counter == 8'hFF) && (send_command == 1'b1))
                    ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;

                else if ((ps2_data_reg == 1'b0) && (ps2_clk_posedge == 1'b1))
                    ns_ps2_transceiver = PS2_STATE_1_DATA_IN;

                else
                    ns_ps2_transceiver = PS2_STATE_0_IDLE;
            end

        /* Получение данных */
        PS2_STATE_1_DATA_IN:

            begin

                if ((received_data_en == 1'b1)/* && (ps2_clk_posedge == 1'b1)*/)
                    ns_ps2_transceiver = PS2_STATE_0_IDLE;
                else
                    ns_ps2_transceiver = PS2_STATE_1_DATA_IN;
            end

        /* Команда */
        PS2_STATE_2_COMMAND_OUT:

            begin
                if ((command_was_sent == 1'b1) || (error_communication_timed_out == 1'b1))
                     ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
                else ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;
            end

        /* Завершение передачи */
        PS2_STATE_3_END_TRANSFER:

            begin
                if (send_command == 1'b0)
                    ns_ps2_transceiver = PS2_STATE_0_IDLE;

                else if ((ps2_data_reg == 1'b0) && (ps2_clk_posedge == 1'b1))
                    ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;

                else
                    ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
            end

        /* Завершение передачи с задержкой */
        PS2_STATE_4_END_DELAYED:

            begin

                if (received_data_en == 1'b1)
                begin

                    if (send_command == 1'b0)
                        ns_ps2_transceiver = PS2_STATE_0_IDLE;
                    else
                        ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
                end
                else
                    ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;
            end

        /* Все другие статусы */
        default:
            ns_ps2_transceiver = PS2_STATE_0_IDLE;

    endcase
end

/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
begin

    if (reset == 1'b1)
    begin

        last_ps2_clk    <= 1'b1;
        ps2_clk_reg     <= 1'b1;
        ps2_data_reg    <= 1'b1;

    end
    else
    begin

        last_ps2_clk    <= ps2_clk_reg;
        ps2_clk_reg     <= PS2_CLK;
        ps2_data_reg    <= PS2_DAT;

    end
end

always @(posedge CLOCK_50)
begin

    if (reset == 1'b1)
        idle_counter <= 6'h00;

    else if ((s_ps2_transceiver == PS2_STATE_0_IDLE) && (idle_counter != 8'hFF))
        idle_counter <= idle_counter + 6'h01;

    else if (s_ps2_transceiver != PS2_STATE_0_IDLE)
        idle_counter <= 6'h00;
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/

assign ps2_clk_posedge         = ((ps2_clk_reg == 1'b1) && (last_ps2_clk == 1'b0)) ? 1'b1 : 1'b0;
assign ps2_clk_negedge         = ((ps2_clk_reg == 1'b0) && (last_ps2_clk == 1'b1)) ? 1'b1 : 1'b0;
assign start_receiving_data    = (s_ps2_transceiver == PS2_STATE_1_DATA_IN);
assign wait_for_incoming_data  = (s_ps2_transceiver == PS2_STATE_3_END_TRANSFER);

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Altera_UP_PS2_Data_In PS2_Data_In
(
    // Inputs
    .clk                        (CLOCK_50),
    .reset                      (reset),

    .wait_for_incoming_data     (wait_for_incoming_data),
    .start_receiving_data       (start_receiving_data),

    .ps2_clk_posedge            (ps2_clk_posedge),
    .ps2_clk_negedge            (ps2_clk_negedge),
    .ps2_data                   (ps2_data_reg),

    // Bidirectionals Outputs
    .received_data              (received_data),
    .received_data_en           (received_data_en)
);

Altera_UP_PS2_Command_Out PS2_Command_Out (

    // Inputs
    .clk                (CLOCK_50),
    .reset              (reset),
    .the_command        (the_command_w),
    .send_command       (send_command_w),
    .ps2_clk_posedge    (ps2_clk_posedge),
    .ps2_clk_negedge    (ps2_clk_negedge),

    // Bidirectionals
    .PS2_CLK            (PS2_CLK),
    .PS2_DAT            (PS2_DAT),

    // Outputs
    .command_was_sent               (command_was_sent_w),
    .error_communication_timed_out  (error_communication_timed_out_w)
);

endmodule

//*****************************************************************************
//*                                                                           *
//* Module:       Altera_UP_PS2_Command_Out                                   *
//* Description:                                                              *
//*      This module sends commands out to the PS2 core.                      *
//*                                                                           *
//*****************************************************************************/

module Altera_UP_PS2_Command_Out (

    // Inputs
    clk,
    reset,
    the_command,
    send_command,
    ps2_clk_posedge,
    ps2_clk_negedge,

    // Bidirectionals
    PS2_CLK,
    PS2_DAT,

    // Outputs
    command_was_sent,
    error_communication_timed_out
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

// Timing info for initiating Host-to-Device communication
//   when using a 50MHz system clock
parameter    CLOCK_CYCLES_FOR_101US         = 5050;
parameter    NUMBER_OF_BITS_FOR_101US       = 13;
parameter    COUNTER_INCREMENT_FOR_101US    = 13'h0001;

// Timing info for start of transmission error
//   when using a 50MHz system clock
parameter    CLOCK_CYCLES_FOR_15MS          = 750000;
parameter    NUMBER_OF_BITS_FOR_15MS        = 20;
parameter    COUNTER_INCREMENT_FOR_15MS     = 20'h00001;

// Timing info for sending data error
//   when using a 50MHz system clock
parameter    CLOCK_CYCLES_FOR_2MS           = 100000;
parameter    NUMBER_OF_BITS_FOR_2MS         = 17;
parameter    COUNTER_INCREMENT_FOR_2MS      = 17'h00001;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

input           clk;
input           reset;
input   [7:0]   the_command;
input           send_command;
input           ps2_clk_posedge;
input           ps2_clk_negedge;
inout           PS2_CLK;
inout           PS2_DAT;
output  reg     command_was_sent;
output  reg     error_communication_timed_out;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
// states
parameter   PS2_STATE_0_IDLE                        = 3'h0,
            PS2_STATE_1_INITIATE_COMMUNICATION      = 3'h1,
            PS2_STATE_2_WAIT_FOR_CLOCK              = 3'h2,
            PS2_STATE_3_TRANSMIT_DATA               = 3'h3,
            PS2_STATE_4_TRANSMIT_STOP_BIT           = 3'h4,
            PS2_STATE_5_RECEIVE_ACK_BIT             = 3'h5,
            PS2_STATE_6_COMMAND_WAS_SENT            = 3'h6,
            PS2_STATE_7_TRANSMISSION_ERROR          = 3'h7;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

// Internal Registers
reg [3:0]    cur_bit;
reg [8:0]    ps2_command;

reg [NUMBER_OF_BITS_FOR_101US:1]    command_initiate_counter;
reg [NUMBER_OF_BITS_FOR_15MS:1]     waiting_counter;
reg [NUMBER_OF_BITS_FOR_2MS:1]      transfer_counter;

// State Machine Registers
reg [2:0]    ns_ps2_transmitter;
reg [2:0]    s_ps2_transmitter;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

always @(posedge clk)
begin
    if (reset == 1'b1)
        s_ps2_transmitter <= PS2_STATE_0_IDLE;
    else
        s_ps2_transmitter <= ns_ps2_transmitter;
end

always @(*)
begin

    // Defaults
    ns_ps2_transmitter = PS2_STATE_0_IDLE;

    case (s_ps2_transmitter)

        PS2_STATE_0_IDLE:

            begin
                if (send_command == 1'b1)
                    ns_ps2_transmitter = PS2_STATE_1_INITIATE_COMMUNICATION;
                else
                    ns_ps2_transmitter = PS2_STATE_0_IDLE;
            end

        PS2_STATE_1_INITIATE_COMMUNICATION:

            begin
                if (command_initiate_counter == CLOCK_CYCLES_FOR_101US)
                    ns_ps2_transmitter = PS2_STATE_2_WAIT_FOR_CLOCK;
                else
                    ns_ps2_transmitter = PS2_STATE_1_INITIATE_COMMUNICATION;
            end

        PS2_STATE_2_WAIT_FOR_CLOCK:

            begin
                if (ps2_clk_negedge == 1'b1)
                    ns_ps2_transmitter = PS2_STATE_3_TRANSMIT_DATA;
                else if (waiting_counter == CLOCK_CYCLES_FOR_15MS)
                    ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
                else
                    ns_ps2_transmitter = PS2_STATE_2_WAIT_FOR_CLOCK;
            end

        PS2_STATE_3_TRANSMIT_DATA:

            begin
                if ((cur_bit == 4'd8) && (ps2_clk_negedge == 1'b1))
                    ns_ps2_transmitter = PS2_STATE_4_TRANSMIT_STOP_BIT;
                else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
                    ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
                else
                    ns_ps2_transmitter = PS2_STATE_3_TRANSMIT_DATA;
            end

        PS2_STATE_4_TRANSMIT_STOP_BIT:

            begin
                if (ps2_clk_negedge == 1'b1)
                    ns_ps2_transmitter = PS2_STATE_5_RECEIVE_ACK_BIT;
                else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
                    ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
                else
                    ns_ps2_transmitter = PS2_STATE_4_TRANSMIT_STOP_BIT;
            end

        PS2_STATE_5_RECEIVE_ACK_BIT:

            begin
                if (ps2_clk_posedge == 1'b1)
                    ns_ps2_transmitter = PS2_STATE_6_COMMAND_WAS_SENT;
                else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
                    ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
                else
                    ns_ps2_transmitter = PS2_STATE_5_RECEIVE_ACK_BIT;
            end

        PS2_STATE_6_COMMAND_WAS_SENT:

            begin
                if (send_command == 1'b0)
                    ns_ps2_transmitter = PS2_STATE_0_IDLE;
                else
                    ns_ps2_transmitter = PS2_STATE_6_COMMAND_WAS_SENT;
            end

        PS2_STATE_7_TRANSMISSION_ERROR:

            begin
                if (send_command == 1'b0)
                    ns_ps2_transmitter = PS2_STATE_0_IDLE;
                else
                    ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
            end

        default:

            begin
                ns_ps2_transmitter = PS2_STATE_0_IDLE;
            end

    endcase
end

/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

always @(posedge clk)
begin
    if (reset == 1'b1)
        ps2_command <= 9'h000;
    else if (s_ps2_transmitter == PS2_STATE_0_IDLE)
        ps2_command <= {(^the_command) ^ 1'b1, the_command};
end

always @(posedge clk)
begin

    if (reset == 1'b1)
        command_initiate_counter <= {NUMBER_OF_BITS_FOR_101US{1'b0}};

    else if ((s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) &&
            (command_initiate_counter != CLOCK_CYCLES_FOR_101US))
        command_initiate_counter <=
            command_initiate_counter + COUNTER_INCREMENT_FOR_101US;

    else if (s_ps2_transmitter != PS2_STATE_1_INITIATE_COMMUNICATION)
        command_initiate_counter <= {NUMBER_OF_BITS_FOR_101US{1'b0}};
end

always @(posedge clk)
begin
    if (reset == 1'b1)
        waiting_counter <= {NUMBER_OF_BITS_FOR_15MS{1'b0}};

    else if ((s_ps2_transmitter == PS2_STATE_2_WAIT_FOR_CLOCK) &&
            (waiting_counter != CLOCK_CYCLES_FOR_15MS))
        waiting_counter <= waiting_counter + COUNTER_INCREMENT_FOR_15MS;

    else if (s_ps2_transmitter != PS2_STATE_2_WAIT_FOR_CLOCK)
        waiting_counter <= {NUMBER_OF_BITS_FOR_15MS{1'b0}};
end

always @(posedge clk)
begin

    if (reset == 1'b1)
        transfer_counter <= {NUMBER_OF_BITS_FOR_2MS{1'b0}};
    else
    begin

        if ((s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) ||
            (s_ps2_transmitter == PS2_STATE_4_TRANSMIT_STOP_BIT) ||
            (s_ps2_transmitter == PS2_STATE_5_RECEIVE_ACK_BIT))
        begin
            if (transfer_counter != CLOCK_CYCLES_FOR_2MS)
                transfer_counter <= transfer_counter + COUNTER_INCREMENT_FOR_2MS;
        end
        else
            transfer_counter <= {NUMBER_OF_BITS_FOR_2MS{1'b0}};
    end
end

always @(posedge clk)
begin

    if (reset == 1'b1)
        cur_bit <= 4'h0;
    else if ((s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) &&
            (ps2_clk_negedge == 1'b1))
        cur_bit <= cur_bit + 4'h1;
    else if (s_ps2_transmitter != PS2_STATE_3_TRANSMIT_DATA)
        cur_bit <= 4'h0;
end

always @(posedge clk)
begin

    if (reset == 1'b1)
        command_was_sent <= 1'b0;
    else if (s_ps2_transmitter == PS2_STATE_6_COMMAND_WAS_SENT)
        command_was_sent <= 1'b1;
    else if (send_command == 1'b0)
            command_was_sent <= 1'b0;
end

always @(posedge clk)
begin

    if (reset == 1'b1)
        error_communication_timed_out <= 1'b0;
    else if (s_ps2_transmitter == PS2_STATE_7_TRANSMISSION_ERROR)
        error_communication_timed_out <= 1'b1;
    else if (send_command == 1'b0)
        error_communication_timed_out <= 1'b0;
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/

assign PS2_CLK    = (s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) ? 1'b0 : 1'bz;
assign PS2_DAT    = (s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) ? ps2_command[cur_bit] :
                    (s_ps2_transmitter == PS2_STATE_2_WAIT_FOR_CLOCK) ? 1'b0 :
                    ((s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) &&
                    (command_initiate_counter[NUMBER_OF_BITS_FOR_101US] == 1'b1)) ? 1'b0 : 1'bz;

endmodule

/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_PS2_Data_In                                       *
 * Description:                                                              *
 *      This module accepts incoming data from a PS2 core.                   *
 *                                                                           *
 *****************************************************************************/

module Altera_UP_PS2_Data_In (

    // Inputs
    clk,
    reset,
    wait_for_incoming_data,
    start_receiving_data,
    ps2_clk_posedge,
    ps2_clk_negedge,
    ps2_data,

    // Outputs
    received_data,
    received_data_en            // If 1 - new data has been received
);

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input   clk;
input   reset;
input   wait_for_incoming_data;
input   start_receiving_data;
input   ps2_clk_posedge;
input   ps2_clk_negedge;
input   ps2_data;


// Outputs
output reg [7:0]    received_data;
output reg          received_data_en;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
// states
localparam  PS2_STATE_0_IDLE            = 3'h0,
            PS2_STATE_1_WAIT_FOR_DATA   = 3'h1,
            PS2_STATE_2_DATA_IN         = 3'h2,
            PS2_STATE_3_PARITY_IN       = 3'h3,
            PS2_STATE_4_STOP_IN         = 3'h4;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/
// Internal Wires
reg [3:0]   data_count;
reg [7:0]   data_shift_reg;

// State Machine Registers
reg [2:0]   ns_ps2_receiver;
reg [2:0]   s_ps2_receiver;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

always @(posedge clk)
begin

    if (reset == 1'b1)
        s_ps2_receiver <= PS2_STATE_0_IDLE;
    else
        s_ps2_receiver <= ns_ps2_receiver;
end

always @(*)
begin

    // Defaults
    ns_ps2_receiver = PS2_STATE_0_IDLE;

    case (s_ps2_receiver)

        PS2_STATE_0_IDLE:

            begin
                if ((wait_for_incoming_data == 1'b1) && (received_data_en == 1'b0))
                    ns_ps2_receiver = PS2_STATE_1_WAIT_FOR_DATA;

                else if ((start_receiving_data == 1'b1) && (received_data_en == 1'b0))
                    ns_ps2_receiver = PS2_STATE_2_DATA_IN;

                else
                    ns_ps2_receiver = PS2_STATE_0_IDLE;
            end

        PS2_STATE_1_WAIT_FOR_DATA:

            begin
                if ((ps2_data == 1'b0) && (ps2_clk_posedge == 1'b1))
                    ns_ps2_receiver = PS2_STATE_2_DATA_IN;
                else if (wait_for_incoming_data == 1'b0)
                    ns_ps2_receiver = PS2_STATE_0_IDLE;
                else
                    ns_ps2_receiver = PS2_STATE_1_WAIT_FOR_DATA;
            end

        PS2_STATE_2_DATA_IN:

            begin
                if ((data_count == 3'h7) && (ps2_clk_posedge == 1'b1))
                    ns_ps2_receiver = PS2_STATE_3_PARITY_IN;
                else
                    ns_ps2_receiver = PS2_STATE_2_DATA_IN;
            end

        PS2_STATE_3_PARITY_IN:

            begin
                if (ps2_clk_posedge == 1'b1)
                    ns_ps2_receiver = PS2_STATE_4_STOP_IN;
                else
                    ns_ps2_receiver = PS2_STATE_3_PARITY_IN;
            end

        PS2_STATE_4_STOP_IN:

            begin
                if (ps2_clk_posedge == 1'b1)
                    ns_ps2_receiver = PS2_STATE_0_IDLE;
                else
                    ns_ps2_receiver = PS2_STATE_4_STOP_IN;
            end

        default:

            begin
                ns_ps2_receiver = PS2_STATE_0_IDLE;
            end

    endcase
end

/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

always @(posedge clk)
begin

    if (reset == 1'b1)
        data_count    <= 3'h0;

    else if ((s_ps2_receiver == PS2_STATE_2_DATA_IN) && (ps2_clk_posedge == 1'b1))
        data_count    <= data_count + 3'h1;

    else if (s_ps2_receiver != PS2_STATE_2_DATA_IN)
        data_count    <= 3'h0;
end

always @(posedge clk)
begin

    if (reset == 1'b1)
        data_shift_reg <= 8'h00;

    else if ((s_ps2_receiver == PS2_STATE_2_DATA_IN) && (ps2_clk_posedge == 1'b1))
        data_shift_reg <= {ps2_data, data_shift_reg[7:1]};
end

always @(posedge clk)
begin

    if (reset == 1'b1)
        received_data <= 8'h00;

    else if (s_ps2_receiver == PS2_STATE_4_STOP_IN)
        received_data <= data_shift_reg;
end

always @(posedge clk)
begin

    if (reset == 1'b1)
        received_data_en    <= 1'b0;

    else if ((s_ps2_receiver == PS2_STATE_4_STOP_IN) && (ps2_clk_posedge == 1'b1))
        received_data_en    <= 1'b1;
    else
        received_data_en    <= 1'b0;
end

endmodule
