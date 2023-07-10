`timescale 1ns / 1ps
// Clock sync handler and counter.
module turfio_sync_sysclk_count(
        input sysclk_i,
        // N.B.: Sync offset needs a bit of fiddly-ness to find the right value.
        // It actually is "delay minus 1" and resets the phase counter to 0,
        // and it won't trip sync_o until the *next* phase after it.
        input [7:0] sync_offset_i,
        input       en_ext_sync_i,
        // this is the value that the clock will reset to
        input [7:0] clock_offset_i,
        
        output [47:0] sysclk_count_o,
        
        input       sync_req_i,
        output      sync_o,
        output      dbg_surf_clk_o,
        output      SYNC
    );
    
    (* CUSTOM_CC = "TO_SYSCLK" *)
    reg [5:0] sync_offset_resync = {6{1'b0}};
    (* CUSTOM_CC = "TO_SYSCLK" *)
    reg [7:0] clk_offset_resync = {8{1'b0}};
    (* CUSTOM_CC = "TO_SYSCLK" *)
    reg [1:0] en_ext_sync_resync = 0;
        
    wire      do_sync_out;
    reg [4:0] clk_phase_counter = {4{1'b0}};

    (* USE_DSP = "TRUE" *)
    reg [47:0] sysclk_counter = {48{1'b0}};

    // The SYNC stuff absolutely needs to be properly timed.
    // Unfortunately the stupid datasheet doesn't specify offset
    // requirements... so we have to make them up! Just assume
    // 2 ns/2 ns setup/hold is okay and see if we can hit it??

    // Timing-wise the way it works is that we need to go LOW
    // for 4+ clocks and then HIGH such that 4 clocks AFTER we go
    // high is the SYNC cycle.
    
    // Therefore we want to go high in clock 11 and *conditioned*
    // on clock 10. It will be captured by clock 12, propagate on
    // 13, 14, and 15, and the clocks will restart synchronized to
    // clock 0.
    (* IOB = "TRUE" *)
    reg ext_sync = 1;

    reg sync_done = 0;

    // This is a mimic of the SURF clock so we can compare.
    (* IOB = "TRUE" *)        
    reg dbg_surf_clk = 0;
    
    always @(posedge sysclk_i) begin
        if (do_sync_out) sysclk_counter <= { {40{1'b0}}, clk_offset_resync };
        else sysclk_counter <= sysclk_counter + 1;

        if (do_sync_out) clk_phase_counter <= {4{1'b0}};
        else clk_phase_counter <= clk_phase_counter[3:0] + 1;        

        sync_offset_resync <= sync_offset_i;
        clk_offset_resync <= clock_offset_i;
        en_ext_sync_resync <= {en_ext_sync_resync[0], en_ext_sync_i };
        
        if (!en_ext_sync_resync[1]) sync_done <= 1'b0;
        else if (en_ext_sync_resync[1] && (clk_phase_counter[4:0] == 0)) sync_done <= 1'b1;

        if (clk_phase_counter[3:0] == 4'h0 && !sync_done) ext_sync <= 1'b0;
        else if (clk_phase_counter[3:0] == 10) ext_sync <= 1'b1;
        
        // SURF clock is designed to be high clocks 0-7 and low 8-15
        if (clk_phase_counter[3:0] == 15) dbg_surf_clk <= 1'b1;
        else if (clk_phase_counter[3:0] == 7) dbg_surf_clk <= 1'b0;
    end
    
    SRLC32E u_syncdelay(.D(sync_req_i),
                       .CE(1'b1),
                       .CLK(sysclk_i),
                       .A(sync_offset_resync[0 +: 5]),
                       .Q(do_sync_out));

    
    assign sync_o = clk_phase_counter[4];
    assign sysclk_count_o = sysclk_counter;
    assign SYNC = ext_sync;
    assign dbg_surf_clk_o = dbg_surf_clk;
endmodule
