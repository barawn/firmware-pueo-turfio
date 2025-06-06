`timescale 1ns / 1ps
// v2: cleanup naming, remove TXCLK
module surf_cout_phy_v2 #(parameter COUT_INV = 1'b0,
                       parameter DOUT_INV = 1'b0,
                       parameter DEBUG = "FALSE")(
        input sysclk_i,                       
        input sysclk_x2_i,
        input sync_i,
        input dout_sync_i,
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
        output [3:0] cout_o,
        output [7:0] dout_o,

        input COUT_P,
        input COUT_N,
        input DOUT_P,
        input DOUT_N
    );
    
    wire [7:0] cout_parallel;
    wire [7:0] dout_parallel;
    // handle the automatic inversions
    wire cout_norm, cout_inv;
    wire dout_norm, dout_inv;
    wire cout, dout, txclk;
    wire cout_dly, dout_dly, txclk_dly;

    // This is reregistered and driven into reset
    // by iserdes_rst_i and pulled out of reset
    // by dout_sync_i to make sure that each time
    // we reset, it's still being done relative
    // to the same 2 clock cycle. I have *no idea*
    // if this is necessary but who TF knows
    // how bitslipping works.
    reg iserdes_reset = 0;   
    always @(posedge sysclk_i) begin
        if (iserdes_rst_i) iserdes_reset <= 1;
        else if (dout_sync_i) iserdes_reset <= 0;
    end 
    
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
                               .RST(iserdes_reset),
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
                .DATA_WIDTH(4),
                .IOBDELAY("IFD"),
                .NUM_CE(1))
                u_dout_iserdes(.BITSLIP(iserdes_dout_bitslip_i),
                               .CLK(sysclk_x2_i),
                               .CLKB(~sysclk_x2_i),
                               .CLKDIV(sysclk_i),
                               .RST(iserdes_reset),
                               .DDLY(dout_dly),
                               .Q1(dout_parallel[3]),
                               .Q2(dout_parallel[2]),
                               .Q3(dout_parallel[1]),
                               .Q4(dout_parallel[0]),
                               .Q5(dout_parallel[7]),
                               .Q6(dout_parallel[6]),
                               .Q7(dout_parallel[5]),
                               .Q8(dout_parallel[4]));                

    // in our first clock, we get the low 4 bits
    // then in the second clock we get the high 4 bits
    reg [3:0] dout_history = {4{1'b0}};
    reg [7:0] dout_store = {8{1'b0}};
    always @(posedge sysclk_i) begin
        dout_history <= dout_parallel[3:0];
        // we will need to check if this results in nybble-aligned data or misaligned
        if (dout_sync_i) dout_store <= { dout_parallel[3:0], dout_history };
    end

    generate
        if (DEBUG == "TRUE") begin : DBG
            surf_cout_phy_ila u_ila(.clk(sysclk_i),
                                    .probe0(cout_o),
                                    .probe1(dout_parallel[3:0]),
                                    .probe2(sync_i),
                                    .probe3(dout_sync_i),
                                    .probe4(dout_store)
                                    );
        end
    endgenerate
    
    assign cout_o = cout_parallel[3:0];
    assign dout_o = dout_store;        
endmodule
