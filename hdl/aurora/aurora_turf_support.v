///////////////////////////////////////////////////////////////////////////////
// (c) Copyright 1995-2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
///////////////////////////////////////////////////////////////////////////////

 `timescale 1 ns / 10 ps

(* core_generation_info = "aurora_turf,aurora_8b10b_v11_1_15,{user_interface=AXI_4_Streaming,backchannel_mode=Sidebands,c_aurora_lanes=1,c_column_used=None,c_gt_clock_1=GTPQ0,c_gt_clock_2=None,c_gt_loc_1=1,c_gt_loc_10=X,c_gt_loc_11=X,c_gt_loc_12=X,c_gt_loc_13=X,c_gt_loc_14=X,c_gt_loc_15=X,c_gt_loc_16=X,c_gt_loc_17=X,c_gt_loc_18=X,c_gt_loc_19=X,c_gt_loc_2=X,c_gt_loc_20=X,c_gt_loc_21=X,c_gt_loc_22=X,c_gt_loc_23=X,c_gt_loc_24=X,c_gt_loc_25=X,c_gt_loc_26=X,c_gt_loc_27=X,c_gt_loc_28=X,c_gt_loc_29=X,c_gt_loc_3=X,c_gt_loc_30=X,c_gt_loc_31=X,c_gt_loc_32=X,c_gt_loc_33=X,c_gt_loc_34=X,c_gt_loc_35=X,c_gt_loc_36=X,c_gt_loc_37=X,c_gt_loc_38=X,c_gt_loc_39=X,c_gt_loc_4=X,c_gt_loc_40=X,c_gt_loc_41=X,c_gt_loc_42=X,c_gt_loc_43=X,c_gt_loc_44=X,c_gt_loc_45=X,c_gt_loc_46=X,c_gt_loc_47=X,c_gt_loc_48=X,c_gt_loc_5=X,c_gt_loc_6=X,c_gt_loc_7=X,c_gt_loc_8=X,c_gt_loc_9=X,c_lane_width=2,c_line_rate=62500,c_nfc=false,c_nfc_mode=IMM,c_refclk_frequency=125000,c_simplex=false,c_simplex_mode=TX,c_stream=false,c_ufc=true,flow_mode=UFC,interface_mode=Framing,dataflow_config=Duplex}" *)
module aurora_turf_support
 (
    // AXI TX Interface
input   [15:0]     s_axi_tx_tdata,
input   [1:0]      s_axi_tx_tkeep,
 
input              s_axi_tx_tvalid,
input              s_axi_tx_tlast,

output             s_axi_tx_tready,

    // AXI RX Interface
output  [15:0]     m_axi_rx_tdata,
output  [1:0]      m_axi_rx_tkeep,
 
output             m_axi_rx_tvalid,
output             m_axi_rx_tlast,



    // User Flow Control TX Interface
input              s_axi_ufc_tx_req,
input   [2:0]      s_axi_ufc_tx_ms,

output             s_axi_ufc_tx_ack,

    // User Flow Control RX Inteface
output  [15:0]     m_axi_ufc_rx_tdata,
output  [1:0]      m_axi_ufc_rx_tkeep,
output             m_axi_ufc_rx_tvalid,
output             m_axi_ufc_rx_tlast,

    // GT Serial I/O
input              rxp,
input              rxn,

output             txp,
output             txn,

    // GT Reference Clock Interface
 
input              gt_refclk1_p,
input              gt_refclk1_n,
 

    // Error Detection Interface
output             frame_err,
output             hard_err,
output             soft_err,
    // Status
output             lane_up,
output             channel_up,




    // System Interface
output              user_clk_out,
input               gt_reset,
input               reset,

input              power_down,
input   [2:0]      loopback,
output             tx_lock,

input              init_clk_p,
input              init_clk_n,
output             init_clk_out,
output             tx_resetdone_out,
output             rx_resetdone_out,
output             link_reset_out,
output             sys_reset_out,

    //DRP Ports
input              drpclk_in,
input   [8:0]      drpaddr_in, 
input              drpen_in, 
input   [15:0]     drpdi_in, 
output             drprdy_out, 
output  [15:0]     drpdo_out, 
input              drpwe_in, 
output             gt0_pll0lock_out,
output             gt0_pll1lock_out,
        //---------------------- TX Configurable Driver Ports ----------------------
 input   [4:0]     gt0_txpostcursor_in,
 input   [4:0]     gt0_txprecursor_in,
        //---------------- Transmit Ports - TX 8B/10B Encoder Ports ----------------
 input   [1:0]           gt0_txchardispmode_in,
 input   [1:0]           gt0_txchardispval_in,
 output            gt0_tx_buf_err_out,
 input   [6:0]     gt0_txmaincursor_in,
 input   [3:0]     gt0_txdiffctrl_in,
        //--------------- Transmit Ports - TX Polarity Control Ports ---------------
 input             gt0_txpolarity_in,
        //---------------- Transmit Ports - Pattern Generator Ports ----------------
 input             gt0_txprbsforceerr_in,
 input   [2:0]     gt0_txprbssel_in,
        //----------------- Transmit Ports - TX Data Path interface -----------------
 input             gt0_txpcsreset_in,
 input             gt0_txinhibit_in,
 input             gt0_txpmareset_in,
 output            gt0_txresetdone_out,
 output  [1:0]     gt0_txbufstatus_out,
 
 output            gt0_rxresetdone_out, 
 output  [2:0]     gt0_rxbufstatus_out,
    //------------------------ RX Margin Analysis Ports ------------------------
 input             gt0_eyescanreset_in,
 output            gt0_eyescandataerror_out,
 input             gt0_eyescantrigger_in,

 input             gt0_rxlpmhfhold_in,
 input             gt0_rxlpmlfhold_in,
 input             gt0_rxlpmhfovrden_in,
 input             gt0_rxlpmreset_in,
 input             gt0_rxcdrhold_in,
 output            gt0_rxbyteisaligned_out,
 output            gt0_rxcommadet_out,

 output  [1:0]   gt0_rx_disp_err_out,
 output  [1:0]   gt0_rx_not_in_table_out,
 output            gt0_rx_realign_out,
 output            gt0_rx_buf_err_out,
        //----------------- Receive Ports - Pattern Checker Ports ------------------
 output            gt0_rxprbserr_out,
 input   [2:0]     gt0_rxprbssel_in,
        //----------------- Receive Ports - Pattern Checker ports ------------------
 input             gt0_rxprbscntreset_in,
        //----------------- Receive Ports - RX Data Path interface -----------------
 input             gt0_rxpcsreset_in,
 input             gt0_rxpmareset_in,
 output            gt0_rxpmaresetdone_out,
 output   [14:0]    gt0_dmonitorout_out,
        //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
 input             gt0_rxbufreset_in,


output             pll_not_locked_out

 );

 `define DLY #1

 //*********************************Main Body of Code**********************************

