`timescale 1ns / 1ps
// Clock module for Aurora TURF.
// The 4-byte version needs an MMCM to drop the TXOUTCLK to half frequency.
// We don't directly use the exdes version because it pointlessly includes
// the initclk stuff too.
module aurora_turf_clock(
        input tx_outclk_i,
        input tx_locked_i,
        output user_clk_o,
        output sync_clk_o,
        output pll_not_locked_o        
    );
    
    // TXOUTCLK comes out at 312.5 MHz. VCO needs to run from 600-1440 for a -2
    // so we just double it to 625 MHz. And then user_clk_o needs to be 156.25 MHz, 
    // so we divide by 4. And sync_clk needs to be 312.5 MHz, so we divide by 2.
    //
    // The key here is that userclk needs to be TXUSRCLK2 and syncclk needs to be TXUSRCLK.
    // In 2-byte mode TXUSRCLK2=TXUSRCLK.
    // In 4-byte mode TXUSRCLK2=TXUSRCLK/2.
    // This does mean we burn lots of BUFGs for it.
    
    // MMCM parameters
    parameter MULT = 6.0;
    parameter DIVIDE = 3;
    parameter CLK_PERIOD = 3.200;
    parameter OUT0_DIVIDE = 4.0;
    parameter OUT1_DIVIDE = 2;
    // These are pointless but the exdes uses them    
    parameter OUT2_DIVIDE = 4;
    parameter OUT3_DIVIDE = 2;
    parameter CLK_DUTY_CYCLE = 0.5;
    parameter CLK_PHASE = 0.000;
    
                                     
    
    // TXOUTCLK in the global clock buffer network.
    wire tx_outclk_buf;
    // Clock buf for TXOUTCLK
    BUFG u_txoutclk_buf(.I(tx_outclk_i),.O(tx_outclk_buf));

    // Unbuffered user clk output
    wire userclk_unbuf;
    // Unbuffered sync clk output
    wire syncclk_unbuf;
    
    // Feedback output
    wire clkfbout;
    
    // MMCM locked signal
    wire mmcm_locked;
    
    MMCME2_ADV #(.BANDWIDTH("OPTIMIZED"),
                 .CLKOUT4_CASCADE("FALSE"),
                 .COMPENSATION("ZHOLD"),
                 .STARTUP_WAIT("FALSE"),
                 .DIVCLK_DIVIDE(DIVIDE),
                 .CLKFBOUT_MULT_F(MULT),
                 .CLKFBOUT_PHASE(CLK_PHASE),
                 .CLKFBOUT_USE_FINE_PS("FALSE"),
                 
                 .CLKOUT0_DIVIDE_F(OUT0_DIVIDE),
                 .CLKOUT0_PHASE(CLK_PHASE),
                 .CLKOUT0_DUTY_CYCLE(CLK_DUTY_CYCLE),
                 .CLKOUT0_USE_FINE_PS("FALSE"),
                 
                 .CLKOUT1_DIVIDE(OUT1_DIVIDE),
                 .CLKOUT1_PHASE(CLK_PHASE),
                 .CLKOUT1_DUTY_CYCLE(CLK_DUTY_CYCLE),
                 .CLKOUT1_USE_FINE_PS("FALSE"),
                 
                 .CLKOUT2_DIVIDE(OUT2_DIVIDE),
                 .CLKOUT2_PHASE(CLK_PHASE),
                 .CLKOUT2_DUTY_CYCLE(CLK_DUTY_CYCLE),
                 .CLKOUT2_USE_FINE_PS("FALSE"),

                 .CLKOUT3_DIVIDE(OUT3_DIVIDE),
                 .CLKOUT3_PHASE(CLK_PHASE),
                 .CLKOUT3_DUTY_CYCLE(CLK_DUTY_CYCLE),
                 .CLKOUT3_USE_FINE_PS("FALSE"),
                 
                 .REF_JITTER1(0.010))
    u_userclk_mmcm( .CLKFBOUT(clkfbout),
                    .CLKOUT0( userclk_unbuf ),
                    .CLKOUT1( syncclk_unbuf ),
                    .CLKFBIN(clkfbout),
                    .CLKIN1(tx_outclk_buf),
                    .CLKINSEL(1'b1),
                    .DADDR(7'h0),
                    .DCLK(1'b0),
                    .DEN(1'b0),
                    .DI(16'h0),
                    .DWE(1'b0),
                    .PSCLK(1'b0),
                    .PSEN(1'b0),
                    .PSINCDEC(1'b0),
                    .LOCKED(mmcm_locked),
                    .PWRDWN(1'b0),
                    .RST(!tx_locked_i));
    
    // Buffer userclk
    BUFG u_userclk_bufg(.I(userclk_unbuf),.O(user_clk_o));
    // Buffer syncclk
    BUFG u_syncclk_bufg(.I(syncclk_unbuf),.O(sync_clk_o));
    // PLL not locked is just !mmcm_locked
    assign pll_not_locked_o = !mmcm_locked;
    
endmodule
