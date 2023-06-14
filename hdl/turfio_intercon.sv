`timescale 1ns / 1ps
`include "interfaces.vh"

// TURFIO interconnect. Right now we only generate 4 slave
// address spaces.
//
// Plan for *four* master interfaces (jeez)
// 0: gigabit transceiver path (gtp)
// 1: cin/cout path (ctl)
// 2: debug serial path (dbg)
// 3: TURF serial path (ser)
//
// Currently implement 4 slaves, with 12 bit address space
// evenly mapped. But those are in parameters.
// 0: tio_id_ctrl
// 1: genshift
// 2: surfturf
// 3: hski2c
module turfio_intercon(
        input clk_i,
        input rst_i,
        // Masters
        `TARGET_NAMED_PORTS_WB_IF( gtp_ , 22, 32 ),
        `TARGET_NAMED_PORTS_WB_IF( ctl_ , 22, 32 ),
        `TARGET_NAMED_PORTS_WB_IF( dbg_ , 22, 32 ),
        `TARGET_NAMED_PORTS_WB_IF( ser_ , 22, 32 ),
        // Slaves
        `HOST_NAMED_PORTS_WB_IF( tio_id_ctrl_ , 12, 32),
        `HOST_NAMED_PORTS_WB_IF( genshift_ , 12, 32),
        `HOST_NAMED_PORTS_WB_IF( surfturf_ , 12, 32),
        `HOST_NAMED_PORTS_WB_IF( hski2c_ , 12, 32)     
    );    

    parameter DEBUG = "TRUE";
        
    // Address space selections work by masking off the
    // bit range that corresponds to each one and comparing
    // the inbound address.
    // So for instance, since we only currently have 4 12-bit addresses
    // we mask off the bottom 12 bits (since those are for the modules to decode)
    // and we mask off the top 8 bits (since those are unused).
    // This effectively means that the modules are shadowed at higher address spaces
    // currently.
    // I use this approach generally for building simple intercons: the one downside
    // that it has is that you *have* to map out the entire space somehow. It doesn't
    // have to be even, it doesn't have to make sense, but it has to be mapped fully.
    localparam [21:0] TIO_ID_CTRL_BASE = 22'h000000;
    localparam [21:0] TIO_ID_CTRL_MASK = 22'h3FCFFF;
    localparam [21:0] GENSHIFT_BASE    = 22'h001000;
    localparam [21:0] GENSHIFT_MASK    = 22'h3FCFFF;
    localparam [21:0] SURFTURF_BASE    = 22'h002000;
    localparam [21:0] SURFTURF_MASK    = 22'h3FCFFF;
    localparam [21:0] HSKI2C_BASE      = 22'h003000;
    localparam [21:0] HSKI2C_MASK      = 22'h3FCFFF;

    // START BOILERPLATE INTERCONNECT
    localparam NUM_MASTERS = 4;
    localparam NUM_SLAVES = 4;    
    localparam ADDR_WIDTH = 22;
    localparam DATA_WIDTH = 32;
	wire [NUM_MASTERS-1:0] requests;
	wire [NUM_MASTERS-1:0] grants;
	wire [NUM_MASTERS-1:0] strobes;
	wire [NUM_MASTERS-1:0] writes;
	wire [NUM_MASTERS-1:0] acks;
	wire [NUM_MASTERS-1:0] errs;
	wire [NUM_MASTERS-1:0] rtys;
	
    wire [ADDR_WIDTH-1:0] addrs[NUM_MASTERS-1:0];
    wire [DATA_WIDTH-1:0] unmuxed_dat_o[NUM_MASTERS-1:0];
    wire [(DATA_WIDTH/8)-1:0] sels[NUM_MASTERS-1:0];

	wire muxed_ack;
	wire muxed_err;
	wire muxed_rty;
	// data TO the masters
	wire [DATA_WIDTH-1:0] muxed_dat_i;

	`define MASTER(x, y) \
		assign requests[ y ] = x``cyc_i; \
		assign strobes[ y ] = x``stb_i;  \
		assign writes[ y ] = x``we_i;	 \
		assign x``ack_o = acks[ y ];	    \
		assign x``err_o = errs[ y ];     \
		assign x``rty_o = rtys[ y ];     \
		assign addrs[ y ] = x``adr_i;    \
		assign unmuxed_dat_o[ y ] = x``dat_i; \
		assign sels[ y ] = x``sel_i;      \
		assign x``dat_o = muxed_dat_i        
    
    wishbone_arbiter #(.NUM_MASTERS(NUM_MASTERS))
        u_arbiter(.rst_i(rst_i),
                  .clk_i(clk_i),
                  .cyc_i(requests),
                  .gnt_o(grants));

    // Create the "common" WISHBONE bus. Just a reduction-or of the masked-off signals.
    wire cyc = |(requests & grants);
    wire stb = |(strobes & grants);
    wire we  = |(writes & grants);
    // And the returned values are just bitwise ands
    assign acks = {NUM_MASTERS{muxed_ack}} & grants;
    assign rtys = {NUM_MASTERS{muxed_rty}} & grants;
    assign errs = {NUM_MASTERS{muxed_err}} & grants;
    
    // Now do the multiplexed addresses, data, and selects.
    // Multiplexed address.
    wire [ADDR_WIDTH-1:0] adr;
    // Multiplexed to-slave data
    wire [DATA_WIDTH-1:0] dat_o;
    // Multiplexed select
    wire [(DATA_WIDTH/8)-1:0] sel;  
    
    // Let's test the tools
    function integer m_mux_encoder;
        input [NUM_MASTERS-1:0] grants;
        begin
            integer i;
            for (i=NUM_MASTERS-1;i>0;i--) begin
                if (grants[i]) return i;
            end
            return 0;
        end
    endfunction

    assign adr = addrs[m_mux_encoder(grants)];
    assign dat_o = unmuxed_dat_o[m_mux_encoder(grants)];
    assign sel = sels[m_mux_encoder(grants)];
    
    wire [NUM_SLAVES-1:0] selected;
    wire [DATA_WIDTH-1:0] unmuxed_dat_i[NUM_SLAVES-1:0];
    wire [NUM_SLAVES-1:0] s_acks;
    wire [NUM_SLAVES-1:0] s_rtys;
    wire [NUM_SLAVES-1:0] s_errs;
    `define SLAVE_MAP( prefix, number, mask, base)          \
        assign selected[number] = ((adr & ~mask) == base);  \
        assign unmuxed_dat_i[number] = prefix``dat_i;       \
        assign s_acks[number] = prefix``ack_i;              \
        assign s_rtys[number] = prefix``rty_i;              \
        assign s_errs[number] = prefix``err_i;              \
        assign prefix``cyc_o = cyc && selected[number];     \
        assign prefix``stb_o = stb && selected[number];     \
        assign prefix``we_o = we;                           \
        assign prefix``adr_o = (adr & mask);                \
        assign prefix``dat_o = dat_o;                       \
        assign prefix``sel_o = sel

    function integer s_mux_encoder;
        input [NUM_SLAVES-1:0] sels;
        begin
            integer i;
            for (i=NUM_SLAVES-1;i>0;i--) begin
                if (sels[i]) return i;
            end
            return 0;
        end
    endfunction

    assign muxed_ack = s_acks[s_mux_encoder(selected)];
    assign muxed_err = s_errs[s_mux_encoder(selected)];
    assign muxed_rty = s_rtys[s_mux_encoder(selected)];
    assign muxed_dat_i = unmuxed_dat_i[s_mux_encoder(selected)];

    // END BOILERPLATE
    
    // Map masters
    `MASTER( gtp_ , 0);
    `MASTER( ctl_ , 1);
    `MASTER( dbg_ , 2);
    `MASTER( ser_ , 3);
    // Map slaves
    `SLAVE_MAP( tio_id_ctrl_ , 0 , TIO_ID_CTRL_MASK, TIO_ID_CTRL_BASE );
    `SLAVE_MAP( genshift_ , 1, GENSHIFT_MASK, GENSHIFT_BASE );
    `SLAVE_MAP( surfturf_ , 2, SURFTURF_MASK, SURFTURF_BASE );
    `SLAVE_MAP( hski2c_ , 3, HSKI2C_MASK, HSKI2C_BASE );
                
    generate
        if (DEBUG == "TRUE") begin
            // Minimal internal WISHBONE bus. Combines bidir data into one.
            reg [DATA_WIDTH-1:0] dbg_data = {32{1'b0}};
            reg [ADDR_WIDTH-1:0] dbg_addr = {22{1'b0}};
            reg [(DATA_WIDTH/8)-1:0] dbg_sel = {(DATA_WIDTH/8){1'b0}};
            reg dbg_cyc = 0;
            reg dbg_stb = 0;
            reg dbg_ack = 0;
            reg dbg_we = 0;
            // I super-don't use err/rty so just combine them
            reg dbg_err_rty = 0;
            reg [NUM_MASTERS-1:0] dbg_gnt = {NUM_MASTERS{1'b0}};
            reg [NUM_SLAVES-1:0] dbg_ssel = {NUM_SLAVES{1'b0}};
            always @(posedge clk_i) begin
                if (we) dbg_data <= dat_o;
                else dbg_data <= muxed_dat_i;
                
                dbg_addr <= adr;
                dbg_cyc <= cyc;
                dbg_stb <= stb;
                dbg_we <= we;
                dbg_sel <= sel;
                dbg_ack <= muxed_ack;
                dbg_err_rty <= muxed_err | muxed_rty;
                dbg_gnt <= grants;
                dbg_ssel <= selected;
            end
            intercon_ila u_ila(.clk(clk_i),
                               .probe0(dbg_data),
                               .probe1(dbg_addr),
                               .probe2(dbg_cyc),
                               .probe3(dbg_stb),
                               .probe4(dbg_we),
                               .probe5(dbg_sel),
                               .probe6(dbg_ack),
                               .probe7(dbg_err_rty),
                               .probe8(dbg_gnt),
                               .probe9(dbg_ssel));
        end
    endgenerate
endmodule
