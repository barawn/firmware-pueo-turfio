`timescale 1ns / 1ps
`include "dsp_macros.vh"
// Very, very simple clock monitor. Fairly low resource usage
// for even a fairly large number of clocks.
//
// TL;DR Usage Version:
// 1) You need a running clock that's relatively fast, probably at least
//    25 MHz ish. 
// 2) You need to calibrate the clock counter first. Write into any
//    address (2^24 - (clk_frequency/256)). If it's not divisible just round.
//    The actual clock counts are often uncertain to similar amounts anyway.
// 3) Read from any address to get the clock count. After you calibrate it
//    you'll need to wait (NUM_CLOCKS*4 ms) before the values are accurate.
//    Which is usually negligibly long anyway.
// 4) The clock frequencies (by default) are measured in steps of around 16 kHz,
//    however they will read out in Hz correctly: the bottom 14 bits will always
//    be 0.
// 5) You also need to implement CDC constraints, such that
//    going from clk_32x_level -> level_cdc_ff is set to
//    datapath_only with some reasonable value (like 10 ns).

// Having clocks measured to obscene precision is fairly stupid,
// and having them constantly monitored is also pretty dumb.
// For instance, if we have clocks that range from:
// 7.8125 MHz to 500 MHz, this is a total range of 64 (6 bits)
// If we use a 16 bit value to store the count, that means each
// tick is ~15 kHz-ish.
//
// To allow us to count in one clock domain, we'll generate slow
// level changes in the target domain (via the SRL trick) and
// look for rising edges, counting them as 64 ticks.
// In order to get ~15 kHz-ish with 64 tick values that requires
// around 200 Hz-ish accumulating time, around 5 milliseconds.
//
// Of course we want a simple way of getting a value in Hz afterwards
// because EVERYONE ALWAYS complains if software has to do math
// (god only knows why).
// So let's figure out the trick.
// We count in 64 tick values so we'll need to scale up by 64. That's
// easy. We're only going to accumulate for around 1/200th of a second,
// so we would need to multiply by 200, which is awkward. Instead
// make it 1/256th of a second. 1/256th of a second ends up being
// really convenient anyway since lots of clocks are evenly divisible
// at 256ths of a second.
// So for instance if we have a 40 MHz clock, 1/256th of a second
// consists of 156,250 ticks.
//
// To really simplify things, we put the burden on software to
// calibrate the initialization clock: we use the DSP in 24-bit SIMD mode
// and have software program in 2^24 - (1/256th)*clock, so for
// a 40 MHz clock we program in 16,620,966. This gets loaded into the
// 24-bit input on the A:B register input whenever on the lower DSP input.
//
// When the DSP input rolls over (CARRYOUT[1] goes high) this drives
// RSTP and also sets OPMODE[1:0] = 11. This makes P equal to the value
// of the AB input. The upper AB input is zero, so it doesn't affect the
// accumulator.
//
// This is a really, really simple way of allowing us to monitor lots of
// clocks easily. We end up needing to upshift by 14 bits.
//
// CLOCK_BITS/CLOCK_SHIFT_CNT/CLOCK_SHIFT_DAT can be adjusted for more precision but it's
// basically pointless, it's easier to leave them as they are unless
// you've got super-huge resource constraints or something.
//
// Basically the value that you read is
// (((24-bit DSP output) >> CLOCK_SHIFT_CNT) % (1<<CLOCK_BITS)) << CLOCK_SHIFT_DAT.
//
// Because the clock cross is formed by a 32-fold divide,
// this means that your base clock needs to be probably at most 30x slower than
// the fastest clock. This shouldn't be an issue in most cases: the highest
// clock we can really run at is 500 MHz ish, which would be like, 16 MHz.
// Our init clock here is 40 MHz.
//
// Note: you CANNOT read back the clock prescale. It's internal to the DSP.
// Deal with it.
//
module simple_clock_mon #(
        parameter NUM_CLOCKS = 8,       // Number of clocks to monitor
        parameter CLOCK_BITS = 16,      // Precision to store. Can be up to 24
        parameter CLOCK_SHIFT_CNT = 0,  // Number of bits to shift DSP output *down*
        parameter CLOCK_SHIFT_DAT = 14  // Number of bits to upshift the output.
    )(
        input clk_i,
        input [$clog2(NUM_CLOCKS)-1:0] adr_i,
        input en_i,
        input wr_i,
        input [31:0] dat_i,
        output [31:0] dat_o,
        output ack_o,
        
        input [NUM_CLOCKS-1:0] clk_mon_i
    );
    
    // Number of bits for the clock select counter.
    localparam SELECT_BITS = $clog2(NUM_CLOCKS);
    // Number of clocks, expanded to nearest power of 2. For memory storage.
    localparam NUM_CLOCKS_EXP = (1<<SELECT_BITS);
    
    // Memory storage for the clock outputs. Will get implemented as dual-port dist RAM
    // I hope.
    reg [CLOCK_BITS-1:0] clk_count_value[NUM_CLOCKS_EXP-1:0];
    // Output data register
    reg [CLOCK_BITS-1:0] clk_value_read = {CLOCK_BITS{1'b0}};
    // Initialize all values to zero (including unused ones in the expanded space).
    integer ii;
    initial for (ii=0;ii<NUM_CLOCKS_EXP;ii=ii+1) clk_count_value[ii] <= {CLOCK_BITS{1'b0}};
    
    // These are the level toggles for each clock. They toggle every 32 clocks.
    reg [NUM_CLOCKS-1:0] clk_32x_level = {NUM_CLOCKS{1'b0}};
    
    // We need 3 registers here: the first is the metastable
    // clock crossing register, and the next two form the
    // rising edge detector. We can't (well, shouldn't) just
    // do (ff1 && !ff2) because the timing tools would think
    // they have a full clock to get there.
    (* ASYNC_REG = "TRUE" *)
    reg [NUM_CLOCKS-1:0] level_cdc_ff1 = {NUM_CLOCKS{1'b0}};
    (* ASYNC_REG = "TRUE" *)
    reg [NUM_CLOCKS-1:0] level_cdc_ff2 = {NUM_CLOCKS{1'b0}};
    (* ASYNC_REG = "TRUE" *)
    reg [NUM_CLOCKS-1:0] level_cdc_ff3 = {NUM_CLOCKS{1'b0}};
    // This is the actual rising edge for each flag.
    reg [NUM_CLOCKS-1:0] level_flag = {NUM_CLOCKS{1'b0}};

    reg [SELECT_BITS-1:0] clock_select = {SELECT_BITS{1'b0}};
    wire selected_clock_cnt64 = level_flag[clock_select];
    
    // Implement the level toggles.
    generate
        genvar i;
        for (i=0;i<NUM_CLOCKS;i=i+1) begin : CLG
            reg q_rereg = 0;
            wire srl_out;
            SRLC32E #(.INIT(32'h0)) u_srl(.D(!srl_out),.CE(1'b1),.Q31(srl_out),.CLK(clk_mon_i[i]));
            always @(posedge clk_mon_i[i]) clk_32x_level[i] <= srl_out;
        end
    endgenerate

    always @(posedge clk_i) begin
        level_cdc_ff1 <= clk_32x_level;
        level_cdc_ff2 <= level_cdc_ff1;
        level_cdc_ff3 <= level_cdc_ff2;
        // Form the rising edges.
        level_flag <= ~level_cdc_ff3 & level_cdc_ff2;
    end            

    wire [47:0] dspAB = { {24{1'b0}}, dat_i[0 +: 24] };
    wire [47:0] dspC = { {23{1'b0}}, selected_clock_cnt64, {23{1'b0}}, 1'b1 };
    wire [47:0] dspP;
    wire        dspAB_ce = (en_i && wr_i && ack_o);
    wire [3:0]  dsp_carryout;
    wire [3:0]  dsp_alumode = `ALUMODE_SUM_ZXYCIN;
    wire [2:0]  dsp_carryinsel = `CARRYINSEL_CARRYIN;    
    wire        count_done = dsp_carryout[`DUAL_DSP_CARRY0];
    
    wire        count_reset = (en_i && wr_i && ack_o);
    
    // This makes the opmode equal to P+C+AB in the clock cycle after it completes.
    // Otherwise it's just P+C. It happens 1 clock later because OPMODEREG is 1
    wire [6:0]  dsp_opmode = { `Z_OPMODE_P, `Y_OPMODE_C, count_done || count_reset , count_done || count_reset };

    DSP48E1 #( .ALUMODEREG(0),
               .CARRYINSELREG(0),
               .OPMODEREG(1),
               .USE_SIMD("TWO24"),
               .AREG(1),
               .BREG(1),
               .CREG(0),
               .PREG(1),
               `D_UNUSED_ATTRS,
               `NO_MULT_ATTRS )
               u_dsp( .CLK(clk_i),
                      .A( `DSP_AB_A(dspAB) ),
                      .B( `DSP_AB_B(dspAB) ),
                      .C( dspC ),
                      `D_UNUSED_PORTS,
                      .CEA2( dspAB_ce ),
                      .CEB2( dspAB_ce ),
                      .CEP(1'b1),
                      .CEC(1'b0),
                      .CEM(1'b0),
                      .CECTRL(1'b1),
                      .CEINMODE(1'b0),
                      .CECARRYIN(1'b0),                      
                      .RSTA(1'b0),
                      .RSTB(1'b0),
                      .RSTC(1'b0),
                      .RSTP( count_done || count_reset ),
                      .RSTM(1'b0),
                      .RSTCTRL(1'b0),
                      .RSTINMODE(1'b0),
                      .ALUMODE( dsp_alumode ),
                      .OPMODE(  dsp_opmode ),
                      .CARRYOUT(dsp_carryout ),
                      .CARRYINSEL(dsp_carryinsel),
                      .CARRYIN(1'b0),
                      .P(dspP));
                      
    reg ack_ff = 0;
                      
    always @(posedge clk_i) begin
        if (count_done) clk_count_value[clock_select] <= dspP[(24 + CLOCK_SHIFT_CNT) +: CLOCK_BITS];
        if (en_i && !wr_i) clk_value_read <= clk_count_value[adr_i];
        ack_ff <= en_i;
        
        if (count_done) begin
            if (clock_select == (NUM_CLOCKS-1)) clock_select <= {SELECT_BITS{1'b0}};
            else clock_select <= clock_select + 1;
        end
    end

    assign ack_o = ack_ff && en_i;
    assign dat_o = { {(CLOCK_BITS-CLOCK_SHIFT_DAT){1'b0}}, clk_value_read, {CLOCK_SHIFT_DAT{1'b0}}};
endmodule
