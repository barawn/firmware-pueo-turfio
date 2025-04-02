`timescale 1ns / 1ps
// This module processes the Aurora command input streams,
// executes the access, and returns the data. The command input stream
// and response here comes via the UFC path.
`include "interfaces.vh"
// ADDR_BITS here can only be up to 31
module aurora_wb_master #(parameter ADDR_BITS=25,
                          parameter DEBUG = "TRUE")(
        // NOTE: aclk = wbclk
        input aclk,
        input aresetn,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_addr_ , 32 ),
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_data_ , 32 ),
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_resp_ , 32 ),
        input wb_rst_i,        
        `HOST_NAMED_PORTS_WB_IF( wb_ , ADDR_BITS, 32 )        
    );
    
    localparam FSM_BITS=2;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] ISSUE = 1;
    localparam [FSM_BITS-1:0] READ_RESPOND = 2;
    localparam [FSM_BITS-1:0] WRITE_FINISH = 3;
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
                ISSUE: if (wb_ack_i || wb_err_i || wb_rty_i) begin
                    // No response if it's a write.
                    if (wb_we_o) state <= WRITE_FINISH;
                    // Otherwise respond.
                    else state <= READ_RESPOND;
                end
                WRITE_FINISH: state <= IDLE;
                READ_RESPOND: if (m_resp_tready) state <= IDLE;
            endcase
        end
        
        // these will be 1-cycle acks and will occur in either WRITE_FINISH or the first cycle of READ_RESPOND
        addr_tready <= (state == ISSUE && (wb_ack_i || wb_err_i || wb_rty_i));
        data_tready <= (state == ISSUE && (wb_ack_i || wb_err_i || wb_rty_i) && wb_we_o);
        
        if (wb_ack_i) resp_data <= wb_dat_i;
    end

    generate
        if (DEBUG == "TRUE") begin : ILA
            aurora_cmd_ila u_acmd_ila(.clk(aclk),
                                 .probe0( s_addr_tdata ),
                                 .probe1( s_addr_tvalid ),
                                 .probe2( s_data_tdata ),
                                 .probe3( s_data_tvalid ),
                                 .probe4( m_resp_tdata ),
                                 .probe5( m_resp_tvalid) );
        end
    endgenerate        
    // now all of these should just be direct paths
    assign s_addr_tready = addr_tready;
    assign s_data_tready = data_tready;
    
    assign wb_adr_o = {s_addr_tdata[2 +: (ADDR_BITS-2)], 2'b00};
    assign wb_we_o = !s_addr_tdata[31];
    assign wb_sel_o = {4{wb_we_o}};
    assign wb_dat_o = s_data_tdata;        
    assign wb_cyc_o = (state == ISSUE);
    assign wb_stb_o = wb_cyc_o;
    assign m_resp_tvalid = (state == READ_RESPOND);
    assign m_resp_tdata = resp_data;
endmodule
