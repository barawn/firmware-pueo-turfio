proc hskbus_enable { args  } {
    array set data [list -sn "*" {*}$args]
    set sn $data(-sn)
    jtag targets -set -filter {name =~ "xc7a35t" && jtag_cable_serial =~ $sn }
    set jseq [jtag sequence]
    # shift 6-bit IR code of 0x23 in (USER4)
    $jseq irshift -state IDLE -hex 6 23
    # shift 8 bit USER4 code in (0x80, enable HSKBUS)
    $jseq drshift -state IDLE -hex 8 80
    $jseq run
    $jseq clear
}

proc hskbus_enable_full { args } {
    array set data [list -sn "*" {*}$args]
    set sn $data(-sn)
    jtag targets -set -filter {name =~ "xc7a35t" && jtag_cable_serial =~ $sn }
    set jseq [jtag sequence]
    # shift 6-bit IR code of 0x23 in (USER4)
    $jseq irshift -state IDLE -hex 6 23
    # shift 8 bit USER4 code in (0x80, enable HSKBUS)
    $jseq drshift -state IDLE -hex 8 C0
    $jseq run
    $jseq clear
}

# force the SURF crate on
proc hskbus_enable_force_crate { args } {
    array set data [list -sn "*" {*}$args]
    set sn $data(-sn)
    jtag targets -set -filter {name =~ "xc7a35t" && jtag_cable_serial =~ $sn }
    set jseq [jtag sequence]
    # shift 6-bit IR code of 0x23 in (USER4)
    $jseq irshift -state IDLE -hex 6 23
    # shift 8 bit USER4 code in (0x40, ONLY enable cratebridge)
    $jseq drshift -state IDLE -hex 8 00
    $jseq run
    $jseq clear
}

# disable everything
proc hskbus_disable { args } {
    array set data [list -sn "*" {*}$args]
    set sn $data(-sn)
    jtag targets -set -filter {name =~ "xc7a35t" && jtag_cable_serial =~ $sn }
    set jseq [jtag sequence]
    # shift 6-bit IR code of 0x23 in (USER4)
    $jseq irshift -state IDLE -hex 6 23
    # shift 8 bit USER4 code in (0x00, disable HSKBUS)
    $jseq drshift -state IDLE -hex 8 00
    $jseq run
    $jseq clear
}


