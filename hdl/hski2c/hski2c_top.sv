`timescale 1ns / 1ps
`include "interfaces.vh"
`include "turfio_debug.vh"
module hski2c_top(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF( wb_ , 12, 32),
        
        inout F_SDA,
        inout F_SCL,
        input I2C_RDY        
    );
    
    parameter DEBUG = `HSKI2C_DEBUG;
    // The I2C access core is controlled fundamentally by a softcore PicoBlaze
    // to allow it to handle monitoring easily.
    // We crib the I2C stuff from the HELIX TOF controller, except we also
    // add the generic PicoBlaze core control from the RADIANT/SURFv5/etc.
    
    // holds PicoBlaze in reset
    reg processor_reset = 0;
    // enables writes to BRAM
    reg bram_we_enable = 0;
    // address register for BRAM
    reg [9:0] bram_address_reg = {10{1'b0}};
    // data register for BRAM
    reg [17:0] bram_data_reg = {18{1'b0}};
    // actual write flag to BRAM
    reg bram_we = 0;
    // readback data from BRAM
    wire [17:0] bram_readback;

    // combined register
    wire [31:0] pb_bram_data = {processor_reset, bram_we_enable, {2{1'b0}}, bram_address_reg, bram_readback };
    
    
    
    
endmodule
