`timescale 1ns / 1ps
`include "interfaces.vh"
// Wrapper for the general purpose shift register module for TURFIO.
module turfio_gen_shift_wrapper(
        input wb_clk_i,
        input wb_rst_i,
        `TARGET_NAMED_PORTS_WB_IF( wb_ , 12, 32),        
        // JTAG ports
        output TCTRL_B,
        output JTAG_OE,
        output TDI,
        input TDO,
        output TCK,
        output TMS,
        // I2C PORT ALSO IS CONTROLLABLE FROM HSK
        // NEVER USE THESE UNLESS THE HSK IS IN RESET!!
        output sda_in_o,
        output scl_in_o,
        input sda_t_i,
        input scl_t_i,
        inout F_SDA,
        inout F_SCL,
        // LMK ports
        output LMKCLK,
        output LMKDATA,
        output LMKLE,
        output LMKOE,
        // (external) SPI ports
        output SPI_CS_B,
        output SPI_MOSI,
        input SPI_MISO                        
    );
    
    parameter DEBUG = "TRUE";
    
    localparam DEV_JTAG = 0;
    localparam DEV_LMK = 1;
    localparam DEV_SPI = 2;
    
    localparam GPIO_TCTRL_B = 0;
    localparam GPIO_JTAG_OE = 1;
    localparam GPIO_LMKLE = 2;
    localparam GPIO_LMKOE = 3;
    localparam GPIO_SPI_CS_B = 4;
    
    // General shift register module.
    // This is used for LMK configuration, for JTAG, and for SPI flash.
    // Device 0 is JTAG, device 1 is LMK, device 2 is SPI flash.
    // GPIO 0 is JTAG TCTRL, 1 is JTAG OE, 2 is LMK LE, 3 is LMK OE, and 4 is SPI CS.
    // This means both GPIO1 and 4 are inverted (active low)
    // CLK 2 is unused, DOUT 1 is unused, and AUX_OUT 1 and 2 are unused.
    //
    // Note: the LMK sync output does not come from here, it's part of the
    // TURF interface.
    //
    
    //localparam NUM_GPIO = 5;
    // TEMPORARY
    localparam NUM_GPIO = 7;
    
    // General wires for connecting.
    wire [2:0] gen_cclk;
    wire [2:0] gen_din;
    wire [2:0] gen_dout;
    wire [2:0] gen_aux_out;
    wire [NUM_GPIO-1:0] gen_gpio_o;
    wire [NUM_GPIO-1:0] gen_gpio_t;    
    wire [NUM_GPIO-1:0] gen_gpio_i;
    
    assign gen_gpio_i[4:0] = {5{1'b0}};

    // TEMPORARY
    // gen_gpio_t[6:5] START OFF high by default (see below)
    // we combine the two tristate signals like a wire-or
    // so if EITHER of the tristates is low the output is low
    wire sda_tri = gen_gpio_t[5] && sda_t_i;
    wire scl_tri = gen_gpio_t[6] && scl_t_i;
    assign sda_in_o = gen_gpio_i[5];
    assign scl_in_o = gen_gpio_i[6];
    IOBUF u_sda(.IO(F_SDA),.I(gen_gpio_o[5]),.O(gen_gpio_i[5]),.T(sda_tri));
    IOBUF u_scl(.IO(F_SCL),.I(gen_gpio_o[6]),.O(gen_gpio_i[6]),.T(scl_tri));
    
    //localparam [NUM_GPIO-1:0] INVERT_GPIO = 5'b10010;
    localparam [NUM_GPIO-1:0] INVERT_GPIO = 7'b0010010;

    localparam [NUM_GPIO-1:0] GPIO_DEFAULT_TRI = (1 << 5) | (1 << 6) | (1 << GPIO_TCTRL_B);
    localparam [NUM_GPIO-1:0] GPIO_DEFAULT_OUT = (1 << GPIO_JTAG_OE);
    
    
    // DIN/DOUT IS FROM THE DEVICE POINT OF VIEW
    // DIN = DEVICE INPUT (output from us)
    // DOUT = DEVICE OUTPUT (input to us)
    gen_shift_if #(.DEBUG(DEBUG),
                   .NUM_DEVICES(3),
                   .USE_CLK(    8'b0000_0011),
                   .USE_DIN(    8'b0000_0111),
                   .USE_DOUT(   8'b0000_0101),
                   .USE_AUX_OUT(8'b0000_0001),
                   .NUM_GPIO(NUM_GPIO),
                   .GPIO_DEFAULT_TRI(GPIO_DEFAULT_TRI),
                   .GPIO_DEFAULT_OUT(GPIO_DEFAULT_OUT),
                   .INVERT_GPIO(INVERT_GPIO))
        u_gen_shift( .clk(wb_clk_i),
                     .rst(wb_rst_i),
                     .en_i(wb_cyc_i && wb_stb_i),
                     .wr_i(wb_we_i),
                     .wstrb_i(wb_sel_i),
                     .address_i(wb_adr_i[3:2]),
                     .dat_i(wb_dat_i),
                     .dat_o(wb_dat_o),
                     .ack_o(wb_ack_o),
                     .DEV_CLK(gen_cclk),
                     .DEV_DIN(gen_din),
                     .DEV_DOUT(gen_dout),
                     .DEV_AUX_OUT(gen_aux_out),
                     .dev_gpio_i( gen_gpio_i ),
                     .dev_gpio_o( gen_gpio_o ),
                     .dev_gpio_t( gen_gpio_t ));

    // Hook up CCLK. 
    STARTUPE2 u_startup(.KEYCLEARB(1'b1),
                        .CLK(1'b0),
                        .GSR(1'b0),
                        .GTS(1'b0),
                        .PACK(1'b0),
                        .USRCCLKO(gen_cclk[DEV_SPI]),
                        .USRCCLKTS(1'b0),
                        .USRDONEO(1'b1),
                        .USRDONETS(1'b0));    

    // JTAG
    assign TCK = gen_cclk[DEV_JTAG];
    assign TDI = gen_din[DEV_JTAG];
    assign TMS = gen_aux_out[DEV_JTAG];
    assign gen_dout[DEV_JTAG] = TDO;
    assign TCTRL_B = gen_gpio_t[GPIO_TCTRL_B] ? 1'bZ : gen_gpio_o[GPIO_TCTRL_B];
    assign JTAG_OE = gen_gpio_t[GPIO_JTAG_OE] ? 1'bZ : gen_gpio_o[GPIO_JTAG_OE];
    
    // LMK
    assign LMKCLK = gen_cclk[DEV_LMK];
    assign LMKDATA = gen_din[DEV_LMK];
    assign LMKLE = gen_gpio_t[GPIO_LMKLE] ? 1'bZ : gen_gpio_o[GPIO_LMKLE];
    assign LMKOE = gen_gpio_t[GPIO_LMKOE] ? 1'bZ : gen_gpio_o[GPIO_LMKOE];
    
    // SPI
    assign SPI_MOSI = gen_din[DEV_SPI];     // OUTPUT IS THIS
    assign gen_dout[DEV_SPI] = SPI_MISO;    // INPUT IS THIS
    assign SPI_CS_B = gen_gpio_t[GPIO_SPI_CS_B] ? 1'bZ : gen_gpio_o[GPIO_SPI_CS_B];

    wire csb_dbg = gen_gpio_t[GPIO_SPI_CS_B] || gen_gpio_o[GPIO_SPI_CS_B];
    wire clk_dbg = gen_cclk[DEV_SPI];
//    tgs_ila u_ila(.clk(wb_clk_i),
//                  .probe0(sda_in_o),
//                  .probe1(scl_in_o),
//                  .probe2(sda_tri),
//                  .probe3(scl_tri));
    
    // sigh nothing ever works
//    generate
//        if (DEBUG == "TRUE") begin : ILA
//            wire csb_dbg = gen_gpio_t[GPIO_SPI_CS_B] ? 1'b1 : gen_gpio_o[GPIO_SPI_CS_B];
//            tgs_ila u_ila(.clk(wb_clk_i),
//                          .probe0(SPI_MISO),
//                          .probe1(SPI_MOSI),
//                          .probe2(csb_dbg),
//                          .probe3(gen_cclk[DEV_SPI]));
//        end
//    endgenerate

    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
    
endmodule
