`timescale 1ns / 1ps
`include "interfaces.vh"
// Accepts WISHBONE interface and translates into RACKctl transactions.
// Just mode 0 for now, but the ports support mode 1.
module rackctl_wb_bridge #(parameter INV = 1'b0,
                           parameter WB_CLK_TYPE = "INITCLK",
                           parameter USE_IDELAY = "FALSE",
                           parameter IDELAY_VALUE = 0,
                           parameter DEBUG = "FALSE")(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF( gtp_ , 22, 32 ),
        `TARGET_NAMED_PORTS_WB_IF( dbg_ , 22, 32 ),
        // goes to the ctrlstat reg
        output bridge_err_o,
        input  err_rst_i,
        
        // sysclk side
        input sysclk_i,
        input sysclk_ok_i,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_cmd_ , 8 ),
        output m_cmd_tlast,
        input mode_i,        
        
        inout RACKCTL_P,
        inout RACKCTL_N
    );
    
    localparam DBG_BUS = 0;
    localparam GTP_BUS = 1;
    reg master_select = DBG_BUS;
    
    wire any_cyc_stb = (gtp_cyc_i && gtp_stb_i) || (dbg_cyc_i && dbg_stb_i);
    wire mux_we = (master_select == GTP_BUS) ? gtp_we_i : dbg_we_i;
    wire [21:0] mux_addr = (master_select == GTP_BUS) ? gtp_adr_i : dbg_adr_i;
    wire [31:0] mux_data = (master_select == GTP_BUS) ? gtp_dat_i : dbg_dat_i;
    wire [3:0] mux_sel = (master_select == GTP_BUS) ? gtp_sel_i : dbg_sel_i;        
        
    reg bridge_timeout = 0;    
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg mode = 0;
    (* CUSTOM_CC_DST = "SYSCLK", ASYNC_REG = "TRUE" *)
    reg [1:0] mode_sysclk = {2{1'b0}};
    
    // 0 if a write, 1 if a read
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg        txn_type = 0;
    // 22 bit address.
    // The bottom 2 bits here are actually unused, plus there's a 3rd up top.
    // Might be abusable if needed.
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [21:0] txn_address = {22{1'b0}};
    // expand to 24 bits
    wire [23:0] txn_address_full = {txn_type, 1'b0, txn_address };
    // either data in or out    
    (* CUSTOM_CC_SRC = WB_CLK_TYPE, CUSTOM_CC_DST = WB_CLK_TYPE *)
    reg [31:0] txn_data = {32{1'b0}};
    
    // start transaction in 
    wire txn_start_flag_wbclk;
    wire txn_start_flag_sysclk;
    // transaction finish OK in
    wire txn_done_flag_sysclk;
    wire txn_done_flag_wbclk;
    // transaction error in
    wire txn_err_flag_sysclk;
    wire txn_err_flag_wbclk;
    // response data out
    wire [31:0] response_data;
    
    // AXI4-Stream path to 32-bit FIFO
    `DEFINE_AXI4S_MIN_IF( wbcmd_ , 32 );
    // just make it a dump for now
    assign wbcmd_tready = 1'b1;
    // kill the output too
    assign m_cmd_tvalid = 1'b0;
    
    localparam FSM_BITS = 3;
    localparam [FSM_BITS-1:0] IDLE = 0;             
    localparam [FSM_BITS-1:0] ACCEPT = 1;             // capture inputs
    localparam [FSM_BITS-1:0] ISSUE = 2;              // generate txn flag in both modes
    localparam [FSM_BITS-1:0] WAIT_COMPLETE = 3;      // wait for either done or err
    localparam [FSM_BITS-1:0] ACK = 4;                // WISHBONE ack
    localparam [FSM_BITS-1:0] MODE1_WRITE_0 = 5;      // write address/rnw
    localparam [FSM_BITS-1:0] MODE1_WRITE_1 = 6;      // write data if needed
    localparam [FSM_BITS-1:0] MODE_CHANGE_WAIT = 7;   // mode changes are transactions too
    reg [FSM_BITS-1:0] state = IDLE;
    
    always @(posedge wb_clk_i) begin
        if (state == ACCEPT) begin
            txn_type <= !mux_we;
            txn_address <= mux_addr[0 +: 22];
        end
        if (state == ACCEPT && mux_we) txn_data <= mux_data;
        else if (state == WAIT_COMPLETE) begin
            if (txn_done_flag_wbclk) txn_data <= response_data;
            else if (txn_err_flag_wbclk) txn_data <= {32{1'b1}};
        end
        // only change in IDLE
        if (state == IDLE) mode <= mode_i;
        // arbitrate
        if (state == IDLE && sysclk_ok_i) begin
            if (gtp_cyc_i && gtp_stb_i) master_select <= GTP_BUS;
            else if (dbg_cyc_i && dbg_stb_i) master_select <= DBG_BUS;
        end
        // TODO: IMPROVE THE SYSCLK_OK HANDLING
        // WE NEED TO BE BAILING OUT FROM THE WAIT OR SOMETHING
        case (state)
            // when we jump to ACCEPT, master_select becomes valid in SELECT so we can capture then
            IDLE: if (sysclk_ok_i) begin
                        if (mode_i != mode) state <= MODE_CHANGE_WAIT; 
                        else if (any_cyc_stb) state <= ACCEPT;
                   end
            ACCEPT: if (!mode) state <= ISSUE;
                    else state <= MODE1_WRITE_0;
            ISSUE: state <= WAIT_COMPLETE;
            WAIT_COMPLETE: if (txn_done_flag_wbclk || txn_err_flag_wbclk) state <= ACK;
            ACK: state <= IDLE;
            MODE1_WRITE_0: if (wbcmd_tready && wbcmd_tvalid) state <= MODE1_WRITE_1;
            MODE1_WRITE_1: if (wbcmd_tready && wbcmd_tvalid) state <= ISSUE;                    
            MODE_CHANGE_WAIT: if (txn_done_flag_wbclk || txn_err_flag_wbclk) state <= IDLE;
        endcase           
    end
    
    always @(posedge sysclk_i) begin
        mode_sysclk <= { mode_sysclk[0], mode };
    end
    
    assign txn_start_flag_wbclk = (state == ISSUE);
    
    // cross-clocks
    flag_sync u_start_sync(.clkA(wb_clk_i),.clkB(sysclk_i),
                           .in_clkA(txn_start_flag_wbclk),.out_clkB(txn_start_flag_sysclk));
    flag_sync u_done_sync(.clkA(sysclk_i),.clkB(wb_clk_i),
                          .in_clkA(txn_done_flag_sysclk),.out_clkB(txn_done_flag_wbclk));
    flag_sync u_err_sync(.clkA(sysclk_i),.clkB(wb_clk_i),
                         .in_clkA(txn_err_flag_sysclk),.out_clkB(txn_err_flag_wbclk));                                      
    
    surf_rackctl_phy #(.USE_IDELAY(USE_IDELAY),
                       .IDELAY_VALUE(IDELAY_VALUE),
                       .INV(INV),.DEBUG((DEBUG == "PHY" || DEBUG == "FULL") ? "TRUE" : "FALSE"))
        u_phy( .sysclk_i(sysclk_i),.mode_i(mode_sysclk[1]),
               .txn_addr_i(txn_address_full),
               .txn_data_i(txn_data),
               .txn_resp_o(response_data),
               .txn_start_i(txn_start_flag_sysclk),
               .txn_done_o(txn_done_flag_sysclk),
               .txn_err_o(txn_err_flag_sysclk),
               .RACKCTL_P(RACKCTL_P),
               .RACKCTL_N(RACKCTL_N));
    
    assign gtp_ack_o = (state == ACK) && (master_select == GTP_BUS);
    assign dbg_ack_o = (state == ACK) && (master_select == DBG_BUS);
    assign gtp_err_o = 1'b0;
    assign dbg_err_o = 1'b0;
    assign gtp_rty_o = 1'b0;
    assign dbg_rty_o = 1'b0;
    assign gtp_dat_o = txn_data;
    assign dbg_dat_o = txn_data;    
    
endmodule
