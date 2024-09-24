`timescale 1ns / 1ps
`include "rackbus.vh"
`include "interfaces.vh"
// Commands from the TURF need to get spliced in with commands
// from the TURFIO. This happens combinatorically.
//
// THIS MODULE NEEDS TO USE THE MACROS ABOVE
// DO WE NEED TO HAVE A FAKEITY-FAKE-FAKE SYNC FOR DEBUGGING??
module turfio_cmd_splice(
        input sysclk_i,
        input sync_i,
        input [31:0] command_i,
        input        command_valid_i,
        // TURFIO streams
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( mode1_ , 8 ),
        input [1:0] mode1_tuser,
        // these come from the surfturf wrapper
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( tfio_fw_ , 8 ),
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( tfio_runcmd_ , `RACKBUS_RUNCMD_BITS),
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( tfio_trig_ , `RACKBUS_TRIG_BITS ),
        // INPUT FLAG FOR FAKEYFAKEY PPS
        input tfio_pps_i,
        input use_tfio_pps_i,
        output [31:0] spliced_o
    );    
    parameter DEBUG = "TRUE";

    reg [2:0] command_phase = {3{1'b0}};
    
    reg tfio_fw_ack = 0;
    reg mode1_ack = 0;
    reg tfio_runcmd_ack = 0;
    reg tfio_trig_ack = 0;
    reg command_capture = 0;
    
    reg tfio_pps_seen = 0;
    wire tfio_pps = (tfio_pps_i || tfio_pps_seen);
    wire turf_mode1valid = (`RACKBUS_IGNORE(command_i) || (`RACKBUS_MODE1TYPE( command_i ) == `RACKBUS_MODE1_SPECIAL && `RACKBUS_MODE1DATA( command_i ) == `RACKBUS_MODE1_NOOP ));
    wire total_ignore = `RACKBUS_IGNORE(command_i) && !mode1_tvalid && !tfio_runcmd_tvalid && !tfio_fw_tvalid;
    // splice turfio and mode1 path
    wire [7:0] mode1data = (mode1_tvalid && !turf_mode1valid) ? mode1_tdata : `RACKBUS_MODE1DATA(command_i);
    wire [1:0] mode1type = (mode1_tvalid && !turf_mode1valid) ? mode1_tuser : `RACKBUS_MODE1TYPE(command_i);
    wire mode1valid = mode1_tvalid || turf_mode1valid;
    // LOWEST priority is tfio fw, update it separately
    wire [7:0] full_mode1data = (tfio_fw_tvalid && !mode1valid) ? tfio_fw_tdata : mode1data;
    wire [1:0] full_mode1type = (tfio_fw_tvalid && !mode1valid) ? 2'b11 : mode1type;

    wire [`RACKBUS_RUNCMD_BITS-1:0] runcmd = (tfio_runcmd_tvalid && `RACKBUS_IGNORE(command_i)) ? tfio_runcmd_tdata : `RACKBUS_RUNCMD(command_i);
    wire [`RACKBUS_TRIG_BITS-1:0] trig = (tfio_trig_tvalid && !`RACKBUS_TRIG_VALID(command_i)) ? tfio_trig_tdata : `RACKBUS_TRIG(command_i);
    wire trig_valid = `RACKBUS_TRIG_VALID(command_i) || tfio_trig_tvalid;
    wire pps = (use_tfio_pps_i) ? tfio_pps : `RACKBUS_PPS(command_i);
    
    assign spliced_o = `RACKBUS_PACK(   total_ignore,
                                        pps,
                                        runcmd,
                                        full_mode1type,
                                        full_mode1data,
                                        trig_valid,
                                        trig );
            
    always @(posedge sysclk_i) begin
        if (command_capture) tfio_pps_seen <= 1'b0;
        else if (tfio_pps) tfio_pps_seen <= 1'b1;
    
        if (sync_i) command_phase <= 3'h1;
        else command_phase <= command_phase + 1;
        
        // we want command_capture high in command_phase 7 so
        // go high in command phase 6
        // god this should go in a header file somewhere
        command_capture <= (command_phase == 6);
        
        mode1_ack <= mode1_tvalid && (command_capture && (!command_valid_i || !turf_mode1valid));
        tfio_fw_ack <= tfio_fw_tvalid && (command_capture && (!command_valid_i || !turf_mode1valid || !mode1_tvalid));
        tfio_runcmd_ack <= tfio_runcmd_tvalid && (command_capture && (!command_valid_i || `RACKBUS_IGNORE(command_i)));
        tfio_trig_ack <= tfio_trig_tvalid && (command_capture && (!command_valid_i || `RACKBUS_IGNORE(command_i)));        
    end
    
    generate
        if (DEBUG == "TRUE") begin : ILA
            // sigh, we need to recapture splice here because it's cross-clock.
            (* CUSTOM_CC_DST = "SYSCLK" *)
            reg [31:0] dbg_splice = {32{1'b0}};
            always @(posedge sysclk_i) begin : DSL
                dbg_splice <= spliced_o;
            end                
            turfio_cmd_splice_ila u_ila(.clk(sysclk_i),
                                        .probe0( command_i),
                                        .probe1( command_valid_i ),
                                        .probe2( dbg_splice ));
        end
    endgenerate        

    assign mode1_tready = mode1_ack;
    assign tfio_runcmd_tready = tfio_runcmd_ack;
    assign tfio_trig_tready = tfio_trig_ack;
    assign tfio_fw_tready = tfio_fw_ack;
        
endmodule
