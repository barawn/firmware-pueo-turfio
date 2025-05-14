# INVERTED
# rxclk[0]
# cin[0]
# RXCLK[1]
# COUT[0]
# T_COUT[3]
# T_RXCLK
# T_COUT[6]
# T_SPARE
# T_COUT[5]
# COUT6
# DOUT5
# COUT5
# TXCLK4
# COUT3
# COUT4
# CIN5
# CIN4
# DOUT3
# RXCLK4

## crate serial
set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN L14 } [get_ports { SURF_RX }]
## this is open drain from SURFs
set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN U10 PULLUP TRUE} [get_ports { SURF_TX }]

## debug serial. These were named from the FT2232's perspective originally, so they're swapped here
## relative to the schematic.
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN D8} [get_ports DBG_TX]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN C9} [get_ports DBG_RX]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN D14} [get_ports DBG_LED]

## turf serial.
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN D15} [get_ports F_TTX]
# this is SDA anyway so the pull shouldn't matter? I hope?
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN B15 PULLTYPE PULLUP} [get_ports TRX]
# this is pulled down on the board
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN D9} [get_ports TCTRL_B]

## SPI (cclk is internal)
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN K16} [get_ports SPI_MOSI]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN L17} [get_ports SPI_MISO]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN L15} [get_ports SPI_CS_B]

## LMK
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN J16} [get_ports LMKDATA]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN J18} [get_ports LMKLE]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN K18} [get_ports LMKCLK]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN K15} [get_ports LMKOE]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN J14} [get_ports CLK_SYNC]

## crate interface
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN M17} [get_ports EN_3V3]
set_property IOSTANDARD LVCMOS25 [get_ports F_SDA]
set_property PACKAGE_PIN M15 [get_ports F_SDA]
set_property PULLUP true [get_ports F_SDA]
set_property IOSTANDARD LVCMOS25 [get_ports F_SCL]
set_property PACKAGE_PIN N16 [get_ports F_SCL]
set_property PULLUP true [get_ports F_SCL]
#set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN R6  } [get_ports {    ALERT_B     }]
set_property IOSTANDARD LVCMOS25 [get_ports I2C_RDY]
set_property PACKAGE_PIN P6 [get_ports I2C_RDY]
set_property PULLUP true [get_ports I2C_RDY]
#set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN M14 } [get_ports {    PSYNC       }]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN N14} [get_ports ENABLE]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN M16} [get_ports {CONF[1]}]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN N17} [get_ports {CONF[0]}]

## init clk, MGT clock, local system clock
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN E15} [get_ports INITCLK]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN G14} [get_ports INITCLKSTDBY]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN C8} [get_ports EN_LCLK_B]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN H14} [get_ports EN_MYCLK_B]

## cal sel
#set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN E16 } [get_ports {    CALPWDN     }]
#set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN D16 } [get_ports {    CALSEL      }]

## TURF slow interface
#set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN D9  } [get_ports {    T_CTRL_B    }]
#set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN B15 } [get_ports {    TRX         }]
#set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN D15 } [get_ports {    TTX         }]
#set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN B17 } [get_ports {    T_GPIO[1]   }]

# crate JTAG
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN P5} [get_ports JTAG_EN]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN J6} [get_ports T_JCTRL_B]
# T_TDI and T_TDO are functionally switched with levconv v2
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN K5} [get_ports T_TDI]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN K6} [get_ports T_TDO]

set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN M4} [get_ports T_TCK]
set_property -dict {IOSTANDARD LVCMOS25 PACKAGE_PIN N4} [get_ports T_TMS]

## GPIO
set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN G16 } [get_ports {    GPI[0]      }]
set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN G15 } [get_ports {    GPO[0]      }]
set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN F15 } [get_ports {    GPOE_B[0]   }]
set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN H17 } [get_ports {    GPI[1]      }]
set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN H18 } [get_ports {    GPO[1]      }]
set_property -dict { IOSTANDARD LVCMOS25 PACKAGE_PIN H16 } [get_ports {    GPOE_B[1]   }]

