`timescale 1ns / 1ps
`include "turfio_debug.vh"
`include "interfaces.vh"
// This is pulled from the RADIANT firmware originally.
// 
module uart_interface(
        input clk,
        input rst,
        
        // Make this a semi-proper WISHBONE interface
        `HOST_NAMED_PORTS_WB_IF( wb_ , 20, 32 ),

        input [1:0] burst_size_i,

        input RX,
        output TX
    );


    parameter SIMULATION = "FALSE";    
    parameter DEBUG = `UART_INTERFACE_DEBUG;
            
    parameter CLOCK_RATE = 100000000;
    parameter BAUD_RATE = 1000000;    


    //////////////////////////////////////////////////////////
    // UART
    //////////////////////////////////////////////////////////
    wire [7:0] cobs_rx_tdata;
    wire cobs_rx_tvalid;
    wire cobs_rx_tready;
    wire cobs_rx_tlast = (cobs_rx_tdata == 8'h00);

    wire [7:0] cobs_tx_tdata;
    wire cobs_tx_full;
    wire cobs_tx_tready = !cobs_tx_full;
    wire cobs_tx_tvalid;

    uart_wrap #(.CLOCK_FREQ(CLOCK_RATE),
                .BAUD(BAUD_RATE),
                .DEBUG(DEBUG))
                u_uart( .aclk(clk),
                        .aresetn(1'b1),
                        `CONNECT_AXI4S_MIN_IF( s_axis_ , cobs_tx_ ),
                        `CONNECT_AXI4S_MIN_IF( m_axis_ , cobs_rx_ ),
                        .RX(RX),
                        .TX(TX)); 
 
    //////////////////////////////////////////////////////////
    // COBS decode/encode
    //////////////////////////////////////////////////////////    
 
    wire [7:0] axis_rx_tdata;
    wire axis_rx_tvalid;
    wire axis_rx_tready;
    wire axis_rx_tlast;
    wire axis_rx_tuser;
    
    reg [7:0] axis_tx_tdata = {8{1'b0}};
    wire axis_tx_tvalid;
    wire axis_tx_tready;
    reg axis_tx_tlast = 0;
    
    reg cobs_reset = 0;

    axis_cobs_decode u_decoder(.clk(clk),.rst(rst || cobs_reset),
                                .s_axis_tdata(cobs_rx_tdata),
                                .s_axis_tvalid(cobs_rx_tvalid),
                                .s_axis_tready(cobs_rx_tready),
                                .s_axis_tuser(1'b0),
                                .s_axis_tlast(cobs_rx_tlast),
                                .m_axis_tdata(axis_rx_tdata),
                                .m_axis_tuser(axis_rx_tuser),
                                .m_axis_tvalid(axis_rx_tvalid),
                                .m_axis_tready(axis_rx_tready),
                                .m_axis_tlast(axis_rx_tlast));
    axis_cobs_encode u_encoder( .clk(clk), .rst(rst || cobs_reset),
                                .s_axis_tdata(axis_tx_tdata),
                                .s_axis_tvalid(axis_tx_tvalid),
                                .s_axis_tready(axis_tx_tready),
                                .s_axis_tuser(1'b0),
                                .s_axis_tlast(axis_tx_tlast),
                                .m_axis_tdata(cobs_tx_tdata),
                                .m_axis_tready(cobs_tx_tready),
                                .m_axis_tvalid(cobs_tx_tvalid));    
 
    reg en = 0;
    reg wr = 0;
    reg [3:0] wstrb = {4{1'b0}};
    reg [31:0] data = {32{1'b0}};
    // this is bit 22 in the address field (MSB)
    reg addr_increment = 0;
    
    reg [7:0] len = {8{1'b0}};
    reg write_last = 0;
    
    // rty_i is just ignored       
    wire internal_ack = wb_ack_i || wb_err_i;

    reg [23:0] address = {24{1'b0}};
    reg [23:0] capture_address = {24{1'b0}};
    // On burst reads we auto-align addresses. 
    wire [1:0] lowbit_mask = { !burst_size_i[1], !burst_size_i[1] && !burst_size_i[0] };
    wire [7:0] lowbyte_mask = { 6'h3F, lowbit_mask };
    wire [7:0] aligned_address = (capture_address[23] && capture_address[22]) ? axis_rx_tdata & lowbyte_mask : axis_rx_tdata;
        
    localparam FSM_BITS=5;
    localparam [FSM_BITS-1:0] IDLE=0;
    // address comes in big-endian, just freaking because
    localparam [FSM_BITS-1:0] ADDR2=1;
    localparam [FSM_BITS-1:0] ADDR1=2;
    localparam [FSM_BITS-1:0] ADDR0=3;
    localparam [FSM_BITS-1:0] READLEN=4;
    localparam [FSM_BITS-1:0] READADDR2=5;
    localparam [FSM_BITS-1:0] READADDR1=6;
    localparam [FSM_BITS-1:0] READADDR0=7;
    localparam [FSM_BITS-1:0] READCAPTURE=8;
    localparam [FSM_BITS-1:0] READDATA0=9;
    localparam [FSM_BITS-1:0] READDATA1=10;
    localparam [FSM_BITS-1:0] READDATA2=11;
    localparam [FSM_BITS-1:0] READDATA3=12;    
    // data comes in little-endian, as if it's byte-addressed
    localparam [FSM_BITS-1:0] WRITE0=13;
    localparam [FSM_BITS-1:0] WRITE1=14;
    localparam [FSM_BITS-1:0] WRITE2=15;
    localparam [FSM_BITS-1:0] WRITE3=16;
    localparam [FSM_BITS-1:0] WRITEEN=17;
    localparam [FSM_BITS-1:0] WRITEADDR2=18;
    localparam [FSM_BITS-1:0] WRITEADDR1=19;
    localparam [FSM_BITS-1:0] WRITEADDR0=20;
    localparam [FSM_BITS-1:0] WRITELEN=21;
    localparam [FSM_BITS-1:0] RESET0 = 22;
    localparam [FSM_BITS-1:0] RESET1 = 23;
    // yikes this is big
    reg [FSM_BITS-1:0] state = RESET0;

    always @(posedge clk) begin
        case (state)
            IDLE: if (axis_rx_tvalid && !axis_rx_tlast && !axis_rx_tuser) state <= ADDR2;
            ADDR2: if (axis_rx_tvalid) begin
                if (axis_rx_tlast || axis_rx_tuser) state <= IDLE;
                else state <= ADDR1;
            end
            ADDR1: if (axis_rx_tvalid) begin
                if (axis_rx_tlast || axis_rx_tuser) state <= IDLE;
                else state <= ADDR0;
            end
            ADDR0: if (axis_rx_tvalid) begin
                if (axis_rx_tlast || axis_rx_tuser) state <= IDLE;
                else begin
                    if (capture_address[23]) begin
                        // Figure out where we start.
                        // Note that capture_address[1:0] isn't valid yet, grab it from the RX
                        if (axis_rx_tdata[1:0] == 2'b00) state <= WRITE0;
                        else if (axis_rx_tdata[1:0] == 2'b01) state <= WRITE1;
                        else if (axis_rx_tdata[1:0] == 2'b10) state <= WRITE2;
                        else if (axis_rx_tdata[1:0] == 2'b11) state <= WRITE3;
                    end else state <= READLEN;
                end
            end
            READLEN: if (axis_rx_tvalid) begin
                // TLAST *should* be asserted here.
                if (axis_rx_tuser || !axis_rx_tlast) state <= IDLE;
                else state <= READADDR2;
            end
            // This writes the address back, byte by byte
            READADDR2: if (axis_tx_tready) state <= READADDR1;
            READADDR1: if (axis_tx_tready) state <= READADDR0;
            READADDR0: if (axis_tx_tready) state <= READCAPTURE;
            READCAPTURE: if (internal_ack) begin
                // Figure out where we start. Note that 'address' here is
                // already burst-aligned, so if we're bursting, it'll only go to the appropriate
                // address.
                if (address[1:0] == 2'b00) state <= READDATA0;
                else if (address[1:0] == 2'b01) state <= READDATA1;
                else if (address[1:0] == 2'b10) state <= READDATA2;
                else if (address[1:0] == 2'b11) state <= READDATA3;
            end
            // If bursting in byte mode, jump to READCAPTURE to grab data again. Otherwise
            // go to READDATA1.
            READDATA0: if (axis_tx_tready) begin
                if (!len) state <= IDLE;
                else if (addr_increment || (burst_size_i != 2'b00)) state <= READDATA1;
                else state <= READCAPTURE;
            end
            // If bursting in byte mode OR in word mode (NOT in dword mode) jump to
            // READCAPTURE to grab data again. Otherwise go to READDATA2.
            READDATA1: if (axis_tx_tready) begin
                if (!len) state <= IDLE;
                else if (addr_increment || (burst_size_i == 2'b10)) state <= READDATA2;
                else state <= READCAPTURE;
            end
            // If bursting in byte mode, jump to READCAPTURE to grab data again. Otherwise
            // go to READDATA3.
            READDATA2: if (axis_tx_tready) begin
                if (!len) state <= IDLE;
                else if (addr_increment || (burst_size_i != 2'b00)) state <= READDATA3;
                else state <= READCAPTURE;
            end
            // No matter what, go to READCAPTURE to grab next data.
            READDATA3: if (axis_tx_tready) begin
                if (!len) state <= IDLE;
                else state <= READCAPTURE;
            end
            // soooo... this will do wackadoodle things if an
            // error comes in the middle. Maybe buffer the writes.
            // Check that later.
            //
            // The burst_size_i qualification makes it so we interpret these differently.
            // If 00, we go WRITEx->WRITEEN->WRITEx->WRITEEN repeatedly.
            // If 01, we go WRITE0/2->WRITE1/3->WRITEEN repeatedly.
            // If 10, we go WRITE0->WRITE1->WRITE2->WRITE3->WRITEEN repeatedly.
            // Note that if you screw up and do it unaligned, it'll go like
            // WRITE3->WRITEEN->WRITE0->WRITE1->WRITE2->WRITE3->WRITEEN
            // which, I guess could be useful
            WRITE0: if (axis_rx_tvalid) begin
                if (axis_rx_tuser) state <= IDLE;
                else if (axis_rx_tlast || (!addr_increment && (burst_size_i == 2'b00) )) state <= WRITEEN;
                else state <= WRITE1;
            end
            WRITE1: if (axis_rx_tvalid) begin
                if (axis_rx_tuser) state <= IDLE;
                else if (axis_rx_tlast || (!addr_increment && (burst_size_i == 2'b01 || burst_size_i == 2'b00) )) state <= WRITEEN;
                else state <= WRITE2;
            end
            WRITE2: if (axis_rx_tvalid) begin
                if (axis_rx_tuser) state <= IDLE;
                else if (axis_rx_tlast || (!addr_increment && (burst_size_i == 2'b00) )) state <= WRITEEN;
                else state <= WRITE3;
            end
            WRITE3: if (axis_rx_tvalid) begin
                if (axis_rx_tuser) state <= IDLE;
                else state <= WRITEEN;
            end
            WRITEEN: if (internal_ack) begin
                if (write_last) state <= WRITEADDR2;
                else if (!addr_increment) begin
                    if (burst_size_i == 2'b00) begin
                        // figure out where we jump back to
                        if (address[1:0] == 2'b00) state <= WRITE0;
                        else if (address[1:0] == 2'b01) state <= WRITE1;
                        else if (address[1:0] == 2'b10) state <= WRITE2;
                        else if (address[1:0] == 2'b11) state <= WRITE3;                
                    end else if (burst_size_i == 2'b01) begin
                        if (address[1]) state <= WRITE2;
                        else state <= WRITE3;
                    end else state <= WRITE0;
                end else state <= WRITE0;
            end
            WRITEADDR2: if (axis_tx_tready) state <= WRITEADDR1;
            WRITEADDR1: if (axis_tx_tready) state <= WRITEADDR0;
            WRITEADDR0: if (axis_tx_tready) state <= WRITELEN;
            WRITELEN: if (axis_tx_tready) state <= IDLE;
            RESET0: state <= RESET1;
            RESET1: state <= IDLE;
        endcase
                
        // deal with the address increments
        if (((state == WRITEEN && internal_ack) || (state == READDATA3 && axis_tx_tready)) && addr_increment)
            address <= { 2'b00, address[21:2], 2'b00 } + 4;
        else if (state == ADDR0)
            address <= {capture_address[23:8],aligned_address};
        
        if (state == ADDR2) addr_increment <= !axis_rx_tdata[6];
        
        if (state == ADDR2) capture_address[23:16] <= axis_rx_tdata;
        if (state == ADDR1) capture_address[15:8] <= axis_rx_tdata;
        if (state == ADDR0) capture_address[7:0] <= axis_rx_tdata;
    
        if (state == WRITE0 && axis_rx_tvalid) data[7:0] <= axis_rx_tdata;
        else if (state == READCAPTURE && internal_ack) data[7:0] <= wb_dat_i[7:0];
        
        if (state == WRITE1 && axis_rx_tvalid) data[15:8] <= axis_rx_tdata;
        else if (state == READCAPTURE && internal_ack) data[15:8] <= wb_dat_i[15:8];
        
        if (state == WRITE2 && axis_rx_tvalid) data[23:16] <= axis_rx_tdata;
        else if (state == READCAPTURE && internal_ack) data[23:16] <= wb_dat_i[23:16];
        
        if (state == WRITE3 && axis_rx_tvalid) data[31:24] <= axis_rx_tdata;
        else if (state == READCAPTURE && internal_ack) data[31:24] <= wb_dat_i[31:24];
        
        if (state == IDLE || (state == WRITEEN && internal_ack)) wstrb <= {4{1'b0}};
        else begin
            if (state == WRITE0) wstrb[0] <= 1;
            if (state == WRITE1) wstrb[1] <= 1;
            if (state == WRITE2) wstrb[2] <= 1;
            if (state == WRITE3) wstrb[3] <= 1;
        end
        
        if (state == IDLE) write_last <= 0;
        else if (state == WRITE0 || state == WRITE1 || 
                 state == WRITE2 || state == WRITE3) begin
            if (axis_rx_tvalid && axis_rx_tlast && !axis_rx_tuser) 
                write_last <= 1;
            else 
                write_last <= 0;
        end
        
        // length handling
        if (state == IDLE) len <= {8{1'b0}};
        else if ((state == WRITE0 || state == WRITE1 || state == WRITE2 || state == WRITE3) && axis_rx_tvalid) len <= len + 1;
        else if ((state == READDATA0 || state == READDATA1 || state == READDATA2 || state == READDATA3) && axis_tx_tready) len <= len - 1;
        else if ((state == READLEN) && axis_rx_tvalid) len <= axis_rx_tdata;
        
        // outgoing data determination. Here we need to prep things the cycle before.
        if (state == READLEN || state == WRITEEN) 
            axis_tx_tdata <= capture_address[23:16];
        else if ((state == READADDR2 || state == WRITEADDR2) && axis_tx_tready)
            axis_tx_tdata <= capture_address[15:8];
        else if ((state == READADDR1 || state == WRITEADDR1) && axis_tx_tready)
            axis_tx_tdata <= capture_address[7:0];
        else if (state == READCAPTURE && internal_ack) begin
            if (address[1:0] == 2'b00) axis_tx_tdata <= wb_dat_i[7:0];
            else if (address[1:0] == 2'b01) axis_tx_tdata <= wb_dat_i[15:8];
            else if (address[1:0] == 2'b10) axis_tx_tdata <= wb_dat_i[23:16];
            else if (address[1:0] == 2'b11) axis_tx_tdata <= wb_dat_i[31:24];
        end 
        else if (state == READDATA0 && axis_tx_tready) axis_tx_tdata <= wb_dat_i[15:8];
        else if (state == READDATA1 && axis_tx_tready) axis_tx_tdata <= wb_dat_i[23:16];
        else if (state == READDATA2 && axis_tx_tready) axis_tx_tdata <= wb_dat_i[31:24];
        else if (state == WRITEADDR0 && axis_tx_tready) axis_tx_tdata <= len;

        // tlast generation
        if (state == WRITEADDR0 && axis_tx_tready) axis_tx_tlast <= 1;
        // TLAST goes when we're going to TRANSIT to 0 in the next guy.
        // There's one special case we need to handle, which is in READCAPTURE if len is already 0.
        // This happens if READDATA0 is going to be the final byte. Note that READDATA3 is excluded
        // here because the next state after READDATA3 is always READCAPTURE, so the len = 0 catches
        // that there.
        else if ((state == READCAPTURE && internal_ack && (len == 0)) || 
                 (((state == READDATA0 || state == READDATA1 || state == READDATA2) && axis_tx_tready) && 
                 (len == 1))) axis_tx_tlast <= 1;
        else axis_tx_tlast <= 0;
    end

    // Our "hard reset the interface" method: 4 null bytes (0) in a row.
    reg [1:0] null_counter = {2{1'b0}};
    always @(posedge clk) begin
        if (cobs_rx_tready && cobs_rx_tvalid) begin
            if (cobs_rx_tdata == 8'h00) null_counter[1:0] <= null_counter[1:0] + 1;
            else null_counter <= {2{1'b0}};
        end
        if (cobs_rx_tready && cobs_rx_tvalid && cobs_rx_tdata == 8'h00 && null_counter[1:0] == 2'b11) cobs_reset <= 1;
        else cobs_reset <= 0;
    end    
                
    generate
        if (DEBUG == "TRUE") begin : COBSILA                                                                                                                            
            cobs_ila u_ila(.clk(clk),.probe0(axis_rx_tdata),
                                     .probe1(axis_rx_tuser),
                                     .probe2(axis_rx_tvalid),
                                     .probe3(axis_rx_tlast),
                                     .probe4(axis_rx_tready),
                                     .probe5(state),
                                     .probe6(wb_adr_o),
                                     .probe7(wb_cyc_o),
                                     .probe8(wb_we_o),
                                     .probe9(wb_sel_o),
                                     .probe10(wb_dat_o),
                                     .probe11(wb_dat_i),
                                     .probe12(axis_tx_tdata),
                                     .probe13(axis_tx_tvalid),
                                     .probe14(axis_tx_tready),
                                     .probe15(axis_tx_tlast),
                                     .probe16(cobs_tx_tdata),
                                     .probe17(cobs_tx_tready),
                                     .probe18(cobs_tx_tvalid),
                                     .probe19(burst_size_i),
                                     .probe20(len),
                                     .probe21(cobs_reset));
         end
     endgenerate
    
    // tready generation. Does NOT happen in IDLE unless we have gar-bage to zip through.    
    // The state names describe what's currently on the TDATA busses.
    wire idle_dump = (state == IDLE && axis_rx_tvalid && (axis_rx_tlast || axis_rx_tuser));
    
    assign axis_rx_tready = (state == ADDR2 || state == ADDR1 || 
                             state == ADDR0 || state == READLEN ||
                             state == WRITE0 || state == WRITE1 || state == WRITE2 ||
                             state == WRITE3 || idle_dump);

    // tvalid generation
    assign axis_tx_tvalid = (state == READDATA0 || state == READDATA1 || state == READDATA2 ||
                             state == READDATA3 || state == READADDR0 || state == READADDR1 ||
                             state == READADDR2 || state == WRITEADDR0 || state == WRITEADDR1 ||
                             state == WRITEADDR2 || state == WRITELEN);

    reg [21:0] simadr = {22{1'b0}};
    reg [31:0] simdat = {32{1'b0}};
    reg simen = 0;
    reg simwr = 0;
    reg [3:0] simwstrb = {4{1'b0}};

    // synthesis translate off

    task automatic SIMWR(input [21:0] address, input [31:0] value);
        begin
            @(posedge clk); #1 simen = 1; simadr = address; simdat = value; simwstrb = 4'hF; simwr = 1; @(posedge clk);
            while (!internal_ack) @(posedge clk);
            #1 simen = 0; simwr = 0;
        end
    endtask
    
    task automatic SIMRD(input [21:0] address, output [31:0] value);
        begin
            @(posedge clk); #1 simen = 1; simadr = address; @(posedge clk);
            while (!internal_ack) @(posedge clk);
            value = wb_dat_i;
            #1 simen = 0;
        end
    endtask
        

    // synthesis translate on

    generate
        if (SIMULATION == "TRUE") begin : INTSIGS
            assign wb_adr_o = simadr[21:2];
            assign wb_dat_o = simdat;
            assign wb_cyc_o = simen;
            assign wb_stb_o = simen;
            assign wb_we_o = simwr;
            assign wb_sel_o = simwstrb;
        end else begin : REAL
            assign wb_adr_o = address[21:2];
            assign wb_dat_o = data;
            assign wb_cyc_o = (state == WRITEEN) || (state == READCAPTURE);
            assign wb_stb_o = wb_cyc_o;
            assign wb_we_o = (state == WRITEEN);
            assign wb_sel_o = wstrb;
        end                
    endgenerate
                
endmodule
