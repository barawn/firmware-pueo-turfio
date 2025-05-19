`timescale 1ns / 1ps
// The SURF live detector works by keeping track of the state of the COUTs and DOUTs
// from each SURF.
//
// The outputs from this feed into the autostartup module (used by the TURF brains)
//
// SURFs start off as not ready. We power on way faster than them so at startup this is good,
// and when SURFs detect loss of RXCLK they fall back into not ready anyway (at least this is the plan)
//
// When DOUT goes low, that's a train *in* request: as in, we have clocks, we're ready to train
// CIN.
// When COUT goes low, that's a train *out* request, as in, I've put my outputs into training,
// go ahead and lock on it.
// Obviously detecting COUT going low is actually "COUT is anything other than 0xF".
//
// Once we're at train out request and train_complete_i is set, we then wait for
// DOUT == 0x00 to set SURF live: however we need to go 0x6A -> 0x00. ANYTHING ELSE
// indicates a misalignment which gets flagged as surf_misaligned_o.
//
// trainin_req_o can autoswitch CIN to training mode if it's allowed (which it is by default)
//
// COUT/DOUT are in sysclk, but the actual statuses are generated in wbclk space because
// they interact with registers.
module surf_live_detector(
        input sys_clk_i,
        input sys_clk_ok_i,
        input wb_clk_i,
        // vector of all 7x4 = 28 COUT inputs
        input [27:0] cout_i,
        // vector of all 7x8 = 56 DOUT inputs
        input [55:0] dout_i,
        // train in request
        output [6:0] trainin_req_o,
        // train out ready
        output [6:0] trainout_rdy_o,
        // out train complete (from the autostart module, or just tied high)
        input [6:0] train_complete_i,
        // live indicator
        output [6:0] surf_live_o,
        // indicates we actually went
        // 0x6a (something other than 0) (zero)
        // probably 0x6A 0x6A 0x60.
        // this should never happen
        output [6:0] surf_misaligned_o        
    );
    
    parameter [7:0] DOUT_TRAIN = 8'h6A;
    
    // counter to kill SURF on COUT loss: 16 is fine, that's impossible
    // we use COUT rather than DOUT to go poof because DOUT can literally be basically anything
    parameter COUT_COUNTER = 16;
    parameter WBCLKTYPE = "NONE";
    parameter SYSCLKTYPE = "NONE";        
    generate
        genvar i;
        for (i=0;i<7;i=i+1) begin : SL
            reg boot_seen = 0;

            (* CUSTOM_CC_SRC = SYSCLKTYPE *)
            reg train_in_req = 0;
            (* CUSTOM_CC_DST = WBCLKTYPE, ASYNC_REG = "TRUE" *)
            reg [1:0] train_in_req_wbclk = {2{1'b0}};            

            (* CUSTOM_CC_SRC = SYSCLKTYPE *)
            reg train_out_rdy = 0;
            (* CUSTOM_CC_DST = WBCLKTYPE, ASYNC_REG = "TRUE" *)
            reg [1:0] train_out_rdy_wbclk = {2{1'b0}};
            
            (* CUSTOM_CC_SRC = SYSCLKTYPE *)
            reg surf_live = 0;
            
            (* CUSTOM_CC_DST = SYSCLKTYPE, ASYNC_REG = "TRUE" *)
            reg [1:0] surf_train_complete = 0;

            (* CUSTOM_CC_DST = WBCLKTYPE, ASYNC_REG = "TRUE" *)
            reg [1:0] surf_live_wbclk = {2{1'b0}};            

            (* CUSTOM_CC_SRC = SYSCLKTYPE *)
            reg surf_misaligned = 0;
            
            (* CUSTOM_CC_DST = WBCLKTYPE, ASYNC_REG = "TRUE" *)
            reg [1:0] surf_misaligned_wbclk = {2{1'b0}};

            wire dout_out_of_train = (surf_train_complete[1] && dout_i != DOUT_TRAIN);
            wire dout_is_null = (dout_i == {8{1'b0}});
            
            reg [4:0] cout_counter = {5{1'b0}};
            always @(posedge sys_clk_i) begin : LNR
                surf_train_complete <= { surf_train_complete[0], train_complete_i[i] };
            end
            always @(posedge sys_clk_i or negedge sys_clk_ok_i) begin : LWR
                if (!sys_clk_ok_i) surf_misaligned <= 0;
                else if (dout_out_of_train && !dout_is_null) surf_misaligned <= 1;
            
                // surf_live requires surf train complete and dout_out_of_train.
                // surf_live and !surf_misaligned means you can enable the DOUT interface.
                if (!sys_clk_ok_i) surf_live <= 0;
                else begin
                    if (cout_counter[4])
                        surf_live <= 0;
                    else if (surf_train_complete[1] && dout_out_of_train)
                        surf_live <= 1;
                end
                // this only matters at startup, it's a once-and-done
                if (!sys_clk_ok_i) boot_seen <= 0;
                else if (cout_counter[4]) boot_seen <= 1;
                                        
                if (!sys_clk_ok_i) cout_counter <= {5{1'b0}};
                else begin
                    if (surf_live || !boot_seen) begin
                        if (cout_i[4*i +: 4] == {4{1'b1}})
                            cout_counter <= cout_counter[3:0] + 1;
                        else
                            cout_counter <= {5{1'b0}};
                    end else begin
                        cout_counter <= {5{1'b0}};
                    end
                end
                
                // whenever we see DOUT drop after boot seen and !surf_live,
                // that's a training request. If the SURF comes live AFTER we're
                // already live we don't have to wait for boot seen because
                // surf_live dropping already counts as boot_seen
                // (it'd just set it again)
                if (!sys_clk_ok_i) train_in_req <= 0;
                else begin
                    if (cout_counter[4])
                        train_in_req <= 0;
                    else if (dout_i[8*i +: 8] == 8'h00 && boot_seen)
                        train_in_req <= 1;
                end                    
                // whenever we see COUT drop after we're in training, that's
                // train out ready.
                if (!sys_clk_ok_i) train_out_rdy <= 0;
                else begin
                    if (cout_counter[4]) 
                        train_out_rdy <= 0;
                    else if (train_in_req && cout_i[4*i +: 4] != {4{1'b1}}) 
                        train_out_rdy <= 1;
                end                    
            end
            
            always @(posedge wb_clk_i) begin
                train_in_req_wbclk <= { train_in_req_wbclk[0], train_in_req };
                train_out_rdy_wbclk <= { train_out_rdy_wbclk[0], train_out_rdy };
                surf_live_wbclk <= { surf_live_wbclk[0], surf_live };
                surf_misaligned_wbclk <= { surf_misaligned_wbclk[0], surf_misaligned };
            end
            assign trainin_req_o[i] = train_in_req_wbclk[1];
            assign trainout_rdy_o[i] = train_out_rdy_wbclk[1];
            assign surf_live_o[i] = surf_live_wbclk[1];
            assign surf_misaligned_o[i] = surf_misaligned_wbclk[1];
        end
    endgenerate

endmodule
