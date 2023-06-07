`timescale 1ns / 1ps
// Generic shift interface module.
// This is based on the JTAG interface used in the
// RADIANT, with the addition of configuration addresses.
// It has been expanded so that it can handle up to 8 separate devices.
// These devices can be SPI-like or even JTAG-like.
// Address 0 is the module configuration register.
// Address 1 is the device configuration register.
// Address 2 is the data register.
// Module configuration register:
// [7:0]  clock prescale
// [15:8] don't tristate device when not enabled
// Device configuration register:
// [7:0]   enable interface
// [15:8]  direction pin for GPIOs (1=input/tristate)
// [23:16] current GPIO value
// [31:24] GPIO output value
// Data register:
// [7:0]  DIN (output) values
// [15:8] AUX_OUT (output) values
// [23:16] DOUT (input) values
// [26:24] number of bits to send minus 1
// [27:28] reserved
// [29]    reverse DIN output bit order
// [30]    enable sequence
// [31]    data not done capturing
//
// The interfaces allows for individual bytes to be addressed,
// which allows continues outputting of the bits if you just set
// "enable sequence" and only write to the outputs you want to update.
//
// This interface can adapt to:
// SPI: use a GPIO as chip select, DIN = MOSI, DOUT = MISO
// JTAG: use AUX_OUT as TMS
module gen_shift_if 
      #(parameter NUM_DEVICES=1,            // number of devices to implement
        parameter [7:0] USE_CLK = 8'h1,     // if 1 for device, implement CCLK as IOB
        parameter [7:0] USE_DIN = 8'h1,     // if 1 for device, implement DIN (output) as IOB
        parameter [7:0] USE_DOUT = 8'h1,    // if 1 for device, implement DOUT (input) as IOB
        parameter [7:0] USE_AUX_OUT = 8'h1, // if 1 for device, implement AUX_OUT (out) as IOB
        parameter NUM_GPIO=1,               // Number of GPIOs go implement
        parameter [NUM_GPIO-1:0] INVERT_GPIO={NUM_GPIO{1'b0}},  // Invert selected GPIO
        parameter [NUM_GPIO-1:0] INTERNAL_GPIO={NUM_GPIO{1'b0}} // Selected GPIO is internal (no IOBUF)
        )
       (input clk,
        input rst,
        input en_i,
        input wr_i,
        input [3:0] wstrb_i,
        input [1:0] address_i,
        input [31:0] dat_i,
        output [31:0] dat_o,
        output ack_o,
        
        output [NUM_DEVICES-1:0] DEV_CLK,
        output [NUM_DEVICES-1:0] DEV_DIN,
        output [NUM_DEVICES-1:0] DEV_AUX_OUT,
        input [NUM_DEVICES-1:0]  DEV_DOUT,
        inout [NUM_GPIO-1:0] DEV_GPIO
    );
    
    localparam [1:0] CLK_STATE_OUTPUT = 2'b01;
    localparam [1:0] CLK_STATE_HIGH = 2'b10;
    localparam [1:0] CLK_STATE_CAPTURE = 2'b11;
    
    // The original module used clk running at 1/4th the
    // system clock speed, and it did
    // clk = 0 output 0 on sclk
    // clk = 1 output data
    // clk = 2 output 1 on sclk
    // clk = 3 capture

    // To slow this down we split this into two. First, a prescaler.
    reg [7:0] clk_prescale = {8{1'b0}};
    // current clk counter
    reg [7:0] clk_count = {8{1'b0}};
    // And clock enable based on the prescaler.
    wire clk_ce = (clk_prescale == clk_count);

    // And second, a clock state counter.
    reg [2:0] clk_state_count = {3{1'b0}};
    wire CLK_STATE_IS_OUTPUT = (clk_state_count[1:0] == CLK_STATE_OUTPUT);
    wire CLK_STATE_IS_HIGH = (clk_state_count[1:0] == CLK_STATE_HIGH);
    wire CLK_STATE_IS_CAPTURE = (clk_state_count[1:0] == CLK_STATE_CAPTURE);
    wire CLK_STATE_IS_DONE = (clk_state_count[2]);
    
    reg [NUM_DEVICES-1:0] enable_interface = {NUM_DEVICES{1'b0}};
    reg [NUM_DEVICES-1:0] disable_tristate = {NUM_DEVICES{1'b0}};

    // GPIOs. We have GPIOs here to deal with stuff like chip selects
    // and latch enables and who knows what else.
    reg [NUM_GPIO-1:0] gpio_tristate = {NUM_GPIO{1'b0}};
    reg [NUM_GPIO-1:0] gpio_output_reg = {NUM_GPIO{1'b0}};
    wire [NUM_GPIO-1:0] gpio_input;
    reg [NUM_GPIO-1:0] gpio_input_reg = {NUM_GPIO{1'b0}};;    
    
    generate
        genvar g;
        for (g=0;g<NUM_GPIO;g=g+1) begin : GPIO_LOOP
            // friggin' let Xilinx figure out what to do with it
            if (INTERNAL_GPIO[g]) begin : INT
                assign DEV_GPIO[g] = (gpio_tristate[g]) ? 
                    1'bZ : gpio_output_reg[g] ^ INVERT_GPIO[g];
                assign gpio_input[g] = DEV_GPIO;
            end else begin : IOBUF
                IOBUF gpio_iobuf(.IO(DEV_GPIO[g]),
                                 .I(gpio_output_reg[g] ^ INVERT_GPIO[g]),
                                 .O(gpio_input[g]),
                                 .T(gpio_tristate[g]));
            end
        end
    endgenerate
        
    reg sequence_running = 0;
    reg enable_sequence = 0;
    reg reverse_bitorder = 0;
    reg [2:0] nbit_count = {3{1'b0}};
    reg [2:0] nbit_count_max = {3{1'b0}};
    wire nbit_count_reached = nbit_count == nbit_count_max;
    reg [7:0] din_reg = {8{1'b0}};
    reg [7:0] dout_reg = {8{1'b0}};
    reg [7:0] aux_out_reg = {8{1'b0}};
    
    wire [31:0] module_config_register =
        { {16{1'b0}}, disable_tristate, clk_prescale };

    wire [31:0] device_config_register =
        { gpio_output_reg,
          gpio_input,
          gpio_tristate,
          enable_interface };
    
    wire [31:0] data_register =
        { sequence_running, enable_sequence, reverse_bitorder, 2'b00, nbit_count_max,
          dout_reg, aux_out_reg, din_reg };

    wire [31:0] register_mux[3:0];
    assign register_mux[0] = module_config_register;
    assign register_mux[1] = device_config_register;
    assign register_mux[2] = data_register;
    assign register_mux[3] = register_mux[1];
    reg [31:0] dat_out_ff = {32{1'b0}};
    reg ack_ff = 0;

    // Common stuff!
    always @(posedge clk) begin : LOGIC
        // we always ack immediately after an enable
        ack_ff <= en_i;
        if (en_i && !wr_i) dat_out_ff <= register_mux[address_i];
        if (en_i && ack_o && wr_i && (address_i == 0)) begin
            if (wstrb_i[0]) clk_prescale <= dat_i[7:0];
            if (wstrb_i[1]) disable_tristate <= dat_i[15:8];
        end
        if (en_i && ack_o && wr_i && (address_i == 1)) begin
            if (wstrb_i[0]) enable_interface <= dat_i[7:0];
            if (wstrb_i[1]) gpio_tristate <= dat_i[8 +: NUM_GPIO];
            if (wstrb_i[3]) gpio_output_reg <= dat_i[24 +: NUM_GPIO];
        end
        gpio_input_reg <= gpio_input;
    
        // This makes it go
        // 0,1,2,3,4,1,2,3,4,1,2,3,4,etc.        
        // Gets the count right.
        if (sequence_running) begin
            if (clk_ce) clk_state_count <= clk_state_count[1:0] + 1;
        end else clk_state_count <= {3{1'b0}};     
    
        if (rst) begin
            reverse_bitorder <= 1'b0;
            enable_sequence <= 1'b0;
            nbit_count_max <= {3{1'b0}};
            din_reg <= {8{1'b0}};
            aux_out_reg <= {8{1'b0}};
        end else if (en_i && ack_o && wr_i && (address_i == 2)) begin
            // MSB is control
            if (wstrb_i[3]) begin
                reverse_bitorder <= dat_i[29];
                enable_sequence <= dat_i[30];
                nbit_count_max <= dat_i[24 +: 3];
            end
            // LSB is data
            if (wstrb_i[0]) begin
                if ((wstrb_i[3] && !dat_i[29]) ||
                    (!wstrb_i[3] && !reverse_bitorder)) begin
                    // straight bitorder
                    din_reg <= dat_i[0 +: 8];
                end else begin
                    // reverse bitorder
                    din_reg[0] <= dat_i[7];
                    din_reg[1] <= dat_i[6];
                    din_reg[2] <= dat_i[5];
                    din_reg[3] <= dat_i[4];
                    din_reg[4] <= dat_i[3];
                    din_reg[5] <= dat_i[2];
                    din_reg[6] <= dat_i[1];
                    din_reg[7] <= dat_i[0];
                end
            end
            // bits [15:8] are aux: no reversing
            if (wstrb_i[1]) begin
                aux_out_reg <= dat_i[8 +: 8];
            end
        end
        
        if (nbit_count_reached && clk_ce && CLK_STATE_IS_DONE) 
            sequence_running <= 0;
        else if (en_i && ack_o && wr_i && ((!wstrb_i[3] && enable_sequence) || (wstrb_i[3] && dat_i[30])))
            sequence_running <= 1;

        // Prescaler
        if (sequence_running) begin
            if (clk_ce) clk_count <= {8{1'b0}};
            else clk_count <= clk_count + 1;
        end else begin
            clk_count <= {8{1'b0}};
        end
        
        // Bit counter.
        if (sequence_running) begin
            if (clk_ce && CLK_STATE_IS_DONE) nbit_count <= nbit_count + 1;
        end else nbit_count <= {3{1'b0}};        
    end
    // Device loop!
    generate
        genvar d;
        for (d=0;d<NUM_DEVICES;d=d+1) begin : DEV
            // Need to figure out if these are real (pack into IOBs)
            // or purely internal. Can't just let the implementation
            // figure out if it's connected or not because the IOB
            // attribute also effectively acts as KEEP and you end
            // up with a dangling register that it complains about.
            
            localparam CLK_IOB = (USE_CLK[d]) ? "TRUE" : "FALSE";        
            localparam DIN_IOB = (USE_DIN[d]) ? "TRUE" : "FALSE";
            localparam DOUT_IOB = (USE_DOUT[d]) ? "TRUE" : "FALSE";
            localparam AUX_OUT_IOB = (USE_AUX_OUT[d]) ? "TRUE" : "FALSE";

            (* IOB = CLK_IOB *)
            reg clk_ff = 0;
            (* IOB = DIN_IOB *)
            reg din_ff = 0;
            (* IOB = DOUT_IOB *)
            reg dout_ff = 0;
            (* IOB = AUX_OUT_IOB *)
            reg aux_out_ff = 0;

            always @(posedge clk) begin : CLK_REG_LOGIC
                if (enable_interface[d]) begin
                    if (clk_ce) begin
                        if (CLK_STATE_IS_HIGH) clk_ff <= 1'b1;
                        else if (CLK_STATE_IS_DONE) clk_ff <= 1'b0;
                     end
                end else begin
                    clk_ff <= 1'b0;
                end
            end
            // If these are real, we optionally tristate them when not in use.
            if (USE_CLK[d]) begin : CLK_TRIS
                assign DEV_CLK[d] = (enable_interface[d] || disable_tristate[d]) ?
                                    clk_ff : 1'bZ;
            end else begin : CLK_INTERNAL
                assign DEV_CLK[d] = clk_ff;
            end
                                                
            always @(posedge clk) begin : DIN_REG_LOGIC
                if (enable_interface[d]) begin
                    if (clk_ce && CLK_STATE_IS_OUTPUT) din_ff <= din_reg[nbit_count];
                end else begin
                    din_ff <= 1'b0;
                end
            end
            if (USE_DIN[d]) begin : DIN_TRIS
                assign DEV_DIN[d] = (enable_interface[d] || disable_tristate[d]) ?
                                    din_ff : 1'bZ;
            end else begin : DIN_INTERNAL
                assign DEV_DIN[d] = din_ff;
            end
            
            always @(posedge clk) begin : AUX_OUT_REG_LOGIC                                
                if (enable_interface[d]) begin
                    if (clk_ce && CLK_STATE_IS_OUTPUT) aux_out_ff <= aux_out_reg[nbit_count];
                end else begin
                    aux_out_ff <= 1'b0;
                end
            end
            if (USE_AUX_OUT[d]) begin : AUX_OUT_TRIS
                assign DEV_AUX_OUT[d] = (enable_interface[d] || disable_tristate[d]) ? 
                                        aux_out_ff : 1'bZ;
            end else begin : AUX_OUT_INTERNAL
                assign DEV_AUX_OUT[d] = aux_out_ff;
            end
            
            // DOUT happens in two steps: first, capture at CLK_STATE_IS_CAPTURE
            // then transfer to the data input shift register at CLK_STATE_IS_DONE
            always @(posedge clk) begin : DOUT_REG_LOGIC
                if (enable_interface[d]) begin
                    if (clk_ce && CLK_STATE_IS_CAPTURE) dout_ff <= DEV_DOUT[d];
                    if (clk_ce && CLK_STATE_IS_DONE) dout_reg[nbit_count] <= dout_ff;
                end
            end
        end // end for (d=0;d<NUM_DEVICES;d=d+1)            
    endgenerate    
    
    assign ack_o = ack_ff;
    assign dat_o = dat_out_ff;
    
endmodule