`timescale 1ns / 1ps
// RACKctl interface. Handles both mode 0 (bidirectional half-duplex)
// and mode 1 (receive only, transmit through the CIN interface).
// This module is ONLY the PHY. The actual transaction requests come
// from the wb_surfbridge_rackctl.sv module.
//
// we need:
// 24-bit address/type input (statically held from surfbridge)
// 32-bit data input (statically held from surfbridge)
// 32-bit data output
// transaction start flag input (begin process)
// transaction done flag output (process done)
// transaction error flag output (process done, end in error)
// Because we control the rackctl process, we don't need an ack flag,
// we just don't issue another transaction.
module surf_rackctl_phy #(parameter INV=1'b0, 
                          parameter DEBUG = "FALSE")(
        input sysclk_i,
        input mode_i,
        input [23:0] txn_addr_i,
        input [31:0] txn_data_i,
        output [31:0] txn_resp_o,
        input txn_start_i,
        output txn_done_o,
        output txn_err_o,
        inout RACKCTL_P,
        inout RACKCTL_N
    );
    // if 1, rackctl is tristated    
    wire rackctl_tri;
    // output TO rackctl
    wire rackctl_out;
    // data FROM rackctl FF
    wire rackctl_in;
    // capture rackctl FF
    wire rackctl_ce;
    // data FROM rackctl monitor FF
    wire rackctl_mon_inb;

    rackctl_bidir_phy #(.INV(INV)) 
        u_phy(.clk_i(sysclk_i),
              .rack_tri_i(rackctl_tri),
              .rack_out_i(rackctl_out),
              .rack_cein_i(rackctl_ce),
              .rack_in_o(rackctl_in),
              .rack_mon_o(rackctl_mon_inb),
              .RACKCTL_P(RACKCTL_P),
              .RACKCTL_N(RACKCTL_N));

    // at 125 MHz, we need to delay around 125 clocks once we hit turnaround.
    // just use 128.
    reg [7:0] turnaround_timer = {8{1'b0}};
    
    // Data storage/shift register. Data always shifts out the top and in the bottom.
    // This is a CC source and target.
    (* CUSTOM_CC_DST = "SYSCLK", CUSTOM_CC_SRC = "SYSCLK" *)
    reg [31:0] data_reg = {32{1'b0}};
    
    // we don't need a reset since we're the master originally.
    // the mode switch essentially happens in a sequence after alignment:
    // a write to the register switches off training on CIN, and that
    // (plus the locked interface) does a mode switch at the SURF and at the TURFIO
    // at the same time. I haven't thought too hard about switching back yet,
    // need to do that.
    //
    // The reason we have the mode at all here is because in mode0, we idle driving,
    // and in mode1, we idle receiving. 
    localparam FSM_BITS = 5;
    localparam [FSM_BITS-1:0] MODE0_IDLE = 0; // drive 1
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_0 = 1; // drive 1
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_1 = 2; // drive 0
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_2 = 3; // drive 1
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_3 = 4; // drive 0
    localparam [FSM_BITS-1:0] MODE0_PREAMBLE_4 = 5; // drive 1
    localparam [FSM_BITS-1:0] MODE0_TXN = 6;        // drive 24 bits of addr/readwriteb
    localparam [FSM_BITS-1:0] MODE0_DATA = 7;       // drive data if needed
    localparam [FSM_BITS-1:0] MODE0_TURNAROUND_0 = 8; // tristate and wait
    localparam [FSM_BITS-1:0] POSTAMBLE_0 = 9;  // both in mode0/mode1
    localparam [FSM_BITS-1:0] START_BIT = 10;    // both in mode0/mode1
    localparam [FSM_BITS-1:0] CAPTURE = 11;     // both in mode0/mode1
    localparam [FSM_BITS-1:0] COMPLETE = 12;    // both in mode0/mode1
    localparam [FSM_BITS-1:0] MODE0_TURNAROUND_1 = 13; // drive again and wait
    localparam [FSM_BITS-1:0] MODE0_TIMEOUT = 14;   // mode0 did not see a 1 after turnaround
    localparam [FSM_BITS-1:0] MODE1_IDLE = 15;      // wait for a data/ack capture request
    localparam [FSM_BITS-1:0] MODE1_TIMEOUT = 16;   // mode1 did not see a start bit within a short window
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
    // we count in (MODE0_PREAMBLE_4) || (MODE0_TXN) || (MODE0_DATA) || (START_BIT && !rackctl_in) || CAPTURE
    wire [3:0] data_counter_addend = { (state == MODE0_PREAMBLE_4), 1'b0, 1'b0, 1'b1 };
    
    // for debugging
    (* KEEP = "TRUE" *)
    reg tristate_rackctl_mon = 0;
    // these need to be set up a clock before
    wire preamble_data = 
        (state == MODE0_IDLE || state == MODE0_PREAMBLE_1 || 
         state == MODE0_PREAMBLE_3 || state == MODE0_TURNAROUND_1);
    
    // This is the current mode. mode_i makes us switch when safe.
    reg rackctl_mode = 0;
    // Stored transaction type. Captured from top bit of txn_addr.
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg rackctl_txn_type = 0;
    // This indicates a transaction is pending.
    reg rackctl_txn_pending = 0;
    

    always @(posedge sysclk_i) begin
        // with the ordering this way, we can just check rackctl_txn_pending instead
        // of the input flag.
        // NOTE: WE HAVE TO MAKE SURE TO GUARD TXN_START_I HAPPENING AT THE SAME TIME AS
        // A MODE TRANSITION. MODE TRANSITIONS EFFECTIVELY ACT LIKE TRANSACTIONS, SO THEY
        // NEED TO BE ACKED.
        if (txn_start_i) rackctl_txn_pending <= 1;
        else if (state == MODE0_IDLE || state == MODE1_IDLE) rackctl_txn_pending <= 0;
        // checking txn_pending && one of the IDLE states makes this a flag.
        // (note: you can't go txn_start_i -> mode_i change without waiting for done flag)
        if (rackctl_txn_pending && (state == MODE0_IDLE || state == MODE1_IDLE))
            rackctl_txn_type <= txn_addr_i[23];

        // mode transitions only happen in idle        
        if (state == MODE0_IDLE && mode_i) rackctl_mode <= 1;
        else if (state == MODE1_IDLE && !mode_i) rackctl_mode <= 0;
        
        // turnaround timer. in START_BIT this is used as a timeout.
        if (state == MODE0_TURNAROUND_0 || state == MODE0_TURNAROUND_1 || state == START_BIT) 
            turnaround_timer <= turnaround_timer[6:0] + 1;
        else 
            turnaround_timer <= {7{1'b0}};

        // state transitions 
        case (state)
            // mode switch takes priority over pending transaction: mode switches from
            // the SURFbridge act like transactions, so when mode_i changes, it will
            // wait for an ack before issuing a transaction in the new mode.
            MODE0_IDLE: if (mode_i) state <= MODE0_TURNAROUND_0;
                        else if (rackctl_txn_pending) state <= MODE0_PREAMBLE_0;
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
            POSTAMBLE_0: if (rackctl_in == 1'b0) begin
                            if (rackctl_mode) state <= MODE1_TIMEOUT;
                            else state <= MODE0_TIMEOUT;
                         end else state <= START_BIT;
            // the turnaround timer becomes our timeout counter.
            // this is excessively long, but whatever.
            START_BIT:   if (turnaround_timer[7]) begin
                            if (rackctl_mode) state <= MODE1_TIMEOUT;
                            else state <= MODE0_TIMEOUT;
                         end else if (rackctl_in == 1'b0) begin
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
            // switching back from MODE1 to MODE0 needs to generate
            // a completion flag.
            MODE1_IDLE: if (!mode_i) state <= COMPLETE;
                        else if (rackctl_txn_pending) state <= POSTAMBLE_0;
            // error flag out                        
            MODE1_TIMEOUT: state <= MODE1_IDLE;                        
        endcase            

        // we count in (MODE0_PREAMBLE_4) || (MODE0_TXN) || (MODE0_DATA) || (START_BIT) || CAPTURE
        if (state == MODE0_PREAMBLE_4 || state == MODE0_TXN ||
            state == MODE0_DATA || (state == START_BIT && !rackctl_in) || state == CAPTURE)
            data_counter <= data_counter[4:0] + data_counter_addend[3:0];
        else
            data_counter <= {6{1'b0}};
    
        // data register is a loadable shift register.
        // it's loaded in MODE0_PREAMBLE_3 because
        // in MODE0_PREAMBLE_4 rackctl_out_ff grabs bit 31 next.
        // It's also loaded in MODE0_TXN if data_counter[5].
        // It then shifts in MODE0_PREAMBLE_4/MODE0_TXN/MODE0_DATA/CAPTURE.
        if (state == MODE0_PREAMBLE_3) begin
            // OK, this is ultra-sleaze. We need txn_data_i[31] to be in the top bit of data_reg
            // when data_counter is 31 in MODE0_TXN state. But we have no way to signal that.
            // Except we don't need to - we can capture it *here*, and let it shift up naturally,
            // and then fill in the rest of the bits at MODE0_TXN. && data_counter[5].
            // In reads, that value just gets dropped, so it doesn't matter.
            // We don't care about the bottom 7 bits (they get dropped) so we actually keep their logic
            // the same as below.
            //
            // Basically, if you work out the entire logic here:
            // data_reg[0] is ALWAYS capturing rackctl_in in ANY of these states.
            // data_reg[1] is capturing either data_reg[0] or txn_data_i[0]
            // data_reg[2] is capturing either data_reg[1] or txn_data_i[1] etc.
            // data_reg[7] is capturing either data_reg[6] or txn_data_i[6] or txn_data_i[31]
            // data_reg[8] is capturing either data_reg[7] or txn_data_i[7] or txn_addr_i[0].
            // Because we FULLY capture data_reg as well, the synthesizer can convert the entire if block
            // here to a control set CE and then use the various state encodings to mux the data.
            // God knows if it'll be that smart.
            data_reg[31:7] <= {txn_addr_i, txn_data_i[31]};
            data_reg[6:0] <= {data_reg[5:0], rackctl_in};
        end else if (state == MODE0_TXN && data_counter[5]) begin
            // txn_data_i[31] is captured at MODE0_PREAMBLE_3, we just need to fill in the rest here.
            // The top bit is being loaded into rackctl_out here.
            // Note the sleaze here of grabbing rackctl_in: we don't care what value we shift in,
            // and this means the bottom bit only grabs from rackctl_in, period. 
            data_reg <= {txn_data_i[30:0], rackctl_in };
        end else if (state == MODE0_TXN || state == MODE0_DATA || state == CAPTURE || state == MODE0_PREAMBLE_4) begin
            data_reg <= {data_reg[30:0], rackctl_in};
        end     
        tristate_rackctl_mon <= rackctl_tri;        
    end

    generate
        // probes
        // rackctl_mon_ff
        // data_reg
        // tristate_rackctl
        // state
        // data_counter
        if (DEBUG == "TRUE") begin : ILA
            rackctl_ila u_ila(.clk(sysclk_i),
                              // rackctl_mon_inb is inverted, so invert it going to the ILA.
                              .probe0(~rackctl_mon_inb),
                              .probe1(data_reg),
                              .probe2(tristate_rackctl_mon),
                              .probe3(state),
                              .probe4(data_counter));
        end
    endgenerate

    // our final data is either the preamble data, the shift register
    assign rackctl_out = (state == MODE0_PREAMBLE_4 || state == MODE0_TXN || state == MODE0_DATA) 
                            ? data_reg[31] : preamble_data;
    // we're tristated only in these states
    assign rackctl_tri = (state == MODE0_TURNAROUND_0 || 
                             state == POSTAMBLE_0 || 
                             state == START_BIT || 
                             state == CAPTURE ||
                             state == COMPLETE ||
                             state == MODE1_TIMEOUT ||
                             state == MODE1_IDLE);    
    // these determine when we start capturing rackctl_in.
    // we keep capturing even all the way through capture because we store in the data register.
    // we always need to capture in MODE1_IDLE because we need to make sure rackctl_in_ff is valid
    // in POSTAMBLE_0.
    assign rackctl_ce = (state == MODE0_TURNAROUND_0 || 
                         state == POSTAMBLE_0 || 
                         state == START_BIT || 
                         state == CAPTURE ||
                         state == MODE1_IDLE);
    // data_reg is functionally static b/c the bridge doesn't issue another transaction
    // until it gets the result.
    assign txn_resp_o = data_reg;
    assign txn_done_o = (state == COMPLETE);
    assign txn_err_o = (state == MODE0_TIMEOUT || state == MODE1_TIMEOUT);
endmodule
