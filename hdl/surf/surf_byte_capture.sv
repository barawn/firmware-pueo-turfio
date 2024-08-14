`timescale 1ns / 1ps
// This dumb module captures for both the DOUT and RESP (old TXCLK) path.
// We technically don't NEED to sync, but if we do, the various bitslips and
// such should be more stable maybe? I dunno?
// 
// This handles both the DOUT and RESP paths.
module surf_byte_capture(
        input sysclk_i,
        input sync_i,
        input dout_capture_i,
        input dout_enable_i,
        input [7:0] dout_i,

        input resp_capture_i,
        input resp_enable_i,
        input [7:0] resp_i,
        
        output [7:0] dout_o,
        output dout_valid_o,
        output dout_biterr_o,
        output [7:0] resp_o,
        output resp_valid_o,
        output resp_biterr_o
    );
    
    reg capture = 0;
    always @(posedge sysclk_i) if (sync_i) capture <= 1'b0; else capture <= ~capture;
    
    // this ALSO goes to the register core after a capture
    (* CUSTOM_CC_SRC = "SYSCLK" *)    
    reg [7:0] dout_store = {8{1'b0}};
    (* CUSTOM_CC_SRC = "SYSCLK" *)
    reg [7:0] resp_store = {8{1'b0}};

    wire dout_enable_delay;
    SRL16E u_dout_en_delay(.D(dout_enable_i),
			.CE(1'b1),
			.CLK(clk),
			.A0(1'b1),
			.A1(1'b1),
			.A2(1'b1),
			.A3(1'b1),
			.Q(dout_enable_delay));
    wire resp_enable_delay;			
    SRL16E u_resp_en_delay(.D(resp_enable_i),
			.CE(1'b1),
			.CLK(clk),
			.A0(1'b1),
			.A1(1'b1),
			.A2(1'b1),
			.A3(1'b1),
			.Q(resp_enable_delay));

    // these are for bit error testing    
    reg dout_biterr = 0;
    wire [7:0] dout_history;
    srlvec #(.NBITS(8)) u_dout_srl(.clk(sysclk_i),
                                  .ce(~dout_enable_i),
                                  .a(4'h1),
                                  .din(dout_i),
                                  .dout(dout_history));    
    reg resp_biterr = 0;
    wire [7:0] resp_history;
    srlvec #(.NBITS(8)) u_resp_srl(.clk(sysclk_i),
                                   .ce(~resp_enable_i),
                                   .a(4'h1),
                                   .din(resp_i),
                                   .dout(resp_history));
        
    // these aren't actually async registers: they're flags qualified
    // by already-static values, so they just need a standard delay
        
    // reregister dout_capture_i since it's a flag and our cycle is 2 clocks long
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg       dout_capture_rereg = 0;
    // reregister resp_capture_i since it's a flag and our cycle is 2 clocks long
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg       resp_capture_rereg = 0;
    
    // this is the clock enable for dout store
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg       dout_ce = 0;
    // clock enable for resp store
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg       resp_ce = 0;
    
    // this runs only when dout_enable is on
    reg       dout_valid = 0;
    // this runs only when resp_enable is on
    reg       resp_valid = 0;
    
    always @(posedge sysclk_i) begin
        if (~dout_enable_i && ~dout_enable_delay) dout_biterr <= (dout_history != dout_i);
        if (~resp_enable_i && ~resp_enable_delay) resp_biterr <= (resp_history != resp_i);

        dout_capture_rereg <= dout_capture_i;
        resp_capture_rereg <= resp_capture_i;
        // ok, now this is a bit tricky. We need to make sure that dout_ce is always
        // synced relative to capture, but dout_capture_i/dout_enable_i can turn on at any time.
        // first consider if dout_capture_i/dout_enable_i turn on when capture is high.
        // Just have it catch ~capture.
        // capture          dout_capture_i  dout_capture_rereg  dout_enable_i   dout_ce
        // 0                0               0                   0               0
        // 1                1               0                   0               0
        // 0                0               1                   0               0
        // 1                0               0                   0               1  <-- due to dout_capture_rereg
        // Now consider if it turns on when capture is low.
        // 0                0               0                   0               0
        // 1                0               0                   0               0
        // 0                1               0                   0               0
        // 1                0               1                   0               1  <-- due to dout_capture_rereg
        // 0                0               0                   0               0  <-- due to capture        
        // Just treat this as a 4-input capture.
        dout_ce <= (dout_capture_rereg || dout_capture_i || dout_enable_i) && ~capture;
        resp_ce <= (resp_capture_rereg || resp_capture_i || resp_enable_i) && ~capture;
        
        if (dout_ce) dout_store <= dout_i;
        if (resp_ce) resp_store <= resp_i;        
    end        

    assign dout_biterr_o = dout_biterr;
    assign resp_biterr_o = resp_biterr;
    assign dout_o = dout_store;
    assign resp_o = resp_store;
    
endmodule
