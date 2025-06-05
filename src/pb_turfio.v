/*
 * == pblaze-cc ==
 * source : pb_turfio.c
 * create : Thu Jun  5 16:42:49 2025
 * modify : Thu Jun  5 16:42:49 2025
 */
`timescale 1 ps / 1ps

/* 
 * == pblaze-as ==
 * source : pb_turfio.s
 * create : Thu Jun  5 16:48:15 2025
 * modify : Thu Jun  5 16:48:15 2025
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
         38 : dbg_instr = "isr_serial+0x01f                               ";
         39 : dbg_instr = "isr_serial+0x020                               ";
         40 : dbg_instr = "isr_serial+0x021                               ";
         41 : dbg_instr = "isr_serial+0x022                               ";
         42 : dbg_instr = "isr_serial+0x023                               ";
         43 : dbg_instr = "isr_serial+0x024                               ";
         44 : dbg_instr = "isr_serial+0x025                               ";
         45 : dbg_instr = "init                                           ";
         46 : dbg_instr = "init+0x001                                     ";
         47 : dbg_instr = "init+0x002                                     ";
         48 : dbg_instr = "init+0x003                                     ";
         49 : dbg_instr = "init+0x004                                     ";
         50 : dbg_instr = "init+0x005                                     ";
         51 : dbg_instr = "init+0x006                                     ";
         52 : dbg_instr = "init+0x007                                     ";
         53 : dbg_instr = "init+0x008                                     ";
         54 : dbg_instr = "init+0x009                                     ";
         55 : dbg_instr = "init+0x00a                                     ";
         56 : dbg_instr = "init+0x00b                                     ";
         57 : dbg_instr = "init+0x00c                                     ";
         58 : dbg_instr = "init+0x00d                                     ";
         59 : dbg_instr = "init+0x00e                                     ";
         60 : dbg_instr = "init+0x00f                                     ";
         61 : dbg_instr = "init+0x010                                     ";
         62 : dbg_instr = "init+0x011                                     ";
         63 : dbg_instr = "init+0x012                                     ";
         64 : dbg_instr = "init+0x013                                     ";
         65 : dbg_instr = "init+0x014                                     ";
         66 : dbg_instr = "init+0x015                                     ";
         67 : dbg_instr = "init+0x016                                     ";
         68 : dbg_instr = "init+0x017                                     ";
         69 : dbg_instr = "init+0x018                                     ";
         70 : dbg_instr = "init+0x019                                     ";
         71 : dbg_instr = "init+0x01a                                     ";
         72 : dbg_instr = "init+0x01b                                     ";
         73 : dbg_instr = "init+0x01c                                     ";
         74 : dbg_instr = "init+0x01d                                     ";
         75 : dbg_instr = "init+0x01e                                     ";
         76 : dbg_instr = "init+0x01f                                     ";
         77 : dbg_instr = "init+0x020                                     ";
         78 : dbg_instr = "init+0x021                                     ";
         79 : dbg_instr = "init+0x022                                     ";
         80 : dbg_instr = "init+0x023                                     ";
         81 : dbg_instr = "init+0x024                                     ";
         82 : dbg_instr = "init+0x025                                     ";
         83 : dbg_instr = "init+0x026                                     ";
         84 : dbg_instr = "init+0x027                                     ";
         85 : dbg_instr = "init+0x028                                     ";
         86 : dbg_instr = "init+0x029                                     ";
         87 : dbg_instr = "init+0x02a                                     ";
         88 : dbg_instr = "init+0x02b                                     ";
         89 : dbg_instr = "init+0x02c                                     ";
         90 : dbg_instr = "init+0x02d                                     ";
         91 : dbg_instr = "update_housekeeping                            ";
         92 : dbg_instr = "update_housekeeping+0x001                      ";
         93 : dbg_instr = "update_housekeeping+0x002                      ";
         94 : dbg_instr = "update_housekeeping+0x003                      ";
         95 : dbg_instr = "update_housekeeping+0x004                      ";
         96 : dbg_instr = "update_housekeeping+0x005                      ";
         97 : dbg_instr = "update_housekeeping+0x006                      ";
         98 : dbg_instr = "update_housekeeping+0x007                      ";
         99 : dbg_instr = "update_housekeeping+0x008                      ";
         100 : dbg_instr = "IDLE_WAIT                                      ";
         101 : dbg_instr = "IDLE_WAIT+0x001                                ";
         102 : dbg_instr = "IDLE_WAIT+0x002                                ";
         103 : dbg_instr = "IDLE_WAIT+0x003                                ";
         104 : dbg_instr = "IDLE_WAIT+0x004                                ";
         105 : dbg_instr = "IDLE_WAIT+0x005                                ";
         106 : dbg_instr = "IDLE_WAIT+0x006                                ";
         107 : dbg_instr = "IDLE_WAIT+0x007                                ";
         108 : dbg_instr = "IDLE_WAIT+0x008                                ";
         109 : dbg_instr = "IDLE_WAIT+0x009                                ";
         110 : dbg_instr = "IDLE_WAIT+0x00a                                ";
         111 : dbg_instr = "IDLE_WAIT+0x00b                                ";
         112 : dbg_instr = "IDLE_WAIT+0x00c                                ";
         113 : dbg_instr = "IDLE_WAIT+0x00d                                ";
         114 : dbg_instr = "IDLE_WAIT+0x00e                                ";
         115 : dbg_instr = "IDLE_WAIT+0x00f                                ";
         116 : dbg_instr = "IDLE_WAIT+0x010                                ";
         117 : dbg_instr = "IDLE_WAIT+0x011                                ";
         118 : dbg_instr = "IDLE_WAIT+0x012                                ";
         119 : dbg_instr = "IDLE_WAIT+0x013                                ";
         120 : dbg_instr = "IDLE_WAIT+0x014                                ";
         121 : dbg_instr = "IDLE_WAIT+0x015                                ";
         122 : dbg_instr = "IDLE_WAIT+0x016                                ";
         123 : dbg_instr = "IDLE_WAIT+0x017                                ";
         124 : dbg_instr = "IDLE_WAIT+0x018                                ";
         125 : dbg_instr = "SURF_CHECK                                     ";
         126 : dbg_instr = "SURF_CHECK+0x001                               ";
         127 : dbg_instr = "SURF_CHECK+0x002                               ";
         128 : dbg_instr = "SURF_CHECK+0x003                               ";
         129 : dbg_instr = "SURF_WRITE_REG                                 ";
         130 : dbg_instr = "SURF_WRITE_REG+0x001                           ";
         131 : dbg_instr = "SURF_WRITE_REG+0x002                           ";
         132 : dbg_instr = "SURF_WRITE_REG+0x003                           ";
         133 : dbg_instr = "SURF_WRITE_REG+0x004                           ";
         134 : dbg_instr = "SURF_WRITE_REG+0x005                           ";
         135 : dbg_instr = "SURF_WRITE_REG+0x006                           ";
         136 : dbg_instr = "SURF_WRITE_REG+0x007                           ";
         137 : dbg_instr = "SURF_WRITE_REG+0x008                           ";
         138 : dbg_instr = "SURF_WRITE_REG+0x009                           ";
         139 : dbg_instr = "SURF_WRITE_REG+0x00a                           ";
         140 : dbg_instr = "SURF_WRITE_REG+0x00b                           ";
         141 : dbg_instr = "SURF_WRITE_REG+0x00c                           ";
         142 : dbg_instr = "SURF_READ_REG                                  ";
         143 : dbg_instr = "SURF_READ_REG+0x001                            ";
         144 : dbg_instr = "SURF_READ_REG+0x002                            ";
         145 : dbg_instr = "SURF_READ_REG+0x003                            ";
         146 : dbg_instr = "SURF_READ_REG+0x004                            ";
         147 : dbg_instr = "SURF_READ_REG+0x005                            ";
         148 : dbg_instr = "SURF_READ_REG+0x006                            ";
         149 : dbg_instr = "SURF_READ_REG+0x007                            ";
         150 : dbg_instr = "SURF_READ_REG+0x008                            ";
         151 : dbg_instr = "SURF_READ_REG+0x009                            ";
         152 : dbg_instr = "SURF_READ_REG+0x00a                            ";
         153 : dbg_instr = "SURF_READ_REG+0x00b                            ";
         154 : dbg_instr = "SURF_READ_REG+0x00c                            ";
         155 : dbg_instr = "SURF_READ_REG+0x00d                            ";
         156 : dbg_instr = "SURF_READ_REG+0x00e                            ";
         157 : dbg_instr = "SURF_READ_REG+0x00f                            ";
         158 : dbg_instr = "SURF_READ_REG+0x010                            ";
         159 : dbg_instr = "SURF_READ_REG+0x011                            ";
         160 : dbg_instr = "SURF_READ_REG+0x012                            ";
         161 : dbg_instr = "SURF_READ_REG+0x013                            ";
         162 : dbg_instr = "SURF_READ_REG+0x014                            ";
         163 : dbg_instr = "SURF_READ_REG+0x015                            ";
         164 : dbg_instr = "SURF_READ_REG+0x016                            ";
         165 : dbg_instr = "SURF_READ_REG+0x017                            ";
         166 : dbg_instr = "SURF_READ_REG+0x018                            ";
         167 : dbg_instr = "SURF_READ_REG+0x019                            ";
         168 : dbg_instr = "SURF_READ_REG+0x01a                            ";
         169 : dbg_instr = "TURFIO                                         ";
         170 : dbg_instr = "TURFIO+0x001                                   ";
         171 : dbg_instr = "TURFIO+0x002                                   ";
         172 : dbg_instr = "TURFIO+0x003                                   ";
         173 : dbg_instr = "TURFIO+0x004                                   ";
         174 : dbg_instr = "TURFIO+0x005                                   ";
         175 : dbg_instr = "TURFIO+0x006                                   ";
         176 : dbg_instr = "TURFIO+0x007                                   ";
         177 : dbg_instr = "TURFIO+0x008                                   ";
         178 : dbg_instr = "TURFIO+0x009                                   ";
         179 : dbg_instr = "TURFIO+0x00a                                   ";
         180 : dbg_instr = "TURFIO+0x00b                                   ";
         181 : dbg_instr = "TURFIO+0x00c                                   ";
         182 : dbg_instr = "TURFIO+0x00d                                   ";
         183 : dbg_instr = "TURFIO+0x00e                                   ";
         184 : dbg_instr = "TURFIO+0x00f                                   ";
         185 : dbg_instr = "TURFIO+0x010                                   ";
         186 : dbg_instr = "TURFIO+0x011                                   ";
         187 : dbg_instr = "TURFIO+0x012                                   ";
         188 : dbg_instr = "TURFIO+0x013                                   ";
         189 : dbg_instr = "TURFIO+0x014                                   ";
         190 : dbg_instr = "TURFIO+0x015                                   ";
         191 : dbg_instr = "TURFIO+0x016                                   ";
         192 : dbg_instr = "TURFIO+0x017                                   ";
         193 : dbg_instr = "TURFIO+0x018                                   ";
         194 : dbg_instr = "TURFIO+0x019                                   ";
         195 : dbg_instr = "TURFIO+0x01a                                   ";
         196 : dbg_instr = "TURFIO+0x01b                                   ";
         197 : dbg_instr = "TURFIO+0x01c                                   ";
         198 : dbg_instr = "TURFIO+0x01d                                   ";
         199 : dbg_instr = "TURFIO+0x01e                                   ";
         200 : dbg_instr = "TURFIO+0x01f                                   ";
         201 : dbg_instr = "PMBUS                                          ";
         202 : dbg_instr = "PMBUS+0x001                                    ";
         203 : dbg_instr = "PMBUS+0x002                                    ";
         204 : dbg_instr = "PMBUS+0x003                                    ";
         205 : dbg_instr = "PMBUS+0x004                                    ";
         206 : dbg_instr = "WRITE_PMBUS                                    ";
         207 : dbg_instr = "WRITE_PMBUS+0x001                              ";
         208 : dbg_instr = "WRITE_PMBUS+0x002                              ";
         209 : dbg_instr = "WRITE_PMBUS+0x003                              ";
         210 : dbg_instr = "WRITE_PMBUS+0x004                              ";
         211 : dbg_instr = "WRITE_PMBUS+0x005                              ";
         212 : dbg_instr = "WRITE_PMBUS+0x006                              ";
         213 : dbg_instr = "WRITE_PMBUS+0x007                              ";
         214 : dbg_instr = "WRITE_PMBUS+0x008                              ";
         215 : dbg_instr = "WRITE_PMBUS+0x009                              ";
         216 : dbg_instr = "WRITE_PMBUS+0x00a                              ";
         217 : dbg_instr = "WRITE_PMBUS+0x00b                              ";
         218 : dbg_instr = "WRITE_PMBUS+0x00c                              ";
         219 : dbg_instr = "WRITE_PMBUS+0x00d                              ";
         220 : dbg_instr = "WRITE_PMBUS+0x00e                              ";
         221 : dbg_instr = "WRITE_PMBUS+0x00f                              ";
         222 : dbg_instr = "WRITE_PMBUS+0x010                              ";
         223 : dbg_instr = "WRITE_PMBUS+0x011                              ";
         224 : dbg_instr = "WRITE_PMBUS+0x012                              ";
         225 : dbg_instr = "READ_PMBUS                                     ";
         226 : dbg_instr = "READ_PMBUS+0x001                               ";
         227 : dbg_instr = "READ_PMBUS+0x002                               ";
         228 : dbg_instr = "READ_PMBUS+0x003                               ";
         229 : dbg_instr = "READ_PMBUS+0x004                               ";
         230 : dbg_instr = "READ_PMBUS+0x005                               ";
         231 : dbg_instr = "READ_PMBUS+0x006                               ";
         232 : dbg_instr = "READ_PMBUS+0x007                               ";
         233 : dbg_instr = "READ_PMBUS+0x008                               ";
         234 : dbg_instr = "READ_PMBUS+0x009                               ";
         235 : dbg_instr = "READ_PMBUS+0x00a                               ";
         236 : dbg_instr = "READ_PMBUS+0x00b                               ";
         237 : dbg_instr = "READ_PMBUS+0x00c                               ";
         238 : dbg_instr = "READ_PMBUS+0x00d                               ";
         239 : dbg_instr = "READ_PMBUS+0x00e                               ";
         240 : dbg_instr = "READ_PMBUS+0x00f                               ";
         241 : dbg_instr = "FINISH_PMBUS                                   ";
         242 : dbg_instr = "FINISH_PMBUS+0x001                             ";
         243 : dbg_instr = "FINISH_PMBUS+0x002                             ";
         244 : dbg_instr = "FINISH_PMBUS+0x003                             ";
         245 : dbg_instr = "FINISH_PMBUS+0x004                             ";
         246 : dbg_instr = "hskNextDevice                                  ";
         247 : dbg_instr = "hskNextDevice+0x001                            ";
         248 : dbg_instr = "hskNextDevice+0x002                            ";
         249 : dbg_instr = "hskNextDevice+0x003                            ";
         250 : dbg_instr = "hskNextDevice+0x004                            ";
         251 : dbg_instr = "hskNextDevice+0x005                            ";
         252 : dbg_instr = "hskNextDevice+0x006                            ";
         253 : dbg_instr = "hskNextDevice+0x007                            ";
         254 : dbg_instr = "hskNextDevice+0x008                            ";
         255 : dbg_instr = "hskNextDevice+0x009                            ";
         256 : dbg_instr = "hskNextDevice+0x00a                            ";
         257 : dbg_instr = "hskNextDevice+0x00b                            ";
         258 : dbg_instr = "hskNextDevice+0x00c                            ";
         259 : dbg_instr = "hskCountDevice                                 ";
         260 : dbg_instr = "hskCountDevice+0x001                           ";
         261 : dbg_instr = "hskCountDevice+0x002                           ";
         262 : dbg_instr = "hskCountDevice+0x003                           ";
         263 : dbg_instr = "hskCountDevice+0x004                           ";
         264 : dbg_instr = "hskGetDeviceAddress                            ";
         265 : dbg_instr = "hskGetDeviceAddress+0x001                      ";
         266 : dbg_instr = "hskGetDeviceAddress+0x002                      ";
         267 : dbg_instr = "hskGetDeviceAddress+0x003                      ";
         268 : dbg_instr = "hskGetDeviceAddress+0x004                      ";
         269 : dbg_instr = "handle_serial                                  ";
         270 : dbg_instr = "handle_serial+0x001                            ";
         271 : dbg_instr = "handle_serial+0x002                            ";
         272 : dbg_instr = "handle_serial+0x003                            ";
         273 : dbg_instr = "handle_serial+0x004                            ";
         274 : dbg_instr = "handle_serial+0x005                            ";
         275 : dbg_instr = "handle_serial+0x006                            ";
         276 : dbg_instr = "handle_serial+0x007                            ";
         277 : dbg_instr = "parse_serial                                   ";
         278 : dbg_instr = "parse_serial+0x001                             ";
         279 : dbg_instr = "parse_serial+0x002                             ";
         280 : dbg_instr = "parse_serial+0x003                             ";
         281 : dbg_instr = "parse_serial+0x004                             ";
         282 : dbg_instr = "parse_serial+0x005                             ";
         283 : dbg_instr = "parse_serial+0x006                             ";
         284 : dbg_instr = "parse_serial+0x007                             ";
         285 : dbg_instr = "parse_serial+0x008                             ";
         286 : dbg_instr = "parse_serial+0x009                             ";
         287 : dbg_instr = "parse_serial+0x00a                             ";
         288 : dbg_instr = "parse_serial+0x00b                             ";
         289 : dbg_instr = "parse_serial+0x00c                             ";
         290 : dbg_instr = "parse_serial+0x00d                             ";
         291 : dbg_instr = "parse_serial+0x00e                             ";
         292 : dbg_instr = "parse_serial+0x00f                             ";
         293 : dbg_instr = "parse_serial+0x010                             ";
         294 : dbg_instr = "parse_serial+0x011                             ";
         295 : dbg_instr = "parse_serial+0x012                             ";
         296 : dbg_instr = "parse_serial+0x013                             ";
         297 : dbg_instr = "parse_serial+0x014                             ";
         298 : dbg_instr = "parse_serial+0x015                             ";
         299 : dbg_instr = "parse_serial+0x016                             ";
         300 : dbg_instr = "parse_serial+0x017                             ";
         301 : dbg_instr = "parse_serial+0x018                             ";
         302 : dbg_instr = "parse_serial+0x019                             ";
         303 : dbg_instr = "parse_serial+0x01a                             ";
         304 : dbg_instr = "parse_serial+0x01b                             ";
         305 : dbg_instr = "parse_serial+0x01c                             ";
         306 : dbg_instr = "parse_serial+0x01d                             ";
         307 : dbg_instr = "parse_serial+0x01e                             ";
         308 : dbg_instr = "parse_serial+0x01f                             ";
         309 : dbg_instr = "parse_serial+0x020                             ";
         310 : dbg_instr = "parse_serial+0x021                             ";
         311 : dbg_instr = "parse_serial+0x022                             ";
         312 : dbg_instr = "parse_serial+0x023                             ";
         313 : dbg_instr = "parse_serial+0x024                             ";
         314 : dbg_instr = "do_PingPong                                    ";
         315 : dbg_instr = "do_PingPong+0x001                              ";
         316 : dbg_instr = "do_Statistics                                  ";
         317 : dbg_instr = "do_Statistics+0x001                            ";
         318 : dbg_instr = "do_Statistics+0x002                            ";
         319 : dbg_instr = "do_Statistics+0x003                            ";
         320 : dbg_instr = "do_Statistics+0x004                            ";
         321 : dbg_instr = "do_Statistics+0x005                            ";
         322 : dbg_instr = "do_Statistics+0x006                            ";
         323 : dbg_instr = "do_Statistics+0x007                            ";
         324 : dbg_instr = "do_Statistics+0x008                            ";
         325 : dbg_instr = "do_Statistics+0x009                            ";
         326 : dbg_instr = "do_Statistics+0x00a                            ";
         327 : dbg_instr = "do_Statistics+0x00b                            ";
         328 : dbg_instr = "do_Statistics+0x00c                            ";
         329 : dbg_instr = "do_Statistics+0x00d                            ";
         330 : dbg_instr = "do_Statistics+0x00e                            ";
         331 : dbg_instr = "do_Statistics+0x00f                            ";
         332 : dbg_instr = "do_Statistics+0x010                            ";
         333 : dbg_instr = "do_Statistics+0x011                            ";
         334 : dbg_instr = "do_Temps                                       ";
         335 : dbg_instr = "do_Temps+0x001                                 ";
         336 : dbg_instr = "do_Temps+0x002                                 ";
         337 : dbg_instr = "do_Temps+0x003                                 ";
         338 : dbg_instr = "do_Temps+0x004                                 ";
         339 : dbg_instr = "do_Temps+0x005                                 ";
         340 : dbg_instr = "do_Temps+0x006                                 ";
         341 : dbg_instr = "do_Temps+0x007                                 ";
         342 : dbg_instr = "do_Temps+0x008                                 ";
         343 : dbg_instr = "do_Temps+0x009                                 ";
         344 : dbg_instr = "do_Temps+0x00a                                 ";
         345 : dbg_instr = "do_Temps+0x00b                                 ";
         346 : dbg_instr = "do_Temps+0x00c                                 ";
         347 : dbg_instr = "do_Temps+0x00d                                 ";
         348 : dbg_instr = "do_Volts                                       ";
         349 : dbg_instr = "do_Volts+0x001                                 ";
         350 : dbg_instr = "do_Volts+0x002                                 ";
         351 : dbg_instr = "do_Volts+0x003                                 ";
         352 : dbg_instr = "do_Volts+0x004                                 ";
         353 : dbg_instr = "do_Volts+0x005                                 ";
         354 : dbg_instr = "do_Volts+0x006                                 ";
         355 : dbg_instr = "do_Volts+0x007                                 ";
         356 : dbg_instr = "do_Volts+0x008                                 ";
         357 : dbg_instr = "do_Volts+0x009                                 ";
         358 : dbg_instr = "do_Volts+0x00a                                 ";
         359 : dbg_instr = "do_Volts+0x00b                                 ";
         360 : dbg_instr = "do_Volts+0x00c                                 ";
         361 : dbg_instr = "do_Volts+0x00d                                 ";
         362 : dbg_instr = "do_Currents                                    ";
         363 : dbg_instr = "do_Currents+0x001                              ";
         364 : dbg_instr = "do_Currents+0x002                              ";
         365 : dbg_instr = "do_Currents+0x003                              ";
         366 : dbg_instr = "do_Currents+0x004                              ";
         367 : dbg_instr = "do_Currents+0x005                              ";
         368 : dbg_instr = "do_Currents+0x006                              ";
         369 : dbg_instr = "do_Currents+0x007                              ";
         370 : dbg_instr = "do_Currents+0x008                              ";
         371 : dbg_instr = "do_Currents+0x009                              ";
         372 : dbg_instr = "do_Currents+0x00a                              ";
         373 : dbg_instr = "do_Currents+0x00b                              ";
         374 : dbg_instr = "do_Currents+0x00c                              ";
         375 : dbg_instr = "do_Currents+0x00d                              ";
         376 : dbg_instr = "do_Aurora                                      ";
         377 : dbg_instr = "do_Aurora+0x001                                ";
         378 : dbg_instr = "do_Aurora+0x002                                ";
         379 : dbg_instr = "do_Aurora+0x003                                ";
         380 : dbg_instr = "do_Aurora+0x004                                ";
         381 : dbg_instr = "do_Aurora+0x005                                ";
         382 : dbg_instr = "do_Aurora+0x006                                ";
         383 : dbg_instr = "do_Aurora+0x007                                ";
         384 : dbg_instr = "do_ReloadFirmware                              ";
         385 : dbg_instr = "do_ReloadFirmware+0x001                        ";
         386 : dbg_instr = "do_ReloadFirmware+0x002                        ";
         387 : dbg_instr = "do_ReloadFirmware+0x003                        ";
         388 : dbg_instr = "do_ReloadFirmware+0x004                        ";
         389 : dbg_instr = "do_ReloadFirmware+0x005                        ";
         390 : dbg_instr = "do_Enable                                      ";
         391 : dbg_instr = "do_Enable+0x001                                ";
         392 : dbg_instr = "do_Enable+0x002                                ";
         393 : dbg_instr = "do_Enable+0x003                                ";
         394 : dbg_instr = "do_Enable+0x004                                ";
         395 : dbg_instr = "do_Enable+0x005                                ";
         396 : dbg_instr = "do_Enable+0x006                                ";
         397 : dbg_instr = "do_Enable+0x007                                ";
         398 : dbg_instr = "do_Enable+0x008                                ";
         399 : dbg_instr = "do_Enable+0x009                                ";
         400 : dbg_instr = "do_Enable+0x00a                                ";
         401 : dbg_instr = "do_Enable+0x00b                                ";
         402 : dbg_instr = "do_Enable+0x00c                                ";
         403 : dbg_instr = "do_Enable+0x00d                                ";
         404 : dbg_instr = "do_Enable+0x00e                                ";
         405 : dbg_instr = "do_Enable+0x00f                                ";
         406 : dbg_instr = "do_Enable+0x010                                ";
         407 : dbg_instr = "do_Enable+0x011                                ";
         408 : dbg_instr = "do_Enable+0x012                                ";
         409 : dbg_instr = "do_PMBus                                       ";
         410 : dbg_instr = "do_PMBus+0x001                                 ";
         411 : dbg_instr = "do_PMBus+0x002                                 ";
         412 : dbg_instr = "do_PMBus+0x003                                 ";
         413 : dbg_instr = "do_PMBus+0x004                                 ";
         414 : dbg_instr = "do_PMBus+0x005                                 ";
         415 : dbg_instr = "do_PMBus+0x006                                 ";
         416 : dbg_instr = "do_PMBus+0x007                                 ";
         417 : dbg_instr = "do_PMBus+0x008                                 ";
         418 : dbg_instr = "do_PMBus+0x009                                 ";
         419 : dbg_instr = "do_PMBus+0x00a                                 ";
         420 : dbg_instr = "PMBus_Write                                    ";
         421 : dbg_instr = "PMBus_Write+0x001                              ";
         422 : dbg_instr = "PMBus_Write+0x002                              ";
         423 : dbg_instr = "PMBus_Write+0x003                              ";
         424 : dbg_instr = "PMBus_Write+0x004                              ";
         425 : dbg_instr = "PMBus_Write+0x005                              ";
         426 : dbg_instr = "PMBus_Write+0x006                              ";
         427 : dbg_instr = "PMBus_Write+0x007                              ";
         428 : dbg_instr = "PMBus_Write+0x008                              ";
         429 : dbg_instr = "PMBus_Write+0x009                              ";
         430 : dbg_instr = "PMBus_Write+0x00a                              ";
         431 : dbg_instr = "PMBus_Write+0x00b                              ";
         432 : dbg_instr = "PMBus_Write+0x00c                              ";
         433 : dbg_instr = "PMBus_Write+0x00d                              ";
         434 : dbg_instr = "PMBus_Write+0x00e                              ";
         435 : dbg_instr = "PMBus_Write+0x00f                              ";
         436 : dbg_instr = "PMBus_Write+0x010                              ";
         437 : dbg_instr = "PMBus_Read                                     ";
         438 : dbg_instr = "PMBus_Read+0x001                               ";
         439 : dbg_instr = "PMBus_Read+0x002                               ";
         440 : dbg_instr = "PMBus_Read+0x003                               ";
         441 : dbg_instr = "PMBus_Read+0x004                               ";
         442 : dbg_instr = "PMBus_Read+0x005                               ";
         443 : dbg_instr = "PMBus_Read+0x006                               ";
         444 : dbg_instr = "PMBus_Read+0x007                               ";
         445 : dbg_instr = "PMBus_Read+0x008                               ";
         446 : dbg_instr = "PMBus_Read+0x009                               ";
         447 : dbg_instr = "PMBus_Read+0x00a                               ";
         448 : dbg_instr = "PMBus_Read+0x00b                               ";
         449 : dbg_instr = "PMBus_Read+0x00c                               ";
         450 : dbg_instr = "PMBus_Read+0x00d                               ";
         451 : dbg_instr = "PMBus_Read+0x00e                               ";
         452 : dbg_instr = "PMBus_Read+0x00f                               ";
         453 : dbg_instr = "PMBus_Read+0x010                               ";
         454 : dbg_instr = "PMBus_Read+0x011                               ";
         455 : dbg_instr = "do_Identify                                    ";
         456 : dbg_instr = "do_Identify+0x001                              ";
         457 : dbg_instr = "do_Identify+0x002                              ";
         458 : dbg_instr = "do_Identify+0x003                              ";
         459 : dbg_instr = "do_Identify+0x004                              ";
         460 : dbg_instr = "do_Identify+0x005                              ";
         461 : dbg_instr = "do_Identify+0x006                              ";
         462 : dbg_instr = "do_Identify+0x007                              ";
         463 : dbg_instr = "finishPacket                                   ";
         464 : dbg_instr = "finishPacket+0x001                             ";
         465 : dbg_instr = "finishPacket+0x002                             ";
         466 : dbg_instr = "goodPacket                                     ";
         467 : dbg_instr = "goodPacket+0x001                               ";
         468 : dbg_instr = "goodPacket+0x002                               ";
         469 : dbg_instr = "goodPacket+0x003                               ";
         470 : dbg_instr = "fetchAndIncrement                              ";
         471 : dbg_instr = "fetchAndIncrement+0x001                        ";
         472 : dbg_instr = "fetchAndIncrement+0x002                        ";
         473 : dbg_instr = "fetchAndIncrement+0x003                        ";
         474 : dbg_instr = "skippedPacket                                  ";
         475 : dbg_instr = "skippedPacket+0x001                            ";
         476 : dbg_instr = "droppedPacket                                  ";
         477 : dbg_instr = "droppedPacket+0x001                            ";
         478 : dbg_instr = "errorPacket                                    ";
         479 : dbg_instr = "errorPacket+0x001                              ";
         480 : dbg_instr = "hsk_header                                     ";
         481 : dbg_instr = "hsk_header+0x001                               ";
         482 : dbg_instr = "hsk_header+0x002                               ";
         483 : dbg_instr = "hsk_header+0x003                               ";
         484 : dbg_instr = "hsk_copy4                                      ";
         485 : dbg_instr = "hsk_copy2                                      ";
         486 : dbg_instr = "hsk_copy1                                      ";
         487 : dbg_instr = "hsk_copy1+0x001                                ";
         488 : dbg_instr = "hsk_copy1+0x002                                ";
         489 : dbg_instr = "hsk_copy1+0x003                                ";
         490 : dbg_instr = "hsk_copy1+0x004                                ";
         491 : dbg_instr = "hsk_copy1+0x005                                ";
         492 : dbg_instr = "I2C_delay_hclk                                 ";
         493 : dbg_instr = "I2C_delay_med                                  ";
         494 : dbg_instr = "I2C_delay_med+0x001                            ";
         495 : dbg_instr = "I2C_delay_med+0x002                            ";
         496 : dbg_instr = "I2C_delay_short                                ";
         497 : dbg_instr = "I2C_delay_short+0x001                          ";
         498 : dbg_instr = "I2C_delay_short+0x002                          ";
         499 : dbg_instr = "I2C_delay_short+0x003                          ";
         500 : dbg_instr = "I2C_delay_short+0x004                          ";
         501 : dbg_instr = "I2C_delay_short+0x005                          ";
         502 : dbg_instr = "I2C_Rx_bit                                     ";
         503 : dbg_instr = "I2C_Rx_bit+0x001                               ";
         504 : dbg_instr = "I2C_Rx_bit+0x002                               ";
         505 : dbg_instr = "I2C_Rx_bit+0x003                               ";
         506 : dbg_instr = "I2C_Rx_bit+0x004                               ";
         507 : dbg_instr = "I2C_Rx_bit+0x005                               ";
         508 : dbg_instr = "I2C_Rx_bit+0x006                               ";
         509 : dbg_instr = "I2C_Rx_bit+0x007                               ";
         510 : dbg_instr = "I2C_Rx_bit+0x008                               ";
         511 : dbg_instr = "I2C_stop                                       ";
         512 : dbg_instr = "I2C_stop+0x001                                 ";
         513 : dbg_instr = "I2C_stop+0x002                                 ";
         514 : dbg_instr = "I2C_stop+0x003                                 ";
         515 : dbg_instr = "I2C_stop+0x004                                 ";
         516 : dbg_instr = "I2C_stop+0x005                                 ";
         517 : dbg_instr = "I2C_stop+0x006                                 ";
         518 : dbg_instr = "I2C_start                                      ";
         519 : dbg_instr = "I2C_start+0x001                                ";
         520 : dbg_instr = "I2C_start+0x002                                ";
         521 : dbg_instr = "I2C_start+0x003                                ";
         522 : dbg_instr = "I2C_start+0x004                                ";
         523 : dbg_instr = "I2C_start+0x005                                ";
         524 : dbg_instr = "I2C_start+0x006                                ";
         525 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK                         ";
         526 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x001                   ";
         527 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x002                   ";
         528 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x003                   ";
         529 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x004                   ";
         530 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x005                   ";
         531 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x006                   ";
         532 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x007                   ";
         533 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x008                   ";
         534 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x009                   ";
         535 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00a                   ";
         536 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00b                   ";
         537 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00c                   ";
         538 : dbg_instr = "I2C_Rx_byte                                    ";
         539 : dbg_instr = "I2C_Rx_byte+0x001                              ";
         540 : dbg_instr = "I2C_Rx_byte+0x002                              ";
         541 : dbg_instr = "I2C_Rx_byte+0x003                              ";
         542 : dbg_instr = "I2C_Rx_byte+0x004                              ";
         543 : dbg_instr = "I2C_test                                       ";
         544 : dbg_instr = "I2C_test+0x001                                 ";
         545 : dbg_instr = "I2C_test+0x002                                 ";
         546 : dbg_instr = "I2C_test+0x003                                 ";
         547 : dbg_instr = "I2C_user_tx_process                            ";
         548 : dbg_instr = "I2C_user_tx_process+0x001                      ";
         549 : dbg_instr = "I2C_user_tx_process+0x002                      ";
         550 : dbg_instr = "I2C_user_tx_process+0x003                      ";
         551 : dbg_instr = "I2C_user_tx_process+0x004                      ";
         552 : dbg_instr = "I2C_user_tx_process+0x005                      ";
         553 : dbg_instr = "I2C_user_tx_process+0x006                      ";
         554 : dbg_instr = "I2C_send3                                      ";
         555 : dbg_instr = "I2C_send3+0x001                                ";
         556 : dbg_instr = "I2C_send3+0x002                                ";
         557 : dbg_instr = "I2C_send1_prcs                                 ";
         558 : dbg_instr = "I2C_send1_prcs+0x001                           ";
         559 : dbg_instr = "I2C_send1_prcs+0x002                           ";
         560 : dbg_instr = "I2C_send1_prcs+0x003                           ";
         561 : dbg_instr = "I2C_send1_prcs+0x004                           ";
         562 : dbg_instr = "I2C_turfio_initialize                          ";
         563 : dbg_instr = "I2C_turfio_initialize+0x001                    ";
         564 : dbg_instr = "I2C_turfio_initialize+0x002                    ";
         565 : dbg_instr = "I2C_turfio_initialize+0x003                    ";
         566 : dbg_instr = "I2C_turfio_initialize+0x004                    ";
         567 : dbg_instr = "I2C_surf_initialize                            ";
         568 : dbg_instr = "I2C_surf_initialize+0x001                      ";
         569 : dbg_instr = "I2C_surf_initialize+0x002                      ";
         570 : dbg_instr = "I2C_surf_initialize+0x003                      ";
         571 : dbg_instr = "I2C_surf_initialize+0x004                      ";
         572 : dbg_instr = "I2C_surf_initialize+0x005                      ";
         573 : dbg_instr = "I2C_surf_initialize+0x006                      ";
         574 : dbg_instr = "I2C_surf_initialize+0x007                      ";
         575 : dbg_instr = "I2C_surf_initialize+0x008                      ";
         576 : dbg_instr = "I2C_surf_initialize+0x009                      ";
         577 : dbg_instr = "I2C_read_register                              ";
         578 : dbg_instr = "I2C_read_register+0x001                        ";
         579 : dbg_instr = "I2C_read_register+0x002                        ";
         580 : dbg_instr = "I2C_read_register+0x003                        ";
         581 : dbg_instr = "I2C_read_register+0x004                        ";
         582 : dbg_instr = "I2C_read                                       ";
         583 : dbg_instr = "I2C_read+0x001                                 ";
         584 : dbg_instr = "I2C_read+0x002                                 ";
         585 : dbg_instr = "I2C_read+0x003                                 ";
         586 : dbg_instr = "I2C_read+0x004                                 ";
         587 : dbg_instr = "I2C_read+0x005                                 ";
         588 : dbg_instr = "I2C_read+0x006                                 ";
         589 : dbg_instr = "I2C_read+0x007                                 ";
         590 : dbg_instr = "I2C_read+0x008                                 ";
         591 : dbg_instr = "I2C_read+0x009                                 ";
         592 : dbg_instr = "I2C_read+0x00a                                 ";
         593 : dbg_instr = "I2C_read+0x00b                                 ";
         594 : dbg_instr = "I2C_read+0x00c                                 ";
         595 : dbg_instr = "I2C_read+0x00d                                 ";
         596 : dbg_instr = "I2C_read+0x00e                                 ";
         597 : dbg_instr = "I2C_read+0x00f                                 ";
         598 : dbg_instr = "I2C_read+0x010                                 ";
         599 : dbg_instr = "I2C_read+0x011                                 ";
         600 : dbg_instr = "I2C_read+0x012                                 ";
         601 : dbg_instr = "I2C_read+0x013                                 ";
         602 : dbg_instr = "cobsFindZero                                   ";
         603 : dbg_instr = "cobsFindZero+0x001                             ";
         604 : dbg_instr = "cobsFindZero+0x002                             ";
         605 : dbg_instr = "cobsFindZero+0x003                             ";
         606 : dbg_instr = "cobsFindZero+0x004                             ";
         607 : dbg_instr = "cobsFindZero+0x005                             ";
         608 : dbg_instr = "cobsFindZero+0x006                             ";
         609 : dbg_instr = "cobsFindZero+0x007                             ";
         610 : dbg_instr = "cobsFixZero                                    ";
         611 : dbg_instr = "cobsFixZero+0x001                              ";
         612 : dbg_instr = "cobsFixZero+0x002                              ";
         613 : dbg_instr = "cobsFixZero+0x003                              ";
         614 : dbg_instr = "cobsFixZero+0x004                              ";
         615 : dbg_instr = "cobsEncode                                     ";
         616 : dbg_instr = "cobsEncode+0x001                               ";
         617 : dbg_instr = "cobsEncode+0x002                               ";
         618 : dbg_instr = "cobsEncode+0x003                               ";
         619 : dbg_instr = "cobsEncode+0x004                               ";
         620 : dbg_instr = "cobsEncode+0x005                               ";
         621 : dbg_instr = "cobsEncode+0x006                               ";
         622 : dbg_instr = "cobsEncode+0x007                               ";
         623 : dbg_instr = "cobsEncode+0x008                               ";
         624 : dbg_instr = "cobsEncode+0x009                               ";
         625 : dbg_instr = "cobsEncode+0x00a                               ";
         626 : dbg_instr = "cobsEncode+0x00b                               ";
         627 : dbg_instr = "cobsEncode+0x00c                               ";
         628 : dbg_instr = "cobsEncode+0x00d                               ";
         629 : dbg_instr = "cobsEncode+0x00e                               ";
         630 : dbg_instr = "icap_reboot                                    ";
         631 : dbg_instr = "icap_reboot+0x001                              ";
         632 : dbg_instr = "icap_reboot+0x002                              ";
         633 : dbg_instr = "icap_reboot+0x003                              ";
         634 : dbg_instr = "icap_reboot+0x004                              ";
         635 : dbg_instr = "icap_reboot+0x005                              ";
         636 : dbg_instr = "icap_reboot+0x006                              ";
         637 : dbg_instr = "icap_reboot+0x007                              ";
         638 : dbg_instr = "icap_reboot+0x008                              ";
         639 : dbg_instr = "icap_reboot+0x009                              ";
         640 : dbg_instr = "icap_reboot+0x00a                              ";
         641 : dbg_instr = "icap_reboot+0x00b                              ";
         642 : dbg_instr = "icap_reboot+0x00c                              ";
         643 : dbg_instr = "icap_reboot+0x00d                              ";
         644 : dbg_instr = "icap_reboot+0x00e                              ";
         645 : dbg_instr = "icap_reboot+0x00f                              ";
         646 : dbg_instr = "icap_reboot+0x010                              ";
         647 : dbg_instr = "icap_reboot+0x011                              ";
         648 : dbg_instr = "icap_reboot+0x012                              ";
         649 : dbg_instr = "icap_reboot+0x013                              ";
         650 : dbg_instr = "icap_reboot+0x014                              ";
         651 : dbg_instr = "icap_reboot+0x015                              ";
         652 : dbg_instr = "icap_reboot+0x016                              ";
         653 : dbg_instr = "icap_reboot+0x017                              ";
         654 : dbg_instr = "icap_reboot+0x018                              ";
         655 : dbg_instr = "icap_noop                                      ";
         656 : dbg_instr = "icap_3zero                                     ";
         657 : dbg_instr = "icap_3zero+0x001                               ";
         658 : dbg_instr = "icap_3zero+0x002                               ";
         659 : dbg_instr = "icap_3zero+0x003                               ";
         660 : dbg_instr = "icap_3zero+0x004                               ";
         661 : dbg_instr = "icap_3zero+0x005                               ";
         662 : dbg_instr = "icap_3zero+0x006                               ";
         663 : dbg_instr = "icap_3zero+0x007                               ";
         664 : dbg_instr = "icap_3zero+0x008                               ";
         665 : dbg_instr = "icap_3zero+0x009                               ";
         666 : dbg_instr = "icap_3zero+0x00a                               ";
         667 : dbg_instr = "icap_3zero+0x00b                               ";
         668 : dbg_instr = "icap_3zero+0x00c                               ";
         669 : dbg_instr = "icap_3zero+0x00d                               ";
         670 : dbg_instr = "icap_3zero+0x00e                               ";
         671 : dbg_instr = "icap_3zero+0x00f                               ";
         672 : dbg_instr = "icap_3zero+0x010                               ";
         673 : dbg_instr = "icap_3zero+0x011                               ";
         674 : dbg_instr = "icap_3zero+0x012                               ";
         675 : dbg_instr = "icap_3zero+0x013                               ";
         676 : dbg_instr = "icap_3zero+0x014                               ";
         677 : dbg_instr = "icap_3zero+0x015                               ";
         678 : dbg_instr = "icap_3zero+0x016                               ";
         679 : dbg_instr = "icap_3zero+0x017                               ";
         680 : dbg_instr = "icap_3zero+0x018                               ";
         681 : dbg_instr = "icap_3zero+0x019                               ";
         682 : dbg_instr = "icap_3zero+0x01a                               ";
         683 : dbg_instr = "icap_3zero+0x01b                               ";
         684 : dbg_instr = "icap_3zero+0x01c                               ";
         685 : dbg_instr = "icap_3zero+0x01d                               ";
         686 : dbg_instr = "icap_3zero+0x01e                               ";
         687 : dbg_instr = "icap_3zero+0x01f                               ";
         688 : dbg_instr = "icap_3zero+0x020                               ";
         689 : dbg_instr = "icap_3zero+0x021                               ";
         690 : dbg_instr = "icap_3zero+0x022                               ";
         691 : dbg_instr = "icap_3zero+0x023                               ";
         692 : dbg_instr = "icap_3zero+0x024                               ";
         693 : dbg_instr = "icap_3zero+0x025                               ";
         694 : dbg_instr = "icap_3zero+0x026                               ";
         695 : dbg_instr = "icap_3zero+0x027                               ";
         696 : dbg_instr = "icap_3zero+0x028                               ";
         697 : dbg_instr = "icap_3zero+0x029                               ";
         698 : dbg_instr = "icap_3zero+0x02a                               ";
         699 : dbg_instr = "icap_3zero+0x02b                               ";
         700 : dbg_instr = "icap_3zero+0x02c                               ";
         701 : dbg_instr = "icap_3zero+0x02d                               ";
         702 : dbg_instr = "icap_3zero+0x02e                               ";
         703 : dbg_instr = "icap_3zero+0x02f                               ";
         704 : dbg_instr = "icap_3zero+0x030                               ";
         705 : dbg_instr = "icap_3zero+0x031                               ";
         706 : dbg_instr = "icap_3zero+0x032                               ";
         707 : dbg_instr = "icap_3zero+0x033                               ";
         708 : dbg_instr = "icap_3zero+0x034                               ";
         709 : dbg_instr = "icap_3zero+0x035                               ";
         710 : dbg_instr = "icap_3zero+0x036                               ";
         711 : dbg_instr = "icap_3zero+0x037                               ";
         712 : dbg_instr = "icap_3zero+0x038                               ";
         713 : dbg_instr = "icap_3zero+0x039                               ";
         714 : dbg_instr = "icap_3zero+0x03a                               ";
         715 : dbg_instr = "icap_3zero+0x03b                               ";
         716 : dbg_instr = "icap_3zero+0x03c                               ";
         717 : dbg_instr = "icap_3zero+0x03d                               ";
         718 : dbg_instr = "icap_3zero+0x03e                               ";
         719 : dbg_instr = "icap_3zero+0x03f                               ";
         720 : dbg_instr = "icap_3zero+0x040                               ";
         721 : dbg_instr = "icap_3zero+0x041                               ";
         722 : dbg_instr = "icap_3zero+0x042                               ";
         723 : dbg_instr = "icap_3zero+0x043                               ";
         724 : dbg_instr = "icap_3zero+0x044                               ";
         725 : dbg_instr = "icap_3zero+0x045                               ";
         726 : dbg_instr = "icap_3zero+0x046                               ";
         727 : dbg_instr = "icap_3zero+0x047                               ";
         728 : dbg_instr = "icap_3zero+0x048                               ";
         729 : dbg_instr = "icap_3zero+0x049                               ";
         730 : dbg_instr = "icap_3zero+0x04a                               ";
         731 : dbg_instr = "icap_3zero+0x04b                               ";
         732 : dbg_instr = "icap_3zero+0x04c                               ";
         733 : dbg_instr = "icap_3zero+0x04d                               ";
         734 : dbg_instr = "icap_3zero+0x04e                               ";
         735 : dbg_instr = "icap_3zero+0x04f                               ";
         736 : dbg_instr = "icap_3zero+0x050                               ";
         737 : dbg_instr = "icap_3zero+0x051                               ";
         738 : dbg_instr = "icap_3zero+0x052                               ";
         739 : dbg_instr = "icap_3zero+0x053                               ";
         740 : dbg_instr = "icap_3zero+0x054                               ";
         741 : dbg_instr = "icap_3zero+0x055                               ";
         742 : dbg_instr = "icap_3zero+0x056                               ";
         743 : dbg_instr = "icap_3zero+0x057                               ";
         744 : dbg_instr = "icap_3zero+0x058                               ";
         745 : dbg_instr = "icap_3zero+0x059                               ";
         746 : dbg_instr = "icap_3zero+0x05a                               ";
         747 : dbg_instr = "icap_3zero+0x05b                               ";
         748 : dbg_instr = "icap_3zero+0x05c                               ";
         749 : dbg_instr = "icap_3zero+0x05d                               ";
         750 : dbg_instr = "icap_3zero+0x05e                               ";
         751 : dbg_instr = "icap_3zero+0x05f                               ";
         752 : dbg_instr = "icap_3zero+0x060                               ";
         753 : dbg_instr = "icap_3zero+0x061                               ";
         754 : dbg_instr = "icap_3zero+0x062                               ";
         755 : dbg_instr = "icap_3zero+0x063                               ";
         756 : dbg_instr = "icap_3zero+0x064                               ";
         757 : dbg_instr = "icap_3zero+0x065                               ";
         758 : dbg_instr = "icap_3zero+0x066                               ";
         759 : dbg_instr = "icap_3zero+0x067                               ";
         760 : dbg_instr = "icap_3zero+0x068                               ";
         761 : dbg_instr = "icap_3zero+0x069                               ";
         762 : dbg_instr = "icap_3zero+0x06a                               ";
         763 : dbg_instr = "icap_3zero+0x06b                               ";
         764 : dbg_instr = "icap_3zero+0x06c                               ";
         765 : dbg_instr = "icap_3zero+0x06d                               ";
         766 : dbg_instr = "icap_3zero+0x06e                               ";
         767 : dbg_instr = "icap_3zero+0x06f                               ";
         768 : dbg_instr = "icap_3zero+0x070                               ";
         769 : dbg_instr = "icap_3zero+0x071                               ";
         770 : dbg_instr = "icap_3zero+0x072                               ";
         771 : dbg_instr = "icap_3zero+0x073                               ";
         772 : dbg_instr = "icap_3zero+0x074                               ";
         773 : dbg_instr = "icap_3zero+0x075                               ";
         774 : dbg_instr = "icap_3zero+0x076                               ";
         775 : dbg_instr = "icap_3zero+0x077                               ";
         776 : dbg_instr = "icap_3zero+0x078                               ";
         777 : dbg_instr = "icap_3zero+0x079                               ";
         778 : dbg_instr = "icap_3zero+0x07a                               ";
         779 : dbg_instr = "icap_3zero+0x07b                               ";
         780 : dbg_instr = "icap_3zero+0x07c                               ";
         781 : dbg_instr = "icap_3zero+0x07d                               ";
         782 : dbg_instr = "icap_3zero+0x07e                               ";
         783 : dbg_instr = "icap_3zero+0x07f                               ";
         784 : dbg_instr = "icap_3zero+0x080                               ";
         785 : dbg_instr = "icap_3zero+0x081                               ";
         786 : dbg_instr = "icap_3zero+0x082                               ";
         787 : dbg_instr = "icap_3zero+0x083                               ";
         788 : dbg_instr = "icap_3zero+0x084                               ";
         789 : dbg_instr = "icap_3zero+0x085                               ";
         790 : dbg_instr = "icap_3zero+0x086                               ";
         791 : dbg_instr = "icap_3zero+0x087                               ";
         792 : dbg_instr = "icap_3zero+0x088                               ";
         793 : dbg_instr = "icap_3zero+0x089                               ";
         794 : dbg_instr = "icap_3zero+0x08a                               ";
         795 : dbg_instr = "icap_3zero+0x08b                               ";
         796 : dbg_instr = "icap_3zero+0x08c                               ";
         797 : dbg_instr = "icap_3zero+0x08d                               ";
         798 : dbg_instr = "icap_3zero+0x08e                               ";
         799 : dbg_instr = "icap_3zero+0x08f                               ";
         800 : dbg_instr = "icap_3zero+0x090                               ";
         801 : dbg_instr = "icap_3zero+0x091                               ";
         802 : dbg_instr = "icap_3zero+0x092                               ";
         803 : dbg_instr = "icap_3zero+0x093                               ";
         804 : dbg_instr = "icap_3zero+0x094                               ";
         805 : dbg_instr = "icap_3zero+0x095                               ";
         806 : dbg_instr = "icap_3zero+0x096                               ";
         807 : dbg_instr = "icap_3zero+0x097                               ";
         808 : dbg_instr = "icap_3zero+0x098                               ";
         809 : dbg_instr = "icap_3zero+0x099                               ";
         810 : dbg_instr = "icap_3zero+0x09a                               ";
         811 : dbg_instr = "icap_3zero+0x09b                               ";
         812 : dbg_instr = "icap_3zero+0x09c                               ";
         813 : dbg_instr = "icap_3zero+0x09d                               ";
         814 : dbg_instr = "icap_3zero+0x09e                               ";
         815 : dbg_instr = "icap_3zero+0x09f                               ";
         816 : dbg_instr = "icap_3zero+0x0a0                               ";
         817 : dbg_instr = "icap_3zero+0x0a1                               ";
         818 : dbg_instr = "icap_3zero+0x0a2                               ";
         819 : dbg_instr = "icap_3zero+0x0a3                               ";
         820 : dbg_instr = "icap_3zero+0x0a4                               ";
         821 : dbg_instr = "icap_3zero+0x0a5                               ";
         822 : dbg_instr = "icap_3zero+0x0a6                               ";
         823 : dbg_instr = "icap_3zero+0x0a7                               ";
         824 : dbg_instr = "icap_3zero+0x0a8                               ";
         825 : dbg_instr = "icap_3zero+0x0a9                               ";
         826 : dbg_instr = "icap_3zero+0x0aa                               ";
         827 : dbg_instr = "icap_3zero+0x0ab                               ";
         828 : dbg_instr = "icap_3zero+0x0ac                               ";
         829 : dbg_instr = "icap_3zero+0x0ad                               ";
         830 : dbg_instr = "icap_3zero+0x0ae                               ";
         831 : dbg_instr = "icap_3zero+0x0af                               ";
         832 : dbg_instr = "icap_3zero+0x0b0                               ";
         833 : dbg_instr = "icap_3zero+0x0b1                               ";
         834 : dbg_instr = "icap_3zero+0x0b2                               ";
         835 : dbg_instr = "icap_3zero+0x0b3                               ";
         836 : dbg_instr = "icap_3zero+0x0b4                               ";
         837 : dbg_instr = "icap_3zero+0x0b5                               ";
         838 : dbg_instr = "icap_3zero+0x0b6                               ";
         839 : dbg_instr = "icap_3zero+0x0b7                               ";
         840 : dbg_instr = "icap_3zero+0x0b8                               ";
         841 : dbg_instr = "icap_3zero+0x0b9                               ";
         842 : dbg_instr = "icap_3zero+0x0ba                               ";
         843 : dbg_instr = "icap_3zero+0x0bb                               ";
         844 : dbg_instr = "icap_3zero+0x0bc                               ";
         845 : dbg_instr = "icap_3zero+0x0bd                               ";
         846 : dbg_instr = "icap_3zero+0x0be                               ";
         847 : dbg_instr = "icap_3zero+0x0bf                               ";
         848 : dbg_instr = "icap_3zero+0x0c0                               ";
         849 : dbg_instr = "icap_3zero+0x0c1                               ";
         850 : dbg_instr = "icap_3zero+0x0c2                               ";
         851 : dbg_instr = "icap_3zero+0x0c3                               ";
         852 : dbg_instr = "icap_3zero+0x0c4                               ";
         853 : dbg_instr = "icap_3zero+0x0c5                               ";
         854 : dbg_instr = "icap_3zero+0x0c6                               ";
         855 : dbg_instr = "icap_3zero+0x0c7                               ";
         856 : dbg_instr = "icap_3zero+0x0c8                               ";
         857 : dbg_instr = "icap_3zero+0x0c9                               ";
         858 : dbg_instr = "icap_3zero+0x0ca                               ";
         859 : dbg_instr = "icap_3zero+0x0cb                               ";
         860 : dbg_instr = "icap_3zero+0x0cc                               ";
         861 : dbg_instr = "icap_3zero+0x0cd                               ";
         862 : dbg_instr = "icap_3zero+0x0ce                               ";
         863 : dbg_instr = "icap_3zero+0x0cf                               ";
         864 : dbg_instr = "icap_3zero+0x0d0                               ";
         865 : dbg_instr = "icap_3zero+0x0d1                               ";
         866 : dbg_instr = "icap_3zero+0x0d2                               ";
         867 : dbg_instr = "icap_3zero+0x0d3                               ";
         868 : dbg_instr = "icap_3zero+0x0d4                               ";
         869 : dbg_instr = "icap_3zero+0x0d5                               ";
         870 : dbg_instr = "icap_3zero+0x0d6                               ";
         871 : dbg_instr = "icap_3zero+0x0d7                               ";
         872 : dbg_instr = "icap_3zero+0x0d8                               ";
         873 : dbg_instr = "icap_3zero+0x0d9                               ";
         874 : dbg_instr = "icap_3zero+0x0da                               ";
         875 : dbg_instr = "icap_3zero+0x0db                               ";
         876 : dbg_instr = "icap_3zero+0x0dc                               ";
         877 : dbg_instr = "icap_3zero+0x0dd                               ";
         878 : dbg_instr = "icap_3zero+0x0de                               ";
         879 : dbg_instr = "icap_3zero+0x0df                               ";
         880 : dbg_instr = "icap_3zero+0x0e0                               ";
         881 : dbg_instr = "icap_3zero+0x0e1                               ";
         882 : dbg_instr = "icap_3zero+0x0e2                               ";
         883 : dbg_instr = "icap_3zero+0x0e3                               ";
         884 : dbg_instr = "icap_3zero+0x0e4                               ";
         885 : dbg_instr = "icap_3zero+0x0e5                               ";
         886 : dbg_instr = "icap_3zero+0x0e6                               ";
         887 : dbg_instr = "icap_3zero+0x0e7                               ";
         888 : dbg_instr = "icap_3zero+0x0e8                               ";
         889 : dbg_instr = "icap_3zero+0x0e9                               ";
         890 : dbg_instr = "icap_3zero+0x0ea                               ";
         891 : dbg_instr = "icap_3zero+0x0eb                               ";
         892 : dbg_instr = "icap_3zero+0x0ec                               ";
         893 : dbg_instr = "icap_3zero+0x0ed                               ";
         894 : dbg_instr = "icap_3zero+0x0ee                               ";
         895 : dbg_instr = "icap_3zero+0x0ef                               ";
         896 : dbg_instr = "icap_3zero+0x0f0                               ";
         897 : dbg_instr = "icap_3zero+0x0f1                               ";
         898 : dbg_instr = "icap_3zero+0x0f2                               ";
         899 : dbg_instr = "icap_3zero+0x0f3                               ";
         900 : dbg_instr = "icap_3zero+0x0f4                               ";
         901 : dbg_instr = "icap_3zero+0x0f5                               ";
         902 : dbg_instr = "icap_3zero+0x0f6                               ";
         903 : dbg_instr = "icap_3zero+0x0f7                               ";
         904 : dbg_instr = "icap_3zero+0x0f8                               ";
         905 : dbg_instr = "icap_3zero+0x0f9                               ";
         906 : dbg_instr = "icap_3zero+0x0fa                               ";
         907 : dbg_instr = "icap_3zero+0x0fb                               ";
         908 : dbg_instr = "icap_3zero+0x0fc                               ";
         909 : dbg_instr = "icap_3zero+0x0fd                               ";
         910 : dbg_instr = "icap_3zero+0x0fe                               ";
         911 : dbg_instr = "icap_3zero+0x0ff                               ";
         912 : dbg_instr = "icap_3zero+0x100                               ";
         913 : dbg_instr = "icap_3zero+0x101                               ";
         914 : dbg_instr = "icap_3zero+0x102                               ";
         915 : dbg_instr = "icap_3zero+0x103                               ";
         916 : dbg_instr = "icap_3zero+0x104                               ";
         917 : dbg_instr = "icap_3zero+0x105                               ";
         918 : dbg_instr = "icap_3zero+0x106                               ";
         919 : dbg_instr = "icap_3zero+0x107                               ";
         920 : dbg_instr = "icap_3zero+0x108                               ";
         921 : dbg_instr = "icap_3zero+0x109                               ";
         922 : dbg_instr = "icap_3zero+0x10a                               ";
         923 : dbg_instr = "icap_3zero+0x10b                               ";
         924 : dbg_instr = "icap_3zero+0x10c                               ";
         925 : dbg_instr = "icap_3zero+0x10d                               ";
         926 : dbg_instr = "icap_3zero+0x10e                               ";
         927 : dbg_instr = "icap_3zero+0x10f                               ";
         928 : dbg_instr = "icap_3zero+0x110                               ";
         929 : dbg_instr = "icap_3zero+0x111                               ";
         930 : dbg_instr = "icap_3zero+0x112                               ";
         931 : dbg_instr = "icap_3zero+0x113                               ";
         932 : dbg_instr = "icap_3zero+0x114                               ";
         933 : dbg_instr = "icap_3zero+0x115                               ";
         934 : dbg_instr = "icap_3zero+0x116                               ";
         935 : dbg_instr = "icap_3zero+0x117                               ";
         936 : dbg_instr = "icap_3zero+0x118                               ";
         937 : dbg_instr = "icap_3zero+0x119                               ";
         938 : dbg_instr = "icap_3zero+0x11a                               ";
         939 : dbg_instr = "icap_3zero+0x11b                               ";
         940 : dbg_instr = "icap_3zero+0x11c                               ";
         941 : dbg_instr = "icap_3zero+0x11d                               ";
         942 : dbg_instr = "icap_3zero+0x11e                               ";
         943 : dbg_instr = "icap_3zero+0x11f                               ";
         944 : dbg_instr = "icap_3zero+0x120                               ";
         945 : dbg_instr = "icap_3zero+0x121                               ";
         946 : dbg_instr = "icap_3zero+0x122                               ";
         947 : dbg_instr = "icap_3zero+0x123                               ";
         948 : dbg_instr = "icap_3zero+0x124                               ";
         949 : dbg_instr = "icap_3zero+0x125                               ";
         950 : dbg_instr = "icap_3zero+0x126                               ";
         951 : dbg_instr = "icap_3zero+0x127                               ";
         952 : dbg_instr = "icap_3zero+0x128                               ";
         953 : dbg_instr = "icap_3zero+0x129                               ";
         954 : dbg_instr = "icap_3zero+0x12a                               ";
         955 : dbg_instr = "icap_3zero+0x12b                               ";
         956 : dbg_instr = "icap_3zero+0x12c                               ";
         957 : dbg_instr = "icap_3zero+0x12d                               ";
         958 : dbg_instr = "icap_3zero+0x12e                               ";
         959 : dbg_instr = "icap_3zero+0x12f                               ";
         960 : dbg_instr = "icap_3zero+0x130                               ";
         961 : dbg_instr = "icap_3zero+0x131                               ";
         962 : dbg_instr = "icap_3zero+0x132                               ";
         963 : dbg_instr = "icap_3zero+0x133                               ";
         964 : dbg_instr = "icap_3zero+0x134                               ";
         965 : dbg_instr = "icap_3zero+0x135                               ";
         966 : dbg_instr = "icap_3zero+0x136                               ";
         967 : dbg_instr = "icap_3zero+0x137                               ";
         968 : dbg_instr = "icap_3zero+0x138                               ";
         969 : dbg_instr = "icap_3zero+0x139                               ";
         970 : dbg_instr = "icap_3zero+0x13a                               ";
         971 : dbg_instr = "icap_3zero+0x13b                               ";
         972 : dbg_instr = "icap_3zero+0x13c                               ";
         973 : dbg_instr = "icap_3zero+0x13d                               ";
         974 : dbg_instr = "icap_3zero+0x13e                               ";
         975 : dbg_instr = "icap_3zero+0x13f                               ";
         976 : dbg_instr = "icap_3zero+0x140                               ";
         977 : dbg_instr = "icap_3zero+0x141                               ";
         978 : dbg_instr = "icap_3zero+0x142                               ";
         979 : dbg_instr = "icap_3zero+0x143                               ";
         980 : dbg_instr = "icap_3zero+0x144                               ";
         981 : dbg_instr = "icap_3zero+0x145                               ";
         982 : dbg_instr = "icap_3zero+0x146                               ";
         983 : dbg_instr = "icap_3zero+0x147                               ";
         984 : dbg_instr = "icap_3zero+0x148                               ";
         985 : dbg_instr = "icap_3zero+0x149                               ";
         986 : dbg_instr = "icap_3zero+0x14a                               ";
         987 : dbg_instr = "icap_3zero+0x14b                               ";
         988 : dbg_instr = "icap_3zero+0x14c                               ";
         989 : dbg_instr = "icap_3zero+0x14d                               ";
         990 : dbg_instr = "icap_3zero+0x14e                               ";
         991 : dbg_instr = "icap_3zero+0x14f                               ";
         992 : dbg_instr = "icap_3zero+0x150                               ";
         993 : dbg_instr = "icap_3zero+0x151                               ";
         994 : dbg_instr = "icap_3zero+0x152                               ";
         995 : dbg_instr = "icap_3zero+0x153                               ";
         996 : dbg_instr = "icap_3zero+0x154                               ";
         997 : dbg_instr = "icap_3zero+0x155                               ";
         998 : dbg_instr = "icap_3zero+0x156                               ";
         999 : dbg_instr = "icap_3zero+0x157                               ";
         1000 : dbg_instr = "icap_3zero+0x158                               ";
         1001 : dbg_instr = "icap_3zero+0x159                               ";
         1002 : dbg_instr = "icap_3zero+0x15a                               ";
         1003 : dbg_instr = "icap_3zero+0x15b                               ";
         1004 : dbg_instr = "icap_3zero+0x15c                               ";
         1005 : dbg_instr = "icap_3zero+0x15d                               ";
         1006 : dbg_instr = "icap_3zero+0x15e                               ";
         1007 : dbg_instr = "icap_3zero+0x15f                               ";
         1008 : dbg_instr = "icap_3zero+0x160                               ";
         1009 : dbg_instr = "icap_3zero+0x161                               ";
         1010 : dbg_instr = "icap_3zero+0x162                               ";
         1011 : dbg_instr = "icap_3zero+0x163                               ";
         1012 : dbg_instr = "icap_3zero+0x164                               ";
         1013 : dbg_instr = "icap_3zero+0x165                               ";
         1014 : dbg_instr = "icap_3zero+0x166                               ";
         1015 : dbg_instr = "icap_3zero+0x167                               ";
         1016 : dbg_instr = "icap_3zero+0x168                               ";
         1017 : dbg_instr = "icap_3zero+0x169                               ";
         1018 : dbg_instr = "icap_3zero+0x16a                               ";
         1019 : dbg_instr = "icap_3zero+0x16b                               ";
         1020 : dbg_instr = "icap_3zero+0x16c                               ";
         1021 : dbg_instr = "icap_3zero+0x16d                               ";
         1022 : dbg_instr = "icap_3zero+0x16e                               ";
         1023 : dbg_instr = "icap_3zero+0x16f                               ";
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
    .INIT_00(256'h1600150014002012D280920B900A70016EE02004005B010D000000002004002D),
    .INIT_01(256'hCED0DD0B7D036EE04ED011802027D202C0109001700011002017D20102761700),
    .INIT_02(256'h01FFB03FB80B90019001700031FFD1C01101202C90017000202C900070002024),
    .INIT_03(256'hAA102041D00111380232F000307F70FFE0334008021FAA10110110801137B008),
    .INIT_04(256'h7001F210F212F214F2131200F216F2171200D21132FE9211603D400E11010237),
    .INIT_05(256'h2081D202207DD201B210500080019F10110010011E0070001D011E001180B01B),
    .INIT_06(256'h43801280D000F314F213B3009201B314B21360C9D700B71720A9D204208ED203),
    .INIT_07(256'hC230B300B2125000F311F21013001201207A130412046078D200B212F314F213),
    .INIT_08(256'hF22101085000F2101203B02D022314210206F2210108F220A2201234B21120F6),
    .INIT_09(256'h1601C560B520B42106304306430643060103B21206704706B71116C002461621),
    .INIT_0A(256'h02461622F421149060C3D204B2115000F2101202F71120F6D7041701B711C460),
    .INIT_0B(256'hD6FBD5FAD4F9D7F8E0B94608450E5608E0B44700440046061710B620B521B422),
    .INIT_0C(256'h1218171F60E1D80060CED701B81620F6D2FC320F920FD2FD920E5000F2111205),
    .INIT_0D(256'hD800F4151401F418B31834E102230206141FB41760D0D71F97011201E370A320),
    .INIT_0E(256'h180160E9D91F12019901E320A3901219F61836E102460960161F0680F32120F1),
    .INIT_0F(256'h92115000F3101300F212420E128060FAD200B2125000F216F217120001FFF815),

    // Address 256 to 511
    .INIT_10(256'h01151000C0E05000A23013380103B2125000E104420E130113FF5000D2117201),
    .INIT_11(256'h05608610118401401500E1DCD43C948361DAC2F0928150008001D00B70036E00),
    .INIT_12(256'h2178D215216AD21321C7D212215CD211214ED210928261DED500611ED1839101),
    .INIT_13(256'hD984B908B05301E021D201E061DCD2002180D2CA2199D2C92186D2C8213CD20F),
    .INIT_14(256'hB10301E021CF11890920D288B20C0920D287B20B0920D286B20A0920D285B209),
    .INIT_15(256'hD98499F8B1E301E021CF6157D5FE150601E515C611860920D28592FDD98499FC),
    .INIT_16(256'hD28592FBD98499FAB10301E021CF6165D5F8150401E415C011860920D28592F9),
    .INIT_17(256'h21D2B013D385D28483201300920F01E021CF6173D5FC150601E515C411860920),
    .INIT_18(256'h232072FF24209485931192842192D200928301E0500002769787968695859484),
    .INIT_19(256'hD300B31721B5D200B013928301E021D2B013D385D284832013009211D3114340),
    .INIT_1A(256'h920115011401E340835015851418F2179201F7169784F31521D2B005B00421A4),
    .INIT_1B(256'hA340190011841418D28321D2B004B00361BBD200B21521D2D285D484824061AB),
    .INIT_1C(256'h79FF1186D2850920B200D9841908B02301E021CF61BF920111011401C3100930),
    .INIT_1D(256'h21D6130A21D6130B21D6130C5000E2301201A230130901D613080267C9101901),
    .INIT_1E(256'h500001F001F001F05000110115010920C210825001E601E55000DF80D2819280),
    .INIT_1F(256'hB00E5000B00DD201920C01EC01F0B02D01ECB01E50004308E1F2420012044300),

    // Address 512 to 767
    .INIT_20(256'h4B004A021B015000B00D01F0B00E01EDB02DB01E500001F0B01E01EDB02D01F0),
    .INIT_21(256'h02065000E21B4A0001F61A01500001EC01F6E20EB00D01EC01F0B02D01ECDB0E),
    .INIT_22(256'h02230206F620F5211423F42250006223D41F94019000020DAA40500001FF020D),
    .INIT_23(256'h022A1601158D14D8022A1607151E14D4FA23222D16051421F4211490500001FF),
    .INIT_24(256'hD20E4200D621EA60021A9000020D5A01BA210206022314210206F520F4215000),
    .INIT_25(256'h1000D20082701000C7600750500001FF01EC624BD61F9601B00D01ECB02D01EC),
    .INIT_26(256'hD20015018250D708977F025A1685968315805000027017018750025A225B1701),
    .INIT_27(256'hB660B550B990BAA0BFF0BFF0BFF0BFF0D21112105000B008A26DC560D2080262),
    .INIT_28(256'hB200B0F00290B010B800B000B300D700D600D500D400B010B000B020B300028F),
    .INIT_29(256'h1000100010001000100010001000100010001000100010005000B000B000B000),
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
    .INITP_00(256'h02A0834A4E9434DDDD280302EA8A20D630A0D842AAB56BAF210CACC803036A0A),
    .INITP_01(256'h38934A8A7560984B621A4D581DD28228AAD4D50088D28B5260558508AA28AA13),

    // Address 256 to 511
    .INITP_02(256'hAA42B58188AB58188AB58188A86186188AADDDDDDDDDD3754434D2A0B218B528),
    .INITP_03(256'hA82AA9D1AA958AA8888A42290922AD5900AAD2A7560262AB4D8AA908000D2A00),

    // Address 512 to 767
    .INITP_04(256'hAAAA8ADB52642169D34AB5AA96B828AA8080A08AAA2B5E2AAD8ABAAA52AAAAAA),
    .INITP_05(256'h000000000000000000000000000000000000000000000000000000AAAAAAAAAA),

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
