`timescale 1ns / 1ps
module turfio_hski2c_tb;
    wire clk;
    tb_rclk #(.PERIOD(12.5)) u_clk(.clk(clk));
    
    wire sda;
    pullup(sda);
    wire scl;
    pullup(scl);
    wire I2C_RDY = 1'b1;

    // this is SURF4
    adm1278_model #(.I2C_ADR(7'h40),.NAME("surf4"))
        u_surf4(.scl(scl),.sda(sda));    
    adm1176_model #(.I2C_ADR(7'h48),.NAME("turfio")) 
        u_turfio(.scl(scl),.sda(sda));
        

    reg [7:0] uart_data = {8{1'b0}};
    reg       uart_write = 0;
    wire      HSK_TX;
    wire      HSK_RX;
    parameter CLOCK_RATE = 80000000;
    parameter BAUD_RATE = 500000;    

    /// BAUD RATE GENERATION   
    localparam ACC_BITS = 10;
    localparam real CLOCK_REAL = CLOCK_RATE;
    localparam real BAUD_REAL_X16 = BAUD_RATE*16;
    localparam real BAUD_DIVIDE = CLOCK_REAL/BAUD_REAL_X16;
    localparam real ACC_MAX = (1 << ACC_BITS);
    localparam real ACC_VAL = ACC_MAX/BAUD_DIVIDE;
    localparam ACC_VAL_X2 = ACC_VAL*2;
    // get a fixed bit value here
    localparam [10:0] BRG_ACCUMULATOR_VALUE_X2 = ACC_VAL_X2;
    // this rounds the above. For 1 MBaud this should be 164.
    localparam [9:0] BRG_ACCUMULATOR_VALUE = BRG_ACCUMULATOR_VALUE_X2[10:1] + BRG_ACCUMULATOR_VALUE_X2[0];
    reg [10:0] acc = {11{1'b0}};
    always @(posedge clk) begin
        acc <= acc[9:0] + BRG_ACCUMULATOR_VALUE;
    end
    wire en_16x_baud = acc[10];

    reg rst = 1;
    wire tx_data_present;
    uart_tx6 u_uart(.clk(clk),.en_16_x_baud(en_16x_baud),
                    .buffer_write(uart_write),
                    .buffer_reset(rst),
                    .buffer_full(),
                    .buffer_data_present(tx_data_present),
                    .data_in(uart_data),
                    .serial_out(HSK_RX));
    
    hski2c_top #(.SIM_FAST("TRUE")) uut(.wb_clk_i(clk),
                   .wb_rst_i(rst),
                   .wb_cyc_i(1'b0),
                   .wb_stb_i(1'b0),
                   .wb_we_i(1'b0),
                   .wb_sel_i({4{1'b0}}),
                   .wb_dat_i({32{1'b0}}),
                   .wb_adr_i({12{1'b0}}),
                   .CONF(2'b00),
                   .F_SDA(sda),
                   .F_SCL(scl),
                   .HSK_TX(HSK_TX),
                   .HSK_RX(HSK_RX),
                   .I2C_RDY(I2C_RDY));

    initial begin
        #100;
        @(posedge clk); #1 rst <= 0;

        // we need to wait STUPID LONG because pre initialization it will just throw away
        // our data, bastards
        #1000000;
        @(posedge clk);
        // ePingPong from 00 to 40: 00 40 00 00 00
        // COBS:                 01 02 40 01 01 01 00
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h02; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h40; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h00; uart_write = 1; @(posedge clk);
        #1 uart_write = 0; @(posedge clk);
        
        // now we need to move to about 1.65 ms to ensure the
        // first update has happened (n.b. the timing is slower
        // in real hardware currently)
        #650000;
        @(posedge clk);
        // eVolts from 00 to 40: 00 40 11 00 00
        // COBS:              01 03 40 11 01 01 00
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h03; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h40; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h11; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h00; uart_write = 1; @(posedge clk);
        #1 uart_write = 0; @(posedge clk);
        
    end
                   
endmodule
