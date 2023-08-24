`timescale 1ns / 1ps
// This module processes the Aurora command input streams,
// executes the access, and returns the data. The command input stream
// and response here comes via the UFC path.
//
// The commands can also be routed through the command processor
// via the turfctl interface, but in that case the data will be returned
// via the TURFIO's COUT path.
`include "interfaces.vh"
module aurora_wb_master(
        // NOTE: aclk = wbclk
        input aclk,
        input aresetn,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_addr_ , 32 ),
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_data_ , 32 ),
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_resp_ , 32 ),
        input wb_rst_i,        
        `HOST_NAMED_PORTS_WB_IF( wb_ , 22, 32 )        
    );
    
    localparam FSM_BITS=2;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] ISSUE = 1;
    localparam [FSM_BITS-1:0] RESPOND = 2;
    reg [FSM_BITS-1:0] state = IDLE;
    
    // just hold the WB data
    reg [31:0] resp_data = {32{1'b0}};
    // register the tready response for the addr paths to simplify
    reg addr_tready = 1'b0;
    // register the tready response for the data paths to simplify
    reg data_tready = 1'b0;
    
    // overall process is pretty straightforward    
    always @(posedge aclk) begin
        if (!aresetn) state <= IDLE;
        else begin
            case (state)
                IDLE: if (s_addr_tvalid && (s_addr_tdata[31] || s_data_tvalid)) state <= ISSUE;
                ISSUE: if (wb_ack_i || wb_err_i || wb_rty_i) state <= RESPOND;
                RESPOND: if (m_resp_tready) state <= IDLE;
            endcase
        end
        
        // these will be 1-cycle acks
        addr_tready <= (state == ISSUE && (wb_ack_i || wb_err_i || wb_rty_i));
        data_tready <= (state == ISSUE && (wb_ack_i || wb_err_i || wb_rty_i) && wb_we_o);
        
        if (wb_ack_i) resp_data <= wb_dat_i;
    end
    
    // now all of these should just be direct paths
    assign s_addr_tready = addr_tready;
    assign s_data_tready = data_tready;
    
    assign wb_adr_o = {s_addr_tdata[2 +: 20], 2'b00};
    assign wb_we_o = !s_addr_tdata[31];
    assign wb_sel_o = {4{wb_we_o}};
    assign wb_dat_o = s_data_tdata;        
    assign wb_cyc_o = (state == ISSUE);
    assign wb_stb_o = wb_cyc_o;
    assign m_resp_tvalid = (state == RESPOND);
    assign m_resp_tdata = resp_data;
endmodule
