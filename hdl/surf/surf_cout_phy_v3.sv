`timescale 1ns / 1ps
// v3: double the IDELAYs so we have enough range to
//     equalize the delays on everyone.
//
// Stacking IDELAYs is a little complicated.
// First, because you're *adding* delays your total
// range is reduced (max you can delay by is 62 taps).
// Second because the values don't cascade, you need
// to forcibly deal with it yourself. We do this in a way
// to make it easier for firmware, harder for software.
// so if we have idelay_value_i[5:0]:
// cntvalueinA[4:0] = (idelay_value_i[5]) ? {4{1'b1}} : cntvalueinA[3:0];
// cntvalueinB[4:0] = (idelay_value_i[5]) ? cntvalueinA[3:0] : {4{1'b0}};
//
// this maps to
// idelay_value_i       cntvalueinA     cntvalueinB     total tap delay
// 0                    0               0               0
// ..
// 30                   30              0               30
// 31                   31              0               31
// 32                   31              0               31
// 33                   31              1               32
// ...
// so converting linear delay -> idelay_value in software is
// inval = (delay & 32) ? delay + 1 : delay;
//
// And then reversing it for idelay_dout_current_o is
// idelay_dout_current[5] = (cntvalueoutA == {4{1'b1}})
// idelay_dout_current[4:0] = (idelay_dout_current[5]) ? cntvalueoutB : cntvalueoutA;
//
//
// The other trick is that we always want to go DOWN, from P to N.
// This allows us to RLOC the two. This means the top will always
// connect to P regardless.
// So if DOUT_INV is 1, we need to hook DOUT_N to the P-side IDELAY.
module surf_cout_phy_v3 #(parameter COUT_INV = 1'b0,
                       parameter DOUT_INV = 1'b0,
                       parameter DEBUG = "FALSE")(
        input sysclk_i,                       
        input sysclk_x2_i,
        input sync_i,
        input dout_sync_i,
        input dout_capture_phase_i,
        // common reset
        input iserdes_rst_i,
        input iserdes_cout_bitslip_i,
        input iserdes_dout_bitslip_i,
        // common value
        input [5:0] idelay_value_i,        
        input idelay_cout_load_i,
        input idelay_dout_load_i,
        output [5:0] idelay_cout_current_o,
        output [5:0] idelay_dout_current_o,        

        // for COUT we output 4 bits, for DOUT we output all 8
        output [3:0] cout_o,
        output [7:0] dout_o,

        input COUT_P,
        input COUT_N,
        input DOUT_P,
        input DOUT_N
    );

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

    wire [4:0] dout_cntdelay_P = idelay_value_i[5] ? {5{1'b1}} : idelay_value_i[4:0];
    wire [4:0] dout_cntdelay_N = idelay_value_i[5] ? idelay_value_i[4:0] : {5{1'b0}};
    wire [4:0] dout_cntdelayout_P;
    wire [4:0] dout_cntdelayout_N;
    assign idelay_dout_current_o[5] = (dout_cntdelayout_P == {5{1'b1}});
    assign idelay_dout_current_o[4:0] = idelay_dout_current_o[5] ? dout_cntdelayout_N : dout_cntdelayout_P;    
    
    wire [7:0] cout_parallel;
    wire [7:0] dout_parallel;

    // ALWAYS use cout_norm to put it at the P-side.
    wire cout_norm, cout_inv;
    wire cout_dly_P;
    wire cout_dly;
    ibufds_autoinv #(.INV(COUT_INV)) u_cout(.I_P(COUT_P),.I_N(COUT_N),.O(cout_norm),.OB(cout_inv));
    
    // DOUT chain.
    wire dout_m = (DOUT_INV) ? DOUT_N : DOUT_P;
    wire dout_s = (DOUT_INV) ? DOUT_P : DOUT_N;
    wire dout_in;
    wire dout_dly_m;
    wire dout_dly_s;
    IBUFDS u_dout_ibuf(.I(dout_m),.IB(dout_s),.O(dout_in));
    (* CUSTOM_CC_SRC = "SYSCLK", CUSTOM_CC_DST = "SYSCLK" *)
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"),
               .IS_IDATAIN_INVERTED(DOUT_INV),
               .DELAY_SRC("IDATAIN"))
        u_doutdlyP( .C(sysclk_i),
                    .LD(idelay_dout_load_i),
                    .CNTVALUEIN(dout_cntdelay_P),
                    .CNTVALUEOUT(dout_cntdelayout_P),
                    .IDATAIN(dout_in),
                    .DATAOUT(dout_dly_m));
    (* CUSTOM_CC_SRC = "SYSCLK", CUSTOM_CC_DST = "SYSCLK" *)
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"),
               .DELAY_SRC("DATAIN"))
        u_doutdlyN( .C(sysclk_i),
                    .LD(idelay_dout_load_i),
                    .CNTVALUEIN(dout_cntdelay_N),
                    .CNTVALUEOUT(dout_cntdelayout_N),
                    .DATAIN(dout_dly_m),
                    .DATAOUT(dout_dly_s));
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
                               .DDLY(dout_dly_s),
                               .Q1(dout_parallel[3]),
                               .Q2(dout_parallel[2]),
                               .Q3(dout_parallel[1]),
                               .Q4(dout_parallel[0]),
                               .Q5(dout_parallel[7]),
                               .Q6(dout_parallel[6]),
                               .Q7(dout_parallel[5]),
                               .Q8(dout_parallel[4]));                

//    wire [4:0] dout_cntdelay_P = idelay_value_i[5] ? {5{1'b1}} : idelay_value_i[4:0];
//    wire [4:0] dout_cntdelay_N = idelay_value_i[5] ? idelay_value_i[4:0] : {5{1'b0}};
//    wire [4:0] dout_cntdelayout_P;
//    wire [4:0] dout_cntdelayout_N;
//    assign idelay_dout_current_o[5] = (dout_cntdelayout_P == {5{1'b1}});
//    assign idelay_dout_current_o[4:0] = idelay_dout_current_o[5] ? dout_cntdelayout_N : dout_cntdelayout_P;    
    wire [4:0] cout_cntdelay_P = idelay_value_i[5] ? {5{1'b1}} : idelay_value_i[4:0];
    wire [4:0] cout_cntdelay_N = idelay_value_i[5] ? idelay_value_i[4:0] : {5{1'b0}};
    wire [4:0] cout_cntdelayout_P;
    wire [4:0] cout_cntdelayout_N;
    assign idelay_cout_current_o[5] = (cout_cntdelayout_P == {5{1'b1}});
    assign idelay_cout_current_o[4:0] = idelay_cout_current_o[5] ? cout_cntdelayout_N : cout_cntdelayout_P;    
        
    // these are both source and destination clock cross
    (* CUSTOM_CC_SRC = "SYSCLK", CUSTOM_CC_DST = "SYSCLK" *)
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"),
               .IS_IDATAIN_INVERTED(COUT_INV))
             u_cout_delay_P(.C(sysclk_i),
                            .LD(idelay_cout_load_i),
                            .CNTVALUEIN(cout_cntdelay_P),
                            .CNTVALUEOUT(cout_cntdelayout_P),
                            .IDATAIN(cout_norm),
                            .DATAOUT(cout_dly_P));
    (* CUSTOM_CC_SRC = "SYSCLK", CUSTOM_CC_DST = "SYSCLK" *)
    IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"),
               .HIGH_PERFORMANCE_MODE("TRUE"),
               .DELAY_SRC("DATAIN"))
             u_cout_delay_N(.C(sysclk_i),
                            .LD(idelay_cout_load_i),
                            .CNTVALUEIN(cout_cntdelay_N),
                            .CNTVALUEOUT(cout_cntdelayout_N),
                            .DATAIN(cout_dly_P),
                            .DATAOUT(cout_dly));
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

    // in our first clock, we get the low 4 bits
    // then in the second clock we get the high 4 bits
    reg [3:0] dout_history = {4{1'b0}};
    reg [7:0] dout_store = {8{1'b0}};
    always @(posedge sysclk_i) begin
        dout_history <= dout_parallel[3:0];
        // we will need to check if this results in nybble-aligned data or misaligned
        if (dout_sync_i ^ dout_capture_phase_i) dout_store <= { dout_parallel[3:0], dout_history };
    end

    generate
        if (DEBUG == "TRUE") begin : DBG
            surf_cout_phy_ila u_ila(.clk(sysclk_i),
                                    .probe0(cout_o),
                                    .probe1(dout_parallel[3:0]),
                                    .probe2(sync_i),
                                    .probe3(dout_sync_i ^ dout_capture_phase_i),
                                    .probe4(dout_store)
                                    );
        end
    endgenerate
    
    assign cout_o = cout_parallel[3:0];
    assign dout_o = dout_store;        
endmodule
