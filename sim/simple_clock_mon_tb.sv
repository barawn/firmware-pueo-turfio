`timescale 1ns / 1ps
module simple_clock_mon_tb;
    wire ifclk;
    wire [1:0] clks_to_mon;
    tb_rclk #(.PERIOD(5.00)) u_clk0(.clk(clks_to_mon[0]));
    tb_rclk #(.PERIOD(7.14)) u_clk1(.clk(clks_to_mon[1]));
    tb_rclk #(.PERIOD(25.00)) u_ifclk(.clk(ifclk));
    
    reg en = 0;
    reg wr = 0;
    reg [0:0] adr = 1'b0;
    reg [31:0] data_in = {32{1'b0}};
    wire ack;
    wire [31:0] data_out;
    
    simple_clock_mon #(.NUM_CLOCKS(2))
        u_monitor( .clk_i(ifclk),
                   .en_i(en),
                   .wr_i(wr),
                   .adr_i(adr),
                   .ack_o(ack),
                   .dat_i(data_in),
                   .dat_o(data_out),
                   .clk_mon_i(clks_to_mon));

    initial begin
        #100;
        // calibrate clock = 16,620,966
        @(posedge ifclk); #1;
        en = 1;
        wr = 1;
        data_in = 32'd16620966;
        @(posedge ifclk); #1;
        // ack is high here
        @(posedge ifclk); #1;
        en = 0;
        wr = 0;
        data_in = {32{1'b0}};
        #4000000;
        @(posedge ifclk); #1;
        en = 1;
        adr = 0;
        @(posedge ifclk); #1;
        // ack is high
        @(posedge ifclk); #1;
        en = 0;
    end                         

endmodule
