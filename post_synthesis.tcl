# Allow easy detection of synthesis in Tcl constraint file
create_property -type bool IS_SYNTH design
set_property IS_SYNTH true [current_design]
