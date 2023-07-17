`timescale 1ns / 1ps
// dumb dumb testing
module turf_cout_interface_tb;

    reg sysclk = 0;
    reg sysclk_x2 = 0;
    always #2 sysclk_x2 <= ~sysclk_x2;
    always #4 sysclk <= ~sysclk;
    
    reg rst = 0;
    reg train = 1;
    reg sync = 0;
    reg [31:0] response = {32{1'b0}};
    reg [27:0] surf_response = {28{1'b0}};
    
    wire [6:0] T_COUT_P;
    wire [6:0] T_COUT_N;
    wire COUTTIO_P;
    wire COUTTIO_N;
    wire TXCLK_P;
    wire TXCLK_N;
    
    turf_cout_interface uut( .sysclk_i(sysclk),
                             .sysclk_x2_i(sysclk_x2),
                             .oserdes_rst_i(rst),
                             .train_i(train),
                             .sync_i(sync),
                             .response_i(response),
                             .surf_response_i(surf_response),
                             .T_COUT_P(T_COUT_P),
                             .T_COUT_N(T_COUT_N),
                             .COUTTIO_P(COUTTIO_P),
                             .COUTTIO_N(COUTTIO_N),
                             .TXCLK_P(TXCLK_P),
                             .TXCLK_N(TXCLK_N));

    initial begin
    end

endmodule
