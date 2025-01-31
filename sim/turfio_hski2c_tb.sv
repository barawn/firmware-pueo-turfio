`timescale 1ns / 1ps
module turfio_hski2c_tb;
    wire clk;
    tb_rclk #(.PERIOD(12.5)) u_clk(.clk(clk));
    
    wire sda;
    pullup(sda);
    wire scl;
    pullup(scl);

    wire sda_i, sda_t;
    wire scl_i, scl_t;    
    IOBUF u_sda(.T(sda_t),.IO(sda),.I(1'b0),.O(sda_i));
    IOBUF u_scl(.T(scl_t),.IO(scl),.I(1'b0),.O(scl_i));

    wire I2C_RDY = 1'b1;

    // this is SURF1
    adm1278_model #(.I2C_ADR(7'h10),.NAME("surf1"))
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
    // ok we need to start automating this stuff
    wire rx_has_data;
    wire [7:0] rx_data;
    uart_rx6 u_rx(.clk(clk),.en_16_x_baud(en_16x_baud),
                      .buffer_read(rx_has_data),
                      .buffer_data_present(rx_has_data),
                      .data_out(rx_data),
                      .serial_in(HSK_TX));
    reg [7:0] packet[255:0];
    reg [7:0] packet_pointer = {8{1'b0}};
    reg [7:0] zero_counter = {8{1'b0}};
    always @(posedge clk) begin
        if (rx_has_data) begin
            $display("received data %x", rx_data);
            if (zero_counter == 0) begin
                // start of packet
                zero_counter <= rx_data;
                packet_pointer <= 0;
            end else if (zero_counter == 1) begin
                // encoded zero hit. if zero, is end of packet
                if (rx_data == 8'h00) begin
                    integer i;
                    $display("got packet:");
                    for (i=0;i<packet_pointer;i=i+1) begin
                        $write("%x", packet[i]);
                        if (i == packet_pointer-1) begin
                            $display("");
                        end else begin
                            $write(" ");
                        end                            
                    end
                    zero_counter <= 0;
                end else begin // otherwise this is a real zero
                    zero_counter <= rx_data;
                    packet[packet_pointer] <= {8{1'b0}};
                    packet_pointer <= packet_pointer + 1;
                end // if rx_data != 0
            end else begin //if zero_counter != 0 and != 1
                packet[packet_pointer] <= rx_data;
                packet_pointer <= packet_pointer + 1;
                zero_counter <= zero_counter - 1;
            end
        end // if rx_has_data
    end // always
    
    reg cyc = 0;
    reg we = 0;
    reg [31:0] dat_i = {32{1'b0}};
    wire [31:0] dat_o;
    wire ack;
    
    hski2c_top #(.SIM_FAST("TRUE")) uut(.wb_clk_i(clk),
                   .wb_rst_i(1'b0),
                   .wb_cyc_i(cyc),
                   .wb_stb_i(cyc),
                   .wb_we_i(we),
                   .wb_sel_i({4{we}}),
                   .wb_dat_i(dat_i),
                   .wb_adr_i({12{1'b0}}),
                   .wb_ack_o(ack),
                   .wb_dat_o(dat_o),
                   .CONF(2'b00),
                   .sda_i(sda_i),
                   .sda_t(sda_t),
                   .scl_i(scl_i),
                   .scl_t(scl_t),
                   .HSK_TX(HSK_TX),
                   .HSK_RX(HSK_RX),
                   .I2C_RDY(I2C_RDY));

    initial begin
        #100;
        @(posedge clk); #1 rst = 0;
        @(posedge clk);
        #1 cyc = 1; dat_i = 32'd1; we = 1;
        while (!ack) @(posedge clk); 
        #1 cyc = 0; we = 0;

        #100;
        @(posedge clk);
        #1 cyc = 1; dat_i = 32'd0; we = 1;
        while (!ack) @(posedge clk);
        #1 cyc = 0; we = 0;
        
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
        #1000000;
        @(posedge clk);
        // eTemps from 00 to 40: 00 40 10 00 00
        // COBS               01 03 40 10 01 01 00
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h03; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h40; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h10; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h00; uart_write = 1; @(posedge clk);
        #1 uart_write = 0; @(posedge clk);
        #1000000;
        @(posedge clk);
        // eIdentify from 00 to 40: same as above just with 12
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h03; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h40; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h12; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h00; uart_write = 1; @(posedge clk);
        #1 uart_write = 0; @(posedge clk);
        #1000000;
        // eCurrents from 00 to 40: same as above just with 13
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h03; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h40; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h13; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h00; uart_write = 1; @(posedge clk);
        #1 uart_write = 0; @(posedge clk);
        #1000000;
    
        // ePMBus from 00 to 40, 0 read bytes, addr 0x20, data 0xD9
        //    00 40 C1 03 00 20 D9 07
        // 01 04 40 C1 03 04 20 D9 07 00
        #1 uart_data = 8'h01; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h04; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h40; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'hC1; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h03; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h04; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h20; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'hD9; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h07; uart_write = 1; @(posedge clk);
        #1 uart_data = 8'h00; uart_write = 1; @(posedge clk);
        #1 uart_write = 0; @(posedge clk);
    end
                   
endmodule
