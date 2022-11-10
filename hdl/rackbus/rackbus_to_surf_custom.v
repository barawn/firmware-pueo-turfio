
// file: rackbus_to_surf_selectio_wiz.v
// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
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
//----------------------------------------------------------------------------
// PSA 11/9/22 : Modified to allow for clock/data inversion
//----------------------------------------------------------------------------
// None
//----------------------------------------------------------------------------

`timescale 1ps/1ps

module rackbus_to_surf_custom
   // width of the data for the system
 #(parameter SYS_W = 1,
   // width of the data for the device
   parameter DEV_W = 6,
   // 1 if clock is inverted
   parameter INV_CLK = 1'b0,
   // 1 if data is inverted
   parameter INV_DATA = 1'b0
)
 (
  // From the device out to the system
  input  [DEV_W-1:0] data_out_from_device,
  output [SYS_W-1:0] data_out_to_pins_p,
  output [SYS_W-1:0] data_out_to_pins_n,
  output  clk_to_pins_p,
  output  clk_to_pins_n,
  input              clk_in,        // Fast clock input from PLL/MMCM
  input              clk_div_in,    // Slow clock input from PLL/MMCM
  input              clk_reset,
  input              io_reset);
  localparam         num_serial_bits = DEV_W/SYS_W;
  wire clock_enable = 1'b1;
  // Signal declarations
  ////------------------------------
  wire clk_fwd_out;
  // Before the buffer
  wire   [SYS_W-1:0] data_out_to_pins_int;
  // Between the delay and serdes
  wire   [SYS_W-1:0] data_out_to_pins_predelay;
  // Array to use intermediately from the serdes to the internal
  //  devices. bus "0" is the leftmost bus
  wire [SYS_W-1:0]  oserdes_d[0:13];   // fills in starting with 13
  // Create the clock logic


  // We have multiple bits- step over every bit, instantiating the required elements
  genvar pin_count;
  genvar slice_count;
  generate for (pin_count = 0; pin_count < SYS_W; pin_count = pin_count + 1) begin: pins
    // Instantiate the buffers
    ////------------------------------
    // Instantiate a buffer for every bit of the data bus
    OBUFDS
      #(.IOSTANDARD ("LVDS_25"))
     obufds_inst
       (.O          (data_out_to_pins_p  [pin_count]),
        .OB         (data_out_to_pins_n  [pin_count]),
        .I          (data_out_to_pins_int[pin_count]));

    // Pass through the delay
    ////-------------------------------
   assign data_out_to_pins_int[pin_count]    = data_out_to_pins_predelay[pin_count];
 
     // Instantiate the serdes primitive
     ////------------------------------

     // declare the oserdes
     OSERDESE2
       # (
         .DATA_RATE_OQ   ("DDR"),
         .DATA_RATE_TQ   ("SDR"),
         .DATA_WIDTH     (6),
         .TRISTATE_WIDTH (1),
         .SERDES_MODE    ("MASTER"))
       oserdese2_master (
         .D1             (oserdes_d[13][pin_count] ^ INV_DATA),
         .D2             (oserdes_d[12][pin_count] ^ INV_DATA),
         .D3             (oserdes_d[11][pin_count] ^ INV_DATA),
         .D4             (oserdes_d[10][pin_count] ^ INV_DATA),
         .D5             (oserdes_d[9][pin_count] ^ INV_DATA),
         .D6             (oserdes_d[8][pin_count] ^ INV_DATA),
         .D7             (oserdes_d[7][pin_count] ^ INV_DATA),
         .D8             (oserdes_d[6][pin_count] ^ INV_DATA),
         .T1             (1'b0),
         .T2             (1'b0),
         .T3             (1'b0),
         .T4             (1'b0),
         .SHIFTIN1       (1'b0),
         .SHIFTIN2       (1'b0),
         .SHIFTOUT1      (),
         .SHIFTOUT2      (),
         .OCE            (clock_enable),
         .CLK            (clk_in),
         .CLKDIV         (clk_div_in),
         .OQ             (data_out_to_pins_predelay[pin_count]),
         .TQ             (),
         .OFB            (),
         .TFB            (),
         .TBYTEIN        (1'b0),
         .TBYTEOUT       (),
         .TCE            (1'b0),
         .RST            (io_reset));

     // Concatenate the serdes outputs together. Keep the timesliced
     //   bits together, and placing the earliest bits on the right
     //   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
     //       the output will be 3210, 7654, ...
     ////---------------------------------------------------------
     for (slice_count = 0; slice_count < num_serial_bits; slice_count = slice_count + 1) begin: out_slices
        // This places the first data in time on the right
        assign oserdes_d[14-slice_count-1] =
           data_out_from_device[slice_count];
        // To place the first data in time on the left, use the
        //   following code, instead
        // assign oserdes_d[slice_count] =
        //    data_out_from_device[slice_count];
     end
  end
  endgenerate
  
//// NO ODELAY

//// clk fwd
///fuji
//// NO ODELAY

     // declare the oserdes
     OSERDESE2
       # (
         .DATA_RATE_OQ   ("DDR"),
         .DATA_RATE_TQ   ("SDR"),
         .DATA_WIDTH     (4),
         .TRISTATE_WIDTH (1),
         .SERDES_MODE    ("MASTER"))
       clk_fwd (
         .D1             (1'b1 ^ INV_CLK),
         .D2             (1'b0 ^ INV_CLK),
         .D3             (1'b1 ^ INV_CLK),
         .D4             (1'b0 ^ INV_CLK),
         .D5             (1'b1 ^ INV_CLK),
         .D6             (1'b0 ^ INV_CLK),
         .D7             (1'b1 ^ INV_CLK),
         .D8             (1'b0 ^ INV_CLK),
         .T1             (1'b0),
         .T2             (1'b0),
         .T3             (1'b0),
         .T4             (1'b0),
         .SHIFTIN1       (1'b0),
         .SHIFTIN2       (1'b0),
         .SHIFTOUT1      (),
         .SHIFTOUT2      (),
         .OCE            (clock_enable),
         .CLK            (clk_div_in),
         .CLKDIV         (clk_div_in),
         .OQ             (clk_fwd_out),
         .TQ             (),
         .OFB            (),
         .TFB            (),
         .TBYTEIN        (1'b0),
         .TBYTEOUT       (),
         .TCE            (1'b0),
         .RST            (io_reset));


// Clock Output Buffer
    OBUFDS
      #(.IOSTANDARD ("LVDS_25"))
     obufds_inst
       (.O          (clk_to_pins_p),
        .OB         (clk_to_pins_n),
        .I          (clk_fwd_out));
endmodule
