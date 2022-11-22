# run off INTERNAL CLOCK for now
# reset
# divide 1-7 by 16 (7.8125M). Bypass 8 (defaults)
# Divide by 16 requires a divider value of 8.
# LMK input to output (bypass path) 
set lmkvio [get_hw_vios -of_objects [get_hw_devices xc7a35t_0] -filter { CELL_NAME=~"NS.u_lmkvio"}]
set lmkinput [get_hw_probes lmk_input -of_objects $lmkvio]
set lmkgo [get_hw_probes lmk_go -of_objects $lmkvio]

set_property OUTPUT_VALUE 80000000 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 00010100 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 00010101 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 00010102 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 00010103 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 00010104 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 00010105 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 00010106 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 00010107 $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo

set_property OUTPUT_VALUE 4800000E $lmkinput
commit_hw_vio $lmkinput
set_property OUTPUT_VALUE 1 $lmkgo
commit_hw_vio $lmkgo
set_property OUTPUT_VALUE 0 $lmkgo
commit_hw_vio $lmkgo


