`timescale 1ns / 1ps
// This module handles the clock-crossing tasks for the register cores.
//
// The way this works is that when a rising edge on waiting_rclk_i is seen,
// it sends a flag to dclk. That flag (along with static conditions) is
// used to perform the access on the dclk side.
// That flag is then reregistered (so still a flag) and sent back to
// rclk to acknowledge that the task is done.
// This ONLY WORKS for single-cycle tasks, but that's mostly what we do.
module register_core_cc_task(
        // Register core-side clock
        input rclk_i,
        // Destination clock
        input dclk_i,
        // Waiting indicator from register core side
        input waiting_rclk_i,
        // Flag indicating that we've signaled waiting
        output waiting_rclk_o,
        // Flag indicating that a wait is in progress
        output waiting_dclk_o,
        // Flag indicating that the access is complete
        output acknowledge_rclk_o        
    );
    
    reg waiting_seen_rclk = 0;
    assign waiting_rclk_o = (waiting_rclk_i) && !waiting_seen_rclk;
    reg ack_in_dclk = 0;
    
    always @(posedge rclk_i)
        waiting_seen_rclk <= waiting_rclk_i;
        
    always @(posedge dclk_i)
        ack_in_dclk <= waiting_dclk_o;
        
    flag_sync u_waiting_sync(.clkA(rclk_i),.clkB(dclk_i),
                             .in_clkA(waiting_rclk_o),
                             .out_clkB(waiting_dclk_o));
    flag_sync u_ack_sync(.clkA(dclk_i),.clkB(rclk_i),
                         .in_clkA(ack_in_dclk),
                         .out_clkB(acknowledge_rclk_o));    
endmodule
