# This script contains a bunch of clock-crossing
# path definitions that Xilinx can't handle easily
# in an XDC file. It gets auto-loaded at implementation.

# Yes, the massive use of 10 ns is not correct but the
# actual static value's much larger and 10 ns results in
# "reasonably close but not constraining".

# grab ALL the dumb clockmon regs
set clockmon_level_regs [ get_cells -hier -filter {NAME =~ *u_clockmon/*clk_32x_level_reg*} ]
set clockmon_cc_regs [ get_cells -hier -filter {NAME =~ *u_clockmon/*level_cdc_ff1_reg*}]
set clockmon_run_reset_regs [ get_cells -hier -filter {NAME =~ *u_clockmon/clk_running_reset_reg*}]
set clockmon_run_regs [get_cells -hier -filter {NAME=~ *u_clockmon/*u_clkmon*}]
set clockmon_run_cc_regs [get_cells -hier -filter {NAME=~ *u_clockmon/clk_running_status_cdc1_reg*}]
set_max_delay -datapath_only -from $clockmon_level_regs -to $clockmon_cc_regs 10.000
set_max_delay -datapath_only -from $clockmon_run_reset_regs -to $clockmon_run_regs 10.000
set_max_delay -datapath_only -from $clockmon_run_regs -to $clockmon_run_cc_regs 10.000

# the TURF module has a bajillion clock-crosses to deal with. This is our first set...
set wb_static_regs [get_cells -hier -filter {NAME=~ *u_turf/u_core/*static_reg*}]
set wb_static_targets [get_cells -hier -filter {NAME =~ *u_turf/u_turfcin/u_cin_idelay*}]
lappend wb_static_targets [get_cells -hier -filter {NAME=~ *u_turf/u_core/u_cin_biterr/u_dsp}]
lappend wb_static_targets [get_cells -hier -filter {NAME=~ *u_turf/u_cin_sync/cin_capture*}]
lappend wb_static_targets [get_cells -hier -filter {NAME=~ *u_turf/u_turfcin/u_cin_iserdes*}]
set_max_delay -datapath_only -from $wb_static_regs -to $wb_static_targets 10.000

set biterr_count_rxclk [get_cells -hier -filter {NAME=~ *u_turf/u_core/u_cin_biterr/u_dsp}]
set biterr_count_wbclk [get_cells -hier -filter {NAME=~ *u_turf/u_core/bit_error_count_wbclk_reg*}]
set_max_delay -datapath_only -from $biterr_count_rxclk -to $biterr_count_wbclk 10.000

set wb_dat_regs [get_cells -hier -filter {NAME=~ *u_turf/u_core/dat_reg_reg*}]
set wb_dat_sources [get_cells -hier -filter {NAME=~ *u_turf/u_cin_sync/cin_capture*}]
lappend wb_dat_sources [get_cells -hier -filter {NAME=~ *u_turf/u_turfcin/u_cin_idelay*}]
set_max_delay -datapath_only -from $wb_dat_sources -to $wb_dat_regs 10.000

# RXCLK/SYSCLK registers. Here we set a *min* delay. I should probably change this
# and just set them up in an RLOC with some distance from each other. This does what
# I want but it's not great because it still thinks it has to like, get from sysclk
# to rxclk in 2.4 ns (which is *not* what I want, it's the *opposite* of what I want)
set rxsys_xfr_src_regs [get_cells -hier -filter {CUSTOM_SYSCLK_SOURCE=="TRUE"}]
set rxsys_xfr_tgt_regs [get_cells -hier -filter {CUSTOM_SYSCLK_TARGET=="TRUE"}]
set_min_delay -from $rxsys_xfr_src_regs -to $rxsys_xfr_tgt_regs 0.0

# ignore the properly-tagged FROM_WBCLK and TO_RXCLK clock-crosses.
set custom_cc_from_wbclk [get_cells -hier -filter {CUSTOM_CC=="FROM_WBCLK"}]
set custom_cc_to_rxclk [get_cells -hier -filter {CUSTOM_CC=="TO_RXCLK"}]
set_max_delay -datapath_only -from $custom_cc_from_wbclk -to $custom_cc_to_rxclk 10.000
