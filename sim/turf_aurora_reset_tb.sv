`timescale 1ns / 1ps
module turf_aurora_reset_tb;

    wire init_clk;
    tb_rclk #(.PERIOD(12.5)) u_initclk(.clk(init_clk));
    wire user_clk_fr;
    wire user_clk;
    tb_rclk #(.PERIOD(6.4)) u_userclk(.clk(user_clk_fr));
    
    wire gt_reset;
    wire sys_reset;
    
    reg [3:0] gt_userclk_holdoff = 4'h0;
    always @(posedge user_clk_fr) begin
        #1 gt_userclk_holdoff <= { gt_userclk_holdoff[2:0], gt_reset };
    end
    assign user_clk = user_clk_fr && !gt_userclk_holdoff[3];
        
    reg reset = 0;
    turf_aurora_reset #(.SIM_SPEEDUP("TRUE")) uut(.reset_i(reset),
                          .gt_reset_i(1'b0), // doesn't do anything anyway
                          .user_clk_i(user_clk),
                          .init_clk_i(init_clk),
                          .system_reset_o(sys_reset),
                          .gt_reset_o(gt_reset));

    initial begin
        #5000;
        @(posedge init_clk); #1 reset <= 1'b1; @(posedge init_clk); #1 reset <= 1'b0;                          
    end
    
endmodule
