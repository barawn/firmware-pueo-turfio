`timescale 1ns / 1ps
// merges surf receive + hski2c receive
// this crap used to be in the pueo_turfio top-level
module uart_hskbus_merge(
        input clk_i,

        input hskbus_tx_i,
        output hskbus_rx_o,

        input surf_rx_i,
        output surf_tx_o,
        
        input hski2c_rx_i,
        output hski2c_tx_o,
        
        input crate_enable_i        
    );
    
    
    parameter DEBUG = "TRUE";
    
    generate
        if (DEBUG == "TRUE") begin : ILA        
            // initclk is 80 MHz. we run at 500 kbps,
            // so to get a 16x oversample for debugging
            // just count to 10.
            reg [3:0] oversample_counter = {4{1'b0}};
            reg sample_16x = 0;
            always @(posedge clk_i) begin : OVS
                if (sample_16x)
                    oversample_counter <= {4{1'b0}};
                else
                    oversample_counter <= oversample_counter + 1;
                
                sample_16x <= (oversample_counter == 4'd8);                    
            end
            hskbus_uart_ila u_ila(.clk(clk_i),
                                  .probe0(hskbus_tx_i),
                                  .probe1(surf_rx_i),
                                  .probe2(hski2c_rx_i),
                                  .probe3(crate_enable_i),
                                  .probe4(sample_16x));
        end
    endgenerate

    assign surf_tx_o = (crate_enable_i) ? hskbus_tx_i : 1'b1;
    assign hski2c_tx_o = hskbus_tx_i;    
    assign hskbus_rx_o = (crate_enable_i) ? (surf_rx_i && hski2c_rx_i) : hski2c_rx_i;
    
endmodule
