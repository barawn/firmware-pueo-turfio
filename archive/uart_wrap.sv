`timescale 1ns / 1ps
`include "interfaces.vh"
module uart_wrap(
        input aclk,
        input aresetn,        
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_axis_ , 8),
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_axis_ , 8),
        
        input RX,
        output TX        
    );
    
    parameter CLOCK_FREQ = 50000000;
    parameter BAUD = 1000000;
    parameter DEBUG = "TRUE";    
    // Generate the accumulator value for the appropriate baud rate.
    // The baud rate generator is created via a free-running accumulator's
    // overflow rate. It's a 10-bit counter and we need to generate
    // 16x the baud rate for the oversample UART. So for instance
    // if we have a baud rate of 1M (16x baud = 16M) and a 50M clock,
    // we need it to trip about once every 3 clock cycles, but
    // specifically every 1024/328 = 3.122 clock cycles. Which gives
    // you 16.01 MHz or a rate error of under 0.1%.
    localparam ACC_BITS = 10;
    localparam real CLOCK_REAL = CLOCK_FREQ;
    localparam real BAUD_REAL_X16 = BAUD*16;
    localparam real BAUD_DIVIDE = CLOCK_REAL/BAUD_REAL_X16;
    localparam real ACC_MAX = (1 << ACC_BITS);
    localparam real ACC_VAL = ACC_MAX/BAUD_DIVIDE;
    // Double it so we can round. e.g. if ACC_VAL = 409.6, ACC_VAL_X2 is 819 (floored)
    // and then BRG_ACCUMULATOR_VALUE is 410.
    localparam ACC_VAL_X2 = ACC_VAL*2;
    localparam [10:0] BRG_ACCUMULATOR_VALUE_X2 = ACC_VAL_X2;
    // Round the above.
    localparam [9:0] BRG_ACCUMULATOR_VALUE = BRG_ACCUMULATOR_VALUE_X2[10:1] + BRG_ACCUMULATOR_VALUE_X2[0];

    // Accumulator. One extra bit (the overflow bit).
    reg [ACC_BITS:0] acc = {(ACC_BITS+1){1'b0}};
    // Accumulator. Top bit is just an overflow bit, it's not preserved in the math.
    always @(posedge aclk) begin
        acc <= acc[ACC_BITS-1:0] + BRG_ACCUMULATOR_VALUE;
    end
    // grab the overflow bit
    wire en_16x_baud = acc[10];
    uart_rx6 u_rx(.clk(aclk),.serial_in(RX),.en_16_x_baud(en_16x_baud),
                  .data_out(m_axis_tdata),
                  .buffer_data_present(m_axis_tvalid),
                  .buffer_read(m_axis_tvalid && m_axis_tready),
                  .buffer_reset(!aresetn));
    wire tx_full;
    assign s_axis_tready = !tx_full;
    uart_tx6 u_tx(.clk(aclk),.en_16_x_baud(en_16x_baud),
                  .buffer_write(s_axis_tready && s_axis_tvalid),
                  .buffer_full(tx_full),
                  .data_in(s_axis_tdata),
                  .serial_out(TX));

    generate
        if (DEBUG == "TRUE") begin : ILA
            uart_ila u_ila(.clk(aclk),
                           .probe0(m_axis_tdata),.probe1(m_axis_tvalid),.probe2(m_axis_tready),.probe3(RX),
                           .probe4(s_axis_tdata),.probe5(s_axis_tvalid),.probe6(s_axis_tready),.probe7(TX));                           
        end
    endgenerate 
    
endmodule
