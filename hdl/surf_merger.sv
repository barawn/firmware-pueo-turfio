`timescale 1ns / 1ps
`include "interfaces.vh"
module surf_merger(
        input aclk,
        input aresetn,
        
        input [7:0] err_i,
        
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_s0_ , 8 ),
        input s_s0_tlast,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_s1_ , 8 ),
        input s_s1_tlast,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_s2_ , 8 ),
        input s_s2_tlast,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_s3_ , 8 ),
        input s_s3_tlast,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_s4_ , 8 ),
        input s_s4_tlast,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_s5_ , 8 ),
        input s_s5_tlast,
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_s6_ , 8 ),
        input s_s6_tlast,
        
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_ev_ , 32 ),
        output m_ev_tlast
    );
    
    parameter DEBUG = "TRUE";
    
    `DEFINE_AXI4S_MIN_IF( ev64_ , 64 );
    wire ev64_tlast;

    // this is the TURFIO path, maybe do something
    // with this later    
    `DEFINE_AXI4S_MIN_IF( fake_ , 8 );
    wire fake_tlast;
    assign fake_tdata = err_i;
    assign fake_tvalid = 1'b1;
    assign fake_tlast = 1'b0;
    
    `define VEC_CONNECT( port_pfx, port_name )  \
        .``port_pfx``port_name ( {  fake_``port_name ,  \
                                    s_s6_``port_name ,  \
                                    s_s5_``port_name ,  \
                                    s_s4_``port_name ,  \
                                    s_s3_``port_name ,  \
                                    s_s2_``port_name ,  \
                                    s_s1_``port_name ,  \
                                    s_s0_``port_name } )
    // merge with a combiner
    surf_combiner u_combiner( .aclk(aclk),
                              .aresetn(aresetn),
                              `VEC_CONNECT( s_axis_ , tdata ),
                              `VEC_CONNECT( s_axis_ , tvalid ),
                              `VEC_CONNECT( s_axis_ , tready ),
                              `VEC_CONNECT( s_axis_ , tlast ),
                              `CONNECT_AXI4S_MIN_IF( m_axis_ , ev64_ ),
                              .m_axis_tlast( ev64_tlast) );
    // AXI4-Stream is LSB first, which means when we go 64->32
    // we'll get { s3/s2/s1/s0 } / { fake/s6/s5/s4 } which is what we want                              
    // and reduce to 32
    surf_reducer u_reducer( .aclk(aclk),
                            .aresetn(aresetn),
                            `CONNECT_AXI4S_MIN_IF( s_axis_ , ev64_ ),
                            .s_axis_tlast( ev64_tlast ),
                            `CONNECT_AXI4S_MIN_IF( m_axis_ , m_ev_ ),
                            .m_axis_tlast( m_ev_tlast ));
    // and that's it! that should be all we need to do
    generate
        if (DEBUG == "TRUE") begin : DBG
            event_ila u_ila(.clk(aclk),
                            .probe0( m_ev_tdata ),
                            .probe1( m_ev_tvalid ),
                            .probe2( m_ev_tready ),
                            .probe3( m_ev_tlast ));
        end
    endgenerate        
endmodule
