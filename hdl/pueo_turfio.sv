`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2022 01:01:38 PM
// Design Name: 
// Module Name: pueo_turfio
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pueo_turfio(
        input INITCLK,
        output INITCLKSTDBY,
        
        output EN_MYCLK_B,
        
        output JTAG_EN,
        output T_JCTRL_B,
        output EN_3V3,
        inout T_TDI,
        input T_TDO,
        inout T_TCK,
        inout T_TMS,
        
        output LMKDATA,
        output LMKCLK,
        output LMKLE,
        output LMKOE,
        
        // this isn't actually clkdiv2 anymore, dumbass
        input CLKDIV2_P,
        input CLKDIV2_N,
        output SYNC,
        output DBG_LED
    );
        
    wire sysclk;
    wire serclk;
    wire locked;
    sys_clk_generator u_sysclkgen(.clk_in1_p(CLKDIV2_P),.clk_in1_n(CLKDIV2_N),.reset(1'b0),.sysclk(sysclk),.serclk(serclk),.locked(locked));
    
    
    
    reg led = 0;
    IBUFDS u_sysclk(.I(CLKDIV2_P),.IB(CLKDIV2_N),.O(sysclk));
    always @(posedge sysclk) led <= ~led;
    assign DBG_LED = led;
    
    // this is dumbass-edly inverted with no hint in the name
    assign INITCLKSTDBY = 1'b1;
    // and this too
    assign EN_MYCLK_B = 1'b1;
    
    assign T_JCTRL_B = 1'b1;
    assign EN_3V3 = 1'b1;
    assign LMKOE = 1'b1;
        
    wire drive_jtag;

    wire tdi_mon;
    wire tck_mon;
    wire tms_mon;
    wire tdo_mon = T_TDO;
    
    wire int_tdi = 1'b0;
    wire int_tck = 1'b0;
    wire int_tms = 1'b0;
    
    IOBUF u_tdi(.I(int_tdi),.O(tdi_mon),.IO(T_TDI),.T(!drive_jtag));
    IOBUF u_tck(.I(int_tck),.O(tck_mon),.IO(T_TCK),.T(!drive_jtag));
    IOBUF u_tms(.I(int_tms),.O(tms_mon),.IO(T_TMS),.T(!drive_jtag));

    wire lmk_clk_int;
    wire lmk_data_int;
    wire lmk_le_int;
    wire [31:0] lmk_input;
    wire        lmk_go;
    reg         lmk_go_rereg = 0;
    always @(posedge INITCLK) lmk_go_rereg <= lmk_go;
    wire        lmk_load = (lmk_go && !lmk_go_rereg);
    wire        lmk_busy;
    
    lmk_shift_reg u_lmk(.clk(INITCLK),.load(lmk_load),.din(lmk_input),.busy(lmk_busy),
                        .lmkdata_mon(lmk_data_int),.lmkclk_mon(lmk_clk_int),.lmkle_mon(lmk_le_int),
                        .LMKDATA(LMKDATA),
                        .LMKCLK(LMKCLK),
                        .LMKLE(LMKLE));
    
    lmk_ila u_lmkila(.clk(INITCLK),.probe0(lmk_clk_int),.probe1(lmk_data_int),.probe2(lmk_le_int));
    lmk_vio u_lmkvio(.clk(INITCLK),.probe_out0(lmk_go),.probe_out1(lmk_input),.probe_in0(lmk_busy));
    jtag_ila u_ila(.clk(INITCLK),.probe0(tdi_mon),.probe1(tck_mon),.probe2(tms_mon),.probe3(tdo_mon));
    jtag_vio u_vio(.clk(INITCLK),.probe_out0(JTAG_EN),.probe_out1(drive_jtag));
    
endmodule
