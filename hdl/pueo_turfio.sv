`timescale 1ns / 1ps
`define DLYFF #0.5
// N.B.
// This is mostly a mess right now, just trying to verify functionality
// This will get reorganized later. We'll probably offload the clock initialization into software.
// (Guard against effing the TURFIO clock by having "reset" feed a power-on-reset default to the LMK).
module pueo_turfio #( parameter NSURF=1, parameter SIMULATION="FALSE" )(
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
    
    // OK, here's the inversion craziness. EVERYTHING is always handled at the TURFIO. It's just easier.
    // At the SURF: DOUT, CIN, RXCLK, are all INVERTED
    //              COUT, TXCLK are NOT
    // At the TURFIO:
    // RXCLK[5:0] = 001_0011
    // CIN[5:0]   = 011_0001
    // COUT[5:0] =  111_1001
    // DOUT[5:0] =  010_1000
    // TXCLK[5:0] = 001_0000                          = 7'h10
    // We add an additional parameter to determine if it's inverted at remote.
    // Therefore, we *logically* invert if xx_INV ^ xx_REMOTE_INV and we connect N to the P-side
    // if xx_INV.
    
    localparam [5:0] RXCLK_INV = 7'b001_0011;
    localparam [5:0] RXCLK_REMOTE_INV = {7{1'b1}};
    localparam [5:0] CIN_INV   = 7'b011_0001;
    localparam [5:0] CIN_REMOTE_INV = {7{1'b1}};
    localparam [5:0] COUT_INV  = 7'b111_1001;
    localparam [5:0] COUT_REMOTE_INV = {7{1'b0}};
    localparam [5:0] DOUT_INV  = 7'b010_1000;
    localparam [5:0] DOUT_REMOTE_INV = {7{1'b0}};
    localparam [5:0] TXCLK_INV = 7'b001_0000;        
    localparam [5:0] TXCLK_REMOTE_INV = {7{1'b0}};
            
    wire sysclk;
    wire serclk;
    wire locked;
    wire sysclk_reset;
    sys_clk_generator u_sysclkgen(.clk_in1_p(CLKDIV2_P),.clk_in1_n(CLKDIV2_N),.reset(sysclk_reset),.sys_clk(sysclk),.ser_clk(serclk),.locked(locked));
    
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
    
    wire do_led_toggle;
    dsp_counter_terminal_count #(.FIXED_TCOUNT("TRUE"),
                                 .FIXED_TCOUNT_VALUE(62500000))
                                 u_ledcounter(.clk_i(sysclk),
                                              .count_i(1'b1),
                                              .tcount_reached_o(do_led_toggle));
    reg led = 0;    
    always @(posedge sysclk) if (do_led_toggle) led <= `DLYFF ~led;
    assign DBG_LED = led;
    
    // this is dumbass-edly inverted with no hint in the name
    assign INITCLKSTDBY = 1'b1;
    // and this too
    assign EN_MYCLK_B = 1'b1;
    
    wire [7:0] jtag_shift;
    wire       jtag_load;
    reg jtag_load_rereg = 0;
    always @(posedge INITCLK) jtag_load_rereg <= jtag_load;
    wire       jtag_busy;
    wire       jtag_enable;
    rack_jtag u_jtag(.clk(INITCLK),
                     .load_i(jtag_load && !jtag_load_rereg),
                     .busy_o(jtag_busy),
                     .dat_i(jtag_shift),
                     .jtag_enable_i(jtag_enable),
                     .tck_i(1'b1),
                     .tms_i(1'b1),
                     .tdi_i(1'b1),
                     .tdo_o(),
                     .JTAG_EN(JTAG_EN),
                     .T_JCTRL_B(T_JCTRL_B),
                     .T_TCK(T_TCK),
                     .T_TMS(T_TMS),
                     .T_TDI(T_TDI),
                     .T_TDO(T_TDO));
    
    assign LMKOE = 1'b1;
            
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

    generate
        genvar i;
        for (i=0;i<NSURF;i=i+1) begin : RB
            wire rxclx_pos;
            wire rxclk_neg;
            wire cin_pos;
            wire cin_neg;
            assign RXCLK_P[i] = (RXCLK_INV[i]) ? rxclk_neg : rxclk_pos;
            assign RXCLK_N[i] = (RXCLK_INV[i]) ? rxclk_pos : rxclk_neg;
            assign CIN_P[i] = (CIN_INV[i]) ? cin_neg : cin_pos;
            assign CIN_N[i] = (CIN_INV[i]) ? cin_pos : cin_neg;
            rackbus_to_surf_custom #(.INV_DATA(CIN_INV[i] ^ CIN_REMOTE_INV[i]),
                                     .INV_CLK(RXCLK_INV[i] ^ RXCLK_REMOTE_INV[i]))
                            u_rtos(.clk_in(serclk),.clk_div_in(sysclk),
                                   .data_out_from_device( data_to_surf ),
                                   .clk_reset(clk_reset),
                                   .io_reset(io_reset),
                                   // INTENTIONAL
                                   .clk_to_pins_n( rxclk_neg ),
                                   .clk_to_pins_p( rxclk_pos ),
                                   .data_out_to_pins_n( cin_neg),
                                   .data_out_to_pins_p( cin_pos));
        end
    endgenerate    

    generate
        if (SIMULATION == "FALSE") begin : NS
            wire disable_3v3;
            lmk_ila u_lmkila(.clk(INITCLK),.probe0(lmk_clk_int),.probe1(lmk_data_int),.probe2(lmk_le_int));
            lmk_vio u_lmkvio(.clk(INITCLK),.probe_out0(lmk_go),.probe_out1(lmk_input),.probe_in0(lmk_busy),.probe_out2(do_sync_vio),.probe_out3(sysclk_reset),.probe_in1(locked));
//            jtag_ila u_ila(.clk(sysclk),.probe0(tdi_mon),.probe1(tck_mon),.probe2(tms_mon),.probe3(tdo_mon));
            jtag_vio u_vio(.clk(INITCLK),.probe_out0(jtag_load),.probe_out1(jtag_shift),.probe_out2(jtag_enable),.probe_in0(jtag_busy),.probe_out3(disable_3v3));
            assign EN_3V3 = !disable_3v3;
            rackbus_out_vio u_rbvio(.clk(sysclk),
                                    .probe_out0(data_to_surf),
                                    .probe_out1(clk_reset),
                                    .probe_out2(io_reset));    
    
        end else begin : SIM
            assign lmk_go = 1'b0;
            assign lmk_input = {32{1'b0}};
            assign do_sync_vio = 1'b0;
            
            assign jtag_shift = {8{1'b0}};
            assign jtag_load = 1'b0;
            assign jtag_enable = 1'b0;
            
            assign data_to_surf = 6'b011001;
            assign clk_reset = 1'b0;
            assign io_reset = !done_reset_sysclk[1];
            assign EN_3V3 = 1'b1;
        end
    endgenerate
    
endmodule

`undef DLYFF