//----------  Wire declarations
//------------------{
wire common_reset_i;
//____________________________COMMON PORTS_______________________________{
wire     gt0_pll0refclklost_i;
wire     quad1_common_lock_i;
wire     quad1_common_pll1_lock_i;
//----------------------- Channel - Ref Clock Ports ------------------------
wire            gt0_pll0outclk_i;
wire            gt0_pll1outclk_i;
wire            gt0_pll0outrefclk_i;
wire            gt0_pll1outrefclk_i;
//____________________________COMMON PORTS_______________________________}
//------------------}

wire               gt_refclk1;
wire               tx_out_clk_i;
wire               user_clk_i;
wire               sync_clk_i;
wire               pll_not_locked_i;
wire               tx_lock_i;

wire               init_clk_i;
wire               tx_resetdone_i;
wire               rx_resetdone_i;
wire               link_reset_i;
wire               system_reset_i;
wire               gt_reset_i;
wire               drpclk_i;
wire               reset_sync_user_clk;
wire               gt_reset_sync_init_clk;







//--- Instance of GT differential buffer ---------//
 IBUFDS_GTE2 IBUFDS_GTE2_CLK1
 (
 .I(gt_refclk1_p),
 .IB(gt_refclk1_n),
 .CEB(1'b0),
 .O(gt_refclk1),
 .ODIV2()
 );


assign drpclk_i = drpclk_in;

    // Instantiate a clock module for clock division.
    aurora_turf_CLOCK_MODULE clock_module_i
    (
        .INIT_CLK_P(init_clk_p),
        .INIT_CLK_N(init_clk_n),
        .INIT_CLK_O(init_clk_i),
        .GT_CLK(tx_out_clk_i),
        .GT_CLK_LOCKED(tx_lock_i),
        .USER_CLK(user_clk_i),
        .SYNC_CLK(sync_clk_i),
        .PLL_NOT_LOCKED(pll_not_locked_i)
    );

  //  outputs
  assign init_clk_out          =  init_clk_i;
 
  assign user_clk_out          =  user_clk_i;
  assign pll_not_locked_out    =  pll_not_locked_i;
  assign tx_lock               =  tx_lock_i;
  assign tx_resetdone_out      =  tx_resetdone_i;
  assign rx_resetdone_out      =  rx_resetdone_i;
  assign link_reset_out        =  link_reset_i;
  assign gt0_pll0lock_out      =  quad1_common_lock_i;
  assign gt0_pll1lock_out      =  quad1_common_pll1_lock_i; 


    assign reset_sync_user_clk = reset;
    assign gt_reset_sync_init_clk = gt_reset;

    aurora_turf_SUPPORT_RESET_LOGIC support_reset_logic_i
    (
        .RESET(reset_sync_user_clk),
        .USER_CLK(user_clk_i),
        .INIT_CLK_IN(init_clk_i),
        .GT_RESET_IN(gt_reset_sync_init_clk),
        .SYSTEM_RESET(system_reset_i),
        .GT_RESET_OUT(gt_reset_i)
    );

//------ instance of _gt_common_wrapper ---{
aurora_turf_gt_common_wrapper
gt_common_support
(
    //____________________________COMMON PORTS_______________________________{
.gt0_gtrefclk0_in       (gt_refclk1             ),
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


//------ instance of _gt_common_wrapper ---}

//----- Instance of _xci -----[
aurora_turf aurora_turf_i
     (
        // AXI TX Interface
       .s_axi_tx_tdata               (s_axi_tx_tdata),
       .s_axi_tx_tkeep               (s_axi_tx_tkeep),
       .s_axi_tx_tvalid              (s_axi_tx_tvalid),
       .s_axi_tx_tlast               (s_axi_tx_tlast),
       .s_axi_tx_tready              (s_axi_tx_tready),

        // AXI RX Interface
       .m_axi_rx_tdata               (m_axi_rx_tdata),
       .m_axi_rx_tkeep               (m_axi_rx_tkeep),
       .m_axi_rx_tvalid              (m_axi_rx_tvalid),
       .m_axi_rx_tlast               (m_axi_rx_tlast),

        // User Flow Control TX Interface
       .s_axi_ufc_tx_tvalid           (s_axi_ufc_tx_req),
       .s_axi_ufc_tx_tdata            (s_axi_ufc_tx_ms),
       .s_axi_ufc_tx_tready           (s_axi_ufc_tx_ack),

        // User Flow Control RX Inteface
       .m_axi_ufc_rx_tdata             (m_axi_ufc_rx_tdata),
       .m_axi_ufc_rx_tkeep             (m_axi_ufc_rx_tkeep),
       .m_axi_ufc_rx_tvalid            (m_axi_ufc_rx_tvalid),
       .m_axi_ufc_rx_tlast             (m_axi_ufc_rx_tlast),

        // GT Serial I/O
       .rxp                          (rxp),
       .rxn                          (rxn),
       .txp                          (txp),
       .txn                          (txn),

        // GT Reference Clock Interface
       .gt_refclk1                   (gt_refclk1),
        // Error Detection Interface
       .frame_err                    (frame_err),

        // Error Detection Interface
       .hard_err                     (hard_err),
       .soft_err                     (soft_err),

        // Status
       .channel_up                   (channel_up),
       .lane_up                      (lane_up),




        // System Interface
       .user_clk                     (user_clk_i),
       .sync_clk                     (sync_clk_i),
       .reset                        (system_reset_i),
       .power_down                   (power_down),
       .loopback                     (loopback),
       .gt_reset                     (gt_reset_i),
       .tx_lock                      (tx_lock_i),
       .init_clk_in                  (init_clk_i),
       .pll_not_locked               (pll_not_locked_i),
       .tx_resetdone_out             (tx_resetdone_i),
       .rx_resetdone_out             (rx_resetdone_i),
       .link_reset_out               (link_reset_i),
       .drpclk_in                    (drpclk_i),
       .drpaddr_in                   (drpaddr_in),
       .drpen_in                     (drpen_in),
       .drpdi_in                     (drpdi_in),
       .drprdy_out                   (drprdy_out),
       .drpdo_out                    (drpdo_out),
       .drpwe_in                     (drpwe_in),

//------------------{
.gt_common_reset_out (common_reset_i),
//____________________________COMMON PORTS_______________________________{
.gt0_pll0refclklost_in (gt0_pll0refclklost_i ),
.quad1_common_lock_in (quad1_common_lock_i ),
//----------------------- Channel - Ref Clock Ports ------------------------
.gt0_pll0outclk_in (gt0_pll0outclk_i ),
.gt0_pll1outclk_in (gt0_pll1outclk_i ),
.gt0_pll0outrefclk_in (gt0_pll0outrefclk_i ),
.gt0_pll1outrefclk_in (gt0_pll1outrefclk_i ),
//____________________________COMMON PORTS_______________________________}
//------------------}

       //---------------------- TX Configurable Driver Ports ----------------------
       .gt0_txpostcursor_in        (gt0_txpostcursor_in),
       .gt0_txprecursor_in         (gt0_txprecursor_in),
        //---------------- Transmit Ports - TX 8B/10B Encoder Ports ----------------
       .gt0_txchardispmode_in      (gt0_txchardispmode_in),
       .gt0_txchardispval_in       (gt0_txchardispval_in),
       .gt0_txmaincursor_in        (gt0_txmaincursor_in),
       .gt0_tx_buf_err_out         (gt0_tx_buf_err_out),
       .gt0_txdiffctrl_in          (gt0_txdiffctrl_in),
        //--------------- Transmit Ports - TX Polarity Control Ports ---------------
       .gt0_txpolarity_in          (gt0_txpolarity_in),
        //---------------- Transmit Ports - Pattern Generator Ports ----------------
        .gt0_txprbsforceerr_in              (gt0_txprbsforceerr_in),
        .gt0_txprbssel_in                   (gt0_txprbssel_in),
        //----------------- Transmit Ports - TX Data Path interface -----------------
        .gt0_txpcsreset_in                  (gt0_txpcsreset_in),
        .gt0_txinhibit_in                   (gt0_txinhibit_in),
        .gt0_txpmareset_in                  (gt0_txpmareset_in),
        .gt0_txresetdone_out                (gt0_txresetdone_out),
        .gt0_txbufstatus_out                (gt0_txbufstatus_out),

       .gt0_rxresetdone_out                (gt0_rxresetdone_out),
        .gt0_rxbufstatus_out                (gt0_rxbufstatus_out),
       //------------------------ RX Margin Analysis Ports ------------------------
       .gt0_eyescanreset_in        (gt0_eyescanreset_in),
       .gt0_eyescandataerror_out   (gt0_eyescandataerror_out ),
       .gt0_eyescantrigger_in      (gt0_eyescantrigger_in),

        .gt0_rxlpmhfhold_in                 (gt0_rxlpmhfhold_in),
        .gt0_rxlpmlfhold_in                 (gt0_rxlpmlfhold_in),
        .gt0_rxlpmreset_in                  (gt0_rxlpmreset_in),
        .gt0_rxlpmhfovrden_in               (gt0_rxlpmhfovrden_in),

       .gt0_rxcdrhold_in                   (gt0_rxcdrhold_in),
       .gt0_rxbyteisaligned_out    (gt0_rxbyteisaligned_out ),
       .gt0_rx_buf_err_out         (gt0_rx_buf_err_out),
       .gt0_rx_realign_out         (gt0_rx_realign_out),
       .gt0_rxcommadet_out         (gt0_rxcommadet_out),
       .gt0_rx_disp_err_out        (gt0_rx_disp_err_out),
       .gt0_rx_not_in_table_out    (gt0_rx_not_in_table_out),
        //----------------- Receive Ports - Pattern Checker Ports ------------------
        .gt0_rxprbserr_out                  (gt0_rxprbserr_out),
        .gt0_rxprbssel_in                   (gt0_rxprbssel_in),
        //----------------- Receive Ports - Pattern Checker ports ------------------
        .gt0_rxprbscntreset_in              (gt0_rxprbscntreset_in),
        //----------------- Receive Ports - RX Data Path interface -----------------
        .gt0_rxpcsreset_in                  (gt0_rxpcsreset_in),
        .gt0_rxpmareset_in                  (gt0_rxpmareset_in),
        .gt0_dmonitorout_out                (gt0_dmonitorout_out),
        .gt0_rxpmaresetdone_out             (gt0_rxpmaresetdone_out),
        //------ Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
        .gt0_rxbufreset_in                  (gt0_rxbufreset_in),


       .sys_reset_out                (sys_reset_out),
       .tx_out_clk                   (tx_out_clk_i)

     );
//----- Instance of _xci -----]



 endmodule 
