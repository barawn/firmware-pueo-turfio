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
                      parameter [7:0] VER_REV =   8'd23,
                      parameter [15:0] FIRMWARE_DATE = {16{1'b0}} )(
        // 40 MHz constantly on clock. Which we need to goddamn *boost*, just freaking BECAUSE
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
        // Enable SURFs
        output ENABLE,
        
        // Crate configuration
        input [1:0] CONF,
        
        // I2C
        inout F_SDA,
        inout F_SCL,
        input I2C_RDY,
        
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
        
        // 0: L18, K17 (inverted) 
        // 1: T18, R18 (inverted)
        // 2: U15, U16
        // 3: R7, T7
        // 4: V6, U7 (inverted)
        // 5: U4, V4
        // 6: L5, M5
        output [NSURF-1:0] RXCLK_P,
        output [NSURF-1:0] RXCLK_N,
        
        output [NSURF-1:0] CIN_P,
        output [NSURF-1:0] CIN_N, 

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
        output [6:0] T_COUT_P,
        output [6:0] T_COUT_N,
        // GTP stuff
        input F_LCLK_P,   // GTP clock D6
        input F_LCLK_N,   // GTP clock D5
        // MGTRX (n.b. this is inverted but it doesn't matter)
        input MGTRX_P,  // A4
        input MGTRX_N,  // A3
        // MGTTX
        output MGTTX_P, // F2
        output MGTTX_N, // F1
        //
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

    // For the boardman interface
    
    // Clock rate
    localparam INITCLK_RATE = 80000000;
    // Baud rate
    localparam BOARDMAN_BAUD = 115200;

    //////////////////////////////////////////////
    // CLOCKS                                   //
    //////////////////////////////////////////////
    
    // 40 MHz always running clock *input*
    wire init_clk_in;
    // 80 MHz initialization clock used for all the logic
    wire init_clk;
    // 200 MHz clock for IDELAYCTRLs (derived)
    wire clk200;
    // 125 MHz clock from the TURF arriving on RXCLK
    wire rxclk;
    // Rxclk is OK (toggling)
    wire rxclk_ok;
    // High speed (250 MHz) clock for digitizing CIN-type data
    wire rxclk_x2;
    // Local gigabit clock derived 
    wire gtp_clk;
    // System clock (from LMK)
    wire sysclk;
    // System clock x2 (derived) for COUT data
    wire sysclk_x2;
    // Sysclk is OK (toggling) 
    wire sysclk_ok;
    
    wire clk200_locked;
    BUFG u_initclk_bufg(.I(INITCLK),.O(init_clk_in));
    // init_clk and clk200 come out of the clock wizard.
    // init_clk is now *** 80 *** MHz
    clk200_wiz u_clk200(.clk_in1(init_clk_in),.reset(1'b0),.clk_out1(clk200),.clk_out2(init_clk),.locked(clk200_locked));
    IDELAYCTRL u_idelayctrl(.RST(!clk200_locked),.REFCLK(clk200));


    // Main wishbone bus. The address is a byte address, but it'll always be aligned on 32-bits
    // We have 4 master devices on the bus:
    // 0: gigabit transceiver (gtp)
    // 1: cin/cout (ctl)
    // 2: debug rx/tx (dbg)
    // 3: turf serial (ser)
    
    // We define this here so it's switchable for whatever reason.
    localparam WB_CLK_TYPE = "INITCLK";
    wire wb_clk = init_clk;

    `DEFINE_WB_IF( gtp_ , 22, 32);
    `DEFINE_WB_IF( ctl_ , 22, 32);
    `DEFINE_WB_IF( dbg_ , 22, 32);
    `DEFINE_WB_IF( ser_ , 22, 32);
    
    // And hook up the debug port which comes from the boardman interface.
    // fix this later
    wire [1:0] burst_size = 2'b00;
    boardman_wrapper #(.SIMULATION(SIMULATION),
                       .CLOCK_RATE(INITCLK_RATE),
                       .BAUD_RATE(BOARDMAN_BAUD))
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
    `DEFINE_WB_IF( aurora_ , 12, 32);
    
    // Command path data
    wire [31:0] turf_command;
    // Command path data is valid
    wire        turf_command_valid;
    // Sync request from command path
    wire        turf_cmdsync;
    // PPS request from command path
    wire        turf_cmdpps;
    // Command processor reset
    wire        turf_cmdproc_rst;
    // Command processor data
    wire [7:0]  turf_cmdproc_tdata;
    // Command processor data valid
    wire        turf_cmdproc_tvalid;
    // Command processor data last
    wire        turf_cmdproc_tlast;
    // Trigger time
    wire [14:0] turf_trigtime;
    // Trigger time valid
    wire        turf_trigtime_valid;

    // Sync indicator: first cycle of the 16-cycle clock period.
    wire        sync;
    // Sync offset (from TIO core)
    wire [7:0]  sync_offset;
    // Clock offset (from TIO core)
    wire [7:0]  clock_offset;
    // External sync enable (from TIO core)
    wire        en_ext_sync;
    // Clock time
    wire [47:0] sysclk_count;

    // Slave stubs    
    wbs_dummy #(.ADDRESS_WIDTH(12),.DATA_WIDTH(32)) u_hski2c_stub( `CONNECT_WBS_IFM(wb_ , hski2c_) );
    // Master stubs
//    wbm_dummy #(.ADDRESS_WIDTH(22),.DATA_WIDTH(32)) u_gtp_stub( `CONNECT_WBM_IFM(wb_ , gtp_ ));
    wbm_dummy #(.ADDRESS_WIDTH(22),.DATA_WIDTH(32)) u_ctl_stub( `CONNECT_WBM_IFM(wb_ , ctl_ ));
    wbm_dummy #(.ADDRESS_WIDTH(22),.DATA_WIDTH(32)) u_ser_stub( `CONNECT_WBM_IFM(wb_ , ser_ ));
    // Interconnect
    turfio_intercon #(.DEBUG("TRUE"))
        u_intercon( .clk_i(wb_clk),
                    .rst_i(1'b0),
                    `CONNECT_WBS_IFM(gtp_ , gtp_),
                    `CONNECT_WBS_IFM(ctl_ , ctl_),
                    `CONNECT_WBS_IFM(dbg_ , dbg_),
                    `CONNECT_WBS_IFM(ser_ , ser_),
                    
                    `CONNECT_WBM_IFM(tio_id_ctrl_ , tio_id_ctrl_ ),
                    `CONNECT_WBM_IFM(genshift_ , genshift_ ),
                    `CONNECT_WBM_IFM(surfturf_ , surfturf_ ),
                    `CONNECT_WBM_IFM(hski2c_ , hski2c_ ),
                    `CONNECT_WBM_IFM(aurora_ , aurora_ ));
    // ID control module
    tio_id_ctrl #(.DEVICE(IDENT),
                  .VERSION(DATEVERSION),
                  .WB_CLK_TYPE(WB_CLK_TYPE))
        u_id_ctrl( .wb_clk_i(wb_clk),
                   .wb_rst_i(1'b0),
                   `CONNECT_WBS_IFM( wb_ , tio_id_ctrl_ ),
                   
                   .enable_crate_o(ENABLE),
                   .enable_3v3_o(EN_3V3),
                   .crate_conf_i(CONF),
                   .i2c_rdy_i(I2C_RDY),
                   
                   .rx_clk_ok_o(rxclk_ok),
                   .sys_clk_ok_o(sysclk_ok),
                   .sys_clk_i(sysclk),
                   .sys_clk_x2_i(sysclk_x2),
                   .gtp_clk_i(gtp_clk),
                   .rx_clk_i(rxclk),
                   .rx_clk_x2_i(rxclk_x2),
                   .clk200_i(clk200),
                   .en_ext_sync_o(en_ext_sync),
                   .clk_offset_o(clock_offset),
                   .sync_offset_o(sync_offset)
                   
                   );
    // Genshift module    
    turfio_gen_shift_wrapper
        u_genshift( .wb_clk_i(wb_clk),
                    .wb_rst_i(1'b0),
                    `CONNECT_WBS_IFM( wb_ , genshift_ ),
                    // DEBUG ONLY
                    .F_SDA(F_SDA),
                    .F_SCL(F_SCL),

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
    // SURFTURF module. This is just the TURF component for now.
    // Internally it gets mapped to a subset of the address space. Here it just
    // connects up what it can.
    surfturf_wrapper #(.T_RXCLK_INV(T_RXCLK_INV),
                       .T_TXCLK_INV(T_TXCLK_INV),
                       .T_COUT_INV(T_COUT_INV),
                       .T_COUTTIO_INV(T_COUTTIO_INV),
                       .T_CIN_INV(T_CIN_INV),
                       .RXCLK_INV(RXCLK_INV),
                       .TXCLK_INV(TXCLK_INV),
                       .COUT_INV(COUT_INV),
                       .CIN_INV(CIN_INV),
                       .DOUT_INV(DOUT_INV),
                       .WB_CLK_TYPE(WB_CLK_TYPE))
        u_surfturf(.wb_clk_i(wb_clk),
               .wb_rst_i(1'b0),
               `CONNECT_WBS_IFM( wb_ , surfturf_ ),
               
                .sync_i(sync),
                .command_o(turf_command),
                .command_valid_o(turf_command_valid),
                
               .rxclk_o(rxclk),
               .rxclk_ok_i(rxclk_ok),
               .rxclk_x2_o(rxclk_x2),        
               .sysclk_i(sysclk),
               .sysclk_ok_i(sysclk_ok),
               .sysclk_x2_i(sysclk_x2),
               .T_RXCLK_P(T_RXCLK_P),
               .T_RXCLK_N(T_RXCLK_N),
               .T_TXCLK_P(T_TXCLK_P),
               .T_TXCLK_N(T_TXCLK_N),
               .T_COUTTIO_P(T_COUTTIO_P),
               .T_COUTTIO_N(T_COUTTIO_N),
               .T_COUT_P(T_COUT_P),
               .T_COUT_N(T_COUT_N),
               .T_CIN_P(T_CIN_P),
               .T_CIN_N(T_CIN_N),
               
               .RXCLK_P(RXCLK_P),
               .RXCLK_N(RXCLK_N),
               .CIN_P(CIN_P),
               .CIN_N(CIN_N)
               );                     

    pueo_command_decoder u_decoder(.sysclk_i(sysclk),
                                   .command_i(turf_command),
                                   .command_valid_i(turf_command_valid),
                                   .cmdsync_o(turf_cmdsync),
                                   .cmdpps_o(turf_cmdpps),
                                   .cmdproc_rst_o(turf_cmdproc_rst),
                                   .cmdproc_tdata(turf_cmdproc_tdata),
                                   .cmdproc_tvalid(turf_cmdproc_tvalid),
                                   .cmdproc_tlast(turf_cmdproc_tlast),
                                   .trig_time_o(turf_trigtime),
                                   .trig_valid_o(turf_trigtime_valid));

    turfio_sync_sysclk_count u_synccount(.sysclk_i(sysclk),
                                         .sync_offset_i(sync_offset),
                                         .clock_offset_i(clock_offset),
                                         .en_ext_sync_i(en_ext_sync),
                                         .sysclk_count_o(sysclk_count),
                                         .sync_req_i(turf_cmdsync),
                                         .sync_o(sync),
                                         .dbg_surf_clk_o(DBG_LED),
                                         .SYNC(CLK_SYNC));
    
    wire locked;
    wire sysclk_reset=1'b0;
    sys_clk_generator u_sysclkgen(.clk_in1_p(CLKDIV2_P),
                                  .clk_in1_n(CLKDIV2_N),
                                  .reset(sysclk_reset),
                                  .sys_clk(sysclk),
                                  .sys_clk_x2(sysclk_x2),
                                  .locked(locked));
    
    wire gtp_inclk;
    IBUFDS_GTE2 u_gtpclk( .I(F_LCLK_P),.IB(F_LCLK_N),.CEB(1'b0),.O(gtp_inclk));
    BUFG u_gtpclk_bufg(.I(gtp_inclk),.O(gtp_clk));
    // Now we hook up Aurora. Really need to figure out the whole aresetn thing
    `DEFINE_AXI4S_MIN_IF( cmd_addr_ , 32 );
    `DEFINE_AXI4S_MIN_IF( cmd_data_ , 32 );
    `DEFINE_AXI4S_MIN_IF( cmd_resp_ , 32 );
    aurora_wb_master u_wbgtp( .aclk(wb_clk),
                              .aresetn(1'b1),
                              `CONNECT_AXI4S_MIN_IF( s_addr_ , cmd_addr_ ),
                              `CONNECT_AXI4S_MIN_IF( s_data_ , cmd_data_ ),
                              `CONNECT_AXI4S_MIN_IF( m_resp_ , cmd_resp_ ),
                              
                              `CONNECT_WBM_IFM( wb_ , gtp_ ));
        
    // Main path ifs. Just killed for now.
    `DEFINE_AXI4S_MIN_IF( aurora_in_ , 32 );
    `DEFINE_AXI4S_MIN_IF( aurora_out_ , 32 );
    // kill 'em
    assign aurora_out_tready = 1'b1;
    assign aurora_in_tvalid = 1'b0;
    assign aurora_in_tdata = {32{1'b0}};
    // shove inbounds into ilas
    aurora_cmd_ila u_acmd_ila(.clk(wb_clk),
                         .probe0( cmd_addr_tdata ),
                         .probe1( cmd_addr_tvalid ),
                         .probe2( cmd_data_tdata ),
                         .probe3( cmd_data_tvalid ),
                         .probe4( cmd_resp_tdata ),
                         .probe5( cmd_resp_tvalid) );
//    aurora_trig_ila u_atrig_ila(.clk(sysclk),
//                                .probe0( aurora_out_tdata ),
//                                .probe1( aurora_out_tvalid ));                 
    // ok here we go
    turf_aurora_wrapper u_aurora( .wb_clk_i(wb_clk),
                                  .wb_rst_i(1'b0),
                                  `CONNECT_WBS_IFM( wb_ , aurora_ ),
                                  `CONNECT_AXI4S_MIN_IF( m_cmd_addr_ , cmd_addr_ ),
                                  `CONNECT_AXI4S_MIN_IF( m_cmd_data_ , cmd_data_ ),
                                  `CONNECT_AXI4S_MIN_IF( s_cmd_data_ , cmd_resp_ ),
                                  .sys_clk_i(sysclk),
                                  `CONNECT_AXI4S_MIN_IF( s_axis_ , aurora_in_ ),
                                  `CONNECT_AXI4S_MIN_IF( m_axis_ , aurora_out_ ),
                                  
                                  .gtp_inclk_i(gtp_inclk),
                                  .MGTRX_P(MGTRX_P),
                                  .MGTRX_N(MGTRX_N),
                                  .MGTTX_P(MGTTX_P),
                                  .MGTTX_N(MGTTX_N));
    


    // this is dumbass-edly inverted with no hint in the name
    assign INITCLKSTDBY = 1'b1;
    // and this too
    assign EN_MYCLK_B = 1'b1;
    // plus this!
    assign EN_LCLK_B = 1'b1;
    
endmodule

`undef DLYFF
