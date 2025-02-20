# search_repo_dir finds the repo dir so long as we were called ANYWHERE
# in the project AND the project dir is called vivado_project
proc search_repo_dir {} {
    set projdir [get_property DIRECTORY [current_project]]
    set fullprojdir [file normalize $projdir]
    set projdirlist [ file split $fullprojdir ]
    set projindex [lsearch $projdirlist "vivado_project"]
    set basedirlist [lrange $projdirlist 0 [expr $projindex - 1]]
    return [ file join {*}$basedirlist ]
}

set projdir [search_repo_dir]
source [file join $projdir project_utility.tcl]

set curdir [pwd]
set ver [get_built_project_version]
puts "ver $ver"
set verstring [pretty_version $ver]
puts "verstring $verstring"
set topname [get_property TOP [current_design]]
set origbit [format "%s.bit" $topname]
set origltx [format "%s.ltx" $topname]
set origll [format "%s.ll" $topname]
set fullbitname [format "%s_%s.bit" $topname $verstring]
set fullltxname [format "%s_%s.ltx" $topname $verstring]
set fullmcsname [format "%s_%s.mcs" $topname $verstring]

set build_dir [file join $projdir build]
set bitfn [file join $build_dir $fullbitname]
set ltxfn [file join $build_dir $fullltxname]
set mcsfn [file join $build_dir $fullmcsname]

file copy -force $origbit $bitfn
write_debug_probes -force $ltxfn
set bitlist [list up 0x00000000 $bitfn]
write_cfgmem -format mcs -size 4 -interface SPIx2 -loadbit $bitlist -file $mcsfn -force
