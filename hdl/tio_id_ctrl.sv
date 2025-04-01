`timescale 1ns / 1ps
`include "interfaces.vh"
// TURFIO ID/control/internal housekeeping.
// Does NOT include the general shift register module,
// which is used for a variety of purposes.
//
// Does include clock monitors.
//
// 0x000: Device ID ("TFIO")
// 0x004: Firmware ID (standard day/month/major/minor/revision packing)
// 0x008: DNA port
// 0x00C: General status/control.
// 0x010: Sync offset register/sync enable.
// 0x014: Clock offset register.
// 0x018: Debug board manager control (burst size/upper address bits).
// 0x01C-0x3F: Reserved
// 0x040: Sys clock monitor (125 MHz)
// 0x044: Local GTP clock monitor (125 MHz)
// 0x048: RX clock monitor (125 MHz)
// 0x04C: HS RX clk monitor (250 MHz)
// 0x050: clk200 monitor (200 MHz)
// 0x054-0x7F: reserved
// 0x080-0xFFF: reserved
module tio_id_ctrl(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF( wb_ , 12, 32),

        // Debug boardman interface burst size when burst bit (bit 22) is set.
        output [1:0] burst_size_o,
        // Debug boardman interface upper addr bits when upper addr bit (bit 21) is set.
        output [3:0] upper_addr_o,

        // Sync sequence offset. When a sync sequence
        // comes in, this is the number of sysclks
        // we wait before resetting the internal
        // sync sequence (and issuing the external clock sync if enabled)
        output [7:0] sync_offset_o,
        // Enable the external sync. This is optional because it will eff the SURF clocks when done.
        // Only needs to be done once.
        output       en_ext_sync_o,
        
        output       hsk_enable_i,
        input        hsk_enable_t,
        input        hsk_enable_o,

        input        hsk_local_i,
        input        hskbus_crate_i,
        input [7:0]  hskbus_rx_bytes_i,
                
        output       enable_crate_o,
        output       enable_3v3_o,
        input [1:0]  crate_conf_i,
        // probably temporary
        input        i2c_rdy_i,
        
        // Clock counter offset. When a sync request
        // comes in, this is what we reset the sysclk
        // counter to.
        output [7:0] clk_offset_o,
        // Clocks for monitoring. We leave space for up to 16.
        input sys_clk_i,        // 125 MHz from LMK (U2)
        input sys_clk_x2_i,
        input gtp_clk_i,        // 125 MHz from MGT clock (LCLK, Y2)
        input rx_clk_i,         // 125 MHz from TURF receive clock
        input rx_clk_x2_i,      // 250 MHz derived from TURF receive clock
        input clk200_i,         // 200 MHz used for IDELAYCTRL
        // Important clock indicators. These are clock domains where
        // the register interface crosses over into them to wait for
        // a response, so you can imagine deadlocking. More of these
        // may get added.
        
        // TURF RX clock        
        output rx_clk_ok_o,
        // System clock
        output sys_clk_ok_o
    );
    
    parameter [31:0] DEVICE = "TFIO";
    parameter [31:0] VERSION = {32{1'b0}};
    parameter WB_CLK_TYPE = "INITCLK";
    localparam [31:0] ICAP_KEY = "FKey";

    // Board manager stuff
    // Upper address bits when upper bit is set. Aligned to match addr (e.g. just write the address).
    reg [3:0] boardman_upper_addr = {4{1'b0}};    
    // Burst size when burst bit is set. Bottom 2 bits so they don't clash with the upper addr since all
    // addrs are 32 bits.
    reg [1:0] boardman_burst_size = {2{1'b0}};
    // Full register.
    // 31 30 29 28 27 26 25 24 23 22 21
    // B1 B0 0  0  0  0  0  U3 U2 U1 U0
    wire [31:0] boardman_debug_ctrl = { boardman_burst_size, {5{1'b0}}, boardman_upper_addr, {21{1'b0}} };
    // Output from the DNA port.
    wire dna_data;
    // Shift the DNA port
    reg dna_shift = 0;
    // Read the DNA port
    reg dna_read = 0;
    
    // Sync offset + enable
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [8:0] sync_offset_plus_en = {9{1'b0}};
    
    // Clock offset.
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [7:0] clock_offset = {8{1'b0}};

    reg enable_crate = 1;
    assign hsk_enable_i = enable_crate;
    
    reg enable_3v3 = 1;

    (* IOB = "TRUE" *)
    reg [1:0] crate_conf = {2{1'b0}};
    // probably temporary
    (* IOB = "TRUE" *)
    reg i2c_rdy = 1'b0;                
    
    // Status/control register
    wire [31:0] ctrlstat_reg;
    assign ctrlstat_reg[0] = sys_clk_ok_o;
    assign ctrlstat_reg[1] = rx_clk_ok_o;
    assign ctrlstat_reg[2] = enable_crate;
    assign ctrlstat_reg[3] = enable_3v3;
    assign ctrlstat_reg[4] = i2c_rdy;  
    assign ctrlstat_reg[5] = hsk_local_i;
    assign ctrlstat_reg[6] = hskbus_crate_i;
    assign ctrlstat_reg[7] = 1'b0;
    assign ctrlstat_reg[9:8] = crate_conf;
    assign ctrlstat_reg[15:10] = {6{1'b0}};
    assign ctrlstat_reg[16 +: 8]= hskbus_rx_bytes_i;
    assign ctrlstat_reg[31:24] = {8{1'b0}};
    
    // Main internal register stuff. We have basically 64 groups of 16 registers.
    wire        sel_internal = (wb_adr_i[6 +: 6] == 0);
    wire [31:0] wishbone_registers[15:0];

        // Convenience stuff. These allow setting up wishbone registers easier.
		// BASE needs to be defined to convert the base address into an index.
		localparam BASEWIDTH = 4;
		function [BASEWIDTH-1:0] BASE;
				input [11:0] bar_value;
				begin
						BASE = bar_value[5:2];
				end
		endfunction
		`define OUTPUT(addr, x, range, dummy)																				\
					assign wishbone_registers[ addr ] range = x
		`define SELECT(addr, x, dummy, dummy1)																			\
					wire x;																											\
					localparam [BASEWIDTH-1:0] addr_``x = addr;															\
					assign x = (sel_internal && wb_cyc_i && wb_stb_i && wb_we_i && wb_ack_o && (BASE(wb_adr_i) == addr_``x))
		`define OUTPUTSELECT(addr, x, y, dummy)																		\
					wire y;																											\
					localparam [BASEWIDTH-1:0] addr_``y = addr;															\
					assign y = (sel_internal && wb_cyc_i && wb_stb_i && wb_ack_o && (BASE(wb_adr_i) == addr_``y));	\
					assign wishbone_registers[ addr ] = x

		`define SIGNALRESET(addr, x, range, resetval)																	\
					always @(posedge wb_clk_i) begin																			\
						if (wb_rst_i) x <= resetval;																				\
						else if (sel_internal && wb_cyc_i && wb_stb_i && wb_we_i && (BASE(wb_adr_i) == addr))		\
							x <= wb_dat_i range;																						\
					end																												\
					assign wishbone_registers[ addr ] range = x
		`define WISHBONE_ADDRESS( addr, name, TYPE, par1, par2 )														\
					`TYPE(BASE(addr), name, par1, par2)
    
    
    `WISHBONE_ADDRESS( 12'h000, DEVICE, OUTPUT, [31:0], 0);
    `WISHBONE_ADDRESS( 12'h004, VERSION, OUTPUT, [31:0], 0);
    `WISHBONE_ADDRESS( 12'h008, { {31{1'b0}}, dna_data }, OUTPUTSELECT, sel_dna, 0);
    `WISHBONE_ADDRESS( 12'h00C, ctrlstat_reg, OUTPUTSELECT, sel_ctrlstat, 0);
    `WISHBONE_ADDRESS( 12'h010, sync_offset_plus_en, SIGNALRESET, [8:0], 9'h00);
    `WISHBONE_ADDRESS( 12'h014, clock_offset, SIGNALRESET, [7:0], 8'h00);
    `WISHBONE_ADDRESS( 12'h018, boardman_debug_ctrl, OUTPUTSELECT, sel_boardman_debug, 0);
    assign wishbone_registers[7] = wishbone_registers[3];
    assign wishbone_registers[8] = wishbone_registers[0];
    assign wishbone_registers[9] = wishbone_registers[1];
    assign wishbone_registers[10] = wishbone_registers[2];
    assign wishbone_registers[11] = wishbone_registers[3];
    assign wishbone_registers[12] = wishbone_registers[0];
    assign wishbone_registers[13] = wishbone_registers[1];
    assign wishbone_registers[14] = wishbone_registers[2];
    assign wishbone_registers[15] = wishbone_registers[3];
    
    wire [31:0] dat_internal = wishbone_registers[wb_adr_i[5:2]];
    reg         ack_internal = 0;
    
    wire ack_clockmon;
    wire [31:0] dat_clockmon;
    
    always @(posedge wb_clk_i) begin
        ack_internal <= (wb_cyc_i && wb_stb_i && sel_internal) && !ack_internal;
        if (sel_dna && ~wb_we_i && wb_ack_o) dna_shift <= 1;
        else dna_shift <= 0;
        if (sel_dna && wb_we_i && wb_ack_o && wb_sel_i[3]) dna_read <= wb_dat_i[31];
        else dna_read <= 0;
        // WISHBONE takes precedence over housekeeping
        if (sel_ctrlstat && wb_we_i && wb_ack_o && wb_sel_i[0]) begin
            enable_crate <= wb_dat_i[2];
        end else if (!hsk_enable_t) begin
            enable_crate <= hsk_enable_o;
        end            
        if (sel_ctrlstat && wb_we_i && wb_ack_o && wb_sel_i[0]) begin                    
            enable_3v3 <= wb_dat_i[3];
        end        

        // the alignment here lets you just write the desired address here unless you're
        // trying to burst or something
        if (sel_boardman_debug && wb_we_i && wb_ack_o) begin
            if (wb_sel_i[0]) boardman_burst_size <= wb_dat_i[1:0];
            // the upper addr spans 2 bytes
            if (wb_sel_i[2]) boardman_upper_addr[2:0] <= wb_dat_i[23:21];
            if (wb_sel_i[3]) boardman_upper_addr[3] <= wb_dat_i[24];
        end
        
        crate_conf <= crate_conf_i;
        i2c_rdy <= i2c_rdy_i;
    end    

    (* CUSTOM_DNA_VER = VERSION *)
    DNA_PORT u_dina(.DIN(1'b0),.READ(dna_read),.SHIFT(dna_shift),.CLK(wb_clk_i),.DOUT(dna_data));

    // Clock running monitors
    wire [4:0] clk_running;
    // We only care about sys_clk (0) and rx_clk (2) right now.
    // We might care about a few others later.
    assign sys_clk_ok_o = clk_running[0];
    assign rx_clk_ok_o = clk_running[2];
    // Peel off the select for the clock monitor. It gets 0x40-0x7F = xxxx_x1xx_xxxx
    // But right now we grab the top 6 bits
    wire sel_clockmon = (wb_cyc_i && wb_stb_i && (wb_adr_i[6 +: 6] == 6'h01));
    // 6 clocks needs 3 bits    
    simple_clock_mon #(.NUM_CLOCKS(6))
        u_clockmon( .clk_i(wb_clk_i),
                    .adr_i(wb_adr_i[2 +: 3]),
                    .en_i(sel_clockmon),
                    .wr_i(wb_we_i),
                    .dat_i(wb_dat_i),
                    .dat_o(dat_clockmon),
                    .ack_o(ack_clockmon),
                    .clk_running_o(clk_running),
                    // From MSB to LSB
                    .clk_mon_i( { sys_clk_x2_i,
                                  clk200_i,
                                  rx_clk_x2_i,
                                  rx_clk_i,
                                  gtp_clk_i,
                                  sys_clk_i } ));
    // fix this decode if we add more
    assign wb_ack_o = (wb_adr_i[6]) ? ack_clockmon : ack_internal;
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
    assign wb_dat_o = (wb_adr_i[6]) ? dat_clockmon : dat_internal;

    assign sync_offset_o = sync_offset_plus_en[7:0];
    assign en_ext_sync_o = sync_offset_plus_en[8];
    assign clk_offset_o = clock_offset;

    assign enable_crate_o = enable_crate;
    assign enable_3v3_o = enable_3v3;

    assign burst_size_o = boardman_burst_size;
    assign upper_addr_o = boardman_upper_addr;

endmodule
