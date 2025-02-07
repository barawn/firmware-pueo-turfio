proc hskbus_enable { } {
    jtag targets -set -filter {name =~ "xc7a35t"}
    set jseq [jtag sequence]
    # shift 6-bit IR code of 0x23 in (USER4)
    $jseq irshift -state IDLE -hex 6 23
    # shift 8 bit USER4 code in (0x80, enable HSKBUS)
    $jseq drshift -state IDLE -hex 8 80
    $jseq run
    $jseq clear
}

proc hskbus_enable_full { } {
    jtag targets -set -filter {name =~ "xc7a35t"}
    set jseq [jtag sequence]
    # shift 6-bit IR code of 0x23 in (USER4)
    $jseq irshift -state IDLE -hex 6 23
    # shift 8 bit USER4 code in (0x80, enable HSKBUS)
    $jseq drshift -state IDLE -hex 8 C0
    $jseq run
    $jseq clear
}

proc hskbus_disable { } {
    jtag targets -set -filter {name =~ "xc7a35t"}
    set jseq [jtag sequence]
    # shift 6-bit IR code of 0x23 in (USER4)
    $jseq irshift -state IDLE -hex 6 23
    # shift 8 bit USER4 code in (0x00, disable HSKBUS)
    $jseq drshift -state IDLE -hex 8 00
    $jseq run
    $jseq clear
}
