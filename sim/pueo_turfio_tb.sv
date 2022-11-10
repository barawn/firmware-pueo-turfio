`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2022 10:39:56 PM
// Design Name: 
// Module Name: pueo_turfio_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pueo_turfio_tb;

    wire sysclk;
    wire sysclk_p = sysclk;
    wire sysclk_n = ~sysclk;
    tb_rclk #(.PERIOD(8.0)) u_sysclk(.clk(sysclk));
    wire initclk;
    tb_rclk #(.PERIOD(25.0)) u_initclk(.clk(initclk));
    
    wire LMKDATA;
    wire LMKCLK;
    wire LMKLE;
    wire LMKOE;
    wire CLK_SYNC;
    
    localparam NSURF = 1;
    wire [NSURF-1:0] RXCLK_P;
    wire [NSURF-1:0] RXCLK_N;
    wire [NSURF-1:0] CIN_P;
    wire [NSURF-1:0] CIN_N;
    pueo_turfio #(.SIMULATION("TRUE")) u_turfio( .INITCLK(initclk),
                                                 .CLKDIV2_P(sysclk_p),
                                                 .CLKDIV2_N(sysclk_n),
                                                 
                                                 .LMKDATA(LMKDATA),
                                                 .LMKCLK(LMKCLK),
                                                 .LMKLE(LMKLE),
                                                 .LMKOE(LMKOE),                                                 
                                                 .CLK_SYNC(CLK_SYNC),
                                                 
                                                 .RXCLK_P(RXCLK_P),
                                                 .RXCLK_N(RXCLK_N),
                                                 .CIN_P(CIN_P),
                                                 .CIN_N(CIN_N));                                                 

endmodule
