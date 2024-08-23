`timescale 1ns / 1ps
`include "interfaces.vh"
// This module separates out all of the register interface
// from the TURF control core. Was just too messy.

// Register 0: TURFCTL Control/Reset/Phase.
//             [0] RXCLK MMCM reset
//             [1] RXCLK MMCM not locked
//             [2] ISERDES reset
//             [3] CIN parallelizer reset
//             [4] OSERDES reset
//             [7:5] reserved
//             [8]  CIN parallelizer lock enable
//             [9]  CIN parallelizer lock
//             [10] COUT (all of them) train enable
//             [15:11] reserved
//             [24:16] RXCLK phase adjust
//             [31] RXCLK phase adjust in progress

module turfctl_register_core(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_, 6, 32),
        
        input sysclk_ok_i,
        input sysclk_i,
        input rxclk_ok_i,
        input rxclk_i,
        
        // RXCLK/SYSCLK transfer controls
        output ps_en_o,
        input ps_done_i,
        input mmcm_locked_i,
        output mmcm_rst_o,
        input sysclk_rxclk_biterr_i,
        
        // IDELAY inputs/outputs and bitslip (to turf_cin)
        output idelay_load_o,
        output [5:0] idelay_value_o,
        input [5:0] idelay_current_i,
        output iserdes_rst_o,
        output iserdes_bitslip_o,
        
        // OSERDES reset output, to synchronize.
        output oserdes_rst_o,
        
        // turf_cin_parallel_sync inputs/outputs
        output cin_sync_rst_o,
        output cin_sync_capture_o,
        input [31:0] cin_sync_data_i,
        input cin_sync_biterr_i,
        output cin_sync_lock_o,
        input cin_sync_locked_i,
        
        // cout train enable
        output cout_train_o
    );

    parameter DEBUG = "FALSE";
    parameter WB_CLK_TYPE = "INITCLK";
    
    // Maximum phase shift for RXCLK. Fine phase shift is 1/56th, RXCLK is 8x, 56*8=448.
    localparam [8:0] RXCLK_FINE_PS_MAX = 448 - 1;

    // Demultiplexed output register.
    (* CUSTOM_CC_DST = WB_CLK_TYPE *)
    reg [31:0] dat_reg = {32{1'b0}};

    //////////////////////////////////////////
    // Clock Crossings
    //
    // Our register access in the wb clk domain
    // But some of our controls/etc. are in the
    // rxclk and sysclk domains.
    //
    // So if those controls are accessed,
    // we bounce over to the other domain
    // and let them process it.
    //
    // Just to make the clock crossings easier
    // we hold address, write enable, and data
    // static here.
    //////////////////////////////////////////
    
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [31:0] dat_in_static = {32{1'b0}};
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [5:0]  adr_in_static = {6{1'b0}};
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [3:0]  sel_in_static = {4{1'b0}};
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg        we_in_static = 0;

    // These determine whether we're jumping over to the rxclk or sysclk sides.
    wire rxclk_access = (wb_adr_i == 6'h4 || (wb_adr_i == 6'h0C && wb_we_i));
    wire sysclk_access = (wb_adr_i == 6'h8 || (wb_adr_i == 6'h0C && !wb_we_i) ||
                          wb_adr_i == 6'h10 || wb_adr_i == 6'h14 || wb_adr_i == 6'h18 || 
                          wb_adr_i == 6'h1C);
    // These are the flags to inform the other domains.
    wire rxclk_waiting;
    reg rxclk_waiting_reg = 0;
    always @(posedge wb_clk_i) rxclk_waiting_reg <= rxclk_waiting;
    wire rxclk_waiting_flag_wbclk = (rxclk_waiting && !rxclk_waiting_reg);
    wire rxclk_waiting_flag_rxclk;
    flag_sync u_rxclk_waiting_sync(.clkA(wb_clk_i),.clkB(rxclk_i),
                                   .in_clkA(rxclk_waiting_flag_wbclk),
                                   .out_clkB(rxclk_waiting_flag_rxclk));
    reg  rxclk_ack_flag_rxclk = 0;
    always @(posedge rxclk_i) rxclk_ack_flag_rxclk <= rxclk_waiting_flag_rxclk;
    wire rxclk_ack_flag_wbclk;
    flag_sync u_rxclk_ack_sync(.clkA(rxclk_i),.clkB(wb_clk_i),
                               .in_clkA(rxclk_ack_flag_rxclk),
                               .out_clkB(rxclk_ack_flag_wbclk));

    wire sysclk_waiting;
    reg sysclk_waiting_reg = 0;
    always @(posedge wb_clk_i) sysclk_waiting_reg <= sysclk_waiting;
    wire sysclk_waiting_flag_wbclk = (sysclk_waiting && !sysclk_waiting_reg);
    wire sysclk_waiting_flag_sysclk;
    flag_sync u_sysclk_waiting_sync(.clkA(wb_clk_i),.clkB(sysclk_i),
                                    .in_clkA(sysclk_waiting_flag_wbclk),
                                    .out_clkB(sysclk_waiting_flag_sysclk));
    reg sysclk_ack_flag_sysclk = 0;
    always @(posedge sysclk_i) sysclk_ack_flag_sysclk <= sysclk_waiting_flag_sysclk;
    wire sysclk_ack_flag_wbclk;
    flag_sync u_sysclk_ack_sync(.clkA(sysclk_i),.clkB(wb_clk_i),
                                .in_clkA(sysclk_ack_flag_sysclk),
                                .out_clkB(sysclk_ack_flag_wbclk));

    ///////////////////////////////////////////
    // BIT ERROR COUNTING FOR SYSCLK/RXCLK TRANSFER
    ///////////////////////////////////////////

    wire [24:0] sysclk_bit_error_count;
    wire        sysclk_bit_error_count_valid;
    reg         sysclk_bit_error_count_valid_rereg = 0;
    always @(posedge sysclk_i) sysclk_bit_error_count_valid_rereg <= sysclk_bit_error_count_valid;
    wire        sysclk_bit_error_count_flag = sysclk_bit_error_count_valid && !sysclk_bit_error_count_valid_rereg;
    wire        sysclk_bit_error_count_valid_wbclk;
    flag_sync   u_sysclk_biterr_valid_sync(.in_clkA(sysclk_bit_error_count_flag),
                                           .out_clkB(sysclk_bit_error_count_valid_wbclk),
                                           .clkA(sysclk_i),
                                           .clkB(wb_clk_i));
    wire        sysclk_bit_error_count_ack;
    flag_sync   u_sysclk_biterr_ack(.in_clkA(sysclk_bit_error_count_valid_wbclk),
                                    .out_clkB(sysclk_bit_error_count_ack),
                                    .clkA(wb_clk_i),
                                    .clkB(sysclk_i));
    (* CUSTOM_CC_DST = WB_CLK_TYPE *)                                    
    reg [24:0]  sysclk_bit_error_count_wbclk = {25{1'b0}};
    always @(posedge wb_clk_i)
        if (sysclk_bit_error_count_valid_wbclk) 
            sysclk_bit_error_count_wbclk <= sysclk_bit_error_count;
    
    // We use the timed counters in acknowledge mode so we don't need a separate set of clock-cross.
    // Note: this implies you *probably* should write an interval in first rather than
    // trusting them to run with max interval in the beginning.
    dsp_timed_counter #(.MODE("ACKNOWLEDGE"),.CLKTYPE_SRC("SYSCLK"),.CLKTYPE_DST("SYSCLK"))
            u_sysclk_biterr( .clk(sysclk_i),
                             .rst(sysclk_bit_error_count_ack),
                             .count_in(sysclk_rxclk_biterr_i),
                             .interval_in(dat_in_static[23:0]),
                             .interval_load( sysclk_waiting_flag_sysclk &&
                                             adr_in_static == 6'h1C &&
                                             we_in_static ),
                             .count_out(sysclk_bit_error_count),
                             .count_out_valid(sysclk_bit_error_count_valid));

    ///////////////////////////////////////////
    // BIT ERROR COUNTING FOR ISERDES
    ///////////////////////////////////////////
    wire [24:0] bit_error_count;
    wire        bit_error_count_valid;
    reg         bit_error_count_valid_rereg = 0;
    always @(posedge sysclk_i) bit_error_count_valid_rereg <= bit_error_count_valid;
    wire        bit_error_count_flag = bit_error_count_valid && !bit_error_count_valid_rereg;    
    wire        bit_error_count_valid_wbclk;
    flag_sync   u_bit_error_count_valid_sync(.clkA(sysclk_i),.clkB(wb_clk_i),
                                             .in_clkA(bit_error_count_flag),
                                             .out_clkB(bit_error_count_valid_wbclk));
    wire        bit_error_count_ack;
    flag_sync   u_bit_error_ack_sync(.clkA(wb_clk_i),.clkB(sysclk_i),
                                     .in_clkA(bit_error_count_valid_wbclk),
                                     .out_clkB(bit_error_count_ack));    
    (* CUSTOM_CC_DST = WB_CLK_TYPE *)                                     
    reg [24:0]  bit_error_count_wbclk = {25{1'b0}};
    always @(posedge wb_clk_i) if (bit_error_count_valid_wbclk) bit_error_count_wbclk <= bit_error_count;
        
    dsp_timed_counter #(.MODE("ACKNOWLEDGE"),.CLKTYPE_SRC("SYSCLK"),.CLKTYPE_DST("SYSCLK"))
                        u_cin_biterr( .clk(sysclk_i),
                                      .rst(bit_error_count_ack),
                                      .count_in(cin_sync_biterr_i),
                                      .interval_in(dat_in_static[23:0]),
                                      .interval_load( sysclk_waiting_flag_sysclk &&
                                                      adr_in_static == 6'h8 &&
                                                      we_in_static ),
                                      .count_out(bit_error_count),
                                      .count_out_valid(bit_error_count_valid));

    // CIN parallelization and lock.
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg enable_lock = 0;
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] enable_lock_sysclk = {2{1'b0}};    
    always @(posedge sysclk_i) enable_lock_sysclk <= {enable_lock_sysclk[0], enable_lock };
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = WB_CLK_TYPE *)
    reg [1:0] cin_locked_wbclk = {2{1'b0}};
    always @(posedge wb_clk_i) cin_locked_wbclk <= {cin_locked_wbclk[0], cin_sync_locked_i };    
    wire cin_locked = cin_locked_wbclk[1];

    // Interface logic
    localparam FSM_BITS=2;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] ACK = 1;
    localparam [FSM_BITS-1:0] WAIT_ACK_RXCLK = 2;
    localparam [FSM_BITS-1:0] WAIT_ACK_SYSCLK = 3;
    reg [FSM_BITS-1:0] state = IDLE;
    
    assign rxclk_waiting = (state == WAIT_ACK_RXCLK);
    assign sysclk_waiting = (state == WAIT_ACK_SYSCLK);
    
    // These need to be 9 bits! Duh.
    reg [8:0] current_ps_value = {9{1'b0}};
    reg [8:0] target_ps_value = {9{1'b0}};
    reg       ps_waiting = 0;
    reg       ps_enable = 0;
    wire      fine_ps_enable;
    assign    fine_ps_enable = ps_enable && !ps_waiting;
    reg       ps_incomplete = 0;        

    // MMCM reset (async, doesn't matter)
    reg       mmcm_reset = 0;
    // ISERDES reset (also copied to output).
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg       iserdes_reset = 0;
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg       oserdes_reset = 0;
    // Resync registers.
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "RXCLK" *)
    reg [1:0] iserdes_reset_resync = {2{1'b0}};
    always @(posedge rxclk_i) iserdes_reset_resync <= {iserdes_reset_resync[0], iserdes_reset };
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] oserdes_reset_resync = {2{1'b0}};
    always @(posedge sysclk_i) oserdes_reset_resync <= { oserdes_reset_resync[0], oserdes_reset };
    // parallelizer reset (convert to flag, resync to sysclk)
    reg       cin_sync_reset = 0;
    // reregister
    reg       cin_sync_reset_rereg = 0;
    // flag
    wire      cin_sync_reset_flag = cin_sync_reset && !cin_sync_reset_rereg;
    // cross
    flag_sync u_cin_sync_reset_sync(.in_clkA(cin_sync_reset_flag),
                                    .out_clkB(cin_sync_rst_o),
                                    .clkA(wb_clk_i),
                                    .clkB(sysclk_i));
    
    // Enable training on COUT registers
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg       cout_train_enable = 0;
    // in sysclk land
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] cout_train_enable_sysclk = {2{1'b0}};
    
    
    wire [31:0] reset_register;
    assign reset_register[0] = mmcm_reset;
    assign reset_register[1] = mmcm_locked_i;
    assign reset_register[2] = iserdes_reset;
    assign reset_register[3] = cin_sync_reset;
    assign reset_register[4] = oserdes_reset;
    assign reset_register[7:5] = 3'h0;
    assign reset_register[8] = enable_lock;
    assign reset_register[9] = cin_locked;
    assign reset_register[10] = cout_train_enable;
    assign reset_register[15:11] = 5'h00;
    assign reset_register[16 +: 9] = target_ps_value;
    assign reset_register[25 +: 6] = {6{1'b0}};
    assign reset_register[31] = ps_incomplete;


    always @(posedge wb_clk_i) begin        
        if (target_ps_value != current_ps_value) begin
            if (ps_waiting) ps_enable <= 0;
            else ps_enable <= 1;
        end else ps_enable <= 0;

        if (ps_enable) ps_waiting <= 1;
        else if (ps_done_i) ps_waiting <= 0;

        if (fine_ps_enable) begin
            if (current_ps_value == RXCLK_FINE_PS_MAX) current_ps_value <= {9{1'b0}};
            else current_ps_value <= current_ps_value + 1;
        end
        ps_incomplete <= !((target_ps_value == current_ps_value) && !ps_waiting);
    
        if (state == ACK && we_in_static && adr_in_static == 6'h00) begin
            // just... don't ever do byte-wide writes to these...
            if (sel_in_static[3]) target_ps_value[8] <= dat_in_static[24];
            if (sel_in_static[2]) target_ps_value[7:0] <= dat_in_static[23:16];    
            if (sel_in_static[1]) begin
                enable_lock <= dat_in_static[8];
                cout_train_enable <= dat_in_static[10];
            end
            if (sel_in_static[0]) begin
                mmcm_reset <= dat_in_static[0];
                iserdes_reset <= dat_in_static[2];
                cin_sync_reset <= dat_in_static[3];
                oserdes_reset <= dat_in_static[4];
            end
        end    
    
        if (wb_cyc_i && wb_stb_i) begin
            // stupid, but whatever
            if (wb_sel_i[0]) dat_in_static[7:0] <= wb_dat_i[7:0];
            if (wb_sel_i[1]) dat_in_static[15:8] <= wb_dat_i[15:8];
            if (wb_sel_i[2]) dat_in_static[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) dat_in_static[31:24] <= wb_dat_i[31:24];
            adr_in_static <= wb_adr_i;
            we_in_static <= wb_we_i;
            sel_in_static <= wb_sel_i;
        end

        if (wb_rst_i) state <= IDLE;
        else begin
            case (state)
                IDLE:   if (wb_cyc_i && wb_stb_i) begin
                            if (rxclk_access) state <= WAIT_ACK_RXCLK;
                            else if (sysclk_access) state <= WAIT_ACK_SYSCLK;
                            else state <= ACK;
                        end
                ACK: state <= IDLE;
                WAIT_ACK_RXCLK: if (rxclk_ack_flag_wbclk || !rxclk_ok_i) state <= ACK;
                WAIT_ACK_SYSCLK: if (sysclk_ack_flag_wbclk || !sysclk_ok_i) state <= ACK;
            endcase
        end
    
        if (state == WAIT_ACK_RXCLK) begin
            if (rxclk_ack_flag_wbclk) begin
                if (wb_adr_i == 6'h4) dat_reg <= idelay_current_i;
            end else if (!rxclk_ok_i) begin
                dat_reg <= {32{1'b1}};
            end
        end else if (state == WAIT_ACK_SYSCLK) begin
            if (!sysclk_ok_i) dat_reg <= {32{1'b1}};
            else if (sysclk_ack_flag_wbclk) begin
                if (wb_adr_i == 6'h8) dat_reg <= bit_error_count_wbclk;
                else if (wb_adr_i == 6'hC) dat_reg <= cin_sync_data_i;
                else if (wb_adr_i == 6'h1C) dat_reg <= sysclk_bit_error_count_wbclk;
                else dat_reg <= {32{1'b0}};
            end            
        end else if (state == IDLE) begin
            if (wb_cyc_i && wb_stb_i && wb_adr_i == 6'h0 && !wb_we_i) begin
                dat_reg <= reset_register;
            end
        end
    end            

    always @(posedge sysclk_i) begin
        cout_train_enable_sysclk <= { cout_train_enable_sysclk[0], cout_train_enable };
    end
    
    generate
        if (DEBUG == "TRUE") begin : DBG    
            turfwb_ila u_ila(.clk(wb_clk_i),
                             .probe0(wb_cyc_i),
                             .probe1(wb_stb_i),
                             .probe2(wb_ack_o),
                             .probe3(wb_adr_i),
                             .probe4(dat_reg),
                             .probe5(rxclk_ack_flag_wbclk),
                             .probe6(sysclk_ack_flag_wbclk),
                             .probe7(current_ps_value),
                             .probe8(fine_ps_enable),
                             .probe9(ps_done_i),
                             .probe10(state));
        end
    endgenerate

    assign wb_dat_o = dat_reg;
    assign wb_ack_o = (state == ACK);
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;

    assign ps_en_o = fine_ps_enable;
    // figure this out later
    assign mmcm_rst_o = mmcm_reset;

    assign cin_sync_lock_o = enable_lock_sysclk[1];
    assign cin_sync_capture_o = sysclk_waiting_flag_sysclk && adr_in_static == 6'h0C;

    assign idelay_value_o = dat_in_static[5:0];
    assign idelay_load_o = rxclk_waiting_flag_rxclk &&
                                 adr_in_static == 6'h4 &&
                                 we_in_static;
    assign iserdes_bitslip_o = rxclk_waiting_flag_rxclk &&
                                     adr_in_static == 6'hC &&
                                     we_in_static;                                 
    assign iserdes_rst_o = iserdes_reset_resync[1];

    assign oserdes_rst_o = oserdes_reset_resync[1];
    // parallel sync comes out of the flag synchronizer

    assign cout_train_o = cout_train_enable_sysclk[1];
endmodule
