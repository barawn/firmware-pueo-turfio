`timescale 1ns / 1ps
`include "interfaces.vh"
// Based on turfctl register core, but quite a few changes.
// - we don't need the RXCLK phase adjust stuff. RXCLK phase adjustment only happens in the
//   downstream-from-TURF direction to validate the delays.
// - in fact we have no 'rxclk' at all since we don't use SURF rxclks
//   since we don't have enough global clocks
//
// TODO:
// - The next revision will have only ONE biterr counter, and will reorganize.
module surfctl_register_core(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 6, 32),
        
        input sysclk_ok_i,
        input sysclk_i,
                
        // IDELAY inputs/outputs and bitslip
        output idelay_load_o,
        output idelay_dout_load_o,
        // common value
        output [5:0] idelay_value_o,
        input [5:0] idelay_current_i,
        input [5:0] idelay_dout_current_i,
        // common reset
        output iserdes_rst_o,
        output iserdes_bitslip_o,
        output iserdes_dout_bitslip_o,
        // OSERDES reset output, to synchronize
        output oserdes_rst_o,
        
        // COUT alignment for SURFs happens differently
        // than the TURF because we don't try to sync align.
        // So all we have is a capture request,
        // return data, and bit error.
        // We don't have sync lock.
        // We still do a 32-bit capture because it helps.
        input [31:0] cout_data_i,
        input cout_biterr_i,
        output cout_capture_o,
    
        // DOUT alignment happens only on an 8-bit path
        // We don't have a sync lock, but we do have an enable.
        input [7:0] dout_data_i,
        input dout_biterr_i,
        output dout_enable_o,
        output dout_capture_o,
                
        // train enable
        output cin_train_o
    );

    // okay this is all getting SUPER DUMB
    // I'm going to rework this to allow muxing the
    // idelay/bit error count/capture stuff.

    // register definitions
    localparam [5:0] CONTROL_REG = 6'h00;
    localparam [5:0] IDELAY_REG = 6'h04;
    localparam [5:0] BIT_ERROR_COUNT_REG = 6'h08;
    localparam [5:0] COUT_DATA_REG = 6'h0C;
    // dout path
    localparam [5:0] DOUT_IDELAY_REG = 6'h14;
    localparam [5:0] DOUT_BIT_ERROR_COUNT_REG = 6'h18;
    localparam [5:0] DOUT_DATA_REG = 6'h1C;
    // resp path
    localparam [5:0] RESP_IDELAY_REG = 6'h24;
    localparam [5:0] RESP_BIT_ERROR_COUNT_REG = 6'h28;
    localparam [5:0] RESP_DATA_REG = 6'h2C;
    
    
    parameter WB_CLK_TYPE = "INITCLK";

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

    // TODO: Convert this into a module, this is a mess.


    // This determines whether we're jumping to the sysclk side.
    // This happens with the bit error count registers and the COUT/DOUT data registers.
    // It also happens when writing the IDELAYs, but not reading (since they output their current values statically)
    wire sysclk_access = (wb_adr_i == BIT_ERROR_COUNT_REG || wb_adr_i == DOUT_BIT_ERROR_COUNT_REG) ||
                         (wb_adr_i == COUT_DATA_REG || wb_adr_i == DOUT_DATA_REG) ||
                         ((wb_adr_i == IDELAY_REG || wb_adr_i == DOUT_IDELAY_REG) && wb_we_i);
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

    ///////////////////////////////////
    // COUT STUFF
    ///////////////////////////////////
                                
    // BIT ERROR COUNTING FOR ISERDES
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
    
    dsp_timed_counter #(.MODE("ACKNOWLEDGE"),.CLKTYPE_DST("SYSCLK"),.CLKTYPE_SRC("SYSCLK"))
            u_cout_biterr( .clk(sysclk_i),
                          .rst(bit_error_count_ack),
                          .count_in(cout_biterr_i),
                          .interval_in(dat_in_static[23:0]),
                          .interval_load( sysclk_waiting_flag_sysclk &&
                                          adr_in_static == BIT_ERROR_COUNT_REG &&
                                          we_in_static ),
                          .count_out(bit_error_count),
                          .count_out_valid(bit_error_count_valid));

    ///////////////////////////////////
    // DOUT STUFF
    ///////////////////////////////////

    // BIT ERROR COUNTING FOR ISERDES
    wire [24:0] dout_bit_error_count;
    wire        dout_bit_error_count_valid;
    reg         dout_bit_error_count_valid_rereg = 0;
    always @(posedge sysclk_i) dout_bit_error_count_valid_rereg <= dout_bit_error_count_valid;
    wire        dout_bit_error_count_flag = dout_bit_error_count_valid && !dout_bit_error_count_valid_rereg;
    wire        dout_bit_error_count_valid_wbclk;
    flag_sync   u_dout_bit_error_count_valid_sync(.clkA(sysclk_i),.clkB(wb_clk_i),
                                             .in_clkA(dout_bit_error_count_flag),
                                             .out_clkB(dout_bit_error_count_valid_wbclk));
    wire        dout_bit_error_count_ack;
    flag_sync   u_dout_bit_error_ack_sync(.clkA(wb_clk_i),.clkB(sysclk_i),
                                     .in_clkA(dout_bit_error_count_valid_wbclk),
                                     .out_clkB(dout_bit_error_count_ack));
    (* CUSTOM_CC_DST = WB_CLK_TYPE *)
    reg [24:0]  dout_bit_error_count_wbclk = {25{1'b0}};                                     
    always @(posedge wb_clk_i) if (dout_bit_error_count_valid_wbclk) dout_bit_error_count_wbclk <= dout_bit_error_count;
    
    dsp_timed_counter #(.MODE("ACKNOWLEDGE"),.CLKTYPE_DST("SYSCLK"),.CLKTYPE_SRC("SYSCLK"))
            u_cin_biterr( .clk(sysclk_i),
                          .rst(dout_bit_error_count_ack),
                          .count_in(dout_biterr_i),
                          .interval_in(dat_in_static[23:0]),
                          .interval_load( sysclk_waiting_flag_sysclk &&
                                          adr_in_static == DOUT_BIT_ERROR_COUNT_REG &&
                                          we_in_static ),
                          .count_out(dout_bit_error_count),
                          .count_out_valid(dout_bit_error_count_valid));


    // interface logic
    localparam FSM_BITS = 2;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] ACK = 1;
    localparam [FSM_BITS-1:0] WAIT_ACK_SYSCLK = 2;
    reg [FSM_BITS-1:0] state = IDLE;
    
    assign sysclk_waiting = (state == WAIT_ACK_SYSCLK);    

    // iserdes reset
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg iserdes_reset = 0;
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg dout_iserdes_reset = 0;
    
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] iserdes_reset_resync = {2{1'b0}};
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] dout_iserdes_reset_resync = {2{1'b0}};

    // oserdes STARTS OUT in reset.
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg oserdes_reset = 1;
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] oserdes_reset_resync = {2{1'b1}};
    always @(posedge sysclk_i) begin
        iserdes_reset_resync <= { iserdes_reset_resync[0], iserdes_reset };
        dout_iserdes_reset_resync <= { dout_iserdes_reset_resync[0], dout_iserdes_reset };
        oserdes_reset_resync <= { oserdes_reset_resync[0], oserdes_reset };
    end
    
    // switch CIN outputs to SURFs to training mode
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg cin_train_enable = 0;
    // in sysclk domain
    (* CUSTOM_CC_DST = "SYSCLK", ASYNC_REG = "TRUE" *)
    reg [1:0] cin_train_enable_sysclk = {2{1'b0}};
    
    // treat the DOUT data as valid
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg dout_enable = 0;
    (* CUSTOM_CC_DST = "SYSCLK", ASYNC_REG = "TRUE" *)
    reg [1:0] dout_enable_sysclk = {2{1'b0}};

    // treat the RESP data (old TXCLK) as valid
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg resp_enable = 0;
    (* CUSTOM_CC_DST = "SYSCLK", ASYNC_REG = "TRUE" *)
    reg [1:0] resp_enable_sysclk = {2{1'b0}};
            
    wire [31:0] control_register;
    assign control_register[0] = 1'b0;
    assign control_register[1] = 1'b0;
    assign control_register[2] = iserdes_reset;
    assign control_register[3] = 1'b0; 
    assign control_register[4] = 1'b0;
    assign control_register[7:5] = 3'b000;
    assign control_register[9:8] = 2'b00; 
    assign control_register[10] = cin_train_enable;
    assign control_register[11] = dout_enable;
    assign control_register[12] = resp_enable;
    assign control_register[15:13] = 3'h0;
    assign control_register[31:16] = {16{1'b0}};
    
    always @(posedge wb_clk_i) begin
        if (state == ACK && we_in_static && adr_in_static == CONTROL_REG) begin
            if (sel_in_static[1]) begin
                cin_train_enable <= dat_in_static[10];
                dout_enable <= dat_in_static[11];
                resp_enable <= dat_in_static[12];
            end                
            if (sel_in_static[0]) begin
                iserdes_reset <= dat_in_static[2];
                oserdes_reset <= dat_in_static[4];
            end                
        end
        if (wb_cyc_i && wb_stb_i) begin
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
                IDLE: if (wb_cyc_i && wb_stb_i) begin
                    if (sysclk_access) state <= WAIT_ACK_SYSCLK;
                    else state <= ACK;
                end
                ACK: state <= IDLE;
                WAIT_ACK_SYSCLK: if (sysclk_ack_flag_wbclk || !sysclk_ok_i) state <= ACK;
            endcase
        end
        
        if (state == WAIT_ACK_SYSCLK) begin
            if (!sysclk_ok_i) dat_reg <= {32{1'b1}};
            else if (sysclk_ack_flag_wbclk) begin
                if (wb_adr_i == BIT_ERROR_COUNT_REG) dat_reg <= bit_error_count_wbclk;
                else if (wb_adr_i == DOUT_BIT_ERROR_COUNT_REG) dat_reg <= dout_bit_error_count_wbclk;
                else if (wb_adr_i == COUT_DATA_REG) dat_reg <= cout_data_i;
                else if (wb_adr_i == DOUT_DATA_REG) dat_reg <= dout_data_i;
                else dat_reg <= {32{1'b0}};
            end
        end else if (state == IDLE) begin
            if (wb_cyc_i && wb_stb_i && !wb_we_i) begin
                if (wb_adr_i == CONTROL_REG) dat_reg <= control_register;
                else if (wb_adr_i == IDELAY_REG) dat_reg <= idelay_current_i;
                else if (wb_adr_i == DOUT_IDELAY_REG) dat_reg <= idelay_dout_current_i;
                else dat_reg <= {32{1'b0}};
            end
        end
    end
    
    // these are just clock-crosses. This whole module is a bit of a mess.
    always @(posedge sysclk_i) begin
        cin_train_enable_sysclk <= { cin_train_enable_sysclk[0], cin_train_enable };
        dout_enable_sysclk <= { dout_enable_sysclk[0], dout_enable };
        resp_enable_sysclk <= { resp_enable_sysclk[0], resp_enable };        
    end
    
    assign wb_dat_o = dat_reg;
    assign wb_ack_o = (state == ACK);
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
    assign cout_capture_o = sysclk_waiting_flag_sysclk && adr_in_static == COUT_DATA_REG;
    assign dout_capture_o = sysclk_waiting_flag_sysclk && adr_in_static == DOUT_DATA_REG;
    assign dout_enable_o = dout_enable_sysclk[1];

    
    assign idelay_value_o = dat_in_static[5:0];
    assign idelay_load_o = sysclk_waiting_flag_sysclk &&
                            adr_in_static == IDELAY_REG &&
                            we_in_static;
    assign idelay_dout_load_o = sysclk_waiting_flag_sysclk &&
                                adr_in_static == DOUT_IDELAY_REG &&
                                we_in_static;

    assign iserdes_bitslip_o = sysclk_waiting_flag_sysclk &&
                               adr_in_static == COUT_DATA_REG &&
                               we_in_static;
    assign iserdes_dout_bitslip_o = sysclk_waiting_flag_sysclk &&
                                    adr_in_static == DOUT_DATA_REG &&
                                    we_in_static;
    assign iserdes_rst_o = iserdes_reset_resync[1];

    assign oserdes_rst_o = oserdes_reset_resync[1];
    assign cin_train_o = cin_train_enable_sysclk[1];
                                      
endmodule
