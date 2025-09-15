`timescale 1ns / 1ps
`include "interfaces.vh"
// first attempt at the SURFbridge.
// I just need to get this working
// This currently only handles mode 0. To handle mode 1
// we need an AXI4-Stream output for each SURF
module surf_bridge #(parameter [6:0] RACKCTL_INV=7'h00,
                     parameter WB_CLK_TYPE = "INITCLK",
                     parameter DEBUG = "FALSE")(
        input                       wb_clk_i,
        input                       wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(  gtp_ , 25, 32 ),
        input [2:0]                 gtp_select_i,
        `TARGET_NAMED_PORTS_WB_IF(  dbg_ , 25, 32 ),
        input [2:0]                 dbg_select_i,
        output [6:0]                bridge_err_o,
        input                       err_rst_i,
        // add axi4-stream outputs here
        input                       sysclk_i,
        input                       sysclk_ok_i,
        inout [6:0]                 RACKCTL_P,
        inout [6:0]                 RACKCTL_N
    );

    wire [31:0] muxed_gtp_dat[7:0];
    wire [7:0] muxed_gtp_ack;
    wire [7:0] muxed_gtp_rty;
    wire [7:0] muxed_gtp_err;
    
    wire [31:0] muxed_dbg_dat[7:0];
    wire [7:0] muxed_dbg_ack;
    wire [7:0] muxed_dbg_rty;
    wire [7:0] muxed_dbg_err;

    // this doesn't actually matter, just give them valid values
    // synthesis should be able to figure out these conditions can't happen.    
    assign muxed_gtp_dat[0] = muxed_gtp_dat[4];
    assign muxed_dbg_dat[0] = muxed_dbg_dat[4];
    assign muxed_gtp_ack[0] = muxed_gtp_ack[4];
    assign muxed_dbg_ack[0] = muxed_dbg_ack[4];
    assign muxed_gtp_rty[0] = muxed_gtp_rty[4];
    assign muxed_dbg_rty[0] = muxed_dbg_rty[4];
    assign muxed_gtp_err[0] = muxed_gtp_err[4];
    assign muxed_dbg_err[0] = muxed_dbg_err[4];

    generate
        genvar i;
        for (i=0;i<7;i=i+1) begin : SF
            `DEFINE_WB_IF( sgtp_ , 22, 32 );
            `DEFINE_WB_IF( sdbg_ , 22, 32 );
            assign sgtp_cyc_o = gtp_cyc_i && (gtp_select_i == i + 1);
            assign sgtp_stb_o = gtp_stb_i;
            assign sgtp_we_o = gtp_we_i;
            assign sgtp_sel_o = gtp_sel_i;
            assign sgtp_dat_o = gtp_dat_i;
            assign sgtp_adr_o = gtp_adr_i[21:0];
            assign muxed_gtp_dat[i+1] = sgtp_dat_i;
            assign muxed_gtp_ack[i+1] = sgtp_ack_i;
            assign muxed_gtp_err[i+1] = sgtp_err_i;
            assign muxed_gtp_rty[i+1] = sgtp_rty_i;
            
            assign sdbg_cyc_o = dbg_cyc_i && (dbg_select_i == i + 1);
            assign sdbg_stb_o = dbg_stb_i;
            assign sdbg_we_o = dbg_we_i;
            assign sdbg_sel_o = dbg_sel_i;
            assign sdbg_dat_o = dbg_dat_i;
            assign sdbg_adr_o = dbg_adr_i[21:0];
            assign muxed_dbg_dat[i+1] = sdbg_dat_i;
            assign muxed_dbg_ack[i+1] = sdbg_ack_i;
            assign muxed_dbg_rty[i+1] = sdbg_rty_i;
            assign muxed_dbg_err[i+1] = sdbg_err_i;
            
            `DEFINE_AXI4S_MIN_IF( scmd_ , 8 );
            wire scmd_tlast;
            assign scmd_tready = 1'b1;
            
            rackctl_wb_bridge #(.INV(RACKCTL_INV[i]),
                                .DEBUG((i==6 || i == 0) ? "PHY" : "FALSE"),
                                // sleazy sleazy
                                .USE_IDELAY( (i>3) ? "TRUE" : "FALSE" ),
                                .IDELAY_VALUE(18),
                                .WB_CLK_TYPE(WB_CLK_TYPE))
                u_bridge(.wb_clk_i(wb_clk_i),
                         .wb_rst_i(wb_rst_i),
                         `CONNECT_WBS_IFM( gtp_ , sgtp_ ),
                         `CONNECT_WBS_IFM( dbg_ , sdbg_ ),
                         .bridge_err_o(bridge_err_o[i]),
                         .err_rst_i(err_rst_i),
                         .sysclk_i(sysclk_i),
                         .sysclk_ok_i(sysclk_ok_i),
                         `CONNECT_AXI4S_MIN_IF( m_cmd_ , scmd_ ),
                         .m_cmd_tlast(scmd_tlast),
                         .mode_i(1'b0),
                         .RACKCTL_P(RACKCTL_P[i]),
                         .RACKCTL_N(RACKCTL_N[i]));
        end
    endgenerate
    
    assign gtp_dat_o = muxed_gtp_dat[gtp_select_i];
    assign gtp_ack_o = muxed_gtp_ack[gtp_select_i];
    assign gtp_err_o = muxed_gtp_err[gtp_select_i];
    assign gtp_rty_o = muxed_gtp_rty[gtp_select_i];
    
    assign dbg_dat_o = muxed_dbg_dat[dbg_select_i];
    assign dbg_ack_o = muxed_dbg_ack[dbg_select_i];
    assign dbg_err_o = muxed_dbg_err[dbg_select_i];
    assign dbg_rty_o = muxed_dbg_rty[dbg_select_i];

    generate
        if (DEBUG == "TRUE") begin : ILA
            reg dbg_cycstb = 0;
            reg [2:0] dbg_select = {3{1'b0}};
            reg [21:0] dbg_addr = {22{1'b0}};
            reg [32:0] dbg_data = {32{1'b0}};
            reg dbg_ack = 0;
            always @(posedge wb_clk_i) begin : MX
                dbg_cycstb <= dbg_cyc_i && dbg_stb_i;
                dbg_select <= dbg_select_i;
                dbg_addr <= dbg_adr_i;
                if (dbg_we_i) dbg_data <= dbg_dat_i;
                else dbg_data <= dbg_dat_o;
                dbg_ack <= dbg_ack_o;
            end
            surfbridge_ila u_ila(.clk(wb_clk_i),
                                 .probe0(dbg_cycstb),
                                 .probe1(dbg_select),
                                 .probe2(dbg_addr),
                                 .probe3(dbg_data),
                                 .probe4(dbg_ack));
        end
    endgenerate    
endmodule
