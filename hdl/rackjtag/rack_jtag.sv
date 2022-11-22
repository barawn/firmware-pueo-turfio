`timescale 1ns / 1ps
// interface to RACK jtag
module rack_jtag(
        input clk,
        input load_i,
        output busy_o,
        input [7:0] dat_i,
        
        input jtag_enable_i,        
        input tck_i,
        input tms_i,
        input tdi_i,
        output tdo_o,
        
        output JTAG_EN,
        output T_JCTRL_B,
        output T_TCK,
        output T_TMS,
        output T_TDI,
        input T_TDO        
    );
    
    parameter DEBUG = "TRUE";
    
    wire delay_done;
    reg ce = 0;
    always @(posedge clk) ce <= ~ce;
    
    
    localparam FSM_BITS=3;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] ENABLE = 1;
    localparam [FSM_BITS-1:0] DELAY = 2;
    localparam [FSM_BITS-1:0] CLK_LOW = 3;
    localparam [FSM_BITS-1:0] CLK_HIGH = 4;
    localparam [FSM_BITS-1:0] FINISH_LOW_0 = 5;
    localparam [FSM_BITS-1:0] FINISH_LOW_1 = 6;
    localparam [FSM_BITS-1:0] END_ENABLE = 7;
    reg [FSM_BITS-1:0] state = IDLE;
    
    reg [2:0] bit_counter = {3{1'b0}};
    
    reg force_jtag_enable = 0;
    
    reg [7:0] shift_reg = {8{1'b0}};

    // long time for the enable to complete
    dsp_counter_terminal_count #(.FIXED_TCOUNT("TRUE"),
                                 .FIXED_TCOUNT_VALUE(1000))
                                    u_delay(.clk_i(clk),
                                            .rst_i(state != DELAY),
                                            .count_i(state == DELAY),
                                            .tcount_reached_o(delay_done));
    (* IOB = "TRUE" *)
    reg tck_reg = 1'b0;
    (* IOB = "TRUE" *)
    reg tdi_reg = 1'b0;
    (* IOB = "TRUE" *)
    reg tms_reg = 1'b0;
    (* IOB = "TRUE" *)
    reg tdo_reg = 1'b0;
    (* IOB = "TRUE" *)
    reg tctrl_reg = 1'b1;
    
    always @(posedge clk) begin
        case (state)
            IDLE: if (load_i) state <= ENABLE;
            ENABLE: state <= DELAY;
            DELAY: if (delay_done) state <= CLK_LOW;
            CLK_LOW: if (ce) state <= CLK_HIGH;
            CLK_HIGH: if (ce) begin
                        if (bit_counter == 3'h7) state <= FINISH_LOW_0;
                        else state <= CLK_LOW;
                      end
            FINISH_LOW_0: if (ce) state <= FINISH_LOW_1;
            FINISH_LOW_1: if (ce) state <= END_ENABLE;
            END_ENABLE: state <= IDLE;
        endcase
        if (state == IDLE) bit_counter <= {3{1'b0}};
        else if (state == CLK_HIGH && ce) bit_counter <= bit_counter + 1;
        
        // shift data in MSB first since it upshifts on the other side
        if (state == IDLE && load_i) shift_reg <= dat_i;
        else if (state == CLK_HIGH && ce) shift_reg <= { shift_reg[6:0], 1'b0 };
        
        if (state == ENABLE) force_jtag_enable <= 1'b1;
        else if (state == END_ENABLE) force_jtag_enable <= 1'b0;        
        
        if (state == DELAY) tctrl_reg <= 1'b0;
        else if (state == FINISH_LOW_0) tctrl_reg <= 1'b1;



        tck_reg <= (force_jtag_enable) ? (state == CLK_HIGH) : tck_i;
        tdi_reg <= (force_jtag_enable) ? shift_reg[7] : tdi_i;
        tms_reg <= (force_jtag_enable) ? 1'b1 : tms_i;
        tdo_reg <= T_TDO;
        
        
    end
    
    generate
        if (DEBUG == "TRUE") begin : ILA
            (* KEEP = "TRUE" *)
            reg tck_mon = 1'b0;
            (* KEEP = "TRUE" *)
            reg tdi_mon = 1'b0;
            (* KEEP = "TRUE" *)
            reg tctrl_mon = 1'b1;
                
            always @(posedge clk) begin : MON
                tck_mon <= (state == CLK_HIGH);                
                tdi_mon <= shift_reg[7];
                if (state == DELAY) tctrl_mon <= 1'b0;
                else if (state == FINISH_LOW_0) tctrl_mon <= 1'b1;                
            end
            rack_jtag_ila u_ila(.clk(clk),.probe0(state),.probe1(load_i),.probe2(dat_i),.probe3(tck_mon),.probe4(tdi_mon),.probe5(tctrl_mon));
         end
    endgenerate 
                  
    
    assign T_TCK = tck_reg;
    assign T_TMS = tms_reg;
    assign T_TDI = tdi_reg;
    assign T_JCTRL_B = tctrl_reg;
    assign JTAG_EN = force_jtag_enable || jtag_enable_i;
    assign tdo_o = (force_jtag_enable) ? 1'b0 : tdo_reg;
    
    assign busy_o = (state != IDLE);        
endmodule
