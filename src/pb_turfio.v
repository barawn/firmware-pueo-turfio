/*
 * == pblaze-cc ==
 * source : pb_turfio.c
 * create : Wed Apr  2 11:35:29 2025
 * modify : Wed Apr  2 11:35:29 2025
 */
`timescale 1 ps / 1ps

/* 
 * == pblaze-as ==
 * source : pb_turfio.s
 * create : Wed Apr  2 11:36:50 2025
 * modify : Wed Apr  2 11:36:50 2025
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
         83 : dbg_instr = "update_housekeeping                            ";
         84 : dbg_instr = "update_housekeeping+0x001                      ";
         85 : dbg_instr = "update_housekeeping+0x002                      ";
         86 : dbg_instr = "update_housekeeping+0x003                      ";
         87 : dbg_instr = "update_housekeeping+0x004                      ";
         88 : dbg_instr = "update_housekeeping+0x005                      ";
         89 : dbg_instr = "update_housekeeping+0x006                      ";
         90 : dbg_instr = "update_housekeeping+0x007                      ";
         91 : dbg_instr = "update_housekeeping+0x008                      ";
         92 : dbg_instr = "IDLE_WAIT                                      ";
         93 : dbg_instr = "IDLE_WAIT+0x001                                ";
         94 : dbg_instr = "IDLE_WAIT+0x002                                ";
         95 : dbg_instr = "IDLE_WAIT+0x003                                ";
         96 : dbg_instr = "IDLE_WAIT+0x004                                ";
         97 : dbg_instr = "IDLE_WAIT+0x005                                ";
         98 : dbg_instr = "IDLE_WAIT+0x006                                ";
         99 : dbg_instr = "IDLE_WAIT+0x007                                ";
         100 : dbg_instr = "IDLE_WAIT+0x008                                ";
         101 : dbg_instr = "IDLE_WAIT+0x009                                ";
         102 : dbg_instr = "IDLE_WAIT+0x00a                                ";
         103 : dbg_instr = "IDLE_WAIT+0x00b                                ";
         104 : dbg_instr = "IDLE_WAIT+0x00c                                ";
         105 : dbg_instr = "IDLE_WAIT+0x00d                                ";
         106 : dbg_instr = "IDLE_WAIT+0x00e                                ";
         107 : dbg_instr = "IDLE_WAIT+0x00f                                ";
         108 : dbg_instr = "IDLE_WAIT+0x010                                ";
         109 : dbg_instr = "IDLE_WAIT+0x011                                ";
         110 : dbg_instr = "IDLE_WAIT+0x012                                ";
         111 : dbg_instr = "IDLE_WAIT+0x013                                ";
         112 : dbg_instr = "IDLE_WAIT+0x014                                ";
         113 : dbg_instr = "IDLE_WAIT+0x015                                ";
         114 : dbg_instr = "IDLE_WAIT+0x016                                ";
         115 : dbg_instr = "IDLE_WAIT+0x017                                ";
         116 : dbg_instr = "IDLE_WAIT+0x018                                ";
         117 : dbg_instr = "SURF_CHECK                                     ";
         118 : dbg_instr = "SURF_CHECK+0x001                               ";
         119 : dbg_instr = "SURF_CHECK+0x002                               ";
         120 : dbg_instr = "SURF_CHECK+0x003                               ";
         121 : dbg_instr = "SURF_WRITE_REG                                 ";
         122 : dbg_instr = "SURF_WRITE_REG+0x001                           ";
         123 : dbg_instr = "SURF_WRITE_REG+0x002                           ";
         124 : dbg_instr = "SURF_WRITE_REG+0x003                           ";
         125 : dbg_instr = "SURF_WRITE_REG+0x004                           ";
         126 : dbg_instr = "SURF_WRITE_REG+0x005                           ";
         127 : dbg_instr = "SURF_WRITE_REG+0x006                           ";
         128 : dbg_instr = "SURF_WRITE_REG+0x007                           ";
         129 : dbg_instr = "SURF_WRITE_REG+0x008                           ";
         130 : dbg_instr = "SURF_WRITE_REG+0x009                           ";
         131 : dbg_instr = "SURF_WRITE_REG+0x00a                           ";
         132 : dbg_instr = "SURF_WRITE_REG+0x00b                           ";
         133 : dbg_instr = "SURF_WRITE_REG+0x00c                           ";
         134 : dbg_instr = "SURF_READ_REG                                  ";
         135 : dbg_instr = "SURF_READ_REG+0x001                            ";
         136 : dbg_instr = "SURF_READ_REG+0x002                            ";
         137 : dbg_instr = "SURF_READ_REG+0x003                            ";
         138 : dbg_instr = "SURF_READ_REG+0x004                            ";
         139 : dbg_instr = "SURF_READ_REG+0x005                            ";
         140 : dbg_instr = "SURF_READ_REG+0x006                            ";
         141 : dbg_instr = "SURF_READ_REG+0x007                            ";
         142 : dbg_instr = "SURF_READ_REG+0x008                            ";
         143 : dbg_instr = "SURF_READ_REG+0x009                            ";
         144 : dbg_instr = "SURF_READ_REG+0x00a                            ";
         145 : dbg_instr = "SURF_READ_REG+0x00b                            ";
         146 : dbg_instr = "SURF_READ_REG+0x00c                            ";
         147 : dbg_instr = "SURF_READ_REG+0x00d                            ";
         148 : dbg_instr = "SURF_READ_REG+0x00e                            ";
         149 : dbg_instr = "SURF_READ_REG+0x00f                            ";
         150 : dbg_instr = "SURF_READ_REG+0x010                            ";
         151 : dbg_instr = "SURF_READ_REG+0x011                            ";
         152 : dbg_instr = "SURF_READ_REG+0x012                            ";
         153 : dbg_instr = "SURF_READ_REG+0x013                            ";
         154 : dbg_instr = "SURF_READ_REG+0x014                            ";
         155 : dbg_instr = "SURF_READ_REG+0x015                            ";
         156 : dbg_instr = "SURF_READ_REG+0x016                            ";
         157 : dbg_instr = "SURF_READ_REG+0x017                            ";
         158 : dbg_instr = "SURF_READ_REG+0x018                            ";
         159 : dbg_instr = "SURF_READ_REG+0x019                            ";
         160 : dbg_instr = "SURF_READ_REG+0x01a                            ";
         161 : dbg_instr = "TURFIO                                         ";
         162 : dbg_instr = "TURFIO+0x001                                   ";
         163 : dbg_instr = "TURFIO+0x002                                   ";
         164 : dbg_instr = "TURFIO+0x003                                   ";
         165 : dbg_instr = "TURFIO+0x004                                   ";
         166 : dbg_instr = "TURFIO+0x005                                   ";
         167 : dbg_instr = "TURFIO+0x006                                   ";
         168 : dbg_instr = "TURFIO+0x007                                   ";
         169 : dbg_instr = "TURFIO+0x008                                   ";
         170 : dbg_instr = "TURFIO+0x009                                   ";
         171 : dbg_instr = "TURFIO+0x00a                                   ";
         172 : dbg_instr = "TURFIO+0x00b                                   ";
         173 : dbg_instr = "TURFIO+0x00c                                   ";
         174 : dbg_instr = "TURFIO+0x00d                                   ";
         175 : dbg_instr = "TURFIO+0x00e                                   ";
         176 : dbg_instr = "TURFIO+0x00f                                   ";
         177 : dbg_instr = "TURFIO+0x010                                   ";
         178 : dbg_instr = "TURFIO+0x011                                   ";
         179 : dbg_instr = "TURFIO+0x012                                   ";
         180 : dbg_instr = "TURFIO+0x013                                   ";
         181 : dbg_instr = "TURFIO+0x014                                   ";
         182 : dbg_instr = "TURFIO+0x015                                   ";
         183 : dbg_instr = "TURFIO+0x016                                   ";
         184 : dbg_instr = "TURFIO+0x017                                   ";
         185 : dbg_instr = "TURFIO+0x018                                   ";
         186 : dbg_instr = "TURFIO+0x019                                   ";
         187 : dbg_instr = "TURFIO+0x01a                                   ";
         188 : dbg_instr = "TURFIO+0x01b                                   ";
         189 : dbg_instr = "TURFIO+0x01c                                   ";
         190 : dbg_instr = "TURFIO+0x01d                                   ";
         191 : dbg_instr = "TURFIO+0x01e                                   ";
         192 : dbg_instr = "PMBUS                                          ";
         193 : dbg_instr = "PMBUS+0x001                                    ";
         194 : dbg_instr = "PMBUS+0x002                                    ";
         195 : dbg_instr = "PMBUS+0x003                                    ";
         196 : dbg_instr = "PMBUS+0x004                                    ";
         197 : dbg_instr = "WRITE_PMBUS                                    ";
         198 : dbg_instr = "WRITE_PMBUS+0x001                              ";
         199 : dbg_instr = "WRITE_PMBUS+0x002                              ";
         200 : dbg_instr = "WRITE_PMBUS+0x003                              ";
         201 : dbg_instr = "WRITE_PMBUS+0x004                              ";
         202 : dbg_instr = "WRITE_PMBUS+0x005                              ";
         203 : dbg_instr = "WRITE_PMBUS+0x006                              ";
         204 : dbg_instr = "WRITE_PMBUS+0x007                              ";
         205 : dbg_instr = "WRITE_PMBUS+0x008                              ";
         206 : dbg_instr = "WRITE_PMBUS+0x009                              ";
         207 : dbg_instr = "WRITE_PMBUS+0x00a                              ";
         208 : dbg_instr = "WRITE_PMBUS+0x00b                              ";
         209 : dbg_instr = "WRITE_PMBUS+0x00c                              ";
         210 : dbg_instr = "WRITE_PMBUS+0x00d                              ";
         211 : dbg_instr = "WRITE_PMBUS+0x00e                              ";
         212 : dbg_instr = "WRITE_PMBUS+0x00f                              ";
         213 : dbg_instr = "WRITE_PMBUS+0x010                              ";
         214 : dbg_instr = "WRITE_PMBUS+0x011                              ";
         215 : dbg_instr = "WRITE_PMBUS+0x012                              ";
         216 : dbg_instr = "READ_PMBUS                                     ";
         217 : dbg_instr = "READ_PMBUS+0x001                               ";
         218 : dbg_instr = "READ_PMBUS+0x002                               ";
         219 : dbg_instr = "READ_PMBUS+0x003                               ";
         220 : dbg_instr = "READ_PMBUS+0x004                               ";
         221 : dbg_instr = "READ_PMBUS+0x005                               ";
         222 : dbg_instr = "READ_PMBUS+0x006                               ";
         223 : dbg_instr = "READ_PMBUS+0x007                               ";
         224 : dbg_instr = "READ_PMBUS+0x008                               ";
         225 : dbg_instr = "READ_PMBUS+0x009                               ";
         226 : dbg_instr = "READ_PMBUS+0x00a                               ";
         227 : dbg_instr = "READ_PMBUS+0x00b                               ";
         228 : dbg_instr = "READ_PMBUS+0x00c                               ";
         229 : dbg_instr = "READ_PMBUS+0x00d                               ";
         230 : dbg_instr = "READ_PMBUS+0x00e                               ";
         231 : dbg_instr = "READ_PMBUS+0x00f                               ";
         232 : dbg_instr = "FINISH_PMBUS                                   ";
         233 : dbg_instr = "FINISH_PMBUS+0x001                             ";
         234 : dbg_instr = "FINISH_PMBUS+0x002                             ";
         235 : dbg_instr = "FINISH_PMBUS+0x003                             ";
         236 : dbg_instr = "FINISH_PMBUS+0x004                             ";
         237 : dbg_instr = "hskNextDevice                                  ";
         238 : dbg_instr = "hskNextDevice+0x001                            ";
         239 : dbg_instr = "hskNextDevice+0x002                            ";
         240 : dbg_instr = "hskNextDevice+0x003                            ";
         241 : dbg_instr = "hskNextDevice+0x004                            ";
         242 : dbg_instr = "hskNextDevice+0x005                            ";
         243 : dbg_instr = "hskNextDevice+0x006                            ";
         244 : dbg_instr = "hskNextDevice+0x007                            ";
         245 : dbg_instr = "hskNextDevice+0x008                            ";
         246 : dbg_instr = "hskNextDevice+0x009                            ";
         247 : dbg_instr = "hskNextDevice+0x00a                            ";
         248 : dbg_instr = "hskNextDevice+0x00b                            ";
         249 : dbg_instr = "hskNextDevice+0x00c                            ";
         250 : dbg_instr = "hskCountDevice                                 ";
         251 : dbg_instr = "hskCountDevice+0x001                           ";
         252 : dbg_instr = "hskCountDevice+0x002                           ";
         253 : dbg_instr = "hskCountDevice+0x003                           ";
         254 : dbg_instr = "hskCountDevice+0x004                           ";
         255 : dbg_instr = "hskGetDeviceAddress                            ";
         256 : dbg_instr = "hskGetDeviceAddress+0x001                      ";
         257 : dbg_instr = "hskGetDeviceAddress+0x002                      ";
         258 : dbg_instr = "hskGetDeviceAddress+0x003                      ";
         259 : dbg_instr = "hskGetDeviceAddress+0x004                      ";
         260 : dbg_instr = "handle_serial                                  ";
         261 : dbg_instr = "handle_serial+0x001                            ";
         262 : dbg_instr = "handle_serial+0x002                            ";
         263 : dbg_instr = "handle_serial+0x003                            ";
         264 : dbg_instr = "handle_serial+0x004                            ";
         265 : dbg_instr = "handle_serial+0x005                            ";
         266 : dbg_instr = "handle_serial+0x006                            ";
         267 : dbg_instr = "handle_serial+0x007                            ";
         268 : dbg_instr = "parse_serial                                   ";
         269 : dbg_instr = "parse_serial+0x001                             ";
         270 : dbg_instr = "parse_serial+0x002                             ";
         271 : dbg_instr = "parse_serial+0x003                             ";
         272 : dbg_instr = "parse_serial+0x004                             ";
         273 : dbg_instr = "parse_serial+0x005                             ";
         274 : dbg_instr = "parse_serial+0x006                             ";
         275 : dbg_instr = "parse_serial+0x007                             ";
         276 : dbg_instr = "parse_serial+0x008                             ";
         277 : dbg_instr = "parse_serial+0x009                             ";
         278 : dbg_instr = "parse_serial+0x00a                             ";
         279 : dbg_instr = "parse_serial+0x00b                             ";
         280 : dbg_instr = "parse_serial+0x00c                             ";
         281 : dbg_instr = "parse_serial+0x00d                             ";
         282 : dbg_instr = "parse_serial+0x00e                             ";
         283 : dbg_instr = "parse_serial+0x00f                             ";
         284 : dbg_instr = "parse_serial+0x010                             ";
         285 : dbg_instr = "parse_serial+0x011                             ";
         286 : dbg_instr = "parse_serial+0x012                             ";
         287 : dbg_instr = "parse_serial+0x013                             ";
         288 : dbg_instr = "parse_serial+0x014                             ";
         289 : dbg_instr = "parse_serial+0x015                             ";
         290 : dbg_instr = "parse_serial+0x016                             ";
         291 : dbg_instr = "parse_serial+0x017                             ";
         292 : dbg_instr = "parse_serial+0x018                             ";
         293 : dbg_instr = "parse_serial+0x019                             ";
         294 : dbg_instr = "parse_serial+0x01a                             ";
         295 : dbg_instr = "parse_serial+0x01b                             ";
         296 : dbg_instr = "parse_serial+0x01c                             ";
         297 : dbg_instr = "parse_serial+0x01d                             ";
         298 : dbg_instr = "parse_serial+0x01e                             ";
         299 : dbg_instr = "parse_serial+0x01f                             ";
         300 : dbg_instr = "parse_serial+0x020                             ";
         301 : dbg_instr = "parse_serial+0x021                             ";
         302 : dbg_instr = "parse_serial+0x022                             ";
         303 : dbg_instr = "do_PingPong                                    ";
         304 : dbg_instr = "do_PingPong+0x001                              ";
         305 : dbg_instr = "do_Statistics                                  ";
         306 : dbg_instr = "do_Statistics+0x001                            ";
         307 : dbg_instr = "do_Statistics+0x002                            ";
         308 : dbg_instr = "do_Statistics+0x003                            ";
         309 : dbg_instr = "do_Statistics+0x004                            ";
         310 : dbg_instr = "do_Statistics+0x005                            ";
         311 : dbg_instr = "do_Statistics+0x006                            ";
         312 : dbg_instr = "do_Statistics+0x007                            ";
         313 : dbg_instr = "do_Statistics+0x008                            ";
         314 : dbg_instr = "do_Statistics+0x009                            ";
         315 : dbg_instr = "do_Statistics+0x00a                            ";
         316 : dbg_instr = "do_Statistics+0x00b                            ";
         317 : dbg_instr = "do_Statistics+0x00c                            ";
         318 : dbg_instr = "do_Statistics+0x00d                            ";
         319 : dbg_instr = "do_Statistics+0x00e                            ";
         320 : dbg_instr = "do_Statistics+0x00f                            ";
         321 : dbg_instr = "do_Statistics+0x010                            ";
         322 : dbg_instr = "do_Statistics+0x011                            ";
         323 : dbg_instr = "do_Temps                                       ";
         324 : dbg_instr = "do_Temps+0x001                                 ";
         325 : dbg_instr = "do_Temps+0x002                                 ";
         326 : dbg_instr = "do_Temps+0x003                                 ";
         327 : dbg_instr = "do_Temps+0x004                                 ";
         328 : dbg_instr = "do_Temps+0x005                                 ";
         329 : dbg_instr = "do_Temps+0x006                                 ";
         330 : dbg_instr = "do_Temps+0x007                                 ";
         331 : dbg_instr = "do_Temps+0x008                                 ";
         332 : dbg_instr = "do_Temps+0x009                                 ";
         333 : dbg_instr = "do_Temps+0x00a                                 ";
         334 : dbg_instr = "do_Temps+0x00b                                 ";
         335 : dbg_instr = "do_Temps+0x00c                                 ";
         336 : dbg_instr = "do_Temps+0x00d                                 ";
         337 : dbg_instr = "do_Volts                                       ";
         338 : dbg_instr = "do_Volts+0x001                                 ";
         339 : dbg_instr = "do_Volts+0x002                                 ";
         340 : dbg_instr = "do_Volts+0x003                                 ";
         341 : dbg_instr = "do_Volts+0x004                                 ";
         342 : dbg_instr = "do_Volts+0x005                                 ";
         343 : dbg_instr = "do_Volts+0x006                                 ";
         344 : dbg_instr = "do_Volts+0x007                                 ";
         345 : dbg_instr = "do_Volts+0x008                                 ";
         346 : dbg_instr = "do_Volts+0x009                                 ";
         347 : dbg_instr = "do_Volts+0x00a                                 ";
         348 : dbg_instr = "do_Volts+0x00b                                 ";
         349 : dbg_instr = "do_Volts+0x00c                                 ";
         350 : dbg_instr = "do_Volts+0x00d                                 ";
         351 : dbg_instr = "do_Currents                                    ";
         352 : dbg_instr = "do_Currents+0x001                              ";
         353 : dbg_instr = "do_Currents+0x002                              ";
         354 : dbg_instr = "do_Currents+0x003                              ";
         355 : dbg_instr = "do_Currents+0x004                              ";
         356 : dbg_instr = "do_Currents+0x005                              ";
         357 : dbg_instr = "do_Currents+0x006                              ";
         358 : dbg_instr = "do_Currents+0x007                              ";
         359 : dbg_instr = "do_Currents+0x008                              ";
         360 : dbg_instr = "do_Currents+0x009                              ";
         361 : dbg_instr = "do_Currents+0x00a                              ";
         362 : dbg_instr = "do_Currents+0x00b                              ";
         363 : dbg_instr = "do_Currents+0x00c                              ";
         364 : dbg_instr = "do_Currents+0x00d                              ";
         365 : dbg_instr = "do_ReloadFirmware                              ";
         366 : dbg_instr = "do_ReloadFirmware+0x001                        ";
         367 : dbg_instr = "do_ReloadFirmware+0x002                        ";
         368 : dbg_instr = "do_ReloadFirmware+0x003                        ";
         369 : dbg_instr = "do_ReloadFirmware+0x004                        ";
         370 : dbg_instr = "do_ReloadFirmware+0x005                        ";
         371 : dbg_instr = "do_Enable                                      ";
         372 : dbg_instr = "do_Enable+0x001                                ";
         373 : dbg_instr = "do_Enable+0x002                                ";
         374 : dbg_instr = "do_Enable+0x003                                ";
         375 : dbg_instr = "do_Enable+0x004                                ";
         376 : dbg_instr = "do_Enable+0x005                                ";
         377 : dbg_instr = "do_Enable+0x006                                ";
         378 : dbg_instr = "do_Enable+0x007                                ";
         379 : dbg_instr = "do_Enable+0x008                                ";
         380 : dbg_instr = "do_Enable+0x009                                ";
         381 : dbg_instr = "do_Enable+0x00a                                ";
         382 : dbg_instr = "do_Enable+0x00b                                ";
         383 : dbg_instr = "do_Enable+0x00c                                ";
         384 : dbg_instr = "do_Enable+0x00d                                ";
         385 : dbg_instr = "do_Enable+0x00e                                ";
         386 : dbg_instr = "do_Enable+0x00f                                ";
         387 : dbg_instr = "do_Enable+0x010                                ";
         388 : dbg_instr = "do_Enable+0x011                                ";
         389 : dbg_instr = "do_Enable+0x012                                ";
         390 : dbg_instr = "do_PMBus                                       ";
         391 : dbg_instr = "do_PMBus+0x001                                 ";
         392 : dbg_instr = "do_PMBus+0x002                                 ";
         393 : dbg_instr = "do_PMBus+0x003                                 ";
         394 : dbg_instr = "do_PMBus+0x004                                 ";
         395 : dbg_instr = "do_PMBus+0x005                                 ";
         396 : dbg_instr = "do_PMBus+0x006                                 ";
         397 : dbg_instr = "do_PMBus+0x007                                 ";
         398 : dbg_instr = "do_PMBus+0x008                                 ";
         399 : dbg_instr = "do_PMBus+0x009                                 ";
         400 : dbg_instr = "do_PMBus+0x00a                                 ";
         401 : dbg_instr = "PMBus_Write                                    ";
         402 : dbg_instr = "PMBus_Write+0x001                              ";
         403 : dbg_instr = "PMBus_Write+0x002                              ";
         404 : dbg_instr = "PMBus_Write+0x003                              ";
         405 : dbg_instr = "PMBus_Write+0x004                              ";
         406 : dbg_instr = "PMBus_Write+0x005                              ";
         407 : dbg_instr = "PMBus_Write+0x006                              ";
         408 : dbg_instr = "PMBus_Write+0x007                              ";
         409 : dbg_instr = "PMBus_Write+0x008                              ";
         410 : dbg_instr = "PMBus_Write+0x009                              ";
         411 : dbg_instr = "PMBus_Write+0x00a                              ";
         412 : dbg_instr = "PMBus_Write+0x00b                              ";
         413 : dbg_instr = "PMBus_Write+0x00c                              ";
         414 : dbg_instr = "PMBus_Write+0x00d                              ";
         415 : dbg_instr = "PMBus_Write+0x00e                              ";
         416 : dbg_instr = "PMBus_Write+0x00f                              ";
         417 : dbg_instr = "PMBus_Write+0x010                              ";
         418 : dbg_instr = "PMBus_Read                                     ";
         419 : dbg_instr = "PMBus_Read+0x001                               ";
         420 : dbg_instr = "PMBus_Read+0x002                               ";
         421 : dbg_instr = "PMBus_Read+0x003                               ";
         422 : dbg_instr = "PMBus_Read+0x004                               ";
         423 : dbg_instr = "PMBus_Read+0x005                               ";
         424 : dbg_instr = "PMBus_Read+0x006                               ";
         425 : dbg_instr = "PMBus_Read+0x007                               ";
         426 : dbg_instr = "PMBus_Read+0x008                               ";
         427 : dbg_instr = "PMBus_Read+0x009                               ";
         428 : dbg_instr = "PMBus_Read+0x00a                               ";
         429 : dbg_instr = "PMBus_Read+0x00b                               ";
         430 : dbg_instr = "PMBus_Read+0x00c                               ";
         431 : dbg_instr = "PMBus_Read+0x00d                               ";
         432 : dbg_instr = "PMBus_Read+0x00e                               ";
         433 : dbg_instr = "PMBus_Read+0x00f                               ";
         434 : dbg_instr = "PMBus_Read+0x010                               ";
         435 : dbg_instr = "PMBus_Read+0x011                               ";
         436 : dbg_instr = "do_Identify                                    ";
         437 : dbg_instr = "do_Identify+0x001                              ";
         438 : dbg_instr = "do_Identify+0x002                              ";
         439 : dbg_instr = "do_Identify+0x003                              ";
         440 : dbg_instr = "do_Identify+0x004                              ";
         441 : dbg_instr = "do_Identify+0x005                              ";
         442 : dbg_instr = "do_Identify+0x006                              ";
         443 : dbg_instr = "do_Identify+0x007                              ";
         444 : dbg_instr = "finishPacket                                   ";
         445 : dbg_instr = "finishPacket+0x001                             ";
         446 : dbg_instr = "finishPacket+0x002                             ";
         447 : dbg_instr = "goodPacket                                     ";
         448 : dbg_instr = "goodPacket+0x001                               ";
         449 : dbg_instr = "goodPacket+0x002                               ";
         450 : dbg_instr = "goodPacket+0x003                               ";
         451 : dbg_instr = "fetchAndIncrement                              ";
         452 : dbg_instr = "fetchAndIncrement+0x001                        ";
         453 : dbg_instr = "fetchAndIncrement+0x002                        ";
         454 : dbg_instr = "fetchAndIncrement+0x003                        ";
         455 : dbg_instr = "skippedPacket                                  ";
         456 : dbg_instr = "skippedPacket+0x001                            ";
         457 : dbg_instr = "droppedPacket                                  ";
         458 : dbg_instr = "droppedPacket+0x001                            ";
         459 : dbg_instr = "errorPacket                                    ";
         460 : dbg_instr = "errorPacket+0x001                              ";
         461 : dbg_instr = "hsk_header                                     ";
         462 : dbg_instr = "hsk_header+0x001                               ";
         463 : dbg_instr = "hsk_header+0x002                               ";
         464 : dbg_instr = "hsk_header+0x003                               ";
         465 : dbg_instr = "hsk_copy4                                      ";
         466 : dbg_instr = "hsk_copy2                                      ";
         467 : dbg_instr = "hsk_copy1                                      ";
         468 : dbg_instr = "hsk_copy1+0x001                                ";
         469 : dbg_instr = "hsk_copy1+0x002                                ";
         470 : dbg_instr = "hsk_copy1+0x003                                ";
         471 : dbg_instr = "hsk_copy1+0x004                                ";
         472 : dbg_instr = "hsk_copy1+0x005                                ";
         473 : dbg_instr = "I2C_delay_hclk                                 ";
         474 : dbg_instr = "I2C_delay_med                                  ";
         475 : dbg_instr = "I2C_delay_med+0x001                            ";
         476 : dbg_instr = "I2C_delay_med+0x002                            ";
         477 : dbg_instr = "I2C_delay_short                                ";
         478 : dbg_instr = "I2C_delay_short+0x001                          ";
         479 : dbg_instr = "I2C_delay_short+0x002                          ";
         480 : dbg_instr = "I2C_delay_short+0x003                          ";
         481 : dbg_instr = "I2C_delay_short+0x004                          ";
         482 : dbg_instr = "I2C_delay_short+0x005                          ";
         483 : dbg_instr = "I2C_Rx_bit                                     ";
         484 : dbg_instr = "I2C_Rx_bit+0x001                               ";
         485 : dbg_instr = "I2C_Rx_bit+0x002                               ";
         486 : dbg_instr = "I2C_Rx_bit+0x003                               ";
         487 : dbg_instr = "I2C_Rx_bit+0x004                               ";
         488 : dbg_instr = "I2C_Rx_bit+0x005                               ";
         489 : dbg_instr = "I2C_Rx_bit+0x006                               ";
         490 : dbg_instr = "I2C_Rx_bit+0x007                               ";
         491 : dbg_instr = "I2C_Rx_bit+0x008                               ";
         492 : dbg_instr = "I2C_stop                                       ";
         493 : dbg_instr = "I2C_stop+0x001                                 ";
         494 : dbg_instr = "I2C_stop+0x002                                 ";
         495 : dbg_instr = "I2C_stop+0x003                                 ";
         496 : dbg_instr = "I2C_stop+0x004                                 ";
         497 : dbg_instr = "I2C_stop+0x005                                 ";
         498 : dbg_instr = "I2C_stop+0x006                                 ";
         499 : dbg_instr = "I2C_start                                      ";
         500 : dbg_instr = "I2C_start+0x001                                ";
         501 : dbg_instr = "I2C_start+0x002                                ";
         502 : dbg_instr = "I2C_start+0x003                                ";
         503 : dbg_instr = "I2C_start+0x004                                ";
         504 : dbg_instr = "I2C_start+0x005                                ";
         505 : dbg_instr = "I2C_start+0x006                                ";
         506 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK                         ";
         507 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x001                   ";
         508 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x002                   ";
         509 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x003                   ";
         510 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x004                   ";
         511 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x005                   ";
         512 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x006                   ";
         513 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x007                   ";
         514 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x008                   ";
         515 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x009                   ";
         516 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00a                   ";
         517 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00b                   ";
         518 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00c                   ";
         519 : dbg_instr = "I2C_Rx_byte                                    ";
         520 : dbg_instr = "I2C_Rx_byte+0x001                              ";
         521 : dbg_instr = "I2C_Rx_byte+0x002                              ";
         522 : dbg_instr = "I2C_Rx_byte+0x003                              ";
         523 : dbg_instr = "I2C_Rx_byte+0x004                              ";
         524 : dbg_instr = "I2C_test                                       ";
         525 : dbg_instr = "I2C_test+0x001                                 ";
         526 : dbg_instr = "I2C_test+0x002                                 ";
         527 : dbg_instr = "I2C_test+0x003                                 ";
         528 : dbg_instr = "I2C_user_tx_process                            ";
         529 : dbg_instr = "I2C_user_tx_process+0x001                      ";
         530 : dbg_instr = "I2C_user_tx_process+0x002                      ";
         531 : dbg_instr = "I2C_user_tx_process+0x003                      ";
         532 : dbg_instr = "I2C_user_tx_process+0x004                      ";
         533 : dbg_instr = "I2C_user_tx_process+0x005                      ";
         534 : dbg_instr = "I2C_user_tx_process+0x006                      ";
         535 : dbg_instr = "I2C_send3                                      ";
         536 : dbg_instr = "I2C_send3+0x001                                ";
         537 : dbg_instr = "I2C_send3+0x002                                ";
         538 : dbg_instr = "I2C_send1_prcs                                 ";
         539 : dbg_instr = "I2C_send1_prcs+0x001                           ";
         540 : dbg_instr = "I2C_send1_prcs+0x002                           ";
         541 : dbg_instr = "I2C_send1_prcs+0x003                           ";
         542 : dbg_instr = "I2C_send1_prcs+0x004                           ";
         543 : dbg_instr = "I2C_turfio_initialize                          ";
         544 : dbg_instr = "I2C_turfio_initialize+0x001                    ";
         545 : dbg_instr = "I2C_turfio_initialize+0x002                    ";
         546 : dbg_instr = "I2C_turfio_initialize+0x003                    ";
         547 : dbg_instr = "I2C_turfio_initialize+0x004                    ";
         548 : dbg_instr = "I2C_surf_initialize                            ";
         549 : dbg_instr = "I2C_surf_initialize+0x001                      ";
         550 : dbg_instr = "I2C_surf_initialize+0x002                      ";
         551 : dbg_instr = "I2C_surf_initialize+0x003                      ";
         552 : dbg_instr = "I2C_surf_initialize+0x004                      ";
         553 : dbg_instr = "I2C_surf_initialize+0x005                      ";
         554 : dbg_instr = "I2C_surf_initialize+0x006                      ";
         555 : dbg_instr = "I2C_surf_initialize+0x007                      ";
         556 : dbg_instr = "I2C_surf_initialize+0x008                      ";
         557 : dbg_instr = "I2C_surf_initialize+0x009                      ";
         558 : dbg_instr = "I2C_read_register                              ";
         559 : dbg_instr = "I2C_read_register+0x001                        ";
         560 : dbg_instr = "I2C_read_register+0x002                        ";
         561 : dbg_instr = "I2C_read_register+0x003                        ";
         562 : dbg_instr = "I2C_read_register+0x004                        ";
         563 : dbg_instr = "I2C_read                                       ";
         564 : dbg_instr = "I2C_read+0x001                                 ";
         565 : dbg_instr = "I2C_read+0x002                                 ";
         566 : dbg_instr = "I2C_read+0x003                                 ";
         567 : dbg_instr = "I2C_read+0x004                                 ";
         568 : dbg_instr = "I2C_read+0x005                                 ";
         569 : dbg_instr = "I2C_read+0x006                                 ";
         570 : dbg_instr = "I2C_read+0x007                                 ";
         571 : dbg_instr = "I2C_read+0x008                                 ";
         572 : dbg_instr = "I2C_read+0x009                                 ";
         573 : dbg_instr = "I2C_read+0x00a                                 ";
         574 : dbg_instr = "I2C_read+0x00b                                 ";
         575 : dbg_instr = "I2C_read+0x00c                                 ";
         576 : dbg_instr = "I2C_read+0x00d                                 ";
         577 : dbg_instr = "I2C_read+0x00e                                 ";
         578 : dbg_instr = "I2C_read+0x00f                                 ";
         579 : dbg_instr = "I2C_read+0x010                                 ";
         580 : dbg_instr = "I2C_read+0x011                                 ";
         581 : dbg_instr = "I2C_read+0x012                                 ";
         582 : dbg_instr = "I2C_read+0x013                                 ";
         583 : dbg_instr = "cobsFindZero                                   ";
         584 : dbg_instr = "cobsFindZero+0x001                             ";
         585 : dbg_instr = "cobsFindZero+0x002                             ";
         586 : dbg_instr = "cobsFindZero+0x003                             ";
         587 : dbg_instr = "cobsFindZero+0x004                             ";
         588 : dbg_instr = "cobsFindZero+0x005                             ";
         589 : dbg_instr = "cobsFindZero+0x006                             ";
         590 : dbg_instr = "cobsFindZero+0x007                             ";
         591 : dbg_instr = "cobsFixZero                                    ";
         592 : dbg_instr = "cobsFixZero+0x001                              ";
         593 : dbg_instr = "cobsFixZero+0x002                              ";
         594 : dbg_instr = "cobsFixZero+0x003                              ";
         595 : dbg_instr = "cobsFixZero+0x004                              ";
         596 : dbg_instr = "cobsEncode                                     ";
         597 : dbg_instr = "cobsEncode+0x001                               ";
         598 : dbg_instr = "cobsEncode+0x002                               ";
         599 : dbg_instr = "cobsEncode+0x003                               ";
         600 : dbg_instr = "cobsEncode+0x004                               ";
         601 : dbg_instr = "cobsEncode+0x005                               ";
         602 : dbg_instr = "cobsEncode+0x006                               ";
         603 : dbg_instr = "cobsEncode+0x007                               ";
         604 : dbg_instr = "cobsEncode+0x008                               ";
         605 : dbg_instr = "cobsEncode+0x009                               ";
         606 : dbg_instr = "cobsEncode+0x00a                               ";
         607 : dbg_instr = "cobsEncode+0x00b                               ";
         608 : dbg_instr = "cobsEncode+0x00c                               ";
         609 : dbg_instr = "cobsEncode+0x00d                               ";
         610 : dbg_instr = "cobsEncode+0x00e                               ";
         611 : dbg_instr = "icap_reboot                                    ";
         612 : dbg_instr = "icap_reboot+0x001                              ";
         613 : dbg_instr = "icap_reboot+0x002                              ";
         614 : dbg_instr = "icap_reboot+0x003                              ";
         615 : dbg_instr = "icap_reboot+0x004                              ";
         616 : dbg_instr = "icap_reboot+0x005                              ";
         617 : dbg_instr = "icap_reboot+0x006                              ";
         618 : dbg_instr = "icap_reboot+0x007                              ";
         619 : dbg_instr = "icap_reboot+0x008                              ";
         620 : dbg_instr = "icap_reboot+0x009                              ";
         621 : dbg_instr = "icap_reboot+0x00a                              ";
         622 : dbg_instr = "icap_reboot+0x00b                              ";
         623 : dbg_instr = "icap_reboot+0x00c                              ";
         624 : dbg_instr = "icap_reboot+0x00d                              ";
         625 : dbg_instr = "icap_reboot+0x00e                              ";
         626 : dbg_instr = "icap_reboot+0x00f                              ";
         627 : dbg_instr = "icap_reboot+0x010                              ";
         628 : dbg_instr = "icap_reboot+0x011                              ";
         629 : dbg_instr = "icap_reboot+0x012                              ";
         630 : dbg_instr = "icap_reboot+0x013                              ";
         631 : dbg_instr = "icap_reboot+0x014                              ";
         632 : dbg_instr = "icap_reboot+0x015                              ";
         633 : dbg_instr = "icap_reboot+0x016                              ";
         634 : dbg_instr = "icap_reboot+0x017                              ";
         635 : dbg_instr = "icap_reboot+0x018                              ";
         636 : dbg_instr = "icap_noop                                      ";
         637 : dbg_instr = "icap_3zero                                     ";
         638 : dbg_instr = "icap_3zero+0x001                               ";
         639 : dbg_instr = "icap_3zero+0x002                               ";
         640 : dbg_instr = "icap_3zero+0x003                               ";
         641 : dbg_instr = "icap_3zero+0x004                               ";
         642 : dbg_instr = "icap_3zero+0x005                               ";
         643 : dbg_instr = "icap_3zero+0x006                               ";
         644 : dbg_instr = "icap_3zero+0x007                               ";
         645 : dbg_instr = "icap_3zero+0x008                               ";
         646 : dbg_instr = "icap_3zero+0x009                               ";
         647 : dbg_instr = "icap_3zero+0x00a                               ";
         648 : dbg_instr = "icap_3zero+0x00b                               ";
         649 : dbg_instr = "icap_3zero+0x00c                               ";
         650 : dbg_instr = "icap_3zero+0x00d                               ";
         651 : dbg_instr = "icap_3zero+0x00e                               ";
         652 : dbg_instr = "icap_3zero+0x00f                               ";
         653 : dbg_instr = "icap_3zero+0x010                               ";
         654 : dbg_instr = "icap_3zero+0x011                               ";
         655 : dbg_instr = "icap_3zero+0x012                               ";
         656 : dbg_instr = "icap_3zero+0x013                               ";
         657 : dbg_instr = "icap_3zero+0x014                               ";
         658 : dbg_instr = "icap_3zero+0x015                               ";
         659 : dbg_instr = "icap_3zero+0x016                               ";
         660 : dbg_instr = "icap_3zero+0x017                               ";
         661 : dbg_instr = "icap_3zero+0x018                               ";
         662 : dbg_instr = "icap_3zero+0x019                               ";
         663 : dbg_instr = "icap_3zero+0x01a                               ";
         664 : dbg_instr = "icap_3zero+0x01b                               ";
         665 : dbg_instr = "icap_3zero+0x01c                               ";
         666 : dbg_instr = "icap_3zero+0x01d                               ";
         667 : dbg_instr = "icap_3zero+0x01e                               ";
         668 : dbg_instr = "icap_3zero+0x01f                               ";
         669 : dbg_instr = "icap_3zero+0x020                               ";
         670 : dbg_instr = "icap_3zero+0x021                               ";
         671 : dbg_instr = "icap_3zero+0x022                               ";
         672 : dbg_instr = "icap_3zero+0x023                               ";
         673 : dbg_instr = "icap_3zero+0x024                               ";
         674 : dbg_instr = "icap_3zero+0x025                               ";
         675 : dbg_instr = "icap_3zero+0x026                               ";
         676 : dbg_instr = "icap_3zero+0x027                               ";
         677 : dbg_instr = "icap_3zero+0x028                               ";
         678 : dbg_instr = "icap_3zero+0x029                               ";
         679 : dbg_instr = "icap_3zero+0x02a                               ";
         680 : dbg_instr = "icap_3zero+0x02b                               ";
         681 : dbg_instr = "icap_3zero+0x02c                               ";
         682 : dbg_instr = "icap_3zero+0x02d                               ";
         683 : dbg_instr = "icap_3zero+0x02e                               ";
         684 : dbg_instr = "icap_3zero+0x02f                               ";
         685 : dbg_instr = "icap_3zero+0x030                               ";
         686 : dbg_instr = "icap_3zero+0x031                               ";
         687 : dbg_instr = "icap_3zero+0x032                               ";
         688 : dbg_instr = "icap_3zero+0x033                               ";
         689 : dbg_instr = "icap_3zero+0x034                               ";
         690 : dbg_instr = "icap_3zero+0x035                               ";
         691 : dbg_instr = "icap_3zero+0x036                               ";
         692 : dbg_instr = "icap_3zero+0x037                               ";
         693 : dbg_instr = "icap_3zero+0x038                               ";
         694 : dbg_instr = "icap_3zero+0x039                               ";
         695 : dbg_instr = "icap_3zero+0x03a                               ";
         696 : dbg_instr = "icap_3zero+0x03b                               ";
         697 : dbg_instr = "icap_3zero+0x03c                               ";
         698 : dbg_instr = "icap_3zero+0x03d                               ";
         699 : dbg_instr = "icap_3zero+0x03e                               ";
         700 : dbg_instr = "icap_3zero+0x03f                               ";
         701 : dbg_instr = "icap_3zero+0x040                               ";
         702 : dbg_instr = "icap_3zero+0x041                               ";
         703 : dbg_instr = "icap_3zero+0x042                               ";
         704 : dbg_instr = "icap_3zero+0x043                               ";
         705 : dbg_instr = "icap_3zero+0x044                               ";
         706 : dbg_instr = "icap_3zero+0x045                               ";
         707 : dbg_instr = "icap_3zero+0x046                               ";
         708 : dbg_instr = "icap_3zero+0x047                               ";
         709 : dbg_instr = "icap_3zero+0x048                               ";
         710 : dbg_instr = "icap_3zero+0x049                               ";
         711 : dbg_instr = "icap_3zero+0x04a                               ";
         712 : dbg_instr = "icap_3zero+0x04b                               ";
         713 : dbg_instr = "icap_3zero+0x04c                               ";
         714 : dbg_instr = "icap_3zero+0x04d                               ";
         715 : dbg_instr = "icap_3zero+0x04e                               ";
         716 : dbg_instr = "icap_3zero+0x04f                               ";
         717 : dbg_instr = "icap_3zero+0x050                               ";
         718 : dbg_instr = "icap_3zero+0x051                               ";
         719 : dbg_instr = "icap_3zero+0x052                               ";
         720 : dbg_instr = "icap_3zero+0x053                               ";
         721 : dbg_instr = "icap_3zero+0x054                               ";
         722 : dbg_instr = "icap_3zero+0x055                               ";
         723 : dbg_instr = "icap_3zero+0x056                               ";
         724 : dbg_instr = "icap_3zero+0x057                               ";
         725 : dbg_instr = "icap_3zero+0x058                               ";
         726 : dbg_instr = "icap_3zero+0x059                               ";
         727 : dbg_instr = "icap_3zero+0x05a                               ";
         728 : dbg_instr = "icap_3zero+0x05b                               ";
         729 : dbg_instr = "icap_3zero+0x05c                               ";
         730 : dbg_instr = "icap_3zero+0x05d                               ";
         731 : dbg_instr = "icap_3zero+0x05e                               ";
         732 : dbg_instr = "icap_3zero+0x05f                               ";
         733 : dbg_instr = "icap_3zero+0x060                               ";
         734 : dbg_instr = "icap_3zero+0x061                               ";
         735 : dbg_instr = "icap_3zero+0x062                               ";
         736 : dbg_instr = "icap_3zero+0x063                               ";
         737 : dbg_instr = "icap_3zero+0x064                               ";
         738 : dbg_instr = "icap_3zero+0x065                               ";
         739 : dbg_instr = "icap_3zero+0x066                               ";
         740 : dbg_instr = "icap_3zero+0x067                               ";
         741 : dbg_instr = "icap_3zero+0x068                               ";
         742 : dbg_instr = "icap_3zero+0x069                               ";
         743 : dbg_instr = "icap_3zero+0x06a                               ";
         744 : dbg_instr = "icap_3zero+0x06b                               ";
         745 : dbg_instr = "icap_3zero+0x06c                               ";
         746 : dbg_instr = "icap_3zero+0x06d                               ";
         747 : dbg_instr = "icap_3zero+0x06e                               ";
         748 : dbg_instr = "icap_3zero+0x06f                               ";
         749 : dbg_instr = "icap_3zero+0x070                               ";
         750 : dbg_instr = "icap_3zero+0x071                               ";
         751 : dbg_instr = "icap_3zero+0x072                               ";
         752 : dbg_instr = "icap_3zero+0x073                               ";
         753 : dbg_instr = "icap_3zero+0x074                               ";
         754 : dbg_instr = "icap_3zero+0x075                               ";
         755 : dbg_instr = "icap_3zero+0x076                               ";
         756 : dbg_instr = "icap_3zero+0x077                               ";
         757 : dbg_instr = "icap_3zero+0x078                               ";
         758 : dbg_instr = "icap_3zero+0x079                               ";
         759 : dbg_instr = "icap_3zero+0x07a                               ";
         760 : dbg_instr = "icap_3zero+0x07b                               ";
         761 : dbg_instr = "icap_3zero+0x07c                               ";
         762 : dbg_instr = "icap_3zero+0x07d                               ";
         763 : dbg_instr = "icap_3zero+0x07e                               ";
         764 : dbg_instr = "icap_3zero+0x07f                               ";
         765 : dbg_instr = "icap_3zero+0x080                               ";
         766 : dbg_instr = "icap_3zero+0x081                               ";
         767 : dbg_instr = "icap_3zero+0x082                               ";
         768 : dbg_instr = "icap_3zero+0x083                               ";
         769 : dbg_instr = "icap_3zero+0x084                               ";
         770 : dbg_instr = "icap_3zero+0x085                               ";
         771 : dbg_instr = "icap_3zero+0x086                               ";
         772 : dbg_instr = "icap_3zero+0x087                               ";
         773 : dbg_instr = "icap_3zero+0x088                               ";
         774 : dbg_instr = "icap_3zero+0x089                               ";
         775 : dbg_instr = "icap_3zero+0x08a                               ";
         776 : dbg_instr = "icap_3zero+0x08b                               ";
         777 : dbg_instr = "icap_3zero+0x08c                               ";
         778 : dbg_instr = "icap_3zero+0x08d                               ";
         779 : dbg_instr = "icap_3zero+0x08e                               ";
         780 : dbg_instr = "icap_3zero+0x08f                               ";
         781 : dbg_instr = "icap_3zero+0x090                               ";
         782 : dbg_instr = "icap_3zero+0x091                               ";
         783 : dbg_instr = "icap_3zero+0x092                               ";
         784 : dbg_instr = "icap_3zero+0x093                               ";
         785 : dbg_instr = "icap_3zero+0x094                               ";
         786 : dbg_instr = "icap_3zero+0x095                               ";
         787 : dbg_instr = "icap_3zero+0x096                               ";
         788 : dbg_instr = "icap_3zero+0x097                               ";
         789 : dbg_instr = "icap_3zero+0x098                               ";
         790 : dbg_instr = "icap_3zero+0x099                               ";
         791 : dbg_instr = "icap_3zero+0x09a                               ";
         792 : dbg_instr = "icap_3zero+0x09b                               ";
         793 : dbg_instr = "icap_3zero+0x09c                               ";
         794 : dbg_instr = "icap_3zero+0x09d                               ";
         795 : dbg_instr = "icap_3zero+0x09e                               ";
         796 : dbg_instr = "icap_3zero+0x09f                               ";
         797 : dbg_instr = "icap_3zero+0x0a0                               ";
         798 : dbg_instr = "icap_3zero+0x0a1                               ";
         799 : dbg_instr = "icap_3zero+0x0a2                               ";
         800 : dbg_instr = "icap_3zero+0x0a3                               ";
         801 : dbg_instr = "icap_3zero+0x0a4                               ";
         802 : dbg_instr = "icap_3zero+0x0a5                               ";
         803 : dbg_instr = "icap_3zero+0x0a6                               ";
         804 : dbg_instr = "icap_3zero+0x0a7                               ";
         805 : dbg_instr = "icap_3zero+0x0a8                               ";
         806 : dbg_instr = "icap_3zero+0x0a9                               ";
         807 : dbg_instr = "icap_3zero+0x0aa                               ";
         808 : dbg_instr = "icap_3zero+0x0ab                               ";
         809 : dbg_instr = "icap_3zero+0x0ac                               ";
         810 : dbg_instr = "icap_3zero+0x0ad                               ";
         811 : dbg_instr = "icap_3zero+0x0ae                               ";
         812 : dbg_instr = "icap_3zero+0x0af                               ";
         813 : dbg_instr = "icap_3zero+0x0b0                               ";
         814 : dbg_instr = "icap_3zero+0x0b1                               ";
         815 : dbg_instr = "icap_3zero+0x0b2                               ";
         816 : dbg_instr = "icap_3zero+0x0b3                               ";
         817 : dbg_instr = "icap_3zero+0x0b4                               ";
         818 : dbg_instr = "icap_3zero+0x0b5                               ";
         819 : dbg_instr = "icap_3zero+0x0b6                               ";
         820 : dbg_instr = "icap_3zero+0x0b7                               ";
         821 : dbg_instr = "icap_3zero+0x0b8                               ";
         822 : dbg_instr = "icap_3zero+0x0b9                               ";
         823 : dbg_instr = "icap_3zero+0x0ba                               ";
         824 : dbg_instr = "icap_3zero+0x0bb                               ";
         825 : dbg_instr = "icap_3zero+0x0bc                               ";
         826 : dbg_instr = "icap_3zero+0x0bd                               ";
         827 : dbg_instr = "icap_3zero+0x0be                               ";
         828 : dbg_instr = "icap_3zero+0x0bf                               ";
         829 : dbg_instr = "icap_3zero+0x0c0                               ";
         830 : dbg_instr = "icap_3zero+0x0c1                               ";
         831 : dbg_instr = "icap_3zero+0x0c2                               ";
         832 : dbg_instr = "icap_3zero+0x0c3                               ";
         833 : dbg_instr = "icap_3zero+0x0c4                               ";
         834 : dbg_instr = "icap_3zero+0x0c5                               ";
         835 : dbg_instr = "icap_3zero+0x0c6                               ";
         836 : dbg_instr = "icap_3zero+0x0c7                               ";
         837 : dbg_instr = "icap_3zero+0x0c8                               ";
         838 : dbg_instr = "icap_3zero+0x0c9                               ";
         839 : dbg_instr = "icap_3zero+0x0ca                               ";
         840 : dbg_instr = "icap_3zero+0x0cb                               ";
         841 : dbg_instr = "icap_3zero+0x0cc                               ";
         842 : dbg_instr = "icap_3zero+0x0cd                               ";
         843 : dbg_instr = "icap_3zero+0x0ce                               ";
         844 : dbg_instr = "icap_3zero+0x0cf                               ";
         845 : dbg_instr = "icap_3zero+0x0d0                               ";
         846 : dbg_instr = "icap_3zero+0x0d1                               ";
         847 : dbg_instr = "icap_3zero+0x0d2                               ";
         848 : dbg_instr = "icap_3zero+0x0d3                               ";
         849 : dbg_instr = "icap_3zero+0x0d4                               ";
         850 : dbg_instr = "icap_3zero+0x0d5                               ";
         851 : dbg_instr = "icap_3zero+0x0d6                               ";
         852 : dbg_instr = "icap_3zero+0x0d7                               ";
         853 : dbg_instr = "icap_3zero+0x0d8                               ";
         854 : dbg_instr = "icap_3zero+0x0d9                               ";
         855 : dbg_instr = "icap_3zero+0x0da                               ";
         856 : dbg_instr = "icap_3zero+0x0db                               ";
         857 : dbg_instr = "icap_3zero+0x0dc                               ";
         858 : dbg_instr = "icap_3zero+0x0dd                               ";
         859 : dbg_instr = "icap_3zero+0x0de                               ";
         860 : dbg_instr = "icap_3zero+0x0df                               ";
         861 : dbg_instr = "icap_3zero+0x0e0                               ";
         862 : dbg_instr = "icap_3zero+0x0e1                               ";
         863 : dbg_instr = "icap_3zero+0x0e2                               ";
         864 : dbg_instr = "icap_3zero+0x0e3                               ";
         865 : dbg_instr = "icap_3zero+0x0e4                               ";
         866 : dbg_instr = "icap_3zero+0x0e5                               ";
         867 : dbg_instr = "icap_3zero+0x0e6                               ";
         868 : dbg_instr = "icap_3zero+0x0e7                               ";
         869 : dbg_instr = "icap_3zero+0x0e8                               ";
         870 : dbg_instr = "icap_3zero+0x0e9                               ";
         871 : dbg_instr = "icap_3zero+0x0ea                               ";
         872 : dbg_instr = "icap_3zero+0x0eb                               ";
         873 : dbg_instr = "icap_3zero+0x0ec                               ";
         874 : dbg_instr = "icap_3zero+0x0ed                               ";
         875 : dbg_instr = "icap_3zero+0x0ee                               ";
         876 : dbg_instr = "icap_3zero+0x0ef                               ";
         877 : dbg_instr = "icap_3zero+0x0f0                               ";
         878 : dbg_instr = "icap_3zero+0x0f1                               ";
         879 : dbg_instr = "icap_3zero+0x0f2                               ";
         880 : dbg_instr = "icap_3zero+0x0f3                               ";
         881 : dbg_instr = "icap_3zero+0x0f4                               ";
         882 : dbg_instr = "icap_3zero+0x0f5                               ";
         883 : dbg_instr = "icap_3zero+0x0f6                               ";
         884 : dbg_instr = "icap_3zero+0x0f7                               ";
         885 : dbg_instr = "icap_3zero+0x0f8                               ";
         886 : dbg_instr = "icap_3zero+0x0f9                               ";
         887 : dbg_instr = "icap_3zero+0x0fa                               ";
         888 : dbg_instr = "icap_3zero+0x0fb                               ";
         889 : dbg_instr = "icap_3zero+0x0fc                               ";
         890 : dbg_instr = "icap_3zero+0x0fd                               ";
         891 : dbg_instr = "icap_3zero+0x0fe                               ";
         892 : dbg_instr = "icap_3zero+0x0ff                               ";
         893 : dbg_instr = "icap_3zero+0x100                               ";
         894 : dbg_instr = "icap_3zero+0x101                               ";
         895 : dbg_instr = "icap_3zero+0x102                               ";
         896 : dbg_instr = "icap_3zero+0x103                               ";
         897 : dbg_instr = "icap_3zero+0x104                               ";
         898 : dbg_instr = "icap_3zero+0x105                               ";
         899 : dbg_instr = "icap_3zero+0x106                               ";
         900 : dbg_instr = "icap_3zero+0x107                               ";
         901 : dbg_instr = "icap_3zero+0x108                               ";
         902 : dbg_instr = "icap_3zero+0x109                               ";
         903 : dbg_instr = "icap_3zero+0x10a                               ";
         904 : dbg_instr = "icap_3zero+0x10b                               ";
         905 : dbg_instr = "icap_3zero+0x10c                               ";
         906 : dbg_instr = "icap_3zero+0x10d                               ";
         907 : dbg_instr = "icap_3zero+0x10e                               ";
         908 : dbg_instr = "icap_3zero+0x10f                               ";
         909 : dbg_instr = "icap_3zero+0x110                               ";
         910 : dbg_instr = "icap_3zero+0x111                               ";
         911 : dbg_instr = "icap_3zero+0x112                               ";
         912 : dbg_instr = "icap_3zero+0x113                               ";
         913 : dbg_instr = "icap_3zero+0x114                               ";
         914 : dbg_instr = "icap_3zero+0x115                               ";
         915 : dbg_instr = "icap_3zero+0x116                               ";
         916 : dbg_instr = "icap_3zero+0x117                               ";
         917 : dbg_instr = "icap_3zero+0x118                               ";
         918 : dbg_instr = "icap_3zero+0x119                               ";
         919 : dbg_instr = "icap_3zero+0x11a                               ";
         920 : dbg_instr = "icap_3zero+0x11b                               ";
         921 : dbg_instr = "icap_3zero+0x11c                               ";
         922 : dbg_instr = "icap_3zero+0x11d                               ";
         923 : dbg_instr = "icap_3zero+0x11e                               ";
         924 : dbg_instr = "icap_3zero+0x11f                               ";
         925 : dbg_instr = "icap_3zero+0x120                               ";
         926 : dbg_instr = "icap_3zero+0x121                               ";
         927 : dbg_instr = "icap_3zero+0x122                               ";
         928 : dbg_instr = "icap_3zero+0x123                               ";
         929 : dbg_instr = "icap_3zero+0x124                               ";
         930 : dbg_instr = "icap_3zero+0x125                               ";
         931 : dbg_instr = "icap_3zero+0x126                               ";
         932 : dbg_instr = "icap_3zero+0x127                               ";
         933 : dbg_instr = "icap_3zero+0x128                               ";
         934 : dbg_instr = "icap_3zero+0x129                               ";
         935 : dbg_instr = "icap_3zero+0x12a                               ";
         936 : dbg_instr = "icap_3zero+0x12b                               ";
         937 : dbg_instr = "icap_3zero+0x12c                               ";
         938 : dbg_instr = "icap_3zero+0x12d                               ";
         939 : dbg_instr = "icap_3zero+0x12e                               ";
         940 : dbg_instr = "icap_3zero+0x12f                               ";
         941 : dbg_instr = "icap_3zero+0x130                               ";
         942 : dbg_instr = "icap_3zero+0x131                               ";
         943 : dbg_instr = "icap_3zero+0x132                               ";
         944 : dbg_instr = "icap_3zero+0x133                               ";
         945 : dbg_instr = "icap_3zero+0x134                               ";
         946 : dbg_instr = "icap_3zero+0x135                               ";
         947 : dbg_instr = "icap_3zero+0x136                               ";
         948 : dbg_instr = "icap_3zero+0x137                               ";
         949 : dbg_instr = "icap_3zero+0x138                               ";
         950 : dbg_instr = "icap_3zero+0x139                               ";
         951 : dbg_instr = "icap_3zero+0x13a                               ";
         952 : dbg_instr = "icap_3zero+0x13b                               ";
         953 : dbg_instr = "icap_3zero+0x13c                               ";
         954 : dbg_instr = "icap_3zero+0x13d                               ";
         955 : dbg_instr = "icap_3zero+0x13e                               ";
         956 : dbg_instr = "icap_3zero+0x13f                               ";
         957 : dbg_instr = "icap_3zero+0x140                               ";
         958 : dbg_instr = "icap_3zero+0x141                               ";
         959 : dbg_instr = "icap_3zero+0x142                               ";
         960 : dbg_instr = "icap_3zero+0x143                               ";
         961 : dbg_instr = "icap_3zero+0x144                               ";
         962 : dbg_instr = "icap_3zero+0x145                               ";
         963 : dbg_instr = "icap_3zero+0x146                               ";
         964 : dbg_instr = "icap_3zero+0x147                               ";
         965 : dbg_instr = "icap_3zero+0x148                               ";
         966 : dbg_instr = "icap_3zero+0x149                               ";
         967 : dbg_instr = "icap_3zero+0x14a                               ";
         968 : dbg_instr = "icap_3zero+0x14b                               ";
         969 : dbg_instr = "icap_3zero+0x14c                               ";
         970 : dbg_instr = "icap_3zero+0x14d                               ";
         971 : dbg_instr = "icap_3zero+0x14e                               ";
         972 : dbg_instr = "icap_3zero+0x14f                               ";
         973 : dbg_instr = "icap_3zero+0x150                               ";
         974 : dbg_instr = "icap_3zero+0x151                               ";
         975 : dbg_instr = "icap_3zero+0x152                               ";
         976 : dbg_instr = "icap_3zero+0x153                               ";
         977 : dbg_instr = "icap_3zero+0x154                               ";
         978 : dbg_instr = "icap_3zero+0x155                               ";
         979 : dbg_instr = "icap_3zero+0x156                               ";
         980 : dbg_instr = "icap_3zero+0x157                               ";
         981 : dbg_instr = "icap_3zero+0x158                               ";
         982 : dbg_instr = "icap_3zero+0x159                               ";
         983 : dbg_instr = "icap_3zero+0x15a                               ";
         984 : dbg_instr = "icap_3zero+0x15b                               ";
         985 : dbg_instr = "icap_3zero+0x15c                               ";
         986 : dbg_instr = "icap_3zero+0x15d                               ";
         987 : dbg_instr = "icap_3zero+0x15e                               ";
         988 : dbg_instr = "icap_3zero+0x15f                               ";
         989 : dbg_instr = "icap_3zero+0x160                               ";
         990 : dbg_instr = "icap_3zero+0x161                               ";
         991 : dbg_instr = "icap_3zero+0x162                               ";
         992 : dbg_instr = "icap_3zero+0x163                               ";
         993 : dbg_instr = "icap_3zero+0x164                               ";
         994 : dbg_instr = "icap_3zero+0x165                               ";
         995 : dbg_instr = "icap_3zero+0x166                               ";
         996 : dbg_instr = "icap_3zero+0x167                               ";
         997 : dbg_instr = "icap_3zero+0x168                               ";
         998 : dbg_instr = "icap_3zero+0x169                               ";
         999 : dbg_instr = "icap_3zero+0x16a                               ";
         1000 : dbg_instr = "icap_3zero+0x16b                               ";
         1001 : dbg_instr = "icap_3zero+0x16c                               ";
         1002 : dbg_instr = "icap_3zero+0x16d                               ";
         1003 : dbg_instr = "icap_3zero+0x16e                               ";
         1004 : dbg_instr = "icap_3zero+0x16f                               ";
         1005 : dbg_instr = "icap_3zero+0x170                               ";
         1006 : dbg_instr = "icap_3zero+0x171                               ";
         1007 : dbg_instr = "icap_3zero+0x172                               ";
         1008 : dbg_instr = "icap_3zero+0x173                               ";
         1009 : dbg_instr = "icap_3zero+0x174                               ";
         1010 : dbg_instr = "icap_3zero+0x175                               ";
         1011 : dbg_instr = "icap_3zero+0x176                               ";
         1012 : dbg_instr = "icap_3zero+0x177                               ";
         1013 : dbg_instr = "icap_3zero+0x178                               ";
         1014 : dbg_instr = "icap_3zero+0x179                               ";
         1015 : dbg_instr = "icap_3zero+0x17a                               ";
         1016 : dbg_instr = "icap_3zero+0x17b                               ";
         1017 : dbg_instr = "icap_3zero+0x17c                               ";
         1018 : dbg_instr = "icap_3zero+0x17d                               ";
         1019 : dbg_instr = "icap_3zero+0x17e                               ";
         1020 : dbg_instr = "icap_3zero+0x17f                               ";
         1021 : dbg_instr = "icap_3zero+0x180                               ";
         1022 : dbg_instr = "icap_3zero+0x181                               ";
         1023 : dbg_instr = "icap_3zero+0x182                               ";
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
    .INIT_00(256'h9001700011002010D201920B900A70016EE02004005301040000000020040026),
    .INIT_01(256'h202590017000202590007000201DCED0DD0B7D036EE04ED011802020D202C010),
    .INIT_02(256'hE02B4008020CAA1011011080113701ECB03FB80B90019001700031FFD1C01101),
    .INIT_03(256'h1200D21132FE92116035400E11010224AA102039D0011138021FF000307F70FF),
    .INIT_04(256'h110010011E0070001D011E001180B01B7001F210F212F214F2131200F216F217),
    .INIT_05(256'hB21360C0D700B71720A1D2042086D2032079D2022075D201B210500080019F10),
    .INIT_06(256'h2072130412046070D200B212F314F21343801280D000F314F213B3009201B314),
    .INIT_07(256'h01F3F22100FFF220A2201234B21120EDC230B300B2125000F311F21013001201),
    .INIT_08(256'h00FAB21206704706B71116C002331621F22100FF5000F2101203B02D02101421),
    .INIT_09(256'hF2101202F71120EDD7041701B711C4601601C560B520B4210630430643064306),
    .INIT_0A(256'hE0AC4700440046061710B620B521B42202331622F421149060BBD204B2115000),
    .INIT_0B(256'h20EDD2FC920FD2FD920E5000F2111205D6FBD5FAD4F9D7F8E0B14608450E5608),
    .INIT_0C(256'h01F3141FB41760C7D71F97011201E370A3201218171F60D8D80060C5D701B816),
    .INIT_0D(256'h1219F61836E102330960161F0680F32120E8D800F4151401F418B31834E10210),
    .INIT_0E(256'h60F1D200B2125000F216F217120001ECF815180160E0D91F12019901E320A390),
    .INIT_0F(256'hB2125000E0FB420E130113FF5000D211720192115000F3101300F212420E1280),

    // Address 256 to 511
    .INIT_10(256'h948361C7C2F0928150008001D00B70036E00010C1000C0E05000A230133800FA),
    .INIT_11(256'hD2112143D210928261CBD5006115D183910105608610118401401500E1C9D43C),
    .INIT_12(256'h01CD61C9D200216DD2CA2186D2C92173D2C82131D20F215FD21321B4D2122151),
    .INIT_13(256'hD288B20C0920D287B20B0920D286B20A0920D285B209D984B908B05301CD21BF),
    .INIT_14(256'h614CD5FE150601D215C611860920D28592FDD98499FCB10301CD21BC11890920),
    .INIT_15(256'h01CD21BC615AD5F8150401D115C011860920D28592F9D98499F8B1E301CD21BC),
    .INIT_16(256'h96869585948421BC6168D5FC150601D215C411860920D28592FBD98499FAB103),
    .INIT_17(256'h9211D3114340232072FF2420948593119284217FD200928301CD500002639787),
    .INIT_18(256'hB005B0042191D300B31721A2D200B013928301CD21BFB013D385D28483201300),
    .INIT_19(256'hD48482406198920115011401E340835015851418F2179201F7169784F31521BF),
    .INIT_1A(256'h1401C3100930A340190011841418D28321BFB004B00361A8D200B21521BFD285),
    .INIT_1B(256'h0254C910190179FF1186D2850920B200D9841906B02301CD21BC61AC92011101),
    .INIT_1C(256'hDF80D281928021C3130A21C3130B21C3130C5000E2301201A230130901C31308),
    .INIT_1D(256'h420012084300500001DD01DD01DD5000110115010920C210825001D301D25000),
    .INIT_1E(256'h01DAB02D01DDB00E5000B00DD201920C01D901DDB02D01D9B01E50004308E1DF),
    .INIT_1F(256'hB02D01D9DB0E4B004A021B015000B00D01DDB00E01DAB02DB01E500001DDB01E),

    // Address 512 to 767
    .INIT_20(256'h500001EC01FA01F35000E2084A0001E31A01500001D901E3E1FBB00D01D901DD),
    .INIT_21(256'h1490500001EC021001F3F620F5211423F42250006210D41F9401900001FAAA40),
    .INIT_22(256'hF520F421500002171601158D14D802171607151E14D4FA23221A16051421F421),
    .INIT_23(256'h01D9B02D01D9D20E4200D621EA600207900001FA5A01BA2101F30210142101F3),
    .INIT_24(256'h0247224817011000D20082701000C7600750500001EC01D96238D61F9601B00D),
    .INIT_25(256'hC560D208024FD20015018250D708977F02471685968315805000027017018750),
    .INIT_26(256'hB020B300027CB660B550B990BAA0BFF0BFF0BFF0BFF0D21112805000B008A25A),
    .INIT_27(256'hB000B000B000B200B0F0027DB010B080B000B300D700D600D500D400B010B000),
    .INIT_28(256'h1000100010001000100010001000100010001000100010001000100010005000),
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
    .INITP_00(256'hAA1302A0834A4E9434DDDD280302EA8A20D630A0D842AAD5AEBC8432B3036A0A),
    .INITP_01(256'h2D4A0E24D2A29D582612D88693560774A228AAD4D50088D28B5260558508AA28),

    // Address 256 to 511
    .INITP_02(256'h200034A802D60622AD60622AD60622A18618622AB777777774DD510D34A82C86),
    .INITP_03(256'hA94AAAAAAAA0AAA746AA562AA2222908A4248AB56402AB4A9D58098AAD362AA4),

    // Address 512 to 767
    .INITP_04(256'hAAAAAAAAAAAAAA2B6D499085A74D2AD6AA5AE0A2AA0202822AA8AD78AAB62AEA),
    .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000002),

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
