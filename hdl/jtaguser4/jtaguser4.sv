`timescale 1ns / 1ps
// dumb module to effectively allow the equivalent of a pure output VIO
// with waaay less resources
module jtaguser4 #(parameter DATA_WIDTH=8)(
        input clk_i,
        output [DATA_WIDTH-1:0] dat_o
    );
    
    // this is the shreg
    reg [DATA_WIDTH-1:0] data_shreg = {DATA_WIDTH{1'b0}};
    // this is the actual register
    reg [DATA_WIDTH-1:0] data_register = {DATA_WIDTH{1'b0}};

    // jtag signals    
    wire user4_tck;
    reg [1:0] user4_tck_sync = {2{1'b0}};
    wire user4_tck_flag = user4_tck_sync[0] && !user4_tck_sync[1];
    wire user4_capture;     // capture-dr 
    wire user4_update;      // update-dr : we don't actually user this
    wire user4_sel;         // our instruction is in the IR: qualify everything on this
    wire user4_shift;       // shift-dr
    wire user4_runtest;     // in runtest
    wire user4_tdi;
    wire user4_tms;
    wire user4_tdo = data_shreg[DATA_WIDTH-1];
    // runtest is used to actually load data_shreg -> data_register
    always @(posedge clk_i) begin
        user4_tck_sync <= {user4_tck_sync[0], user4_tck};
        if (user4_tck_flag && user4_sel && user4_runtest) data_register <= data_shreg;
        
        if (user4_tck_flag && user4_sel && user4_capture) data_shreg <= data_register;
        else if (user4_tck_flag && user4_sel && user4_shift) data_shreg <= { data_shreg[DATA_WIDTH-2:0], user4_tdi };        
    end
    
    BSCANE2 #(.JTAG_CHAIN(4))
        u_bscan(.CAPTURE(user4_capture),
                .RUNTEST(user4_runtest),
                .SEL(user4_sel),
                .SHIFT(user4_shift),
                .TCK(user4_tck),
                .TDI(user4_tdi),
                .TMS(user4_tms),
                .UPDATE(user4_update),
                .TDO(user4_tdo));
    
    assign dat_o = data_register;    
endmodule
