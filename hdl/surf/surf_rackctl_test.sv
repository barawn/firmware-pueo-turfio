`timescale 1ns / 1ps
// Testing mode 0 of the RACKCTL interface.
// Because we don't have as much FIFO space as the SURF we hang around after a
// transaction until it's fully captured.
//
// The full rackctl is going to need
// 24-bit address/type input (statically held from surfbridge)
// 32-bit data input (statically held from surfbridge)
// 32-bit data output
// transaction start flag input (begin process)
// transaction done flag output (process done)
// transaction error flag output (process done, end in error)
// Because we control the rackctl process, we don't need an ack flag,
// we just don't issue another transaction.
//
// Here we can test the interface: the 24-bit address/type are the top 24 bits.
module surf_rackctl_test #(parameter INV=1'b0, parameter DEBUG = "FALSE")(
        input sysclk_i,
        input mode_i,
        inout RACKCTL_P,
        inout RACKCTL_N
    );
    
    // I really need to modularize a lot of this
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
    // here we only use 24 bits of it for addr and
    // retransmit it if it's data.
    wire [31:0] msg_data;
    wire        send_msg;
    reg         send_msg_rereg = 0;
    wire        send_msg_flag = (send_msg && !send_msg_rereg);
    always @(posedge sysclk_i) send_msg_rereg <= send_msg;

    wire [23:0] txn_addr = msg_data[31:8];
    wire [31:0] txn_data = msg_data[31:0];
    // fully 32-bits wide now
    reg [31:0] data_reg = {32{1'b0}};
    
//    localparam FSM_BITS = 4;
//    localparam [FSM_BITS-1:0] IDLE = 0;       // drive 1
//    localparam [FSM_BITS-1:0] PREAMBLE_0 = 1; // drive 1
//    localparam [FSM_BITS-1:0] PREAMBLE_1 = 2; // drive 0
//    localparam [FSM_BITS-1:0] PREAMBLE_2 = 3; // drive 1
//    localparam [FSM_BITS-1:0] PREAMBLE_3 = 4; // drive 0
//    localparam [FSM_BITS-1:0] PREAMBLE_4 = 5; // drive 1
//    localparam [FSM_BITS-1:0] DATA = 6;       // drive data
//    localparam [FSM_BITS-1:0] TURNAROUND_0 = 7; // tristate and wait
//    localparam [FSM_BITS-1:0] POSTAMBLE_0 = 8;  // check 1
//    localparam [FSM_BITS-1:0] START_BIT = 9;    // search 0
//    localparam [FSM_BITS-1:0] CAPTURE = 10;
//    localparam [FSM_BITS-1:0] TURNAROUND_1 = 11; // drive again and wait
//    localparam [FSM_BITS-1:0] TIMEOUT = 12;
//    reg [FSM_BITS-1:0] state = IDLE;

    // we don't need a reset since we're the master originally.
    // the mode switch essentially happens in a sequence after alignment:
    // a write to the register switches off training on CIN, and that
    // (plus the locked interface) does a mode switch at the SURF and at the TURFIO
    // at the same time. I haven't thought too hard about switching back yet,
    // need to do that.
    //
    // The reason we have the mode at all here is because in mode0, we idle driving,
    // and in mode1, we idle receiving. 
    localparam FSM_BITS = 4;
    localparam [FSM_BITS-1:0] MODE0_IDLE = 0; // drive 1
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_0 = 1; // drive 1
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_1 = 2; // drive 0
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_2 = 3; // drive 1
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_3 = 4; // drive 0
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_4 = 5; // drive 1
    localparam [FSM_BITS-1:0] MODE0_TXN = 6;        // drive 24 bits of addr/readwriteb
    localparam [FSM_BITS-1:0] MODE0_DATA = 6;       // drive data if needed
    localparam [FSM_BITS-1:0] MODE0_TURNAROUND_0 = 7; // tristate and wait
    localparam [FSM_BITS-1:0] POSTAMBLE_0 = 8;  // both in mode0/mode1
    localparam [FSM_BITS-1:0] START_BIT = 9;    // both in mode0/mode1
    localparam [FSM_BITS-1:0] CAPTURE = 10;     // both in mode0/mode1
    localparam [FSM_BITS-1:0] COMPLETE = 11;    // both in mode0/mode1
    localparam [FSM_BITS-1:0] MODE0_TURNAROUND_1 = 12; // drive again and wait
    localparam [FSM_BITS-1:0] MODE0_TIMEOUT = 13;   // mode0 did not see a 1 after turnaround
    localparam [FSM_BITS-1:0] MODE1_IDLE = 14;      // wait for a data/ack capture request
    localparam [FSM_BITS-1:0] MODE1_TIMEOUT = 15;   // mode1 did not see a start bit within a short window
    reg [FSM_BITS-1:0] state = MODE0_IDLE;

    // the data counter gets used 3 times. in MODE0_PREAMBLE_4 (just before sending the address)
    // we want to preload it to 9 so it counts 9-32 in the 24 clocks of MODE0_TXN.
    // it then counts 1-32 (because of the lack of rollover) in MODE0_DATA.
    // On the receive side, we want the data fully in data_reg so if we go (imagine 8 bit receive)
    // clk  rackctl_in_ff   data_reg        counter     state
    // 0    0               X               0           START_BIT
    // 1    A               X               1           CAPTURE
    // 2    B               A               2           CAPTURE
    // 3    C               BA              3           CAPTURE
    // 4    D               CBA             4           CAPTURE
    // 5    E               DCBA            5           CAPTURE
    // 6    F               E_DCBA          6           CAPTURE
    // 7    G               FE_DCBA         7           CAPTURE
    // 8    H               GFE_DCBA        8           CAPTURE
    // 9    X               HGFE_DCBA       X           COMPLETE
    reg [5:0] data_counter = {6{1'b0}};
    // start off at 9 in MODE0_TXN then count sequentially.
    // we count in (MODE0_PREAMBLE_4) || (MODE0_TXN) || (MODE0_DATA) || (START_BIT) || CAPTURE
    wire [3:0] data_counter_addend = { (state == MODE0_PREAMBLE_4), 1'b0, 1'b0, 1'b1 };
    
    (* IOB = "TRUE" *)
    reg tristate_rackctl = 0;    
    (* KEEP = "TRUE" *)
    reg tristate_rackctl_mon = 0;
    // these need to be set up a clock before
    wire preamble_data = 
        (state == MODE0_IDLE || state == MODE0_PREAMBLE_1 || 
         state == MODE0_PREAMBLE_3 || state == MODE0_TURNAROUND_1);
    // these determine when we start capturing rackctl_in.
    // we keep capturing even all the way through capture because we store in the data register.
    // we always need to capture in MODE1_IDLE because we need to make sure rackctl_in_ff is valid
    // in POSTAMBLE_0.
    wire rackctl_ce = (state == MODE0_TURNAROUND_0 || 
                       state == POSTAMBLE_0 || 
                       state == START_BIT || 
                       state == CAPTURE ||
                       state == MODE1_IDLE);
    
    // 0 for mode 0, 1 for mode 1
    reg rackctl_mode = 0;
    // 0 for a write, 1 for a read
    reg rackctl_txn_type = 0;
    // indicates transaction request. We really need to capture
    // the flag and hold it if we're not in MODE0_IDLE/MODE1_IDLE.
    // This can happen in MODE0 if we're still in turnaround.
    wire rackctl_do_txn = send_msg_flag;
        
    always @(posedge sysclk_i) begin
        // FIX THIS THIS IS JUST FOR TESTING
        if (send_msg_flag) rackctl_txn_type <= txn_addr[23];
        
        if (state == MODE0_IDLE && mode_i) rackctl_mode <= 1;
        else if (state == MODE1_IDLE && !mode_i) rackctl_mode <= 0;
        
        if (state == MODE0_TURNAROUND_0 || state == MODE0_TURNAROUND_1 || state == START_BIT) 
            turnaround_timer <= turnaround_timer[6:0] + 1;
        else 
            turnaround_timer <= {7{1'b0}};

        case (state)
            MODE0_IDLE: if (mode_i) state <= MODE0_TURNAROUND_0;
                        else if (rackctl_do_txn) state <= MODE0_PREAMBLE_0;
            MODE0_PREAMBLE_0: state <= MODE0_PREAMBLE_1;
            MODE0_PREAMBLE_1: state <= MODE0_PREAMBLE_2;
            MODE0_PREAMBLE_2: state <= MODE0_PREAMBLE_3;
            MODE0_PREAMBLE_3: state <= MODE0_PREAMBLE_4;
            MODE0_PREAMBLE_4: state <= MODE0_TXN;
            // transmit more right away if a write, otherwise turnaround
            MODE0_TXN: if (data_counter[5]) begin
                          if (rackctl_txn_type) state <= MODE0_TURNAROUND_0;
                          else state <= MODE0_DATA;
                       end
            MODE0_DATA: if (data_counter[5]) state <= MODE0_TURNAROUND_0;
            MODE0_TURNAROUND_0: if (turnaround_timer[7]) state <= POSTAMBLE_0;
            POSTAMBLE_0: if (rackctl_in_ff == 1'b0) begin
                            if (rackctl_mode) state <= MODE1_TIMEOUT;
                            else state <= MODE0_TIMEOUT;
                         end else state <= START_BIT;
            // the turnaround timer becomes our timeout counter.
            // this is excessively long, but whatever.
            START_BIT:   if (turnaround_timer[7]) begin
                            if (rackctl_mode) state <= MODE1_TIMEOUT;
                            else state <= MODE0_TIMEOUT;
                         end else if (rackctl_in_ff == 1'b0) begin
                            // found start bit
                            // is it a read?
                            if (rackctl_txn_type) 
                                state <= CAPTURE;
                            else // no, so we're done. 
                                state <= COMPLETE;
                         end
            CAPTURE: if (data_counter[5]) state <= COMPLETE;
            // done flag out
            COMPLETE: if (rackctl_mode) state <= MODE1_IDLE;
                      else state <= MODE0_TURNAROUND_1;
            MODE0_TURNAROUND_1: if (turnaround_timer[7]) state <= MODE0_IDLE;
            // error flag out
            MODE0_TIMEOUT: state <= MODE0_IDLE;
            MODE1_IDLE: if (!mode_i) state <= MODE0_TURNAROUND_1;
                        else if (rackctl_do_txn) state <= POSTAMBLE_0;
            // error flag out                        
            MODE1_TIMEOUT: state <= MODE1_IDLE;                        
        endcase            

        // we count in (MODE0_PREAMBLE_4) || (MODE0_TXN) || (MODE0_DATA) || (START_BIT) || CAPTURE
        if (state == MODE0_PREAMBLE_4 || state == MODE0_TXN ||
            state == MODE0_DATA || (state == START_BIT && !rackctl_in_ff) ||
            state == CAPTURE)
            data_counter <= data_counter[4:0] + data_counter_addend[3:0];
        else
            data_counter <= {6{1'b0}};
    
        // data register is a loadable shift register.
        // it's loaded in MODE0_PREAMBLE_3 because
        // in MODE0_PREAMBLE_4 rackctl_out_ff grabs bit 31 next.
        // It's also loaded in MODE0_TXN if data_counter[5].
        // It then shifts in MODE0_PREAMBLE_4/MODE0_TXN/MODE0_DATA/CAPTURE.
        if (state == MODE0_PREAMBLE_3) begin
            data_reg[31:8] <= txn_addr;
        end else if (state == MODE0_TXN && data_counter[5]) begin
            data_reg <= txn_data;
        end else if (state == MODE0_TXN || state == MODE0_DATA || state == CAPTURE || state == MODE0_PREAMBLE_4) begin
            data_reg <= {data_reg[30:0], rackctl_in_ff};
        end     
        // monitor runs all the time
        rackctl_mon_ff <= rackctl_in_inv;
                
        // We don't need to invert rackctl_in_ff, we did that by picking
        // off the non-inverted input.
        //rackctl_in_ff needs to be captured when tristate_rackctl is high.
        // but we can't use that because it's an IOB, so use its monitor.
        if (rackctl_ce) rackctl_in_ff <= rackctl_in;

        // We have to invert here, there's no programmable inverter on the output.
        // our data needs to go out the top and in the bottom
        if (state == MODE0_PREAMBLE_4 || state == MODE0_TXN || state == MODE0_DATA)
            rackctl_out_ff <= INV ^ data_reg[31];
        else
            rackctl_out_ff <= INV ^ preamble_data;
                
        // rackctl tristating is just handled by spec'ing everything.
        // we exit out of tristate either in MODE0_TIMEOUT or MODE0_TURNAROUND_1.
        tristate_rackctl <= (state == MODE0_TURNAROUND_0 || 
                             state == POSTAMBLE_0 || 
                             state == START_BIT || 
                             state == CAPTURE ||
                             state == COMPLETE ||
                             state == MODE1_TIMEOUT ||
                             state == MODE1_IDLE);
        tristate_rackctl_mon <= (state == MODE0_TURNAROUND_0 || 
                             state == POSTAMBLE_0 || 
                             state == START_BIT || 
                             state == CAPTURE ||
                             state == COMPLETE ||
                             state == MODE1_TIMEOUT ||
                             state == MODE1_IDLE);
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
        // data_reg
        // tristate_rackctl
        // state
        // data_counter
        if (DEBUG == "TRUE") begin : ILA
            rackctl_ila u_ila(.clk(sysclk_i),
                              .probe0(rackctl_mon_ff),
                              .probe1(data_reg),
                              .probe2(tristate_rackctl_mon),
                              .probe3(state),
                              .probe4(data_counter));
            rackctl_vio u_vio(.clk(sysclk_i),
                              .probe_out0(msg_data),
                              .probe_out1(send_msg));                              
        end
    endgenerate


endmodule
