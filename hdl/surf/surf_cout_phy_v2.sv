`timescale 1ns / 1ps
// v2: cleanup naming, remove TXCLK
module surf_cout_phy_v2 #(parameter COUT_INV = 1'b0,
                       parameter DOUT_INV = 1'b0,
                       parameter DEBUG = "FALSE")(
        input sysclk_i,                       
        input sysclk_x2_i,
                               
        // common reset
        input iserdes_rst_i,
        input iserdes_cout_bitslip_i,
        input iserdes_dout_bitslip_i,
        // common value
        input [4:0] idelay_value_i,        
        input idelay_cout_load_i,
        input idelay_dout_load_i,
        output [4:0] idelay_cout_current_o,
        output [4:0] idelay_dout_current_o,        

        // for COUT we output 4 bits, for DOUT we output all 8
        // and rando-capture
        output [3:0] cout_o,
        output [7:0] dout_o,

        input COUT_P,
        input COUT_N,
        input DOUT_P,
        input DOUT_N
    );
    
    wire [7:0] cout_parallel;
    // handle the automatic inversions
    wire cout_norm, cout_inv;
    wire dout_norm, dout_inv;
    wire cout, dout, txclk;
    wire cout_dly, dout_dly, txclk_dly;
    
    
    ibufds_autoinv #(.INV(COUT_INV)) u_cout(.I_P(COUT_P),.I_N(COUT_N),.O(cout_norm),.OB(cout_inv));
    ibufds_autoinv #(.INV(DOUT_INV)) u_dout(.I_P(DOUT_P),.I_N(DOUT_N),.O(dout_norm),.OB(dout_inv));
    
    assign cout = (COUT_INV == 1'b1) ? cout_inv : cout_norm;
    assign dout = (DOUT_INV == 1'b1) ? dout_inv : dout_norm;
    
    // these are both source and destination clock cross
    (* CUSTOM_CC_SRC = "SYSCLK", CUSTOM_CC_DST = "SYSCLK" *)
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"))
               u_cout_delay(.C(sysclk_i),
                            .LD(idelay_cout_load_i),
                            .CNTVALUEIN(idelay_value_i),
                            .CNTVALUEOUT(idelay_cout_current_o),
                            .IDATAIN(cout),
                            .DATAOUT(cout_dly));
    (* CUSTOM_CC_SRC = "SYSCLK", CUSTOM_CC_DST = "SYSCLK" *)                            
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"))
               u_dout_delay(.C(sysclk_i),
                            .LD(idelay_dout_load_i),
                            .CNTVALUEIN(idelay_value_i),
                            .CNTVALUEOUT(idelay_dout_current_o),
                            .IDATAIN(dout),
                            .DATAOUT(dout_dly));  
    // this is only a destination
    (* CUSTOM_CC_DST = "SYSCLK" *)
    ISERDESE2 #(.INTERFACE_TYPE("NETWORKING"),
                .DATA_RATE("DDR"),
                .DATA_WIDTH(4),
                .IOBDELAY("IFD"),
                .NUM_CE(1))
                u_cout_iserdes(.BITSLIP(iserdes_cout_bitslip_i),
                               .CLK(sysclk_x2_i),
                               .CLKB(~sysclk_x2_i),
                               .CLKDIV(sysclk_i),
                               .RST(iserdes_rst_i),
                               .DDLY(cout_dly),
                               .Q1(cout_parallel[3]),
                               .Q2(cout_parallel[2]),
                               .Q3(cout_parallel[1]),
                               .Q4(cout_parallel[0]),
                               .Q5(cout_parallel[7]),
                               .Q6(cout_parallel[6]),
                               .Q7(cout_parallel[5]),
                               .Q8(cout_parallel[4]));                
    (* CUSTOM_CC_DST = "SYSCLK" *)
    ISERDESE2 #(.INTERFACE_TYPE("NETWORKING"),
                .DATA_RATE("DDR"),
                .DATA_WIDTH(8),
                .IOBDELAY("IFD"),
                .NUM_CE(1))
                u_dout_iserdes(.BITSLIP(iserdes_dout_bitslip_i),
                               .CLK(sysclk_x2_i),
                               .CLKB(~sysclk_x2_i),
                               .CLKDIV(sysclk_i),
                               .RST(iserdes_rst_i),
                               .DDLY(dout_dly),
                               .Q1(dout_o[3]),
                               .Q2(dout_o[2]),
                               .Q3(dout_o[1]),
                               .Q4(dout_o[0]),
                               .Q5(dout_o[7]),
                               .Q6(dout_o[6]),
                               .Q7(dout_o[5]),
                               .Q8(dout_o[4]));                

    generate
        if (DEBUG == "TRUE") begin : DBG
            surf_cout_phy_ila u_ila(.clk(sysclk_i),.probe0(cout_o),.probe1(dout_o));
        end
    endgenerate
    
    assign cout_o = cout_parallel[3:0];
        
endmodule
