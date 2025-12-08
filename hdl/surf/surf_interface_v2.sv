`timescale 1ns / 1ps
`include "interfaces.vh"

// Very similar to TURF interface module.
module surf_interface_v2 #(parameter RXCLK_INV = 1'b0,
                        parameter CIN_INV = 1'b0,
                        parameter COUT_INV = 1'b0,
                        parameter DOUT_INV = 1'b0,
                        parameter [31:0] TRAIN_SEQUENCE = 32'hA55A6996,
                        parameter WB_CLK_TYPE = "INITCLK",
                        parameter SYS_CLK_TYPE = "SYSCLK",
                        parameter DEBUG = "FALSE")(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 6, 32),
        input sysclk_ok_i,
        input sysclk_i,
        input sysclk_x2_i,

        input disable_rxclk_i,
        input [3:0] cout_offset_i,
        
        input [23:0] rdholdoff_i,
        
        input [31:0] command_i,
        input sync_i,
        // masked SURF trigger input
        input trig_i,
        // global event stream reset
        input event_reset_i,
        // mask clock enable, just simplifies things
        input mask_ce_i,
        // when surf_live_i FALLS we force the serdes reset high again
        input surf_live_i,
        // when the automatic train enable is set up, enables training.
        input surf_autotrain_en_i,
        
        // these are for the surf live detector
        output [3:0] cout_o,
        output [7:0] dout_o,
        
        input COUT_P,
        input COUT_N,
        input DOUT_P,
        input DOUT_N,

        output dout_overflow_o,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_dout_ , 8 ),
        output m_dout_tlast,
                
        output CIN_P,
        output CIN_N,
        output RXCLK_P,
        output RXCLK_N
    );

    // IDELAY controls.
    wire idelay_cout_load;
    wire idelay_dout_load;
    wire [5:0] idelay_value;
    wire [5:0] idelay_cout_current;
    wire [5:0] idelay_dout_current;
    // ISERDES controls
    wire iserdes_rst;
    wire iserdes_cout_bitslip;
    wire iserdes_dout_bitslip;
    // COUT data path. It only needs an enable.
    wire [31:0] cout_data;
    wire        cout_valid;
    wire        cout_capture;
    wire        cout_captured;
    wire        cout_biterr;
    wire        cout_enable;
    // DOUT data path. It only needs an enable.
    wire [7:0]  dout_data;
    wire        dout_valid;
    // fake it into a stream
    `DEFINE_AXI4S_MIN_IF( surf_ , 8);
    assign surf_tdata = dout_data;
    assign surf_tvalid = dout_valid;
    
    
    wire        surf_mask;
    masked_dout_splice #(.DEBUG(DEBUG != "FALSE" ? "TRUE" : "FALSE"),
                         .CLKTYPE(SYS_CLK_TYPE))
                       u_splice( .aclk(sysclk_i),
                                 .aresetn( !event_reset_i ),
                                 .trig_i(trig_i),
                                 .rdholdoff_i(rdholdoff_i),
                                 .err_o(dout_overflow_o),
                                 .mask_i(surf_mask),
                                 .mask_ce_i(mask_ce_i),
                                 `CONNECT_AXI4S_MIN_IF( s_dout_ , surf_ ),
                                 `CONNECT_AXI4S_MIN_IF( m_dout_ , m_dout_ ),
                                 .m_dout_tlast(m_dout_tlast));
//    assign m_dout_tdata = dout_data;
//    assign m_dout_tvalid = dout_valid;
    
    
    
    wire        dout_capture;
    wire        dout_biterr;
    wire        dout_enable;
    wire        dout_capture_phase;
            
    // OSERDES controls
    wire oserdes_rst;
    wire cin_train;
    
    surf_cin_interface #(.CIN_INV(CIN_INV),
                         .RXCLK_INV(RXCLK_INV))
        u_surf_cin(.sysclk_i(sysclk_i),
                   .sysclk_x2_i(sysclk_x2_i),
                   .disable_rxclk_i(disable_rxclk_i),
                   .oserdes_rst_i(oserdes_rst),
                   .train_i(cin_train),
                   .sync_i(sync_i),
                   .command_i(command_i),
                   .CIN_P(CIN_P),
                   .CIN_N(CIN_N),
                   .RXCLK_P(RXCLK_P),
                   .RXCLK_N(RXCLK_N));
                   
    surf_cout_interface_v2 #(.COUT_INV(COUT_INV),
                    .DOUT_INV(DOUT_INV),
                    .DEBUG(DEBUG != "FALSE" ? "PHY" : "FALSE"))
        u_surf_coutif(.sysclk_i(sysclk_i),
                   .sysclk_x2_i(sysclk_x2_i),
                   .sync_i(sync_i),
                   
                   .iserdes_rst_i(iserdes_rst),
                   .iserdes_cout_bitslip_i(iserdes_cout_bitslip),
                   .iserdes_dout_bitslip_i(iserdes_dout_bitslip),
                   .idelay_value_i(idelay_value),
                   .idelay_cout_load_i(idelay_cout_load),
                   .idelay_dout_load_i(idelay_dout_load),
                   .idelay_cout_current_o(idelay_cout_current),
                   .idelay_dout_current_o(idelay_dout_current),

                   .cout_o(cout_o),
                   .dout_o(dout_o),
                   
                   .cout_data_o(cout_data),
                   .cout_valid_o(cout_valid),
                   .cout_capture_i(cout_capture),
                   .cout_captured_i(cout_captured),
                   .cout_biterr_o(cout_biterr),
                   .cout_offset_i(cout_offset_i),
                   
                   .dout_data_o(dout_data),
                   .dout_valid_o(dout_valid),
                   .dout_capture_i(dout_capture),
                   .dout_enable_i(dout_enable),
                   .dout_biterr_o(dout_biterr),
                   .dout_capture_phase_i(dout_capture_phase),
                                      
                   // the actual douts/couts come in a bit
                   .COUT_P(COUT_P),
                   .COUT_N(COUT_N),
                   .DOUT_P(DOUT_P),
                   .DOUT_N(DOUT_N));    

    // we're a slave inside a slave so we need WBS_IFS
    // clean up all this stuff
    surfctl_register_core_v2 #(.WB_CLK_TYPE(WB_CLK_TYPE))
        u_core( .wb_clk_i(wb_clk_i),
                .wb_rst_i(wb_rst_i),
                `CONNECT_WBS_IFS(wb_ , wb_ ),
                .sysclk_ok_i(sysclk_ok_i),
                .sysclk_i(sysclk_i),
                .surf_live_i(surf_live_i),
                .surf_autotrain_en_i(surf_autotrain_en_i),
                // IDELAYs are semicommon                
                .idelay_cout_load_o(idelay_cout_load),
                .idelay_dout_load_o(idelay_dout_load),
                .idelay_value_o(idelay_value),
                .idelay_cout_current_i(idelay_cout_current),
                .idelay_dout_current_i(idelay_dout_current),
                .iserdes_rst_o(iserdes_rst),
                .iserdes_cout_bitslip_o(iserdes_cout_bitslip),
                .iserdes_dout_bitslip_o(iserdes_dout_bitslip),
                .oserdes_rst_o(oserdes_rst),
                
                .cout_data_i(cout_data),
                .cout_capture_o(cout_capture),
                .cout_captured_o(cout_captured),
                .cout_biterr_i(cout_biterr),
                .cout_enable_o(cout_enable),
                
                .dout_data_i(dout_data),
                .dout_biterr_i(dout_biterr),
                .dout_capture_o(dout_capture),
                .dout_enable_o(dout_enable),
                .dout_capture_phase_o(dout_capture_phase),
                
                .mask_o(surf_mask),

                .cin_train_o(cin_train));

endmodule
