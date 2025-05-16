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
    wire [4:0] cntdelay_P = idelay_value_i[5] ? {5{1'b1}} : idelay_value_i[4:0];
    wire [4:0] cntdelay_N = idelay_value_i[5] ? idelay_value_i[4:0] : {5{1'b0}};
    wire [4:0] cntvalueout_P;
    wire [4:0] cntvalueout_N;
    assign idelay_value_o[5] = cntvalueout_P == {5{1'b1}};
    assign idelay_value_o[4:0] = (idelay_value_o[5]) ? cntvalueout_N : cntvalueout_P;    
    
    wire [7:0] cin_parallel;        

    // CIN ISERDES wires
    // CIN positive inputs to IBUFDS_DIFF_OUT
    wire cin_in_p = (CIN_INV) ? CIN_N : CIN_P;
    // CIN negative inputs to IBUFDS_DIFF_OUT
    wire cin_in_n = (CIN_INV) ? CIN_P : CIN_N;
    // Output from IBUF.
    wire cin;
    // From M IDELAY.
    wire cin_idelay_m;
    // From S IDELAY.
    wire cin_idelay_s;

    IBUFDS u_ibuf(.I(cin_in_p), .IB(cin_in_n),.O(cin) );    
    (* CUSTOM_CC_DST = "RXCLK", CUSTOM_CC_SRC = "RXCLK" *)
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"),
               .IS_IDATAIN_INVERTED(CIN_INV),               
               .DELAY_SRC("IDATAIN"))
             u_cin_idelaym(.C(rxclk_i),
                          .LD(idelay_load_i),
                          .CNTVALUEIN(cntdelay_P),
                          .CNTVALUEOUT(cntvalueout_P),
                          .IDATAIN(cin),
                          .DATAOUT(cin_idelay_m));
    (* CUSTOM_CC_DST = "RXCLK", CUSTOM_CC_SRC = "RXCLK" *)
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"),
               .DELAY_SRC("DATAIN"))
             u_cin_idelays(.C(rxclk_i),
                           .LD(idelay_load_i),
                           .CNTVALUEIN(cntdelay_N),
                           .CNTVALUEOUT(cntvalueout_N),
                           .DATAIN(cin_idelay_m),
                           .DATAOUT(cin_idelay_s));
    // ISERDES uses network-type byte order, meaning the first in time is the MSB bit.
    // OSERDES is opposite that (LSB is first out)
    // In UltraScale they are BOTH LSB is first in.
    // So that means we need to flop the ISERDES here.
    // We also use the TOP bits (which... we're not supposed to) because they still
    // actually do work to do an 8-fold deserialization over 2 clock periods.
    // just a destination (bitslip)
    (* CUSTOM_CC_DST = "RXCLK" *)
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
                      .DDLY(cin_idelay_s),
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
