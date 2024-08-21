`timescale 1ns / 1ps
`include "interfaces.vh"
// This is the version of the boardman wrapper used in the TURFIO.
// The main difference is that this interface takes in an
// upper-bit vector (which comes from the idctrl module) and sub
// it in for the top bits when bit 21 (the top address bit)
// is set. It basically costs nothing because of the way it's implemented.
//
// The intention here is that you can access stuff in the SURFbridge
// this way, but swap back to the TURF side no matter what you've
// programmed those bits to.
module turfio_boardman_wrapper(
        input wb_clk_i,
        input wb_rst_i,
        // the OUTPUT WB bus is actually 25 bits
        `HOST_NAMED_PORTS_WB_IF( wb_ , 25, 32 ),
        // if burst bit is set, this controls the type of access
        input [1:0] burst_size_i,
        // if top address bit is set, use these bits to replace it.
        input [3:0] upper_addr_i,
        // address input if used
        input [7:0] address_i,
        
        input RX,
        output TX
    );
    
    parameter SIMULATION = "FALSE";
    parameter CLOCK_RATE = 40000000;
    parameter BAUD_RATE = 115200;
    parameter USE_ADDRESS = "FALSE";

    wire upper_addr_bit;
    // splice in the upper addresses if used.
    assign wb_adr_o[24:21] = (upper_addr_bit) ? upper_addr_i : {4{1'b0}};
    assign wb_adr_o[1:0] = 2'b00;
    assign wb_cyc_o = wb_stb_o;
    // v1/v2 can be swapped freely here for checking
    boardman_interface_v2 #(.SIMULATION(SIMULATION),
                         .CLOCK_RATE(CLOCK_RATE),
                         .BAUD_RATE(BAUD_RATE),
                         .USE_ADDRESS(USE_ADDRESS),
                         .DEBUG("FALSE"))
        u_dev(.clk(wb_clk_i),
              .rst(wb_rst_i),
              .adr_o({upper_addr_bit,wb_adr_o[20:2]}),
              .dat_o(wb_dat_o),
              .dat_i(wb_dat_i),
              .en_o(wb_stb_o),
              .wr_o(wb_we_o),
              .wstrb_o(wb_sel_o),
              .ack_i(wb_ack_i || wb_rty_i || wb_err_i),
              .burst_size_i(burst_size_i),
              
              .address_i(address_i),
              
              .BM_RX(RX),
              .BM_TX(TX));           
endmodule
