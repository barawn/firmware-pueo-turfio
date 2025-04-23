/*
 * == pblaze-cc ==
 * source : pb_turfio.c
 * create : Wed Apr 23 14:15:23 2025
 * modify : Wed Apr 23 14:15:23 2025
 */
`timescale 1 ps / 1ps

/* 
 * == pblaze-as ==
 * source : pb_turfio.s
 * create : Wed Apr 23 14:15:42 2025
 * modify : Wed Apr 23 14:15:42 2025
 */
/* 
 * == pblaze-ld ==
 * target : kcpsm3
 */

module pb_turfio (address, instruction, enable, clk, bram_adr_i, bram_dat_o, bram_dat_i, bram_en_i, bram_we_i, bram_rd_i);
parameter BRAM_PORT_WIDTH = 9;
localparam BRAM_ADR_WIDTH = (BRAM_PORT_WIDTH == 18) ? 10 : 11;
localparam BRAM_WE_WIDTH = (BRAM_PORT_WIDTH == 18) ? 2 : 1;
input [9:0] address;
input clk;
input enable;
output [17:0] instruction;
input [BRAM_ADR_WIDTH-1:0] bram_adr_i;
output [BRAM_PORT_WIDTH-1:0] bram_dat_o;
input [BRAM_PORT_WIDTH-1:0] bram_dat_i;
input bram_we_i;
input bram_en_i;
input bram_rd_i;

// Debugging symbols. Note that they're
// only 48 characters long max.
// synthesis translate_off

// allocate a bunch of space for the text
   reg [8*48-1:0] dbg_instr;
   always @(*) begin
     case(address)
         0 : dbg_instr = "boot                                           ";
         1 : dbg_instr = "boot+0x001                                     ";
         2 : dbg_instr = "boot+0x002                                     ";
         3 : dbg_instr = "boot+0x003                                     ";
         4 : dbg_instr = "loop                                           ";
         5 : dbg_instr = "loop+0x001                                     ";
         6 : dbg_instr = "loop+0x002                                     ";
         7 : dbg_instr = "isr_serial                                     ";
         8 : dbg_instr = "isr_serial+0x001                               ";
         9 : dbg_instr = "isr_serial+0x002                               ";
         10 : dbg_instr = "isr_serial+0x003                               ";
         11 : dbg_instr = "isr_serial+0x004                               ";
         12 : dbg_instr = "isr_serial+0x005                               ";
         13 : dbg_instr = "isr_serial+0x006                               ";
         14 : dbg_instr = "isr_serial+0x007                               ";
         15 : dbg_instr = "isr_serial+0x008                               ";
         16 : dbg_instr = "isr_serial+0x009                               ";
         17 : dbg_instr = "isr_serial+0x00a                               ";
         18 : dbg_instr = "isr_serial+0x00b                               ";
         19 : dbg_instr = "isr_serial+0x00c                               ";
         20 : dbg_instr = "isr_serial+0x00d                               ";
         21 : dbg_instr = "isr_serial+0x00e                               ";
         22 : dbg_instr = "isr_serial+0x00f                               ";
         23 : dbg_instr = "isr_serial+0x010                               ";
         24 : dbg_instr = "isr_serial+0x011                               ";
         25 : dbg_instr = "isr_serial+0x012                               ";
         26 : dbg_instr = "isr_serial+0x013                               ";
         27 : dbg_instr = "isr_serial+0x014                               ";
         28 : dbg_instr = "isr_serial+0x015                               ";
         29 : dbg_instr = "isr_serial+0x016                               ";
         30 : dbg_instr = "isr_serial+0x017                               ";
         31 : dbg_instr = "isr_serial+0x018                               ";
         32 : dbg_instr = "isr_serial+0x019                               ";
         33 : dbg_instr = "isr_serial+0x01a                               ";
         34 : dbg_instr = "isr_serial+0x01b                               ";
         35 : dbg_instr = "isr_serial+0x01c                               ";
         36 : dbg_instr = "isr_serial+0x01d                               ";
         37 : dbg_instr = "isr_serial+0x01e                               ";
         38 : dbg_instr = "init                                           ";
         39 : dbg_instr = "init+0x001                                     ";
         40 : dbg_instr = "init+0x002                                     ";
         41 : dbg_instr = "init+0x003                                     ";
         42 : dbg_instr = "init+0x004                                     ";
         43 : dbg_instr = "init+0x005                                     ";
         44 : dbg_instr = "init+0x006                                     ";
         45 : dbg_instr = "init+0x007                                     ";
         46 : dbg_instr = "init+0x008                                     ";
         47 : dbg_instr = "init+0x009                                     ";
         48 : dbg_instr = "init+0x00a                                     ";
         49 : dbg_instr = "init+0x00b                                     ";
         50 : dbg_instr = "init+0x00c                                     ";
         51 : dbg_instr = "init+0x00d                                     ";
         52 : dbg_instr = "init+0x00e                                     ";
         53 : dbg_instr = "init+0x00f                                     ";
         54 : dbg_instr = "init+0x010                                     ";
         55 : dbg_instr = "init+0x011                                     ";
         56 : dbg_instr = "init+0x012                                     ";
         57 : dbg_instr = "init+0x013                                     ";
         58 : dbg_instr = "init+0x014                                     ";
         59 : dbg_instr = "init+0x015                                     ";
         60 : dbg_instr = "init+0x016                                     ";
         61 : dbg_instr = "init+0x017                                     ";
         62 : dbg_instr = "init+0x018                                     ";
         63 : dbg_instr = "init+0x019                                     ";
         64 : dbg_instr = "init+0x01a                                     ";
         65 : dbg_instr = "init+0x01b                                     ";
         66 : dbg_instr = "init+0x01c                                     ";
         67 : dbg_instr = "init+0x01d                                     ";
         68 : dbg_instr = "init+0x01e                                     ";
         69 : dbg_instr = "init+0x01f                                     ";
         70 : dbg_instr = "init+0x020                                     ";
         71 : dbg_instr = "init+0x021                                     ";
         72 : dbg_instr = "init+0x022                                     ";
         73 : dbg_instr = "init+0x023                                     ";
         74 : dbg_instr = "init+0x024                                     ";
         75 : dbg_instr = "init+0x025                                     ";
         76 : dbg_instr = "init+0x026                                     ";
         77 : dbg_instr = "init+0x027                                     ";
         78 : dbg_instr = "init+0x028                                     ";
         79 : dbg_instr = "init+0x029                                     ";
         80 : dbg_instr = "init+0x02a                                     ";
         81 : dbg_instr = "init+0x02b                                     ";
         82 : dbg_instr = "init+0x02c                                     ";
         83 : dbg_instr = "init+0x02d                                     ";
         84 : dbg_instr = "update_housekeeping                            ";
         85 : dbg_instr = "update_housekeeping+0x001                      ";
         86 : dbg_instr = "update_housekeeping+0x002                      ";
         87 : dbg_instr = "update_housekeeping+0x003                      ";
         88 : dbg_instr = "update_housekeeping+0x004                      ";
         89 : dbg_instr = "update_housekeeping+0x005                      ";
         90 : dbg_instr = "update_housekeeping+0x006                      ";
         91 : dbg_instr = "update_housekeeping+0x007                      ";
         92 : dbg_instr = "update_housekeeping+0x008                      ";
         93 : dbg_instr = "IDLE_WAIT                                      ";
         94 : dbg_instr = "IDLE_WAIT+0x001                                ";
         95 : dbg_instr = "IDLE_WAIT+0x002                                ";
         96 : dbg_instr = "IDLE_WAIT+0x003                                ";
         97 : dbg_instr = "IDLE_WAIT+0x004                                ";
         98 : dbg_instr = "IDLE_WAIT+0x005                                ";
         99 : dbg_instr = "IDLE_WAIT+0x006                                ";
         100 : dbg_instr = "IDLE_WAIT+0x007                                ";
         101 : dbg_instr = "IDLE_WAIT+0x008                                ";
         102 : dbg_instr = "IDLE_WAIT+0x009                                ";
         103 : dbg_instr = "IDLE_WAIT+0x00a                                ";
         104 : dbg_instr = "IDLE_WAIT+0x00b                                ";
         105 : dbg_instr = "IDLE_WAIT+0x00c                                ";
         106 : dbg_instr = "IDLE_WAIT+0x00d                                ";
         107 : dbg_instr = "IDLE_WAIT+0x00e                                ";
         108 : dbg_instr = "IDLE_WAIT+0x00f                                ";
         109 : dbg_instr = "IDLE_WAIT+0x010                                ";
         110 : dbg_instr = "IDLE_WAIT+0x011                                ";
         111 : dbg_instr = "IDLE_WAIT+0x012                                ";
         112 : dbg_instr = "IDLE_WAIT+0x013                                ";
         113 : dbg_instr = "IDLE_WAIT+0x014                                ";
         114 : dbg_instr = "IDLE_WAIT+0x015                                ";
         115 : dbg_instr = "IDLE_WAIT+0x016                                ";
         116 : dbg_instr = "IDLE_WAIT+0x017                                ";
         117 : dbg_instr = "IDLE_WAIT+0x018                                ";
         118 : dbg_instr = "SURF_CHECK                                     ";
         119 : dbg_instr = "SURF_CHECK+0x001                               ";
         120 : dbg_instr = "SURF_CHECK+0x002                               ";
         121 : dbg_instr = "SURF_CHECK+0x003                               ";
         122 : dbg_instr = "SURF_WRITE_REG                                 ";
         123 : dbg_instr = "SURF_WRITE_REG+0x001                           ";
         124 : dbg_instr = "SURF_WRITE_REG+0x002                           ";
         125 : dbg_instr = "SURF_WRITE_REG+0x003                           ";
         126 : dbg_instr = "SURF_WRITE_REG+0x004                           ";
         127 : dbg_instr = "SURF_WRITE_REG+0x005                           ";
         128 : dbg_instr = "SURF_WRITE_REG+0x006                           ";
         129 : dbg_instr = "SURF_WRITE_REG+0x007                           ";
         130 : dbg_instr = "SURF_WRITE_REG+0x008                           ";
         131 : dbg_instr = "SURF_WRITE_REG+0x009                           ";
         132 : dbg_instr = "SURF_WRITE_REG+0x00a                           ";
         133 : dbg_instr = "SURF_WRITE_REG+0x00b                           ";
         134 : dbg_instr = "SURF_WRITE_REG+0x00c                           ";
         135 : dbg_instr = "SURF_READ_REG                                  ";
         136 : dbg_instr = "SURF_READ_REG+0x001                            ";
         137 : dbg_instr = "SURF_READ_REG+0x002                            ";
         138 : dbg_instr = "SURF_READ_REG+0x003                            ";
         139 : dbg_instr = "SURF_READ_REG+0x004                            ";
         140 : dbg_instr = "SURF_READ_REG+0x005                            ";
         141 : dbg_instr = "SURF_READ_REG+0x006                            ";
         142 : dbg_instr = "SURF_READ_REG+0x007                            ";
         143 : dbg_instr = "SURF_READ_REG+0x008                            ";
         144 : dbg_instr = "SURF_READ_REG+0x009                            ";
         145 : dbg_instr = "SURF_READ_REG+0x00a                            ";
         146 : dbg_instr = "SURF_READ_REG+0x00b                            ";
         147 : dbg_instr = "SURF_READ_REG+0x00c                            ";
         148 : dbg_instr = "SURF_READ_REG+0x00d                            ";
         149 : dbg_instr = "SURF_READ_REG+0x00e                            ";
         150 : dbg_instr = "SURF_READ_REG+0x00f                            ";
         151 : dbg_instr = "SURF_READ_REG+0x010                            ";
         152 : dbg_instr = "SURF_READ_REG+0x011                            ";
         153 : dbg_instr = "SURF_READ_REG+0x012                            ";
         154 : dbg_instr = "SURF_READ_REG+0x013                            ";
         155 : dbg_instr = "SURF_READ_REG+0x014                            ";
         156 : dbg_instr = "SURF_READ_REG+0x015                            ";
         157 : dbg_instr = "SURF_READ_REG+0x016                            ";
         158 : dbg_instr = "SURF_READ_REG+0x017                            ";
         159 : dbg_instr = "SURF_READ_REG+0x018                            ";
         160 : dbg_instr = "SURF_READ_REG+0x019                            ";
         161 : dbg_instr = "SURF_READ_REG+0x01a                            ";
         162 : dbg_instr = "TURFIO                                         ";
         163 : dbg_instr = "TURFIO+0x001                                   ";
         164 : dbg_instr = "TURFIO+0x002                                   ";
         165 : dbg_instr = "TURFIO+0x003                                   ";
         166 : dbg_instr = "TURFIO+0x004                                   ";
         167 : dbg_instr = "TURFIO+0x005                                   ";
         168 : dbg_instr = "TURFIO+0x006                                   ";
         169 : dbg_instr = "TURFIO+0x007                                   ";
         170 : dbg_instr = "TURFIO+0x008                                   ";
         171 : dbg_instr = "TURFIO+0x009                                   ";
         172 : dbg_instr = "TURFIO+0x00a                                   ";
         173 : dbg_instr = "TURFIO+0x00b                                   ";
         174 : dbg_instr = "TURFIO+0x00c                                   ";
         175 : dbg_instr = "TURFIO+0x00d                                   ";
         176 : dbg_instr = "TURFIO+0x00e                                   ";
         177 : dbg_instr = "TURFIO+0x00f                                   ";
         178 : dbg_instr = "TURFIO+0x010                                   ";
         179 : dbg_instr = "TURFIO+0x011                                   ";
         180 : dbg_instr = "TURFIO+0x012                                   ";
         181 : dbg_instr = "TURFIO+0x013                                   ";
         182 : dbg_instr = "TURFIO+0x014                                   ";
         183 : dbg_instr = "TURFIO+0x015                                   ";
         184 : dbg_instr = "TURFIO+0x016                                   ";
         185 : dbg_instr = "TURFIO+0x017                                   ";
         186 : dbg_instr = "TURFIO+0x018                                   ";
         187 : dbg_instr = "TURFIO+0x019                                   ";
         188 : dbg_instr = "TURFIO+0x01a                                   ";
         189 : dbg_instr = "TURFIO+0x01b                                   ";
         190 : dbg_instr = "TURFIO+0x01c                                   ";
         191 : dbg_instr = "TURFIO+0x01d                                   ";
         192 : dbg_instr = "TURFIO+0x01e                                   ";
         193 : dbg_instr = "PMBUS                                          ";
         194 : dbg_instr = "PMBUS+0x001                                    ";
         195 : dbg_instr = "PMBUS+0x002                                    ";
         196 : dbg_instr = "PMBUS+0x003                                    ";
         197 : dbg_instr = "PMBUS+0x004                                    ";
         198 : dbg_instr = "WRITE_PMBUS                                    ";
         199 : dbg_instr = "WRITE_PMBUS+0x001                              ";
         200 : dbg_instr = "WRITE_PMBUS+0x002                              ";
         201 : dbg_instr = "WRITE_PMBUS+0x003                              ";
         202 : dbg_instr = "WRITE_PMBUS+0x004                              ";
         203 : dbg_instr = "WRITE_PMBUS+0x005                              ";
         204 : dbg_instr = "WRITE_PMBUS+0x006                              ";
         205 : dbg_instr = "WRITE_PMBUS+0x007                              ";
         206 : dbg_instr = "WRITE_PMBUS+0x008                              ";
         207 : dbg_instr = "WRITE_PMBUS+0x009                              ";
         208 : dbg_instr = "WRITE_PMBUS+0x00a                              ";
         209 : dbg_instr = "WRITE_PMBUS+0x00b                              ";
         210 : dbg_instr = "WRITE_PMBUS+0x00c                              ";
         211 : dbg_instr = "WRITE_PMBUS+0x00d                              ";
         212 : dbg_instr = "WRITE_PMBUS+0x00e                              ";
         213 : dbg_instr = "WRITE_PMBUS+0x00f                              ";
         214 : dbg_instr = "WRITE_PMBUS+0x010                              ";
         215 : dbg_instr = "WRITE_PMBUS+0x011                              ";
         216 : dbg_instr = "WRITE_PMBUS+0x012                              ";
         217 : dbg_instr = "READ_PMBUS                                     ";
         218 : dbg_instr = "READ_PMBUS+0x001                               ";
         219 : dbg_instr = "READ_PMBUS+0x002                               ";
         220 : dbg_instr = "READ_PMBUS+0x003                               ";
         221 : dbg_instr = "READ_PMBUS+0x004                               ";
         222 : dbg_instr = "READ_PMBUS+0x005                               ";
         223 : dbg_instr = "READ_PMBUS+0x006                               ";
         224 : dbg_instr = "READ_PMBUS+0x007                               ";
         225 : dbg_instr = "READ_PMBUS+0x008                               ";
         226 : dbg_instr = "READ_PMBUS+0x009                               ";
         227 : dbg_instr = "READ_PMBUS+0x00a                               ";
         228 : dbg_instr = "READ_PMBUS+0x00b                               ";
         229 : dbg_instr = "READ_PMBUS+0x00c                               ";
         230 : dbg_instr = "READ_PMBUS+0x00d                               ";
         231 : dbg_instr = "READ_PMBUS+0x00e                               ";
         232 : dbg_instr = "READ_PMBUS+0x00f                               ";
         233 : dbg_instr = "FINISH_PMBUS                                   ";
         234 : dbg_instr = "FINISH_PMBUS+0x001                             ";
         235 : dbg_instr = "FINISH_PMBUS+0x002                             ";
         236 : dbg_instr = "FINISH_PMBUS+0x003                             ";
         237 : dbg_instr = "FINISH_PMBUS+0x004                             ";
         238 : dbg_instr = "hskNextDevice                                  ";
         239 : dbg_instr = "hskNextDevice+0x001                            ";
         240 : dbg_instr = "hskNextDevice+0x002                            ";
         241 : dbg_instr = "hskNextDevice+0x003                            ";
         242 : dbg_instr = "hskNextDevice+0x004                            ";
         243 : dbg_instr = "hskNextDevice+0x005                            ";
         244 : dbg_instr = "hskNextDevice+0x006                            ";
         245 : dbg_instr = "hskNextDevice+0x007                            ";
         246 : dbg_instr = "hskNextDevice+0x008                            ";
         247 : dbg_instr = "hskNextDevice+0x009                            ";
         248 : dbg_instr = "hskNextDevice+0x00a                            ";
         249 : dbg_instr = "hskNextDevice+0x00b                            ";
         250 : dbg_instr = "hskNextDevice+0x00c                            ";
         251 : dbg_instr = "hskCountDevice                                 ";
         252 : dbg_instr = "hskCountDevice+0x001                           ";
         253 : dbg_instr = "hskCountDevice+0x002                           ";
         254 : dbg_instr = "hskCountDevice+0x003                           ";
         255 : dbg_instr = "hskCountDevice+0x004                           ";
         256 : dbg_instr = "hskGetDeviceAddress                            ";
         257 : dbg_instr = "hskGetDeviceAddress+0x001                      ";
         258 : dbg_instr = "hskGetDeviceAddress+0x002                      ";
         259 : dbg_instr = "hskGetDeviceAddress+0x003                      ";
         260 : dbg_instr = "hskGetDeviceAddress+0x004                      ";
         261 : dbg_instr = "handle_serial                                  ";
         262 : dbg_instr = "handle_serial+0x001                            ";
         263 : dbg_instr = "handle_serial+0x002                            ";
         264 : dbg_instr = "handle_serial+0x003                            ";
         265 : dbg_instr = "handle_serial+0x004                            ";
         266 : dbg_instr = "handle_serial+0x005                            ";
         267 : dbg_instr = "handle_serial+0x006                            ";
         268 : dbg_instr = "handle_serial+0x007                            ";
         269 : dbg_instr = "parse_serial                                   ";
         270 : dbg_instr = "parse_serial+0x001                             ";
         271 : dbg_instr = "parse_serial+0x002                             ";
         272 : dbg_instr = "parse_serial+0x003                             ";
         273 : dbg_instr = "parse_serial+0x004                             ";
         274 : dbg_instr = "parse_serial+0x005                             ";
         275 : dbg_instr = "parse_serial+0x006                             ";
         276 : dbg_instr = "parse_serial+0x007                             ";
         277 : dbg_instr = "parse_serial+0x008                             ";
         278 : dbg_instr = "parse_serial+0x009                             ";
         279 : dbg_instr = "parse_serial+0x00a                             ";
         280 : dbg_instr = "parse_serial+0x00b                             ";
         281 : dbg_instr = "parse_serial+0x00c                             ";
         282 : dbg_instr = "parse_serial+0x00d                             ";
         283 : dbg_instr = "parse_serial+0x00e                             ";
         284 : dbg_instr = "parse_serial+0x00f                             ";
         285 : dbg_instr = "parse_serial+0x010                             ";
         286 : dbg_instr = "parse_serial+0x011                             ";
         287 : dbg_instr = "parse_serial+0x012                             ";
         288 : dbg_instr = "parse_serial+0x013                             ";
         289 : dbg_instr = "parse_serial+0x014                             ";
         290 : dbg_instr = "parse_serial+0x015                             ";
         291 : dbg_instr = "parse_serial+0x016                             ";
         292 : dbg_instr = "parse_serial+0x017                             ";
         293 : dbg_instr = "parse_serial+0x018                             ";
         294 : dbg_instr = "parse_serial+0x019                             ";
         295 : dbg_instr = "parse_serial+0x01a                             ";
         296 : dbg_instr = "parse_serial+0x01b                             ";
         297 : dbg_instr = "parse_serial+0x01c                             ";
         298 : dbg_instr = "parse_serial+0x01d                             ";
         299 : dbg_instr = "parse_serial+0x01e                             ";
         300 : dbg_instr = "parse_serial+0x01f                             ";
         301 : dbg_instr = "parse_serial+0x020                             ";
         302 : dbg_instr = "parse_serial+0x021                             ";
         303 : dbg_instr = "parse_serial+0x022                             ";
         304 : dbg_instr = "do_PingPong                                    ";
         305 : dbg_instr = "do_PingPong+0x001                              ";
         306 : dbg_instr = "do_Statistics                                  ";
         307 : dbg_instr = "do_Statistics+0x001                            ";
         308 : dbg_instr = "do_Statistics+0x002                            ";
         309 : dbg_instr = "do_Statistics+0x003                            ";
         310 : dbg_instr = "do_Statistics+0x004                            ";
         311 : dbg_instr = "do_Statistics+0x005                            ";
         312 : dbg_instr = "do_Statistics+0x006                            ";
         313 : dbg_instr = "do_Statistics+0x007                            ";
         314 : dbg_instr = "do_Statistics+0x008                            ";
         315 : dbg_instr = "do_Statistics+0x009                            ";
         316 : dbg_instr = "do_Statistics+0x00a                            ";
         317 : dbg_instr = "do_Statistics+0x00b                            ";
         318 : dbg_instr = "do_Statistics+0x00c                            ";
         319 : dbg_instr = "do_Statistics+0x00d                            ";
         320 : dbg_instr = "do_Statistics+0x00e                            ";
         321 : dbg_instr = "do_Statistics+0x00f                            ";
         322 : dbg_instr = "do_Statistics+0x010                            ";
         323 : dbg_instr = "do_Statistics+0x011                            ";
         324 : dbg_instr = "do_Temps                                       ";
         325 : dbg_instr = "do_Temps+0x001                                 ";
         326 : dbg_instr = "do_Temps+0x002                                 ";
         327 : dbg_instr = "do_Temps+0x003                                 ";
         328 : dbg_instr = "do_Temps+0x004                                 ";
         329 : dbg_instr = "do_Temps+0x005                                 ";
         330 : dbg_instr = "do_Temps+0x006                                 ";
         331 : dbg_instr = "do_Temps+0x007                                 ";
         332 : dbg_instr = "do_Temps+0x008                                 ";
         333 : dbg_instr = "do_Temps+0x009                                 ";
         334 : dbg_instr = "do_Temps+0x00a                                 ";
         335 : dbg_instr = "do_Temps+0x00b                                 ";
         336 : dbg_instr = "do_Temps+0x00c                                 ";
         337 : dbg_instr = "do_Temps+0x00d                                 ";
         338 : dbg_instr = "do_Volts                                       ";
         339 : dbg_instr = "do_Volts+0x001                                 ";
         340 : dbg_instr = "do_Volts+0x002                                 ";
         341 : dbg_instr = "do_Volts+0x003                                 ";
         342 : dbg_instr = "do_Volts+0x004                                 ";
         343 : dbg_instr = "do_Volts+0x005                                 ";
         344 : dbg_instr = "do_Volts+0x006                                 ";
         345 : dbg_instr = "do_Volts+0x007                                 ";
         346 : dbg_instr = "do_Volts+0x008                                 ";
         347 : dbg_instr = "do_Volts+0x009                                 ";
         348 : dbg_instr = "do_Volts+0x00a                                 ";
         349 : dbg_instr = "do_Volts+0x00b                                 ";
         350 : dbg_instr = "do_Volts+0x00c                                 ";
         351 : dbg_instr = "do_Volts+0x00d                                 ";
         352 : dbg_instr = "do_Currents                                    ";
         353 : dbg_instr = "do_Currents+0x001                              ";
         354 : dbg_instr = "do_Currents+0x002                              ";
         355 : dbg_instr = "do_Currents+0x003                              ";
         356 : dbg_instr = "do_Currents+0x004                              ";
         357 : dbg_instr = "do_Currents+0x005                              ";
         358 : dbg_instr = "do_Currents+0x006                              ";
         359 : dbg_instr = "do_Currents+0x007                              ";
         360 : dbg_instr = "do_Currents+0x008                              ";
         361 : dbg_instr = "do_Currents+0x009                              ";
         362 : dbg_instr = "do_Currents+0x00a                              ";
         363 : dbg_instr = "do_Currents+0x00b                              ";
         364 : dbg_instr = "do_Currents+0x00c                              ";
         365 : dbg_instr = "do_Currents+0x00d                              ";
         366 : dbg_instr = "do_ReloadFirmware                              ";
         367 : dbg_instr = "do_ReloadFirmware+0x001                        ";
         368 : dbg_instr = "do_ReloadFirmware+0x002                        ";
         369 : dbg_instr = "do_ReloadFirmware+0x003                        ";
         370 : dbg_instr = "do_ReloadFirmware+0x004                        ";
         371 : dbg_instr = "do_ReloadFirmware+0x005                        ";
         372 : dbg_instr = "do_Enable                                      ";
         373 : dbg_instr = "do_Enable+0x001                                ";
         374 : dbg_instr = "do_Enable+0x002                                ";
         375 : dbg_instr = "do_Enable+0x003                                ";
         376 : dbg_instr = "do_Enable+0x004                                ";
         377 : dbg_instr = "do_Enable+0x005                                ";
         378 : dbg_instr = "do_Enable+0x006                                ";
         379 : dbg_instr = "do_Enable+0x007                                ";
         380 : dbg_instr = "do_Enable+0x008                                ";
         381 : dbg_instr = "do_Enable+0x009                                ";
         382 : dbg_instr = "do_Enable+0x00a                                ";
         383 : dbg_instr = "do_Enable+0x00b                                ";
         384 : dbg_instr = "do_Enable+0x00c                                ";
         385 : dbg_instr = "do_Enable+0x00d                                ";
         386 : dbg_instr = "do_Enable+0x00e                                ";
         387 : dbg_instr = "do_Enable+0x00f                                ";
         388 : dbg_instr = "do_Enable+0x010                                ";
         389 : dbg_instr = "do_Enable+0x011                                ";
         390 : dbg_instr = "do_Enable+0x012                                ";
         391 : dbg_instr = "do_PMBus                                       ";
         392 : dbg_instr = "do_PMBus+0x001                                 ";
         393 : dbg_instr = "do_PMBus+0x002                                 ";
         394 : dbg_instr = "do_PMBus+0x003                                 ";
         395 : dbg_instr = "do_PMBus+0x004                                 ";
         396 : dbg_instr = "do_PMBus+0x005                                 ";
         397 : dbg_instr = "do_PMBus+0x006                                 ";
         398 : dbg_instr = "do_PMBus+0x007                                 ";
         399 : dbg_instr = "do_PMBus+0x008                                 ";
         400 : dbg_instr = "do_PMBus+0x009                                 ";
         401 : dbg_instr = "do_PMBus+0x00a                                 ";
         402 : dbg_instr = "PMBus_Write                                    ";
         403 : dbg_instr = "PMBus_Write+0x001                              ";
         404 : dbg_instr = "PMBus_Write+0x002                              ";
         405 : dbg_instr = "PMBus_Write+0x003                              ";
         406 : dbg_instr = "PMBus_Write+0x004                              ";
         407 : dbg_instr = "PMBus_Write+0x005                              ";
         408 : dbg_instr = "PMBus_Write+0x006                              ";
         409 : dbg_instr = "PMBus_Write+0x007                              ";
         410 : dbg_instr = "PMBus_Write+0x008                              ";
         411 : dbg_instr = "PMBus_Write+0x009                              ";
         412 : dbg_instr = "PMBus_Write+0x00a                              ";
         413 : dbg_instr = "PMBus_Write+0x00b                              ";
         414 : dbg_instr = "PMBus_Write+0x00c                              ";
         415 : dbg_instr = "PMBus_Write+0x00d                              ";
         416 : dbg_instr = "PMBus_Write+0x00e                              ";
         417 : dbg_instr = "PMBus_Write+0x00f                              ";
         418 : dbg_instr = "PMBus_Write+0x010                              ";
         419 : dbg_instr = "PMBus_Read                                     ";
         420 : dbg_instr = "PMBus_Read+0x001                               ";
         421 : dbg_instr = "PMBus_Read+0x002                               ";
         422 : dbg_instr = "PMBus_Read+0x003                               ";
         423 : dbg_instr = "PMBus_Read+0x004                               ";
         424 : dbg_instr = "PMBus_Read+0x005                               ";
         425 : dbg_instr = "PMBus_Read+0x006                               ";
         426 : dbg_instr = "PMBus_Read+0x007                               ";
         427 : dbg_instr = "PMBus_Read+0x008                               ";
         428 : dbg_instr = "PMBus_Read+0x009                               ";
         429 : dbg_instr = "PMBus_Read+0x00a                               ";
         430 : dbg_instr = "PMBus_Read+0x00b                               ";
         431 : dbg_instr = "PMBus_Read+0x00c                               ";
         432 : dbg_instr = "PMBus_Read+0x00d                               ";
         433 : dbg_instr = "PMBus_Read+0x00e                               ";
         434 : dbg_instr = "PMBus_Read+0x00f                               ";
         435 : dbg_instr = "PMBus_Read+0x010                               ";
         436 : dbg_instr = "PMBus_Read+0x011                               ";
         437 : dbg_instr = "do_Identify                                    ";
         438 : dbg_instr = "do_Identify+0x001                              ";
         439 : dbg_instr = "do_Identify+0x002                              ";
         440 : dbg_instr = "do_Identify+0x003                              ";
         441 : dbg_instr = "do_Identify+0x004                              ";
         442 : dbg_instr = "do_Identify+0x005                              ";
         443 : dbg_instr = "do_Identify+0x006                              ";
         444 : dbg_instr = "do_Identify+0x007                              ";
         445 : dbg_instr = "finishPacket                                   ";
         446 : dbg_instr = "finishPacket+0x001                             ";
         447 : dbg_instr = "finishPacket+0x002                             ";
         448 : dbg_instr = "goodPacket                                     ";
         449 : dbg_instr = "goodPacket+0x001                               ";
         450 : dbg_instr = "goodPacket+0x002                               ";
         451 : dbg_instr = "goodPacket+0x003                               ";
         452 : dbg_instr = "fetchAndIncrement                              ";
         453 : dbg_instr = "fetchAndIncrement+0x001                        ";
         454 : dbg_instr = "fetchAndIncrement+0x002                        ";
         455 : dbg_instr = "fetchAndIncrement+0x003                        ";
         456 : dbg_instr = "skippedPacket                                  ";
         457 : dbg_instr = "skippedPacket+0x001                            ";
         458 : dbg_instr = "droppedPacket                                  ";
         459 : dbg_instr = "droppedPacket+0x001                            ";
         460 : dbg_instr = "errorPacket                                    ";
         461 : dbg_instr = "errorPacket+0x001                              ";
         462 : dbg_instr = "hsk_header                                     ";
         463 : dbg_instr = "hsk_header+0x001                               ";
         464 : dbg_instr = "hsk_header+0x002                               ";
         465 : dbg_instr = "hsk_header+0x003                               ";
         466 : dbg_instr = "hsk_copy4                                      ";
         467 : dbg_instr = "hsk_copy2                                      ";
         468 : dbg_instr = "hsk_copy1                                      ";
         469 : dbg_instr = "hsk_copy1+0x001                                ";
         470 : dbg_instr = "hsk_copy1+0x002                                ";
         471 : dbg_instr = "hsk_copy1+0x003                                ";
         472 : dbg_instr = "hsk_copy1+0x004                                ";
         473 : dbg_instr = "hsk_copy1+0x005                                ";
         474 : dbg_instr = "I2C_delay_hclk                                 ";
         475 : dbg_instr = "I2C_delay_med                                  ";
         476 : dbg_instr = "I2C_delay_med+0x001                            ";
         477 : dbg_instr = "I2C_delay_med+0x002                            ";
         478 : dbg_instr = "I2C_delay_short                                ";
         479 : dbg_instr = "I2C_delay_short+0x001                          ";
         480 : dbg_instr = "I2C_delay_short+0x002                          ";
         481 : dbg_instr = "I2C_delay_short+0x003                          ";
         482 : dbg_instr = "I2C_delay_short+0x004                          ";
         483 : dbg_instr = "I2C_delay_short+0x005                          ";
         484 : dbg_instr = "I2C_Rx_bit                                     ";
         485 : dbg_instr = "I2C_Rx_bit+0x001                               ";
         486 : dbg_instr = "I2C_Rx_bit+0x002                               ";
         487 : dbg_instr = "I2C_Rx_bit+0x003                               ";
         488 : dbg_instr = "I2C_Rx_bit+0x004                               ";
         489 : dbg_instr = "I2C_Rx_bit+0x005                               ";
         490 : dbg_instr = "I2C_Rx_bit+0x006                               ";
         491 : dbg_instr = "I2C_Rx_bit+0x007                               ";
         492 : dbg_instr = "I2C_Rx_bit+0x008                               ";
         493 : dbg_instr = "I2C_stop                                       ";
         494 : dbg_instr = "I2C_stop+0x001                                 ";
         495 : dbg_instr = "I2C_stop+0x002                                 ";
         496 : dbg_instr = "I2C_stop+0x003                                 ";
         497 : dbg_instr = "I2C_stop+0x004                                 ";
         498 : dbg_instr = "I2C_stop+0x005                                 ";
         499 : dbg_instr = "I2C_stop+0x006                                 ";
         500 : dbg_instr = "I2C_start                                      ";
         501 : dbg_instr = "I2C_start+0x001                                ";
         502 : dbg_instr = "I2C_start+0x002                                ";
         503 : dbg_instr = "I2C_start+0x003                                ";
         504 : dbg_instr = "I2C_start+0x004                                ";
         505 : dbg_instr = "I2C_start+0x005                                ";
         506 : dbg_instr = "I2C_start+0x006                                ";
         507 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK                         ";
         508 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x001                   ";
         509 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x002                   ";
         510 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x003                   ";
         511 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x004                   ";
         512 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x005                   ";
         513 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x006                   ";
         514 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x007                   ";
         515 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x008                   ";
         516 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x009                   ";
         517 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00a                   ";
         518 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00b                   ";
         519 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00c                   ";
         520 : dbg_instr = "I2C_Rx_byte                                    ";
         521 : dbg_instr = "I2C_Rx_byte+0x001                              ";
         522 : dbg_instr = "I2C_Rx_byte+0x002                              ";
         523 : dbg_instr = "I2C_Rx_byte+0x003                              ";
         524 : dbg_instr = "I2C_Rx_byte+0x004                              ";
         525 : dbg_instr = "I2C_test                                       ";
         526 : dbg_instr = "I2C_test+0x001                                 ";
         527 : dbg_instr = "I2C_test+0x002                                 ";
         528 : dbg_instr = "I2C_test+0x003                                 ";
         529 : dbg_instr = "I2C_user_tx_process                            ";
         530 : dbg_instr = "I2C_user_tx_process+0x001                      ";
         531 : dbg_instr = "I2C_user_tx_process+0x002                      ";
         532 : dbg_instr = "I2C_user_tx_process+0x003                      ";
         533 : dbg_instr = "I2C_user_tx_process+0x004                      ";
         534 : dbg_instr = "I2C_user_tx_process+0x005                      ";
         535 : dbg_instr = "I2C_user_tx_process+0x006                      ";
         536 : dbg_instr = "I2C_send3                                      ";
         537 : dbg_instr = "I2C_send3+0x001                                ";
         538 : dbg_instr = "I2C_send3+0x002                                ";
         539 : dbg_instr = "I2C_send1_prcs                                 ";
         540 : dbg_instr = "I2C_send1_prcs+0x001                           ";
         541 : dbg_instr = "I2C_send1_prcs+0x002                           ";
         542 : dbg_instr = "I2C_send1_prcs+0x003                           ";
         543 : dbg_instr = "I2C_send1_prcs+0x004                           ";
         544 : dbg_instr = "I2C_turfio_initialize                          ";
         545 : dbg_instr = "I2C_turfio_initialize+0x001                    ";
         546 : dbg_instr = "I2C_turfio_initialize+0x002                    ";
         547 : dbg_instr = "I2C_turfio_initialize+0x003                    ";
         548 : dbg_instr = "I2C_turfio_initialize+0x004                    ";
         549 : dbg_instr = "I2C_surf_initialize                            ";
         550 : dbg_instr = "I2C_surf_initialize+0x001                      ";
         551 : dbg_instr = "I2C_surf_initialize+0x002                      ";
         552 : dbg_instr = "I2C_surf_initialize+0x003                      ";
         553 : dbg_instr = "I2C_surf_initialize+0x004                      ";
         554 : dbg_instr = "I2C_surf_initialize+0x005                      ";
         555 : dbg_instr = "I2C_surf_initialize+0x006                      ";
         556 : dbg_instr = "I2C_surf_initialize+0x007                      ";
         557 : dbg_instr = "I2C_surf_initialize+0x008                      ";
         558 : dbg_instr = "I2C_surf_initialize+0x009                      ";
         559 : dbg_instr = "I2C_read_register                              ";
         560 : dbg_instr = "I2C_read_register+0x001                        ";
         561 : dbg_instr = "I2C_read_register+0x002                        ";
         562 : dbg_instr = "I2C_read_register+0x003                        ";
         563 : dbg_instr = "I2C_read_register+0x004                        ";
         564 : dbg_instr = "I2C_read                                       ";
         565 : dbg_instr = "I2C_read+0x001                                 ";
         566 : dbg_instr = "I2C_read+0x002                                 ";
         567 : dbg_instr = "I2C_read+0x003                                 ";
         568 : dbg_instr = "I2C_read+0x004                                 ";
         569 : dbg_instr = "I2C_read+0x005                                 ";
         570 : dbg_instr = "I2C_read+0x006                                 ";
         571 : dbg_instr = "I2C_read+0x007                                 ";
         572 : dbg_instr = "I2C_read+0x008                                 ";
         573 : dbg_instr = "I2C_read+0x009                                 ";
         574 : dbg_instr = "I2C_read+0x00a                                 ";
         575 : dbg_instr = "I2C_read+0x00b                                 ";
         576 : dbg_instr = "I2C_read+0x00c                                 ";
         577 : dbg_instr = "I2C_read+0x00d                                 ";
         578 : dbg_instr = "I2C_read+0x00e                                 ";
         579 : dbg_instr = "I2C_read+0x00f                                 ";
         580 : dbg_instr = "I2C_read+0x010                                 ";
         581 : dbg_instr = "I2C_read+0x011                                 ";
         582 : dbg_instr = "I2C_read+0x012                                 ";
         583 : dbg_instr = "I2C_read+0x013                                 ";
         584 : dbg_instr = "cobsFindZero                                   ";
         585 : dbg_instr = "cobsFindZero+0x001                             ";
         586 : dbg_instr = "cobsFindZero+0x002                             ";
         587 : dbg_instr = "cobsFindZero+0x003                             ";
         588 : dbg_instr = "cobsFindZero+0x004                             ";
         589 : dbg_instr = "cobsFindZero+0x005                             ";
         590 : dbg_instr = "cobsFindZero+0x006                             ";
         591 : dbg_instr = "cobsFindZero+0x007                             ";
         592 : dbg_instr = "cobsFixZero                                    ";
         593 : dbg_instr = "cobsFixZero+0x001                              ";
         594 : dbg_instr = "cobsFixZero+0x002                              ";
         595 : dbg_instr = "cobsFixZero+0x003                              ";
         596 : dbg_instr = "cobsFixZero+0x004                              ";
         597 : dbg_instr = "cobsEncode                                     ";
         598 : dbg_instr = "cobsEncode+0x001                               ";
         599 : dbg_instr = "cobsEncode+0x002                               ";
         600 : dbg_instr = "cobsEncode+0x003                               ";
         601 : dbg_instr = "cobsEncode+0x004                               ";
         602 : dbg_instr = "cobsEncode+0x005                               ";
         603 : dbg_instr = "cobsEncode+0x006                               ";
         604 : dbg_instr = "cobsEncode+0x007                               ";
         605 : dbg_instr = "cobsEncode+0x008                               ";
         606 : dbg_instr = "cobsEncode+0x009                               ";
         607 : dbg_instr = "cobsEncode+0x00a                               ";
         608 : dbg_instr = "cobsEncode+0x00b                               ";
         609 : dbg_instr = "cobsEncode+0x00c                               ";
         610 : dbg_instr = "cobsEncode+0x00d                               ";
         611 : dbg_instr = "cobsEncode+0x00e                               ";
         612 : dbg_instr = "icap_reboot                                    ";
         613 : dbg_instr = "icap_reboot+0x001                              ";
         614 : dbg_instr = "icap_reboot+0x002                              ";
         615 : dbg_instr = "icap_reboot+0x003                              ";
         616 : dbg_instr = "icap_reboot+0x004                              ";
         617 : dbg_instr = "icap_reboot+0x005                              ";
         618 : dbg_instr = "icap_reboot+0x006                              ";
         619 : dbg_instr = "icap_reboot+0x007                              ";
         620 : dbg_instr = "icap_reboot+0x008                              ";
         621 : dbg_instr = "icap_reboot+0x009                              ";
         622 : dbg_instr = "icap_reboot+0x00a                              ";
         623 : dbg_instr = "icap_reboot+0x00b                              ";
         624 : dbg_instr = "icap_reboot+0x00c                              ";
         625 : dbg_instr = "icap_reboot+0x00d                              ";
         626 : dbg_instr = "icap_reboot+0x00e                              ";
         627 : dbg_instr = "icap_reboot+0x00f                              ";
         628 : dbg_instr = "icap_reboot+0x010                              ";
         629 : dbg_instr = "icap_reboot+0x011                              ";
         630 : dbg_instr = "icap_reboot+0x012                              ";
         631 : dbg_instr = "icap_reboot+0x013                              ";
         632 : dbg_instr = "icap_reboot+0x014                              ";
         633 : dbg_instr = "icap_reboot+0x015                              ";
         634 : dbg_instr = "icap_reboot+0x016                              ";
         635 : dbg_instr = "icap_reboot+0x017                              ";
         636 : dbg_instr = "icap_reboot+0x018                              ";
         637 : dbg_instr = "icap_noop                                      ";
         638 : dbg_instr = "icap_3zero                                     ";
         639 : dbg_instr = "icap_3zero+0x001                               ";
         640 : dbg_instr = "icap_3zero+0x002                               ";
         641 : dbg_instr = "icap_3zero+0x003                               ";
         642 : dbg_instr = "icap_3zero+0x004                               ";
         643 : dbg_instr = "icap_3zero+0x005                               ";
         644 : dbg_instr = "icap_3zero+0x006                               ";
         645 : dbg_instr = "icap_3zero+0x007                               ";
         646 : dbg_instr = "icap_3zero+0x008                               ";
         647 : dbg_instr = "icap_3zero+0x009                               ";
         648 : dbg_instr = "icap_3zero+0x00a                               ";
         649 : dbg_instr = "icap_3zero+0x00b                               ";
         650 : dbg_instr = "icap_3zero+0x00c                               ";
         651 : dbg_instr = "icap_3zero+0x00d                               ";
         652 : dbg_instr = "icap_3zero+0x00e                               ";
         653 : dbg_instr = "icap_3zero+0x00f                               ";
         654 : dbg_instr = "icap_3zero+0x010                               ";
         655 : dbg_instr = "icap_3zero+0x011                               ";
         656 : dbg_instr = "icap_3zero+0x012                               ";
         657 : dbg_instr = "icap_3zero+0x013                               ";
         658 : dbg_instr = "icap_3zero+0x014                               ";
         659 : dbg_instr = "icap_3zero+0x015                               ";
         660 : dbg_instr = "icap_3zero+0x016                               ";
         661 : dbg_instr = "icap_3zero+0x017                               ";
         662 : dbg_instr = "icap_3zero+0x018                               ";
         663 : dbg_instr = "icap_3zero+0x019                               ";
         664 : dbg_instr = "icap_3zero+0x01a                               ";
         665 : dbg_instr = "icap_3zero+0x01b                               ";
         666 : dbg_instr = "icap_3zero+0x01c                               ";
         667 : dbg_instr = "icap_3zero+0x01d                               ";
         668 : dbg_instr = "icap_3zero+0x01e                               ";
         669 : dbg_instr = "icap_3zero+0x01f                               ";
         670 : dbg_instr = "icap_3zero+0x020                               ";
         671 : dbg_instr = "icap_3zero+0x021                               ";
         672 : dbg_instr = "icap_3zero+0x022                               ";
         673 : dbg_instr = "icap_3zero+0x023                               ";
         674 : dbg_instr = "icap_3zero+0x024                               ";
         675 : dbg_instr = "icap_3zero+0x025                               ";
         676 : dbg_instr = "icap_3zero+0x026                               ";
         677 : dbg_instr = "icap_3zero+0x027                               ";
         678 : dbg_instr = "icap_3zero+0x028                               ";
         679 : dbg_instr = "icap_3zero+0x029                               ";
         680 : dbg_instr = "icap_3zero+0x02a                               ";
         681 : dbg_instr = "icap_3zero+0x02b                               ";
         682 : dbg_instr = "icap_3zero+0x02c                               ";
         683 : dbg_instr = "icap_3zero+0x02d                               ";
         684 : dbg_instr = "icap_3zero+0x02e                               ";
         685 : dbg_instr = "icap_3zero+0x02f                               ";
         686 : dbg_instr = "icap_3zero+0x030                               ";
         687 : dbg_instr = "icap_3zero+0x031                               ";
         688 : dbg_instr = "icap_3zero+0x032                               ";
         689 : dbg_instr = "icap_3zero+0x033                               ";
         690 : dbg_instr = "icap_3zero+0x034                               ";
         691 : dbg_instr = "icap_3zero+0x035                               ";
         692 : dbg_instr = "icap_3zero+0x036                               ";
         693 : dbg_instr = "icap_3zero+0x037                               ";
         694 : dbg_instr = "icap_3zero+0x038                               ";
         695 : dbg_instr = "icap_3zero+0x039                               ";
         696 : dbg_instr = "icap_3zero+0x03a                               ";
         697 : dbg_instr = "icap_3zero+0x03b                               ";
         698 : dbg_instr = "icap_3zero+0x03c                               ";
         699 : dbg_instr = "icap_3zero+0x03d                               ";
         700 : dbg_instr = "icap_3zero+0x03e                               ";
         701 : dbg_instr = "icap_3zero+0x03f                               ";
         702 : dbg_instr = "icap_3zero+0x040                               ";
         703 : dbg_instr = "icap_3zero+0x041                               ";
         704 : dbg_instr = "icap_3zero+0x042                               ";
         705 : dbg_instr = "icap_3zero+0x043                               ";
         706 : dbg_instr = "icap_3zero+0x044                               ";
         707 : dbg_instr = "icap_3zero+0x045                               ";
         708 : dbg_instr = "icap_3zero+0x046                               ";
         709 : dbg_instr = "icap_3zero+0x047                               ";
         710 : dbg_instr = "icap_3zero+0x048                               ";
         711 : dbg_instr = "icap_3zero+0x049                               ";
         712 : dbg_instr = "icap_3zero+0x04a                               ";
         713 : dbg_instr = "icap_3zero+0x04b                               ";
         714 : dbg_instr = "icap_3zero+0x04c                               ";
         715 : dbg_instr = "icap_3zero+0x04d                               ";
         716 : dbg_instr = "icap_3zero+0x04e                               ";
         717 : dbg_instr = "icap_3zero+0x04f                               ";
         718 : dbg_instr = "icap_3zero+0x050                               ";
         719 : dbg_instr = "icap_3zero+0x051                               ";
         720 : dbg_instr = "icap_3zero+0x052                               ";
         721 : dbg_instr = "icap_3zero+0x053                               ";
         722 : dbg_instr = "icap_3zero+0x054                               ";
         723 : dbg_instr = "icap_3zero+0x055                               ";
         724 : dbg_instr = "icap_3zero+0x056                               ";
         725 : dbg_instr = "icap_3zero+0x057                               ";
         726 : dbg_instr = "icap_3zero+0x058                               ";
         727 : dbg_instr = "icap_3zero+0x059                               ";
         728 : dbg_instr = "icap_3zero+0x05a                               ";
         729 : dbg_instr = "icap_3zero+0x05b                               ";
         730 : dbg_instr = "icap_3zero+0x05c                               ";
         731 : dbg_instr = "icap_3zero+0x05d                               ";
         732 : dbg_instr = "icap_3zero+0x05e                               ";
         733 : dbg_instr = "icap_3zero+0x05f                               ";
         734 : dbg_instr = "icap_3zero+0x060                               ";
         735 : dbg_instr = "icap_3zero+0x061                               ";
         736 : dbg_instr = "icap_3zero+0x062                               ";
         737 : dbg_instr = "icap_3zero+0x063                               ";
         738 : dbg_instr = "icap_3zero+0x064                               ";
         739 : dbg_instr = "icap_3zero+0x065                               ";
         740 : dbg_instr = "icap_3zero+0x066                               ";
         741 : dbg_instr = "icap_3zero+0x067                               ";
         742 : dbg_instr = "icap_3zero+0x068                               ";
         743 : dbg_instr = "icap_3zero+0x069                               ";
         744 : dbg_instr = "icap_3zero+0x06a                               ";
         745 : dbg_instr = "icap_3zero+0x06b                               ";
         746 : dbg_instr = "icap_3zero+0x06c                               ";
         747 : dbg_instr = "icap_3zero+0x06d                               ";
         748 : dbg_instr = "icap_3zero+0x06e                               ";
         749 : dbg_instr = "icap_3zero+0x06f                               ";
         750 : dbg_instr = "icap_3zero+0x070                               ";
         751 : dbg_instr = "icap_3zero+0x071                               ";
         752 : dbg_instr = "icap_3zero+0x072                               ";
         753 : dbg_instr = "icap_3zero+0x073                               ";
         754 : dbg_instr = "icap_3zero+0x074                               ";
         755 : dbg_instr = "icap_3zero+0x075                               ";
         756 : dbg_instr = "icap_3zero+0x076                               ";
         757 : dbg_instr = "icap_3zero+0x077                               ";
         758 : dbg_instr = "icap_3zero+0x078                               ";
         759 : dbg_instr = "icap_3zero+0x079                               ";
         760 : dbg_instr = "icap_3zero+0x07a                               ";
         761 : dbg_instr = "icap_3zero+0x07b                               ";
         762 : dbg_instr = "icap_3zero+0x07c                               ";
         763 : dbg_instr = "icap_3zero+0x07d                               ";
         764 : dbg_instr = "icap_3zero+0x07e                               ";
         765 : dbg_instr = "icap_3zero+0x07f                               ";
         766 : dbg_instr = "icap_3zero+0x080                               ";
         767 : dbg_instr = "icap_3zero+0x081                               ";
         768 : dbg_instr = "icap_3zero+0x082                               ";
         769 : dbg_instr = "icap_3zero+0x083                               ";
         770 : dbg_instr = "icap_3zero+0x084                               ";
         771 : dbg_instr = "icap_3zero+0x085                               ";
         772 : dbg_instr = "icap_3zero+0x086                               ";
         773 : dbg_instr = "icap_3zero+0x087                               ";
         774 : dbg_instr = "icap_3zero+0x088                               ";
         775 : dbg_instr = "icap_3zero+0x089                               ";
         776 : dbg_instr = "icap_3zero+0x08a                               ";
         777 : dbg_instr = "icap_3zero+0x08b                               ";
         778 : dbg_instr = "icap_3zero+0x08c                               ";
         779 : dbg_instr = "icap_3zero+0x08d                               ";
         780 : dbg_instr = "icap_3zero+0x08e                               ";
         781 : dbg_instr = "icap_3zero+0x08f                               ";
         782 : dbg_instr = "icap_3zero+0x090                               ";
         783 : dbg_instr = "icap_3zero+0x091                               ";
         784 : dbg_instr = "icap_3zero+0x092                               ";
         785 : dbg_instr = "icap_3zero+0x093                               ";
         786 : dbg_instr = "icap_3zero+0x094                               ";
         787 : dbg_instr = "icap_3zero+0x095                               ";
         788 : dbg_instr = "icap_3zero+0x096                               ";
         789 : dbg_instr = "icap_3zero+0x097                               ";
         790 : dbg_instr = "icap_3zero+0x098                               ";
         791 : dbg_instr = "icap_3zero+0x099                               ";
         792 : dbg_instr = "icap_3zero+0x09a                               ";
         793 : dbg_instr = "icap_3zero+0x09b                               ";
         794 : dbg_instr = "icap_3zero+0x09c                               ";
         795 : dbg_instr = "icap_3zero+0x09d                               ";
         796 : dbg_instr = "icap_3zero+0x09e                               ";
         797 : dbg_instr = "icap_3zero+0x09f                               ";
         798 : dbg_instr = "icap_3zero+0x0a0                               ";
         799 : dbg_instr = "icap_3zero+0x0a1                               ";
         800 : dbg_instr = "icap_3zero+0x0a2                               ";
         801 : dbg_instr = "icap_3zero+0x0a3                               ";
         802 : dbg_instr = "icap_3zero+0x0a4                               ";
         803 : dbg_instr = "icap_3zero+0x0a5                               ";
         804 : dbg_instr = "icap_3zero+0x0a6                               ";
         805 : dbg_instr = "icap_3zero+0x0a7                               ";
         806 : dbg_instr = "icap_3zero+0x0a8                               ";
         807 : dbg_instr = "icap_3zero+0x0a9                               ";
         808 : dbg_instr = "icap_3zero+0x0aa                               ";
         809 : dbg_instr = "icap_3zero+0x0ab                               ";
         810 : dbg_instr = "icap_3zero+0x0ac                               ";
         811 : dbg_instr = "icap_3zero+0x0ad                               ";
         812 : dbg_instr = "icap_3zero+0x0ae                               ";
         813 : dbg_instr = "icap_3zero+0x0af                               ";
         814 : dbg_instr = "icap_3zero+0x0b0                               ";
         815 : dbg_instr = "icap_3zero+0x0b1                               ";
         816 : dbg_instr = "icap_3zero+0x0b2                               ";
         817 : dbg_instr = "icap_3zero+0x0b3                               ";
         818 : dbg_instr = "icap_3zero+0x0b4                               ";
         819 : dbg_instr = "icap_3zero+0x0b5                               ";
         820 : dbg_instr = "icap_3zero+0x0b6                               ";
         821 : dbg_instr = "icap_3zero+0x0b7                               ";
         822 : dbg_instr = "icap_3zero+0x0b8                               ";
         823 : dbg_instr = "icap_3zero+0x0b9                               ";
         824 : dbg_instr = "icap_3zero+0x0ba                               ";
         825 : dbg_instr = "icap_3zero+0x0bb                               ";
         826 : dbg_instr = "icap_3zero+0x0bc                               ";
         827 : dbg_instr = "icap_3zero+0x0bd                               ";
         828 : dbg_instr = "icap_3zero+0x0be                               ";
         829 : dbg_instr = "icap_3zero+0x0bf                               ";
         830 : dbg_instr = "icap_3zero+0x0c0                               ";
         831 : dbg_instr = "icap_3zero+0x0c1                               ";
         832 : dbg_instr = "icap_3zero+0x0c2                               ";
         833 : dbg_instr = "icap_3zero+0x0c3                               ";
         834 : dbg_instr = "icap_3zero+0x0c4                               ";
         835 : dbg_instr = "icap_3zero+0x0c5                               ";
         836 : dbg_instr = "icap_3zero+0x0c6                               ";
         837 : dbg_instr = "icap_3zero+0x0c7                               ";
         838 : dbg_instr = "icap_3zero+0x0c8                               ";
         839 : dbg_instr = "icap_3zero+0x0c9                               ";
         840 : dbg_instr = "icap_3zero+0x0ca                               ";
         841 : dbg_instr = "icap_3zero+0x0cb                               ";
         842 : dbg_instr = "icap_3zero+0x0cc                               ";
         843 : dbg_instr = "icap_3zero+0x0cd                               ";
         844 : dbg_instr = "icap_3zero+0x0ce                               ";
         845 : dbg_instr = "icap_3zero+0x0cf                               ";
         846 : dbg_instr = "icap_3zero+0x0d0                               ";
         847 : dbg_instr = "icap_3zero+0x0d1                               ";
         848 : dbg_instr = "icap_3zero+0x0d2                               ";
         849 : dbg_instr = "icap_3zero+0x0d3                               ";
         850 : dbg_instr = "icap_3zero+0x0d4                               ";
         851 : dbg_instr = "icap_3zero+0x0d5                               ";
         852 : dbg_instr = "icap_3zero+0x0d6                               ";
         853 : dbg_instr = "icap_3zero+0x0d7                               ";
         854 : dbg_instr = "icap_3zero+0x0d8                               ";
         855 : dbg_instr = "icap_3zero+0x0d9                               ";
         856 : dbg_instr = "icap_3zero+0x0da                               ";
         857 : dbg_instr = "icap_3zero+0x0db                               ";
         858 : dbg_instr = "icap_3zero+0x0dc                               ";
         859 : dbg_instr = "icap_3zero+0x0dd                               ";
         860 : dbg_instr = "icap_3zero+0x0de                               ";
         861 : dbg_instr = "icap_3zero+0x0df                               ";
         862 : dbg_instr = "icap_3zero+0x0e0                               ";
         863 : dbg_instr = "icap_3zero+0x0e1                               ";
         864 : dbg_instr = "icap_3zero+0x0e2                               ";
         865 : dbg_instr = "icap_3zero+0x0e3                               ";
         866 : dbg_instr = "icap_3zero+0x0e4                               ";
         867 : dbg_instr = "icap_3zero+0x0e5                               ";
         868 : dbg_instr = "icap_3zero+0x0e6                               ";
         869 : dbg_instr = "icap_3zero+0x0e7                               ";
         870 : dbg_instr = "icap_3zero+0x0e8                               ";
         871 : dbg_instr = "icap_3zero+0x0e9                               ";
         872 : dbg_instr = "icap_3zero+0x0ea                               ";
         873 : dbg_instr = "icap_3zero+0x0eb                               ";
         874 : dbg_instr = "icap_3zero+0x0ec                               ";
         875 : dbg_instr = "icap_3zero+0x0ed                               ";
         876 : dbg_instr = "icap_3zero+0x0ee                               ";
         877 : dbg_instr = "icap_3zero+0x0ef                               ";
         878 : dbg_instr = "icap_3zero+0x0f0                               ";
         879 : dbg_instr = "icap_3zero+0x0f1                               ";
         880 : dbg_instr = "icap_3zero+0x0f2                               ";
         881 : dbg_instr = "icap_3zero+0x0f3                               ";
         882 : dbg_instr = "icap_3zero+0x0f4                               ";
         883 : dbg_instr = "icap_3zero+0x0f5                               ";
         884 : dbg_instr = "icap_3zero+0x0f6                               ";
         885 : dbg_instr = "icap_3zero+0x0f7                               ";
         886 : dbg_instr = "icap_3zero+0x0f8                               ";
         887 : dbg_instr = "icap_3zero+0x0f9                               ";
         888 : dbg_instr = "icap_3zero+0x0fa                               ";
         889 : dbg_instr = "icap_3zero+0x0fb                               ";
         890 : dbg_instr = "icap_3zero+0x0fc                               ";
         891 : dbg_instr = "icap_3zero+0x0fd                               ";
         892 : dbg_instr = "icap_3zero+0x0fe                               ";
         893 : dbg_instr = "icap_3zero+0x0ff                               ";
         894 : dbg_instr = "icap_3zero+0x100                               ";
         895 : dbg_instr = "icap_3zero+0x101                               ";
         896 : dbg_instr = "icap_3zero+0x102                               ";
         897 : dbg_instr = "icap_3zero+0x103                               ";
         898 : dbg_instr = "icap_3zero+0x104                               ";
         899 : dbg_instr = "icap_3zero+0x105                               ";
         900 : dbg_instr = "icap_3zero+0x106                               ";
         901 : dbg_instr = "icap_3zero+0x107                               ";
         902 : dbg_instr = "icap_3zero+0x108                               ";
         903 : dbg_instr = "icap_3zero+0x109                               ";
         904 : dbg_instr = "icap_3zero+0x10a                               ";
         905 : dbg_instr = "icap_3zero+0x10b                               ";
         906 : dbg_instr = "icap_3zero+0x10c                               ";
         907 : dbg_instr = "icap_3zero+0x10d                               ";
         908 : dbg_instr = "icap_3zero+0x10e                               ";
         909 : dbg_instr = "icap_3zero+0x10f                               ";
         910 : dbg_instr = "icap_3zero+0x110                               ";
         911 : dbg_instr = "icap_3zero+0x111                               ";
         912 : dbg_instr = "icap_3zero+0x112                               ";
         913 : dbg_instr = "icap_3zero+0x113                               ";
         914 : dbg_instr = "icap_3zero+0x114                               ";
         915 : dbg_instr = "icap_3zero+0x115                               ";
         916 : dbg_instr = "icap_3zero+0x116                               ";
         917 : dbg_instr = "icap_3zero+0x117                               ";
         918 : dbg_instr = "icap_3zero+0x118                               ";
         919 : dbg_instr = "icap_3zero+0x119                               ";
         920 : dbg_instr = "icap_3zero+0x11a                               ";
         921 : dbg_instr = "icap_3zero+0x11b                               ";
         922 : dbg_instr = "icap_3zero+0x11c                               ";
         923 : dbg_instr = "icap_3zero+0x11d                               ";
         924 : dbg_instr = "icap_3zero+0x11e                               ";
         925 : dbg_instr = "icap_3zero+0x11f                               ";
         926 : dbg_instr = "icap_3zero+0x120                               ";
         927 : dbg_instr = "icap_3zero+0x121                               ";
         928 : dbg_instr = "icap_3zero+0x122                               ";
         929 : dbg_instr = "icap_3zero+0x123                               ";
         930 : dbg_instr = "icap_3zero+0x124                               ";
         931 : dbg_instr = "icap_3zero+0x125                               ";
         932 : dbg_instr = "icap_3zero+0x126                               ";
         933 : dbg_instr = "icap_3zero+0x127                               ";
         934 : dbg_instr = "icap_3zero+0x128                               ";
         935 : dbg_instr = "icap_3zero+0x129                               ";
         936 : dbg_instr = "icap_3zero+0x12a                               ";
         937 : dbg_instr = "icap_3zero+0x12b                               ";
         938 : dbg_instr = "icap_3zero+0x12c                               ";
         939 : dbg_instr = "icap_3zero+0x12d                               ";
         940 : dbg_instr = "icap_3zero+0x12e                               ";
         941 : dbg_instr = "icap_3zero+0x12f                               ";
         942 : dbg_instr = "icap_3zero+0x130                               ";
         943 : dbg_instr = "icap_3zero+0x131                               ";
         944 : dbg_instr = "icap_3zero+0x132                               ";
         945 : dbg_instr = "icap_3zero+0x133                               ";
         946 : dbg_instr = "icap_3zero+0x134                               ";
         947 : dbg_instr = "icap_3zero+0x135                               ";
         948 : dbg_instr = "icap_3zero+0x136                               ";
         949 : dbg_instr = "icap_3zero+0x137                               ";
         950 : dbg_instr = "icap_3zero+0x138                               ";
         951 : dbg_instr = "icap_3zero+0x139                               ";
         952 : dbg_instr = "icap_3zero+0x13a                               ";
         953 : dbg_instr = "icap_3zero+0x13b                               ";
         954 : dbg_instr = "icap_3zero+0x13c                               ";
         955 : dbg_instr = "icap_3zero+0x13d                               ";
         956 : dbg_instr = "icap_3zero+0x13e                               ";
         957 : dbg_instr = "icap_3zero+0x13f                               ";
         958 : dbg_instr = "icap_3zero+0x140                               ";
         959 : dbg_instr = "icap_3zero+0x141                               ";
         960 : dbg_instr = "icap_3zero+0x142                               ";
         961 : dbg_instr = "icap_3zero+0x143                               ";
         962 : dbg_instr = "icap_3zero+0x144                               ";
         963 : dbg_instr = "icap_3zero+0x145                               ";
         964 : dbg_instr = "icap_3zero+0x146                               ";
         965 : dbg_instr = "icap_3zero+0x147                               ";
         966 : dbg_instr = "icap_3zero+0x148                               ";
         967 : dbg_instr = "icap_3zero+0x149                               ";
         968 : dbg_instr = "icap_3zero+0x14a                               ";
         969 : dbg_instr = "icap_3zero+0x14b                               ";
         970 : dbg_instr = "icap_3zero+0x14c                               ";
         971 : dbg_instr = "icap_3zero+0x14d                               ";
         972 : dbg_instr = "icap_3zero+0x14e                               ";
         973 : dbg_instr = "icap_3zero+0x14f                               ";
         974 : dbg_instr = "icap_3zero+0x150                               ";
         975 : dbg_instr = "icap_3zero+0x151                               ";
         976 : dbg_instr = "icap_3zero+0x152                               ";
         977 : dbg_instr = "icap_3zero+0x153                               ";
         978 : dbg_instr = "icap_3zero+0x154                               ";
         979 : dbg_instr = "icap_3zero+0x155                               ";
         980 : dbg_instr = "icap_3zero+0x156                               ";
         981 : dbg_instr = "icap_3zero+0x157                               ";
         982 : dbg_instr = "icap_3zero+0x158                               ";
         983 : dbg_instr = "icap_3zero+0x159                               ";
         984 : dbg_instr = "icap_3zero+0x15a                               ";
         985 : dbg_instr = "icap_3zero+0x15b                               ";
         986 : dbg_instr = "icap_3zero+0x15c                               ";
         987 : dbg_instr = "icap_3zero+0x15d                               ";
         988 : dbg_instr = "icap_3zero+0x15e                               ";
         989 : dbg_instr = "icap_3zero+0x15f                               ";
         990 : dbg_instr = "icap_3zero+0x160                               ";
         991 : dbg_instr = "icap_3zero+0x161                               ";
         992 : dbg_instr = "icap_3zero+0x162                               ";
         993 : dbg_instr = "icap_3zero+0x163                               ";
         994 : dbg_instr = "icap_3zero+0x164                               ";
         995 : dbg_instr = "icap_3zero+0x165                               ";
         996 : dbg_instr = "icap_3zero+0x166                               ";
         997 : dbg_instr = "icap_3zero+0x167                               ";
         998 : dbg_instr = "icap_3zero+0x168                               ";
         999 : dbg_instr = "icap_3zero+0x169                               ";
         1000 : dbg_instr = "icap_3zero+0x16a                               ";
         1001 : dbg_instr = "icap_3zero+0x16b                               ";
         1002 : dbg_instr = "icap_3zero+0x16c                               ";
         1003 : dbg_instr = "icap_3zero+0x16d                               ";
         1004 : dbg_instr = "icap_3zero+0x16e                               ";
         1005 : dbg_instr = "icap_3zero+0x16f                               ";
         1006 : dbg_instr = "icap_3zero+0x170                               ";
         1007 : dbg_instr = "icap_3zero+0x171                               ";
         1008 : dbg_instr = "icap_3zero+0x172                               ";
         1009 : dbg_instr = "icap_3zero+0x173                               ";
         1010 : dbg_instr = "icap_3zero+0x174                               ";
         1011 : dbg_instr = "icap_3zero+0x175                               ";
         1012 : dbg_instr = "icap_3zero+0x176                               ";
         1013 : dbg_instr = "icap_3zero+0x177                               ";
         1014 : dbg_instr = "icap_3zero+0x178                               ";
         1015 : dbg_instr = "icap_3zero+0x179                               ";
         1016 : dbg_instr = "icap_3zero+0x17a                               ";
         1017 : dbg_instr = "icap_3zero+0x17b                               ";
         1018 : dbg_instr = "icap_3zero+0x17c                               ";
         1019 : dbg_instr = "icap_3zero+0x17d                               ";
         1020 : dbg_instr = "icap_3zero+0x17e                               ";
         1021 : dbg_instr = "icap_3zero+0x17f                               ";
         1022 : dbg_instr = "icap_3zero+0x180                               ";
         1023 : dbg_instr = "icap_3zero+0x181                               ";
     endcase
   end
// synthesis translate_on


BRAM_TDP_MACRO #(
    .BRAM_SIZE("18Kb"),
    .DOA_REG(0),
    .DOB_REG(0),
    .INIT_A(18'h00000),
    .INIT_B(18'h00000),
    .READ_WIDTH_A(18),
    .WRITE_WIDTH_A(18),
    .READ_WIDTH_B(BRAM_PORT_WIDTH),
    .WRITE_WIDTH_B(BRAM_PORT_WIDTH),
    .SIM_COLLISION_CHECK("ALL"),
    .WRITE_MODE_A("WRITE_FIRST"),
    .WRITE_MODE_B("WRITE_FIRST"),
    // The following INIT_xx declarations specify the initial contents of the RAM
    // Address 0 to 255
    .INIT_00(256'h9001700011002010D201920B900A70016EE02004005401050000000020040026),
    .INIT_01(256'h202590017000202590007000201DCED0DD0B7D036EE04ED011802020D202C010),
    .INIT_02(256'h4008020DAA10110110801137B00801EDB03FB80B90019001700031FFD1C01101),
    .INIT_03(256'hD21132FE92116036400E11010225AA10203AD00111380220F000307F70FFE02C),
    .INIT_04(256'h10011E0070001D011E001180B01B7001F210F212F214F2131200F216F2171200),
    .INIT_05(256'h60C1D700B71720A2D2042087D203207AD2022076D201B210500080019F101100),
    .INIT_06(256'h130412046071D200B212F314F21343801280D000F314F213B3009201B314B213),
    .INIT_07(256'hF2210100F220A2201234B21120EEC230B300B2125000F311F210130012012073),
    .INIT_08(256'hB21206704706B71116C002341621F22101005000F2101203B02D0211142101F4),
    .INIT_09(256'h1202F71120EED7041701B711C4601601C560B520B421063043064306430600FB),
    .INIT_0A(256'h4700440046061710B620B521B42202341622F421149060BCD204B2115000F210),
    .INIT_0B(256'hD2FC920FD2FD920E5000F2111205D6FBD5FAD4F9D7F8E0B24608450E5608E0AD),
    .INIT_0C(256'h141FB41760C8D71F97011201E370A3201218171F60D9D80060C6D701B81620EE),
    .INIT_0D(256'hF61836E102340960161F0680F32120E9D800F4151401F418B31834E1021101F4),
    .INIT_0E(256'hD200B2125000F216F217120001EDF815180160E1D91F12019901E320A3901219),
    .INIT_0F(256'h5000E0FC420E130113FF5000D211720192115000F3101300F212420E128060F2),

    // Address 256 to 511
    .INIT_10(256'h61C8C2F0928150008001D00B70036E00010D1000C0E05000A230133800FBB212),
    .INIT_11(256'h2144D210928261CCD5006116D183910105608610118401401500E1CAD43C9483),
    .INIT_12(256'h61CAD200216ED2CA2187D2C92174D2C82132D20F2160D21321B5D2122152D211),
    .INIT_13(256'hB20C0920D287B20B0920D286B20A0920D285B209D984B908B05301CE21C001CE),
    .INIT_14(256'hD5FE150601D315C611860920D28592FDD98499FCB10301CE21BD11890920D288),
    .INIT_15(256'h21BD615BD5F8150401D215C011860920D28592F9D98499F8B1E301CE21BD614D),
    .INIT_16(256'h9585948421BD6169D5FC150601D315C411860920D28592FBD98499FAB10301CE),
    .INIT_17(256'hD3114340232072FF24209485931192842180D200928301CE5000026497879686),
    .INIT_18(256'hB0042192D300B31721A3D200B013928301CE21C0B013D385D284832013009211),
    .INIT_19(256'h82406199920115011401E340835015851418F2179201F7169784F31521C0B005),
    .INIT_1A(256'hC3100930A340190011841418D28321C0B004B00361A9D200B21521C0D285D484),
    .INIT_1B(256'hC910190179FF1186D2850920B200D9841907B02301CE21BD61AD920111011401),
    .INIT_1C(256'hD281928021C4130A21C4130B21C4130C5000E2301201A230130901C413080255),
    .INIT_1D(256'h12044300500001DE01DE01DE5000110115010920C210825001D401D35000DF80),
    .INIT_1E(256'hB02D01DEB00E5000B00DD201920C01DA01DEB02D01DAB01E50004308E1E04200),
    .INIT_1F(256'h01DADB0E4B004A021B015000B00D01DEB00E01DBB02DB01E500001DEB01E01DB),

    // Address 512 to 767
    .INIT_20(256'h01ED01FB01F45000E2094A0001E41A01500001DA01E4E1FCB00D01DA01DEB02D),
    .INIT_21(256'h500001ED021101F4F620F5211423F42250006211D41F9401900001FBAA405000),
    .INIT_22(256'hF421500002181601158D14D802181607151E14D4FA23221B16051421F4211490),
    .INIT_23(256'hB02D01DAD20E4200D621EA600208900001FB5A01BA2101F40211142101F4F520),
    .INIT_24(256'h224917011000D20082701000C7600750500001ED01DA6239D61F9601B00D01DA),
    .INIT_25(256'hD2080250D20015018250D708977F024816859683158050000270170187500248),
    .INIT_26(256'hB300027DB660B550B990BAA0BFF0BFF0BFF0BFF0D21112105000B008A25BC560),
    .INIT_27(256'hB000B000B200B0F0027EB010B800B000B300D700D600D500D400B010B000B020),
    .INIT_28(256'h100010001000100010001000100010001000100010001000100010005000B000),
    .INIT_29(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_2A(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_2B(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_2C(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_2D(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_2E(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_2F(256'h1000100010001000100010001000100010001000100010001000100010001000),

    // Address 768 to 1023
    .INIT_30(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_31(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_32(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_33(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_34(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_35(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_36(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_37(256'h2007100010001000100010001000100010001000100010001000100010001000),
    .INIT_38(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_39(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3A(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3B(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3C(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3D(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3E(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3F(256'h0000000000000000000000000000000000000000000000000000000000000000),

    // The next set of INITP_xx are for the parity bits
    // Address 0 to 255
    .INITP_00(256'hA84C0A820D293A50D37774A00C0BAA288358C283610AAAD5AEBC8432B3036A0A),
    .INITP_01(256'hB52838934A8A7560984B621A4D581DD288A2AB535402234A2D4981561422A8A2),

    // Address 256 to 511
    .INITP_02(256'h8000D2A00B58188AB58188AB58188A86186188AADDDDDDDDD3754434D2A0B218),
    .INITP_03(256'hA52AAAAAAA82AA9D1AA958AA8888A42290922AD5900AAD2A7560262AB4D8AA90),

    // Address 512 to 767
    .INITP_04(256'hAAAAAAAAAAAAA8ADB52642169D34AB5AA96B828AA8080A08AAA2B5E2AAD8ABAA),
    .INITP_05(256'h000000000000000000000000000000000000000000000000000000000000000A),

    // Address 768 to 1023
    .INITP_06(256'h8000000000000000000000000000000000000000000000000000000000000000),
    .INITP_07(256'h0000000000000000000000000000000000000000000000000000000000000000),

    // Output value upon SSR assertion
    .SRVAL_A(18'h000000),
    .SRVAL_B({BRAM_PORT_WIDTH{1'b0}})
) ramdp_1024_x_18(
    .DIA (18'h00000),
    .ENA (enable),
    .WEA ({BRAM_WE_WIDTH{1'b0}}),
    .RSTA(1'b0),
    .CLKA (clk),
    .ADDRA (address),
    // swizzle the parity bits into their proper place
    .DOA ({instruction[17],instruction[15:8],instruction[16],instruction[7:0]}),
    .DIB (bram_dat_i),
    // it's your OWN damn job to deswizzle outside this module
    .DOB (bram_dat_o),
    .ENB (bram_en_i),
    .WEB ({BRAM_WE_WIDTH{bram_we_i}}),
    .RSTB(1'b0),
    .CLKB (clk),
    .ADDRB(bram_adr_i)
);

endmodule
