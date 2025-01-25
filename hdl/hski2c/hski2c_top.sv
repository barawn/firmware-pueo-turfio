`timescale 1ns / 1ps
`include "interfaces.vh"
`include "turfio_debug.vh"
// this module handles I2C as well as housekeeping messages
// FOR MAXIMUM FUN
module hski2c_top(
        input wb_clk_i,
        input wb_rst_i,
        // I DON'T KNOW IF I'LL ADD ANYTHING ELSE HERE
        // WHO KNOWS
        `TARGET_NAMED_PORTS_WB_IF( wb_ , 12, 32),
        // this isn't really a tristate.
        // it allows either housekeeping or wishbone
        // to control and read the enable lines
        output hsk_enable_t,
        output hsk_enable_o,
        input hsk_enable_i,
        
        input [1:0] CONF,
        input HSK_RX,
        output HSK_TX,

        input sda_i,
        output sda_t,
        input scl_i,
        output scl_t,
        
        input I2C_RDY        
    );
    parameter SIM_FAST = "FALSE";
    parameter DEBUG = `HSKI2C_DEBUG;

    reg hsk_reset = 1;
    // pop the rx through a UART. we can just use the boardman one
    `DEFINE_AXI4S_MIN_IF( uart_rx_, 8);
    `DEFINE_AXI4S_MIN_IF( cobs_rx_, 8);
    wire cobs_rx_tuser;
    wire cobs_rx_tlast;
    `DEFINE_AXI4S_MIN_IF( uart_tx_, 8);
    `DEFINE_AXI4S_MIN_IF( cobs_tx_, 8);
    wire cobs_tx_tlast;
    boardman_v2_uart #(.BAUD_RATE(500000),.CLOCK_RATE(80000000))
        u_uart(.clk(wb_clk_i),
               .rst(hsk_reset),
               .RX(HSK_RX),
               .TX(HSK_TX),
               `CONNECT_AXI4S_MIN_IF( s_axis_ , uart_tx_ ),
               `CONNECT_AXI4S_MIN_IF( m_axis_ , uart_rx_ ));
    // decode the input
    axis_cobs_decode u_decode(.clk(wb_clk_i),.rst(hsk_reset),
                               `CONNECT_AXI4S_MIN_IF(s_axis_ , uart_rx_ ),
                               .s_axis_tuser(1'b0),
                               .s_axis_tlast(uart_rx_tdata == 8'h00),
                               `CONNECT_AXI4S_MIN_IF(m_axis_ , cobs_rx_ ),
                               .m_axis_tuser(cobs_rx_tuser),
                               .m_axis_tlast(cobs_rx_tlast));
    // we do NOT use the hardware encoder, because it takes a fair amount of lookahead
    // and the PicoBlaze can do it internally easier.

    // we need to add a 64-byte distram FIFO though because the housekeeping packets get long
    // and annoyingly when we don't have zeros we output at around 1 byte/16 clocks which
    // is waay faster than the UART (1 byte / 1600 clocks ).
    // because we're request/response though I'm not worried about overflowing things at the
    // moment. think about that later.
    wire cobs_tx_full;                                   
    assign cobs_tx_tready = !cobs_tx_full;
    uart_distfifo u_distfifo(.clk(wb_clk_i),.srst(hsk_reset),
                             .din(cobs_tx_tdata),
                             .full(cobs_tx_full),
                             .wr_en(cobs_tx_tvalid && cobs_tx_tready),
                             .dout(uart_tx_tdata),
                             .valid(uart_tx_tvalid),
                             .rd_en(uart_tx_tready && uart_tx_tvalid));

    // XADC path
    // need to store the top bits
    reg [3:0] temp_high = {4{1'b0}};
    wire [11:0] temp_bus;
    wire temp_read;                             
    xadc_temp u_temp(.m_axis_aclk(wb_clk_i),.s_axis_aclk(wb_clk_i),
                     .m_axis_resetn(!hsk_reset),
                     .m_axis_tready(1'b1),
                     .temp_out(temp_bus));
                                                  
    // The I2C access core is controlled fundamentally by a softcore PicoBlaze
    // to allow it to handle monitoring easily. We can't easily do the reprogram/debugging
    // stuff via WISHBONE since we don't have enough ports.
    // although I guess we could do ULTRA-MEGA INSANITY and dork through the ICAP
    // probably the easiest way to do that is just have a register which holds the PicoBlaze
    // in reset. Useful anyway.
    //
    // WE'LL SEE
    
    wire [11:0] address;
    wire [17:0] instruction;
    wire bram_enable;
    wire [7:0] in_port;
    wire [7:0] out_port;
    wire [7:0] port_id;
    wire write_strobe;
    wire k_write_strobe;
    wire read_strobe;
    wire interrupt;
    wire interrupt_ack;
    wire sleep = 0;
    wire reset;
    // The 'stock' kcpsm6 does not expose the bank, but it's a trivial expose.
    // it's super-handy so we don't need to do weirdo things.
    wire picoblaze_bank;

    // This allows doublemapping port_id for kports.
    // We want to preserve the BRAM buffer double-map for the low 8 guys
    // which is why we move !port_id[3] up top. (not really sure if this makes
    // sense but WE'LL SEE)    
    wire [7:0] kport_id = (k_write_strobe) ? {!port_id[3], 3'b000, port_id[3:0] } : port_id;
        
    // bram handling. Bit 6 in the BRAM address comes from our tracked values
    // when we're accessing the packet buffer.
    reg bankA_bram_addr = 0;
    reg bankB_bram_addr = 0;
    // this switches to the housekeeping buffer. The way this works is that
    // _writes_ go to hsk_bram_addr and _reads_ go to ~hsk_bram_addr.
    // the way this is implemented is that by default it's ~hsk_bram_addr and
    // write_strobe overwrites it
    reg hsk_bram_addr = 0;
    // bram_bit6 is
    // port_id[6]   picoblaze_bank  write_strobe    |   bram_bit6
    // 0            0               X               |   bankA_bram_addr
    // 0            1               X               |   bankB_bram_addr
    // 1            X               0               |   ~hsk_bram_addr
    // 1            X               1               |   hsk_bram_addr
    wire packet_bit6 = (picoblaze_bank) ? bankB_bram_addr : bankA_bram_addr;
    wire hsk_bit6 = write_strobe ^ (~hsk_bram_addr);
    wire bram_bit6 = (kport_id[6]) ? hsk_bit6 : packet_bit6;
     
    reg sda_tristate = 1;
    reg scl_tristate = 1;    
    wire sda_in = sda_i;
    wire scl_in = scl_i;    
    assign sda_t = sda_tristate;
    assign scl_t = scl_tristate;

    // this DOES NOT MATCH HELIX's TOF I2C because this version is FASTER
    // using carry hacks.
    localparam [2:0] SDA_BIT = 0;
    localparam [2:0] SCL_BIT = 1;
    localparam [7:0] SCL_PORT = 8'h0D; // 1101
    localparam [7:0] SDA_PORT = 8'h0E; // 1110
    wire [7:0] i2c_inport;
    assign i2c_inport[7:2] = {6{1'b0}};
    assign i2c_inport[SCL_BIT] = scl_in;
    assign i2c_inport[SDA_BIT] = sda_in;
    
    // holds PicoBlaze in reset
    reg processor_reset = 0;
    reg ack = 0;

    localparam [7:0] UART_PORT =    8'h08; // matches 8 and 9 on write or 8 and A on read
    localparam [7:0] CTLSTAT_PORT = 8'h0B; // matches A and B on write or 9 and B on read
    reg cobs_error = 0;
    reg cobs_last = 0;

    // ok, so here's how our port mapping works.
    // 0x00 - 0x07 : reserved to make kport mapping easier
    // 0x08 - 0x0B : uart stuff
    // 0x0C - 0x0F : i2c stuff
    // 0x10        : our ID
    // 0x11        : general control
    // 0x80 - 0xFF : BRAM buffer
    // this means we only need to decode [7] [4:0] so 6 and 5 are
    // overall we make this a 16-entry register file and tack on our ID and the buffer data
    
    // pointless.
    localparam [7:0] PB_MASK =          8'b10011111;    // base mask, for exact match
    localparam [7:0] PB_MASK_BUFFER =   8'b10000000;    // used to detect buffer accesses
    localparam [7:0] PB_MASK_OURID  =   8'b10010001;    // used to detect our ID match
    localparam [7:0] PB_MASK_SCL    =   8'b10011101;    // matches 0x0D and 0x0F - for SCL access
    localparam [7:0] PB_MASK_SDA    =   8'b10011110;    // matches 0x0E and 0x0F - for SDA access
    localparam [7:0] PB_MASK_UARTTX =   8'b10011110;    // matches 0x08 and 0x09 - for UART writes
    localparam [7:0] PB_MASK_UARTRX =   8'b10011101;    // matches 0x0A and 0x08 - for UART reads    
    localparam [7:0] PB_MASK_TEMP   =   8'b10011111;    // matches 0xE only
    wire [7:0] bram_data;
    // packet buffer: 780-7FF
    // hsk buffer:    7C0-7FF
    // both split in two based on control registers
    wire [10:0] bram_addr = { 3'h7, kport_id[6], bram_bit6, kport_id[5:0] };
    // this is 64 + CONF<<2
    // 0100_0000 CONF = 00
    // 0100_1000 CONF = 01
    // 0101_0000 CONF = 10
    // 0101_1000 CONF = 11
    localparam [7:0] GENERAL_CONTROL_PORT = 8'h11;
    
    wire [7:0] general_control;
    assign general_control = { hsk_enable_i, {6{1'b0}}, hsk_bram_addr };
    wire [7:0] our_id = {3'b010, CONF, 3'b000 };
    wire [7:0] general_control_and_ourid = (port_id[0]) ? general_control : our_id;

    wire [7:0] cobs_in = cobs_rx_tdata;
    wire [7:0] cobs_status = { {6{1'b0}}, cobs_last, cobs_error };
    assign     interrupt = cobs_rx_tvalid;    
    
    wire [7:0] picoblaze_registers[15:0];
    wire [7:0] register_data = (port_id[4]) ? general_control_and_ourid : picoblaze_registers[port_id[3:0]];
    assign in_port = (port_id[7]) ? bram_data : register_data;
    
    assign picoblaze_registers[0] = bram_data;
    assign picoblaze_registers[1] = bram_data;
    assign picoblaze_registers[2] = bram_data;
    assign picoblaze_registers[3] = bram_data;
    assign picoblaze_registers[4] = bram_data;
    assign picoblaze_registers[5] = bram_data;
    assign picoblaze_registers[6] = bram_data;
    assign picoblaze_registers[7] = bram_data;
    assign picoblaze_registers[8] = cobs_in;
    assign picoblaze_registers[9] = cobs_status;
    assign picoblaze_registers[10] = cobs_in;
    assign picoblaze_registers[11] = cobs_status;
    assign picoblaze_registers[12] = i2c_inport;
    assign picoblaze_registers[13] = i2c_inport;
    // i2c ONLY EVER READS from 12, so we can abuse this for the temperature stuff
    assign picoblaze_registers[14] = temp_bus[7:0];
    assign picoblaze_registers[15] = { {4{1'b0}}, temp_high };        

    // 0x0E is the low byte temperature port, it captures the read bits for the top 4
    localparam [7:0] TEMPERATURE_PORT = 8'h0E;
    assign temp_read = (read_strobe && ((port_id & PB_MASK_TEMP) == TEMPERATURE_PORT));
    wire bram_write = (write_strobe || k_write_strobe) && kport_id[7];
    wire cobs_read = (read_strobe && ((port_id & PB_MASK_UARTRX) == (UART_PORT & PB_MASK_UARTRX)));
    wire cobs_write = (write_strobe || k_write_strobe) && 
                      ((kport_id & PB_MASK_UARTTX) == (UART_PORT & PB_MASK_UARTTX));
    
    assign cobs_rx_tready = cobs_read;
    // I _really_ need to watch this during a sim to see if it's ok
    assign cobs_tx_tvalid = cobs_write;
    assign cobs_tx_tdata = out_port;
    assign cobs_tx_tlast = port_id[0];
    
    wire gc_write = ((port_id & PB_MASK_OURID) == GENERAL_CONTROL_PORT) && write_strobe;
    assign hsk_enable_t = !gc_write;
    assign hsk_enable_o = out_port[7];
        
    always @(posedge wb_clk_i) begin
        // temperature
        if (temp_read) temp_high <= temp_bus[11:8]; 
        // cobsy cobsy
        if (cobs_rx_tready && cobs_rx_tvalid) begin
            cobs_last <= cobs_rx_tlast;
            cobs_error <= cobs_rx_tuser;
        end
        
        // general control stuff
        if (gc_write) begin
            hsk_bram_addr <= out_port[0];
        end
        
        // OK OK MAKE THIS A REGISTER NOW
        if (wb_cyc_i && wb_stb_i && wb_we_i && ack && wb_sel_i[0])
            processor_reset <= wb_dat_i[0];

        ack <= wb_cyc_i && wb_stb_i;
        
        // I2C init does this too, but this forces them into tristate if we hold things in reset
        if (processor_reset) begin
            sda_tristate <= 1;
            scl_tristate <= 1;
        end else if (write_strobe || k_write_strobe) begin
            if ((kport_id & PB_MASK_SCL) == SCL_PORT) scl_tristate <= out_port[SCL_BIT];
            if ((kport_id & PB_MASK_SDA) == SDA_PORT) sda_tristate <= out_port[SDA_BIT];
        end
        if (write_strobe || k_write_strobe) begin
            if ((kport_id & PB_MASK_UARTTX) == (CTLSTAT_PORT & PB_MASK_UARTTX)) begin
                hsk_reset <= out_port[7];
                // we grab bit 2 because they use the FIFO_COMPLETE bitmasks and they're 0x01/0x02
                if (!picoblaze_bank) bankA_bram_addr <= out_port[1];
                if (picoblaze_bank) bankB_bram_addr <= out_port[1];
            end
        end        
    end
    // this is the I2C upper byte timer
    localparam [7:0] HWBUILD = (SIM_FAST == "TRUE") ? 8'h00 : 8'h03;
    // default
    localparam [7:0] SP_INIT_DF = {8{1'b0}};
    localparam [7:0] SP_INIT_34 = 8'h88;
    localparam [7:0] SP_INIT_35 = 8'h8B;
    localparam [7:0] SP_INIT_36 = 8'h8C;
    localparam [7:0] SP_INIT_37 = 8'h8D;
    localparam [7:0] SP_INIT_38 = {7'h10,1'b0};    // SURF1
    localparam [7:0] SP_INIT_39 = {7'h11,1'b0};    // SURF2
    localparam [7:0] SP_INIT_3A = {7'h12,1'b0};    // SURF3
    localparam [7:0] SP_INIT_3B = {7'h40,1'b0};    // SURF4
    localparam [7:0] SP_INIT_3C = {7'h41,1'b0};    // SURF5
    localparam [7:0] SP_INIT_3D = {7'h42,1'b0};    // SURF6
    localparam [7:0] SP_INIT_3E = {7'h46,1'b0};    // SURF7    
    localparam [7:0] SP_INIT_3F = {7'h48,1'b0};    // TURFIO
    // this was made big enough for the largest scratchpad
    // we only use 64 so there are 192*8 blanks
    // Note that we only currently initialize the top 8
    // but for clarity we spell out everything.
    localparam [256*8-1:0] SP_INIT_VEC = {
        {192{SP_INIT_DF}},
        SP_INIT_3F, SP_INIT_3E, SP_INIT_3D, SP_INIT_3C,
        SP_INIT_3B, SP_INIT_3A, SP_INIT_39, SP_INIT_38,

        SP_INIT_37, SP_INIT_36, SP_INIT_35, SP_INIT_34,
        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,

        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,
        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,

        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,
        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,

        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,
        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,

        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,
        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,

        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,
        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,

        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF,
        SP_INIT_DF, SP_INIT_DF, SP_INIT_DF, SP_INIT_DF };

    kcpsm6 #(.HWBUILD(HWBUILD),
             .SCRATCH_PAD_INITIAL_VALUES(SP_INIT_VEC),
             .INTERRUPT_VECTOR(12'h37F)) u_picoblaze(.address(address),.instruction(instruction),.bram_enable(bram_enable),
                        .cur_bank(picoblaze_bank),
                        .in_port(in_port),.out_port(out_port),.port_id(port_id),
                        .write_strobe(write_strobe),.k_write_strobe(k_write_strobe),
                        .read_strobe(read_strobe),.interrupt(interrupt),.interrupt_ack(interrupt_ack),
                        .sleep(sleep),.reset(processor_reset),.clk(wb_clk_i));    
    pb_turfio #(.BRAM_PORT_WIDTH(8))
        u_prom(.address(address),.instruction(instruction),.enable(bram_enable),.clk(wb_clk_i),
               .bram_adr_i(bram_addr),
               .bram_dat_i(out_port),
               .bram_dat_o(bram_data),
               .bram_we_i(bram_write),
               .bram_en_i(kport_id[7]));
    
    // just for testing
// dumbass
//    assign cobs_valid = 0;
//    assign cobs_in = 8'h00;
//    assign our_id = 8'h40;
    assign wb_dat_o = { {31{1'b0}}, processor_reset };
    assign wb_ack_o = ack && wb_cyc_i;
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
endmodule
