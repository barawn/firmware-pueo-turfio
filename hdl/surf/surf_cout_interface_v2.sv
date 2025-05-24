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
        
        // this is actually what goes to the TURF transmitter
        output [3:0]    cout_o,
        // for the surf live detector
        output [7:0]    dout_o,
        
        output [31:0]   cout_data_o,
        output          cout_valid_o,
        
        input           cout_capture_i,
        input           cout_captured_i,
        input           cout_enable_i,
        output          cout_biterr_o,

        output [7:0]    dout_data_o,                
        output          dout_valid_o,
        input           dout_capture_i,
        input           dout_enable_i,
        output          dout_biterr_o,
        input           dout_capture_phase_i,
        
        input COUT_P,
        input COUT_N,
        input DOUT_P,
        input DOUT_N
    );

    // these just change every clock
    wire [3:0] cout_from_iserdes;
    wire [7:0] dout_from_iserdes;

    wire dout_sync;

    surf_cout_phy_v3 #(.COUT_INV(COUT_INV),.DOUT_INV(DOUT_INV),
                    .DEBUG(DEBUG == "PHY" ? "TRUE" : "FALSE"))
        u_phy(.sysclk_i(sysclk_i),
              .sysclk_x2_i(sysclk_x2_i),
              .sync_i(sync_i),
              .dout_sync_i(dout_sync),
              .dout_capture_phase_i(dout_capture_phase_i),
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
                            .dout_sync_o(dout_sync),
                            .dout_capture_i(dout_capture_i),
                            .dout_enable_i(dout_enable_i),
                            .dout_i(dout_from_iserdes),
                            .dout_o(dout_data_o),
                            .dout_valid_o(dout_valid_o),
                            .dout_biterr_o(dout_biterr_o));    
    // COUT capture is significantly easier. We only actually capture
    // for training, based on an 8-cycle counter that resets with sync_i.
    // The value **should** stay static, so I just need to adjust the reset
    // value. And then we DON'T actually output a 32-bit value! We just
    // pass along the 4-bit value and re-clock it out to the TURF, which
    // then does the same thing.
    surf_cout_parallelizer u_cout_parallel(.sysclk_i(sysclk_i),
                                           .sync_i(sync_i),
                                           .capture_i(cout_capture_i),
                                           .captured_i(cout_captured_i),
                                           .enable_i(cout_enable_i),
                                           .biterr_o(cout_bitter_o),
                                           .cout_parallel_o(cout_data_o),
                                           .cout_i(cout_o));
    
    assign cout_o = cout_from_iserdes;
    // surf live detector gets stuff without going through surf byte capture    
    assign dout_o = dout_from_iserdes;

endmodule
