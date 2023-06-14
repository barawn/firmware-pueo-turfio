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
// register 0x0C: CIN SYSCLK bit error control and readback
// register 0x10: CIN value capture and bitslip control
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

    // just kill the WB side interface for now
    assign ack_o = wb_cyc_i && wb_stb_i;
    assign dat_o = {32{1'b0}};
    assign err_o = 1'b0;
    assign rty_o = 1'b0;

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
    IBUFGDS_DIFF_OUT u_rxclk(.I(rxclk_in_p),.IB(rxclk_in_n),.O(rxclk_out_p),.OB(rxclk_out_n));
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
    wire [5:0] cin_idelay_value;
    // Current CIN delay value
    wire [5:0] cin_idelay_current;
    // Load CIN idelay
    wire       cin_idelay_load;
    // reregistered load
    reg        cin_idelay_load_rereg = 0;
    // flag
    wire       do_cin_idelay_load = cin_idelay_load && !cin_idelay_load_rereg;    
    // Bitslip the ISERDES
    wire       cin_bitslip;
    // reregistered
    reg        cin_bitslip_rereg = 0;
    // flag
    wire       do_cin_bitslip = cin_bitslip && !cin_bitslip_rereg;    
    // Current clock output of the ISERDES
    wire [3:0] cin_parallel;
    // Delayed version of the output of the ISERDES, for bit-error testing.
    wire [3:0] cin_parallel_delayed;
    // Bit error generation.
    wire       cin_bit_error = (cin_parallel != cin_parallel_delayed);
    srlvec #(.NBITS(4)) u_cin_srl(.clk(rxclk),
                                  .ce(1'b1),
                                  .a(4'h7),
                                  .din(cin_parallel),
                                  .dout(cin_parallel_delayed));    

    // Reset ISERDES
    wire       cin_iserdes_reset;
    
    always @(posedge rxclk) begin
        cin_idelay_load_rereg <= cin_idelay_load;
        cin_bitslip_rereg <= cin_bitslip;
    end
    
    // CIN path        
    IBUFDS_DIFF_OUT u_cin_ibuf(.I(cin_in_p),.IB(cin_in_n),.O(cin_out_p),.OB(cin_out_n));
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"))
             u_cin_idelay(.C(rxclk),
                          .LD(cin_idelay_load),
                          .CNTVALUEIN(cin_idelay_value),
                          .CNTVALUEOUT(cin_idelay_current),
                          .IDATAIN(cin_out),
                          .DATAOUT(cin_delayed));
    // ISERDES uses network-type byte order, meaning the first in time is the MSB bit.
    // OSERDES is opposite that (LSB is first out)
    // In UltraScale they are BOTH LSB is first in.
    // So that means we need to flop the ISERDES here.
    ISERDESE2 #(.INTERFACE_TYPE("NETWORKING"),
                .DATA_RATE("DDR"),
                .DATA_WIDTH(4),
                .IOBDELAY("IFD"),
                .NUM_CE(1))
        u_cin_iserdes(.BITSLIP(cin_bitslip),
                      .CE1(1'b1),
                      .CLK(rxclk_x2),
                      .CLKB(~rxclk_x2),
                      .CLKDIV(rxclk),
                      .RST(cin_iserdes_reset),
                      .DDLY(cin_delayed),
                      .Q1(cin_parallel[3]),
                      .Q2(cin_parallel[2]),
                      .Q3(cin_parallel[1]),
                      .Q4(cin_parallel[0]));

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

                                            
    // OK, Vio time:
    // cin_idelay_load
    // cin_idelay_value    
    // cin_iserdes_reset
    // cin_bitslip
    // cin_idelay_current (input)
    // 4 out 1 in
    turf_vio u_vio(.clk(rxclk),
                   .probe_in0(cin_idelay_current),
                   .probe_out0(cin_bitslip),
                   .probe_out1(cin_iserdes_reset),
                   .probe_out2(cin_idelay_load),
                   .probe_out3(cin_idelay_value));
    // and ILA (4 bit only)
    turf_ila u_ila(.clk(rxclk),
                   .probe0(cin_parallel),
                   .probe1(cin_bit_error));                   

    assign rxclk_o = rxclk;
    assign rxclk_x2_o = rxclk_x2;
                   
endmodule
