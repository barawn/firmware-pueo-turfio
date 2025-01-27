`timescale 1ns / 1ps
// This is a simple retimer for open-drain UARTs
//
// TL;DR: you can adjust the sample point for asymmetric drive UARTs by passing SAMPLE_POINT 
// and BAUD_RATE parameters in clock units. From a practical point of view, measure the length
// of a received 0xFF. Subtract that length from 2x bit period and divide by 2. Subtract that 
// from 1x bit period and that's your ideal SAMPLE_POINT.
// 
// --- the long version
//
// Open-drain UARTs have an issue because the "time to valid" is different between
// 0 and 1: you can drive a 0 practically instantaneously, but 1s take longer.
// There's no real problem with running it fast, but you need to make sure that your
// sample point is grabbing at the right spot, and a normal UART samples basically
// 1.5 bit-times after the start bit.
//
// if we use a perfect 0.5 Mbaud, our bit times are 2000 ns = exactly 160 80 ns clocks.
// so then we can retime easier. when we see the start bit, we wait 120 clocks, and then
// sample every 160 clocks.
// This shifts the sample point to 1.5 us: because the risetime is roughly 1 us, this
// is right in the middle of the proper data valid window.
//
// rx       rx_out  start_bit    counter     bit count  running
// 1        1       0            42          0          0   - this is 1 CLOCK AFTER RX goes low
// 0        1       1            42          0          0
// 0        1       0            43          0          1
// ...
// 0        1       0            159         0              - this is a delta of 120 clocks
// 0        0       0            0           1
// ...
// 0        0       0            39          1
// D7       0       0            40          1
// ...
// D7       0       0            159         1
// D7       D7      0            0           2
// ...
// Note that bit count needs to reset at 10 here, since we have 10 bits.
//
// however: we don't actually do these counter values since it would
// require a separate comparator. Instead we shift up so that the top carry
// bit of an 8 bit counter (256) is our output flag.
// this requires adding (256-END_COUNT) to everything: so we
// now start at 139 and trip at 256.
//
// our actual trick is
// rx       rx_out  start_bit    counter     bit count  running
// 1        1       0            0           0          0   - this is 1 CLOCK AFTER RX goes low
// 0        1       1            0           0          0
// 0        1       0            137         0          1
// ...
// 0        1       0            255         0              
// 0        0       0            0           1              - this is a delta of 120 clocks from rx=0
// ...
// 0        0       0            97          1
// D7       0       0            98          1
// ...
// D7       0       0            255         1
// D7       D7      0            0           2              - this is a delta of 160 clocks from start bit output
//                                                          - and 280 clocks from rx=0
// so ACTUAL_START = 137 = 256-120+1
// and ACTUAL_RESET = 97 = 256-160+1

//
// note that this cound be done more efficient, but whatever
// also note that we resample RX in the IOB and register start bit,
// hence the 2 clock offset. It doesn't matter much - this can be adjusted
// to the start point.
//
// You pass SAMPLE_POINT and BAUD_PERIOD here in absolutes and
// it does the adjustments. SAMPLE_POINT should be midway through the data valid
// period.
module uart_retime #(parameter SAMPLE_POINT=120,
                     parameter BAUD_PERIOD=160,
                     parameter DEBUG = "FALSE")(
        input clk,
        input RX,
        output RX_RETIMED
    );
    localparam [7:0] ACTUAL_START = (256 - SAMPLE_POINT + 1);
    localparam [7:0] ACTUAL_RESET = (256 - BAUD_PERIOD + 1);
    
    // we want to stop running after bit count hits 10
    localparam MAX_BIT_COUNT = 10;
    // so we start at 6 and count until we roll over.
    localparam OFFSET_BIT_COUNT = (16 - MAX_BIT_COUNT);  
    reg running = 0;
    reg [4:0] bit_count = {5{1'b0}};
    
    reg [8:0] counter = {9{1'b0}};
    
    reg rx_start_bit = 0;
    reg rx_start_bit_rereg = 0;
    reg rx_resample = 1;
    (* IOB = "TRUE" *)
    reg rx_in = 1;
    reg rx_out = 1;

    // okay, now comes the tricky part. we start at 0 when not running.
    // start bit needs to add ACTUAL_START
    // and then the overflow bit needs to add OFFSET.
    // our first attempt here is to just try to do it as a cascaded ternary op
    // and hope things are smart
    // lololol
    // - there is NO REASON this logic can't be pushed into the adder: it depends on
    // only 2 inputs (rx_start_bit and counter[8]). 
    wire [7:0] ADD_VALUE = (rx_start_bit_rereg) ? ACTUAL_START : (counter[8] ? ACTUAL_RESET : 1'b1);


    // at bit counter 6 -> 7 we output start bit
    // at bit counter 7 -> 8 we output D7
    // at bit counter 8 -> 9 we output D6
    // at bit counter 9 -> 10 we output D5
    // at bit counter 10 -> 11 we output D4
    // at bit counter 11 -> 12 we output D3
    // at bit counter 12 -> 13 we output D2
    // at bit counter 13 -> 14 we output D1
    // at bit counter 14 -> 15 we output D0
    // at bit counter 15 -> 0(16) we output STOP and running ends.
    //
    // note that we can run for consecutive bits because we end running
    // right after STOP: this is midway through the STOP bit's period,
    // which means another stop bit could come immediately afterwards
    // and we'd resync to it right away.
    wire rx_start_flag = (!running) && !rx_in && rx_resample;
    
    always @(posedge clk) begin
        rx_in <= RX;
        rx_resample <= rx_in;        
        rx_start_bit <= rx_start_flag;
        rx_start_bit_rereg <= rx_start_bit;
        
        if (!running) bit_count <= OFFSET_BIT_COUNT;
        else if (counter[8]) bit_count <= bit_count[3:0] + 1;

        if (bit_count[4]) running <= 0;
        else if (rx_start_bit) running <= 1;
        
        if (!running) counter <= 9'h000;
        else counter <= counter[7:0] + ADD_VALUE;

        // and now we just resample at our shifted point
        if (counter[8]) rx_out <= rx_in;
    end
    generate
        if (DEBUG == "TRUE") begin : ILA
            uart_ila u_dbguart(.clk(clk),
                               .probe0(rx_in),
                               .probe1(rx_out),
                               .probe2(counter[7:0]));
        end
    endgenerate
            
    assign RX_RETIMED = rx_out;
endmodule
