`timescale 1ns / 1ps
// Incorporates the rackctl IOBs.
//
// Both the tristate and output FFs both act
// as fully-active flops, so we just take their
// inputs here.
// The input FF takes a CE, the monitor FF doesn't.
module rackctl_bidir_phy #(parameter INV=1'b0,
                           parameter USE_IDELAY = "FALSE",
                           parameter IDELAY_VALUE = 0)(
        input clk_i,
        input rack_tri_i,
        input rack_out_i,
        input rack_cein_i,
        output rack_in_o,
        output rack_mon_o,
        inout RACKCTL_P,
        inout RACKCTL_N
    );
    
    // proper polarity
    wire rackctl_in_true;
    // inverse polarity
    wire rackctl_in_inv;
    // to FF
    wire rackctl_in;
    // to mon FF
    wire rackctl_mon;
    
    (* IOB = "TRUE" *)
    reg rackctl_in_ff = 0;
    (* IOB = "TRUE" *)
    reg rackctl_mon_ff = 0;
    (* IOB = "TRUE" *)
    reg rackctl_out_ff = INV;
    (* IOB = "TRUE" *)
    reg tristate_rackctl = 0;
    
    always @(posedge clk_i) begin
        if (rack_cein_i) rackctl_in_ff <= rackctl_in;
        rackctl_mon_ff <= rackctl_mon;
        
        rackctl_out_ff <= INV ^ rack_out_i;
        tristate_rackctl <= rack_tri_i;
    end
    
    // sigh, we need to try an IDELAY I think
    
    generate
        if (USE_IDELAY == "TRUE") begin : ID
            IDELAYE2 #(.IDELAY_TYPE("FIXED"),
                       .DELAY_SRC("IDATAIN"),
                       .IDELAY_VALUE(IDELAY_VALUE))
                u_idelay(.IDATAIN(rackctl_in_true),
                         .DATAOUT(rackctl_in));
            IDELAYE2 #(.IDELAY_TYPE("FIXED"),
                       .DELAY_SRC("IDATAIN"),
                       .IDELAY_VALUE(IDELAY_VALUE))
                u_idelaymon(.IDATAIN(rackctl_in_inv),
                         .DATAOUT(rackctl_mon));
        end else begin : NID
            assign rackctl_in = rackctl_in_true;
            assign rackctl_mon = rackctl_in_inv;
        end
        if (INV == 1'b1) begin : IOINV
            IOBUFDS_DIFF_OUT u_iob(.I(rackctl_out_ff),.O(rackctl_in_inv),.OB(rackctl_in_true),.TM(tristate_rackctl),.TS(tristate_rackctl),
                                   .IO(RACKCTL_N),.IOB(RACKCTL_P));
        end else begin : IO
            IOBUFDS_DIFF_OUT u_iob(.I(rackctl_out_ff),.O(rackctl_in_true),.OB(rackctl_in_inv),.TM(tristate_rackctl),.TS(tristate_rackctl),
                                   .IO(RACKCTL_P),.IOB(RACKCTL_N));
        end    
    endgenerate    
    
    assign rack_in_o = rackctl_in_ff;
    assign rack_mon_o = rackctl_mon_ff;
    
endmodule
