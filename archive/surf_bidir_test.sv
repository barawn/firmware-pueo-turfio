`timescale 1ns / 1ps
// This module matches the turfio_bidir_test. Here we're testing to see that
// the UltraScale LVDS I/O turn around time is realistic.
module surf_bidir_test #(parameter INV=1'b0, parameter DEBUG = "FALSE")(
        input sysclk_i,
        inout RACKCTL_P,
        inout RACKCTL_N
    );
    
    // from IOB
    wire rackctl_in;
    // from IOB, inverted
    wire rackctl_in_inv;
    // data going to IOB
    wire rackctl_out;
    
    // at 125 MHz, we need to delay around 125 clocks once we hit turnaround.
    // just use 128.
    reg [7:0] turnaround_timer = {8{1'b0}};
    
    // we don't need the ignores    
    (* IOB = "TRUE" *)
    reg rackctl_in_ff = 0;
    (* IOB = "TRUE" *)
    reg rackctl_mon_ff = 0;
    (* IOB = "TRUE" *)
    reg rackctl_out_ff = INV;
    assign rackctl_out = rackctl_out_ff;
    
    // crap from the VIO
    wire [31:0] msg_data;
    wire        send_msg;
    reg         send_msg_rereg = 0;
    wire        send_msg_flag = (send_msg && !send_msg_rereg);
    always @(posedge sysclk_i) send_msg_rereg <= send_msg;
    
    reg [30:0] data_reg = {31{1'b0}};
    wire [31:0] full_data_in = {data_reg, rackctl_in_ff};
    
    reg [5:0] data_counter = {6{1'b0}};
    
    localparam FSM_BITS = 4;
    localparam [FSM_BITS-1:0] IDLE = 0;       // drive 1
    localparam [FSM_BITS-1:0] PREAMBLE_0 = 1; // drive 1
    localparam [FSM_BITS-1:0] PREAMBLE_1 = 2; // drive 0
    localparam [FSM_BITS-1:0] PREAMBLE_2 = 3; // drive 1
    localparam [FSM_BITS-1:0] PREAMBLE_3 = 4; // drive 0
    localparam [FSM_BITS-1:0] PREAMBLE_4 = 5; // drive 1
    localparam [FSM_BITS-1:0] DATA = 6;       // drive data
    localparam [FSM_BITS-1:0] TURNAROUND_0 = 7; // tristate and wait
    localparam [FSM_BITS-1:0] POSTAMBLE_0 = 8;  // check 1
    localparam [FSM_BITS-1:0] START_BIT = 9;    // search 0
    localparam [FSM_BITS-1:0] CAPTURE = 10;
    localparam [FSM_BITS-1:0] TURNAROUND_1 = 11; // drive again and wait
    localparam [FSM_BITS-1:0] TIMEOUT = 12;
    reg [FSM_BITS-1:0] state = IDLE;
    
    (* IOB = "TRUE" *)
    reg tristate_rackctl = 0;    
    (* KEEP = "TRUE" *)
    reg tristate_rackctl_mon = 0;
    // these need to be set up a clock before
    wire preamble_data = (state == IDLE || state == PREAMBLE_1 || state == PREAMBLE_3 || state == TURNAROUND_1);
    
    wire rackctl_ce = (state == TURNAROUND_0 || state == POSTAMBLE_0 || state == START_BIT || (state == CAPTURE && !data_counter[5]));    
    
    always @(posedge sysclk_i) begin
        if (state == TURNAROUND_0 || state == TURNAROUND_1) turnaround_timer <= turnaround_timer[6:0] + 1;
        else turnaround_timer <= {7{1'b0}};
        
        if (state == DATA || state == CAPTURE)
            data_counter <= data_counter[4:0] + 1;
        else
            data_counter <= {6{1'b0}};
        
        case (state)
            IDLE: if (send_msg_flag) state <= PREAMBLE_0;
            PREAMBLE_0: state <= PREAMBLE_1;
            PREAMBLE_1: state <= PREAMBLE_2;
            PREAMBLE_2: state <= PREAMBLE_3;
            PREAMBLE_3: state <= PREAMBLE_4;
            PREAMBLE_4: state <= DATA;
            DATA: if (data_counter[5]) state <= TURNAROUND_0;
            TURNAROUND_0: if (turnaround_timer[7]) state <= POSTAMBLE_0;
            POSTAMBLE_0: if (rackctl_in_ff == 1'b0) state <= TIMEOUT;
                         else state <= START_BIT;
            START_BIT: if (rackctl_in_ff == 1'b0) state <= CAPTURE;
            CAPTURE: if (data_counter[5]) state <= TURNAROUND_1;
            TURNAROUND_1: if (turnaround_timer[7]) state <= IDLE;
            TIMEOUT: state <= IDLE;
        endcase            
        
        // monitor runs all the time
        rackctl_mon_ff <= rackctl_in_inv;
                
        // We don't need to invert rackctl_in_ff, we did that by picking
        // off the non-inverted input.
        //rackctl_in_ff needs to be captured when tristate_rackctl is high.
        // but we can't use that because it's an IOB, so use its monitor.
        if (rackctl_ce) rackctl_in_ff <= rackctl_in;

        // We have to invert here, there's no programmable inverter on the output.
        // our data needs to go out the top and in the bottom
        if (state == PREAMBLE_4) rackctl_out_ff <= INV ^ msg_data[31];
        else if (state == DATA) rackctl_out_ff <= INV ^ data_reg[30];
        else rackctl_out_ff <= INV ^ preamble_data;
        
        if (state == PREAMBLE_4) data_reg <= msg_data[30:0];
        else if (state == DATA || (state == CAPTURE && !data_counter[5])) begin
            data_reg <= { data_reg[29:0], rackctl_in_ff };
        end
        
        // ok let's try it this way
        tristate_rackctl <= (state == TURNAROUND_0 || state == POSTAMBLE_0 || state == START_BIT || state == CAPTURE);
        tristate_rackctl_mon <= (state == TURNAROUND_0 || state == POSTAMBLE_0 || state == START_BIT || state == CAPTURE);
    end

    generate
        if (INV == 1'b1) begin : IOINV
            IOBUFDS_DIFF_OUT u_iob(.I(rackctl_out),.O(rackctl_in_inv),.OB(rackctl_in),.TM(tristate_rackctl),.TS(tristate_rackctl),
                                   .IO(RACKCTL_N),.IOB(RACKCTL_P));
        end else begin : IO
            IOBUFDS_DIFF_OUT u_iob(.I(rackctl_out),.O(rackctl_in),.OB(rackctl_in_inv),.TM(tristate_rackctl),.TS(tristate_rackctl),
                                   .IO(RACKCTL_P),.IOB(RACKCTL_N));
        end
        // probes
        // rackctl_mon_ff
        // full_data_in
        // tristate_rackctl
        // state
        // data_counter
        if (DEBUG == "TRUE") begin : ILA
            rackctl_ila u_ila(.clk(sysclk_i),
                              .probe0(rackctl_mon_ff),
                              .probe1(full_data_in),
                              .probe2(tristate_rackctl_mon),
                              .probe3(state),
                              .probe4(data_counter));
            rackctl_vio u_vio(.clk(sysclk_i),
                              .probe_out0(msg_data),
                              .probe_out1(send_msg));                              
        end
    endgenerate


endmodule