## main interfaces
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN K17} [get_ports {RXCLK_N[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN L18} [get_ports {RXCLK_P[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN R18} [get_ports {RXCLK_N[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T18} [get_ports {RXCLK_P[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U15} [get_ports {RXCLK_P[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U16} [get_ports {RXCLK_N[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN R7} [get_ports {RXCLK_P[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T7} [get_ports {RXCLK_N[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U7} [get_ports {RXCLK_N[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V6} [get_ports {RXCLK_P[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U4} [get_ports {RXCLK_P[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V4} [get_ports {RXCLK_N[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN L5} [get_ports {RXCLK_P[6]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN M5} [get_ports {RXCLK_N[6]}]

set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN N18} [get_ports {CIN_N[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN P18} [get_ports {CIN_P[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V16} [get_ports {CIN_P[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V17} [get_ports {CIN_N[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN R13} [get_ports {CIN_P[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T13} [get_ports {CIN_N[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN R5} [get_ports {CIN_P[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T5} [get_ports {CIN_N[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U6} [get_ports {CIN_N[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U5} [get_ports {CIN_P[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T4} [get_ports {CIN_N[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T3} [get_ports {CIN_P[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN J5} [get_ports {CIN_P[6]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN J4} [get_ports {CIN_N[6]}]

set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN P15 DIFF_TERM 1} [get_ports CLKDIV2_P]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN P16 DIFF_TERM 1} [get_ports CLKDIV2_N]
set_property IOSTANDARD LVDS_25 [get_ports {TXCLK_P[2]}]
set_property PULLDOWN true [get_ports {TXCLK_P[2]}]
set_property PACKAGE_PIN P14 [get_ports {TXCLK_P[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN R15} [get_ports {TXCLK_N[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {TXCLK_P[1]}]
set_property PULLDOWN true [get_ports {TXCLK_P[1]}]
set_property PACKAGE_PIN T14 [get_ports {TXCLK_P[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T15} [get_ports {TXCLK_N[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {TXCLK_P[0]}]
set_property PULLDOWN true [get_ports {TXCLK_P[0]}]
set_property PACKAGE_PIN R16 [get_ports {TXCLK_P[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN R17} [get_ports {TXCLK_N[0]}]

set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V12 DIFF_TERM 1} [get_ports {DOUT_P[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V13 DIFF_TERM 1} [get_ports {DOUT_N[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T17 DIFF_TERM 1} [get_ports {DOUT_P[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U17 DIFF_TERM 1} [get_ports {DOUT_N[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U9 DIFF_TERM 1} [get_ports {DOUT_P[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V9 DIFF_TERM 1} [get_ports {DOUT_N[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V8 DIFF_TERM 1} [get_ports {DOUT_N[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V7 DIFF_TERM 1} [get_ports {DOUT_P[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN N1 DIFF_TERM 1} [get_ports {DOUT_P[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN P1 DIFF_TERM 1} [get_ports {DOUT_N[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN L4 DIFF_TERM 1} [get_ports {DOUT_N[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN L3 DIFF_TERM 1} [get_ports {DOUT_P[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN K2 DIFF_TERM 1} [get_ports {DOUT_P[6]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN K1 DIFF_TERM 1} [get_ports {DOUT_N[6]}]


set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U14} [get_ports {COUT_N[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V14} [get_ports {COUT_P[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T12} [get_ports {COUT_P[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U12} [get_ports {COUT_N[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U11} [get_ports {COUT_P[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V11} [get_ports {COUT_N[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN B9} [get_ports T_TXCLK_P]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN A9} [get_ports T_TXCLK_N]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN C11} [get_ports {T_COUT_P[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN B11} [get_ports {T_COUT_N[1]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN B10} [get_ports T_COUTTIO_P]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN A10} [get_ports T_COUTTIO_N]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN A13 DIFF_TERM 1} [get_ports T_CIN_P]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN A14 DIFF_TERM 1} [get_ports T_CIN_N]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN B12} [get_ports {T_COUT_N[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN A12} [get_ports {T_COUT_P[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN B14} [get_ports {T_COUT_P[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN A15} [get_ports {T_COUT_N[0]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN D13 DIFF_TERM 1} [get_ports T_RXCLK_N]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN C13 DIFF_TERM 1} [get_ports T_RXCLK_P]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN B16} [get_ports {T_COUT_P[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN A17} [get_ports {T_COUT_N[2]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN E17} [get_ports {T_COUT_N[6]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN D18} [get_ports {T_COUT_P[6]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN C17} [get_ports {T_COUT_P[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN C18} [get_ports {T_COUT_N[4]}]
#set_property -dict { IOSTANDARD LVDS_25 PACKAGE_PIN G17     } [get_ports {T_SPARE_N  }]
#set_property -dict { IOSTANDARD LVDS_25 PACKAGE_PIN F18     } [get_ports {T_SPARE_P  }]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN F17} [get_ports {T_COUT_N[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN E18} [get_ports {T_COUT_P[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN K3} [get_ports {COUT_N[6]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN L2} [get_ports {COUT_P[6]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN M1} [get_ports {COUT_P[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN M2} [get_ports {COUT_N[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {TXCLK_P[6]}]
set_property PULLDOWN true [get_ports {TXCLK_P[6]}]
set_property PACKAGE_PIN N3 [get_ports {TXCLK_P[6]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN N2} [get_ports {TXCLK_N[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {TXCLK_P[5]}]
set_property PULLDOWN true [get_ports {TXCLK_P[5]}]
set_property PACKAGE_PIN P4 [get_ports {TXCLK_P[5]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN P3} [get_ports {TXCLK_N[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {TXCLK_N[4]}]
set_property PULLDOWN true [get_ports {TXCLK_N[4]}]
set_property PACKAGE_PIN R2 [get_ports {TXCLK_N[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN R1} [get_ports {TXCLK_P[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {TXCLK_P[3]}]
set_property PULLDOWN true [get_ports {TXCLK_P[3]}]
set_property PACKAGE_PIN R3 [get_ports {TXCLK_P[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN T2} [get_ports {TXCLK_N[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U2} [get_ports {COUT_N[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN U1} [get_ports {COUT_P[3]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V3} [get_ports {COUT_N[4]}]
set_property -dict {IOSTANDARD LVDS_25 PACKAGE_PIN V2} [get_ports {COUT_P[4]}]

set_property -dict {PACKAGE_PIN D6} [get_ports F_LCLK_P]
set_property -dict {PACKAGE_PIN D5} [get_ports F_LCLK_N]
set_property -dict {PACKAGE_PIN A4} [get_ports MGTRX_P]
set_property -dict {PACKAGE_PIN A3} [get_ports MGTRX_N]
set_property -dict {PACKAGE_PIN F2} [get_ports MGTTX_P]
set_property -dict {PACKAGE_PIN F1} [get_ports MGTTX_N]

set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS25 PULLUP true} [get_ports SYS_RESET_B]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_property CONFIG_MODE SPIx2 [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR NO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 2 [current_design]


# The debug_hub stuff needs to be in the tcl version so it can dodge
# it if it doesn't exist.
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets u_clk200/inst/clk_out2_clk200_wiz]

set_property BITSTREAM.CONFIG.USERID 32'h08232024 [current_design]

