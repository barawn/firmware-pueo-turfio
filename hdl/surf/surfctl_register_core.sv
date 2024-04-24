`timescale 1ns / 1ps
`include "interfaces.vh"
// Based on turfctl register core, but quite a few changes.
// - we don't need the RXCLK phase adjust stuff. RXCLK phase adjustment only happens in the
//   downstream-from-TURF direction to validate the delays.
// - in fact we have no 'rxclk' at all since we don't use SURF rxclks
//   since we don't have enough global clocks
module surfctl_register_core(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 6, 32),
        
        input sysclk_ok_i,
        input sysclk_i,
                
        // IDELAY inputs/outputs and bitslip
        output idelay_load_o,
        output [5:0] idelay_value_o,
        input [5:0] idelay_current_i,
        output iserdes_rst_o,
        output iserdes_bitslip_o,
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
                
        // train enable
        output cin_train_o
    );

    // register definitions
    localparam [5:0] CONTROL_REG = 6'h00;
    localparam [5:0] IDELAY_REG = 6'h04;
    localparam [5:0] BIT_ERROR_COUNT_REG = 6'h08;
    localparam [5:0] COUT_DATA_REG = 6'h0C;
    // remaining ones are unused right now
    
    parameter WB_CLK_TYPE = "INITCLK";
    
    reg [31:0] dat_reg = {32{1'b0}};
    reg [31:0] dat_in_static = {32{1'b0}};
    reg [5:0] adr_in_static = {6{1'b0}};
    reg [3:0] sel_in_static = {4{1'b0}};
    reg we_in_static = 0;
    
    // This determines whether we're jumping to the sysclk side.
    // Happens whenever we write/read the bit error count reg or when we read the cout data.
    wire sysclk_access = (wb_adr_i == 6'h8 || (wb_adr_i == 6'h0C && !wb_we_i));
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
    reg [24:0]  bit_error_count_wbclk = {25{1'b0}};                                     
    always @(posedge wb_clk_i) if (bit_error_count_valid_wbclk) bit_error_count_wbclk <= bit_error_count;
    
    dsp_timed_counter #(.MODE("ACKNOWLEDGE"))
            u_cin_biterr( .clk(sysclk_i),
                          .rst(bit_error_count_ack),
                          .count_in(cin_sync_biterr_i),
                          .interval_in(dat_in_static[23:0]),
                          .interval_load( sysclk_waiting_flag_sysclk &&
                                          adr_in_static == BIT_ERROR_COUNT_REG &&
                                          we_in_static ),
                          .count_out(bit_error_count),
                          .count_out_valid(bit_error_count_valid));

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
    reg oserdes_reset = 0;
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] iserdes_reset_resync = {2{1'b0}};
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] oserdes_reset_resync = {2{1'b0}};
    always @(posedge sysclk_i) begin
        iserdes_reset_resync <= { iserdes_reset_resync[0], iserdes_reset };
        oserdes_reset_resync <= { oserdes_reset_resync[0], oserdes_reset };
    end
    
    // switch CIN outputs to SURFs to training mode
    reg cin_train_enable = 0;
    wire [31:0] control_register;
    assign control_register[0] = 1'b0;
    assign control_register[1] = 1'b0;
    assign control_register[2] = iserdes_reset;
    assign control_register[3] = 1'b0;
    assign control_register[4] = 1'b0;
    assign control_register[7:5] = 3'b000;
    assign control_register[9:8] = 2'b00;
    assign control_register[10] = cin_train_enable;
    assign control_register[15:11] = 5'h00;
    assign control_register[31:16] = {16{1'b0}};
    
    always @(posedge wb_clk_i) begin
        if (state == ACK && we_in_static && adr_in_static == CONTROL_REG) begin
            if (sel_in_static[1]) cin_train_enable <= dat_in_static[10];
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
                else if (wb_adr_i == COUT_DATA_REG) dat_reg <= cout_data_i;
                else if (wb_adr_i == IDELAY_REG) dat_reg <= idelay_current_i;
                else dat_reg <= {32{1'b0}};
            end
        end else if (state == IDLE) begin
            if (wb_cyc_i && wb_stb_i && wb_adr_i == CONTROL_REG && !wb_we_i) begin
                dat_reg <= control_register;
            end
        end
    end
    
    assign wb_dat_o = dat_reg;
    assign wb_ack_o = (state == ACK);
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
    assign cout_capture_o = sysclk_waiting_flag_sysclk && adr_in_static == COUT_DATA_REG;
    
    assign idelay_value_o = dat_in_static[5:0];
    assign idelay_load_o = sysclk_waiting_flag_sysclk &&
                            adr_in_static == IDELAY_REG &&
                            we_in_static;
    assign iserdes_bitslip_o = sysclk_waiting_flag_sysclk &&
                               adr_in_static == COUT_DATA_REG &&
                               we_in_static;
    assign iserdes_rst_o = iserdes_reset_resync[1];
    assign oserdes_rst_o = oserdes_reset_resync[1];
    assign cin_train_o = cin_train_enable;
                                      
endmodule
