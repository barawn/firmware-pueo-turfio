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

        input COUT_P,
        input COUT_N,
        input TXCLK_P,
        input TXCLK_N,
        input DOUT_P,
        input DOUT_N,

                
        output CIN_P,
        output CIN_N,
        output RXCLK_P,
        output RXCLK_N
    );

    // IDELAY controls.
    wire idelay_load;
    wire idelay_dout_load;
    wire [5:0] idelay_value;
    wire [5:0] idelay_current;
    wire [5:0] idelay_dout_current;
    // ISERDES controls
    wire iserdes_rst;
    wire iserdes_bitslip;
    wire iserdes_dout_bitslip;
    // COUT data path. It needs a sync/lock.
    wire [31:0] cout_data;
    wire        cout_valid;
    wire cout_capture;
    wire cout_biterr;
    // DOUT data path. It only needs a run/no-run.
    wire [7:0] dout_data;
    wire       dout_valid;
    wire dout_capture;
    wire dout_biterr;
    wire dout_run;
            
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
                   
    surf_cout_interface #(.INV(COUT_INV),
                    .DOUT_INV(DOUT_INV),
                    .TXCLK_INV(TXCLK_INV),
                    .DEBUG(DEBUG))
        u_surf_coutif(.sysclk_i(sysclk_i),
                   .sysclk_x2_i(sysclk_x2_i),
                   .sync_i(sync_i),
                   
                   .iserdes_rst_i(iserdes_rst),
                   .iserdes_bitslip_i(iserdes_bitslip),
                   .iserdes_dout_bitslip_i(iserdes_dout_bitslip),
                   .idelay_value_i(idelay_value),
                   .idelay_load_i(idelay_load),
                   .idelay_dout_load_i(idelay_dout_load),
                   .idelay_current_o(idelay_current),
                   .idelay_dout_current_o(idelay_dout_current),
                   
                   .cout_data_o(cout_data),
                   .cout_valid_o(cout_valid),
                   .cout_capture_i(cout_capture),
                   .cout_biterr_o(cout_biterr),
                   
                   .dout_data_o(dout_data),
                   .dout_valid_o(dout_valid),
                   .dout_capture_i(dout_capture),
                   .dout_biterr_o(dout_biterr),
                                      
                   // the actual douts/couts come in a bit
                   .COUT_P(COUT_P),
                   .COUT_N(COUT_N),
                   .DOUT_P(DOUT_P),
                   .DOUT_N(DOUT_N),
                   .TXCLK_P(TXCLK_P),
                   .TXCLK_N(TXCLK_N));    

    // we're a slave inside a slave so we need WBS_IFS
    surfctl_register_core #(.WB_CLK_TYPE(WB_CLK_TYPE))
        u_core( .wb_clk_i(wb_clk_i),
                .wb_rst_i(wb_rst_i),
                `CONNECT_WBS_IFS(wb_ , wb_ ),
                .sysclk_ok_i(sysclk_ok_i),
                .sysclk_i(sysclk_i),
                
                .idelay_load_o(idelay_load),
                .idelay_dout_load_o(idelay_dout_load),
                .idelay_value_o(idelay_value),
                .idelay_current_i(idelay_current),
                .idelay_dout_current_i(idelay_dout_current),
                .iserdes_rst_o(iserdes_rst),
                .iserdes_bitslip_o(iserdes_bitslip),
                .iserdes_dout_bitslip_o(iserdes_dout_bitslip),
                .oserdes_rst_o(oserdes_rst),
                
                .cout_data_i(cout_data),
                .cout_capture_o(cout_capture),
                .cout_biterr_i(cout_biterr),
                .dout_data_i(dout_data),
                .dout_biterr_i(dout_biterr),
                .dout_capture_o(dout_capture),
                .cin_train_o(cin_train));

endmodule
