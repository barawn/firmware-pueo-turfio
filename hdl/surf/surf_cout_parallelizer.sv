`timescale 1ns / 1ps
module surf_cout_parallelizer #(parameter DEBUG = "FALSE")(
        // System clock.
        input sysclk_i,
        // 16-clock global period.
        input sync_i,        
        // Capture request. This actually just stores the data.
        input capture_i,
        // capture completed
        input captured_i,
        // enabled (turns off biterr)
        input enable_i,
        // Input data from iserdes
        input [3:0] cout_i,
        // Parallel output data to the register core.
        output [31:0] cout_parallel_o,
        // bit error output
        output biterr_o
    );
    // NO IDEA    
    localparam [3:0] SYNC_OFFSET = 4;
    localparam [3:0] SYNC_HALF = 7;
    reg [27:0] cout_history = {28{1'b0}};
    (* CUSTOM_CC_SRC = "SYSCLK" *)
    reg [31:0] cout_capture = {32{1'b0}};

    reg cout_biterr = 0;
    wire [3:0] cout_delayed;
    srlvec #(.NBITS(4)) u_cin_srl(.clk(sysclk_i),
                                  .ce(1'b1),
                                  .a(4'h7),
                                  .din(cout_history[3:0]),
                                  .dout(cout_delayed));        

    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg capture_hold = 0;    
    // instead of creating an actual 8 clock sequence we just delay sync 2x and offset by 8
    wire sync_delayed;
    wire sync_half_delayed;
    reg sync_half = 0;
    SRL16E u_sync_delay(.D(sync_i),
                        .A0(SYNC_OFFSET[0]),
                        .A1(SYNC_OFFSET[1]),
                        .A2(SYNC_OFFSET[2]),
                        .A3(SYNC_OFFSET[3]),
                        .CE(1'b1),
                        .CLK(sysclk_i),
                        .Q(sync_delayed));
    SRL16E u_synchalf_delay(.D(sync_delayed),
                            .A0(SYNC_HALF[0]),
                            .A1(SYNC_HALF[1]),
                            .A2(SYNC_HALF[2]),
                            .A3(SYNC_HALF[3]),
                            .CE(1'b1),
                            .CLK(sysclk_i),
                            .Q(sync_half_delayed));       
    always @(posedge sysclk_i) begin
        if (enable_i) cout_biterr <= 0;
        else cout_biterr <= (cout_history[3:0] != cout_delayed);
        
        sync_half <= sync_half_delayed;
        if (captured_i) capture_hold <= 0;
        else if (capture_i) capture_hold <= 1;
        
        cout_history[24 +: 4] <= cout_i;
        cout_history[20 +: 4] <= cout_history[24 +: 4];
        cout_history[16 +: 4] <= cout_history[20 +: 4];
        cout_history[12 +: 4] <= cout_history[16 +: 4];
        cout_history[8 +: 4] <= cout_history[12 +: 4];
        cout_history[4 +: 4] <= cout_history[8 +: 4];
        cout_history[0 +: 4] <= cout_history[4 +: 4];
        if ((sync_delayed || sync_half) && !capture_hold)
            cout_capture <= {cout_i, cout_history};
    end
    
    // ILA:
    // cout_history,cout_i
    // sync_delayed
    // sync_half
    // capture_hold
    // cout_biterr
    generate
        if (DEBUG == "TRUE") begin : ILA
            wire [31:0] cout_to_capture = {cout_i, cout_history};
            surfcout_ila u_ila(.clk(sysclk_i),
                               .probe0( cout_to_capture ),
                               .probe1( sync_delayed ),
                               .probe2( sync_half ),
                               .probe3( capture_hold ),
                               .probe4( cout_biterr ));
        end
    endgenerate        
    
    assign cout_o = cout_i;
    assign cout_parallel_o = cout_capture;
    assign biterr_o = cout_biterr;
endmodule
