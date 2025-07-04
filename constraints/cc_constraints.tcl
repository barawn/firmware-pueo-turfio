# DUMBASS TESTING

set we_are_synthesis [info exists are_we_synthesis]
puts "we are synthesis: $we_are_synthesis"

######## CONVENIENCE FUNCTIONS
# These all have escape clauses because clocks sometimes don't exist in the elaboration/synthesis
# steps.

proc set_cc_paths { srcClk dstClk ctlist } {
    if {$srcClk eq ""} {
        puts "set_cc_paths: No source clock: returning."
        return
    }
    if {$dstClk eq ""} {
        puts "set_cc_paths: No destination clock: returning."
        return
    }
    array set ctypes $ctlist
    set srcType $ctypes($srcClk)
    set dstType $ctypes($dstClk)
    set maxTime [get_property PERIOD $srcClk]
    set srcRegs [get_cells -hier -filter "CUSTOM_CC_SRC == $srcType"]
    set dstRegs [get_cells -hier -filter "CUSTOM_CC_DST == $dstType"]
    set_max_delay -datapath_only -from $srcRegs -to $dstRegs $maxTime
}

proc set_gray_paths { srcClk dstClk ctlist } {
    if {$srcClk eq ""} {
        puts "set_gray_paths: No source clock: returning."
        return
    }
    if {$dstClk eq ""} {
        puts "set_gray_paths: No destination clock: returning."
        return
    }
    array set ctypes $ctlist
    set maxTime [get_property PERIOD $srcClk]
    set maxSkew [expr min([get_property PERIOD $srcClk], [get_property PERIOD $dstClk])]
    set srcRegs [get_cells -hier -filter "CUSTOM_GRAY_SRC == $ctypes($srcClk)"]
    set dstRegs [get_cells -hier -filter "CUSTOM_GRAY_DST == $ctypes($dstClk)"]
    set_max_delay -datapath_only -from $srcRegs -to $dstRegs $maxTime
    set_bus_skew -from $srcRegs -to $dstRegs $maxSkew
}

proc set_ignore_paths { srcClk dstClk ctlist } {
    if {$srcClk eq ""} {
        puts "set_ignore_paths: No source clock: returning."
        return
    }
    if {$dstClk eq ""} {
        puts "set_ignore_paths: No destination clock: returning."
        return
    }
    array set ctypes $ctlist
    set srcRegs [get_cells -hier -filter "CUSTOM_IGN_SRC == $ctypes($srcClk)"]
    set dstRegs [get_cells -hier -filter "CUSTOM_IGN_DST == $ctypes($dstClk)"]
    set_false_path -from $srcRegs -to $dstRegs
}

######## END CONVENIENCE FUNCTIONS

######## CLOCK DEFINITIONS

# PIN CLOCKS
set initclkin [create_clock -period 25.000 -name init_clock [get_ports -filter { NAME =~ "INITCLK" && DIRECTION == "IN" }]]
set clktypes($initclkin) INITCLKIN

# We're using the *nominal* clock offset here, hopefully it works.
set rxclk [create_clock -period 8.00 -waveform {6.4 2.4} -name rx_clock [get_ports -filter { NAME =~ "T_RXCLK_N" && DIRECTION == "IN" }]]
set clktypes($rxclk) RXCLK

set gtpclk [create_clock -period 8.00 -name gtp_clock [get_ports -filter { NAME =~ "F_LCLK_P" && DIRECTION == "IN" }]]
set clktypes($gtpclk) GTPCLK

# INTERNAL CLOCKS
set sysclk [get_clocks -of_objects [get_nets -hier -filter { NAME =~ "sysclk"}]]
set clktypes($sysclk) SYSCLK

set initclk [get_clocks -of_objects [get_nets -hier -filter { NAME =~ "init_clk"}]]
set clktypes($initclk) INITCLK

# grab the buffer, that'll always be safe
set userclk [get_clocks -of_objects [get_pins -hier -filter { NAME =~ "u_aurora/u_clocks/u_userclk_bufg/O" }]]
set clktypes($userclk) USERCLK

# create clktypelist variable to save
set clktypelist [array get clktypes]

###### END CLOCK DEFINITIONS

# THESE ARE ALL IMPLEMENTATION ONLY YOU JERKS

