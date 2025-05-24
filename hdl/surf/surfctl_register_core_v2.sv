`timescale 1ns / 1ps
`include "interfaces.vh"
// Based on turfctl register core, but quite a few changes.
// - we don't need the RXCLK phase adjust stuff. RXCLK phase adjustment only happens in the
//   downstream-from-TURF direction to validate the delays.
//
// This module _presents_ itself as having 2 TURFIOHSAligns, one at 0x00 and one at 0x10.
// Internally however they're not independent: when you write the interval value to BIT_ERROR_COUNT_REG
// it switches the error counter to the new target.
// In addition, the ISERDES resets are common between the two, as is the actual output value register.
//
// The CIN training bit is also common between the two.
// Because of the way the interface is done, you can just pretend there's two TURFIOHSAligns
// separated by 0x10, treating the 0x00 register as read-modify-write.
// It kindof works the same for the TURF-side input, except there its a TURFIOHSAlign and TURFIOClockAlign.
module surfctl_register_core_v2(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 6, 32),
        
        input sysclk_ok_i,
        input sysclk_i,

        // these come from the live detector
        // and automatic sequencer setup
        input surf_live_i,
        // this is a flag!!
        input surf_autotrain_en_i,
                
        // IDELAY inputs/outputs and bitslip
        output idelay_cout_load_o,
        output idelay_dout_load_o,
        // common value
        output [5:0] idelay_value_o,
        input [5:0] idelay_cout_current_i,
        input [5:0] idelay_dout_current_i,
        // common reset
        output iserdes_rst_o,
        output iserdes_cout_bitslip_o,
        output iserdes_dout_bitslip_o,
        // OSERDES reset output, to synchronize
        output oserdes_rst_o,
        
        // COUT alignment for SURFs happens differently
        // than the TURF because we don't try to sync align.
        // So all we have is a capture request,
        // return data, and bit error.
        // We don't have sync lock, but we do enable only when valid.
        // We do a 32-bit capture *here* but we actually just
        // pass out the 4-bit data to the TURF directly.
        input [31:0] cout_data_i,
        input cout_biterr_i,
        output cout_enable_o,
        output cout_capture_o,
        output cout_captured_o,
                    
        // DOUT alignment happens only on an 8-bit path
        // We don't have a sync lock, but we do have an enable.
        input [7:0] dout_data_i,
        input dout_biterr_i,
        output dout_enable_o,
        output dout_capture_o,
        // This flips the capture phase for dout. This is basically
        // instead of the parallelizer.
        output dout_capture_phase_o,
                
        // train enable
        output cin_train_o,
        // event mask
        output mask_o
    );

    // COUT HSAlign
    localparam [5:0] COUT_CONTROL_REG = 6'h00;
    localparam [5:0] COUT_IDELAY_REG = 6'h04;
    localparam [5:0] COUT_BIT_ERROR_COUNT_REG = 6'h08;
    localparam [5:0] COUT_DATA_REG = 6'h0C;

    // DOUT HSAlign
    localparam [5:0] DOUT_CONTROL_REG = 6'h10;
    localparam [5:0] DOUT_IDELAY_REG = 6'h14;
    localparam [5:0] DOUT_BIT_ERROR_COUNT_REG = 6'h18;
    localparam [5:0] DOUT_DATA_REG = 6'h1C;
    
    
    parameter WB_CLK_TYPE = "INITCLK";

    // We do a lot of clock crossing, so we hold the inputs static while they cross.
    (* CUSTOM_CC_DST = WB_CLK_TYPE *)    
    reg [31:0] dat_reg = {32{1'b0}};
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [31:0] dat_in_static = {32{1'b0}};
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [5:0] adr_in_static = {6{1'b0}};
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [3:0] sel_in_static = {4{1'b0}};
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg we_in_static = 0;
    

    ///////////////////////////////////////////////////////////////////////////////////
    //                               SYSCLK TASK CROSSING                            //
    ///////////////////////////////////////////////////////////////////////////////////

    // This determines whether we're jumping to the sysclk side.
    // This happens with the bit error count registers and the COUT/DOUT data registers.
    // It also happens when writing the IDELAYs, but not reading (since they output their current values statically)
    wire sysclk_access = (wb_adr_i == COUT_BIT_ERROR_COUNT_REG || wb_adr_i == DOUT_BIT_ERROR_COUNT_REG) ||
                         (wb_adr_i == COUT_DATA_REG || wb_adr_i == DOUT_DATA_REG) ||
                         ((wb_adr_i == COUT_IDELAY_REG || wb_adr_i == DOUT_IDELAY_REG) && wb_we_i);
    // sysclk_access jumps into a waiting state : this indicates we're in that waiting state.
    wire sysclk_waiting;
    // this is a flag indicating that the above has changed and we've issued a wait
    wire sysclk_waiting_flag_wbclk;
    // flag indicating that a wait has been seen, and execute task
    wire sysclk_waiting_flag_sysclk;
    // flag indicating that the task is complete
    wire sysclk_ack_flag_wbclk;
    // and this last flag informs sysclk that we're totally done if needed.
    wire done_flag_wbclk;
    // in sysclk
    wire done_flag_sysclk;

    register_core_cc_task u_wb_sys_cc(.rclk_i(wb_clk_i),
                                      .dclk_i(sysclk_i),
                                      .waiting_rclk_i(sysclk_waiting),
                                      .waiting_dclk_o(sysclk_waiting_flag_sysclk),
                                      .acknowledge_rclk_o(sysclk_ack_flag_wbclk));

    flag_sync u_donesync(.in_clkA(done_flag_wbclk),.out_clkB(done_flag_sysclk),
                         .clkA(wb_clk_i),.clkB(sysclk_i));

    //////////////////////////////////////////////////////////////////////
    //                      BIT ERROR COUNTING                          //
    //////////////////////////////////////////////////////////////////////

    // This indicates whether or not the bit error count input comes from
    // dout or from cout.
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg use_dout = 0;
    // this is the muxed bit error
    reg muxed_bit_err = 0;
    
    // Output from biterr counter.
    wire [24:0] biterr_count_value;
    // Flag to load interval.
    wire        biterr_load_interval = ( adr_in_static == COUT_BIT_ERROR_COUNT_REG ||
                                         adr_in_static == DOUT_BIT_ERROR_COUNT_REG ) &&
                                         we_in_static &&
                                         sysclk_waiting_flag_sysclk;
    // Sleazy muxing.
    always @(posedge sysclk_i) begin
        if (biterr_load_interval) use_dout <= (adr_in_static == DOUT_BIT_ERROR_COUNT_REG);
        
        if (use_dout) muxed_bit_err <= dout_biterr_i;
        else muxed_bit_err <= cout_biterr_i;
    end
    // Register core counter.
    register_core_biterr_counter #(.RCLK_TYPE(WB_CLK_TYPE),
                                   .DCLK_TYPE("SYSCLK"))
        u_biterr_count(.rclk_i(wb_clk_i),
                       .dclk_i(sysclk_i),
                       .err_dclk_i(muxed_bit_err),
                       .interval_i(dat_in_static[23:0]),
                       .interval_load_i(biterr_load_interval),
                       .error_count_o(biterr_count_value));
                       

    // interface logic
    localparam FSM_BITS = 2;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] ACK = 1;
    localparam [FSM_BITS-1:0] WAIT_ACK_SYSCLK = 2;
    reg [FSM_BITS-1:0] state = IDLE;
    
    assign sysclk_waiting = (state == WAIT_ACK_SYSCLK);    
    assign done_flag_wbclk = (state == ACK);
    
    // iserdes reset is common
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg iserdes_reset = 0;
    
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] iserdes_reset_resync = {2{1'b0}};

    // oserdes reset. This STARTS OUT high
    // to force keep COUT into a known state until
    // pulled low by software. This can be done automatically
    // if enabled.
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg oserdes_reset = 1;
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] oserdes_reset_resync = {2{1'b1}};
    always @(posedge sysclk_i) begin
        iserdes_reset_resync <= { iserdes_reset_resync[0], iserdes_reset };
        oserdes_reset_resync <= { oserdes_reset_resync[0], oserdes_reset };
    end
    
    // switch CIN outputs to SURFs to training mode
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg cin_train_enable = 0;
    // in sysclk domain
    (* CUSTOM_CC_DST = "SYSCLK", ASYNC_REG = "TRUE" *)
    reg [1:0] cin_train_enable_sysclk = {2{1'b0}};
            
    // determine which phase to capture dout in
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg dout_capture_phase = 0;
    (* CUSTOM_CC_DST = "SYSCLK", ASYNC_REG = "TRUE" *)
    reg [1:0] dout_capture_phase_sysclk = {2{1'b0}};

    // treat the DOUT data as valid
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg dout_enable = 0;
    (* CUSTOM_CC_DST = "SYSCLK", ASYNC_REG = "TRUE" *)
    reg [1:0] dout_enable_sysclk = {2{1'b0}};
    
    // treat the COUT data as valid
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg cout_enable = 0;
    (* CUSTOM_CC_DST = "SYSCLK", ASYNC_REG = "TRUE" *)
    reg [1:0] cout_enable_sysclk = {2{1'b0}};

    // this is the common register (and a little silly)            
    wire [31:0] control_register;
    // this is the cout version
    wire [31:0] cout_control_register;
    // this is the dout version
    wire [31:0] dout_control_register;
    // The PUEOHSAligns have Very Similar Structures.
    assign control_register[0] = 1'b0;              // unused, is RXCLK MMCM reset
    assign control_register[1] = 1'b0;              // unused, is RXCLK MMCM not locked
    assign control_register[2] = iserdes_reset;     // common iserdes reset
    assign control_register[3] = 1'b0;              // unused, is parallelizer reset
    assign control_register[4] = oserdes_reset;     // OSERDES reset (common)
    assign control_register[6:5] = 2'b00;           // reserved
    assign control_register[7] = 1'b0;              // dout capture phase, spliced in
    // these are pointless, they get spliced in
    assign control_register[8] = 1'b0;              // not common (enable or lock enable)
    assign control_register[9] = 1'b0;              // not common (lock status or copy of bit 8)
    assign control_register[10] = cin_train_enable; // train enable (common)
    assign control_register[15:11] = {5{1'b0}};     // reserved
    assign control_register[31:16] = {16{1'b0}};    // RXCLK phase adjust
    // Duplicate this so it acts the same as the lock req/status.
    assign cout_control_register[6:0] = control_register[6:0];
    assign cout_control_register[7] = 1'b0;
    assign cout_control_register[8] = cout_enable;
    assign cout_control_register[9] = cout_enable; 
    assign cout_control_register[31:10] = control_register[31:10];
    // Duplicate this so it acts the same as the lock req/status.
    assign dout_control_register[6:0] = control_register[6:0];
    assign dout_control_register[7] = dout_capture_phase;
    assign dout_control_register[8] = dout_enable;
    assign dout_control_register[9] = dout_enable;
    assign dout_control_register[31:10] = control_register[31:10];
    
    reg surf_live_rereg = 0;
    // REGISTER LOGIC    
    wire common_control_write = (state == ACK && we_in_static && (adr_in_static == COUT_CONTROL_REG ||
                                                                  adr_in_static == DOUT_CONTROL_REG));                                                                      

    wire autotrain_oserdes_clear_reset;
    SRL16E u_autotrain_delay(.D(surf_autotrain_en_i),
                             .CE(1'b1),
                             .CLK(wb_clk_i),
                             .A0(1'b1),
                             .A1(1'b1),
                             .A2(1'b1),
                             .A3(1'b1),
                             .Q(autotrain_oserdes_clear_reset));
    always @(posedge wb_clk_i) begin
        surf_live_rereg <= surf_live_i;
        // COMMON CONTROL REGISTER
        // iserdes is ONLY controlled by register path
        if (common_control_write)
            if (sel_in_static[0]) iserdes_reset <= dat_in_static[2];
        // oserdes reset is controlled by either a surf_live_i falling edge,
        // register path, or a delay on the autotrain.
        // when surf live falls, we jump back to reset.
        if (common_control_write) begin
            if (sel_in_static[0]) oserdes_reset <= dat_in_static[4];
        end else begin
            if (!surf_live_i && surf_live_rereg)
                oserdes_reset <= 1'b1;
            else if (autotrain_oserdes_clear_reset)
                oserdes_reset <= 1'b0;
        end
        // train enable is controlled by either register path or the automatic enable
        if (common_control_write) begin
            if (sel_in_static[1]) cin_train_enable <= dat_in_static[10];
        end else if (surf_autotrain_en_i) begin
            cin_train_enable <= 1'b1;
        end
                                                
        // COUT HSALIGN ONLY
        if (state == ACK && we_in_static && adr_in_static == COUT_CONTROL_REG) begin
            if (sel_in_static[1]) cout_enable <= dat_in_static[8];
        end
        // DOUT HSALIGN ONLY
        if (state == ACK && we_in_static && adr_in_static == DOUT_CONTROL_REG) begin
            if (sel_in_static[1]) dout_enable <= dat_in_static[8];
        end            

        if (state == ACK && we_in_static && (adr_in_static == COUT_CONTROL_REG || adr_in_static == DOUT_CONTROL_REG)) begin
            if (sel_in_static[0]) dout_capture_phase <= dat_in_static[7];
        end
        // CAPTURE INPUTS AND HOLD STATIC
        if (wb_cyc_i && wb_stb_i) begin
            if (wb_sel_i[0]) dat_in_static[7:0] <= wb_dat_i[7:0];
            if (wb_sel_i[1]) dat_in_static[15:8] <= wb_dat_i[15:8];
            if (wb_sel_i[2]) dat_in_static[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) dat_in_static[31:24] <= wb_dat_i[31:24];            
            adr_in_static <= wb_adr_i;
            we_in_static <= wb_we_i;
            sel_in_static <= wb_sel_i;
        end
        // STATE MACHINE
        if (wb_rst_i) state <= IDLE;
        else begin
            case (state)
                IDLE: if (wb_cyc_i && wb_stb_i) begin
                    if (sysclk_access) state <= WAIT_ACK_SYSCLK;
                    else state <= ACK;
                end
                ACK: state <= IDLE;
                WAIT_ACK_SYSCLK: if (sysclk_ack_flag_wbclk || !sysclk_ok_i) state <= ACK;
            endcase
        end
        // RESPONSE CAPTURE AND OUTPUT MUXING
        if (state == WAIT_ACK_SYSCLK) begin
            if (!sysclk_ok_i) dat_reg <= {32{1'b1}};
            else if (sysclk_ack_flag_wbclk) begin
                if (wb_adr_i == COUT_BIT_ERROR_COUNT_REG ||
                    wb_adr_i == DOUT_BIT_ERROR_COUNT_REG)
                    dat_reg <= biterr_count_value;
                else if (wb_adr_i == COUT_DATA_REG) dat_reg <= cout_data_i;
                else if (wb_adr_i == DOUT_DATA_REG) dat_reg <= dout_data_i;
                else dat_reg <= {32{1'b0}};
            end
        end else if (state == IDLE) begin
            if (wb_cyc_i && wb_stb_i && !wb_we_i) begin
                if (wb_adr_i == COUT_CONTROL_REG) dat_reg <= cout_control_register;
                else if (wb_adr_i == DOUT_CONTROL_REG) dat_reg <= dout_control_register;
                else if (wb_adr_i == COUT_IDELAY_REG) dat_reg <= idelay_cout_current_i;
                else if (wb_adr_i == DOUT_IDELAY_REG) dat_reg <= idelay_dout_current_i;
                else dat_reg <= {32{1'b0}};
            end
        end
    end
    
    // Synchronize the train/dout/couts
    always @(posedge sysclk_i) begin
        dout_capture_phase_sysclk <= { dout_capture_phase_sysclk[0], dout_capture_phase };
        cin_train_enable_sysclk <= { cin_train_enable_sysclk[0], cin_train_enable };
        dout_enable_sysclk <= { dout_enable_sysclk[0], dout_enable };
        cout_enable_sysclk <= { cout_enable_sysclk[0], cout_enable };        
    end
    
    assign wb_dat_o = dat_reg;
    assign wb_ack_o = (state == ACK);
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
    
    // capture flags
    assign cout_capture_o = sysclk_waiting_flag_sysclk && adr_in_static == COUT_DATA_REG;
    // doesn't matter that this goes off a lot I think
    assign cout_captured_o = done_flag_sysclk;
    assign dout_capture_o = sysclk_waiting_flag_sysclk && adr_in_static == DOUT_DATA_REG;
    // enable outputs
    assign dout_enable_o = dout_enable_sysclk[1];
    assign cout_enable_o = cout_enable_sysclk[1];
    // mask
    assign mask_o = !dout_enable_sysclk[1];
    // capture phase
    assign dout_capture_phase_o = dout_capture_phase_sysclk[1];
    // idelay outputs    
    assign idelay_value_o = dat_in_static[5:0];
    assign idelay_cout_load_o = sysclk_waiting_flag_sysclk &&
                                adr_in_static == COUT_IDELAY_REG &&
                                we_in_static;
    assign idelay_dout_load_o = sysclk_waiting_flag_sysclk &&
                                adr_in_static == DOUT_IDELAY_REG &&
                                we_in_static;
    // bitslip outputs
    assign iserdes_cout_bitslip_o = sysclk_waiting_flag_sysclk &&
                                    adr_in_static == COUT_DATA_REG &&
                                    we_in_static;                                    
    assign iserdes_dout_bitslip_o = sysclk_waiting_flag_sysclk &&
                                    adr_in_static == DOUT_DATA_REG &&
                                    we_in_static;
    // reset outputs
    assign iserdes_rst_o = iserdes_reset_resync[1];
    assign oserdes_rst_o = oserdes_reset_resync[1];
    // train output
    assign cin_train_o = cin_train_enable_sysclk[1];
                                      
endmodule
