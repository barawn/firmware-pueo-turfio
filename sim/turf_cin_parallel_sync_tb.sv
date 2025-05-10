`timescale 1ns / 1ps

module turf_cin_parallel_sync_tb;

    wire clk;
    tb_rclk #(.PERIOD(8.0)) u_clk(.clk(clk));
    
    reg lock = 0;
    // this needs to go 6 9 9 6 A 5 5 A so you rotate down
    reg [31:0] cin_full = 32'hA55A6996;

    wire locked;
    wire [31:0] cin_parallel;
    wire cin_parallel_valid;
    
    turf_cin_parallel_sync uut(.sysclk_i(clk),
                               .cin_i(cin_full[3:0]),
                               .rst_i(1'b0),
                               .capture_i(1'b0),
                               .lock_i(lock),
                               .locked_o(locked),
                               .cin_parallel_o(cin_parallel),
                               .cin_parallel_valid_o(cin_parallel_valid));
    always @(posedge clk) begin
        cin_full <= #1 { cin_full[3:0], cin_full[31:4] };
    end
    
    initial begin
        #100;
        @(posedge clk);
        #1 lock = 1;
    end                               

endmodule
