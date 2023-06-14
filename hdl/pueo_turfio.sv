`timescale 1ns / 1ps
`define DLYFF #0.5
`include "interfaces.vh"
// PUEO TURFIO Firmware.
//
// Still a horrible work in progress: however, I'm trying to move to a more normalized
// setup for interfacing with the flight computer. Serial port debug interface is based
// on the RADIANT comms.
module pueo_turfio #( parameter NSURF=1, 
                      parameter SIMULATION="FALSE",
                      parameter IDENT="TFIO",
                      parameter [3:0] VER_MAJOR = 4'd0,
                      parameter [3:0] VER_MINOR = 4'd0,
                      parameter [7:0] VER_REV =   8'd2,
                      parameter [15:0] FIRMWARE_DATE = {16{1'b0}} )(
        // 40 MHz constantly on clock
        input INITCLK,
        // Force initclk into standby
        output INITCLKSTDBY,
        // Debug receive (from FT2232)
        input DBG_RX,
        // Debug transmit (to FT2232) 
        output DBG_TX,
        
        // Enable local system clock
        output EN_MYCLK_B,
        // Enable crate JTAG outputs
        output JTAG_EN,
        // Crate JTAG control (low = address multiplexer)
        output T_JCTRL_B,
        // Crate TDI
        inout T_TDI,
        // Crate TDO
        input T_TDO,
        // Crate TCK
        inout T_TCK,
        // Crate TMS
        inout T_TMS,

        // Enable crate 3V3 (for JTAG)
        output EN_3V3,
        
        // LMK data output
        output LMKDATA,
        // LMK clock output
        output LMKCLK,
        // LMK latch enable output
        output LMKLE,
        // Enable LMK clock outputs
        output LMKOE,

        // SPI flash output K16
        output SPI_MOSI,
        // SPI flash input L17
        input SPI_MISO,
        // SPI flash chip select L15
        output SPI_CS_B,
        
        
//        // beginning
//        output [NSURF-1:0] RXCLK_P,
//        output [NSURF-1:0] RXCLK_N,
//        output [NSURF-1:0] CIN_P,
//        output [NSURF-1:0] CIN_N, 

        // TURF comms
        input T_RXCLK_P,              // C13 - inverted
        input T_RXCLK_N,              // D13 - inverted
        input T_CIN_P,                // A13
        input T_CIN_N,                // A14
        output T_TXCLK_P,             // B9
        output T_TXCLK_N,             // A9
        output T_COUTTIO_P,           // B10
        output T_COUTTIO_N,           // A10        
        // will add the retimed SURF outputs later
// 0: B14, A15
// 1: C11, B11
// 2: B16, A17
// 3: A12, B12 (inverted)
// 4: C17, C18
// 5: E18, F17 (inverted)
// 6: D18, E17 (inverted)
//      output [6:0] TCOUT_P,
//      output [6:0] TCOUT_N,
        // GTP stuff
        input F_LCLK_P,   // GTP clock D6
        input F_LCLK_N,   // GTP clock D5
        output EN_LCLK_B, // GTP clock enable
        // this isn't actually clkdiv2 anymore, dumbass
        input CLKDIV2_P,
        input CLKDIV2_N,
        output CLK_SYNC,
        output DBG_LED
    );
    
    localparam [15:0] FIRMWARE_VERSION = {VER_MAJOR, VER_MINOR, VER_REV};
    localparam [31:0] DATEVERSION = { FIRMWARE_DATE, FIRMWARE_VERSION };
        
    // OK, here's the inversion craziness. EVERYTHING is always handled at the TURFIO. It's just easier.
    // At the SURF: DOUT, CIN, RXCLK, are all INVERTED
    //              COUT, TXCLK are NOT
    // At the TURFIO:
    // RXCLK[6:0] = 001_0011
    // CIN[6:0]   = 011_0001
    // COUT[6:0] =  111_1001
    // DOUT[6:0] =  010_1000
    // TXCLK[6:0] = 001_0000                          = 7'h10
    // We add an additional parameter to determine if it's inverted at remote.
    // Therefore, we *logically* invert if xx_INV ^ xx_REMOTE_INV and we connect N to the P-side
    // if xx_INV.
    
    localparam [6:0] RXCLK_INV = 7'b001_0011;
    localparam [6:0] RXCLK_REMOTE_INV = {7{1'b1}};
    localparam [6:0] CIN_INV   = 7'b011_0001;
    localparam [6:0] CIN_REMOTE_INV = {7{1'b1}};
    localparam [6:0] COUT_INV  = 7'b111_1001;
    localparam [6:0] COUT_REMOTE_INV = {7{1'b0}};
    localparam [6:0] DOUT_INV  = 7'b010_1000;
    localparam [6:0] DOUT_REMOTE_INV = {7{1'b0}};
    localparam [6:0] TXCLK_INV = 7'b001_0000;        
    localparam [6:0] TXCLK_REMOTE_INV = {7{1'b0}};
            
    // And here are the TURF connection definitions.
    localparam T_RXCLK_INV = 1'b1;
    localparam T_TXCLK_INV = 1'b0;
    localparam T_COUTTIO_INV = 1'b0;
    localparam T_CIN_INV = 1'b0;
    localparam [6:0] T_COUT_INV = 7'b110_1000;

    //////////////////////////////////////////////
    // CLOCKS                                   //
    //////////////////////////////////////////////
    
    // 40 MHz always running clock
    wire init_clk;
    // 200 MHz clock for IDELAYCTRLs (derived)
    wire clk200;
    // 125 MHz clock from the TURF arriving on RXCLK
    wire rxclk;
    // High speed (250 MHz) clock for digitizing CIN-type data
    wire rxclk_x2;
    // Local gigabit clock derived 
    wire gtp_clk;
    // System clock (from LMK)
    wire sysclk;    
    
    wire clk200_locked;
    BUFG u_initclk_bufg(.I(INITCLK),.O(init_clk));
    clk200_wiz u_clk200(.clk_in1(init_clk),.clk_out1(clk200),.locked(clk200_locked));
    IDELAYCTRL u_idelayctrl(.RST(!clk200_locked),.REFCLK(clk200));


    // Main wishbone bus. The address is a byte address, but it'll always be aligned on 32-bits
    // We have 4 master devices on the bus:
    // 0: gigabit transceiver (gtp)
    // 1: cin/cout (ctl)
    // 2: debug rx/tx (dbg)
    // 3: turf serial (ser)
    wire wb_clk = init_clk;

    `DEFINE_WB_IF( gtp_ , 22, 32);
    `DEFINE_WB_IF( ctl_ , 22, 32);
    `DEFINE_WB_IF( dbg_ , 22, 32);
    `DEFINE_WB_IF( ser_ , 22, 32);
    
    // And hook up the debug port which comes from the boardman interface.
    // fix this later
    wire [1:0] burst_size = 2'b00;
    boardman_wrapper #(.SIMULATION(SIMULATION),
                       .CLOCK_RATE(40000000),
                       .BAUD_RATE(115200))
            u_boardman( .wb_clk_i(wb_clk),
                        .wb_rst_i(1'b0),
                        `CONNECT_WBM_IFM( wb_ , dbg_ ),
                        .burst_size_i(burst_size),
                        .TX(DBG_TX),
                        .RX(DBG_RX));            
    // We don't need a lot of registers but we have a *huge* space available (24 bit byte address)
    // We'll give each module 1024 32-bit registers (12 bit address space)
    // Right now we'll implement 4 quick modules:
    // module 0 (0x000000-0x000FFF): identification, version, internal housekeeping (clocks, XADC)
    // module 1 (0x001000-0x001FFF): shift register module
    // module 2 (0x002000-0x002FFF): SURF/TURF serial I/O control
    // module 3 (0x003000-0x003FFF): I2C housekeeping/control
    // I should implement a 4th module too for the GTP link, will do that at some point
    `DEFINE_WB_IF( tio_id_ctrl_ , 12, 32);
    `DEFINE_WB_IF( genshift_ , 12, 32);
    `DEFINE_WB_IF( surfturf_ , 12, 32);
    `DEFINE_WB_IF( hski2c_ , 12, 32);

    // Slave stubs    
    wbs_dummy #(.ADDRESS_WIDTH(12),.DATA_WIDTH(32)) u_surfturf_stub( `CONNECT_WBS_IFM( wb_, surfturf_) );
    wbs_dummy #(.ADDRESS_WIDTH(12),.DATA_WIDTH(32)) u_hski2c_stub( `CONNECT_WBS_IFM(wb_ , hski2c_) );
    // Master stubs
    wbm_dummy #(.ADDRESS_WIDTH(22),.DATA_WIDTH(32)) u_gtp_stub( `CONNECT_WBM_IFM(wb_ , gtp_ ));
    wbm_dummy #(.ADDRESS_WIDTH(22),.DATA_WIDTH(32)) u_ctl_stub( `CONNECT_WBM_IFM(wb_ , ctl_ ));
    wbm_dummy #(.ADDRESS_WIDTH(22),.DATA_WIDTH(32)) u_ser_stub( `CONNECT_WBM_IFM(wb_ , ser_ ));
    // Interconnect
    turfio_intercon #(.DEBUG("FALSE"))
        u_intercon( .clk_i(wb_clk),
                    .rst_i(1'b0),
                    `CONNECT_WBS_IFM(gtp_ , gtp_),
                    `CONNECT_WBS_IFM(ctl_ , ctl_),
                    `CONNECT_WBS_IFM(dbg_ , dbg_),
                    `CONNECT_WBS_IFM(ser_ , ser_),
                    
                    `CONNECT_WBM_IFM(tio_id_ctrl_ , tio_id_ctrl_ ),
                    `CONNECT_WBM_IFM(genshift_ , genshift_ ),
                    `CONNECT_WBM_IFM(surfturf_ , surfturf_ ),
                    `CONNECT_WBM_IFM(hski2c_ , hski2c_ ));
    // ID control module
    tio_id_ctrl #(.DEVICE(IDENT),.VERSION(DATEVERSION))
        u_id_ctrl( .wb_clk_i(wb_clk),
                   .wb_rst_i(1'b0),
                   `CONNECT_WBS_IFM( wb_ , tio_id_ctrl_ ),
                   .sys_clk_i(sysclk),
                   .gtp_clk_i(gtp_clk),
                   .rx_clk_i(rxclk),
                   .rx_clk_x2_i(rxclk_x2),
                   .clk200_i(clk200));
    
    turfio_gen_shift_wrapper
        u_genshift( .wb_clk_i(wb_clk),
                    .wb_rst_i(1'b0),
                    `CONNECT_WBS_IFM( wb_ , genshift_ ),
                    // JTAG
                    .TCTRL_B(T_JCTRL_B),
                    .JTAG_OE(JTAG_EN),
                    .TDI(T_TDI),
                    .TDO(T_TDO),
                    .TMS(T_TMS),
                    .TCK(T_TCK),
                    // LMK
                    .LMKCLK(LMKCLK),
                    .LMKDATA(LMKDATA),
                    .LMKLE(LMKLE),
                    .LMKOE(LMKOE),
                    // SPI
                    .SPI_MISO(SPI_MISO),
                    .SPI_MOSI(SPI_MOSI),
                    .SPI_CS_B(SPI_CS_B));

    // this is temporary and going away.
    wire serclk;
    wire locked;
    wire sysclk_reset;
    sys_clk_generator u_sysclkgen(.clk_in1_p(CLKDIV2_P),.clk_in1_n(CLKDIV2_N),.reset(sysclk_reset),.sys_clk(sysclk),.ser_clk(serclk),.locked(locked));
    
    
//    // this is ALLLL going away
//    (* IOB="TRUE" *)
//    reg do_sync = 0;
//    wire do_sync_vio_sysclk;
//    wire do_sync_vio;
//    reg do_sync_vio_reg = 0;
//    wire do_sync_vio_flag = (do_sync_vio && !do_sync_vio_reg);
//    flag_sync u_dosyncsync(.in_clkA(do_sync_vio_flag),.out_clkB(do_sync_vio_sysclk),.clkA(init_clk),.clkB(sysclk));
    
//    wire do_sync_delay;
//    SRLC32E u_syncdelay(.D(do_sync_vio),.CE(1'b1),.CLK(sysclk),.A(4'd15),.Q(do_sync_delay));
//    always @(posedge sysclk) begin
//        if (do_sync_vio) do_sync <= `DLYFF 1'b0;
//        else if (do_sync_delay) do_sync <= `DLYFF 1'b1;
//    end
//    assign CLK_SYNC = do_sync;
    
//    wire do_led_toggle;
//    dsp_counter_terminal_count #(.FIXED_TCOUNT("TRUE"),
//                                 .FIXED_TCOUNT_VALUE(62500000))
//                                 u_ledcounter(.clk_i(sysclk),
//                                              .count_i(1'b1),
//                                              .tcount_reached_o(do_led_toggle));
//    reg led = 0;    
//    always @(posedge sysclk) if (do_led_toggle) led <= `DLYFF ~led;
//    assign DBG_LED = led;
    
    
//    wire [7:0] jtag_shift;
//    wire       jtag_load;
//    reg jtag_load_rereg = 0;
//    always @(posedge init_clk) jtag_load_rereg <= jtag_load;
//    wire       jtag_busy;
//    wire       jtag_enable;
//    rack_jtag u_jtag(.clk(init_clk),
//                     .load_i(jtag_load && !jtag_load_rereg),
//                     .busy_o(jtag_busy),
//                     .dat_i(jtag_shift),
//                     .jtag_enable_i(jtag_enable),
//                     .tck_i(1'b1),
//                     .tms_i(1'b1),
//                     .tdi_i(1'b1),
//                     .tdo_o(),
//                     .JTAG_EN(JTAG_EN),
//                     .T_JCTRL_B(T_JCTRL_B),
//                     .T_TCK(T_TCK),
//                     .T_TMS(T_TMS),
//                     .T_TDI(T_TDI),
//                     .T_TDO(T_TDO));
    
//    assign LMKOE = 1'b1;
            
//    wire lmk_clk_int;
//    wire lmk_data_int;
//    wire lmk_le_int;
//    wire [31:0] lmk_input;
//    wire        lmk_go;
//    reg         lmk_go_rereg = 0;
//    always @(posedge init_clk) lmk_go_rereg <= `DLYFF lmk_go;
//    wire        lmk_load = (lmk_go && !lmk_go_rereg);
//    wire        lmk_busy;
    
//    lmk_shift_reg u_lmk(.clk(init_clk),.load(lmk_load),.din(lmk_input),.busy(lmk_busy),
//                        .lmkdata_mon(lmk_data_int),.lmkclk_mon(lmk_clk_int),.lmkle_mon(lmk_le_int),
//                        .LMKDATA(LMKDATA),
//                        .LMKCLK(LMKCLK),
//                        .LMKLE(LMKLE));
    
    
//    // 6 bit alignment pattern = 011001
//    // aligned 011001
//    // next    110010
//    //         100101
//    //         001011
//    //         010110
//    //         101100
//    wire [5:0] data_to_surf;
//    wire clk_reset;
//    wire io_reset;
//    // This is ONLY FOR TESTING
//    // I need to yoink the internals on this because some of these pins need to be ker-flopped and the dorky
//    // IP doesn't allow for it

//    wire done_reset;
//    SRLC32E u_rstdelay(.D(1'b1),.CE(1'b1),.CLK(init_clk),.A(5'd0),.Q31(done_reset));
//    reg [1:0] done_reset_sysclk = {2{1'b0}};
//    always @(posedge sysclk) done_reset_sysclk <= { done_reset_sysclk[0], done_reset };        

////    generate
////        genvar i;
////        for (i=0;i<NSURF;i=i+1) begin : RB
////            wire rxclx_pos;
////            wire rxclk_neg;
////            wire cin_pos;
////            wire cin_neg;
////            assign RXCLK_P[i] = (RXCLK_INV[i]) ? rxclk_neg : rxclk_pos;
////            assign RXCLK_N[i] = (RXCLK_INV[i]) ? rxclk_pos : rxclk_neg;
////            assign CIN_P[i] = (CIN_INV[i]) ? cin_neg : cin_pos;
////            assign CIN_N[i] = (CIN_INV[i]) ? cin_pos : cin_neg;
////            rackbus_to_surf_custom #(.INV_DATA(CIN_INV[i] ^ CIN_REMOTE_INV[i]),
////                                     .INV_CLK(RXCLK_INV[i] ^ RXCLK_REMOTE_INV[i]))
////                            u_rtos(.clk_in(serclk),.clk_div_in(sysclk),
////                                   .data_out_from_device( data_to_surf ),
////                                   .clk_reset(clk_reset),
////                                   .io_reset(io_reset),
////                                   // INTENTIONAL
////                                   .clk_to_pins_n( rxclk_neg ),
////                                   .clk_to_pins_p( rxclk_pos ),
////                                   .data_out_to_pins_n( cin_neg),
////                                   .data_out_to_pins_p( cin_pos));
////        end
////    endgenerate    

    turf_interface #(.RXCLK_INV(T_RXCLK_INV),
                     .TXCLK_INV(T_TXCLK_INV),
                     .COUT_INV(T_COUT_INV),
                     .COUTTIO_INV(T_COUTTIO_INV),
                     .CIN_INV(T_CIN_INV))
        u_turf(.rxclk_o(rxclk),
               .rxclk_x2_o(rxclk_x2),        
               .RXCLK_P(T_RXCLK_P),
               .RXCLK_N(T_RXCLK_N),
               .TXCLK_P(T_TXCLK_P),
               .TXCLK_N(T_TXCLK_N),
               .COUTTIO_P(T_COUTTIO_P),
               .COUTTIO_N(T_COUTTIO_N),
               .CIN_P(T_CIN_P),
               .CIN_N(T_CIN_N));                     

    wire gtp_inclk;
    IBUFDS_GTE2 u_gtpclk( .I(F_LCLK_P),.IB(F_LCLK_N),.CEB(1'b0),.O(gtp_inclk));
    BUFG u_gtpclk_bufg(.I(gtp_inclk),.O(gtp_clk));
    
//    generate
//        if (SIMULATION == "FALSE") begin : NS
//            wire disable_3v3;
//            lmk_ila u_lmkila(.clk(init_clk),.probe0(lmk_clk_int),.probe1(lmk_data_int),.probe2(lmk_le_int));
//            lmk_vio u_lmkvio(.clk(init_clk),.probe_out0(lmk_go),.probe_out1(lmk_input),.probe_in0(lmk_busy),.probe_out2(do_sync_vio),.probe_out3(sysclk_reset),.probe_in1(locked));
////            jtag_ila u_ila(.clk(sysclk),.probe0(tdi_mon),.probe1(tck_mon),.probe2(tms_mon),.probe3(tdo_mon));
//            jtag_vio u_vio(.clk(init_clk),.probe_out0(jtag_load),.probe_out1(jtag_shift),.probe_out2(jtag_enable),.probe_in0(jtag_busy),.probe_out3(disable_3v3));
//            assign EN_3V3 = !disable_3v3;
//            rackbus_out_vio u_rbvio(.clk(sysclk),
//                                    .probe_out0(data_to_surf),
//                                    .probe_out1(clk_reset),
//                                    .probe_out2(io_reset));    
    
//        end else begin : SIM
//            assign lmk_go = 1'b0;
//            assign lmk_input = {32{1'b0}};
//            assign do_sync_vio = 1'b0;
            
//            assign jtag_shift = {8{1'b0}};
//            assign jtag_load = 1'b0;
//            assign jtag_enable = 1'b0;
            
//            assign data_to_surf = 6'b011001;
//            assign clk_reset = 1'b0;
//            assign io_reset = !done_reset_sysclk[1];
//            assign EN_3V3 = 1'b1;
//        end
//    endgenerate

    // this is dumbass-edly inverted with no hint in the name
    assign INITCLKSTDBY = 1'b1;
    // and this too
    assign EN_MYCLK_B = 1'b1;
    // plus this!
    assign EN_LCLK_B = 1'b1;
    
    // just leave this on for now
    assign EN_3V3 = 1'b1;    
endmodule

`undef DLYFF
