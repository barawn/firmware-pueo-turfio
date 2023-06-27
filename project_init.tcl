# utility function
proc get_repo_dir {} {
    set projdir [get_property DIRECTORY [current_project]]
    set projdirlist [ file split $projdir ]
    set basedirlist [ lreplace $projdirlist end end ]
    return [ file join {*}$basedirlist ]
}

# source utilities
source [file join [get_repo_dir] "verilog-library-barawn/tclbits/utility.tcl"]
# source repo control
source [file join [get_repo_dir] "verilog-library-barawn/tclbits/repo_files.tcl"]

# add include directories
add_include_dir [file join [get_repo_dir] "verilog-library-barawn/include"]
add_include_dir [file join [get_repo_dir] "include"]

# set pre-synthesis script
set_pre_synthesis_tcl [file join [get_repo_dir] "pre_synthesis.tcl"]

# set post-implementation init script
set_post_implementation_init_tcl [file join [get_repo_dir] "post_implementation_init.tcl"]

# And check if everything's loaded.
check_all
