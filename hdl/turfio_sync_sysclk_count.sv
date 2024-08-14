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
    
    parameter DEBUG = "TRUE";
    
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg [5:0] sync_offset_resync = {6{1'b0}};
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg [7:0] clk_offset_resync = {8{1'b0}};
    (* CUSTOM_CC_DST = "SYSCLK" *)
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
    
    // OK, here's how this works:
    // do_sync_out resets the clock phase counter. When that happens
    // IF en_ext_sync_resync[1] is high AND sync_done is low, we LOWER ext_sync when do_sync_out occurs.
    // ext_sync can ALWAYS be raised by clk_phase_counter == 10
    // sync_done can then be set by do_sync_out AND en_ext_sync_resync[1]
    //
    // Timing diagram:
    // clk  en_ext_sync_resync[1]   sync_done   do_sync_out clk_phase_counter   ext_sync
    // 0    1                       0           0           3                   1
    // 1    1                       0           0           4                   1
    // 2    1                       0           1           5                   1
    // 3    1                       1           0           0                   0
    // 4    1                       1           0           1                   0
    // 5-12 1                       1           0           2..9                0
    // 13   1                       1           0           10                  0
    // 14   1                       1           0           11                  1
    // 15   1                       1           0           12                  1
    // 16   1                       1           0           13                  1
    // 17   1                       1           0           14                  1
    // 18   1                       1           0           15                  1
    // 19   1                       1           0           0                   1
    //
    // so again: logic is:
    // sync_done: lower if !en_ext_sync_resync[1], raise if (do_sync_out).
    // ext_sync: lower if do_sync_out && !sync_done
    //           raise on clk_phase_counter == 10
    // let's simplify logic on ext_sync: we'll create a register that'll go high in clk phase 10
    reg raise_ext_sync = 0;
    
    (* KEEP = "TRUE" *)
    reg dbg_ext_sync = 1;
        
    always @(posedge sysclk_i) begin
        if (do_sync_out) sysclk_counter <= { {40{1'b0}}, clk_offset_resync };
        else sysclk_counter <= sysclk_counter + 1;

        if (do_sync_out) clk_phase_counter <= {4{1'b0}};
        else clk_phase_counter <= clk_phase_counter[3:0] + 1;        

        sync_offset_resync <= sync_offset_i;
        clk_offset_resync <= clock_offset_i;
        en_ext_sync_resync <= {en_ext_sync_resync[0], en_ext_sync_i };
        
        if (!en_ext_sync_resync[1]) sync_done <= 1'b0;
        else if (do_sync_out) sync_done <= 1'b1;

        // Slight caveat here: if clk_phase_counter[3:0] is 9 the same clock do_sync_out
        // is high, then raise_ext_sync will go to 1 in the next clock, which is WRONG
        // so we caveat that here
        raise_ext_sync <= (clk_phase_counter[3:0] == 9) && !do_sync_out;
        
        if (do_sync_out && !sync_done && en_ext_sync_resync[1]) ext_sync <= 1'b0;
        else if (raise_ext_sync) ext_sync <= 1'b1;
        
        if (do_sync_out && !sync_done && en_ext_sync_resync[1]) dbg_ext_sync <= 1'b0;
        else if (raise_ext_sync) dbg_ext_sync <= 1'b1;
        
        // SURF clock is designed to be high clocks 0-7 and low 8-15
        if (clk_phase_counter[3:0] == 15) dbg_surf_clk <= 1'b1;
        else if (clk_phase_counter[3:0] == 7) dbg_surf_clk <= 1'b0;
    end
    
    SRLC32E u_syncdelay(.D(sync_req_i),
                       .CE(1'b1),
                       .CLK(sysclk_i),
                       .A(sync_offset_resync[0 +: 5]),
                       .Q(do_sync_out));

    generate
        if (DEBUG == "TRUE") begin : DBG
            sync_ila u_ila(.clk(sysclk_i),
                           .probe0(clk_phase_counter),
                           .probe1(en_ext_sync_resync[1]),
                           .probe2(sync_done),
                           .probe3(do_sync_out),
                           .probe4(dbg_ext_sync));
        end
    endgenerate
    // This is actually a flag, since the counter only runs the bottom 4 bits.
    assign sync_o = clk_phase_counter[4];
    assign sysclk_count_o = sysclk_counter;
    assign SYNC = ext_sync;
    assign dbg_surf_clk_o = dbg_surf_clk;
endmodule
