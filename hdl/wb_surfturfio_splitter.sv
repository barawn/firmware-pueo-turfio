`timescale 1ns / 1ps
`include "interfaces.vh"
// simple module to peel off address bits.
module wb_surfturfio_splitter(
        `TARGET_NAMED_PORTS_WB_IF( wb_ , 25, 32 ),
        `HOST_NAMED_PORTS_WB_IF( wb_turfio_ , 22, 32 ),
        `HOST_NAMED_PORTS_WB_IF( wb_surf_ , 22, 32 ),
        output [2:0] wb_surf_select_o
    );
    
    assign wb_turfio_cyc_o = wb_cyc_i && (wb_adr_i[24:22] == {3{1'b0}});
    assign wb_turfio_stb_o = wb_stb_i;
    assign wb_turfio_adr_o = wb_adr_i;
    assign wb_turfio_we_o = wb_we_i;
    assign wb_turfio_sel_o = wb_sel_i;
    assign wb_turfio_dat_o = wb_dat_i;

    assign wb_surf_cyc_o = wb_cyc_i && (wb_adr_i[24:22] != {3{1'b0}});
    assign wb_surf_stb_o = wb_stb_i;
    assign wb_surf_adr_o = wb_adr_i;
    assign wb_surf_we_o = wb_we_i;
    assign wb_surf_sel_o = wb_sel_i;
    assign wb_surf_dat_o = wb_dat_i;
    assign wb_surf_select_o = wb_adr_i[24:22];

    assign wb_dat_o = (wb_adr_i[24:22] == {3{1'b0}}) ? wb_turfio_dat_i : wb_surf_dat_i;
    assign wb_ack_o = (wb_adr_i[24:22] == {3{1'b0}}) ? wb_turfio_ack_i : wb_surf_ack_i;
    assign wb_err_o = (wb_adr_i[24:22] == {3{1'b0}}) ? wb_turfio_err_i : wb_surf_err_i;    
    assign wb_rty_o = (wb_adr_i[24:22] == {3{1'b0}}) ? wb_turfio_rty_i : wb_surf_rty_i;

endmodule
