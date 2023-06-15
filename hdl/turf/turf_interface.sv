`timescale 1ns / 1ps
`include "interfaces.vh"
// This is the TURF portion of the TURFIO serial control interface.
// The TURF path is a bit special because it actually uses the RXCLK input.
//
// The overall process is:
// step 0: make sure TURF control interface is put into training mode.
// step 1: check if RXCLK and HSRXCLK are available. If not, stop, we do not
//         have a usable TURF control interface.
// step 2: reset everything I guess?
// step 3: set the RX bit error source control to be on the RXCLK side.
// step 4: step through the IDELAY values to find the center of the eye for RXCLK capture.
// step 5: execute a value capture until a non-ambigous byte is acquired (skip A6, 5A, 69, and D3)
// step 6: execute the appropriate number of bitslips based on the byte acquired
// step 7: on the TURF-side interface, execute an eye scan 
//         
// Training on the TURFIO side is only needed for the CIN path.
// register 0x00: Reset controls, sync enable, interface enable
// register 0x04: CIN IDELAY control/readback
// register 0x08: CIN RXCLK bit error control and readback
// register 0x0C: CIN value capture and bitslip control
// register 0x10: CIN SYSCLK bit error control and readback
// register 0x14: COUT training value
// register 0x18: COUT training enable
// register 0x1C-0x3F: reserved
module turf_interface #(
        parameter RXCLK_INV = 1'b0,
        parameter TXCLK_INV = 1'b0,
        parameter [6:0] COUT_INV = {7{1'b0}},
        parameter COUTTIO_INV = 1'b0,
        parameter CIN_INV = 1'b0 
    )
    (   input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 6, 32),
        input  sysclk_ok_i,
        input  sysclk_i,
        output sync_o,
        input rxclk_ok_i,
        output rxclk_o,
        output rxclk_x2_o,
        input RXCLK_P,
        input RXCLK_N,
        output TXCLK_P,
        output TXCLK_N,
        output COUTTIO_P,
        output COUTTIO_N,
        input CIN_P,
        input CIN_N        
    );

    // Demultiplexed output register.
    reg [31:0] dat_reg = {32{1'b0}};

    //////////////////////////////////////////
    // Clock Crossings
    //
    // Our register access in the wb clk domain
    // But some of our controls/etc. are in the
    // rxclk and sysclk domains.
    //
    // So if those controls are accessed,
    // we bounce over to the other domain
    // and let them process it.
    //
    // Just to make the clock crossings easier
    // we hold address, write enable, and data
    // static here.
    //////////////////////////////////////////
    
    reg [31:0] dat_in_static = {32{1'b0}};
    reg [5:0]  adr_in_static = {6{1'b0}};
    reg        we_in_static = 0;

    // These determine whether we're jumping over to the rxclk or sysclk sides.
    wire rxclk_access = (wb_adr_i == 6'h4 || wb_adr_i == 6'h8 || wb_adr_i == 6'h0C);
    wire sysclk_access= (wb_adr_i == 6'h10);
    // These are the flags to inform the other domains.
    wire rxclk_waiting;
    reg rxclk_waiting_reg = 0;
    always @(posedge wb_clk_i) rxclk_waiting_reg <= rxclk_waiting;
    wire rxclk_waiting_flag_wbclk = (rxclk_waiting && !rxclk_waiting_reg);
    wire rxclk_waiting_flag_rxclk;
    flag_sync u_rxclk_waiting_sync(.clkA(wb_clk_i),.clkB(rxclk_o),
                                   .in_clkA(rxclk_waiting_flag_wbclk),
                                   .out_clkB(rxclk_waiting_flag_rxclk));
    reg  rxclk_ack_flag_rxclk = 0;
    always @(posedge rxclk_o) rxclk_ack_flag_rxclk <= rxclk_waiting_flag_rxclk;
    wire rxclk_ack_flag_wbclk;
    flag_sync u_rxclk_ack_sync(.clkA(rxclk_o),.clkB(wb_clk_i),
                               .in_clkA(rxclk_ack_flag_rxclk),
                               .out_clkB(rxclk_ack_flag_wbclk));

    wire sysclk_waiting;
    reg sysclk_waiting_reg = 0;
    always @(posedge wb_clk_i) sysclk_waiting_reg <= sysclk_waiting;
    wire sysclk_waiting_flag_wbclk = (sysclk_waiting && !sysclk_waiting_reg);
    wire sysclk_waiting_flag_sysclk;
    flag_sync u_sysclk_waiting_sync(.clkA(wb_clk_i),.clkB(sysclk_i),
                                    .in_clkA(sysclk_waiting_flag_wbclk),
                                    .out_clkB(sysclk_waiting_flag_sysclk));
    reg sysclk_ack_flag_sysclk = 0;
    always @(posedge sysclk_i) sysclk_ack_flag_sysclk <= sysclk_waiting_flag_sysclk;
    wire sysclk_ack_flag_wbclk;
    flag_sync u_sysclk_ack_sync(.clkA(sysclk_i),.clkB(wb_clk_i),
                                .in_clkA(sysclk_ack_flag_sysclk),
                                .out_clkB(sysclk_ack_flag_wbclk));


        
    // This is our first attempt just to get it working.
    // Try at 500 Mbit/s.
    
    // RXCLK is special, because if it's inverted,
    // we have to fix it at the MMCM. You *cannot* just grab
    // the inverted output, and you can't just freely invert
    // it along the way. Because Xilinx is stupid.
    
    // RXCLK positive inputs to IBUFDS
    wire rxclk_in_p = (RXCLK_INV) ? RXCLK_N : RXCLK_P;
    // RXCLK negative inputs to IBUFDS
    wire rxclk_in_n = (RXCLK_INV) ? RXCLK_P : RXCLK_N;
    // RXCLK O output from IBUFGDS_DIFF_OUT (p)
    wire rxclk_out_p;
    // RXCLK O output from IBUFGDS_DIFF_OUT (n)
    wire rxclk_out_n;
    // RXCLK out of MMCM
    wire rxclk;
    // 2x RXCLK out of MMCM
    wire rxclk_x2;
    // MMCM is locked
    wire rxclk_locked;
    
    // RXCLK path    
    IBUFGDS_DIFF_OUT #(.IBUF_LOW_PWR("FALSE"))
        u_rxclk(.I(rxclk_in_p),.IB(rxclk_in_n),.O(rxclk_out_p),.OB(rxclk_out_n));
    // Just use the damn MMCM base directly
    // The math we use here is to run it at 1 GHz.
    // So CLKFBOUT_MULT_F is 8
    //    CLKIN1_PERIOD is 8.000
    //    CLKOUT1_DIVIDE is 8
    //    CLKOUT2_DIVIDE is 4
    //    CLKOUT0_DIVIDE_F is 8

    // RXCLK feedback output to bufg
    wire rxclk_fb_to_bufg;
    // RXCLK feedback bufg
    wire rxclk_fb_bufg;
    // RXCLK main output (positive)
    wire rxclk_to_bufg_p;
    // RXCLK main output (negative)
    wire rxclk_to_bufg_n;
    // RXCLK main output (correct pol)
    wire rxclk_to_bufg = (RXCLK_INV) ? rxclk_to_bufg_n : rxclk_to_bufg;
    // RXCLKx2 main output (positive)
    wire rxclk_x2_to_bufg_p;
    // RXCLKx2 main output (negative)
    wire rxclk_x2_to_bufg_n;
    // RXCLKx2 main output (correct pol)
    wire rxclk_x2_to_bufg = (RXCLK_INV) ? rxclk_x2_to_bufg_n : rxclk_x2_to_bufg_p;
    BUFG u_rxclk_fb(.I(rxclk_fb_to_bufg),.O(rxclk_fb_bufg));
    BUFG u_rxclk_bufg(.I(rxclk_to_bufg),.O(rxclk));
    BUFG u_rxclk_x2_bufg(.I(rxclk_x2_to_bufg),.O(rxclk_x2));
    MMCME2_BASE #(.CLKFBOUT_MULT_F(8.000),
                  .CLKFBOUT_PHASE(0.000),
                  .CLKIN1_PERIOD(8.000),
                  .CLKOUT1_DIVIDE(4),
                  .CLKOUT0_DIVIDE_F(8.000))
        u_rxclk_mmcm(.CLKIN1(rxclk_out_p),
                     .CLKFBIN(rxclk_fb_bufg),
                     .PWRDWN(1'b0),
                     .CLKFBOUT(rxclk_fb_to_bufg),
                     .CLKOUT0(rxclk_to_bufg_p),
                     .CLKOUT0B(rxclk_to_bufg_n),
                     .CLKOUT1(rxclk_x2_to_bufg_p),
                     .CLKOUT1B(rxclk_x2_to_bufg_n),
                     .LOCKED(rxclk_locked));
    
//    turf_rxclk_clkwiz u_rxclk_wiz(.clk_in1(rxclk_in),.reset(1'b0),
//                                  .clk_out1(rxclk),
//                                  .clk_out2(rxclk_x2),
//                                  .locked(rxclk_locked)); 
    // CIN positive inputs to IBUFDS_DIFF_OUT
    wire cin_in_p = (CIN_INV) ? CIN_N : CIN_P;
    // CIN negative inputs to IBUFDS_DIFF_OUT
    wire cin_in_n = (CIN_INV) ? CIN_P : CIN_N;
    // CIN positive output from IBUFDS_DIFF_OUT
    wire cin_out_p;
    // CIN negative output from IBUFDS_DIFF_OUT
    wire cin_out_n;
    // Correct polarity CIN signal
    wire cin_out = (CIN_INV) ? cin_out_n : cin_out_p;
    // CIN out of IDELAY
    wire cin_delayed;
    // CIN idelay value
    wire [5:0] cin_idelay_value = dat_in_static[5:0];
    // Current CIN delay value
    wire [5:0] cin_idelay_current;
    // Load CIN value.
    wire       do_cin_idelay_load = rxclk_waiting_flag_rxclk &&
                                    adr_in_static == 6'h4 &&
                                    we_in_static;
    // Bitslip the ISERDES
    wire       do_cin_bitslip = rxclk_waiting_flag_rxclk &&
                                adr_in_static == 6'hC &&
                                we_in_static;
                                
    // Current clock output of the ISERDES.
    // We need to grab *all* 32 because it's the only real way to ensure that
    // the value being captured is correct. Our error tester only actually
    // checks that the pattern repeats, not that it's correct.
    // Annoyingly we're not actually going to use this for the proper deserialization
    // because we want to have the fewest number of bits cross to the SYSCLK domain.
    //
    // Note: we *might* want to look into using the IO_FIFOs as they'll almost get
    // us entirely to full deserialization. The only question is whether or not
    // they'll be synchronous enough.
    // (Technically they might be able to do the whole damn thing, using
    //  2x 4-bit inputs to expand to 16 total bits and then 4x 4 bit inputs to expand
    // to the full 32 bits). That would require extremely clever control signaling
    // and timing however.
    reg [27:0] cin_history = {28{1'b0}};
    wire [7:0] cin_parallel;
    reg [31:0] cin_parallel_capture = {32{1'b0}};
    always @(posedge rxclk) if (rxclk_waiting_flag_rxclk &&
                                adr_in_static == 6'hC) cin_parallel_capture <= { cin_parallel[3:0], cin_history };
    // Shifts need to be right shifts. Data
    // comes out:
    // 0 1 2 3 4 5 6 7
    // 6 9 9 6 a 5 5 a
    // so to put it back the same way (0xA55A6996) we need to shift as:
    // 0 6xxxxxxx
    // 1 96xxxxxx
    // 2 996xxxxx
    // 3 6996xxxx
    // 4 a6996xxx
    // 5 5a6996xx
    // 6 55a6996x
    // 7 a55a6996
    always @(posedge rxclk) begin
        cin_history[24 +: 4] <= cin_parallel[3:0];
        cin_history[20 +: 4] <= cin_history[24 +: 4];
        cin_history[16 +: 4] <= cin_history[20 +: 4];
        cin_history[12 +: 4] <= cin_history[16 +: 4];
        cin_history[8 +: 4] <= cin_history[12 +: 4];
        cin_history[4 +: 4] <= cin_history[8 +: 4];
        cin_history[0 +: 4] <= cin_history[4 +: 4];
    end 
    // Delayed version of the output of the ISERDES, for bit-error testing.
    wire [3:0] cin_parallel_delayed;
    // Bit error generation.
    wire       cin_bit_error = (cin_parallel[3:0] != cin_parallel_delayed[3:0]);
    srlvec #(.NBITS(4)) u_cin_srl(.clk(rxclk),
                                  .ce(1'b1),
                                  .a(4'h7),
                                  .din(cin_parallel[3:0]),
                                  .dout(cin_parallel_delayed));    
    // Bit error testing. This sucks a bit because we have to have holding registers
    // both here and in wb_clk.
    wire [24:0] bit_error_count;
    wire        bit_error_count_valid;
    wire        bit_error_count_valid_wbclk;
    flag_sync   u_bit_error_count_valid_sync(.clkA(rxclk),.clkB(wb_clk_i),
                                             .in_clkA(bit_error_count_valid),
                                             .out_clkB(bit_error_count_valid_wbclk));
    reg [24:0]  bit_error_count_reg = {25{1'b0}};
    always @(posedge rxclk) if (bit_error_count_valid) bit_error_count_reg <= bit_error_count;
    reg [24:0]  bit_error_count_wbclk = {25{1'b0}};
    always @(posedge wb_clk_i) if (bit_error_count_valid_wbclk) bit_error_count_wbclk <= bit_error_count_reg;
        
    dsp_timed_counter u_rxclk_biterr( .clk(rxclk),
                                      .count_in(cin_bit_error),
                                      .interval_in(dat_in_static[23:0]),
                                      .interval_load( rxclk_waiting_flag_rxclk &&
                                                      adr_in_static == 6'h8 &&
                                                      we_in_static ),
                                      .count_out(bit_error_count),
                                      .count_out_valid(bit_error_count_valid));

    // Reset ISERDES
    wire       cin_iserdes_reset;
        
    // CIN path        
    IBUFDS_DIFF_OUT #(.IBUF_LOW_PWR("FALSE"))
        u_cin_ibuf(.I(cin_in_p),.IB(cin_in_n),.O(cin_out_p),.OB(cin_out_n));
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"))
             u_cin_idelay(.C(rxclk),
                          .LD(do_cin_idelay_load),
                          .CNTVALUEIN(cin_idelay_value),
                          .CNTVALUEOUT(cin_idelay_current),
                          .IDATAIN(cin_out),
                          .DATAOUT(cin_delayed));
    // ISERDES uses network-type byte order, meaning the first in time is the MSB bit.
    // OSERDES is opposite that (LSB is first out)
    // In UltraScale they are BOTH LSB is first in.
    // So that means we need to flop the ISERDES here.
    // We also use the TOP bits (which... we're not supposed to) because they still
    // actually do work to do an 8-fold deserialization over 2 clock periods.
    ISERDESE2 #(.INTERFACE_TYPE("NETWORKING"),
                .DATA_RATE("DDR"),
                .DATA_WIDTH(4),
                .IOBDELAY("IFD"),
                .NUM_CE(1))
        u_cin_iserdes(.BITSLIP(do_cin_bitslip),
                      .CE1(1'b1),
                      .CLK(rxclk_x2),
                      .CLKB(~rxclk_x2),
                      .CLKDIV(rxclk),
                      .RST(cin_iserdes_reset),
                      .DDLY(cin_delayed),
                      .Q1(cin_parallel[3]),
                      .Q2(cin_parallel[2]),
                      .Q3(cin_parallel[1]),
                      .Q4(cin_parallel[0]),
                      .Q5(cin_parallel[7]),
                      .Q6(cin_parallel[6]),
                      .Q7(cin_parallel[5]),
                      .Q8(cin_parallel[4]));

    // COUT positive output from OBUFDS
    wire couttio_out_p;
    // COUT negative output from OBUFDS
    wire couttio_out_n;
    // Assign correct polarity
    assign COUTTIO_P = (COUTTIO_INV) ? couttio_out_n : couttio_out_p;
    assign COUTTIO_N = (COUTTIO_INV) ? couttio_out_p : couttio_out_n;

    // just terminate COUT right now        
    OBUFDS u_couttio_obuf(.I(1'b0),.O(couttio_out_p),.OB(couttio_out_n));


    // TXCLK positive output from OBUFDS
    wire txclk_out_p;
    // TXCLK negative output from OBUFDS
    wire txclk_out_n;
    // TXCLK input to OBUFDS
    wire txclk_in;
    // Assign correct polarity
    assign TXCLK_P = (TXCLK_INV) ? txclk_out_n : txclk_out_p;
    assign TXCLK_N = (TXCLK_INV) ? txclk_out_p : txclk_out_n;
    
    // This clock selection is not right, it should be sysclk based
    ODDR #(.DDR_CLK_EDGE("SAME_EDGE"),.INIT(TXCLK_INV),.SRTYPE("SYNC"))
        u_txclk_oddr(.C(rxclk),
                     .CE(1'b1),
                     .D1(~TXCLK_INV),
                     .D2(TXCLK_INV),
                     .R(1'b0),
                     .S(1'b0),
                     .Q(txclk_in));
    OBUFDS u_txclk_obuf(.I(txclk_in),.O(txclk_out_p),.OB(txclk_out_n));

                                            
//    // OK, Vio time:
//    // cin_idelay_load
//    // cin_idelay_value    
//    // cin_iserdes_reset
//    // cin_bitslip
//    // cin_idelay_current (input)
//    // 4 out 1 in
//    turf_vio u_vio(.clk(rxclk),
//                   .probe_in0(cin_idelay_current),
//                   .probe_out0(cin_bitslip),
//                   .probe_out1(cin_iserdes_reset),
//                   .probe_out2(cin_idelay_load),
//                   .probe_out3(cin_idelay_value));
    // and ILA (4 bit only)
    turf_ila u_ila(.clk(rxclk),
                   .probe0(cin_parallel),
                   .probe1(cin_bit_error));                   

    // Interface logic
    localparam FSM_BITS=2;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] ACK = 1;
    localparam [FSM_BITS-1:0] WAIT_ACK_RXCLK = 2;
    localparam [FSM_BITS-1:0] WAIT_ACK_SYSCLK = 3;
    reg [FSM_BITS-1:0] state = IDLE;
    
    assign rxclk_waiting = (state == WAIT_ACK_RXCLK);
    assign sysclk_waiting = (state == WAIT_ACK_SYSCLK);
    
    always @(posedge wb_clk_i) begin        
        if (wb_cyc_i && wb_stb_i) begin
            // stupid, but whatever
            if (wb_sel_i[0]) dat_in_static[7:0] <= wb_dat_i[7:0];
            if (wb_sel_i[1]) dat_in_static[15:8] <= wb_dat_i[15:8];
            if (wb_sel_i[2]) dat_in_static[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) dat_in_static[31:24] <= wb_dat_i[31:24];
            adr_in_static <= wb_adr_i;
            we_in_static <= wb_we_i;
        end

        if (wb_rst_i) state <= IDLE;
        else begin
            case (state)
                IDLE:   if (wb_cyc_i && wb_stb_i) begin
                            if (rxclk_access) state <= WAIT_ACK_RXCLK;
                            else if (sysclk_access) state <= WAIT_ACK_SYSCLK;
                            else state <= ACK;
                        end
                ACK: state <= IDLE;
                WAIT_ACK_RXCLK: if (rxclk_ack_flag_wbclk || !rxclk_ok_i) state <= ACK;
                WAIT_ACK_SYSCLK: if (sysclk_ack_flag_wbclk || !sysclk_ok_i) state <= ACK;
            endcase
        end
    
        if (state == WAIT_ACK_RXCLK) begin
            if (rxclk_ack_flag_wbclk) begin
                if (wb_adr_i == 6'h4) dat_reg <= cin_idelay_current;
                else if (wb_adr_i == 6'h8) dat_reg <= bit_error_count_wbclk;
                else if (wb_adr_i == 6'hC) dat_reg <= cin_parallel_capture;
            end else if (!rxclk_ok_i) begin
                dat_reg <= {32{1'b1}};
            end
        end else if (state == WAIT_ACK_SYSCLK) begin
            if (!sysclk_ok_i) dat_reg <= {32{1'b1}};
            else dat_reg <= {32{1'b0}};
        end
    end            

    assign wb_dat_o = dat_reg;
    assign wb_ack_o = (state == ACK);
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;

    assign rxclk_o = rxclk;
    assign rxclk_x2_o = rxclk_x2;
                   
endmodule
