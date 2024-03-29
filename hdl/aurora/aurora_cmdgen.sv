`timescale 1ns / 1ps
`include "interfaces.vh"
module aurora_cmdgen( input aclk,
                      input aresetn,
                      `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_axis_ , 32 ),
                      input [3:0] s_axis_tkeep,
                      input s_axis_tlast,
                      `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_cmd_addr_ , 32 ),
                      `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_cmd_data_ , 32 )
    );

    parameter DEBUG = "TRUE";

    // internal write checked bus (see later)
    `DEFINE_AXI4S_MIN_IF( cmdin_wrcheck_ , 32);
    wire cmdin_wrcheck_tdest;
    
    // path to register slice, address
    `DEFINE_AXI4S_MIN_IF( rs_cmd_addr_ , 32 );
    // path to register slice, data
    `DEFINE_AXI4S_MIN_IF( rs_cmd_data_ , 32 );
    
    // OK, so now we're a 32-bit output.
    // Our trickery here is to make a fake tdest register
    // When cmdin_tvalid && cmdin_tready, cmd_tdest is !cmdin_tlast.
    // So if it's a 64-bit command (write, including data) the data will get forwarded
    // to the m_cmd_data path.
    //
    reg s_axis_tdest = 1'b0;

    always @(posedge aclk) begin
        if (!aresetn) s_axis_tdest <= 1'b0;
        else if (s_axis_tvalid && s_axis_tready) begin
            if (s_axis_tlast) s_axis_tdest <= 1'b0;
            else s_axis_tdest <= 1'b1;
        end
    end
    
    // We can now also forcibly make sure the "addr" portion is properly mapped to writes:
    // that is, if bit[31] is set, it is NOT a write.
    // We have 4 possible cases:
    // cmd_tdest = 0 cmd_tlast = 0 : this is a write, bit 31 should be 0
    // cmd_tdest = 0 cmd_tlast = 1 : this is a read, bit 31 should be 1
    // cmd_tdest = 1 : bit 31 should be cmdin_tdata[31]
    assign cmdin_wrcheck_tdata[31] = (s_axis_tdest) ? s_axis_tdata[31] : s_axis_tlast;    
    assign cmdin_wrcheck_tdata[30:0]= s_axis_tdata[30:0];
    assign cmdin_wrcheck_tvalid = s_axis_tvalid;
    assign s_axis_tready = cmdin_wrcheck_tready;    
    assign cmdin_wrcheck_tdest = s_axis_tdest;
    // Switch. We need register slices after it, though, to decouple the two streams.
    cmd_switch u_switch( .aclk(aclk),.aresetn(aresetn),
                         `CONNECT_AXI4S_MIN_IF( s_axis_ , cmdin_wrcheck_ ),
                         .s_axis_tdest( cmdin_wrcheck_tdest ),
                         .m_axis_tdata( { rs_cmd_data_tdata,     rs_cmd_addr_tdata } ),
                         .m_axis_tvalid({ rs_cmd_data_tvalid,    rs_cmd_addr_tvalid }),
                         .m_axis_tready({ rs_cmd_data_tready,    rs_cmd_addr_tready }));    
    cmd_register_slice u_addrslice( .aclk(aclk),.aresetn(aresetn),
                                    `CONNECT_AXI4S_MIN_IF( s_axis_ , rs_cmd_addr_ ),
                                    `CONNECT_AXI4S_MIN_IF( m_axis_ , m_cmd_addr_ ));
    cmd_register_slice u_dataslice( .aclk(aclk),.aresetn(aresetn),
                                    `CONNECT_AXI4S_MIN_IF( s_axis_ , rs_cmd_data_ ),
                                    `CONNECT_AXI4S_MIN_IF( m_axis_ , m_cmd_data_ ));
    // Outbound processing is then relatively simple:
    // cyc_i/stb_i = (m_cmd_addr_tvalid && (!m_cmd_addr_tdata[31] || m_cmd_data_tvalid))
    // we_i = m_cmd_addr[31]
    // m_cmd_addr_tready = ack_i
    // This is basically conceptually right, however we handle it in a state machine
    // to ensure that reads have someplace to go. Otherwise we have a deadlock possibility.
    generate
        if (DEBUG == "TRUE") begin : ILA
            aurora_cmdgen_ila u_ila(.clk(aclk),
                                    .probe0(s_axis_tdata),
                                    .probe1(s_axis_tvalid),
                                    .probe2(s_axis_tready),
                                    .probe3(s_axis_tlast),
                                    .probe4(s_axis_tdest),
                                    .probe5(s_axis_tkeep));
        end
    endgenerate

endmodule
