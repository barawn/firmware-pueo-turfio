`timescale 1ns / 1ps
// controls the COUT path from TURFIO to SURF.
// despite its name this is the INPUT FROM THE SURF
module surf_cout_interface_v2 #(parameter COUT_INV = 1'b0,
                                parameter DOUT_INV = 1'b0,
                                parameter DEBUG = "FALSE")(
        input sysclk_i,
        input sysclk_x2_i,
        input sync_i,
        
        // common reset
        input           iserdes_rst_i,
        input           iserdes_cout_bitslip_i,
        input           iserdes_dout_bitslip_i,
        // common value
        input [5:0]     idelay_value_i,        
        input           idelay_cout_load_i,
        input           idelay_dout_load_i,
        output [5:0]    idelay_cout_current_o,
        output [5:0]    idelay_dout_current_o,
        
        output [31:0]   cout_data_o,
        output          cout_valid_o,
        input           cout_capture_i,
        input           cout_enable_i,
        output          cout_biterr_o,

        output [7:0]    dout_data_o,                
        output          dout_valid_o,
        input           dout_capture_i,
        input           dout_enable_i,
        output          dout_biterr_o,
        
        input COUT_P,
        input COUT_N,
        input DOUT_P,
        input DOUT_N
    );

    // these just change every clock
    wire [3:0] cout_from_iserdes;
    wire [7:0] dout_from_iserdes;

    surf_cout_phy_v2 #(.COUT_INV(COUT_INV),.DOUT_INV(DOUT_INV),
                    .DEBUG(DEBUG == "PHY" ? "TRUE" : "FALSE"))
        u_phy(.sysclk_i(sysclk_i),
              .sysclk_x2_i(sysclk_x2_i),
              .iserdes_rst_i(iserdes_rst_i),
              .iserdes_cout_bitslip_i(iserdes_cout_bitslip_i),
              .iserdes_dout_bitslip_i(iserdes_dout_bitslip_i),
              .idelay_value_i(idelay_value_i),
              .idelay_cout_load_i(idelay_cout_load_i),
              .idelay_dout_load_i(idelay_dout_load_i),
              .idelay_cout_current_o(idelay_cout_current_o),
              .idelay_dout_current_o(idelay_dout_current_o),
              .cout_o(cout_from_iserdes),
              .dout_o(dout_from_iserdes),
              .COUT_P(COUT_P),
              .COUT_N(COUT_N),
              .DOUT_P(DOUT_P),
              .DOUT_N(DOUT_N));
    surf_byte_capture u_cap(.sysclk_i(sysclk_i),
                            .sync_i(sync_i),
                            .dout_capture_i(dout_capture_i),
                            .dout_enable_i(dout_enable_i),
                            .dout_i(dout_from_iserdes),
                            .dout_o(dout_data_o),
                            .dout_valid_o(dout_valid_o),
                            .dout_biterr_o(dout_biterr_o));

endmodule
