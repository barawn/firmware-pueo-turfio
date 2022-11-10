`timescale 1ns / 1ps
`define DLYFF #0.5
// N.B.
// This is mostly a mess right now, just trying to verify functionality
// This will get reorganized later. We'll probably offload the clock initialization into software.
// (Guard against effing the TURFIO clock by having "reset" feed a power-on-reset default to the LMK).
module pueo_turfio #( parameter NSURF=1, parameter SIMULATION="TRUE" )(
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
        
        // beginning
        output [NSURF-1:0] RXCLK_P,
        output [NSURF-1:0] RXCLK_N,
        output [NSURF-1:0] CIN_P,
        output [NSURF-1:0] CIN_N, 
        
        // this isn't actually clkdiv2 anymore, dumbass
        input CLKDIV2_P,
        input CLKDIV2_N,
        output CLK_SYNC,
        output DBG_LED
    );
            
    wire sysclk;
    wire serclk;
    wire locked;
    sys_clk_generator u_sysclkgen(.clk_in1_p(CLKDIV2_P),.clk_in1_n(CLKDIV2_N),.reset(1'b0),.sys_clk(sysclk),.ser_clk(serclk),.locked(locked));
    
    (* IOB="TRUE" *)
    reg do_sync = 0;
    wire do_sync_vio_sysclk;
    wire do_sync_vio;
    reg do_sync_vio_reg = 0;
    wire do_sync_vio_flag = (do_sync_vio && !do_sync_vio_reg);
    flag_sync u_dosyncsync(.in_clkA(do_sync_vio_flag),.out_clkB(do_sync_vio_sysclk),.clkA(INITCLK),.clkB(sysclk));
    
    wire do_sync_delay;
    SRLC32E u_syncdelay(.D(do_sync_vio),.CE(1'b1),.CLK(sysclk),.A(4'd15),.Q(do_sync_delay));
    always @(posedge sysclk) begin
        if (do_sync_vio) do_sync <= `DLYFF 1'b0;
        else if (do_sync_delay) do_sync <= `DLYFF 1'b1;
    end
    assign CLK_SYNC = do_sync;
    
    reg led = 0;    
    always @(posedge sysclk) led <= `DLYFF ~led;
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
    always @(posedge INITCLK) lmk_go_rereg <= `DLYFF lmk_go;
    wire        lmk_load = (lmk_go && !lmk_go_rereg);
    wire        lmk_busy;
    
    lmk_shift_reg u_lmk(.clk(INITCLK),.load(lmk_load),.din(lmk_input),.busy(lmk_busy),
                        .lmkdata_mon(lmk_data_int),.lmkclk_mon(lmk_clk_int),.lmkle_mon(lmk_le_int),
                        .LMKDATA(LMKDATA),
                        .LMKCLK(LMKCLK),
                        .LMKLE(LMKLE));
    
    
    // 6 bit alignment pattern = 011001
    // aligned 011001
    // next    110010
    //         100101
    //         001011
    //         010110
    //         101100
    wire [5:0] data_to_surf;
    wire clk_reset;
    wire io_reset;
    // This is ONLY FOR TESTING
    // I need to yoink the internals on this because some of these pins need to be ker-flopped and the dorky
    // IP doesn't allow for it

    wire done_reset;
    SRLC32E u_rstdelay(.D(1'b1),.CE(1'b1),.CLK(INITCLK),.A(5'd0),.Q31(done_reset));
    reg [1:0] done_reset_sysclk = {2{1'b0}};
    always @(posedge sysclk) done_reset_sysclk <= { done_reset_sysclk[0], done_reset };        

    rackbus_to_surf_custom #(.INV_DATA(1'b1),.INV_CLK(1'b1))
                    u_rtos(.clk_in(serclk),.clk_div_in(sysclk),
                           .data_out_from_device( data_to_surf ),
                           .clk_reset(clk_reset),
                           .io_reset(io_reset),
                           // INTENTIONAL
                           .clk_to_pins_n( RXCLK_P[0] ),
                           .clk_to_pins_p( RXCLK_N[0] ),
                           .data_out_to_pins_n( CIN_P[0] ),
                           .data_out_to_pins_p( CIN_N[0] ));

    

    generate
        if (SIMULATION == "FALSE") begin : NS
            lmk_ila u_lmkila(.clk(INITCLK),.probe0(lmk_clk_int),.probe1(lmk_data_int),.probe2(lmk_le_int));
            lmk_vio u_lmkvio(.clk(INITCLK),.probe_out0(lmk_go),.probe_out1(lmk_input),.probe_in0(lmk_busy),.probe_out2(do_sync_vio));
            jtag_ila u_ila(.clk(INITCLK),.probe0(tdi_mon),.probe1(tck_mon),.probe2(tms_mon),.probe3(tdo_mon));
            jtag_vio u_vio(.clk(INITCLK),.probe_out0(JTAG_EN),.probe_out1(drive_jtag));
            rackbus_out_vio u_rbvio(.clk(sysclk),
                                    .probe_out0(data_to_surf),
                                    .probe_out1(clk_reset),
                                    .probe_out2(io_reset));    
    
        end else begin : SIM
            assign lmk_go = 1'b0;
            assign lmk_input = {32{1'b0}};
            assign do_sync_vio = 1'b0;
            assign JTAG_EN = 1'b0;
            assign drive_jtag = 1'b0;
            
            assign data_to_surf = 6'b011001;
            assign clk_reset = 1'b0;
            assign io_reset = !done_reset_sysclk[1];
        end
    endgenerate
    
endmodule

`undef DLYFF
