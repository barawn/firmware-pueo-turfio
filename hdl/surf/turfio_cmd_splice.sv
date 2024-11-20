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
        input        command_locked_i,
        // TURFIO streams
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( mode1_ , 8 ),
        input [1:0] mode1_tuser,
        input [2:0] mode1_tdest,
        // these come from the surfturf wrapper
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( tfio_fw_ , 8 ),
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( tfio_runcmd_ , `RACKBUS_RUNCMD_BITS),
        `TARGET_NAMED_PORTS_AXI4S_MIN_IF( tfio_trig_ , `RACKBUS_TRIG_BITS ),
        input tfio_fw_mark_i,
        output tfio_fw_marked_o,
        // INPUT FLAG FOR FAKEYFAKEY PPS
        input tfio_pps_i,
        input use_tfio_pps_i,
        // THIS NEEDS TO BE EXPANDED TO 7 TOTAL OUTPUTS!!
        output [31:0] spliced_o
    );    
    parameter DEBUG = "TRUE";

    reg [2:0] command_phase = {3{1'b0}};
    
    reg tfio_fw_ack = 0;
    reg mode1_ack = 0;
    reg tfio_runcmd_ack = 0;
    reg tfio_trig_ack = 0;
    reg command_capture = 0;
    reg command_precapture = 0;
    
    reg tfio_pps_seen = 0;
    wire tfio_pps = (tfio_pps_i || tfio_pps_seen);

    // okay: figuring everything out here isn't that easy
    // there are lots of ways for there to be no commands from the TURF.
    // NOTHING IS VALID, YOU CAN SPLICE ANYTHING:
    //    !command_locked_i - the interface isn't running, everything should come from TURFIO
    // NO COMMAND BITS ARE VALID, YOU CAN SPLICE RUNCMD/MODE1DATA
    //    `RACKBUS_IGNORE(command_i) - none of the top bits are valid
    // NO TRIGGER BITS ARE VALID, YOU CAN SPLICE TRIGGERS
    //    !`RACKBUS_TRIG_VALID(command_i) - none of the bottom bits are valid
    // NO RUNCMD BITS ARE VALID, YOU CAN SPLICE RUNCMDS
    //    `RACKBUS_RUNCMD(command_i) == `RACKBUS_RUNCMD_NOOP
    // NO MODE1DATA BITS ARE VALID, YOU CAN SPLICE MODE1DATA
    //    (`RACKBUS_MODE1TYPE(command_i) == `RACKBUS_MODE1_SPECIAL && `RACKBUS_MODE1DATA(command_i) == `RACKBUS_MODE1_NOOP)
    // so let's clean this up bit by bit
    
    // all the splices are combinatoric: the ack registers also need to handle splice priorities right.
    // MODE1DATA has 4 (!) possible inputs. From lowest-to-highest priority:
    // tfio_fw_tdata
    // tfio_fw_finish
    // mode1_tdata
    // TURF MODE1DATA    

    // MODE1 DATA IS HARD!
    // We actually capture it in an EARLIER clock phase and hold it. This is because if it's
    // NOT VALID, we need to set the data and type to MODE1_SPECIAL and MODE1_NOOP in case
    // RUNCMD is valid and we need ignore to be clear

    // NOTE NOTE NOTE NOTE NOTE NOTE NOTE:
    // THIS NEEDS TO BE EXPANDED TO DEAL WITH ADDRESSED MODE1 DATA!!!
    // WE NEED 7 SEPARATE HOLDING/TYPE REGISTERS: IF TDEST MATCHES THE ADDRESS, WE CAPTURE
    // IT, OTHERWISE WE SET TYPE/DATA TO SPECIAL/NOOP.
    // these aren't technically cross clock but WHATEVER
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg [7:0] mode1data_holding = {8{1'b0}};
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] mode1type_holding = {2{1'b0}};
    // note these do NOT need to be cross-clock, because the 
    reg       holding_mode1 = 0;
    reg       holding_fwu = 0;
    reg       holding_mark = 0;
    reg       mode1_ack = 0;
    reg       tfio_fw_ack = 0;
    reg       tfio_fw_marked = 0;
    // so here what happens is:
    // -> if command_precapture: if (mode1_tvalid) mode1data_holding <= mode1_tdata;
    //                           else if (tfio_fw_finish_i) mode1data_holding <= `RACKBUS_MODE1_MARK_FWU;
    //                           else if (tfio_fw_tvalid) mode1data_holding <= tfio_fw_tdata;
    //                           else mode1data_holding <= `RACKBUS_MODE1_NOOP;
    
    //                           if (mode1_tvalid) mode1type_holding <= mode1_tuser;
    //                           else if (tfio_fw_finish_i) mode1type_holding <= `RACKBUS_MODE1_SPECIAL;
    //                           else if (tfio_fw_tvalid) mode1type_holding <= `RACKBUS_MODE1_FWU;
    //                           else mode1type_holding <= `RACKBUS_MODE1_SPECIAL;
    //
    //                           holding_mode1 <= mode1_tvalid;
    //                           holding_finish <= tfio_fw_finish_i && !mode1_tvalid;
    //                           holding_fwu <= tfio_fw_tvalid && !mode1_tvalid && !tfio_fw_finish_i;
    //
    // Note that this updates all of the holding registers each time: if we don't use it,
    // and say mode1 data comes in valid, it'll just overwrite the FW data.
    // This is fine - we generate the tready based on
    // tfio_fw_ack <= (command_capture && holding_fwu && turf_mode1_invalid);
    // mode1_ack <= (command_capture && holding_mode1 && turf_mode1_invalid);
    // finish_ack <= (command_capture && holding_finish && turf_mode1_invalid);
    //
    // so if you assert tfio_fw_tvalid, tready (indicating complete) will only go
    // if the data actually goes out. if it gets overwritten in the holding register, it'll
    // just get recaptured the next time.
    
    // splicing the TURF mode1 data is then easy. note that mode1data_holding is always valid
    wire       turf_mode1_invalid = !command_locked_i ||
                                    `RACKBUS_IGNORE(command_i) || 
                                    (`RACKBUS_MODE1TYPE(command_i) != `RACKBUS_MODE1_SPECIAL) ||
                                    (`RACKBUS_MODE1DATA(command_i) != `RACKBUS_MODE1_NOOP);
    wire [7:0] mode1data = (turf_mode1_invalid) ? mode1data_holding : `RACKBUS_MODE1DATA(command_i);
    wire [1:0] mode1type = (turf_mode1_invalid) ? mode1type_holding : `RACKBUS_MODE1TYPE(command_i);

    // runcmd has the same issue, so we do the same thing, except it's a simpler setup
    (* CUSTOM_CC_DST = "SYSCLK" *)
    reg [1:0] runcmd_holding = {2{1'b0}};
    reg       holding_runcmd = 0;
    reg       runcmd_ack = 0;
    // if command_precapture:   if (tfio_runcmd_tvalid) runcmd_holding <= tfio_runcmd_tdata;
    //                          else runcmd_holding <= `RACKBUS_RUNCMD_NOOP;
    //                          holding_runcmd <= tfio_runcmd_tvalid;
    // runcmd_ack <= (command_capture && holding_runcmd);
    wire      turf_runcmd_invalid = !command_locked_i ||
                                    `RACKBUS_IGNORE(command_i) ||
                                    `RACKBUS_RUNCMD(command_i) == `RACKBUS_RUNCMD_NOOP;
    wire [1:0] runcmd = (turf_runcmd_invalid) ? runcmd_holding : `RACKBUS_RUNCMD(command_i);

    // now PPS splice
    wire turf_pps = `RACKBUS_PPS(command_i) && command_locked_i && !`RACKBUS_IGNORE(command_i);
    wire pps = (use_tfio_pps_i) ? tfio_pps : turf_pps;
    
    // this gets set if the TURFIO has *any* data to insert
    wire tfio_has_command_data = (holding_mode1 || holding_mark || holding_fwu || holding_runcmd || (tfio_pps && use_tfio_pps_i));

    // and this combines the ignores. Note that if the TURF sends all zeros, IGNORE will not be set,
    // but nothing will happen (since it generates MODE1_SPECIAL/MODE1_NOOP and RUNCMD_NOOP, plus no PPS.
    // but before the TURF command path is locked, IGNORE will always be set if no data.
    wire total_ignore = (`RACKBUS_IGNORE(command_i) || !command_locked_i) && !tfio_has_command_data;
        
    // trigger is shedloads easier because it's not split up. we can do it combinatorially.
    // this does mean we need to cross-clock it down below
    wire turf_trig_valid = command_locked_i && `RACKBUS_TRIG_VALID(command_i);
                        
    wire [`RACKBUS_TRIG_BITS-1:0] trig = turf_trig_valid ? `RACKBUS_TRIG(command_i) : tfio_trig_tdata;
    wire trig_valid = turf_trig_valid || tfio_trig_tvalid;
   
    assign spliced_o = `RACKBUS_PACK(   total_ignore,
                                        pps,
                                        runcmd,
                                        mode1type,
                                        mode1data,
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
        command_precapture <= (command_phase == 5);
        
        if (command_precapture) begin
            if (mode1_tvalid) mode1data_holding <= mode1_tdata;
            else if (tfio_fw_mark_i) mode1data_holding <= `RACKBUS_MODE1_MARK_FWU;
            else if (tfio_fw_tvalid) mode1data_holding <= tfio_fw_tdata;
            else mode1data_holding <= `RACKBUS_MODE1_NOOP;
            
            if (mode1_tvalid) mode1type_holding <= mode1_tuser;
            else if (tfio_fw_mark_i) mode1type_holding <= `RACKBUS_MODE1_SPECIAL;
            else if (tfio_fw_tvalid) mode1type_holding <= `RACKBUS_MODE1_FWU;
            else mode1type_holding <= `RACKBUS_MODE1_SPECIAL;
            
            holding_mode1 <= mode1_tvalid;
            holding_mark <= tfio_fw_mark_i && !mode1_tvalid;
            holding_fwu <= tfio_fw_tvalid && !tfio_fw_mark_i && !mode1_tvalid;
            
            if (tfio_runcmd_tvalid) runcmd_holding <= tfio_runcmd_tdata;
            else runcmd_holding <= `RACKBUS_RUNCMD_NOOP;
            
            holding_runcmd <= tfio_runcmd_tvalid;
        end

        tfio_fw_ack <= (command_capture && holding_fwu && turf_mode1_invalid);
        tfio_fw_marked <= (command_capture && holding_mark && turf_mode1_invalid);
        mode1_ack <= (command_capture && holding_mode1 && turf_mode1_invalid);
        runcmd_ack <= (command_capture && holding_runcmd && turf_runcmd_invalid);        
    end
    
    generate
        if (DEBUG == "TRUE") begin : ILA
            // this is technically cross-clock, since the data path
            // for trigger comes from wb clock - but it's static
            // when the condition causes it to splice in, so we don't care.
            (* CUSTOM_CC_DST = "SYSCLK" *)
            reg [31:0] dbg_splice = {32{1'b0}};
            always @(posedge sysclk_i) begin : DBG
                dbg_splice <= spliced_o;
            end
            turfio_cmd_splice_ila u_ila(.clk(sysclk_i),
                                        .probe0( command_i),
                                        .probe1( command_valid_i ),
                                        .probe2( dbg_splice ),
                                        .probe3( command_phase ),
                                        .probe4( sync_i ));
        end
    endgenerate        

    assign mode1_tready = mode1_ack;
    assign tfio_runcmd_tready = tfio_runcmd_ack;
    assign tfio_trig_tready = tfio_trig_ack;
    assign tfio_fw_tready = tfio_fw_ack;
    assign tfio_fw_marked_o = tfio_fw_marked;
        
endmodule
