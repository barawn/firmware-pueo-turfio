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
set wb_static_regs [get_cells -hier -filter {NAME=~ *u_turf/*static_reg*}]
set wb_static_targets [get_cells -hier -filter {NAME =~ *u_turf/u_cin_idelay*}]
lappend wb_static_targets [get_cells -hier -filter {NAME=~ *u_turf/u_cin_idelay*}]
lappend wb_static_targets [get_cells -hier -filter {NAME=~ *u_turf/u_rxclk_biterr/u_dsp}]
lappend wb_static_targets [get_cells -hier -filter {NAME=~ *u_turf/cin_parallel_capture_reg*}]
set_max_delay -datapath_only -from $wb_static_regs -to $wb_static_targets 10.000

set biterr_count_rxclk [get_cells -hier -filter {NAME=~ *u_turf/bit_error_count_reg*}]
set biterr_count_wbclk [get_cells -hier -filter {NAME=~ *u_turf/bit_error_count_wbclk_reg*}]
set_max_delay -datapath_only -from $biterr_count_rxclk -to $biterr_count_wbclk 10.000

set wb_dat_regs [get_cells -hier -filter {NAME=~ *u_turf/dat_reg_reg*}]
set cin_capture_regs [get_cells -hier -filter {NAME=~ *u_turf/cin_parallel_capture_reg*}]
set_max_delay -datapath_only -from $cin_capture_regs -to $wb_dat_regs 10.000
