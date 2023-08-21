`timescale 1ns / 1ps
`include "interfaces.vh"

// 12-bit address space, 10 bits real. Mapping is:
// 0x000 - 0x7FF: control register space
// 0x800 - 0xFFF: DRP space
module turf_aurora_wrapper(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF( wb_ , 12, 32 ),
        
        // These are all in the wb_clk domain
        // Command address + type
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_cmd_addr_ , 32),
        // Command data (for writes only)
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_cmd_data_ , 32),
        // Response data (for reads only). These are ONLY 32-bit, so don't need anything else.
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_cmd_data_ , 32),

        // sysclk. regular data path is in sysclk domain
        input sys_clk_i,
                
        // regular input data path.
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_axis_ , 32 ),
        input [3:0] s_axis_tkeep,
        input s_axis_tlast,
        // who freaking knows
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_axis_ , 32 ),
        output [3:0] m_axis_tkeep,
        output m_axis_tlast,
        
        input gtp_inclk_i,
        
        input MGTRX_P,
        input MGTRX_N,
        output MGTTX_P,
        output MGTTX_N
    );
    
    // sigh, ok, let's do this.
    
    // link status register. This will be captured by wb_dat_reg.
    wire [31:0] link_status;
    // this is the pure link status register in userclk
    wire [31:0] link_status_userclk;
    // this is the *holding* register in userclk for link status
    (* CUSTOM_CC_SRC = "USERCLK" *)
    reg [31:0] link_status_userclk_reg = {32{1'b0}};
    // link control register
    wire [31:0] link_control;
    // link digital monitor register
    wire [31:0] link_dmonitor;
    // link eye scan control register
    wire [31:0] link_eyescan;
    
    // Init clk is the wb_clk
    wire init_clk = wb_clk_i;
    // TX output clk (derived from incoming data)
    wire tx_out_clk;
    // TX output is locked (feeds into the clock module)
    wire tx_lock;
    // User clock (for Aurora interfaces)
    wire user_clk;
    // Sync clock (for internal Aurora use)
    wire sync_clk;
    // Clocks aren't locked.
    wire pll_not_locked;
    
    // Clock module. Because we're 4-lane, we require an MMCM.
    aurora_turf_clock u_clocks( .tx_outclk_i( tx_out_clk ),
                                .tx_locked_i( tx_lock ),
                                .user_clk_o ( user_clk ),
                                .sync_clk_o ( sync_clk ),
                                .pll_not_locked_o( pll_not_locked ));
    
    // The exdesign's reset module is just horse-crap, so we redo it.
    
    // this feeds "reset" input. reset is an async input from the reset module
    wire system_reset;
    // this feeds the "gt_reset" input. gt_reset is also an async input
    wire gt_reset;
    // input to the clock module. This is just a regular register I guess
    reg gt_reset_in = 0; 
    // also a regular register
    reg reset_in = 0;
    // powerdown register in wbclk. This is synced over using standard XPM
    reg gt_powerdown_wbclk = 0;
    // loopback register in wbclk. This is synced over using our async register
    reg [2:0] gt_loopback_wbclk = {3{1'b0}};
    // reset the sticky link errors
    reg linkerr_reset = 0;
    // in userclk
    wire linkerr_reset_userclk;


    // OK, now *these* hook into the debug slots. Defaults pulled from exdes
    // NOTE: These are variables you can set for the TRANSMITTER
    // and verify their behavior AT THE RECEIVER.
    
    // TX differential swing control
    reg [3:0] gt_txdiffctrl = 4'b1000;
    // TX postcursor preemphasis
    reg [5:0] gt_txpostcursor = 5'b00000;
    // TX precursor preemphasis
    reg [5:0] gt_txprecursor = 5'b00000;
    
    // Basically nothing else needs to be done via the **ports**.
    
    // Status stuff.
    
    // Channel is up
    wire channel_up;
    // Lane is up
    wire lane_up;
    // NOTE: no powergood in GTP, just force it to 1
    wire gt_powergood = 1'b1;
    // TX reset done
    wire tx_resetdone_out;
    // RX resetdone
    wire rx_resetdone_out;
    // Sys reset output
    wire sys_reset_out;
    // Link reset output (initclk)
    wire link_reset_out;
    // Hard error
    wire hard_err;
    // Soft err
    wire soft_err;
    // Frame err
    wire frame_err;
    // Digital monitor output
    wire [15:0] dmonitor;
    // Powerdown in userclk
    wire powerdown;
    // Loopback in userclk
    wire [2:0] loopback;
        
    // AXI path. First we need a userclock space TX path.
    `DEFINE_AXI4S_IF( tx_userclk_ , 32 );
    // And here's a userclk RX path. Note that tready is here but NOT USED.
    `DEFINE_AXI4S_IF( rx_userclk_ , 32 );    
    // overflow occurred
    wire rx_overflow;
    // sticky indicator
    reg rx_overflow_occurred = 0;
    // UFC userclk RX path
    `DEFINE_AXI4S_IF( ufc_rx_userclk_ , 32 );
    // And back in sysclk
    `DEFINE_AXI4S_IF( ufc_rx_ , 32 );
    // and an indicator of overflow
    wire ufc_rx_overflow;    
    // sticky-ness
    reg ufc_rx_overflow_occurred = 0;
    // Here's the real UFC interface, which gets merged into the TX path.
    `DEFINE_AXI4S_IF( ufc_tx_userclk_ , 32 );    
    wire [2:0] ufc_tx_userclk_tsize = 3'b001; // always 32 bits
    assign ufc_tx_userclk_tkeep = 2'b11;      // always valid
                
    // create a multiplexed TX path
    `DEFINE_AXI4S_IF( muxed_tx_ , 32 );
    // and a fakey-path for UFC
    `DEFINE_AXI4S_MIN_IF( muxed_ufc_ , 3 );
    // now hook the userclk tx path and ufc userclk path together
    // we can do this simply because the core deasserts muxed_tx_tready when the UFC is being selected
    assign muxed_tx_tvalid = tx_userclk_tvalid;
    assign tx_userclk_tready = muxed_tx_tready;
    assign muxed_tx_tdata = (muxed_tx_tready) ? tx_userclk_tdata : ufc_tx_userclk_tdata;
    assign muxed_tx_tkeep = (muxed_tx_tready) ? tx_userclk_tkeep : ufc_tx_userclk_tkeep;
    assign muxed_tx_tlast = (muxed_tx_tready) ? tx_userclk_tlast : ufc_tx_userclk_tlast;
    // and generate the fakey path
    assign muxed_ufc_tdata = ufc_tx_userclk_tsize;
    assign muxed_ufc_tvalid = ufc_tx_userclk_tvalid;
    assign ufc_tx_userclk_tready = muxed_ufc_tready;
                        
    // hook up the link status
    assign link_status_userclk[0] = lane_up;            //userclk
    assign link_status_userclk[1] = channel_up;         //userclk
    assign link_status_userclk[2] = gt_powergood;       // unused
    assign link_status_userclk[3] = 1'b0;               // this is tx_lock when spliced in
//    assign link_status_userclk[3] = tx_lock;            // *initclk*. This is WRONG in 8b10b docs!
    assign link_status_userclk[4] = tx_resetdone_out;   //userclk
    assign link_status_userclk[5] = rx_resetdone_out;   //userclk
    // this is link_reset_out when spliced in
    assign link_status_userclk[6] = 1'b0;
    assign link_status_userclk[7] = sys_reset_out;      //nooo idea
    assign link_status_userclk[8] = hard_err;           //userclk
    assign link_status_userclk[9] = soft_err;           //userclk
    assign link_status_userclk[10] = frame_err;         //userclk
    assign link_status_userclk[31:11] = {21{1'b0}};

    assign link_status[2:0] = link_status_userclk_reg[2:0];
    assign link_status[3] = tx_lock;
    assign link_status[5:4] = link_status_userclk_reg[5:4];
    assign link_status[6] = link_reset_out;
    assign link_status[31:7] = link_status_userclk_reg[31:7];
        
    // and the link control
    assign link_control[0] = reset_in;
    assign link_control[1] = gt_reset_in;
    assign link_control[2] = 1'b0; // eyescan reset not needed
    assign link_control[3] = gt_powerdown_wbclk;
    assign link_control[4 +:3] = gt_loopback_wbclk;
    assign link_control[7 +: 23] = {23{1'b0}};
    assign link_control[30] = 1'b0; // datapath reset not added yet
    assign link_control[31] = linkerr_reset;
    // and the link eyescan
    assign link_eyescan[0 +: 4] = gt_txdiffctrl;
    assign link_eyescan[4 +: 4] = {4{1'b0}};
    assign link_eyescan[8 +: 5] = gt_txprecursor;
    assign link_eyescan[13 +: 3] = {3{1'b0}};
    assign link_eyescan[16 +: 5] = gt_txpostcursor;
    assign link_eyescan[21 +: 3] = {3{1'b0}};
    assign link_eyescan[24 +: 8] = {8{1'b0}}; // top byte is open
    // and the link dmonitor
    assign link_dmonitor = { {16{1'b0}}, dmonitor };
    
    // PLL stuff. There are all from exdes.
    wire quad1_common_lock_i;
    wire quad1_common_pll1_lock_i;
    wire gt0_pll0outclk_i;
    wire gt0_pll1outclk_i;
    wire gt0_pll0outrefclk_i;
    wire gt0_pll1outrefclk_i;
    wire gt0_pll0refclklost_i;
    wire common_reset_i;
            
    // state machine for register access
    localparam FSM_BITS = 2;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] ACK = 1;
    localparam [FSM_BITS-1:0] DRP_WAIT = 2;
    reg [FSM_BITS-1:0] state = IDLE;    
    
    // Create a DRP interface for GTP
    `DEFINE_DRP_IF( gt_ , 9);
    // Define DRP access by address here
    wire gt_drpaccess = wb_adr_i[11];
    // and hook it up to the WB interface
    assign gt_drpaddr[8:0] = wb_adr_i[2 +: 9];
    assign gt_drpdi = wb_dat_i[15:0];
    assign gt_drpwe = wb_we_i;
    assign gt_drpen = (state == IDLE && wb_cyc_i && wb_stb_i && gt_drpaccess);
    
    // individual control/stat register
    wire [31:0] ctrlstat[3:0];
    assign ctrlstat[0] = link_control;
    assign ctrlstat[1] = link_status;
    assign ctrlstat[2] = link_eyescan;
    assign ctrlstat[3] = link_dmonitor;

    // demux register
    (* CUSTOM_CC_DST = "INITCLK" *)
    reg [31:0] wb_dat_reg = {32{1'b0}};

    // dumb alias to ensure we don't look at bottom 2 bits but we're still talking about proper offsets
    wire [3:0] ctrlstat_addr = {wb_adr_i[2 +: 2], 2'b00 };

    // ok, logic first
    always @(posedge wb_clk_i) begin
        // demux wishbone register output
        if (state == IDLE && wb_cyc_i && wb_stb_i && !gt_drpaccess && !wb_we_i) begin
            wb_dat_reg <= ctrlstat[ wb_adr_i[2 +: 2] ];
        end else if (state == DRP_WAIT && gt_drprdy && !wb_we_i) begin
            wb_dat_reg <= { {16{1'b0}}, gt_drpdo };
        end

        // state flow
        if (wb_rst_i) state <= IDLE;
        else begin
            case (state)
                IDLE: if (wb_cyc_i && wb_stb_i) begin
                    if (gt_drpaccess) state <= DRP_WAIT;
                    else state <= ACK;
                end
                ACK: state <= IDLE;
                DRP_WAIT: if (gt_drprdy) state <= ACK;
            endcase
        end
        // register capture
        if (wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o) begin
            if (!gt_drpaccess && ctrlstat_addr == 4'h0) begin
                if (wb_sel_i[0]) begin
                    reset_in <= wb_dat_i[0];
                    gt_reset_in <= wb_dat_i[1];
                    gt_powerdown_wbclk <= wb_dat_i[3];
                    gt_loopback_wbclk <= wb_dat_i[4 +: 3];
                end
                if (wb_sel_i[3]) begin
                    linkerr_reset <= wb_dat_i[31];
                end
            end
            if (!gt_drpaccess && ctrlstat_addr == 4'h8) begin
                if (wb_sel_i[0]) gt_txdiffctrl <= wb_dat_i[0 +: 4];
                if (wb_sel_i[1]) gt_txprecursor <= wb_dat_i[8 +: 5];
                if (wb_sel_i[2]) gt_txpostcursor <= wb_dat_i[16 +: 5];
            end
        end        
    end

    always @(posedge user_clk) begin
        if (linkerr_reset_userclk) begin
            rx_overflow_occurred <= 1'b0;
            ufc_rx_overflow_occurred <= 1'b0;
        end else begin
            if (rx_overflow) rx_overflow_occurred <= 1'b1;
            if (ufc_rx_overflow) ufc_rx_overflow_occurred <= 1'b1;
        end
        // just capture it here to allow easy clock cross
        link_status_userclk_reg <= link_status_userclk;
    end
                        
    // OK, cross over gt_powerdown...
    xpm_cdc_single #(.SRC_INPUT_REG(0),.DEST_SYNC_FF(2))
        u_sync_powerdown(.src_clk(wb_clk_i),
                         .dest_clk(user_clk),
                         .src_in(gt_powerdown_wbclk),
                         .dest_out(powerdown));
    // and loopback
    async_register #(.WIDTH(3),.CLKATYPE("INITCLK"),.CLKBTYPE("USERCLK")) 
                                u_loopback_sync(.in_clkA(gt_loopback_wbclk),
                                                .out_clkB(loopback),
                                                .clkA(wb_clk_i),
                                                .clkB(user_clk));                         
    // and linkerr reset
    xpm_cdc_pulse #(.DEST_SYNC_FF(2),.RST_USED(0))
        u_linkerr_sync(.src_pulse(linkerr_reset),
                       .dest_pulse(linkerr_reset_userclk),
                       .src_clk(wb_clk_i),
                       .dest_clk(user_clk));

    // custom reset module            
    turf_aurora_reset u_reset(.reset_i(reset_in),
                              .gt_reset_i(gt_reset_in),
                              .user_clk_i(user_clk),
                              .init_clk_i(init_clk),
                              .system_reset_o(system_reset),
                              .gt_reset_o(gt_reset));
    
    // Small clock-cross FIFO for regular TX data
    // We need to pack data (32), tkeep (4), tlast (1) = 37 bits
    wire tx_ccfull;
    assign s_axis_tready = !tx_ccfull;
    aurora_cc_wrfifo u_txfifo( .din( { s_axis_tlast, s_axis_tkeep, s_axis_tdata } ),
                               .dout({ tx_userclk_tlast, tx_userclk_tkeep, tx_userclk_tdata } ),
                               .wr_clk( sys_clk_i ),
                               .rd_clk( user_clk ),
                               .wr_en( s_axis_tvalid && s_axis_tready ),
                               .full(tx_ccfull),
                               .valid( tx_userclk_tvalid ),
                               .rd_en( tx_userclk_tvalid && tx_userclk_tready ));
    // and for UFC, which is 32 bits
    wire ufc_tx_ccfull;
    assign ufc_tx_tready = !ufc_tx_ccfull;
    assign ufc_tx_userclk_tlast = 1'b1;
    aurora_ufc_cc_wrfifo u_ufctxfifo( .din( s_cmd_data_tdata ),
                                      .dout( ufc_tx_userclk_tdata ),
                                      .wr_clk( wb_clk_i ),
                                      .rd_clk( user_clk ),
                                      .wr_en( s_cmd_data_tvalid && s_cmd_data_tready ),
                                      .full( ufc_tx_ccfull ),
                                      .rst( sys_reset_out ),
                                      .valid( ufc_tx_userclk_tvalid ),
                                      .rd_en( ufc_tx_userclk_tvalid && ufc_tx_userclk_tready ));
    // RX path now. Again 37 bits but now we need overflow detection.
    aurora_cc_rdfifo u_rxfifo( .din( { rx_userclk_tlast, rx_userclk_tkeep, rx_userclk_tdata } ),
                               .dout( { m_axis_tlast, m_axis_tkeep, m_axis_tdata } ),
                               .wr_clk( user_clk ),
                               .rd_clk( sys_clk_i ),
                               .wr_en( rx_userclk_tvalid ),
                               .valid( m_axis_tvalid ),
                               .rd_en( m_axis_tvalid && m_axis_tready),
                               .overflow( rx_overflow ));
    // And the UFC path RX. Same as above.
    aurora_cc_rdfifo u_ufc_rxfifo( .din( { ufc_rx_userclk_tlast, ufc_rx_userclk_tkeep, ufc_rx_userclk_tdata } ),
                                   .dout( {ufc_rx_tlast, ufc_rx_tkeep, ufc_rx_tdata } ),
                                   .wr_clk( user_clk ),
                                   .rd_clk( wb_clk_i ),
                                   .wr_en( ufc_rx_userclk_tvalid ),
                                   .valid( ufc_rx_tvalid ),
                                   .rd_en( ufc_rx_tvalid && ufc_rx_tready),
                                   .overflow( ufc_rx_overflow ));
    // ok, now we need to *parse* the inbound RX path.
    aurora_cmdgen u_cmdgen( .aclk(wb_clk_i),
                            .aresetn(1'b1),
                            `CONNECT_AXI4S_MIN_IF( s_axis_ , ufc_rx_ ),
                            .s_axis_tlast( ufc_rx_tlast ),
                            `CONNECT_AXI4S_MIN_IF( m_cmd_addr_ , m_cmd_addr_ ),
                            `CONNECT_AXI4S_MIN_IF( m_cmd_data_ , m_cmd_data_ ));
                                      
    // we also need the common support. This is pulled from exdes
    //------ instance of _gt_common_wrapper ---{
    aurora_turf_gt_common_wrapper
        gt_common_support(
        //____________________________COMMON PORTS_______________________________{
    .gt0_gtrefclk0_in       (gtp_inclk_i             ),
    .gt0_pll0lock_out       (quad1_common_lock_i       ),
    .gt0_pll1lock_out       (quad1_common_pll1_lock_i       ),
    .gt0_pll0lockdetclk_in  (init_clk_i            ),
    .gt0_pll0refclklost_out (gt0_pll0refclklost_i ),
    .gt0_pll0outclk_i   ( gt0_pll0outclk_i    ),
    .gt0_pll1outclk_i   ( gt0_pll1outclk_i    ),
    .gt0_pll0outrefclk_i( gt0_pll0outrefclk_i ),
    .gt0_pll1outrefclk_i( gt0_pll1outrefclk_i ),
    .gt0_pll0reset_in   ( common_reset_i    )
        //____________________________COMMON PORTS_______________________________}
    );

    // and here's the aurora
    aurora_turf u_aurora( // Transmit path
                          `CONNECT_AXI4S_IF( s_axi_tx_ , muxed_tx_ ),
                          `CONNECT_AXI4S_MIN_IF( s_axi_ufc_tx_ , muxed_ufc_ ),
                          // Receive path - can't use connect helpers because no tready
                          .m_axi_rx_tdata(rx_userclk_tdata),
                          .m_axi_rx_tkeep(rx_userclk_tkeep),
                          .m_axi_rx_tlast(rx_userclk_tlast),
                          .m_axi_rx_tvalid(rx_userclk_tvalid),
                          .m_axi_ufc_rx_tdata(ufc_rx_userclk_tdata),
                          .m_axi_ufc_rx_tkeep(ufc_rx_userclk_tkeep),
                          .m_axi_ufc_rx_tlast(ufc_rx_userclk_tlast),
                          .m_axi_ufc_rx_tvalid(ufc_rx_userclk_tvalid),
                          // DRP. NO_PREFIX doesn't work w/SystemVerilog, I think (weirdly)
                          `CONNECT_GTW_DRP_IF(  , gt_ ),
                          // Commons
                          .gt_common_reset_out(common_reset_i),
                          .gt0_pll0refclklost_in(gt0_pll0refclklost_i),
                          .quad1_common_lock_in(quad1_common_lock_i),
                          .gt0_pll0outclk_in(gt0_pll0outclk_i),
                          .gt0_pll1outclk_in(gt1_pll1outclk_i),
                          .gt0_pll0outrefclk_in(gt0_pll0outrefclk_i),
                          .gt0_pll1outrefclk_in(gt0_pll1outrefclk_i),
                          // Done commons
                          
                          .loopback(loopback),
                          .pll_not_locked(pll_not_locked),
                          .power_down(powerdown),
                          .reset(system_reset ),
                          .gt_reset(gt_reset),
                          .init_clk_in(wb_clk_i),
                          .user_clk(user_clk),
                          .sync_clk(sync_clk),
                          .gt_refclk1(gtp_inclk_i),
                          
                          .channel_up(channel_up),
                          .lane_up(lane_up),
                          .hard_err(hadr_err),
                          .soft_err(soft_err),
                          .frame_err(frame_err),
                          .tx_resetdone_out(tx_resetdone_out),
                          .rx_resetdone_out(rx_resetdone_out),
                          .tx_lock(tx_lock),
                          .link_reset_out(link_reset_out),
                          .sys_reset_out(sys_reset_out),
                          // no GT powergood in GTP
                          //.gt_powergood(gt_powergood),
                          .tx_out_clk(tx_out_clk),                          
                          // ACTUAL ports to hook up
                          .gt0_txdiffctrl_in( gt_txdiffctrl ),
                          .gt0_txprecursor_in( gt_txprecursor ),
                          .gt0_txpostcursor_in( gt_txpostcursor ),                          
                          .gt0_dmonitorout_out(dmonitor),
                          
                          .rxp(MGTRX_P),
                          .rxn(MGTRX_N),
                          .txp(MGTTX_P),
                          .txn(MGTTX_N));
                          
    assign wb_ack_o = (state == ACK);
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
    assign wb_dat_o = wb_dat_reg;
    
                              
endmodule
