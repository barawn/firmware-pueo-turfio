`timescale 1ns / 1ps
`include "interfaces.vh"
module masked_dout_splice(
        input aclk,
        input aresetn,
        // we do need to count/decrement these
        input trig_i,
        input mask_i,
        // this is an overflow error
        output err_o,
        // input is a fake AXI4-stream
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( s_dout_ , 8 ),
        // output is real, since we're buffering.
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( m_dout_ , 8 ),
        output m_dout_tlast
    );
    
    // 8 ch, 1536 bytes per ch, plus 4 bytes for headers
    localparam NUM_BYTES = 8*1536 + 4;
    // this means we can represent up to NUM_BYTES with a BYTE_COUNTER_WIDTH counter
    localparam BYTE_COUNTER_WIDTH = $clog2(NUM_BYTES);    
    
    // whatever, this is way past the max
    localparam MAX_TRIG_COUNTER = 15;
    localparam TRIG_COUNTER_WIDTH = $clog2(MAX_TRIG_COUNTER+1);
    
    
    // splicey splicey
    // the SURF data always starts off with 4 header bytes
    // the first 2 bytes are the trigger time, which is
    // actually a 15-bit number plus the top bit always set
    // this allows us to unambiguously determine the start
    // of an event, it's just the first byte with the
    // top bit set, then followed by 12,291 additional
    // bytes.
    // this ALSO means if there's a header WITHOUT that
    // bit set, it's a masked SURF. see the trick?
    
    reg in_event = 0;
    reg [7:0] din_store = {8{1'b0}};
    reg [BYTE_COUNTER_WIDTH-1:0] byte_counter = {BYTE_COUNTER_WIDTH{1'b0}};
    reg [TRIG_COUNTER_WIDTH-1:0] trig_counter = {TRIG_COUNTER_WIDTH{1'b0}};
    reg fake_event_needed = 0;

    // sigh, this requires more thought.
    // data coming in can't wait more than a clock
    // but it doesn't come in every clock.
    //
    // so we want to go
    // IDLE, START, COUNT
    // but then in COUNT on the last beat we should jump
    // straight back to IDLE. No complete. We can pipeline
    // the comparison to exit complete, but we still
    // need to qualify it by fifo_write.

    localparam FSM_BITS = 2;
    localparam [FSM_BITS-1:0] IDLE = 0;
    localparam [FSM_BITS-1:0] START = 1;
    localparam [FSM_BITS-1:0] COUNT = 2;
    reg [FSM_BITS-1:0] state = IDLE;

    reg        last_byte = 1'b0;
    
    // a single FIFO per SURF should be fine, we shouldn't need to absorb
    // virtually any delay.
    wire       fifo_write = (state != IDLE) && (mask_i ? 1'b1 : s_dout_tvalid);
    wire       fifo_overflow;
    reg        latched_overflow = 0;
    wire       fifo_valid;

    wire       start_event = (mask_i) ? fake_event_needed : (s_dout_tdata[7] != 0 && s_dout_tvalid);

    
    always @(posedge aclk) begin
        if (!aresetn) latched_overflow <= 1'b0;
        else if (fifo_overflow) latched_overflow <= 1'b1;
    
        if (!mask_i)
            fake_event_needed <= 1'b0;
        else if (trig_counter != {TRIG_COUNTER_WIDTH{1'b0}})
            fake_event_needed <= 1'b1;

        // increment if we get trig_i, decrement if we enter state == START,
        // and don't do anything if the two happen at the same time.
        // only used if we're masked
        if (!mask_i || !aresetn) trig_counter <= {TRIG_COUNTER_WIDTH{1'b0}};
        else begin
            if (trig_i && (state != START)) trig_counter <= trig_counter + 1;
            else if (!trig_i && (state == START)) trig_counter <= trig_counter - 1;
        end

        // no data if masked            
        if (mask_i) din_store <= {8{1'b0}};
        else din_store <= s_dout_tdata;            
    
        if (!aresetn)
            last_byte <= 1'b0;
        else if (fifo_write)
            last_byte <= (byte_counter == NUM_BYTES-2);

        if (state == IDLE) byte_counter <= {BYTE_COUNTER_WIDTH{1'b0}};
        else if (fifo_write) byte_counter <= byte_counter + 1;    
    
        if (state == IDLE && start_event)
            in_event <= 1;
        else if (fifo_write && last_byte)
            in_event <= 0;            
    
        if (!aresetn) state <= IDLE;
        else begin
            case (state)
                IDLE: if (start_event) state <= START;
                START: state <= COUNT;
                COUNT: if (fifo_write && last_byte) state <= IDLE;
            endcase
        end
    end
    
    surf_event_fifo u_fifo( .clk( aclk ),
                            .rst( !aresetn ),
                            .din({ last_byte, din_store }),
                            .wr_en(fifo_write),
                            .overflow(fifo_overflow),
                            .dout( { m_dout_tlast, m_dout_tdata } ),
                            .valid( m_dout_tvalid ),
                            .rd_en( m_dout_tvalid && m_dout_tready ));
        
endmodule
