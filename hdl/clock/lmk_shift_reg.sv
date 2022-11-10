`timescale 1ns / 1ps
module lmk_shift_reg(
        input clk,
        input rst,
        input load,
        input [31:0] din,
        output busy,
        
        output lmkdata_mon,
        output lmkclk_mon,
        output lmkle_mon,
        
        output LMKDATA,
        output LMKCLK,
        output LMKLE
    );
    
    // At reset, we automatically load this into the LMK so that it restores our input
    // clock in case software blows some crap up or something.
    parameter [31:0] RESET_DEFAULT = 32'h80000000;
    
    // nominally run off initclk, which is 40 MHz.
    // just divide it by 2 for fun
    reg ce = 0;
    always @(posedge clk) ce <= ~ce;
    
    reg [31:0] din_reg = RESET_DEFAULT;
    reg [4:0] bit_count = {5{1'b0}};
    
    (* IOB = "TRUE" *)
    reg lmk_clk = 0;
    (* KEEP = "TRUE" *)
    reg lmk_clk_dbg = 0;
    
    (* IOB = "TRUE" *)
    reg lmk_data = 0;
    (* KEEP = "TRUE" *)
    reg lmk_data_dbg = 0;
    
    (* IOB = "TRUE" *)
    reg lmk_le = 0;
    (* KEEP = "TRUE" *)
    reg lmk_le_dbg = 0;
        
    localparam FSM_BITS = 3;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] CLK_LOW = 1;
    localparam [FSM_BITS-1:0] CLK_HIGH = 2;
    localparam [FSM_BITS-1:0] LATCH_LOW = 3;
    localparam [FSM_BITS-1:0] LATCH_HIGH = 4;
    localparam [FSM_BITS-1:0] RESET = 5;
    reg [FSM_BITS-1:0] state = IDLE;
    
    always @(posedge clk) begin
        if (rst) state <= RESET;
        else begin 
            case (state)
                IDLE: if (load) state <= CLK_LOW;
                CLK_LOW: if (ce) state <= CLK_HIGH;
                CLK_HIGH: if (ce) begin
                    if (bit_count == 31) state <= LATCH_LOW;
                    else state <= CLK_LOW;
                end
                LATCH_LOW: if (ce) state <= LATCH_HIGH;
                LATCH_HIGH: if (ce) state <= IDLE;
                RESET: state <= CLK_LOW;
            endcase
        end
        
        if (state == IDLE || state == RESET) bit_count <= {5{1'b0}};
        else if (state == CLK_HIGH && ce) bit_count <= bit_count + 1;
        
        if (rst) din_reg <= RESET_DEFAULT;
        else if (state == IDLE && load) din_reg <= din;
        else if (state == CLK_HIGH && ce) din_reg <= { din_reg[30:0], 1'b0 };        
        
        lmk_data <= din_reg[31];
        lmk_data_dbg <= din_reg[31];
        lmk_clk <= (state == CLK_HIGH);
        lmk_clk_dbg <= (state == CLK_HIGH);        
        lmk_le <= (state == LATCH_HIGH);   
        lmk_le_dbg <= (state == LATCH_HIGH);     
    end
    
    assign busy = (state != IDLE);

    assign lmkdata_mon = lmk_data_dbg;
    assign lmkclk_mon = lmk_clk_dbg;
    assign lmkle_mon = lmk_le_dbg;
    
    assign LMKDATA = lmk_data;
    assign LMKCLK = lmk_clk;
    assign LMKLE = lmk_le;
    
endmodule