if { $we_are_synthesis != 1 } {

    # autoignore the flag_sync module guys
    set sync_flag_regs [get_cells -hier -filter {NAME =~ *FlagToggle_clkA_reg*}]
    set sync_sync_regs [get_cells -hier -filter {NAME =~ *SyncA_clkB_reg*}]
    set sync_syncB_regs [get_cells -hier -filter {NAME =~ *SyncB_clkA_reg*}]
    set_max_delay -datapath_only -from $sync_flag_regs -to $sync_sync_regs 10.000
    set_max_delay -datapath_only -from $sync_sync_regs -to $sync_syncB_regs 10.000
    
    # ignore the initclk/sysclk path. I need to make these automagic or something
    # no no no, let's *actually* find all of the damn paths
    #set_max_delay -datapath_only -from $sysclk -to $initclk 25.000
    #set_max_delay -datapath_only -from $initclk -to $sysclk 25.000
    
    # These pretty much get automatically satisfied. It should work because CLK_SYNC is definitively after the input clock,
    # and this adds a pretty significant delay.
    set_output_delay -clock $sysclk -min 0.7 [get_ports CLK_SYNC]
    set_output_delay -clock $sysclk -max 1.5   [get_ports CLK_SYNC]
    
    # grab ALL the dumb clockmon regs.
    set clockmon_level_regs [ get_cells -hier -filter {NAME =~ *u_clockmon/*clk_32x_level_reg*} ]
    set clockmon_cc_regs [ get_cells -hier -filter {NAME =~ *u_clockmon/*level_cdc_ff1_reg*}]
    set clockmon_run_reset_regs [ get_cells -hier -filter {NAME =~ *u_clockmon/clk_running_reset_reg*}]
    set clockmon_run_regs [get_cells -hier -filter {NAME=~ *u_clockmon/*u_clkmon*}]
    set clockmon_run_cc_regs [get_cells -hier -filter {NAME=~ *u_clockmon/clk_running_status_cdc1_reg*}]
    set clockmon_run_cc2_regs [get_cells -hier -filter {NAME=~ *u_clockmon/clk_running_status_cdc2_reg*}]
    set_max_delay -datapath_only -from $clockmon_level_regs -to $clockmon_cc_regs 10.000
    set_max_delay -datapath_only -from $clockmon_run_reset_regs -to $clockmon_run_regs 10.000
    set_max_delay -datapath_only -from $clockmon_run_regs -to $clockmon_run_cc_regs 10.000
    
    set live_regs [get_cells -hier -filter {NAME=~ "u_surfturf/u_st_core/*reg*"}]
    set_max_delay -datapath_only -from $clockmon_run_cc2_regs -to $live_regs 10.000
    
    # These all now get automatically set by the CUSTOM_CC_SRC/DST attributes.
    # the TURF module has a bajillion clock-crosses to deal with. This is our first set...
    #set wb_static_regs [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_core/*static_reg*}]
    #set wb_static_targets [get_cells -hier -filter {NAME =~ u_surfturf/*u_turf/u_turfcin/u_cin_idelay*}]
    #lappend wb_static_targets [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_core/u_cin_biterr/u_dsp}]
    #lappend wb_static_targets [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_cin_sync/cin_capture*}]
    #lappend wb_static_targets [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_turfcin/u_cin_iserdes*}]
    #set_max_delay -datapath_only -from $wb_static_regs -to $wb_static_targets 10.000
    
    # I really should add an optional CLKTYPE attribute to the DSP here to automate this
    #set biterr_count_rxclk [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_core/u_cin_biterr/u_dsp}]
    #set biterr_count_wbclk [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_core/bit_error_count_wbclk_reg*}]
    #set_max_delay -datapath_only -from $biterr_count_rxclk -to $biterr_count_wbclk 10.000
    
    #set wb_dat_regs [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_core/dat_reg_reg*}]
    #set wb_dat_sources [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_cin_sync/cin_capture*}]
    #lappend wb_dat_sources [get_cells -hier -filter {NAME=~ u_surfturf/*u_turf/u_turfcin/u_cin_idelay*}]
    #set_max_delay -datapath_only -from $wb_dat_sources -to $wb_dat_regs 10.000
    
    # RXCLK/SYSCLK registers. Here we set a *min* delay. I should probably change this
    # and just set them up in an RLOC with some distance from each other. This does what
    # I want but it's not great because it still thinks it has to like, get from sysclk
    # to rxclk in 2.4 ns (which is *not* what I want, it's the *opposite* of what I want)
    set rxsys_xfr_src_regs [get_cells -hier -filter {CUSTOM_SYSCLK_SOURCE=="TRUE"}]
    set rxsys_xfr_tgt_regs [get_cells -hier -filter {CUSTOM_SYSCLK_TARGET=="TRUE"}]
    if { [llength $rxsys_xfr_src_regs] != 0 } {
        if { [llength $rxsys_xfr_tgt_regs] != 0 } {
            # quiet is necessary here to shut up errors pre-implementation
            set_min_delay -quiet -from $rxsys_xfr_src_regs -to $rxsys_xfr_tgt_regs 0.0
        }
    }
    # These guys are properly tagged.
    set_cc_paths $initclk $rxclk $clktypelist
    set_cc_paths $rxclk $initclk $clktypelist
    
    set_cc_paths $initclk $sysclk $clktypelist
    set_cc_paths $sysclk $initclk $clktypelist
    
    set_cc_paths $userclk $initclk $clktypelist
    set_cc_paths $initclk $userclk $clktypelist
    
    set bitslip_src_regs [get_cells -hier -filter { CUSTOM_CC_SRC =~ "INITCLK"}]
    set bitslip_dbg_reg [get_cells -hier -filter { NAME =~ "u_surfturf/LP[0].TURF.u_turf/u_bitslip_sync/A_POS_POL.FlagToggle_clkA_reg" }]
    set_max_delay -quiet -datapath_only -from $bitslip_src_regs -to $bitslip_dbg_reg 10.00
}    

set_param iconstr.diffPairPulltype opposite

set hub [get_debug_cores dbg_hub -quiet]
if { [llength $hub] > 0 } {
    set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
    set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
    set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
    connect_debug_port dbg_hub/clk [get_nets u_clk200/inst/clk_out2_clk200_wiz]
} else {
    puts "skipping debug hub commands, not inserted yet"
}
    
