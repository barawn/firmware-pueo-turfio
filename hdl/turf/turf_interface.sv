`timescale 1ns / 1ps
`include "interfaces.vh"

`include "turfio_debug.vh"

// This is the TURF portion of the TURFIO serial control interface.
// The TURF  path is a bit special because it actually uses the RXCLK input.
//
// The overall process is:
// step 0: make sure TURF control interface is put into training mode.
// step 1: check if RXCLK and HSRXCLK are available. If not, stop, we do not
//         have a usable TURF control interface.
// step 2: reset everything I guess?
// step 3: set the RX bit error source control to be on the RXCLK side.
// step 4: step through the IDELAY values to find the center of the eye for RXCLK capture.
// step 5: execute a value capture until a non-ambigous byte is acquired (skip A6, 5A, 69, and D3)
// step 6: execute the appropriate number of bitslips based on the byte acquired
// step 7: on the TURF-side interface, execute an eye scan 
//         
// Training on the TURFIO side is only needed for the CIN path.
//
// THIS IS NOW REWORKED TO PUT THE IDELAY/ALIGNMENT/ETC. IN SYSCLK DOMAIN
//
// register 0x00: Reset controls, lock enable, interface enable, RXCLK phase
// register 0x04: (rxclk) CIN IDELAY control/readback
// register 0x08: (sysclk) CIN bit error control and readback
// register 0x0C: (sysclk/rxclk) CIN value capture and bitslip control
// register 0x10: (sysclk) reserved (possible upper bits for CIN value capture)
// register 0x14: (sysclk) SYSCLK phase capture readback
// register 0x18: (sysclk) reserved (possible upper bits for phase capture readback)
// register 0x1C: (sysclk) RXCLK/SYSCLK phase capture bit error counter.
// remaining reserved
//
// Register 0x0C is tricky domain-wise because on a write, it's rxclk, on a read,
// it's sysclk. Only requires qualifying against the write bit though, so not a huge deal.
//
// Note: Until "sync_i" is asserted, this interface essentially has its own internal
// 16-clock sequence.
module turf_interface #(
        parameter RXCLK_INV = 1'b0,
        parameter TXCLK_INV = 1'b0,
        parameter [6:0] COUT_INV = {7{1'b0}},
        parameter COUTTIO_INV = 1'b0,
        parameter CIN_INV = 1'b0,
        parameter [31:0] TRAIN_SEQUENCE = 32'hA55A6996,
        parameter WB_CLK_TYPE = "INITCLK",
        parameter DEBUG = `TURF_INTERFACE_DEBUG
    )
    (   input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 6, 32),
        input  sysclk_ok_i,
        input  sysclk_i,
        input  sysclk_x2_i,
        // Sync input to link the 16-cycle SYSCLK input
        // This signal high indicates the *first cycle* (cycle 0) of the
        // 16-clock cycle.
        // Note that responses should be sent on cycle 7 and 15 of the
        // 16-clock cycle: this means that the first nybble is presented
        // to the ISERDES at clock 0 and 8.
        input  sync_i,
        input rxclk_ok_i,
        output rxclk_o,
        output rxclk_x2_o,

        // Control output               
        output        command_locked_o,
        output [31:0] command_o,
        output        command_valid_o,
        // Response inputs (for COUTTIO)
        input  [31:0] response_i,
        // SURF inputs to forward when not training
        input  [27:0] surf_response_i,
        input RXCLK_P,
        input RXCLK_N,
        output TXCLK_P,
        output TXCLK_N,
        output [6:0] T_COUT_P,
        output [6:0] T_COUT_N,
        output COUTTIO_P,
        output COUTTIO_N,
        input CIN_P,
        input CIN_N        
    );

    // This is our first attempt just to get it working.
    // Try at 500 Mbit/s.
    
    // RXCLK is special, because if it's inverted,
    // we have to fix it at the MMCM. You *cannot* just grab
    // the inverted output, and you can't just freely invert
    // it along the way. Because Xilinx is stupid.
    
    // RXCLK positive inputs to IBUFDS
    wire rxclk_in_p = (RXCLK_INV) ? RXCLK_N : RXCLK_P;
    // RXCLK negative inputs to IBUFDS
    wire rxclk_in_n = (RXCLK_INV) ? RXCLK_P : RXCLK_N;
    // RXCLK O output from IBUFGDS_DIFF_OUT (p)
    wire rxclk_out_p;
    // RXCLK O output from IBUFGDS_DIFF_OUT (n)
    wire rxclk_out_n;
    // RXCLK out of MMCM
    wire rxclk;
    // 2x RXCLK out of MMCM
    wire rxclk_x2;

    // MMCM reset
    wire rxclk_mmcm_reset;
    // MMCM is locked
    wire rxclk_locked;
    // phase shift enable
    wire fine_ps_enable;
    // phase shift is done
    wire fine_ps_done;    

    // Current CIN delay value
    wire [5:0] cin_idelay_current;
    // CIN value
    wire [3:0] cin_parallel;
    // Target CIN delay value
    wire [5:0] cin_idelay_value;
    // Load CIN delay value
    wire cin_idelay_load;
    // Reset ISERDES
    wire cin_iserdes_rst;
    // Bitslip ISERDES
    wire cin_iserdes_bitslip;
    
    // Bit error observed at CIN in training phase
    wire cin_biterr;
    // Capture a CIN 32-bit snapshot
    wire cin_sync_capture;
    // Lock the command interface onto training pattern
    wire cin_sync_lock;
    // Command interface is locked
    wire cin_sync_locked;
    // SYSCLK side cin
    wire [3:0] cin_parallel_sysclk;
    // Capture error.
    wire sysclk_rxclk_biterr;

    // Reset the OSERDES to synchronize.
    wire oserdes_rst_sysclk;

    // Force cout into training path
    wire cout_train;

    // RXCLK path    
    IBUFGDS_DIFF_OUT #(.IBUF_LOW_PWR("FALSE"))
        u_rxclk(.I(rxclk_in_p),.IB(rxclk_in_n),.O(rxclk_out_p),.OB(rxclk_out_n));
    

    // TURF high-speed receive clock generator and phase shift.
    turf_rxclk_gen #(.INVERT_CLOCKS(RXCLK_INV ? "TRUE" : "FALSE"))
        u_rxclk_gen( .rxclk_in(rxclk_out_p),
                     .rxclk_o(rxclk),
                     .rxclk_x2_o(rxclk_x2),
                     .rst_i(rxclk_mmcm_reset),
                     .locked_o(rxclk_locked),
                     .ps_clk_i(wb_clk_i),
                     .ps_en_i(fine_ps_enable),
                     .ps_done_o(fine_ps_done));
    
    turf_cin #(.CIN_INV(CIN_INV))
        u_turfcin(.rxclk_i(rxclk),
                  .rxclk_x2_i(rxclk_x2),
                  .idelay_load_i(cin_idelay_load),
                  .idelay_value_i(cin_idelay_value),
                  .idelay_value_o(cin_idelay_current),
                  .iserdes_rst_i(cin_iserdes_rst),
                  .iserdes_bitslip_i(cin_iserdes_bitslip),
                  .cin_o(cin_parallel),
                  .CIN_P(CIN_P),
                  .CIN_N(CIN_N));                                      

    // SYSCLK crossing.
    rxclk_sysclk_transfer 
        u_rxsys(.rxclk_i(rxclk_o),
                .data_i(cin_parallel),
                .sysclk_i(sysclk_i),
                .data_o(cin_parallel_sysclk),
                .capture_err_o(sysclk_rxclk_biterr));
    
    turf_cin_parallel_sync #(.TRAIN_SEQUENCE(TRAIN_SEQUENCE))
        u_cin_sync(.sysclk_i(sysclk_i),
                   .cin_i(cin_parallel_sysclk),
                   .rst_i(cin_sync_reset),
                   .capture_i( cin_sync_capture ),
                   .lock_i(cin_sync_lock),
                   .locked_o(cin_sync_locked),
                   .cin_parallel_o(command_o),
                   .cin_parallel_valid_o(command_valid_o),
                   .cin_biterr_o(cin_biterr));        

    turf_cout_interface #(.COUTTIO_INV(COUTTIO_INV),
                          .TXCLK_INV(TXCLK_INV),
                          .T_COUT_INV(COUT_INV))
        u_turf_cout(.sysclk_i(sysclk_i),
                    .sysclk_x2_i(sysclk_x2_i),
                    .oserdes_rst_i(oserdes_rst_sysclk),
                    .train_i(cout_train),
                    .sync_i(sync_i),
                    .response_i(response_i),
                    .surf_response_i(surf_response_i),
                    .T_COUT_P(T_COUT_P),
                    .T_COUT_N(T_COUT_N),
                    .COUTTIO_P(COUTTIO_P),
                    .COUTTIO_N(COUTTIO_N),
                    .TXCLK_P(TXCLK_P),
                    .TXCLK_N(TXCLK_N));
        
    // we are a wishbone slave, and passing it to our core
    // requires the CONNECT_WBS_IFS macro (because the interface is
    // named as a WISHBONE slave)
    turfctl_register_core #(.DEBUG(DEBUG),.WB_CLK_TYPE(WB_CLK_TYPE))
        u_core( .wb_clk_i(wb_clk_i),
                .wb_rst_i(wb_rst_i),
                `CONNECT_WBS_IFS(wb_ , wb_ ),
                
                .sysclk_ok_i(sysclk_ok_i),
                .sysclk_i(sysclk_i),
                .rxclk_ok_i(rxclk_ok_i),
                .rxclk_i(rxclk),
                
                .ps_en_o(fine_ps_enable),
                .ps_done_i(fine_ps_done),
                .mmcm_locked_i(rxclk_locked),
                .mmcm_rst_o(rxclk_mmcm_reset),
                .sysclk_rxclk_biterr_i(sysclk_rxclk_biterr),
                
                .idelay_load_o(cin_idelay_load),
                .idelay_value_o(cin_idelay_value),
                .idelay_current_i(cin_idelay_current),
                .iserdes_rst_o(cin_iserdes_rst),
                .iserdes_bitslip_o(cin_iserdes_bitslip),
                .oserdes_rst_o(oserdes_rst_sysclk),
                
                .cin_sync_rst_o(cin_sync_reset),
                .cin_sync_capture_o(cin_sync_capture),
                .cin_sync_data_i(command_o),
                .cin_sync_biterr_i(cin_biterr),
                .cin_sync_lock_o(cin_sync_lock),
                .cin_sync_locked_i(cin_sync_locked),
                .cout_train_o(cout_train));

    assign rxclk_o = rxclk;
    assign rxclk_x2_o = rxclk_x2;
                   
endmodule
