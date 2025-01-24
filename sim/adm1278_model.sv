`timescale 1ns / 1ps
// dumb model for adm1278
module adm1278_model(
        inout sda,
        inout scl
    );
    
    parameter NAME = "adm1278";
    parameter [6:0] I2C_ADR = 7'h40;
    // hackity hackity
    // makes nice in waveform viewer
    reg [31:0] i2c_txn_cnt = 0;
    reg [31:0] i2c_state = {32{1'bZ}};
    wire start;
    wire stop;
    always @(posedge start or posedge stop) begin
        if (stop) begin
            i2c_state <= {32{1'bZ}};
            i2c_txn_cnt <= i2c_txn_cnt + 1;
        end else if (start) begin
            i2c_state <= i2c_txn_cnt;
        end        
    end

    wire dev_rd;
    reg [7:0] dev_mode = 8'h00;
    reg [7:0] dev_in = 8'hZZ;
    wire [7:0] dev_gpio;
    assign dev_gpio = dev_in;
    
    reg dev_msb = 0;
    
    // voltage conversions are V = (raw+0.5)*5.104
    // so 12000 = 2351.    
    parameter [11:0] VIN = 2351;
    parameter [11:0] VOUT = 2340;
    // current conv for us is i = (raw - 2048)*(12.51e-6)/(4.762*0.001)
    // so 1 = 2429
    parameter [11:0] IOUT = 2429;
    // temp conv is t = (raw * 10 - 31880)/42
    // so 25 = 3293
    parameter [11:0] TEMP = 3293;

    always @(posedge dev_rd or posedge stop) begin
        if (stop) begin
            dev_in = 8'hZZ;
            #1;
            dev_mode = dev_gpio;
            dev_msb = 0;
        end else if (dev_rd) begin
            if (dev_mode == 8'h88) begin
                if (dev_msb) dev_in = {4'h0,VIN[11:8]};
                else dev_in = VIN[7:0];
            end else if (dev_mode == 8'h8B) begin
                if (dev_msb) dev_in = {4'h0,VOUT[11:8]};
                else dev_in = VOUT[7:0];
            end else if (dev_mode == 8'h8C) begin
                if (dev_msb) dev_in = {4'h0,IOUT[11:8]};
                else dev_in = IOUT[7:0];
            end else if (dev_mode == 8'h8D) begin
                if (dev_msb) dev_in = {4'h0,TEMP[11:8]};
                else dev_in = TEMP[7:0];
            end
            dev_msb = 1;
        end
    end

    i2c_slave_model #(.NAME(NAME),
                      .DEBUG("TRANSACTION"),
                      .I2C_ADR(I2C_ADR),
                      .BEHAVIOR("CONSTANT"),
                      .TIMING("FALSE"))
        u_model(.scl(scl),.sda(sda),
                .start(start),.stop(stop),
                .read(dev_rd),
                .gpio(dev_gpio));                      
endmodule
