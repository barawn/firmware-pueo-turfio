`timescale 1ns / 1ps
// controls the COUT path from TURFIO to SURF.
// despite its name this is the INPUT FROM THE SURF
module surf_cout_interface #(parameter INV = 1'b0,
                             parameter DOUT_INV = 1'b0,
                             parameter TXCLK_INV = 1'b0,
                             parameter DEBUG = "FALSE")(
        input sysclk_i,
        input sysclk_x2_i,
        input sync_i,
        
        // common reset
        input iserdes_rst_i,
        input iserdes_bitslip_i,
        input iserdes_dout_bitslip_i,
        // common value
        input [5:0] idelay_value_i,        
        input idelay_load_i,
        input idelay_dout_load_i,
        output [5:0] idelay_current_o,
        output [5:0] idelay_dout_current_o,
        
        output [31:0] cout_data_o,
        output cout_valid_o,
        input cout_capture_i,
        output cout_biterr_o,

        output [7:0] dout_data_o,                
        output dout_valid_o,
        // do a one-time data capture for eye alignment
        input  dout_capture_i,
        // accept data on the dout path
        input  dout_enable_i,
        output dout_biterr_o,
        
        // TODO: ADD STUFF FOR THE RESP (old TXCLK) STUFF
        
        input COUT_P,
        input COUT_N,
        input DOUT_P,
        input DOUT_N,
        input TXCLK_P,      // THIS IS RESPONSE PATH
        input TXCLK_N       // THIS IS RESPONSE PATH
    );

    // these just change every clock
    wire [3:0] cout_from_iserdes;
    wire [7:0] dout_from_iserdes;

    surf_cout_phy #(.INV(INV),.DOUT_INV(DOUT_INV),.TXCLK_INV(TXCLK_INV),
                    .DEBUG(DEBUG == "PHY" ? "TRUE" : "FALSE"))
        u_phy(.sysclk_i(sysclk_i),
              .sysclk_x2_i(sysclk_x2_i),
              .iserdes_rst_i(iserdes_rst_i),
              .iserdes_bitslip_i(iserdes_bitslip_i),
              .iserdes_dout_bitslip_i(iserdes_dout_bitslip_i),
              .idelay_value_i(idelay_value_i),
              .idelay_load_i(idelay_load_i),
              .idelay_dout_load_i(idelay_dout_load_i),
              .idelay_current_o(idelay_current_o),
              .idelay_dout_current_o(idelay_dout_current_o),
              .cout_o(cout_from_iserdes),
              .dout_o(dout_from_iserdes),
              .COUT_P(COUT_P),
              .COUT_N(COUT_N),
              .DOUT_P(DOUT_P),
              .DOUT_N(DOUT_N),
              .TXCLK_P(TXCLK_P),
              .TXCLK_N(TXCLK_N));
    // this ALSO has the resp interface when we need it
    surf_byte_capture u_cap(.sysclk_i(sysclk_i),
                            .sync_i(sync_i),
                            .dout_capture_i(dout_capture_i),
                            .dout_enable_i(dout_enable_i),
                            .dout_i(dout_from_iserdes),
                            .dout_o(dout_data_o),
                            .dout_valid_o(dout_valid_o),
                            .dout_biterr_o(dout_biterr_o));
    
    
    

endmodule
