`timescale 1ns / 1ps
// merges surf receive + hski2c receive
// this crap used to be in the pueo_turfio top-level
module uart_hskbus_merge(
        input clk_i,

        input hskbus_tx_i,
        output hskbus_rx_o,
        
        output [7:0] hskbus_rx_bytes_o,

        input surf_rx_i,
        output surf_tx_o,
        
        input hski2c_rx_i,
        output hski2c_tx_o,
        
        input crate_enable_i        
    );
    
    
    parameter DEBUG = "TRUE";

    // screw you so much, let's just figure this out...
    reg [1:0] rx_falling = {2{1'b0}};
    reg [7:0] rx_bytes = {8{1'b0}};
    (* USE_DSP48 = "TRUE" *)
    reg [10:0] rx_holdoff_counter = {11{1'b0}};
    wire rx_holdoff_reached = (rx_holdoff_counter == {11{1'b0}});
    always @(posedge clk_i) begin
        rx_falling <= { rx_falling[0], hskbus_tx_i };
        
        if (rx_falling == 2'b10 && rx_holdoff_reached)
            rx_bytes <= rx_bytes + 1;

        if (rx_falling == 2'b10) 
            rx_holdoff_counter <= 11'd1550;
        else if (!rx_holdoff_reached)
            rx_holdoff_counter <= rx_holdoff_counter - 1;
    end
    
    assign hskbus_rx_bytes_o = rx_bytes;
    // a 500 kbps clock is 160 clock counts
    // after a start bit the next one can't come until 10 bits later
    // which is 1600
    // jump forward 1550
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
