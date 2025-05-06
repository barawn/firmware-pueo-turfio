/*
 * == pblaze-cc ==
 * source : pb_turfio.c
 * create : Tue May  6 14:41:57 2025
 * modify : Tue May  6 14:41:57 2025
 */
`timescale 1 ps / 1ps

/* 
 * == pblaze-as ==
 * source : pb_turfio.s
 * create : Tue May  6 15:43:41 2025
 * modify : Tue May  6 15:43:41 2025
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
         200 : dbg_instr = "PMBUS                                          ";
         201 : dbg_instr = "PMBUS+0x001                                    ";
         202 : dbg_instr = "PMBUS+0x002                                    ";
         203 : dbg_instr = "PMBUS+0x003                                    ";
         204 : dbg_instr = "PMBUS+0x004                                    ";
         205 : dbg_instr = "WRITE_PMBUS                                    ";
         206 : dbg_instr = "WRITE_PMBUS+0x001                              ";
         207 : dbg_instr = "WRITE_PMBUS+0x002                              ";
         208 : dbg_instr = "WRITE_PMBUS+0x003                              ";
         209 : dbg_instr = "WRITE_PMBUS+0x004                              ";
         210 : dbg_instr = "WRITE_PMBUS+0x005                              ";
         211 : dbg_instr = "WRITE_PMBUS+0x006                              ";
         212 : dbg_instr = "WRITE_PMBUS+0x007                              ";
         213 : dbg_instr = "WRITE_PMBUS+0x008                              ";
         214 : dbg_instr = "WRITE_PMBUS+0x009                              ";
         215 : dbg_instr = "WRITE_PMBUS+0x00a                              ";
         216 : dbg_instr = "WRITE_PMBUS+0x00b                              ";
         217 : dbg_instr = "WRITE_PMBUS+0x00c                              ";
         218 : dbg_instr = "WRITE_PMBUS+0x00d                              ";
         219 : dbg_instr = "WRITE_PMBUS+0x00e                              ";
         220 : dbg_instr = "WRITE_PMBUS+0x00f                              ";
         221 : dbg_instr = "WRITE_PMBUS+0x010                              ";
         222 : dbg_instr = "WRITE_PMBUS+0x011                              ";
         223 : dbg_instr = "WRITE_PMBUS+0x012                              ";
         224 : dbg_instr = "READ_PMBUS                                     ";
         225 : dbg_instr = "READ_PMBUS+0x001                               ";
         226 : dbg_instr = "READ_PMBUS+0x002                               ";
         227 : dbg_instr = "READ_PMBUS+0x003                               ";
         228 : dbg_instr = "READ_PMBUS+0x004                               ";
         229 : dbg_instr = "READ_PMBUS+0x005                               ";
         230 : dbg_instr = "READ_PMBUS+0x006                               ";
         231 : dbg_instr = "READ_PMBUS+0x007                               ";
         232 : dbg_instr = "READ_PMBUS+0x008                               ";
         233 : dbg_instr = "READ_PMBUS+0x009                               ";
         234 : dbg_instr = "READ_PMBUS+0x00a                               ";
         235 : dbg_instr = "READ_PMBUS+0x00b                               ";
         236 : dbg_instr = "READ_PMBUS+0x00c                               ";
         237 : dbg_instr = "READ_PMBUS+0x00d                               ";
         238 : dbg_instr = "READ_PMBUS+0x00e                               ";
         239 : dbg_instr = "READ_PMBUS+0x00f                               ";
         240 : dbg_instr = "FINISH_PMBUS                                   ";
         241 : dbg_instr = "FINISH_PMBUS+0x001                             ";
         242 : dbg_instr = "FINISH_PMBUS+0x002                             ";
         243 : dbg_instr = "FINISH_PMBUS+0x003                             ";
         244 : dbg_instr = "FINISH_PMBUS+0x004                             ";
         245 : dbg_instr = "hskNextDevice                                  ";
         246 : dbg_instr = "hskNextDevice+0x001                            ";
         247 : dbg_instr = "hskNextDevice+0x002                            ";
         248 : dbg_instr = "hskNextDevice+0x003                            ";
         249 : dbg_instr = "hskNextDevice+0x004                            ";
         250 : dbg_instr = "hskNextDevice+0x005                            ";
         251 : dbg_instr = "hskNextDevice+0x006                            ";
         252 : dbg_instr = "hskNextDevice+0x007                            ";
         253 : dbg_instr = "hskNextDevice+0x008                            ";
         254 : dbg_instr = "hskNextDevice+0x009                            ";
         255 : dbg_instr = "hskNextDevice+0x00a                            ";
         256 : dbg_instr = "hskNextDevice+0x00b                            ";
         257 : dbg_instr = "hskNextDevice+0x00c                            ";
         258 : dbg_instr = "hskCountDevice                                 ";
         259 : dbg_instr = "hskCountDevice+0x001                           ";
         260 : dbg_instr = "hskCountDevice+0x002                           ";
         261 : dbg_instr = "hskCountDevice+0x003                           ";
         262 : dbg_instr = "hskCountDevice+0x004                           ";
         263 : dbg_instr = "hskGetDeviceAddress                            ";
         264 : dbg_instr = "hskGetDeviceAddress+0x001                      ";
         265 : dbg_instr = "hskGetDeviceAddress+0x002                      ";
         266 : dbg_instr = "hskGetDeviceAddress+0x003                      ";
         267 : dbg_instr = "hskGetDeviceAddress+0x004                      ";
         268 : dbg_instr = "handle_serial                                  ";
         269 : dbg_instr = "handle_serial+0x001                            ";
         270 : dbg_instr = "handle_serial+0x002                            ";
         271 : dbg_instr = "handle_serial+0x003                            ";
         272 : dbg_instr = "handle_serial+0x004                            ";
         273 : dbg_instr = "handle_serial+0x005                            ";
         274 : dbg_instr = "handle_serial+0x006                            ";
         275 : dbg_instr = "handle_serial+0x007                            ";
         276 : dbg_instr = "parse_serial                                   ";
         277 : dbg_instr = "parse_serial+0x001                             ";
         278 : dbg_instr = "parse_serial+0x002                             ";
         279 : dbg_instr = "parse_serial+0x003                             ";
         280 : dbg_instr = "parse_serial+0x004                             ";
         281 : dbg_instr = "parse_serial+0x005                             ";
         282 : dbg_instr = "parse_serial+0x006                             ";
         283 : dbg_instr = "parse_serial+0x007                             ";
         284 : dbg_instr = "parse_serial+0x008                             ";
         285 : dbg_instr = "parse_serial+0x009                             ";
         286 : dbg_instr = "parse_serial+0x00a                             ";
         287 : dbg_instr = "parse_serial+0x00b                             ";
         288 : dbg_instr = "parse_serial+0x00c                             ";
         289 : dbg_instr = "parse_serial+0x00d                             ";
         290 : dbg_instr = "parse_serial+0x00e                             ";
         291 : dbg_instr = "parse_serial+0x00f                             ";
         292 : dbg_instr = "parse_serial+0x010                             ";
         293 : dbg_instr = "parse_serial+0x011                             ";
         294 : dbg_instr = "parse_serial+0x012                             ";
         295 : dbg_instr = "parse_serial+0x013                             ";
         296 : dbg_instr = "parse_serial+0x014                             ";
         297 : dbg_instr = "parse_serial+0x015                             ";
         298 : dbg_instr = "parse_serial+0x016                             ";
         299 : dbg_instr = "parse_serial+0x017                             ";
         300 : dbg_instr = "parse_serial+0x018                             ";
         301 : dbg_instr = "parse_serial+0x019                             ";
         302 : dbg_instr = "parse_serial+0x01a                             ";
         303 : dbg_instr = "parse_serial+0x01b                             ";
         304 : dbg_instr = "parse_serial+0x01c                             ";
         305 : dbg_instr = "parse_serial+0x01d                             ";
         306 : dbg_instr = "parse_serial+0x01e                             ";
         307 : dbg_instr = "parse_serial+0x01f                             ";
         308 : dbg_instr = "parse_serial+0x020                             ";
         309 : dbg_instr = "parse_serial+0x021                             ";
         310 : dbg_instr = "parse_serial+0x022                             ";
         311 : dbg_instr = "do_PingPong                                    ";
         312 : dbg_instr = "do_PingPong+0x001                              ";
         313 : dbg_instr = "do_Statistics                                  ";
         314 : dbg_instr = "do_Statistics+0x001                            ";
         315 : dbg_instr = "do_Statistics+0x002                            ";
         316 : dbg_instr = "do_Statistics+0x003                            ";
         317 : dbg_instr = "do_Statistics+0x004                            ";
         318 : dbg_instr = "do_Statistics+0x005                            ";
         319 : dbg_instr = "do_Statistics+0x006                            ";
         320 : dbg_instr = "do_Statistics+0x007                            ";
         321 : dbg_instr = "do_Statistics+0x008                            ";
         322 : dbg_instr = "do_Statistics+0x009                            ";
         323 : dbg_instr = "do_Statistics+0x00a                            ";
         324 : dbg_instr = "do_Statistics+0x00b                            ";
         325 : dbg_instr = "do_Statistics+0x00c                            ";
         326 : dbg_instr = "do_Statistics+0x00d                            ";
         327 : dbg_instr = "do_Statistics+0x00e                            ";
         328 : dbg_instr = "do_Statistics+0x00f                            ";
         329 : dbg_instr = "do_Statistics+0x010                            ";
         330 : dbg_instr = "do_Statistics+0x011                            ";
         331 : dbg_instr = "do_Temps                                       ";
         332 : dbg_instr = "do_Temps+0x001                                 ";
         333 : dbg_instr = "do_Temps+0x002                                 ";
         334 : dbg_instr = "do_Temps+0x003                                 ";
         335 : dbg_instr = "do_Temps+0x004                                 ";
         336 : dbg_instr = "do_Temps+0x005                                 ";
         337 : dbg_instr = "do_Temps+0x006                                 ";
         338 : dbg_instr = "do_Temps+0x007                                 ";
         339 : dbg_instr = "do_Temps+0x008                                 ";
         340 : dbg_instr = "do_Temps+0x009                                 ";
         341 : dbg_instr = "do_Temps+0x00a                                 ";
         342 : dbg_instr = "do_Temps+0x00b                                 ";
         343 : dbg_instr = "do_Temps+0x00c                                 ";
         344 : dbg_instr = "do_Temps+0x00d                                 ";
         345 : dbg_instr = "do_Volts                                       ";
         346 : dbg_instr = "do_Volts+0x001                                 ";
         347 : dbg_instr = "do_Volts+0x002                                 ";
         348 : dbg_instr = "do_Volts+0x003                                 ";
         349 : dbg_instr = "do_Volts+0x004                                 ";
         350 : dbg_instr = "do_Volts+0x005                                 ";
         351 : dbg_instr = "do_Volts+0x006                                 ";
         352 : dbg_instr = "do_Volts+0x007                                 ";
         353 : dbg_instr = "do_Volts+0x008                                 ";
         354 : dbg_instr = "do_Volts+0x009                                 ";
         355 : dbg_instr = "do_Volts+0x00a                                 ";
         356 : dbg_instr = "do_Volts+0x00b                                 ";
         357 : dbg_instr = "do_Volts+0x00c                                 ";
         358 : dbg_instr = "do_Volts+0x00d                                 ";
         359 : dbg_instr = "do_Currents                                    ";
         360 : dbg_instr = "do_Currents+0x001                              ";
         361 : dbg_instr = "do_Currents+0x002                              ";
         362 : dbg_instr = "do_Currents+0x003                              ";
         363 : dbg_instr = "do_Currents+0x004                              ";
         364 : dbg_instr = "do_Currents+0x005                              ";
         365 : dbg_instr = "do_Currents+0x006                              ";
         366 : dbg_instr = "do_Currents+0x007                              ";
         367 : dbg_instr = "do_Currents+0x008                              ";
         368 : dbg_instr = "do_Currents+0x009                              ";
         369 : dbg_instr = "do_Currents+0x00a                              ";
         370 : dbg_instr = "do_Currents+0x00b                              ";
         371 : dbg_instr = "do_Currents+0x00c                              ";
         372 : dbg_instr = "do_Currents+0x00d                              ";
         373 : dbg_instr = "do_ReloadFirmware                              ";
         374 : dbg_instr = "do_ReloadFirmware+0x001                        ";
         375 : dbg_instr = "do_ReloadFirmware+0x002                        ";
         376 : dbg_instr = "do_ReloadFirmware+0x003                        ";
         377 : dbg_instr = "do_ReloadFirmware+0x004                        ";
         378 : dbg_instr = "do_ReloadFirmware+0x005                        ";
         379 : dbg_instr = "do_Enable                                      ";
         380 : dbg_instr = "do_Enable+0x001                                ";
         381 : dbg_instr = "do_Enable+0x002                                ";
         382 : dbg_instr = "do_Enable+0x003                                ";
         383 : dbg_instr = "do_Enable+0x004                                ";
         384 : dbg_instr = "do_Enable+0x005                                ";
         385 : dbg_instr = "do_Enable+0x006                                ";
         386 : dbg_instr = "do_Enable+0x007                                ";
         387 : dbg_instr = "do_Enable+0x008                                ";
         388 : dbg_instr = "do_Enable+0x009                                ";
         389 : dbg_instr = "do_Enable+0x00a                                ";
         390 : dbg_instr = "do_Enable+0x00b                                ";
         391 : dbg_instr = "do_Enable+0x00c                                ";
         392 : dbg_instr = "do_Enable+0x00d                                ";
         393 : dbg_instr = "do_Enable+0x00e                                ";
         394 : dbg_instr = "do_Enable+0x00f                                ";
         395 : dbg_instr = "do_Enable+0x010                                ";
         396 : dbg_instr = "do_Enable+0x011                                ";
         397 : dbg_instr = "do_Enable+0x012                                ";
         398 : dbg_instr = "do_PMBus                                       ";
         399 : dbg_instr = "do_PMBus+0x001                                 ";
         400 : dbg_instr = "do_PMBus+0x002                                 ";
         401 : dbg_instr = "do_PMBus+0x003                                 ";
         402 : dbg_instr = "do_PMBus+0x004                                 ";
         403 : dbg_instr = "do_PMBus+0x005                                 ";
         404 : dbg_instr = "do_PMBus+0x006                                 ";
         405 : dbg_instr = "do_PMBus+0x007                                 ";
         406 : dbg_instr = "do_PMBus+0x008                                 ";
         407 : dbg_instr = "do_PMBus+0x009                                 ";
         408 : dbg_instr = "do_PMBus+0x00a                                 ";
         409 : dbg_instr = "PMBus_Write                                    ";
         410 : dbg_instr = "PMBus_Write+0x001                              ";
         411 : dbg_instr = "PMBus_Write+0x002                              ";
         412 : dbg_instr = "PMBus_Write+0x003                              ";
         413 : dbg_instr = "PMBus_Write+0x004                              ";
         414 : dbg_instr = "PMBus_Write+0x005                              ";
         415 : dbg_instr = "PMBus_Write+0x006                              ";
         416 : dbg_instr = "PMBus_Write+0x007                              ";
         417 : dbg_instr = "PMBus_Write+0x008                              ";
         418 : dbg_instr = "PMBus_Write+0x009                              ";
         419 : dbg_instr = "PMBus_Write+0x00a                              ";
         420 : dbg_instr = "PMBus_Write+0x00b                              ";
         421 : dbg_instr = "PMBus_Write+0x00c                              ";
         422 : dbg_instr = "PMBus_Write+0x00d                              ";
         423 : dbg_instr = "PMBus_Write+0x00e                              ";
         424 : dbg_instr = "PMBus_Write+0x00f                              ";
         425 : dbg_instr = "PMBus_Write+0x010                              ";
         426 : dbg_instr = "PMBus_Read                                     ";
         427 : dbg_instr = "PMBus_Read+0x001                               ";
         428 : dbg_instr = "PMBus_Read+0x002                               ";
         429 : dbg_instr = "PMBus_Read+0x003                               ";
         430 : dbg_instr = "PMBus_Read+0x004                               ";
         431 : dbg_instr = "PMBus_Read+0x005                               ";
         432 : dbg_instr = "PMBus_Read+0x006                               ";
         433 : dbg_instr = "PMBus_Read+0x007                               ";
         434 : dbg_instr = "PMBus_Read+0x008                               ";
         435 : dbg_instr = "PMBus_Read+0x009                               ";
         436 : dbg_instr = "PMBus_Read+0x00a                               ";
         437 : dbg_instr = "PMBus_Read+0x00b                               ";
         438 : dbg_instr = "PMBus_Read+0x00c                               ";
         439 : dbg_instr = "PMBus_Read+0x00d                               ";
         440 : dbg_instr = "PMBus_Read+0x00e                               ";
         441 : dbg_instr = "PMBus_Read+0x00f                               ";
         442 : dbg_instr = "PMBus_Read+0x010                               ";
         443 : dbg_instr = "PMBus_Read+0x011                               ";
         444 : dbg_instr = "do_Identify                                    ";
         445 : dbg_instr = "do_Identify+0x001                              ";
         446 : dbg_instr = "do_Identify+0x002                              ";
         447 : dbg_instr = "do_Identify+0x003                              ";
         448 : dbg_instr = "do_Identify+0x004                              ";
         449 : dbg_instr = "do_Identify+0x005                              ";
         450 : dbg_instr = "do_Identify+0x006                              ";
         451 : dbg_instr = "do_Identify+0x007                              ";
         452 : dbg_instr = "finishPacket                                   ";
         453 : dbg_instr = "finishPacket+0x001                             ";
         454 : dbg_instr = "finishPacket+0x002                             ";
         455 : dbg_instr = "goodPacket                                     ";
         456 : dbg_instr = "goodPacket+0x001                               ";
         457 : dbg_instr = "goodPacket+0x002                               ";
         458 : dbg_instr = "goodPacket+0x003                               ";
         459 : dbg_instr = "fetchAndIncrement                              ";
         460 : dbg_instr = "fetchAndIncrement+0x001                        ";
         461 : dbg_instr = "fetchAndIncrement+0x002                        ";
         462 : dbg_instr = "fetchAndIncrement+0x003                        ";
         463 : dbg_instr = "skippedPacket                                  ";
         464 : dbg_instr = "skippedPacket+0x001                            ";
         465 : dbg_instr = "droppedPacket                                  ";
         466 : dbg_instr = "droppedPacket+0x001                            ";
         467 : dbg_instr = "errorPacket                                    ";
         468 : dbg_instr = "errorPacket+0x001                              ";
         469 : dbg_instr = "hsk_header                                     ";
         470 : dbg_instr = "hsk_header+0x001                               ";
         471 : dbg_instr = "hsk_header+0x002                               ";
         472 : dbg_instr = "hsk_header+0x003                               ";
         473 : dbg_instr = "hsk_copy4                                      ";
         474 : dbg_instr = "hsk_copy2                                      ";
         475 : dbg_instr = "hsk_copy1                                      ";
         476 : dbg_instr = "hsk_copy1+0x001                                ";
         477 : dbg_instr = "hsk_copy1+0x002                                ";
         478 : dbg_instr = "hsk_copy1+0x003                                ";
         479 : dbg_instr = "hsk_copy1+0x004                                ";
         480 : dbg_instr = "hsk_copy1+0x005                                ";
         481 : dbg_instr = "I2C_delay_hclk                                 ";
         482 : dbg_instr = "I2C_delay_med                                  ";
         483 : dbg_instr = "I2C_delay_med+0x001                            ";
         484 : dbg_instr = "I2C_delay_med+0x002                            ";
         485 : dbg_instr = "I2C_delay_short                                ";
         486 : dbg_instr = "I2C_delay_short+0x001                          ";
         487 : dbg_instr = "I2C_delay_short+0x002                          ";
         488 : dbg_instr = "I2C_delay_short+0x003                          ";
         489 : dbg_instr = "I2C_delay_short+0x004                          ";
         490 : dbg_instr = "I2C_delay_short+0x005                          ";
         491 : dbg_instr = "I2C_Rx_bit                                     ";
         492 : dbg_instr = "I2C_Rx_bit+0x001                               ";
         493 : dbg_instr = "I2C_Rx_bit+0x002                               ";
         494 : dbg_instr = "I2C_Rx_bit+0x003                               ";
         495 : dbg_instr = "I2C_Rx_bit+0x004                               ";
         496 : dbg_instr = "I2C_Rx_bit+0x005                               ";
         497 : dbg_instr = "I2C_Rx_bit+0x006                               ";
         498 : dbg_instr = "I2C_Rx_bit+0x007                               ";
         499 : dbg_instr = "I2C_Rx_bit+0x008                               ";
         500 : dbg_instr = "I2C_stop                                       ";
         501 : dbg_instr = "I2C_stop+0x001                                 ";
         502 : dbg_instr = "I2C_stop+0x002                                 ";
         503 : dbg_instr = "I2C_stop+0x003                                 ";
         504 : dbg_instr = "I2C_stop+0x004                                 ";
         505 : dbg_instr = "I2C_stop+0x005                                 ";
         506 : dbg_instr = "I2C_stop+0x006                                 ";
         507 : dbg_instr = "I2C_start                                      ";
         508 : dbg_instr = "I2C_start+0x001                                ";
         509 : dbg_instr = "I2C_start+0x002                                ";
         510 : dbg_instr = "I2C_start+0x003                                ";
         511 : dbg_instr = "I2C_start+0x004                                ";
         512 : dbg_instr = "I2C_start+0x005                                ";
         513 : dbg_instr = "I2C_start+0x006                                ";
         514 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK                         ";
         515 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x001                   ";
         516 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x002                   ";
         517 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x003                   ";
         518 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x004                   ";
         519 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x005                   ";
         520 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x006                   ";
         521 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x007                   ";
         522 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x008                   ";
         523 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x009                   ";
         524 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00a                   ";
         525 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00b                   ";
         526 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00c                   ";
         527 : dbg_instr = "I2C_Rx_byte                                    ";
         528 : dbg_instr = "I2C_Rx_byte+0x001                              ";
         529 : dbg_instr = "I2C_Rx_byte+0x002                              ";
         530 : dbg_instr = "I2C_Rx_byte+0x003                              ";
         531 : dbg_instr = "I2C_Rx_byte+0x004                              ";
         532 : dbg_instr = "I2C_test                                       ";
         533 : dbg_instr = "I2C_test+0x001                                 ";
         534 : dbg_instr = "I2C_test+0x002                                 ";
         535 : dbg_instr = "I2C_test+0x003                                 ";
         536 : dbg_instr = "I2C_user_tx_process                            ";
         537 : dbg_instr = "I2C_user_tx_process+0x001                      ";
         538 : dbg_instr = "I2C_user_tx_process+0x002                      ";
         539 : dbg_instr = "I2C_user_tx_process+0x003                      ";
         540 : dbg_instr = "I2C_user_tx_process+0x004                      ";
         541 : dbg_instr = "I2C_user_tx_process+0x005                      ";
         542 : dbg_instr = "I2C_user_tx_process+0x006                      ";
         543 : dbg_instr = "I2C_send3                                      ";
         544 : dbg_instr = "I2C_send3+0x001                                ";
         545 : dbg_instr = "I2C_send3+0x002                                ";
         546 : dbg_instr = "I2C_send1_prcs                                 ";
         547 : dbg_instr = "I2C_send1_prcs+0x001                           ";
         548 : dbg_instr = "I2C_send1_prcs+0x002                           ";
         549 : dbg_instr = "I2C_send1_prcs+0x003                           ";
         550 : dbg_instr = "I2C_send1_prcs+0x004                           ";
         551 : dbg_instr = "I2C_turfio_initialize                          ";
         552 : dbg_instr = "I2C_turfio_initialize+0x001                    ";
         553 : dbg_instr = "I2C_turfio_initialize+0x002                    ";
         554 : dbg_instr = "I2C_turfio_initialize+0x003                    ";
         555 : dbg_instr = "I2C_turfio_initialize+0x004                    ";
         556 : dbg_instr = "I2C_surf_initialize                            ";
         557 : dbg_instr = "I2C_surf_initialize+0x001                      ";
         558 : dbg_instr = "I2C_surf_initialize+0x002                      ";
         559 : dbg_instr = "I2C_surf_initialize+0x003                      ";
         560 : dbg_instr = "I2C_surf_initialize+0x004                      ";
         561 : dbg_instr = "I2C_surf_initialize+0x005                      ";
         562 : dbg_instr = "I2C_surf_initialize+0x006                      ";
         563 : dbg_instr = "I2C_surf_initialize+0x007                      ";
         564 : dbg_instr = "I2C_surf_initialize+0x008                      ";
         565 : dbg_instr = "I2C_surf_initialize+0x009                      ";
         566 : dbg_instr = "I2C_read_register                              ";
         567 : dbg_instr = "I2C_read_register+0x001                        ";
         568 : dbg_instr = "I2C_read_register+0x002                        ";
         569 : dbg_instr = "I2C_read_register+0x003                        ";
         570 : dbg_instr = "I2C_read_register+0x004                        ";
         571 : dbg_instr = "I2C_read                                       ";
         572 : dbg_instr = "I2C_read+0x001                                 ";
         573 : dbg_instr = "I2C_read+0x002                                 ";
         574 : dbg_instr = "I2C_read+0x003                                 ";
         575 : dbg_instr = "I2C_read+0x004                                 ";
         576 : dbg_instr = "I2C_read+0x005                                 ";
         577 : dbg_instr = "I2C_read+0x006                                 ";
         578 : dbg_instr = "I2C_read+0x007                                 ";
         579 : dbg_instr = "I2C_read+0x008                                 ";
         580 : dbg_instr = "I2C_read+0x009                                 ";
         581 : dbg_instr = "I2C_read+0x00a                                 ";
         582 : dbg_instr = "I2C_read+0x00b                                 ";
         583 : dbg_instr = "I2C_read+0x00c                                 ";
         584 : dbg_instr = "I2C_read+0x00d                                 ";
         585 : dbg_instr = "I2C_read+0x00e                                 ";
         586 : dbg_instr = "I2C_read+0x00f                                 ";
         587 : dbg_instr = "I2C_read+0x010                                 ";
         588 : dbg_instr = "I2C_read+0x011                                 ";
         589 : dbg_instr = "I2C_read+0x012                                 ";
         590 : dbg_instr = "I2C_read+0x013                                 ";
         591 : dbg_instr = "cobsFindZero                                   ";
         592 : dbg_instr = "cobsFindZero+0x001                             ";
         593 : dbg_instr = "cobsFindZero+0x002                             ";
         594 : dbg_instr = "cobsFindZero+0x003                             ";
         595 : dbg_instr = "cobsFindZero+0x004                             ";
         596 : dbg_instr = "cobsFindZero+0x005                             ";
         597 : dbg_instr = "cobsFindZero+0x006                             ";
         598 : dbg_instr = "cobsFindZero+0x007                             ";
         599 : dbg_instr = "cobsFixZero                                    ";
         600 : dbg_instr = "cobsFixZero+0x001                              ";
         601 : dbg_instr = "cobsFixZero+0x002                              ";
         602 : dbg_instr = "cobsFixZero+0x003                              ";
         603 : dbg_instr = "cobsFixZero+0x004                              ";
         604 : dbg_instr = "cobsEncode                                     ";
         605 : dbg_instr = "cobsEncode+0x001                               ";
         606 : dbg_instr = "cobsEncode+0x002                               ";
         607 : dbg_instr = "cobsEncode+0x003                               ";
         608 : dbg_instr = "cobsEncode+0x004                               ";
         609 : dbg_instr = "cobsEncode+0x005                               ";
         610 : dbg_instr = "cobsEncode+0x006                               ";
         611 : dbg_instr = "cobsEncode+0x007                               ";
         612 : dbg_instr = "cobsEncode+0x008                               ";
         613 : dbg_instr = "cobsEncode+0x009                               ";
         614 : dbg_instr = "cobsEncode+0x00a                               ";
         615 : dbg_instr = "cobsEncode+0x00b                               ";
         616 : dbg_instr = "cobsEncode+0x00c                               ";
         617 : dbg_instr = "cobsEncode+0x00d                               ";
         618 : dbg_instr = "cobsEncode+0x00e                               ";
         619 : dbg_instr = "icap_reboot                                    ";
         620 : dbg_instr = "icap_reboot+0x001                              ";
         621 : dbg_instr = "icap_reboot+0x002                              ";
         622 : dbg_instr = "icap_reboot+0x003                              ";
         623 : dbg_instr = "icap_reboot+0x004                              ";
         624 : dbg_instr = "icap_reboot+0x005                              ";
         625 : dbg_instr = "icap_reboot+0x006                              ";
         626 : dbg_instr = "icap_reboot+0x007                              ";
         627 : dbg_instr = "icap_reboot+0x008                              ";
         628 : dbg_instr = "icap_reboot+0x009                              ";
         629 : dbg_instr = "icap_reboot+0x00a                              ";
         630 : dbg_instr = "icap_reboot+0x00b                              ";
         631 : dbg_instr = "icap_reboot+0x00c                              ";
         632 : dbg_instr = "icap_reboot+0x00d                              ";
         633 : dbg_instr = "icap_reboot+0x00e                              ";
         634 : dbg_instr = "icap_reboot+0x00f                              ";
         635 : dbg_instr = "icap_reboot+0x010                              ";
         636 : dbg_instr = "icap_reboot+0x011                              ";
         637 : dbg_instr = "icap_reboot+0x012                              ";
         638 : dbg_instr = "icap_reboot+0x013                              ";
         639 : dbg_instr = "icap_reboot+0x014                              ";
         640 : dbg_instr = "icap_reboot+0x015                              ";
         641 : dbg_instr = "icap_reboot+0x016                              ";
         642 : dbg_instr = "icap_reboot+0x017                              ";
         643 : dbg_instr = "icap_reboot+0x018                              ";
         644 : dbg_instr = "icap_noop                                      ";
         645 : dbg_instr = "icap_3zero                                     ";
         646 : dbg_instr = "icap_3zero+0x001                               ";
         647 : dbg_instr = "icap_3zero+0x002                               ";
         648 : dbg_instr = "icap_3zero+0x003                               ";
         649 : dbg_instr = "icap_3zero+0x004                               ";
         650 : dbg_instr = "icap_3zero+0x005                               ";
         651 : dbg_instr = "icap_3zero+0x006                               ";
         652 : dbg_instr = "icap_3zero+0x007                               ";
         653 : dbg_instr = "icap_3zero+0x008                               ";
         654 : dbg_instr = "icap_3zero+0x009                               ";
         655 : dbg_instr = "icap_3zero+0x00a                               ";
         656 : dbg_instr = "icap_3zero+0x00b                               ";
         657 : dbg_instr = "icap_3zero+0x00c                               ";
         658 : dbg_instr = "icap_3zero+0x00d                               ";
         659 : dbg_instr = "icap_3zero+0x00e                               ";
         660 : dbg_instr = "icap_3zero+0x00f                               ";
         661 : dbg_instr = "icap_3zero+0x010                               ";
         662 : dbg_instr = "icap_3zero+0x011                               ";
         663 : dbg_instr = "icap_3zero+0x012                               ";
         664 : dbg_instr = "icap_3zero+0x013                               ";
         665 : dbg_instr = "icap_3zero+0x014                               ";
         666 : dbg_instr = "icap_3zero+0x015                               ";
         667 : dbg_instr = "icap_3zero+0x016                               ";
         668 : dbg_instr = "icap_3zero+0x017                               ";
         669 : dbg_instr = "icap_3zero+0x018                               ";
         670 : dbg_instr = "icap_3zero+0x019                               ";
         671 : dbg_instr = "icap_3zero+0x01a                               ";
         672 : dbg_instr = "icap_3zero+0x01b                               ";
         673 : dbg_instr = "icap_3zero+0x01c                               ";
         674 : dbg_instr = "icap_3zero+0x01d                               ";
         675 : dbg_instr = "icap_3zero+0x01e                               ";
         676 : dbg_instr = "icap_3zero+0x01f                               ";
         677 : dbg_instr = "icap_3zero+0x020                               ";
         678 : dbg_instr = "icap_3zero+0x021                               ";
         679 : dbg_instr = "icap_3zero+0x022                               ";
         680 : dbg_instr = "icap_3zero+0x023                               ";
         681 : dbg_instr = "icap_3zero+0x024                               ";
         682 : dbg_instr = "icap_3zero+0x025                               ";
         683 : dbg_instr = "icap_3zero+0x026                               ";
         684 : dbg_instr = "icap_3zero+0x027                               ";
         685 : dbg_instr = "icap_3zero+0x028                               ";
         686 : dbg_instr = "icap_3zero+0x029                               ";
         687 : dbg_instr = "icap_3zero+0x02a                               ";
         688 : dbg_instr = "icap_3zero+0x02b                               ";
         689 : dbg_instr = "icap_3zero+0x02c                               ";
         690 : dbg_instr = "icap_3zero+0x02d                               ";
         691 : dbg_instr = "icap_3zero+0x02e                               ";
         692 : dbg_instr = "icap_3zero+0x02f                               ";
         693 : dbg_instr = "icap_3zero+0x030                               ";
         694 : dbg_instr = "icap_3zero+0x031                               ";
         695 : dbg_instr = "icap_3zero+0x032                               ";
         696 : dbg_instr = "icap_3zero+0x033                               ";
         697 : dbg_instr = "icap_3zero+0x034                               ";
         698 : dbg_instr = "icap_3zero+0x035                               ";
         699 : dbg_instr = "icap_3zero+0x036                               ";
         700 : dbg_instr = "icap_3zero+0x037                               ";
         701 : dbg_instr = "icap_3zero+0x038                               ";
         702 : dbg_instr = "icap_3zero+0x039                               ";
         703 : dbg_instr = "icap_3zero+0x03a                               ";
         704 : dbg_instr = "icap_3zero+0x03b                               ";
         705 : dbg_instr = "icap_3zero+0x03c                               ";
         706 : dbg_instr = "icap_3zero+0x03d                               ";
         707 : dbg_instr = "icap_3zero+0x03e                               ";
         708 : dbg_instr = "icap_3zero+0x03f                               ";
         709 : dbg_instr = "icap_3zero+0x040                               ";
         710 : dbg_instr = "icap_3zero+0x041                               ";
         711 : dbg_instr = "icap_3zero+0x042                               ";
         712 : dbg_instr = "icap_3zero+0x043                               ";
         713 : dbg_instr = "icap_3zero+0x044                               ";
         714 : dbg_instr = "icap_3zero+0x045                               ";
         715 : dbg_instr = "icap_3zero+0x046                               ";
         716 : dbg_instr = "icap_3zero+0x047                               ";
         717 : dbg_instr = "icap_3zero+0x048                               ";
         718 : dbg_instr = "icap_3zero+0x049                               ";
         719 : dbg_instr = "icap_3zero+0x04a                               ";
         720 : dbg_instr = "icap_3zero+0x04b                               ";
         721 : dbg_instr = "icap_3zero+0x04c                               ";
         722 : dbg_instr = "icap_3zero+0x04d                               ";
         723 : dbg_instr = "icap_3zero+0x04e                               ";
         724 : dbg_instr = "icap_3zero+0x04f                               ";
         725 : dbg_instr = "icap_3zero+0x050                               ";
         726 : dbg_instr = "icap_3zero+0x051                               ";
         727 : dbg_instr = "icap_3zero+0x052                               ";
         728 : dbg_instr = "icap_3zero+0x053                               ";
         729 : dbg_instr = "icap_3zero+0x054                               ";
         730 : dbg_instr = "icap_3zero+0x055                               ";
         731 : dbg_instr = "icap_3zero+0x056                               ";
         732 : dbg_instr = "icap_3zero+0x057                               ";
         733 : dbg_instr = "icap_3zero+0x058                               ";
         734 : dbg_instr = "icap_3zero+0x059                               ";
         735 : dbg_instr = "icap_3zero+0x05a                               ";
         736 : dbg_instr = "icap_3zero+0x05b                               ";
         737 : dbg_instr = "icap_3zero+0x05c                               ";
         738 : dbg_instr = "icap_3zero+0x05d                               ";
         739 : dbg_instr = "icap_3zero+0x05e                               ";
         740 : dbg_instr = "icap_3zero+0x05f                               ";
         741 : dbg_instr = "icap_3zero+0x060                               ";
         742 : dbg_instr = "icap_3zero+0x061                               ";
         743 : dbg_instr = "icap_3zero+0x062                               ";
         744 : dbg_instr = "icap_3zero+0x063                               ";
         745 : dbg_instr = "icap_3zero+0x064                               ";
         746 : dbg_instr = "icap_3zero+0x065                               ";
         747 : dbg_instr = "icap_3zero+0x066                               ";
         748 : dbg_instr = "icap_3zero+0x067                               ";
         749 : dbg_instr = "icap_3zero+0x068                               ";
         750 : dbg_instr = "icap_3zero+0x069                               ";
         751 : dbg_instr = "icap_3zero+0x06a                               ";
         752 : dbg_instr = "icap_3zero+0x06b                               ";
         753 : dbg_instr = "icap_3zero+0x06c                               ";
         754 : dbg_instr = "icap_3zero+0x06d                               ";
         755 : dbg_instr = "icap_3zero+0x06e                               ";
         756 : dbg_instr = "icap_3zero+0x06f                               ";
         757 : dbg_instr = "icap_3zero+0x070                               ";
         758 : dbg_instr = "icap_3zero+0x071                               ";
         759 : dbg_instr = "icap_3zero+0x072                               ";
         760 : dbg_instr = "icap_3zero+0x073                               ";
         761 : dbg_instr = "icap_3zero+0x074                               ";
         762 : dbg_instr = "icap_3zero+0x075                               ";
         763 : dbg_instr = "icap_3zero+0x076                               ";
         764 : dbg_instr = "icap_3zero+0x077                               ";
         765 : dbg_instr = "icap_3zero+0x078                               ";
         766 : dbg_instr = "icap_3zero+0x079                               ";
         767 : dbg_instr = "icap_3zero+0x07a                               ";
         768 : dbg_instr = "icap_3zero+0x07b                               ";
         769 : dbg_instr = "icap_3zero+0x07c                               ";
         770 : dbg_instr = "icap_3zero+0x07d                               ";
         771 : dbg_instr = "icap_3zero+0x07e                               ";
         772 : dbg_instr = "icap_3zero+0x07f                               ";
         773 : dbg_instr = "icap_3zero+0x080                               ";
         774 : dbg_instr = "icap_3zero+0x081                               ";
         775 : dbg_instr = "icap_3zero+0x082                               ";
         776 : dbg_instr = "icap_3zero+0x083                               ";
         777 : dbg_instr = "icap_3zero+0x084                               ";
         778 : dbg_instr = "icap_3zero+0x085                               ";
         779 : dbg_instr = "icap_3zero+0x086                               ";
         780 : dbg_instr = "icap_3zero+0x087                               ";
         781 : dbg_instr = "icap_3zero+0x088                               ";
         782 : dbg_instr = "icap_3zero+0x089                               ";
         783 : dbg_instr = "icap_3zero+0x08a                               ";
         784 : dbg_instr = "icap_3zero+0x08b                               ";
         785 : dbg_instr = "icap_3zero+0x08c                               ";
         786 : dbg_instr = "icap_3zero+0x08d                               ";
         787 : dbg_instr = "icap_3zero+0x08e                               ";
         788 : dbg_instr = "icap_3zero+0x08f                               ";
         789 : dbg_instr = "icap_3zero+0x090                               ";
         790 : dbg_instr = "icap_3zero+0x091                               ";
         791 : dbg_instr = "icap_3zero+0x092                               ";
         792 : dbg_instr = "icap_3zero+0x093                               ";
         793 : dbg_instr = "icap_3zero+0x094                               ";
         794 : dbg_instr = "icap_3zero+0x095                               ";
         795 : dbg_instr = "icap_3zero+0x096                               ";
         796 : dbg_instr = "icap_3zero+0x097                               ";
         797 : dbg_instr = "icap_3zero+0x098                               ";
         798 : dbg_instr = "icap_3zero+0x099                               ";
         799 : dbg_instr = "icap_3zero+0x09a                               ";
         800 : dbg_instr = "icap_3zero+0x09b                               ";
         801 : dbg_instr = "icap_3zero+0x09c                               ";
         802 : dbg_instr = "icap_3zero+0x09d                               ";
         803 : dbg_instr = "icap_3zero+0x09e                               ";
         804 : dbg_instr = "icap_3zero+0x09f                               ";
         805 : dbg_instr = "icap_3zero+0x0a0                               ";
         806 : dbg_instr = "icap_3zero+0x0a1                               ";
         807 : dbg_instr = "icap_3zero+0x0a2                               ";
         808 : dbg_instr = "icap_3zero+0x0a3                               ";
         809 : dbg_instr = "icap_3zero+0x0a4                               ";
         810 : dbg_instr = "icap_3zero+0x0a5                               ";
         811 : dbg_instr = "icap_3zero+0x0a6                               ";
         812 : dbg_instr = "icap_3zero+0x0a7                               ";
         813 : dbg_instr = "icap_3zero+0x0a8                               ";
         814 : dbg_instr = "icap_3zero+0x0a9                               ";
         815 : dbg_instr = "icap_3zero+0x0aa                               ";
         816 : dbg_instr = "icap_3zero+0x0ab                               ";
         817 : dbg_instr = "icap_3zero+0x0ac                               ";
         818 : dbg_instr = "icap_3zero+0x0ad                               ";
         819 : dbg_instr = "icap_3zero+0x0ae                               ";
         820 : dbg_instr = "icap_3zero+0x0af                               ";
         821 : dbg_instr = "icap_3zero+0x0b0                               ";
         822 : dbg_instr = "icap_3zero+0x0b1                               ";
         823 : dbg_instr = "icap_3zero+0x0b2                               ";
         824 : dbg_instr = "icap_3zero+0x0b3                               ";
         825 : dbg_instr = "icap_3zero+0x0b4                               ";
         826 : dbg_instr = "icap_3zero+0x0b5                               ";
         827 : dbg_instr = "icap_3zero+0x0b6                               ";
         828 : dbg_instr = "icap_3zero+0x0b7                               ";
         829 : dbg_instr = "icap_3zero+0x0b8                               ";
         830 : dbg_instr = "icap_3zero+0x0b9                               ";
         831 : dbg_instr = "icap_3zero+0x0ba                               ";
         832 : dbg_instr = "icap_3zero+0x0bb                               ";
         833 : dbg_instr = "icap_3zero+0x0bc                               ";
         834 : dbg_instr = "icap_3zero+0x0bd                               ";
         835 : dbg_instr = "icap_3zero+0x0be                               ";
         836 : dbg_instr = "icap_3zero+0x0bf                               ";
         837 : dbg_instr = "icap_3zero+0x0c0                               ";
         838 : dbg_instr = "icap_3zero+0x0c1                               ";
         839 : dbg_instr = "icap_3zero+0x0c2                               ";
         840 : dbg_instr = "icap_3zero+0x0c3                               ";
         841 : dbg_instr = "icap_3zero+0x0c4                               ";
         842 : dbg_instr = "icap_3zero+0x0c5                               ";
         843 : dbg_instr = "icap_3zero+0x0c6                               ";
         844 : dbg_instr = "icap_3zero+0x0c7                               ";
         845 : dbg_instr = "icap_3zero+0x0c8                               ";
         846 : dbg_instr = "icap_3zero+0x0c9                               ";
         847 : dbg_instr = "icap_3zero+0x0ca                               ";
         848 : dbg_instr = "icap_3zero+0x0cb                               ";
         849 : dbg_instr = "icap_3zero+0x0cc                               ";
         850 : dbg_instr = "icap_3zero+0x0cd                               ";
         851 : dbg_instr = "icap_3zero+0x0ce                               ";
         852 : dbg_instr = "icap_3zero+0x0cf                               ";
         853 : dbg_instr = "icap_3zero+0x0d0                               ";
         854 : dbg_instr = "icap_3zero+0x0d1                               ";
         855 : dbg_instr = "icap_3zero+0x0d2                               ";
         856 : dbg_instr = "icap_3zero+0x0d3                               ";
         857 : dbg_instr = "icap_3zero+0x0d4                               ";
         858 : dbg_instr = "icap_3zero+0x0d5                               ";
         859 : dbg_instr = "icap_3zero+0x0d6                               ";
         860 : dbg_instr = "icap_3zero+0x0d7                               ";
         861 : dbg_instr = "icap_3zero+0x0d8                               ";
         862 : dbg_instr = "icap_3zero+0x0d9                               ";
         863 : dbg_instr = "icap_3zero+0x0da                               ";
         864 : dbg_instr = "icap_3zero+0x0db                               ";
         865 : dbg_instr = "icap_3zero+0x0dc                               ";
         866 : dbg_instr = "icap_3zero+0x0dd                               ";
         867 : dbg_instr = "icap_3zero+0x0de                               ";
         868 : dbg_instr = "icap_3zero+0x0df                               ";
         869 : dbg_instr = "icap_3zero+0x0e0                               ";
         870 : dbg_instr = "icap_3zero+0x0e1                               ";
         871 : dbg_instr = "icap_3zero+0x0e2                               ";
         872 : dbg_instr = "icap_3zero+0x0e3                               ";
         873 : dbg_instr = "icap_3zero+0x0e4                               ";
         874 : dbg_instr = "icap_3zero+0x0e5                               ";
         875 : dbg_instr = "icap_3zero+0x0e6                               ";
         876 : dbg_instr = "icap_3zero+0x0e7                               ";
         877 : dbg_instr = "icap_3zero+0x0e8                               ";
         878 : dbg_instr = "icap_3zero+0x0e9                               ";
         879 : dbg_instr = "icap_3zero+0x0ea                               ";
         880 : dbg_instr = "icap_3zero+0x0eb                               ";
         881 : dbg_instr = "icap_3zero+0x0ec                               ";
         882 : dbg_instr = "icap_3zero+0x0ed                               ";
         883 : dbg_instr = "icap_3zero+0x0ee                               ";
         884 : dbg_instr = "icap_3zero+0x0ef                               ";
         885 : dbg_instr = "icap_3zero+0x0f0                               ";
         886 : dbg_instr = "icap_3zero+0x0f1                               ";
         887 : dbg_instr = "icap_3zero+0x0f2                               ";
         888 : dbg_instr = "icap_3zero+0x0f3                               ";
         889 : dbg_instr = "icap_3zero+0x0f4                               ";
         890 : dbg_instr = "icap_3zero+0x0f5                               ";
         891 : dbg_instr = "icap_3zero+0x0f6                               ";
         892 : dbg_instr = "icap_3zero+0x0f7                               ";
         893 : dbg_instr = "icap_3zero+0x0f8                               ";
         894 : dbg_instr = "icap_3zero+0x0f9                               ";
         895 : dbg_instr = "icap_3zero+0x0fa                               ";
         896 : dbg_instr = "icap_3zero+0x0fb                               ";
         897 : dbg_instr = "icap_3zero+0x0fc                               ";
         898 : dbg_instr = "icap_3zero+0x0fd                               ";
         899 : dbg_instr = "icap_3zero+0x0fe                               ";
         900 : dbg_instr = "icap_3zero+0x0ff                               ";
         901 : dbg_instr = "icap_3zero+0x100                               ";
         902 : dbg_instr = "icap_3zero+0x101                               ";
         903 : dbg_instr = "icap_3zero+0x102                               ";
         904 : dbg_instr = "icap_3zero+0x103                               ";
         905 : dbg_instr = "icap_3zero+0x104                               ";
         906 : dbg_instr = "icap_3zero+0x105                               ";
         907 : dbg_instr = "icap_3zero+0x106                               ";
         908 : dbg_instr = "icap_3zero+0x107                               ";
         909 : dbg_instr = "icap_3zero+0x108                               ";
         910 : dbg_instr = "icap_3zero+0x109                               ";
         911 : dbg_instr = "icap_3zero+0x10a                               ";
         912 : dbg_instr = "icap_3zero+0x10b                               ";
         913 : dbg_instr = "icap_3zero+0x10c                               ";
         914 : dbg_instr = "icap_3zero+0x10d                               ";
         915 : dbg_instr = "icap_3zero+0x10e                               ";
         916 : dbg_instr = "icap_3zero+0x10f                               ";
         917 : dbg_instr = "icap_3zero+0x110                               ";
         918 : dbg_instr = "icap_3zero+0x111                               ";
         919 : dbg_instr = "icap_3zero+0x112                               ";
         920 : dbg_instr = "icap_3zero+0x113                               ";
         921 : dbg_instr = "icap_3zero+0x114                               ";
         922 : dbg_instr = "icap_3zero+0x115                               ";
         923 : dbg_instr = "icap_3zero+0x116                               ";
         924 : dbg_instr = "icap_3zero+0x117                               ";
         925 : dbg_instr = "icap_3zero+0x118                               ";
         926 : dbg_instr = "icap_3zero+0x119                               ";
         927 : dbg_instr = "icap_3zero+0x11a                               ";
         928 : dbg_instr = "icap_3zero+0x11b                               ";
         929 : dbg_instr = "icap_3zero+0x11c                               ";
         930 : dbg_instr = "icap_3zero+0x11d                               ";
         931 : dbg_instr = "icap_3zero+0x11e                               ";
         932 : dbg_instr = "icap_3zero+0x11f                               ";
         933 : dbg_instr = "icap_3zero+0x120                               ";
         934 : dbg_instr = "icap_3zero+0x121                               ";
         935 : dbg_instr = "icap_3zero+0x122                               ";
         936 : dbg_instr = "icap_3zero+0x123                               ";
         937 : dbg_instr = "icap_3zero+0x124                               ";
         938 : dbg_instr = "icap_3zero+0x125                               ";
         939 : dbg_instr = "icap_3zero+0x126                               ";
         940 : dbg_instr = "icap_3zero+0x127                               ";
         941 : dbg_instr = "icap_3zero+0x128                               ";
         942 : dbg_instr = "icap_3zero+0x129                               ";
         943 : dbg_instr = "icap_3zero+0x12a                               ";
         944 : dbg_instr = "icap_3zero+0x12b                               ";
         945 : dbg_instr = "icap_3zero+0x12c                               ";
         946 : dbg_instr = "icap_3zero+0x12d                               ";
         947 : dbg_instr = "icap_3zero+0x12e                               ";
         948 : dbg_instr = "icap_3zero+0x12f                               ";
         949 : dbg_instr = "icap_3zero+0x130                               ";
         950 : dbg_instr = "icap_3zero+0x131                               ";
         951 : dbg_instr = "icap_3zero+0x132                               ";
         952 : dbg_instr = "icap_3zero+0x133                               ";
         953 : dbg_instr = "icap_3zero+0x134                               ";
         954 : dbg_instr = "icap_3zero+0x135                               ";
         955 : dbg_instr = "icap_3zero+0x136                               ";
         956 : dbg_instr = "icap_3zero+0x137                               ";
         957 : dbg_instr = "icap_3zero+0x138                               ";
         958 : dbg_instr = "icap_3zero+0x139                               ";
         959 : dbg_instr = "icap_3zero+0x13a                               ";
         960 : dbg_instr = "icap_3zero+0x13b                               ";
         961 : dbg_instr = "icap_3zero+0x13c                               ";
         962 : dbg_instr = "icap_3zero+0x13d                               ";
         963 : dbg_instr = "icap_3zero+0x13e                               ";
         964 : dbg_instr = "icap_3zero+0x13f                               ";
         965 : dbg_instr = "icap_3zero+0x140                               ";
         966 : dbg_instr = "icap_3zero+0x141                               ";
         967 : dbg_instr = "icap_3zero+0x142                               ";
         968 : dbg_instr = "icap_3zero+0x143                               ";
         969 : dbg_instr = "icap_3zero+0x144                               ";
         970 : dbg_instr = "icap_3zero+0x145                               ";
         971 : dbg_instr = "icap_3zero+0x146                               ";
         972 : dbg_instr = "icap_3zero+0x147                               ";
         973 : dbg_instr = "icap_3zero+0x148                               ";
         974 : dbg_instr = "icap_3zero+0x149                               ";
         975 : dbg_instr = "icap_3zero+0x14a                               ";
         976 : dbg_instr = "icap_3zero+0x14b                               ";
         977 : dbg_instr = "icap_3zero+0x14c                               ";
         978 : dbg_instr = "icap_3zero+0x14d                               ";
         979 : dbg_instr = "icap_3zero+0x14e                               ";
         980 : dbg_instr = "icap_3zero+0x14f                               ";
         981 : dbg_instr = "icap_3zero+0x150                               ";
         982 : dbg_instr = "icap_3zero+0x151                               ";
         983 : dbg_instr = "icap_3zero+0x152                               ";
         984 : dbg_instr = "icap_3zero+0x153                               ";
         985 : dbg_instr = "icap_3zero+0x154                               ";
         986 : dbg_instr = "icap_3zero+0x155                               ";
         987 : dbg_instr = "icap_3zero+0x156                               ";
         988 : dbg_instr = "icap_3zero+0x157                               ";
         989 : dbg_instr = "icap_3zero+0x158                               ";
         990 : dbg_instr = "icap_3zero+0x159                               ";
         991 : dbg_instr = "icap_3zero+0x15a                               ";
         992 : dbg_instr = "icap_3zero+0x15b                               ";
         993 : dbg_instr = "icap_3zero+0x15c                               ";
         994 : dbg_instr = "icap_3zero+0x15d                               ";
         995 : dbg_instr = "icap_3zero+0x15e                               ";
         996 : dbg_instr = "icap_3zero+0x15f                               ";
         997 : dbg_instr = "icap_3zero+0x160                               ";
         998 : dbg_instr = "icap_3zero+0x161                               ";
         999 : dbg_instr = "icap_3zero+0x162                               ";
         1000 : dbg_instr = "icap_3zero+0x163                               ";
         1001 : dbg_instr = "icap_3zero+0x164                               ";
         1002 : dbg_instr = "icap_3zero+0x165                               ";
         1003 : dbg_instr = "icap_3zero+0x166                               ";
         1004 : dbg_instr = "icap_3zero+0x167                               ";
         1005 : dbg_instr = "icap_3zero+0x168                               ";
         1006 : dbg_instr = "icap_3zero+0x169                               ";
         1007 : dbg_instr = "icap_3zero+0x16a                               ";
         1008 : dbg_instr = "icap_3zero+0x16b                               ";
         1009 : dbg_instr = "icap_3zero+0x16c                               ";
         1010 : dbg_instr = "icap_3zero+0x16d                               ";
         1011 : dbg_instr = "icap_3zero+0x16e                               ";
         1012 : dbg_instr = "icap_3zero+0x16f                               ";
         1013 : dbg_instr = "icap_3zero+0x170                               ";
         1014 : dbg_instr = "icap_3zero+0x171                               ";
         1015 : dbg_instr = "icap_3zero+0x172                               ";
         1016 : dbg_instr = "icap_3zero+0x173                               ";
         1017 : dbg_instr = "icap_3zero+0x174                               ";
         1018 : dbg_instr = "icap_3zero+0x175                               ";
         1019 : dbg_instr = "icap_3zero+0x176                               ";
         1020 : dbg_instr = "icap_3zero+0x177                               ";
         1021 : dbg_instr = "icap_3zero+0x178                               ";
         1022 : dbg_instr = "icap_3zero+0x179                               ";
         1023 : dbg_instr = "icap_3zero+0x17a                               ";
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
    .INIT_00(256'h1600150014002012D280920B900A70016EE02004005B010C000000002004002D),
    .INIT_01(256'hCED0DD0B7D036EE04ED011802027D202C0109001700011002017D201026B1700),
    .INIT_02(256'h01F4B03FB80B90019001700031FFD1C01101202C90017000202C900070002024),
    .INIT_03(256'hAA102041D00111380227F000307F70FFE03340080214AA10110110801137B008),
    .INIT_04(256'h7001F210F212F214F2131200F216F2171200D21132FE9211603D400E1101022C),
    .INIT_05(256'h2081D202207DD201B210500080019F10110010011E0070001D011E001180B01B),
    .INIT_06(256'h43801280D000F314F213B3009201B314B21360C8D700B71720A9D204208ED203),
    .INIT_07(256'hC230B300B2125000F311F21013001201207A130412046078D200B212F314F213),
    .INIT_08(256'hF22101075000F2101203B02D0218142101FBF2210107F220A2201234B21120F5),
    .INIT_09(256'h1601C560B520B42106304306430643060102B21206704706B71116C0023B1621),
    .INIT_0A(256'h023B1622F421149060C3D204B2115000F2101202F71120F5D7041701B711C460),
    .INIT_0B(256'hD6FBD5FAD4F9D7F8E0B94608450E5608E0B44700440046061710B620B521B422),
    .INIT_0C(256'hA3201218171F60E0D80060CDD701B81620F5D2FC920FD2FD920E5000F2111205),
    .INIT_0D(256'h20F0D800F4151401F418B31834E1021801FB141FB41760CFD71F97011201E370),
    .INIT_0E(256'hF815180160E8D91F12019901E320A3901219F61836E1023B0960161F0680F321),
    .INIT_0F(256'h720192115000F3101300F212420E128060F9D200B2125000F216F217120001F4),

    // Address 256 to 511
    .INIT_10(256'h6E0001141000C0E05000A23013380102B2125000E103420E130113FF5000D211),
    .INIT_11(256'h910105608610118401401500E1D1D43C948361CFC2F0928150008001D00B7003),
    .INIT_12(256'hD2C82139D20F2167D21321BCD2122159D211214BD210928261D3D500611DD183),
    .INIT_13(256'h0920D285B209D984B908B05301D521C701D561D1D2002175D2CA218ED2C9217B),
    .INIT_14(256'h92FDD98499FCB10301D521C411890920D288B20C0920D287B20B0920D286B20A),
    .INIT_15(256'h0920D28592F9D98499F8B1E301D521C46154D5FE150601DA15C611860920D285),
    .INIT_16(256'h15C411860920D28592FBD98499FAB10301D521C46162D5F8150401D915C01186),
    .INIT_17(256'h92842187D200928301D55000026B978796869585948421C46170D5FC150601DA),
    .INIT_18(256'h928301D521C7B013D385D284832013009211D3114340232072FF242094859311),
    .INIT_19(256'h15851418F2179201F7169784F31521C7B005B0042199D300B31721AAD200B013),
    .INIT_1A(256'h21C7B004B00361B0D200B21521C7D285D484824061A0920115011401E3408350),
    .INIT_1B(256'hD9841907B02301D521C461B4920111011401C3100930A340190011841418D283),
    .INIT_1C(256'h130C5000E2301201A230130901CB1308025CC910190179FF1186D2850920B200),
    .INIT_1D(256'h110115010920C210825001DB01DA5000DF80D281928021CB130A21CB130B21CB),
    .INIT_1E(256'h01E101E5B02D01E1B01E50004308E1E7420012044300500001E501E501E55000),
    .INIT_1F(256'h01E5B00E01E2B02DB01E500001E5B01E01E2B02D01E5B00E5000B00DD201920C),

    // Address 512 to 767
    .INIT_20(256'h1A01500001E101EBE203B00D01E101E5B02D01E1DB0E4B004A021B015000B00D),
    .INIT_21(256'hF42250006218D41F940190000202AA40500001F4020201FB5000E2104A0001EB),
    .INIT_22(256'h1607151E14D4FA23222216051421F4211490500001F4021801FBF620F5211423),
    .INIT_23(256'h900002025A01BA2101FB0218142101FBF520F4215000021F1601158D14D8021F),
    .INIT_24(256'h0750500001F401E16240D61F9601B00D01E1B02D01E1D20E4200D621EA60020F),
    .INIT_25(256'h024F1685968315805000027017018750024F225017011000D20082701000C760),
    .INIT_26(256'hBFF0BFF0BFF0D21112105000B008A262C560D2080257D20015018250D708977F),
    .INIT_27(256'hB000B300D700D600D500D400B010B000B020B3000284B660B550B990BAA0BFF0),
    .INIT_28(256'h10001000100010001000100010005000B000B000B000B200B0F00285B010B800),
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
    .INITP_00(256'h02A0834A4E9434DDDD280302EA8A20D630A0D842AAB56BAF210CACC803036A0A),
    .INITP_01(256'h0E24D2A29D582612D88693560774A228AAD4D50088D28B5260558508AA28AA13),

    // Address 256 to 511
    .INITP_02(256'h34A802D60622AD60622AD60622A18618622AB777777774DD510D34A82C862D4A),
    .INITP_03(256'hAAAAAAA0AAA746AA562AA2222908A4248AB56402AB4A9D58098AAD362AA42000),

    // Address 512 to 767
    .INITP_04(256'hAAAAAAAAAA2B6D499085A74D2AD6AA5AE0A2AA0202822AA8AD78AAB62AEAA94A),
    .INITP_05(256'h000000000000000000000000000000000000000000000000000000000002AAAA),

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
