`timescale 1ns / 1ps
`include "interfaces.vh"
`include "rackbus.vh"
// this thing is a mess, sigh
module surfturf_wrapper_v2 #(
        parameter T_RXCLK_INV = 1'b0,
        parameter T_TXCLK_INV = 1'b0,
        parameter [6:0] T_COUT_INV = 1'b0,
        parameter T_COUTTIO_INV = 1'b0,
        parameter T_CIN_INV = 1'b0,
        parameter [31:0] TRAIN_SEQUENCE = 32'hA55A6996,
        parameter WB_CLK_TYPE = "INITCLK",
        parameter [6:0] RXCLK_INV = {6{1'b0}},
        parameter [6:0] CIN_INV = {6{1'b0}},
        parameter [6:0] COUT_INV = {6{1'b0}},
        parameter [6:0] DOUT_INV = {6{1'b0}}
    )(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 12, 32),
        // local receive clock
        input sysclk_ok_i,
        input sysclk_i,
        input sysclk_x2_i,
        input sync_i,
        // turf-side receive clock
        input rxclk_ok_i,
        output rxclk_o,
        output rxclk_x2_o,
        // TURFIO input paths. These get spliced in,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( mode1_ , 8 ),
        input [1:0] mode1_tuser,
        // local TURFIO PPS, and its enable
        input tfio_pps_i,
        // this needs to go EVERYWHERE we swap between PPSes!!!
        input use_tfio_pps_i,        
        
        // turf outputs
        output          command_locked_o,
        output [31:0]   command_o,
        output          command_valid_o,
        // response inputs, I don't know if I'll ever use this
        input [31:0]    response_i,
        
        // datapaths. still in sysclk!!
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_s0_ , 8 ),
        output m_s0_tlast,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_s1_ , 8 ),
        output m_s1_tlast,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_s2_ , 8 ),
        output m_s2_tlast,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_s3_ , 8 ),
        output m_s3_tlast,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_s4_ , 8 ),
        output m_s4_tlast,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_s5_ , 8 ),
        output m_s5_tlast,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_s6_ , 8 ),
        output m_s6_tlast,
                
        // turf-side
        input T_RXCLK_P,
        input T_RXCLK_N,
        output T_TXCLK_P,
        output T_TXCLK_N,
        output [6:0] T_COUT_P,
        output [6:0] T_COUT_N,
        output T_COUTTIO_P,
        output T_COUTTIO_N,
        input T_CIN_P,
        input T_CIN_N,
        
        // surf-side
        input  [6:0] COUT_P,
        input  [6:0] COUT_N,
        input  [6:0] DOUT_P,
        input  [6:0] DOUT_N,
        output [6:0] CIN_P,
        output [6:0] CIN_N,
        output [6:0] RXCLK_P,
        output [6:0] RXCLK_N                
    );
    
    localparam [6:0] SURF_DEBUG = 7'b0000001;

    // output datapath vector.
    `DEFINE_AXI4S_MIN_IFV( dout_ , 8, [6:0] );
    wire [6:0] dout_tlast;
    `define HOOK_SURF( to, from, fromsuffix )   \
        assign to``tdata = from``tdata``fromsuffix; \
        assign to``tvalid = from``tvalid``fromsuffix;   \
        assign to``tlast = from``tlast``fromsuffix; \
        assign from``tready``fromsuffix = to``tready
    
    `HOOK_SURF( m_s0_ , dout_ , [0] );
    `HOOK_SURF( m_s1_ , dout_ , [1] );
    `HOOK_SURF( m_s2_ , dout_ , [2] );
    `HOOK_SURF( m_s3_ , dout_ , [3] );
    `HOOK_SURF( m_s4_ , dout_ , [4] );
    `HOOK_SURF( m_s5_ , dout_ , [5] );
    `HOOK_SURF( m_s6_ , dout_ , [6] );

    
    // our address space is 12 bits
    // we give each module a 6-bit space (64 bytes = 16 32-bit registers).
    // that takes up 8 bits of the address space
    // also slice off the top bit and use it as a debug space for the spliced
    // command crap: that way it doesn't have to come from outside.
    
    // create a vector of WB interfaces to use.
    `DEFINE_WB_IFV( wbvec_ , 6, 32, [7:0] );
    // and our surfturf interface
    `DEFINE_WB_IF( surfturf_ , 10, 32 );
    // splice in the surfturf
    assign surfturf_cyc_o = wb_cyc_i;
    assign surfturf_stb_o = wb_stb_i && wb_adr_i[11];
    assign surfturf_adr_o = wb_adr_i[9:0];
    assign surfturf_we_o = wb_we_i;
    assign surfturf_sel_o = wb_sel_i;
    assign surfturf_dat_o = wb_dat_i;
    
    wire [27:0] surf_response;
    
    // spliced command
    wire [31:0] surf_command;

    // internal stuff
    `DEFINE_AXI4S_MIN_IF( tfio_runcmd_ , 2);
    `DEFINE_AXI4S_MIN_IF( tfio_trig_ , 15);
    `DEFINE_AXI4S_MIN_IF( tfio_fw_ , 8);
    wire [1:0] tfio_fw_mark;
    wire tfio_fw_marked;
    
    wire [7:0] disable_rxclk;

    reg mask_ce = 0;
    always @(posedge sysclk_i) begin
        if (sync_i) mask_ce <= 1'b0;
        else mask_ce <= ~mask_ce;
    end
    
    // just... pull this from some'n for now
    wire trig = tfio_trig_tready && tfio_trig_tvalid;
    
    wire event_reset;
    
    // vectors for the live detector
    wire [27:0] surf_cout;
    wire [55:0] surf_dout;

    // the surfturf register core also includes
    // the live detector and automatic train stuff now
    // for the startup sequencer on the TURF
    surfturf_register_core #(.WB_CLK_TYPE(WB_CLK_TYPE))
            u_st_core(.wb_clk_i(wb_clk_i),
                      .wb_rst_i(wb_rst_i),
                      `CONNECT_WBS_IFM( wb_ , surfturf_ ),
                      .sysclk_i(sysclk_i),
                      // live detector needs sysclk_ok_i
                      .sysclk_ok_i(sysclk_ok_i),
                      .surf_cout_i(surf_cout_i),
                      .surf_dout_i(surf_dout_i),
                                            
                      .event_reset_o(event_reset),
                      .disable_rxclk_o(disable_rxclk),
                      `CONNECT_AXI4S_MIN_IF( fw_ , tfio_fw_ ),
                      .fw_mark_o(tfio_fw_mark),
                      .fw_marked_i(tfio_fw_marked),
                      `CONNECT_AXI4S_MIN_IF( runcmd_ , tfio_runcmd_ ),
                      `CONNECT_AXI4S_MIN_IF( trig_ , tfio_trig_ ));                                    

    turfio_cmd_splice #(.DEBUG("FALSE"))
                      u_splice(.sysclk_i(sysclk_i),
                               .sync_i(sync_i),
                               .command_i(command_o),
                               .command_valid_i(command_valid_o),
                               .command_locked_i(command_locked_o),
                               `CONNECT_AXI4S_MIN_IF( mode1_ , mode1_ ),
                               .mode1_tuser(mode1_tuser),
                               `CONNECT_AXI4S_MIN_IF( tfio_runcmd_ , tfio_runcmd_ ),
                               `CONNECT_AXI4S_MIN_IF( tfio_trig_ , tfio_trig_ ),
                               `CONNECT_AXI4S_MIN_IF( tfio_fw_ , tfio_fw_ ),
                               .tfio_fw_mark_i(tfio_fw_mark),
                               .tfio_fw_marked_o(tfio_fw_marked),
                               .tfio_pps_i(tfio_pps_i),
                               .use_tfio_pps_i(use_tfio_pps_i),
                               .spliced_o(surf_command));
        
    generate
        genvar i;
        for (i=0;i<8;i=i+1) begin : LP
            assign wbvec_cyc_o[ i ] = wb_cyc_i;
            assign wbvec_stb_o[ i ] = wb_stb_i && (wb_adr_i[6 +: 3] == i) && !wb_adr_i[11];
            assign wbvec_adr_o[ i ] = wb_adr_i[5:0];
            assign wbvec_sel_o[ i ] = wb_sel_i;
            assign wbvec_dat_o[ i ] = wb_dat_i;
            assign wbvec_we_o[ i ] = wb_we_i;
            if (i == 0) begin : TURF
                turf_interface #(.RXCLK_INV( T_RXCLK_INV ),
                                 .TXCLK_INV( T_TXCLK_INV ),
                                 .COUT_INV( T_COUT_INV ),
                                 .COUTTIO_INV( T_COUTTIO_INV ),
                                 .CIN_INV( T_CIN_INV ),
                                 .TRAIN_SEQUENCE(TRAIN_SEQUENCE),
                                 .WB_CLK_TYPE(WB_CLK_TYPE))
                    u_turf( .wb_clk_i(wb_clk_i),
                              .wb_rst_i(wb_rst_i),
                              `CONNECT_WBS_IFMV(wb_ , wbvec_ , [0] ),
                              .sysclk_ok_i(sysclk_ok_i),
                              .sysclk_i(sysclk_i),
                              .sysclk_x2_i(sysclk_x2_i),
                              .sync_i(sync_i),
                              .rxclk_ok_i(rxclk_ok_i),
                              .rxclk_o(rxclk_o),
                              .rxclk_x2_o(rxclk_x2_o),
                              .command_locked_o(command_locked_o),
                              .command_o(command_o),
                              .command_valid_o(command_valid_o),
                              .response_i(response_i),
                              .surf_response_i(surf_response),
                              .RXCLK_P(T_RXCLK_P),
                              .RXCLK_N(T_RXCLK_N),
                              .TXCLK_P(T_TXCLK_P),
                              .TXCLK_N(T_TXCLK_N),
                              .T_COUT_P(T_COUT_P),
                              .T_COUT_N(T_COUT_N),
                              .COUTTIO_P(T_COUTTIO_P),
                              .COUTTIO_N(T_COUTTIO_N),
                              .CIN_P(T_CIN_P),
                              .CIN_N(T_CIN_N)); 
            end else begin : SURFS
                surf_interface_v2 #(.RXCLK_INV( RXCLK_INV[i-1] ),
                                 .COUT_INV(  COUT_INV[i-1] ),
                                 .CIN_INV(   CIN_INV[i-1]  ),
                                 .DOUT_INV(  DOUT_INV[i-1] ),
                                 .TRAIN_SEQUENCE(TRAIN_SEQUENCE),
                                 .WB_CLK_TYPE(WB_CLK_TYPE),
                                 .DEBUG( SURF_DEBUG[i-1] == 1'b1 ? "MASK" : "FALSE" ))
                    u_surf( .wb_clk_i(wb_clk_i),
                            .wb_rst_i(wb_rst_i),
                            `CONNECT_WBS_IFMV(wb_ , wbvec_, [i] ),
                            .sysclk_i(sysclk_i),
                            .sysclk_ok_i(sysclk_ok_i),
                            .sysclk_x2_i(sysclk_x2_i),

                            .disable_rxclk_i(disable_rxclk[i]),
                            
                            .sync_i(sync_i),
                            .trig_i(trig),
                            .event_reset_i(event_reset),
                            .mask_ce_i(mask_ce),
                            `CONNECT_AXI4S_MIN_IFV( m_dout_ , dout_ , [i-1]),
                            .m_dout_tlast(dout_tlast[i-1]),
                            
                            // sigh I have no idea if I'm going to do it
                            // this way or not BUT FOR NOW!
                            .command_i(surf_command),
                            .COUT_P(COUT_P[i-1]),
                            .COUT_N(COUT_N[i-1]),
                            .DOUT_P(DOUT_P[i-1]),
                            .DOUT_N(DOUT_N[i-1]),
                            .CIN_P(CIN_P[i-1]),
                            .CIN_N(CIN_N[i-1]),
                            .RXCLK_P(RXCLK_P[i-1]),
                            .RXCLK_N(RXCLK_N[i-1]));
            end
        end    
    endgenerate    

    // hopefully this works, it's a pretty big mux, we'll see
    assign wb_ack_o = wb_adr_i[11] ? surfturf_ack_i : wbvec_ack_i[ wb_adr_i[6 +: 3] ];
    assign wb_dat_o = wb_adr_i[11] ? surfturf_dat_i : wbvec_dat_i[ wb_adr_i[6 +: 3] ];
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
endmodule
