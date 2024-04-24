`timescale 1ns / 1ps
// despite its name this controls the datapath TO THE SURF
// strongly based on turf_cout_interface
module surf_cin_interface(
        input sysclk_i,
        input sysclk_x2_i,
        input oserdes_rst_i,
        input train_i,
        input sync_i,
        input [31:0] command_i,
        
        output CIN_P,
        output CIN_N,
        output RXCLK_P,
        output RXCLK_N
    );
    
    parameter CIN_INV = 1'b0;
    parameter RXCLK_INV = 1'b0;
    
    localparam [31:0] TRAIN_VALUE = 32'hA55A6996;
    
    wire [31:0] value_to_send = (train_i) ? TRAIN_VALUE : command_i;
    
    wire cin_out;
    // didn't have this module when turf_cout was first written, need to update
    obufds_autoinv #(.INV(CIN_INV)) u_cin_obuf(.I(cin_out),.O_P(CIN_P),.O_N(CIN_N));

    wire rxclk_in;
    ODDR #(.DDR_CLK_EDGE("SAME_EDGE"),.INIT(RXCLK_INV),.SRTYPE("SYNC"))
        u_rxclk_oddr(.C(sysclk_i),
                     .CE(1'b1),
                     .D1(~RXCLK_INV),
                     .D2(RXCLK_INV),
                     .R(1'b0),
                     .S(1'b0),
                     .Q(rxclk_in));
    obufds_autoinv #(.INV(RXCLK_INV)) u_rxclk(.I(rxclk_in),.O_P(RXCLK_P),.O_N(RXCLK_N));    

    // don't need a full 16-clock phase
    reg [2:0] command_phase = {3{1'b0}};    
    reg [31:0] command_hold = {32{1'b0}};
    
    always @(posedge sysclk_i) begin
        if (sync_i) command_phase <= 3'h1;
        else command_phase <= command_phase + 1;
        
        if (command_phase == 7) command_hold <= value_to_send;
    end        
    
    // OSERDES. LSB is first out.
    OSERDESE2 #(.DATA_RATE_OQ("DDR"),
                .DATA_WIDTH(4),
                .INIT_OQ(CIN_INV),
                .SRVAL_OQ(CIN_INV))
        u_surfcin_oserdes(.CLK(sysclk_x2_i),
                          .CLKDIV(sysclk_i),
                          .D1(command_hold[0] ^ CIN_INV),
                          .D2(command_hold[1] ^ CIN_INV),
                          .D3(command_hold[2] ^ CIN_INV),
                          .D4(command_hold[3] ^ CIN_INV),
                          .OCE(1'b1),
                          .RST(oserdes_rst_i),
                          .OQ(cin_out));

endmodule
