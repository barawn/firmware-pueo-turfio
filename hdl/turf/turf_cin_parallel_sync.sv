`timescale 1ns / 1ps
`include "turfio_debug.vh"

// Take the 4-bit CIN input and expand it out to 32 bits. We also take
// controls for enabling alignment. Actual alignment to the specific
// 7.8125 MHz period happens upstream of this.
//
// The "lock" here just locks to the 32-bit CIN sequence, which never
// needs an adjustment. The sync alignment (which resets clock counters, etc.)
// happens upstream of this and DOES need adjustment.
module turf_cin_parallel_sync(
        // System clock
        input sysclk_i,
        // Parallel unaligned 4-bit input stream
        input [3:0] cin_i,
        // reset
        input rst_i,
        // Instruct this module to execute a capture
        // even though we're unaligned.
        input capture_i,
        // Lock onto the next correct training sequence
        // and keep it going.
        input lock_i,
        output locked_o,
        
        output [31:0] cin_parallel_o,
        output        cin_parallel_valid_o,
        
        output cin_biterr_o
    );
    
    parameter [31:0] TRAIN_SEQUENCE = 32'hA55A6996;
    parameter DEBUG = `TURF_CIN_PARALLEL_SYNC_DEBUG;
    
    reg [27:0] cin_history = {28{1'b0}};
    wire [31:0] current_cin = { cin_i, cin_history };
    reg [31:0] cin_capture = {32{1'b0}};
    reg enable_capture = 0;
    wire do_cin_capture = enable_capture || capture_i;
    reg enable_lock = 0;
    reg locked = 0;
    reg [3:0] sysclk_sequence = {4{1'b0}};
    // SYNCHRONIZATION
    // We have an 8-clock sequence, so the way this works is:
    //
    // clk  current_cin     enable_lock locked  sysclk_sequence enable_capture  cin_capture
    // 7    TRAIN_SEQUENCE  1           0       0               0               X
    // 0    X               1           1       0               0               X
    // 1    X               1           1       1               0               X
    // 2    X               1           1       2               0               X
    // 3    X               1           1       3               0               X
    // 4    X               1           1       4               0               X
    // 5    X               1           1       5               0               X
    // 6    X               1           1       6               0               X
    // 7    TRAIN_SEQUENCE  1           1       7               1               X
    // 0    X               1           1       8               0               TRAIN_SEQUENCE
    //
    // We delay the locked input because it doesn't matter and it simplifies the counter.
    // It's just a delay so we can use an SRL with address set to 7 for it.

    // BIT ERROR TESTING
    wire [3:0] cin_delayed;
    // Bit error generation. We use the bottom bits of cin_history to reduce
    // loading, since they feed nothing except the capture register. Now
    // of course they've got an extra load, but whatever. We mainly wanted
    // to get away from the input registers since they're special.
    reg cin_biterr = 0;
    assign     cin_biterr_o = cin_biterr;
    srlvec #(.NBITS(4)) u_cin_srl(.clk(sysclk_i),
                                  .ce(1'b1),
                                  .a(4'h7),
                                  .din(cin_history[3:0]),
                                  .dout(cin_delayed));    
    
    // data comes out least-significant nybble first so shift
    // RIGHT.        
    always @(posedge sysclk_i) begin
        if (rst_i) enable_lock <= 1'b0;
        else if (lock_i) enable_lock <= 1'b1;
    
        cin_history[24 +: 4] <= cin_i[3:0];
        cin_history[20 +: 4] <= cin_history[24 +: 4];
        cin_history[16 +: 4] <= cin_history[20 +: 4];
        cin_history[12 +: 4] <= cin_history[16 +: 4];
        cin_history[8 +: 4] <= cin_history[12 +: 4];
        cin_history[4 +: 4] <= cin_history[8 +: 4];
        cin_history[0 +: 4] <= cin_history[4 +: 4];        

        if (rst_i) locked <= 1'b0;
        else if (enable_lock && current_cin == TRAIN_SEQUENCE) locked <= 1'b1;
        
        enable_capture <= sysclk_sequence == 4'h6;        

        if (!locked) sysclk_sequence <= 4'h0;
        else sysclk_sequence <= sysclk_sequence[2:0] + 1;
        
        if (do_cin_capture) begin
            cin_capture <= current_cin;
        end
        
        // cin biterrs only count when we're not locked, because that
        // allows us to turn off the training pattern. Saves some power.
        if (locked) cin_biterr <= 1'b0;
        else cin_biterr <= (cin_history[3:0] != cin_delayed[3:0]);    
    end
    
    generate
        if (DEBUG == "TRUE") begin : ILA
            turf_cin_ila u_ila(.clk(sysclk_i),
                               .probe0(enable_lock),
                               .probe1(locked),
                               .probe2(cin_history[24 +: 4]),
                               .probe3(do_cin_capture),
                               .probe4(cin_parallel_o),
                               .probe5(cin_parallel_valid_o),
                               .probe6(cin_biterr));
        end
    endgenerate
    
    // this is just for status reporting, the top bit of sysclk_sequence will always
    // only go whenever everything's good. A reset immediately kills the counter.
    assign locked_o = locked;
    assign cin_parallel_valid_o = sysclk_sequence[3];
    assign cin_parallel_o = cin_capture;
    
endmodule
