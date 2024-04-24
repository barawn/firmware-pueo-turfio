`timescale 1ns / 1ps
`include "interfaces.vh"

// Very similar to TURF interface module.
module surf_interface #(parameter RXCLK_INV = 1'b0,
                        parameter TXCLK_INV = 1'b0,
                        parameter CIN_INV = 1'b0,
                        parameter COUT_INV = 1'b0,
                        parameter DOUT_INV = 1'b0,
                        parameter [31:0] TRAIN_SEQUENCE = 32'hA55A6996,
                        parameter WB_CLK_TYPE = "INITCLK",
                        parameter DEBUG = "FALSE")(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 6, 32),
        input sysclk_ok_i,
        input sysclk_i,
        input sysclk_x2_i,
        
        // just implement the clock for now, get things working
        output RXCLK_P,
        output RXCLK_N
    );

    reg ack_internal = 0;
    always @(posedge wb_clk_i) ack_internal <= wb_cyc_i && wb_stb_i;
    assign wb_ack_o = ack_internal && wb_cyc_i;
    assign wb_dat_o = {32{1'b0}};

    wire rxclk_in;
    ODDR #(.DDR_CLK_EDGE("SAME_EDGE"),.INIT(RXCLK_INV),.SRTYPE("SYNC"))
        u_rxclk_oddr(.C(sysclk_i),
                     .CE(1'b1),
                     .D1(~RXCLK_INV),
                     .D2(RXCLK_INV),
                     .R(1'b0),
                     .S(1'b0),
                     .Q(rxclk_in));
    obufds_autoinv #(.INV(RXCLK_INV)) u_rxclk(.I(rxclk_in),.O_P(RXCLK_P),.O_N(RXCLK_N));    

endmodule
