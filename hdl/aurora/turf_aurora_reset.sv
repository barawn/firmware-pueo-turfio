`timescale 1ns / 1ps
// reset module. Not directly copied from exdes since the exdes one is uh wrong
module turf_aurora_reset(
        input reset_i,
        input gt_reset_i,
        input user_clk_i,
        input init_clk_i,
        output system_reset_o,
        output gt_reset_o
    );
    parameter SIM_SPEEDUP = "FALSE";
    
    localparam [47:0] HOTPLUG_DELAY = (SIM_SPEEDUP == "TRUE") ? 48'h10 : 48'h400_0000;
    
    // we rising edge detect the input
    reg reset_rereg = 0;
    
    // OK these are the actual reset outputs. Note that they start HIGH
    // When gt_reset is asserted, user clk disappears, hence the reason it needs
    // to be in the init_clk domain.
        
    // System reset, in init_clk
    (* CUSTOM_CC_SRC = "INITCLK" *)
    reg system_reset_initclk = 1'b1;        
    // System reset, resync in user_clk
    (* ASYNC_REG = "TRUE", CUSTOM_CC_SRC="USERCLK", CUSTOM_CC_DST="USERCLK" *)
    reg [1:0] system_reset = 2'b11;
    // GT reset, sync to init_clk.
    reg gt_reset = 1'b1;
    // enable DSP counting for hotplug
    reg enable_hotplug_delay = 1'b0;
    // system reset, resynchronized back to init_clk
    (* ASYNC_REG = "TRUE", CUSTOM_CC_DST="INITCLK" *)
    reg [2:0] system_reset_resync = {3{1'b1}};    
    // Hotplug delay reached
    wire hotplug_delay_reached;
    // Reset begin delay reached
    wire gt_reset_delay_reached;
                
    localparam FSM_BITS=2;
    localparam [FSM_BITS-1:0] RESET = 0;            // exit either at power-on or after 2^26 clocks
    localparam [FSM_BITS-1:0] RESET_ENDING = 1;
    localparam [FSM_BITS-1:0] IDLE = 2;
    localparam [FSM_BITS-1:0] RESET_STARTING = 3;
    reg [FSM_BITS-1:0] state = RESET;
    
    wire reset_flag = reset_i && !reset_rereg;

    always @(posedge init_clk_i) begin
        reset_rereg <= reset_i;
    
        case (state)
            RESET: if (!enable_hotplug_delay || hotplug_delay_reached) state <= RESET_ENDING;
            // avoid getting stuck in reset_ending
            RESET_ENDING: if (reset_flag) state <= RESET_STARTING;
                          else if (!system_reset_resync[2]) state <= IDLE;
            IDLE: if (reset_flag) state <= RESET_STARTING;
            RESET_STARTING: if (gt_reset_delay_reached) state <= RESET;
        endcase
        if (state == RESET_STARTING && gt_reset_delay_reached) enable_hotplug_delay <= 1'b1;
        else if (state == RESET_ENDING) enable_hotplug_delay <= 1'b0;
        
        if (state == RESET_ENDING && !reset_flag) system_reset_initclk <= 1'b0;
        else if ((state == IDLE || state == RESET_ENDING) && reset_flag) system_reset_initclk <= 1'b1;                

        if (state == RESET && (!enable_hotplug_delay || hotplug_delay_reached)) gt_reset <= 1'b0;
        else if (state == RESET_STARTING && gt_reset_delay_reached) gt_reset <= 1'b1;
        
        system_reset_resync <= {system_reset_resync[1:0], system_reset[1]};
    end
    
    always @(posedge user_clk_i) begin
        system_reset <= {system_reset[0],system_reset_initclk};
    end

    dsp_counter_terminal_count #(.FIXED_TCOUNT("TRUE"),
                                 .FIXED_TCOUNT_VALUE(HOTPLUG_DELAY))
        u_hpdelay(.clk_i(init_clk_i),
                  .rst_i(state != RESET),
                  .count_i(enable_hotplug_delay),
                  .tcount_reached_o(hotplug_delay_reached));

    dsp_counter_terminal_count #(.FIXED_TCOUNT("TRUE"),
                                 .FIXED_TCOUNT_VALUE(128))
        u_rst_dly(.clk_i(init_clk_i),
                  .rst_i(state != RESET_STARTING),
                  .count_i(state == RESET_STARTING),
                  .tcount_reached_o(gt_reset_delay_reached));                                   

    assign system_reset_o = system_reset[1];
    assign gt_reset_o = gt_reset;
endmodule
