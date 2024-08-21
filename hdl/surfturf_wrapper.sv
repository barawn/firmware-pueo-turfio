`timescale 1ns / 1ps
`include "interfaces.vh"
// this thing is a mess, sigh
module surfturf_wrapper #(
        parameter T_RXCLK_INV = 1'b0,
        parameter T_TXCLK_INV = 1'b0,
        parameter [6:0] T_COUT_INV = 1'b0,
        parameter T_COUTTIO_INV = 1'b0,
        parameter T_CIN_INV = 1'b0,
        parameter [31:0] TRAIN_SEQUENCE = 32'hA55A6996,
        parameter WB_CLK_TYPE = "INITCLK",
        parameter [6:0] RXCLK_INV = {6{1'b0}},
        parameter [6:0] TXCLK_INV = {6{1'b0}},
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
        // turf outputs
        output          command_locked_o,
        output [31:0]   command_o,
        output          command_valid_o,
        // response inputs
        input [31:0]    response_i,

        // need to figure out the surfbridge stuff!!!
        
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
        inout  [6:0] TXCLK_P,
        inout  [6:0] TXCLK_N,
        output [6:0] CIN_P,
        output [6:0] CIN_N,
        output [6:0] RXCLK_P,
        output [6:0] RXCLK_N                
    );
    
    localparam [6:0] SURF_DEBUG = 7'b0000011;
    
    // create a vector of WB interfaces to use.
    `DEFINE_WB_IFV( wbvec_ , 12, 32, [7:0] );
    
    wire [27:0] surf_response;
    
    generate
        genvar i;
        for (i=0;i<8;i=i+1) begin : LP
            assign wbvec_cyc_o[ i ] = wb_cyc_i;
            assign wbvec_stb_o[ i ] = wb_stb_i && (wb_adr_i[6 +: 3] == i);
            assign wbvec_adr_o[ i ] = wb_adr_i;
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
                if (i == 1 || i == 2) begin : TEST
                    surf_rackctl_test #(.INV(TXCLK_INV[i-1]),.DEBUG("TRUE"))
                                   u_test(.sysclk_i(sysclk_i),
                                          .RACKCTL_P(TXCLK_P[i-1]),
                                          .RACKCTL_N(TXCLK_N[i-1]));
                end
                surf_interface #(.RXCLK_INV( RXCLK_INV[i-1] ),
                                 .TXCLK_INV( TXCLK_INV[i-1] ),
                                 .COUT_INV(  COUT_INV[i-1] ),
                                 .CIN_INV(   CIN_INV[i-1]  ),
                                 .DOUT_INV(  DOUT_INV[i-1] ),
                                 .TRAIN_SEQUENCE(TRAIN_SEQUENCE),
                                 .WB_CLK_TYPE(WB_CLK_TYPE),
                                 .DEBUG( SURF_DEBUG[i-1] == 1'b1 ? "PHY" : "FALSE" ))
                    u_surf( .wb_clk_i(wb_clk_i),
                            .wb_rst_i(wb_rst_i),
                            `CONNECT_WBS_IFMV(wb_ , wbvec_, [i] ),
                            .sysclk_i(sysclk_i),
                            .sysclk_ok_i(sysclk_ok_i),
                            .sysclk_x2_i(sysclk_x2_i),
                            .sync_i(sync_i),
                            // sigh I have no idea if I'm going to do it
                            // this way or not BUT FOR NOW!
                            .command_i(command_o),
                            .COUT_P(COUT_P[i-1]),
                            .COUT_N(COUT_N[i-1]),
                            .DOUT_P(DOUT_P[i-1]),
                            .DOUT_N(DOUT_N[i-1]),
//                            .TXCLK_P(TXCLK_P[i-1]),
//                            .TXCLK_N(TXCLK_N[i-1]),
                            .CIN_P(CIN_P[i-1]),
                            .CIN_N(CIN_N[i-1]),
                            .RXCLK_P(RXCLK_P[i-1]),
                            .RXCLK_N(RXCLK_N[i-1]));
            end
        end    
    endgenerate    

    // hopefully this works, it's a pretty big mux, we'll see
    assign wb_ack_o = wbvec_ack_i[ wb_adr_i[6 +: 3] ];
    assign wb_dat_o = wbvec_dat_i[ wb_adr_i[6 +: 3] ];
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
endmodule
