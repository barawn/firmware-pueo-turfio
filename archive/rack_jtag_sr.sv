`timescale 1ns / 1ps
// This is a generic module to implement a clocked shift register. It has some details that
// make it useful specifically for JTAG (two separate clocked outputs).
//
// It takes a grand total of 2 registers: the first is a control and handles both
// tristates and general-purpose I/O control (for stuff like LE pins). The second
// is the data register which handles the shifting and such.
//
// This handles up to 8 gpios/modules. The first control register uses
// 24 bits to handle the GPIOs (oe/input/output) and the low 8 bits handle
// module control (tristate).
//
// There are 8 parameters to configure each module. Right now it's just 4 bits each:
// create aux (TMS), create clock IOB (TCK), create input IOB (TDI), create output IOB (TDO).
// You specify number of modules, and then the configuration of each module separately.
`include "interfaces.vh"
`include "turfio_debug.vh"
module rack_jtag_sr #( parameter NMOD = 2,
                       parameter NGPIO = 1,
                       parameter CLK_DIVIDE = 1,
                       parameter DEBUG = "FALSE",
                       parameter [3:0] MOD0_CFG = 4'b1111,
                       parameter [3:0] MOD1_CFG = 4'b0101,
                       parameter [3:0] MOD2_CFG = 4'b0000,
                       parameter [3:0] MOD3_CFG = 4'b0000,
                       parameter [3:0] MOD4_CFG = 4'b0000,
                       parameter [3:0] MOD5_CFG = 4'b0000,
                       parameter [3:0] MOD6_CFG = 4'b0000,
                       parameter [3:0] MOD7_CFG = 4'b0000 )
    (
        input wb_clk,
        input wb_rst,
        
        `TARGET_NAMED_PORTS_WB_IF( wb_ , 1, 32 ),
        
        // clock outputs
        output [NMOD-1:0] SR_CLK,
        // data outputs (this is TDI for JTAG)
        output [NMOD-1:0] SR_DO,
        // auxiliary data output (this is TMS for JTAG)
        output [NMOD-1:0] SR_AUX_DO,
        // data inputs (this is TDO for JTAG)
        output [NMOD-1:0] SR_DI,
        
        // general purpose input/outputs
        output [NGPIO-1:0] SR_GPIO
    );
    
    localparam MOD_BITS = (NMOD > 1) ? $clog2(NMOD) : 1;
    reg [MOD_BITS-1:0] mod_select = {MOD_BITS{1'b0}};
    reg mod_enable = 1'b0;
    
    reg enable_sequence = 1'b0;
    reg sequence_running = 1'b0;
    reg reverse_bitorder = 1'b0;
    
    reg [7:0] sr_data_out = {8{1'b0}};
    reg [7:0] sr_aux_data_out = {8{1'b0}};
    reg [7:0] sr_data_in = {8{1'b0}};
    
    reg [2:0] nbit_count = {3{1'b0}};
    reg [2:0] nbit_count_max = {3{1'b0}};
    
    reg [5:0] sr_clk_count = {6{1'b0}};
    
    // The modules only grab the output of the shift register (or the input of the muxed data input)
    // So the logic is common to all of them.

    // Clock enable. Divided down by the fixed divider.
    wire ce;    
    
    // Write selection
    wire select = wb_cyc_i && wb_stb_i;
    
    // The SR clock count goes through 4 phases:
    // phase 0: lower SCLK
    // phase 1: update the data and aux data register output
    // phase 2: raise SCLK
    // phase 3: capture data input
    
    // This is the global stuff
    always @(posedge wb_clk) begin
        if (ce && sequence_running) sr_clk_count <= sr_clk_count[1:0] + 1;
        else if (!sequence_running) sr_clk_count <= {3{1'b0}};
        
        if (ce && sequence_running && sr_clk_count[2]) nbit_count <= nbit_count + 1;
        else if (!sequence_running) nbit_count <= {3{1'b0}};
        
        // Terminating sequence always takes priority
        // Otherwise we run the sequence whenever we get a write which enables it(wb_sel_i[3] && wb_dat_i[30])
        // OR a write NOT to that byte which ALREADY enabled the sequence (!wb_sel_i[3] && enable_sequence).
        // This allows fast streaming writes if the same action occurs multiple times:
        // you do a full 32-bit write to set things up (runs sequence once) and then you do a partial
        // write to update just the data.
        if (ce && nbit_count == nbit_count_max && sr_clk_count[2]) 
            sequence_running <= 1'b0;
        else if (select && wb_we_i && ((!wb_sel_i[3] && enable_sequence) || wb_sel_i[3] && wb_dat_i[30]))
            sequence_running <= 1'b1;
    end     
        
    
endmodule
