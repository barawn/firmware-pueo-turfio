`timescale 1ns / 1ps
// This merges all the biterr count crap into one module.
module register_core_biterr_counter #(parameter RCLK_TYPE = "NONE",
                                      parameter DCLK_TYPE = "NONE")(
        // Register core-side clock
        input rclk_i,
        // Destination (biterr) side clock
        input dclk_i,
        // Error indicator.
        input err_dclk_i,
        // Count interval. Needs to be static when load interval goes
        input [23:0] interval_i,
        // Load interval. Needs to be a flag in dclk
        input interval_load_i,
        // Output value. Static in rclk.
        output [24:0] error_count_o
    );
    
    // Output from dsp_timed_counter. In dclk.
    wire [24:0] error_count_dclk;
    // Error count is valid. In dclk.
    wire        error_count_valid_dclk;
    // Register so we can turn it into a flag.
    reg         error_count_valid_seen_dclk = 0;
    // Valid flag in dclk.
    wire        error_count_valid_flag_dclk = (error_count_valid_dclk && !error_count_valid_seen_dclk);
    // Acknowledge flag back in dclk.
    wire        error_count_ack_flag_dclk;
    
    // Valid flag in rclk.
    wire        error_count_valid_flag_rclk;
    // Storage in rclk.
    (* CUSTOM_CC_DST = RCLK_TYPE *)
    reg [24:0]  error_count_rclk = {25{1'b0}};
    
    always @(posedge rclk_i) begin
        if (error_count_valid_flag_rclk)
            error_count_rclk <= error_count_dclk;
    end
    
    always @(posedge dclk_i) begin
        error_count_valid_seen_dclk <= error_count_valid_dclk;
    end
    
    flag_sync u_valid_sync(.clkA(dclk_i),.clkB(rclk_i),
                           .in_clkA(error_count_valid_flag_dclk),
                           .out_clkB(error_count_valid_flag_rclk));

    flag_sync u_ack_sync(.clkA(rclk_i),.clkB(dclk_i),
                         .in_clkA(error_count_valid_flag_rclk),
                         .out_clkB(error_count_ack_flag_dclk));

    dsp_timed_counter #(.MODE("ACKNOWLEDGE"),
                        .CLKTYPE_DST(DCLK_TYPE),
                        .CLKTYPE_SRC(DCLK_TYPE))
        u_counter(  .clk(dclk_i),
                    .rst(error_count_ack_flag_dclk),
                    .count_in(err_dclk_i),
                    .interval_in(interval_i),
                    .interval_load(interval_load_i),
                    .count_out(error_count_dclk),
                    .count_out_valid(error_count_valid_dclk));                        
    
endmodule
