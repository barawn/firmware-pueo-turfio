`timescale 1ns / 1ps
`define DLYFF #0.5
`include "interfaces.vh"
// PUEO TURFIO Firmware.
//
// Still a horrible work in progress: however, I'm trying to move to a more normalized
// setup for interfacing with the flight computer. Serial port debug interface is based
// on the RADIANT comms.
//
// Now with TURFy housekeeping!
module pueo_turfio #( parameter NSURF=7, 
                      parameter SIMULATION="FALSE",
                      parameter IDENT="TFIO",
                      parameter [3:0] VER_MAJOR = 4'd0,
                      parameter [3:0] VER_MINOR = 4'd2,
                      parameter [7:0] VER_REV =   8'd12,
                      parameter [15:0] FIRMWARE_DATE = {16{1'b0}} )(
        // 40 MHz constantly on clock. Which we need to goddamn *boost*, just freaking BECAUSE
        input INITCLK,
        // Force initclk into standby
        output INITCLKSTDBY,
        
        // Debug receive (from FT2232)
        input DBG_RX,
        // Debug transmit (to FT2232) 
        output DBG_TX,
        // Crate RX (L14) - same side as ENABLE - this goes to pin 53 on SURF
        // This is just called RX on schematic
        output SURF_RX,         // this is just straight output, hopefully the 2.5V is OK
                                // DS926 lists Vihmin as 2.00 so it should be fine.
        // Crate TX (U10) - same side as \ALERT - this goes to pin 54 on SURF
        // this is just called TX on schematic
        input SURF_TX,          // this is an open-drain input and might need to be retimed

        // serial output to TURF - only enabled with T_CTRL low
        output F_TTX,   // D15
        // serial input from TURF - only valid with T_CTRL low
        input TRX,      // B15
        // control input : selects between serial path and remote I2C control
        input TCTRL_B,  // D9
        // This USED to be TGPIO1. It is now system reset from TURF. Makes sure comms will work.
        input SYS_RESET_B, // B17. This is pulled up internally and can be used to tell if a TURFIO
                           // is present and programmed at the TURF.
        
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
        // I'm not going to worry about I2C_RDY for now because
        // I'm just going to assume if the TURF is I2C-ing
        // someone put the housekeeping processor in reset.
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
    
        // COUT0: V14, U14  (inverted)
        // COUT1: U11, V11
        // COUT2: T12, U12
        // COUT3: U1, U2 (inverted)
        // COUT4: V2, V3 (inverted)
        // COUT5: M1, M2 (inverted)
        // COUT6: L2, K3 (inverted)
        input [NSURF-1:0] COUT_P,
        input [NSURF-1:0] COUT_N,
        
        // TXCLK0: R17, R16
        // TXCLK1: T14, T15
        // TXCLK2: P14, R15
        // TXCLK3: R3, T2
        // TXCLK4: R2, R1 (inverted)
        // TXCLK5: P4, P3
        // TXCLK6: N3, N2
        inout [NSURF-1:0] TXCLK_P,
        inout [NSURF-1:0] TXCLK_N,

        input [NSURF-1:0] DOUT_P,
        input [NSURF-1:0] DOUT_N,
    
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
        output DBG_LED,
        // GPIOs
        input [1:0] GPI,
        output [1:0] GPO,
        output [1:0] GPOE_B,
        
        // 100% unused
        input VP,
        input VN
    );
    
    localparam [15:0] FIRMWARE_VERSION = {VER_MAJOR, VER_MINOR, VER_REV};
    localparam [31:0] DATEVERSION = { FIRMWARE_DATE, FIRMWARE_VERSION };
        
    localparam USE_VIO = "FALSE";

    // TURFIO inversion:
    // RXCLK[6:0] = 001_0011
    // CIN[6:0]   = 011_0001
    // COUT[6:0] =  111_1001
    // DOUT[6:0] =  010_1000
    // TXCLK[6:0] = 001_0000                          = 7'h10    
    localparam [6:0] RXCLK_INV = 7'b001_0011;
    localparam [6:0] CIN_INV   = 7'b011_0001;
    localparam [6:0] COUT_INV  = 7'b111_1001;
    localparam [6:0] DOUT_INV  = 7'b010_1000;
    localparam [6:0] TXCLK_INV = 7'b001_0000;        
            
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
    //    localparam BOARDMAN_BAUD = 115200;
    // Up the baudrate, 115,200 is stupidly slow. 80 MHz can generate a 16x oversampled clock fine.
    // goddamnit eff this, just max it out, baby
    // this still works with our BRG: it adds 512 each time
    // higher MIGHT work but then the en_16x_baud isn't a flag
    // anymore and not sure if that's ok
    // this is obviously perfect    
    localparam BOARDMAN_BAUD = 2500000;

    // debugging!!
    wire [7:0] user4_gpo;
        
    //////////////////////////////////////////////
    // UART GOOFINESS                           //
    //////////////////////////////////////////////    

    // user4_gpo[0]     tctrl_b     HSK path
    // 0                0           TRX -> uart_to_crate , uart_from_crate -> F_TTX
    // 1                X           DBG_RX -> uart_to_crate, uart_from_crate ->  DBG_TX
    // 0                1           1 -> uart_to_crate, uart_from_crate -> open

    // if cratebridge_enable is 0, we DO NOT send data
    // to SURFs OR receive data
    // EITHER user4 OR hsk can enable crate HSKbus
    wire cratebridge_enable_hsk;
    wire cratebridge_enable_user4 = user4_gpo[1];
    wire cratebridge_enable = cratebridge_enable_hsk || cratebridge_enable_user4;
    wire hskbus_enable_local = user4_gpo[0];

    // we moved a lot of the uart merge stuff into a module

    // merged uarts
    wire uart_from_crate;
    wire uart_to_crate;

    // to/from surf
    wire uart_from_surf;
    wire uart_to_surf;
    assign SURF_RX = uart_to_surf;
    
    // to/from hsk
    wire uart_to_hsk;
    wire uart_from_hsk;
    
    // to/from TURF. this is still external
    wire uart_from_turf;
    wire uart_to_turf;
    
    // to/from boardman.
    wire uart_from_boardman;
    wire uart_to_boardman;

    /***********************************************/
    /* UART ROUTING                                */
    /* if hskbus_enable_local:                     */
    /* - Detach TURF UART. Detach boardman UART.   */
    /* - Attach uart_to_crate to DBG_RX.           */
    /* - Attach DBG_TX to uart_from_crate.         */
    /* if not hskbus_enable_local:                 */
    /* - Attach uart_to_boardman to DBG_RX.        */
    /* - Attach DBG_TX to uart_from_boardman.      */
    /* - Attach uart_to_crate to TURF RX.          */
    /* - Attach TURF_TX to uart_from_crate.        */
    /***********************************************/

    // DBG uart ->boardman uart only when user4_gpo[0] is low, otherwise it's crate
    assign uart_to_boardman = (hskbus_enable_local) ? 1'b1 : DBG_RX;
    assign DBG_TX = (hskbus_enable_local) ? uart_from_crate : uart_from_boardman;

    // uart from turf <-> surf only when TCTRL_B is low and user4_gpo[0] is low
    // uarts IDLE HIGH so set to 1 when not valid
    assign uart_from_turf = (!TCTRL_B) ? TRX : 1'b1;
    assign uart_to_turf = (!hskbus_enable_local) ? uart_from_crate : 1'b1;
    assign F_TTX = uart_to_turf;

    assign uart_to_crate = (hskbus_enable_local) ? DBG_RX : uart_from_turf;

    /***********************************************/

    //////////////////////////////////////////////
    // AURORA                                   //
    //////////////////////////////////////////////
    wire lane_up;

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
    //////////////////////////////////////////////////////////////////////////////////
    //                          TURF SYSTEM RESET                                   //
    //////////////////////////////////////////////////////////////////////////////////
    
    (* IOB = "TRUE" *)
    reg  sys_rst_b_reg = 1'b1;
    wire sys_rst_b = sys_rst_b_reg;
    wire sys_rst = !sys_rst_b;
    always @(posedge init_clk) sys_rst_b_reg <= SYS_RESET_B;
    
    //////////////////////////////////////////////////////////////////////////////////
    //                              HOUSEKEEPING                                    //
    //////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////
    //                             UART MERGING                                     //
    //////////////////////////////////////////////////////////////////////////////////

    generate
        if (USE_VIO == "TRUE") begin : VIO
            hsk_vio u_hskvio(.clk(init_clk),
                             .probe_in0(TCTRL_B),
                             .probe_in1(hskbus_enable_local),
                             .probe_in2(TRX),
                             .probe_in3(DBG_RX),
                             .probe_in4(SURF_RX),
                             .probe_in5(sys_rst_b_reg));
        end
    endgenerate
            
    wire [7:0] hskbus_rx_bytes;    
    
    uart_hskbus_merge #(.DEBUG("FALSE"))
                      u_hskbus_merge(.clk_i(init_clk),
                                     .rst_i(sys_rst),
                                     .hskbus_rx_bytes_o(hskbus_rx_bytes),
                                     .hskbus_tx_i(uart_to_crate),
                                     .hskbus_rx_o(uart_from_crate),
                                     
                                     .surf_rx_i(uart_from_surf),
                                     .surf_tx_o(uart_to_surf),
                                     
                                     .hski2c_rx_i(uart_from_hsk),
                                     .hski2c_tx_o(uart_to_hsk),
                                     
                                     .crate_enable_i(cratebridge_enable));
    
    // housekeeping shares control of enable and I2C (horribly)
    wire hsk_enable_t;
    wire hsk_enable_i;
    wire hsk_enable_o;
    wire sda_i;
    wire sda_t;
    wire scl_i;
    wire scl_t;
    
    // retimed using an 0.5 Mbaud baud rate and a 1 us risetime.
    uart_retime #(.SAMPLE_POINT(120),
                  .BAUD_PERIOD(160),
                  .DEBUG("FALSE")) u_retimer(.clk(init_clk),
                                               .crate_enabled_i(cratebridge_enable),
                                               .RX(SURF_TX),
                                               .RX_RETIMED(uart_from_surf));
                                                                                             
    //////////////////////////////////////////////////////////////////////////////////
    //                               WISHBONE BUS                                   //
    //////////////////////////////////////////////////////////////////////////////////
    // The WISHBONE bus inside the TURFIO is a little complicated.
    // We're currently simplifying it a bit by cutting things down.
    // There are only going to be 2 overall masters: the debug path and the GTP path.
    // - except each of the debug/GTP paths are split into "SURFbridge" and "TURFIO"
    // masters based on their address selection, and then there are arbiters inside
    // the SURFbridges and TURFIO intercon separately.
    // 
    // We define this here so it's switchable for whatever reason.
    localparam WB_CLK_TYPE = "INITCLK";
    wire wb_clk = init_clk;

    // this swaps our debug UART to the rack UART for testing
    jtaguser4 #(.DATA_WIDTH(8))
        u_user4(.clk_i(init_clk),
                .dat_o(user4_gpo));

    // These are the MAIN masters. They have 25-bit addresses.
    // Bits [25:23] determine which space is being accessed.
    // (bits 27:26 determine which of the 4 TURFIOs at the TURF, and
    //  bit 28 determines TURF via crate).

    // GTP master
    `DEFINE_WB_IF( gtp_ , 25, 32);
    // Debug master
    `DEFINE_WB_IF( dbg_ , 25, 32);
    // Burst size when burst is set (comes from tio_id_ctrl)
    wire [1:0] dbg_burst_size;
    // Upper addr when upper addr bit is set (comes from tio_id_ctrl)
    wire [3:0] dbg_upper_addr;        
    turfio_boardman_wrapper #(.SIMULATION(SIMULATION),
                              .CLOCK_RATE(INITCLK_RATE),
                              .BAUD_RATE(BOARDMAN_BAUD))
            u_boardman( .wb_clk_i(wb_clk),
                        .wb_rst_i(1'b0),
                        `CONNECT_WBM_IFM( wb_ , dbg_ ),
                        .burst_size_i(dbg_burst_size),
                        .upper_addr_i(dbg_upper_addr),
                        .TX(uart_from_boardman),
                        .RX(uart_to_boardman));            

    `DEFINE_AXI4S_MIN_IF( cmd_addr_ , 32 );
    `DEFINE_AXI4S_MIN_IF( cmd_data_ , 32 );
    `DEFINE_AXI4S_MIN_IF( cmd_resp_ , 32 );
    aurora_wb_master #(.ADDR_BITS(25),.DEBUG("FALSE"))
                     u_wbgtp( .aclk(wb_clk),
                              .aresetn(sys_rst_b),
                              `CONNECT_AXI4S_MIN_IF( s_addr_ , cmd_addr_ ),
                              `CONNECT_AXI4S_MIN_IF( s_data_ , cmd_data_ ),
                              `CONNECT_AXI4S_MIN_IF( m_resp_ , cmd_resp_ ),
                              
                              `CONNECT_WBM_IFM( wb_ , gtp_ ));

    // We then split each of the masters into a TURFIO and a SURFbridge master based on 
    // address access. An additional 3-bit user value handles which SURF is being accessed (0 is never used).
    `DEFINE_WB_IF( gtp_turfio_ , 22, 32);
    `DEFINE_WB_IF( gtp_surf_ , 22, 32);
    wire [2:0] gtp_surf_select;
    `DEFINE_WB_IF( dbg_turfio_ , 22, 32);
    `DEFINE_WB_IF( dbg_surf_ , 22, 32);
    wire [2:0] dbg_surf_select;
    // Split happens here.
    wb_surfturfio_splitter u_gtp_split(`CONNECT_WBS_IFM( wb_ , gtp_ ),
                                       `CONNECT_WBM_IFM( wb_turfio_ , gtp_turfio_ ),
                                       `CONNECT_WBM_IFM( wb_surf_ , gtp_surf_ ),
                                       .wb_surf_select_o(gtp_surf_select));
    wb_surfturfio_splitter u_dbg_split(`CONNECT_WBS_IFM( wb_ , dbg_ ),
                                       `CONNECT_WBM_IFM( wb_turfio_ , dbg_turfio_ ),
                                       `CONNECT_WBM_IFM( wb_surf_ , dbg_surf_ ),
                                       .wb_surf_select_o(dbg_surf_select));
    // TURFIO INTERCONS
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
    
    // ADD HSKI2C HERE
    hski2c_top #(.DEBUG("TRUE")) 
               u_hsk(.wb_clk_i(wb_clk),
                     .wb_rst_i(1'b0),
                     .sys_rst_i(sys_rst),
                     `CONNECT_WBS_IFM( wb_ , hski2c_ ),
                     .lane_up_i(lane_up),
                     .hsk_enable_i(hsk_enable_i),
                     .hsk_enable_o(hsk_enable_o),
                     .hsk_enable_t(hsk_enable_t),
                     .cratebridge_en_o(cratebridge_enable_hsk),
                     .cratebridge_en_i(cratebridge_enable),
                     .sda_i(sda_i),
                     .sda_t(sda_t),
                     .scl_i(scl_i),
                     .scl_t(scl_t),
                     .CONF(CONF),
                     .HSK_RX(uart_to_hsk),
                     .HSK_TX(uart_from_hsk),
                     .VP(VP),
                     .VN(VN),
                     .I2C_RDY(I2C_RDY));
                     
    
    // Command path data
    wire [31:0] turf_command;
    // Command path data is valid
    wire        turf_command_valid;
    // Sync request from runcmds
    wire        turf_runsync;
    // Start a run (reset your damn timer)
    wire        turf_runreset;
    // Stop a run (uh this is totally ignored here)
    wire        turf_runstop;
    // PPS via CIN commanding
    wire        turf_cmdpps;
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

    // WE HAVE NO MORE STUBS!!

    // Interconnect, now reduced.
    turfio_intercon #(.DEBUG("FALSE"))
        u_intercon( .clk_i(wb_clk),
                    .rst_i(1'b0),
                    `CONNECT_WBS_IFM(gtp_ , gtp_turfio_),
                    `CONNECT_WBS_IFM(dbg_ , dbg_turfio_),
                    
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
                   
                   .burst_size_o(dbg_burst_size),
                   .upper_addr_o(dbg_upper_addr),
                   
                   .hsk_enable_i(hsk_enable_i),
                   .hsk_enable_o(hsk_enable_o),
                   .hsk_enable_t(hsk_enable_t),
                                      
                   .hsk_local_i(hskbus_enable_local),
                   .hskbus_crate_i(cratebridge_enable),
                   .hskbus_rx_bytes_i(hskbus_rx_bytes),
                                                         
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
    turfio_gen_shift_wrapper #(.DEBUG("FALSE"))
        u_genshift( .wb_clk_i(wb_clk),
                    .wb_rst_i(1'b0),
                    `CONNECT_WBS_IFM( wb_ , genshift_ ),
                    // the I2C bus is shared between the GPIOs
                    // in the genshift wrapper and the hski2c
                    // in order to use it you should STOP the
                    // hsk processor in the TURFIO before mucking with it
                    .sda_in_o(sda_i),
                    .sda_t_i(sda_t),
                    .scl_in_o(scl_i),
                    .scl_t_i(scl_t),
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

//                if (i == 1 || i == 2) begin : TEST
//                    surf_rackctl_test #(.INV(TXCLK_INV[i-1]),.DEBUG("TRUE"))
//                                   u_test(.sysclk_i(sysclk_i),
//                                          .RACKCTL_P(TXCLK_P[i-1]),
//                                          .RACKCTL_N(TXCLK_N[i-1]));
//                end

    // SURFTURF module. This is just the TURF component for now.
    // Internally it gets mapped to a subset of the address space. Here it just
    // connects up what it can.
    
    // HOOK THESE UP TO FRIGGIN SOMETHING    
    `DEFINE_AXI4S_MIN_IF( mode1_ , 8);
    wire [1:0] mode1_tuser;
    `DEFINE_AXI4S_MIN_IF( tfio_runcmd_ , 2);
    `DEFINE_AXI4S_MIN_IF( tfio_trig_ , 15);
    
    // MASSIVE DATAPATH
    `DEFINE_AXI4S_MIN_IF( s0_ , 8 );
    wire s0_tlast;
    `DEFINE_AXI4S_MIN_IF( s1_ , 8 );
    wire s1_tlast;
    `DEFINE_AXI4S_MIN_IF( s2_ , 8 );
    wire s2_tlast;
    `DEFINE_AXI4S_MIN_IF( s3_ , 8 );
    wire s3_tlast;
    `DEFINE_AXI4S_MIN_IF( s4_ , 8 );
    wire s4_tlast;
    `DEFINE_AXI4S_MIN_IF( s5_ , 8 );
    wire s5_tlast;
    `DEFINE_AXI4S_MIN_IF( s6_ , 8 );
    wire s6_tlast;
    
    surfturf_wrapper_v2 #(.T_RXCLK_INV(T_RXCLK_INV),
                       .T_TXCLK_INV(T_TXCLK_INV),
                       .T_COUT_INV(T_COUT_INV),
                       .T_COUTTIO_INV(T_COUTTIO_INV),
                       .T_CIN_INV(T_CIN_INV),
                       .RXCLK_INV(RXCLK_INV),
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
                
                `CONNECT_AXI4S_MIN_IF( m_s0_ , s0_ ),
                .m_s0_tlast(s0_tlast),
                `CONNECT_AXI4S_MIN_IF( m_s1_ , s1_ ),
                .m_s1_tlast(s1_tlast),
                `CONNECT_AXI4S_MIN_IF( m_s2_ , s2_ ),
                .m_s2_tlast(s2_tlast),
                `CONNECT_AXI4S_MIN_IF( m_s3_ , s3_ ),
                .m_s3_tlast(s3_tlast),
                `CONNECT_AXI4S_MIN_IF( m_s4_ , s4_ ),
                .m_s4_tlast(s4_tlast),
                `CONNECT_AXI4S_MIN_IF( m_s5_ , s5_ ),
                .m_s5_tlast(s5_tlast),
                `CONNECT_AXI4S_MIN_IF( m_s6_ , s6_ ),
                .m_s6_tlast(s6_tlast),
                
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
               
               .COUT_P(COUT_P),
               .COUT_N(COUT_N),
               .DOUT_P(DOUT_P),
               .DOUT_N(DOUT_N),
               .RXCLK_P(RXCLK_P),
               .RXCLK_N(RXCLK_N),
               .CIN_P(CIN_P),
               .CIN_N(CIN_N)
               );                     

    surf_bridge #(.RACKCTL_INV( TXCLK_INV ),
                  .WB_CLK_TYPE(WB_CLK_TYPE),
                  .DEBUG("FALSE"))
        u_bridge( .wb_clk_i(wb_clk),
                  .wb_rst_i(1'b0),
                  `CONNECT_WBS_IFM( gtp_ , gtp_surf_ ),
                  .gtp_select_i(gtp_surf_select),
                  `CONNECT_WBS_IFM( dbg_ , dbg_surf_ ),
                  .dbg_select_i(dbg_surf_select),
                  // HOOK THESE UP
                  .bridge_err_o(),
                  .err_rst_i(1'b0),
                  .sysclk_i(sysclk),
                  .sysclk_ok_i(sysclk_ok),
                  .RACKCTL_P(TXCLK_P),
                  .RACKCTL_N(TXCLK_N));
//    // STUB OFF THE SURF INTERFACE FOR NOW TO TEST TO MAKE SURE IT STILL WORKS
//    wbs_dummy #(.ADDRESS_WIDTH(22),.DATA_WIDTH(32)) u_dbgsurf_stub( `CONNECT_WBS_IFM(wb_ , dbg_surf_ ) );
//    wbs_dummy #(.ADDRESS_WIDTH(22),.DATA_WIDTH(32)) u_gtpsurf_stub( `CONNECT_WBS_IFM(wb_ , gtp_surf_ ) );    

    // V2 COMMAND DECODER IS WAY EFFING SIMPLER
    // WE DON'T EVEN BOTHER WITH COMMAND PROCESSOR STUFF IT WON'T COME THIS WAY IT'LL BE SPLICED IN
    // AT LEAST FROM THE TURFIO'S POINT OF VIEW IT'S TOTALLY USELESS EXCEPT FOR SPYING

    // AT THE TURFIO SIDE, WE ONLY CARE ABOUT
    // -> DO_SYNC
    // -> RESET
    // -> STOP
    // -> TRIGGER OUTPUTS
    // -> PPS
    // THE MODE1 STUFF CAN BE IGNORED AT THE TURFIO SIDE EXCEPT TO SPY
    pueo_turfio_command_decoder u_decoder(.sysclk_i(sysclk),
                                      .command_i(turf_command),
                                      .command_valid_i(turf_command_valid),

                                      .sync_o(turf_runsync),
                                      .reset_o(turf_runreset),
                                      .stop_o(turf_runstop),

                                      .pps_o(turf_cmdpps),
                                      
                                      .trig_time_o(turf_trigtime),
                                      .trig_time_valid_o(turf_trigtime_valid));

    assign GPOE_B[1] = 1'b0;
    turfio_sync_sysclk_count #(.DEBUG("FALSE"))
                             u_synccount(.sysclk_i(sysclk),
                                         .sync_offset_i(sync_offset),
                                         .clock_offset_i(clock_offset),
                                         .en_ext_sync_i(en_ext_sync),
                                         .sysclk_count_o(sysclk_count),
                                         .sync_req_i(turf_runsync ),
                                         .sync_o(sync),
                                         .dbg_surf_clk_o(GPO[1]),
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
        
    `DEFINE_AXI4S_MIN_IF( aurora_in_ , 32 );
    wire aurora_in_tlast;
    `DEFINE_AXI4S_MIN_IF( aurora_out_ , 32 );
    // kill the outbound.
    assign aurora_out_tready = 1'b1;
    // the inbounds come from the event merger!!

    // MERGER GOES HERE!!!!!!
    surf_merger #(.DEBUG("FALSE")) u_merger( .aclk( sysclk ),
                          // uhhhhhh figure this out
                          .aresetn( 1'b1 ),
                          `CONNECT_AXI4S_MIN_IF( s_s0_ , s0_ ),
                          .s_s0_tlast( s0_tlast ),
                          `CONNECT_AXI4S_MIN_IF( s_s1_ , s1_ ),
                          .s_s1_tlast( s1_tlast ),
                          `CONNECT_AXI4S_MIN_IF( s_s2_ , s2_ ),
                          .s_s2_tlast( s2_tlast ),
                          `CONNECT_AXI4S_MIN_IF( s_s3_ , s3_ ),
                          .s_s3_tlast( s3_tlast ),
                          `CONNECT_AXI4S_MIN_IF( s_s4_ , s4_ ),
                          .s_s4_tlast( s4_tlast ),
                          `CONNECT_AXI4S_MIN_IF( s_s5_ , s5_ ),
                          .s_s5_tlast( s5_tlast ),
                          `CONNECT_AXI4S_MIN_IF( s_s6_ , s6_ ),
                          .s_s6_tlast( s6_tlast ),
                          
                          `CONNECT_AXI4S_MIN_IF( m_ev_ , aurora_in_ ),
                          .m_ev_tlast( aurora_in_tlast ));
                          
                          

    // ok here we go
    turf_aurora_wrapper u_aurora( .wb_clk_i(wb_clk),
                                  .wb_rst_i(1'b0),
                                  `CONNECT_WBS_IFM( wb_ , aurora_ ),
                                  `CONNECT_AXI4S_MIN_IF( m_cmd_addr_ , cmd_addr_ ),
                                  `CONNECT_AXI4S_MIN_IF( m_cmd_data_ , cmd_data_ ),
                                  `CONNECT_AXI4S_MIN_IF( s_cmd_data_ , cmd_resp_ ),
                                  .lane_up_o(lane_up),
                                  .sys_clk_i(sysclk),
                                  .cmd_rstb_i(sys_rst_b),
                                  `CONNECT_AXI4S_MIN_IF( s_axis_ , aurora_in_ ),
                                  .s_axis_tlast(aurora_in_tlast),
                                  .s_axis_tkeep( {4{1'b1}} ),
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
