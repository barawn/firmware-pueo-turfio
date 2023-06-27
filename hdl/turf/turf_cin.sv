`timescale 1ns / 1ps
// TURF CIN infrastructure and support.
module turf_cin #(parameter CIN_INV = 1'b0)( input rxclk_i,
                 input rxclk_x2_i,
                 input idelay_load_i,
                 input [5:0] idelay_value_i,
                 output [5:0] idelay_value_o,
                 input iserdes_rst_i,
                 input iserdes_bitslip_i,                 
                 output [3:0] cin_o,
                 
                 input CIN_P,
                 input CIN_N
    );
    
    wire [7:0] cin_parallel;        

    // CIN ISERDES wires
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

    // CIN path        
    IBUFDS_DIFF_OUT #(.IBUF_LOW_PWR("FALSE"))
        u_cin_ibuf(.I(cin_in_p),.IB(cin_in_n),.O(cin_out_p),.OB(cin_out_n));
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"))
             u_cin_idelay(.C(rxclk_i),
                          .LD(idelay_load_i),
                          .CNTVALUEIN(idelay_value_i),
                          .CNTVALUEOUT(idelay_value_o),
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
        u_cin_iserdes(.BITSLIP(iserdes_bitslip_i),
                      .CE1(1'b1),
                      .CLK(rxclk_x2_i),
                      .CLKB(~rxclk_x2_i),
                      .CLKDIV(rxclk_i),
                      .RST(iserdes_rst_i),
                      .DDLY(cin_delayed),
                      .Q1(cin_parallel[3]),
                      .Q2(cin_parallel[2]),
                      .Q3(cin_parallel[1]),
                      .Q4(cin_parallel[0]),
                      .Q5(cin_parallel[7]),
                      .Q6(cin_parallel[6]),
                      .Q7(cin_parallel[5]),
                      .Q8(cin_parallel[4]));

    assign cin_o = cin_parallel[3:0];

endmodule
