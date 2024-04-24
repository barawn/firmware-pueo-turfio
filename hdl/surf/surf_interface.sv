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
        
        input [31:0] command_i,
        input sync_i,
                
        output CIN_P,
        output CIN_N,
        output RXCLK_P,
        output RXCLK_N
    );

    // IDELAY controls.
    wire idelay_load;
    wire [5:0] idelay_value;
    wire [5:0] idelay_current;
    // ISERDES controls
    wire iserdes_rst;
    wire iserdes_bitslip;
    wire [31:0] cout_data;
    wire cout_capture;
    wire cout_biterr;
    // OSERDES controls
    wire oserdes_rst;
    wire cin_train;
    
    surf_cin_interface #(.CIN_INV(CIN_INV),
                         .RXCLK_INV(RXCLK_INV))
        u_surf_cin(.sysclk_i(sysclk_i),
                   .sysclk_x2_i(sysclk_x2_i),
                   .oserdes_rst_i(oserdes_rst),
                   .train_i(cin_train),
                   .sync_i(sync_i),
                   .command_i(command_i),
                   .CIN_P(CIN_P),
                   .CIN_N(CIN_N),
                   .RXCLK_P(RXCLK_P),
                   .RXCLK_N(RXCLK_N));

    // we're a slave inside a slave so we need WBS_IFS
    surfctl_register_core #(.WB_CLK_TYPE(WB_CLK_TYPE))
        u_core( .wb_clk_i(wb_clk_i),
                .wb_rst_i(wb_rst_i),
                `CONNECT_WBS_IFS(wb_ , wb_ ),
                .sysclk_ok_i(sysclk_ok_i),
                .sysclk_i(sysclk_i),
                
                .idelay_load_o(idelay_load),
                .idelay_value_o(idelay_value),
                .idelay_current_i(idelay_current),
                .iserdes_rst_o(iserdes_rst),
                .iserdes_bitslip_o(iserdes_bitsip),
                .oserdes_rst_o(oserdes_rst),
                
                .cout_data_i(cout_data),
                .cout_capture_o(cout_capture),
                .cout_biterr_i(cout_biterr),
                .cin_train_o(cin_train));

endmodule
