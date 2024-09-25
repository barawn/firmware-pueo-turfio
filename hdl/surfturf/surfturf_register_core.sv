`timescale 1ns / 1ps
`include "interfaces.vh"
`include "rackbus.vh"
// This might end up being temporary, I don't know.
// The fw_ path needs to be spliced with the mode1_ data as well,
// and it might need to be spliced with actual fw_ data from
// Aurora.
// But I need to be able to Test Stuff Now, so this is what it is.
module surfturf_register_core #(parameter WB_CLK_TYPE = "NONE")(
        input wb_clk_i,
        input wb_rst_i,
        // 10 bit interface, taking 0x400-0x7FF.
        // we likely won't need anywhere NEAR that
        `TARGET_NAMED_PORTS_WB_IF(wb_ , 10, 32),
        input sysclk_i,
        // FW update output port stuff
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( fw_ , 8),
        output fw_mark_o,
        input fw_marked_i,
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( runcmd_ , `RACKBUS_RUNCMD_BITS ),
        `HOST_NAMED_PORTS_AXI4S_MIN_IF( trig_ , `RACKBUS_TRIG_BITS )       
    );
    
    // register 0: control and FIFO status (no FIFOs for runcmd/trig!)
    // register 1: fwupdate register (32-bits, reshaped to 8 bits in sysclk domain
    // register 2: runcmd register (only 2 bits)
    // register 3: trigger register (only 15 bits)
    localparam [3:0] CONTROL_ADDR = 4'h0;
    localparam [3:0] FWUPDATE_ADDR = 4'h4;
    localparam [3:0] RUNCMD_ADDR = 4'h8;
    localparam [3:0] TRIG_ADDR = 4'hC;
    
    // capture in wb clk and hold it: it's flag-synced over to
    // sysclk, so we can just make a datapath only delay to the hold register
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [`RACKBUS_RUNCMD_BITS-1:0] runcmd_holding_reg = {`RACKBUS_RUNCMD_BITS{1'b0}};
    (* CUSTOM_CC_SRC = "SYSCLK" *)
    reg runcmd_holding_valid = 0;
    wire runcmd_is_valid_wbclk = (wb_cyc_i && wb_stb_i && wb_ack_o && (wb_adr_i[3:0] == RUNCMD_ADDR) && wb_we_i && wb_sel_i[0]);
    wire runcmd_is_valid_sysclk;
    (* CUSTOM_CC_DST = WB_CLK_TYPE, ASYNC_REG = "TRUE" *)
    reg [1:0] runcmd_holding_valid_wbclk = {2{1'b0}};

    // same as above
    (* CUSTOM_CC_SRC = WB_CLK_TYPE *)
    reg [`RACKBUS_TRIG_BITS-1:0] trig_holding_reg = {`RACKBUS_TRIG_BITS{1'b0}};
    (* CUSTOM_CC_SRC = "SYSCLK" *)
    reg trig_holding_valid = 0;
    wire trig_is_valid_wbclk = (wb_cyc_i && wb_stb_i && wb_ack_o && (wb_adr_i[3:0] == TRIG_ADDR) && wb_we_i && (wb_sel_i[0] && wb_sel_i[1]));
    wire trig_is_valid_sysclk;
    (* CUSTOM_CC_DST = WB_CLK_TYPE, ASYNC_REG = "TRUE" *)
    reg [1:0] trig_holding_valid_wbclk = {2{1'b0}};
    
    // fwupdate uses a real FIFO for now
    wire fw_write = (wb_cyc_i && wb_stb_i && wb_ack_o && (wb_adr_i[3:0] == FWUPDATE_ADDR) && wb_we_i);
    wire fw_empty;
    (* CUSTOM_CC_SRC = "SYSCLK" *)
    reg fw_empty_sysclk = 0;
    (* CUSTOM_CC_DST = WB_CLK_TYPE, ASYNC_REG = "TRUE" *)
    reg [1:0] fw_empty_wbclk = {2{1'b0}};
    // mark we make a bit more complicated here: there are basically paired registers here
    // if something goes wrong (like you write to this when sysclk is not running)
    // writing again will fix it.
    wire fw_do_mark_wbclk = (wb_cyc_i && wb_stb_i && wb_ack_o && (wb_adr_i[3:0] == CONTROL_ADDR) && wb_we_i && wb_dat_i[8] && wb_sel_i[1]);
    wire fw_do_mark_sysclk;
    reg fw_mark_wbclk = 0;
    reg fw_mark_sysclk = 0;
    wire fw_marked_sysclk = fw_mark_o && fw_marked_i;
    wire fw_marked_wbclk;
    flag_sync u_mark_sync(.in_clkA(fw_do_mark_wbclk),.out_clkB(fw_do_mark_sysclk),
                            .clkA(wb_clk_i),.clkB(sysclk_i));
    flag_sync u_marked_sync(.in_clkA(fw_marked_sysclk),.out_clkB(fw_marked_wbclk),
                              .clkA(sysclk_i),.clkB(wb_clk_i));    

    reg ack = 0;
    reg fwupdate_fifo_reset = 0;
    
    assign wb_ack_o = ack && wb_cyc_i;
    // I don't hook up full here because we know how much to write:
    // you get 1024 integers to write, period, then you check until empty.
    // we can speed this up in the future by letting fwupdate data be the stuff
    // that comes from the TURF Aurora directory and implementing flow control.
    // then the TURF side can buffer a lot more and blast it out.    
    // note that you can mask off SURFs by just not putting them in update mode.
    fwupdate_fifo u_fifo(.wr_clk(wb_clk_i),
                         .rd_clk(sysclk_i),
                         .rst(fwupdate_fifo_reset),
                         .din(wb_dat_i),
                         .wr_en(fw_write),
                         .empty(fw_empty),
                         .dout(fw_tdata),
                         .valid(fw_tvalid),
                         .rd_en(fw_tvalid && fw_tready));

    flag_sync u_runcmd_valid(.in_clkA(runcmd_is_valid_wbclk),.out_clkB(runcmd_is_valid_sysclk),
                             .clkA(wb_clk_i),.clkB(sysclk_i));
    flag_sync u_trig_valid(.in_clkA(trig_is_valid_wbclk),.out_clkB(trig_is_valid_sysclk),
                           .clkA(wb_clk_i),.clkB(sysclk_i));                             

    always @(posedge sysclk_i) begin
        if (runcmd_tready) runcmd_holding_valid <= 1'b0;
        else if (runcmd_is_valid_sysclk) runcmd_holding_valid <= 1'b1;
        
        if (trig_tready) trig_holding_valid <= 1'b0;
        else if (trig_is_valid_sysclk) trig_holding_valid <= 1'b1;
        
        fw_empty_sysclk <= fw_empty;
        
        if (fw_do_mark_sysclk) fw_mark_sysclk <= 1;
        else if (fw_marked_i) fw_mark_sysclk <= 0;
    end
    
    always @(posedge wb_clk_i) begin        
        if (fw_do_mark_wbclk) fw_mark_wbclk <= 1;
        else if (fw_marked_wbclk) fw_mark_wbclk <= 0;

        fw_empty_wbclk <= {fw_empty_wbclk[0], fw_empty_sysclk};

        ack <= wb_cyc_i && wb_stb_i;
        
        if (wb_cyc_i && wb_stb_i && wb_we_i && wb_adr_i[3:0] == CONTROL_ADDR && wb_sel_i[0])
            fwupdate_fifo_reset <= wb_dat_i[0];

        // this is probably batshit stupid: it won't stay set that long so checking if it's zero
        // will probably just get you zero right away        
        runcmd_holding_valid_wbclk <= { runcmd_holding_valid_wbclk[0], runcmd_holding_valid };
        trig_holding_valid_wbclk <= { trig_holding_valid_wbclk[0], trig_holding_valid };
        
        if (runcmd_is_valid_wbclk)
            runcmd_holding_reg <= wb_dat_i[0 +: `RACKBUS_RUNCMD_BITS];
        if (trig_is_valid_wbclk)
            trig_holding_reg <= wb_dat_i[0 + `RACKBUS_TRIG_BITS];                                
    end
    
    assign fw_mark_o = fw_mark_sysclk;
    
    assign runcmd_tvalid = runcmd_holding_valid;
    assign runcmd_tdata = runcmd_holding_reg;
    
    assign trig_tvalid = trig_holding_valid;
    assign trig_tdata = trig_holding_reg;
    
    assign wb_err_o = 1'b0;
    assign wb_rty_o = 1'b0;
    assign wb_dat_o = { {23{1'b0}}, fw_mark_wbclk, {4{1'b0}}, !trig_holding_valid_wbclk[1], !runcmd_holding_valid_wbclk[1], fw_empty_wbclk[1], fwupdate_fifo_reset };
    
endmodule
