`timescale 1ns / 1ps
// Clocking portion of the TURF receive interface.
// The TURF receive interface is the only one that actually captures using RXCLK
// because we just use SYSCLK capture on the SURF sides.
// This just collects a bunch of the modules and logic to clean up.
module turf_rxclk_gen #(parameter INVERT_CLOCKS = "TRUE")(
        input rxclk_in,
        output rxclk_o,
        output rxclk_x2_o,
        input  rst_i,
        output locked_o,
        input ps_clk_i,
        input ps_en_i,
        output ps_done_o        
    );
    
    // RXCLK feedback output to bufg
    wire rxclk_fb_to_bufg;
    // RXCLK feedback bufg
    wire rxclk_fb_bufg;
    // RXCLK main output (positive)
    wire rxclk_to_bufg_p;
    // RXCLK main output (negative)
    wire rxclk_to_bufg_n;
    // RXCLK main output (correct pol)
    wire rxclk_to_bufg = (INVERT_CLOCKS == "TRUE") ? rxclk_to_bufg_n : rxclk_to_bufg;
    // RXCLKx2 main output (positive)
    wire rxclk_x2_to_bufg_p;
    // RXCLKx2 main output (negative)
    wire rxclk_x2_to_bufg_n;
    // RXCLKx2 main output (correct pol)    
    wire rxclk_x2_to_bufg = (INVERT_CLOCKS == "TRUE") ? rxclk_x2_to_bufg_n : rxclk_x2_to_bufg_p;
    
    // Clocking    
    BUFG u_rxclk_fb(.I(rxclk_fb_to_bufg),.O(rxclk_fb_bufg));
    BUFG u_rxclk_bufg(.I(rxclk_to_bufg),.O(rxclk_o));
    BUFG u_rxclk_x2_bufg(.I(rxclk_x2_to_bufg),.O(rxclk_x2_o));
    // AAAUUUGH
    // We can't use a BUFR/BUFIO combination because synchronizing
    // BUFRs is virtually impossible. (Screw off, Xilinx).
    // But driven by 2x MMCM outputs, RXCLK/RXCLKx2 need to have
    // a fine phase shift AND have a relative shift between them,
    // but we can't do that??? AAAUUUGH
    // 
    // I think the only workable solution is to just try abandoning
    // the bitslip operation. If we need to we can try abandoning
    // the ISERDES entirely in favor of an IDDR2!
    MMCME2_ADV #( .CLKFBOUT_MULT_F(8.000),
                  .CLKFBOUT_PHASE(0.000),
                  .CLKIN1_PERIOD(8.000),
                  .CLKOUT1_DIVIDE(4),
                  .CLKOUT1_USE_FINE_PS("TRUE"),
                  .CLKOUT0_DIVIDE_F(8.000),
                  .CLKOUT0_USE_FINE_PS("TRUE"))
        u_rxclk_mmcm(.CLKIN1(rxclk_in),
                     .CLKFBIN(rxclk_fb_bufg),
                     .PWRDWN(1'b0),
                     .CLKFBOUT(rxclk_fb_to_bufg),
                     .CLKOUT0(rxclk_to_bufg_p),
                     .CLKOUT0B(rxclk_to_bufg_n),
                     .CLKOUT1(rxclk_x2_to_bufg_p),
                     .CLKOUT1B(rxclk_x2_to_bufg_n),
                     .RST(rst_i),
                     .LOCKED(locked_o),
                     .PSCLK(ps_clk_i),
                     .PSEN(ps_en_i),
                     .PSINCDEC(1'b1),
                     .PSDONE(ps_done_o));

endmodule
