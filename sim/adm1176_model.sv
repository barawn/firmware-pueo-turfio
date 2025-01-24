`timescale 1ns / 1ps
// dumb model for emulating an adm1176 in simulation
module adm1176_model(
        inout scl,
        inout sda
    );

    parameter [6:0] I2C_ADR = 7'h48;
    parameter NAME = "adm1176";

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
    
    // TURFIO values can be automatically built
    // using the read flag
    wire tfio_rd;                                
    reg [7:0] tfio_in = 8'hZZ;
    wire [7:0] tfio_gpio;
    assign tfio_gpio = tfio_in;
    reg [1:0] tfio_state = 0;
    localparam [11:0] TFIO_MVOLTS = 3300;
    localparam [11:0] TFIO_MAMPS = 100;
    i2c_slave_model #(.NAME(NAME),
                      .DEBUG("TRANSACTION"),
                      .I2C_ADR(I2C_ADR),
                      .BEHAVIOR("CONSTANT"),
                      .TIMING("FALSE"))
        u_turfio(.scl(scl),
                 .sda(sda),
                 .read(tfio_rd),
                 .start(start),
                 .stop(stop),
                 .gpio(tfio_gpio));

    always @(posedge tfio_rd or posedge stop) begin
        if (stop) begin
            tfio_state = 0;
            tfio_in <= 8'hZZ;
        end else if (tfio_rd) begin
            if (tfio_state == 0) tfio_in <= TFIO_MVOLTS[11:4];
            else if (tfio_state == 1) tfio_in <= TFIO_MAMPS[11:4];
            else if (tfio_state == 2) tfio_in <= {TFIO_MVOLTS[3:0],TFIO_MAMPS[3:0]};
            tfio_state = tfio_state + 1;
        end        
    end

     
endmodule
