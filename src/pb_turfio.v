/*
 * == pblaze-cc ==
 * source : pb_turfio.c
 * create : Sat Jan 25 14:19:08 2025
 * modify : Sat Jan 25 14:19:08 2025
 */
`timescale 1 ps / 1ps

/* 
 * == pblaze-as ==
 * source : pb_turfio.s
 * create : Sat Jan 25 14:19:17 2025
 * modify : Sat Jan 25 14:19:17 2025
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
         82 : dbg_instr = "update_housekeeping                            ";
         83 : dbg_instr = "update_housekeeping+0x001                      ";
         84 : dbg_instr = "update_housekeeping+0x002                      ";
         85 : dbg_instr = "update_housekeeping+0x003                      ";
         86 : dbg_instr = "update_housekeeping+0x004                      ";
         87 : dbg_instr = "update_housekeeping+0x005                      ";
         88 : dbg_instr = "update_housekeeping+0x006                      ";
         89 : dbg_instr = "update_housekeeping+0x007                      ";
         90 : dbg_instr = "update_housekeeping+0x008                      ";
         91 : dbg_instr = "IDLE_WAIT                                      ";
         92 : dbg_instr = "IDLE_WAIT+0x001                                ";
         93 : dbg_instr = "IDLE_WAIT+0x002                                ";
         94 : dbg_instr = "IDLE_WAIT+0x003                                ";
         95 : dbg_instr = "IDLE_WAIT+0x004                                ";
         96 : dbg_instr = "IDLE_WAIT+0x005                                ";
         97 : dbg_instr = "IDLE_WAIT+0x006                                ";
         98 : dbg_instr = "IDLE_WAIT+0x007                                ";
         99 : dbg_instr = "IDLE_WAIT+0x008                                ";
         100 : dbg_instr = "IDLE_WAIT+0x009                                ";
         101 : dbg_instr = "IDLE_WAIT+0x00a                                ";
         102 : dbg_instr = "IDLE_WAIT+0x00b                                ";
         103 : dbg_instr = "IDLE_WAIT+0x00c                                ";
         104 : dbg_instr = "IDLE_WAIT+0x00d                                ";
         105 : dbg_instr = "IDLE_WAIT+0x00e                                ";
         106 : dbg_instr = "IDLE_WAIT+0x00f                                ";
         107 : dbg_instr = "IDLE_WAIT+0x010                                ";
         108 : dbg_instr = "IDLE_WAIT+0x011                                ";
         109 : dbg_instr = "IDLE_WAIT+0x012                                ";
         110 : dbg_instr = "IDLE_WAIT+0x013                                ";
         111 : dbg_instr = "IDLE_WAIT+0x014                                ";
         112 : dbg_instr = "IDLE_WAIT+0x015                                ";
         113 : dbg_instr = "IDLE_WAIT+0x016                                ";
         114 : dbg_instr = "IDLE_WAIT+0x017                                ";
         115 : dbg_instr = "IDLE_WAIT+0x018                                ";
         116 : dbg_instr = "SURF_CHECK                                     ";
         117 : dbg_instr = "SURF_CHECK+0x001                               ";
         118 : dbg_instr = "SURF_CHECK+0x002                               ";
         119 : dbg_instr = "SURF_CHECK+0x003                               ";
         120 : dbg_instr = "SURF_WRITE_REG                                 ";
         121 : dbg_instr = "SURF_WRITE_REG+0x001                           ";
         122 : dbg_instr = "SURF_WRITE_REG+0x002                           ";
         123 : dbg_instr = "SURF_WRITE_REG+0x003                           ";
         124 : dbg_instr = "SURF_WRITE_REG+0x004                           ";
         125 : dbg_instr = "SURF_WRITE_REG+0x005                           ";
         126 : dbg_instr = "SURF_WRITE_REG+0x006                           ";
         127 : dbg_instr = "SURF_WRITE_REG+0x007                           ";
         128 : dbg_instr = "SURF_WRITE_REG+0x008                           ";
         129 : dbg_instr = "SURF_WRITE_REG+0x009                           ";
         130 : dbg_instr = "SURF_WRITE_REG+0x00a                           ";
         131 : dbg_instr = "SURF_WRITE_REG+0x00b                           ";
         132 : dbg_instr = "SURF_WRITE_REG+0x00c                           ";
         133 : dbg_instr = "SURF_READ_REG                                  ";
         134 : dbg_instr = "SURF_READ_REG+0x001                            ";
         135 : dbg_instr = "SURF_READ_REG+0x002                            ";
         136 : dbg_instr = "SURF_READ_REG+0x003                            ";
         137 : dbg_instr = "SURF_READ_REG+0x004                            ";
         138 : dbg_instr = "SURF_READ_REG+0x005                            ";
         139 : dbg_instr = "SURF_READ_REG+0x006                            ";
         140 : dbg_instr = "SURF_READ_REG+0x007                            ";
         141 : dbg_instr = "SURF_READ_REG+0x008                            ";
         142 : dbg_instr = "SURF_READ_REG+0x009                            ";
         143 : dbg_instr = "SURF_READ_REG+0x00a                            ";
         144 : dbg_instr = "SURF_READ_REG+0x00b                            ";
         145 : dbg_instr = "SURF_READ_REG+0x00c                            ";
         146 : dbg_instr = "SURF_READ_REG+0x00d                            ";
         147 : dbg_instr = "SURF_READ_REG+0x00e                            ";
         148 : dbg_instr = "SURF_READ_REG+0x00f                            ";
         149 : dbg_instr = "SURF_READ_REG+0x010                            ";
         150 : dbg_instr = "SURF_READ_REG+0x011                            ";
         151 : dbg_instr = "SURF_READ_REG+0x012                            ";
         152 : dbg_instr = "SURF_READ_REG+0x013                            ";
         153 : dbg_instr = "SURF_READ_REG+0x014                            ";
         154 : dbg_instr = "SURF_READ_REG+0x015                            ";
         155 : dbg_instr = "SURF_READ_REG+0x016                            ";
         156 : dbg_instr = "SURF_READ_REG+0x017                            ";
         157 : dbg_instr = "SURF_READ_REG+0x018                            ";
         158 : dbg_instr = "SURF_READ_REG+0x019                            ";
         159 : dbg_instr = "SURF_READ_REG+0x01a                            ";
         160 : dbg_instr = "TURFIO                                         ";
         161 : dbg_instr = "TURFIO+0x001                                   ";
         162 : dbg_instr = "TURFIO+0x002                                   ";
         163 : dbg_instr = "TURFIO+0x003                                   ";
         164 : dbg_instr = "TURFIO+0x004                                   ";
         165 : dbg_instr = "TURFIO+0x005                                   ";
         166 : dbg_instr = "TURFIO+0x006                                   ";
         167 : dbg_instr = "TURFIO+0x007                                   ";
         168 : dbg_instr = "TURFIO+0x008                                   ";
         169 : dbg_instr = "TURFIO+0x009                                   ";
         170 : dbg_instr = "TURFIO+0x00a                                   ";
         171 : dbg_instr = "TURFIO+0x00b                                   ";
         172 : dbg_instr = "TURFIO+0x00c                                   ";
         173 : dbg_instr = "TURFIO+0x00d                                   ";
         174 : dbg_instr = "TURFIO+0x00e                                   ";
         175 : dbg_instr = "TURFIO+0x00f                                   ";
         176 : dbg_instr = "TURFIO+0x010                                   ";
         177 : dbg_instr = "TURFIO+0x011                                   ";
         178 : dbg_instr = "TURFIO+0x012                                   ";
         179 : dbg_instr = "TURFIO+0x013                                   ";
         180 : dbg_instr = "TURFIO+0x014                                   ";
         181 : dbg_instr = "TURFIO+0x015                                   ";
         182 : dbg_instr = "TURFIO+0x016                                   ";
         183 : dbg_instr = "TURFIO+0x017                                   ";
         184 : dbg_instr = "TURFIO+0x018                                   ";
         185 : dbg_instr = "TURFIO+0x019                                   ";
         186 : dbg_instr = "TURFIO+0x01a                                   ";
         187 : dbg_instr = "TURFIO+0x01b                                   ";
         188 : dbg_instr = "TURFIO+0x01c                                   ";
         189 : dbg_instr = "TURFIO+0x01d                                   ";
         190 : dbg_instr = "TURFIO+0x01e                                   ";
         191 : dbg_instr = "PMBUS                                          ";
         192 : dbg_instr = "PMBUS+0x001                                    ";
         193 : dbg_instr = "PMBUS+0x002                                    ";
         194 : dbg_instr = "PMBUS+0x003                                    ";
         195 : dbg_instr = "PMBUS+0x004                                    ";
         196 : dbg_instr = "PMBUS+0x005                                    ";
         197 : dbg_instr = "PMBUS+0x006                                    ";
         198 : dbg_instr = "PMBUS+0x007                                    ";
         199 : dbg_instr = "PMBUS+0x008                                    ";
         200 : dbg_instr = "PMBUS+0x009                                    ";
         201 : dbg_instr = "PMBUS+0x00a                                    ";
         202 : dbg_instr = "PMBUS+0x00b                                    ";
         203 : dbg_instr = "PMBUS+0x00c                                    ";
         204 : dbg_instr = "PMBUS+0x00d                                    ";
         205 : dbg_instr = "PMBUS+0x00e                                    ";
         206 : dbg_instr = "PMBUS+0x00f                                    ";
         207 : dbg_instr = "PMBUS+0x010                                    ";
         208 : dbg_instr = "PMBUS+0x011                                    ";
         209 : dbg_instr = "PMBUS+0x012                                    ";
         210 : dbg_instr = "PMBUS+0x013                                    ";
         211 : dbg_instr = "PMBUS+0x014                                    ";
         212 : dbg_instr = "PMBUS+0x015                                    ";
         213 : dbg_instr = "PMBUS+0x016                                    ";
         214 : dbg_instr = "PMBUS+0x017                                    ";
         215 : dbg_instr = "PMBUS+0x018                                    ";
         216 : dbg_instr = "PMBUS+0x019                                    ";
         217 : dbg_instr = "PMBUS+0x01a                                    ";
         218 : dbg_instr = "PMBUS+0x01b                                    ";
         219 : dbg_instr = "PMBUS+0x01c                                    ";
         220 : dbg_instr = "PMBUS+0x01d                                    ";
         221 : dbg_instr = "PMBUS+0x01e                                    ";
         222 : dbg_instr = "PMBUS+0x01f                                    ";
         223 : dbg_instr = "PMBUS+0x020                                    ";
         224 : dbg_instr = "PMBUS+0x021                                    ";
         225 : dbg_instr = "PMBUS+0x022                                    ";
         226 : dbg_instr = "PMBUS+0x023                                    ";
         227 : dbg_instr = "PMBUS+0x024                                    ";
         228 : dbg_instr = "PMBUS+0x025                                    ";
         229 : dbg_instr = "PMBUS+0x026                                    ";
         230 : dbg_instr = "PMBUS+0x027                                    ";
         231 : dbg_instr = "PMBUS+0x028                                    ";
         232 : dbg_instr = "PMBUS+0x029                                    ";
         233 : dbg_instr = "PMBUS+0x02a                                    ";
         234 : dbg_instr = "PMBUS+0x02b                                    ";
         235 : dbg_instr = "PMBUS+0x02c                                    ";
         236 : dbg_instr = "PMBUS+0x02d                                    ";
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
         301 : dbg_instr = "do_PingPong                                    ";
         302 : dbg_instr = "do_PingPong+0x001                              ";
         303 : dbg_instr = "do_Statistics                                  ";
         304 : dbg_instr = "do_Statistics+0x001                            ";
         305 : dbg_instr = "do_Statistics+0x002                            ";
         306 : dbg_instr = "do_Statistics+0x003                            ";
         307 : dbg_instr = "do_Statistics+0x004                            ";
         308 : dbg_instr = "do_Statistics+0x005                            ";
         309 : dbg_instr = "do_Statistics+0x006                            ";
         310 : dbg_instr = "do_Statistics+0x007                            ";
         311 : dbg_instr = "do_Statistics+0x008                            ";
         312 : dbg_instr = "do_Statistics+0x009                            ";
         313 : dbg_instr = "do_Statistics+0x00a                            ";
         314 : dbg_instr = "do_Statistics+0x00b                            ";
         315 : dbg_instr = "do_Statistics+0x00c                            ";
         316 : dbg_instr = "do_Statistics+0x00d                            ";
         317 : dbg_instr = "do_Statistics+0x00e                            ";
         318 : dbg_instr = "do_Statistics+0x00f                            ";
         319 : dbg_instr = "do_Statistics+0x010                            ";
         320 : dbg_instr = "do_Statistics+0x011                            ";
         321 : dbg_instr = "do_Temps                                       ";
         322 : dbg_instr = "do_Temps+0x001                                 ";
         323 : dbg_instr = "do_Temps+0x002                                 ";
         324 : dbg_instr = "do_Temps+0x003                                 ";
         325 : dbg_instr = "do_Temps+0x004                                 ";
         326 : dbg_instr = "do_Temps+0x005                                 ";
         327 : dbg_instr = "do_Temps+0x006                                 ";
         328 : dbg_instr = "do_Temps+0x007                                 ";
         329 : dbg_instr = "do_Temps+0x008                                 ";
         330 : dbg_instr = "do_Temps+0x009                                 ";
         331 : dbg_instr = "do_Temps+0x00a                                 ";
         332 : dbg_instr = "do_Temps+0x00b                                 ";
         333 : dbg_instr = "do_Temps+0x00c                                 ";
         334 : dbg_instr = "do_Temps+0x00d                                 ";
         335 : dbg_instr = "do_Volts                                       ";
         336 : dbg_instr = "do_Volts+0x001                                 ";
         337 : dbg_instr = "do_Volts+0x002                                 ";
         338 : dbg_instr = "do_Volts+0x003                                 ";
         339 : dbg_instr = "do_Volts+0x004                                 ";
         340 : dbg_instr = "do_Volts+0x005                                 ";
         341 : dbg_instr = "do_Volts+0x006                                 ";
         342 : dbg_instr = "do_Volts+0x007                                 ";
         343 : dbg_instr = "do_Volts+0x008                                 ";
         344 : dbg_instr = "do_Volts+0x009                                 ";
         345 : dbg_instr = "do_Volts+0x00a                                 ";
         346 : dbg_instr = "do_Volts+0x00b                                 ";
         347 : dbg_instr = "do_Volts+0x00c                                 ";
         348 : dbg_instr = "do_Volts+0x00d                                 ";
         349 : dbg_instr = "do_Currents                                    ";
         350 : dbg_instr = "do_Currents+0x001                              ";
         351 : dbg_instr = "do_Currents+0x002                              ";
         352 : dbg_instr = "do_Currents+0x003                              ";
         353 : dbg_instr = "do_Currents+0x004                              ";
         354 : dbg_instr = "do_Currents+0x005                              ";
         355 : dbg_instr = "do_Currents+0x006                              ";
         356 : dbg_instr = "do_Currents+0x007                              ";
         357 : dbg_instr = "do_Currents+0x008                              ";
         358 : dbg_instr = "do_Currents+0x009                              ";
         359 : dbg_instr = "do_Currents+0x00a                              ";
         360 : dbg_instr = "do_Currents+0x00b                              ";
         361 : dbg_instr = "do_Currents+0x00c                              ";
         362 : dbg_instr = "do_Currents+0x00d                              ";
         363 : dbg_instr = "do_Enable                                      ";
         364 : dbg_instr = "do_Enable+0x001                                ";
         365 : dbg_instr = "do_Enable+0x002                                ";
         366 : dbg_instr = "do_Enable+0x003                                ";
         367 : dbg_instr = "do_Enable+0x004                                ";
         368 : dbg_instr = "do_Enable+0x005                                ";
         369 : dbg_instr = "do_Enable+0x006                                ";
         370 : dbg_instr = "do_Enable+0x007                                ";
         371 : dbg_instr = "do_Enable+0x008                                ";
         372 : dbg_instr = "do_Enable+0x009                                ";
         373 : dbg_instr = "do_Enable+0x00a                                ";
         374 : dbg_instr = "do_Enable+0x00b                                ";
         375 : dbg_instr = "do_Enable+0x00c                                ";
         376 : dbg_instr = "do_Enable+0x00d                                ";
         377 : dbg_instr = "do_Enable+0x00e                                ";
         378 : dbg_instr = "do_Enable+0x00f                                ";
         379 : dbg_instr = "do_Enable+0x010                                ";
         380 : dbg_instr = "do_Enable+0x011                                ";
         381 : dbg_instr = "do_Enable+0x012                                ";
         382 : dbg_instr = "do_Enable+0x013                                ";
         383 : dbg_instr = "do_Enable+0x014                                ";
         384 : dbg_instr = "do_PMBus                                       ";
         385 : dbg_instr = "do_PMBus+0x001                                 ";
         386 : dbg_instr = "do_PMBus+0x002                                 ";
         387 : dbg_instr = "do_PMBus+0x003                                 ";
         388 : dbg_instr = "do_PMBus+0x004                                 ";
         389 : dbg_instr = "do_PMBus+0x005                                 ";
         390 : dbg_instr = "do_PMBus+0x006                                 ";
         391 : dbg_instr = "do_PMBus+0x007                                 ";
         392 : dbg_instr = "do_PMBus+0x008                                 ";
         393 : dbg_instr = "do_PMBus+0x009                                 ";
         394 : dbg_instr = "do_PMBus+0x00a                                 ";
         395 : dbg_instr = "PMBus_Write                                    ";
         396 : dbg_instr = "PMBus_Write+0x001                              ";
         397 : dbg_instr = "PMBus_Write+0x002                              ";
         398 : dbg_instr = "PMBus_Write+0x003                              ";
         399 : dbg_instr = "PMBus_Write+0x004                              ";
         400 : dbg_instr = "PMBus_Write+0x005                              ";
         401 : dbg_instr = "PMBus_Write+0x006                              ";
         402 : dbg_instr = "PMBus_Write+0x007                              ";
         403 : dbg_instr = "PMBus_Write+0x008                              ";
         404 : dbg_instr = "PMBus_Write+0x009                              ";
         405 : dbg_instr = "PMBus_Write+0x00a                              ";
         406 : dbg_instr = "PMBus_Write+0x00b                              ";
         407 : dbg_instr = "PMBus_Write+0x00c                              ";
         408 : dbg_instr = "PMBus_Write+0x00d                              ";
         409 : dbg_instr = "PMBus_Write+0x00e                              ";
         410 : dbg_instr = "PMBus_Read                                     ";
         411 : dbg_instr = "PMBus_Read+0x001                               ";
         412 : dbg_instr = "PMBus_Read+0x002                               ";
         413 : dbg_instr = "PMBus_Read+0x003                               ";
         414 : dbg_instr = "PMBus_Read+0x004                               ";
         415 : dbg_instr = "PMBus_Read+0x005                               ";
         416 : dbg_instr = "PMBus_Read+0x006                               ";
         417 : dbg_instr = "PMBus_Read+0x007                               ";
         418 : dbg_instr = "PMBus_Read+0x008                               ";
         419 : dbg_instr = "PMBus_Read+0x009                               ";
         420 : dbg_instr = "PMBus_Read+0x00a                               ";
         421 : dbg_instr = "PMBus_Read+0x00b                               ";
         422 : dbg_instr = "PMBus_Read+0x00c                               ";
         423 : dbg_instr = "PMBus_Read+0x00d                               ";
         424 : dbg_instr = "PMBus_Read+0x00e                               ";
         425 : dbg_instr = "PMBus_Read+0x00f                               ";
         426 : dbg_instr = "PMBus_Read+0x010                               ";
         427 : dbg_instr = "PMBus_Read+0x011                               ";
         428 : dbg_instr = "do_Identify                                    ";
         429 : dbg_instr = "do_Identify+0x001                              ";
         430 : dbg_instr = "do_Identify+0x002                              ";
         431 : dbg_instr = "do_Identify+0x003                              ";
         432 : dbg_instr = "do_Identify+0x004                              ";
         433 : dbg_instr = "do_Identify+0x005                              ";
         434 : dbg_instr = "do_Identify+0x006                              ";
         435 : dbg_instr = "do_Identify+0x007                              ";
         436 : dbg_instr = "finishPacket                                   ";
         437 : dbg_instr = "finishPacket+0x001                             ";
         438 : dbg_instr = "finishPacket+0x002                             ";
         439 : dbg_instr = "goodPacket                                     ";
         440 : dbg_instr = "goodPacket+0x001                               ";
         441 : dbg_instr = "goodPacket+0x002                               ";
         442 : dbg_instr = "goodPacket+0x003                               ";
         443 : dbg_instr = "fetchAndIncrement                              ";
         444 : dbg_instr = "fetchAndIncrement+0x001                        ";
         445 : dbg_instr = "fetchAndIncrement+0x002                        ";
         446 : dbg_instr = "fetchAndIncrement+0x003                        ";
         447 : dbg_instr = "skippedPacket                                  ";
         448 : dbg_instr = "skippedPacket+0x001                            ";
         449 : dbg_instr = "droppedPacket                                  ";
         450 : dbg_instr = "droppedPacket+0x001                            ";
         451 : dbg_instr = "errorPacket                                    ";
         452 : dbg_instr = "errorPacket+0x001                              ";
         453 : dbg_instr = "hsk_header                                     ";
         454 : dbg_instr = "hsk_header+0x001                               ";
         455 : dbg_instr = "hsk_header+0x002                               ";
         456 : dbg_instr = "hsk_header+0x003                               ";
         457 : dbg_instr = "hsk_copy4                                      ";
         458 : dbg_instr = "hsk_copy2                                      ";
         459 : dbg_instr = "hsk_copy1                                      ";
         460 : dbg_instr = "hsk_copy1+0x001                                ";
         461 : dbg_instr = "hsk_copy1+0x002                                ";
         462 : dbg_instr = "hsk_copy1+0x003                                ";
         463 : dbg_instr = "hsk_copy1+0x004                                ";
         464 : dbg_instr = "hsk_copy1+0x005                                ";
         465 : dbg_instr = "I2C_delay_hclk                                 ";
         466 : dbg_instr = "I2C_delay_med                                  ";
         467 : dbg_instr = "I2C_delay_med+0x001                            ";
         468 : dbg_instr = "I2C_delay_med+0x002                            ";
         469 : dbg_instr = "I2C_delay_short                                ";
         470 : dbg_instr = "I2C_delay_short+0x001                          ";
         471 : dbg_instr = "I2C_delay_short+0x002                          ";
         472 : dbg_instr = "I2C_delay_short+0x003                          ";
         473 : dbg_instr = "I2C_delay_short+0x004                          ";
         474 : dbg_instr = "I2C_delay_short+0x005                          ";
         475 : dbg_instr = "I2C_Rx_bit                                     ";
         476 : dbg_instr = "I2C_Rx_bit+0x001                               ";
         477 : dbg_instr = "I2C_Rx_bit+0x002                               ";
         478 : dbg_instr = "I2C_Rx_bit+0x003                               ";
         479 : dbg_instr = "I2C_Rx_bit+0x004                               ";
         480 : dbg_instr = "I2C_Rx_bit+0x005                               ";
         481 : dbg_instr = "I2C_Rx_bit+0x006                               ";
         482 : dbg_instr = "I2C_Rx_bit+0x007                               ";
         483 : dbg_instr = "I2C_stop                                       ";
         484 : dbg_instr = "I2C_stop+0x001                                 ";
         485 : dbg_instr = "I2C_stop+0x002                                 ";
         486 : dbg_instr = "I2C_stop+0x003                                 ";
         487 : dbg_instr = "I2C_stop+0x004                                 ";
         488 : dbg_instr = "I2C_stop+0x005                                 ";
         489 : dbg_instr = "I2C_stop+0x006                                 ";
         490 : dbg_instr = "I2C_start                                      ";
         491 : dbg_instr = "I2C_start+0x001                                ";
         492 : dbg_instr = "I2C_start+0x002                                ";
         493 : dbg_instr = "I2C_start+0x003                                ";
         494 : dbg_instr = "I2C_start+0x004                                ";
         495 : dbg_instr = "I2C_start+0x005                                ";
         496 : dbg_instr = "I2C_start+0x006                                ";
         497 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK                         ";
         498 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x001                   ";
         499 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x002                   ";
         500 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x003                   ";
         501 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x004                   ";
         502 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x005                   ";
         503 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x006                   ";
         504 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x007                   ";
         505 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x008                   ";
         506 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x009                   ";
         507 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00a                   ";
         508 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00b                   ";
         509 : dbg_instr = "I2C_Rx_byte                                    ";
         510 : dbg_instr = "I2C_Rx_byte+0x001                              ";
         511 : dbg_instr = "I2C_Rx_byte+0x002                              ";
         512 : dbg_instr = "I2C_Rx_byte+0x003                              ";
         513 : dbg_instr = "I2C_Rx_byte+0x004                              ";
         514 : dbg_instr = "I2C_test                                       ";
         515 : dbg_instr = "I2C_test+0x001                                 ";
         516 : dbg_instr = "I2C_test+0x002                                 ";
         517 : dbg_instr = "I2C_test+0x003                                 ";
         518 : dbg_instr = "I2C_user_tx_process                            ";
         519 : dbg_instr = "I2C_user_tx_process+0x001                      ";
         520 : dbg_instr = "I2C_user_tx_process+0x002                      ";
         521 : dbg_instr = "I2C_user_tx_process+0x003                      ";
         522 : dbg_instr = "I2C_user_tx_process+0x004                      ";
         523 : dbg_instr = "I2C_user_tx_process+0x005                      ";
         524 : dbg_instr = "I2C_user_tx_process+0x006                      ";
         525 : dbg_instr = "I2C_send3                                      ";
         526 : dbg_instr = "I2C_send3+0x001                                ";
         527 : dbg_instr = "I2C_send3+0x002                                ";
         528 : dbg_instr = "I2C_send1_prcs                                 ";
         529 : dbg_instr = "I2C_send1_prcs+0x001                           ";
         530 : dbg_instr = "I2C_send1_prcs+0x002                           ";
         531 : dbg_instr = "I2C_send1_prcs+0x003                           ";
         532 : dbg_instr = "I2C_send1_prcs+0x004                           ";
         533 : dbg_instr = "I2C_turfio_initialize                          ";
         534 : dbg_instr = "I2C_turfio_initialize+0x001                    ";
         535 : dbg_instr = "I2C_turfio_initialize+0x002                    ";
         536 : dbg_instr = "I2C_turfio_initialize+0x003                    ";
         537 : dbg_instr = "I2C_turfio_initialize+0x004                    ";
         538 : dbg_instr = "I2C_surf_initialize                            ";
         539 : dbg_instr = "I2C_surf_initialize+0x001                      ";
         540 : dbg_instr = "I2C_surf_initialize+0x002                      ";
         541 : dbg_instr = "I2C_surf_initialize+0x003                      ";
         542 : dbg_instr = "I2C_surf_initialize+0x004                      ";
         543 : dbg_instr = "I2C_surf_initialize+0x005                      ";
         544 : dbg_instr = "I2C_surf_initialize+0x006                      ";
         545 : dbg_instr = "I2C_surf_initialize+0x007                      ";
         546 : dbg_instr = "I2C_surf_initialize+0x008                      ";
         547 : dbg_instr = "I2C_surf_initialize+0x009                      ";
         548 : dbg_instr = "I2C_read_register                              ";
         549 : dbg_instr = "I2C_read_register+0x001                        ";
         550 : dbg_instr = "I2C_read_register+0x002                        ";
         551 : dbg_instr = "I2C_read_register+0x003                        ";
         552 : dbg_instr = "I2C_read_register+0x004                        ";
         553 : dbg_instr = "I2C_read                                       ";
         554 : dbg_instr = "I2C_read+0x001                                 ";
         555 : dbg_instr = "I2C_read+0x002                                 ";
         556 : dbg_instr = "I2C_read+0x003                                 ";
         557 : dbg_instr = "I2C_read+0x004                                 ";
         558 : dbg_instr = "I2C_read+0x005                                 ";
         559 : dbg_instr = "I2C_read+0x006                                 ";
         560 : dbg_instr = "I2C_read+0x007                                 ";
         561 : dbg_instr = "I2C_read+0x008                                 ";
         562 : dbg_instr = "I2C_read+0x009                                 ";
         563 : dbg_instr = "I2C_read+0x00a                                 ";
         564 : dbg_instr = "I2C_read+0x00b                                 ";
         565 : dbg_instr = "I2C_read+0x00c                                 ";
         566 : dbg_instr = "I2C_read+0x00d                                 ";
         567 : dbg_instr = "I2C_read+0x00e                                 ";
         568 : dbg_instr = "I2C_read+0x00f                                 ";
         569 : dbg_instr = "I2C_read+0x010                                 ";
         570 : dbg_instr = "I2C_read+0x011                                 ";
         571 : dbg_instr = "I2C_read+0x012                                 ";
         572 : dbg_instr = "cobsFindZero                                   ";
         573 : dbg_instr = "cobsFindZero+0x001                             ";
         574 : dbg_instr = "cobsFindZero+0x002                             ";
         575 : dbg_instr = "cobsFindZero+0x003                             ";
         576 : dbg_instr = "cobsFindZero+0x004                             ";
         577 : dbg_instr = "cobsFindZero+0x005                             ";
         578 : dbg_instr = "cobsFindZero+0x006                             ";
         579 : dbg_instr = "cobsFindZero+0x007                             ";
         580 : dbg_instr = "cobsFixZero                                    ";
         581 : dbg_instr = "cobsFixZero+0x001                              ";
         582 : dbg_instr = "cobsFixZero+0x002                              ";
         583 : dbg_instr = "cobsFixZero+0x003                              ";
         584 : dbg_instr = "cobsFixZero+0x004                              ";
         585 : dbg_instr = "cobsEncode                                     ";
         586 : dbg_instr = "cobsEncode+0x001                               ";
         587 : dbg_instr = "cobsEncode+0x002                               ";
         588 : dbg_instr = "cobsEncode+0x003                               ";
         589 : dbg_instr = "cobsEncode+0x004                               ";
         590 : dbg_instr = "cobsEncode+0x005                               ";
         591 : dbg_instr = "cobsEncode+0x006                               ";
         592 : dbg_instr = "cobsEncode+0x007                               ";
         593 : dbg_instr = "cobsEncode+0x008                               ";
         594 : dbg_instr = "cobsEncode+0x009                               ";
         595 : dbg_instr = "cobsEncode+0x00a                               ";
         596 : dbg_instr = "cobsEncode+0x00b                               ";
         597 : dbg_instr = "cobsEncode+0x00c                               ";
         598 : dbg_instr = "cobsEncode+0x00d                               ";
         599 : dbg_instr = "cobsEncode+0x00e                               ";
         600 : dbg_instr = "cobsEncode+0x00f                               ";
         601 : dbg_instr = "cobsEncode+0x010                               ";
         602 : dbg_instr = "cobsEncode+0x011                               ";
         603 : dbg_instr = "cobsEncode+0x012                               ";
         604 : dbg_instr = "cobsEncode+0x013                               ";
         605 : dbg_instr = "cobsEncode+0x014                               ";
         606 : dbg_instr = "cobsEncode+0x015                               ";
         607 : dbg_instr = "cobsEncode+0x016                               ";
         608 : dbg_instr = "cobsEncode+0x017                               ";
         609 : dbg_instr = "cobsEncode+0x018                               ";
         610 : dbg_instr = "cobsEncode+0x019                               ";
         611 : dbg_instr = "cobsEncode+0x01a                               ";
         612 : dbg_instr = "cobsEncode+0x01b                               ";
         613 : dbg_instr = "cobsEncode+0x01c                               ";
         614 : dbg_instr = "cobsEncode+0x01d                               ";
         615 : dbg_instr = "cobsEncode+0x01e                               ";
         616 : dbg_instr = "cobsEncode+0x01f                               ";
         617 : dbg_instr = "cobsEncode+0x020                               ";
         618 : dbg_instr = "cobsEncode+0x021                               ";
         619 : dbg_instr = "cobsEncode+0x022                               ";
         620 : dbg_instr = "cobsEncode+0x023                               ";
         621 : dbg_instr = "cobsEncode+0x024                               ";
         622 : dbg_instr = "cobsEncode+0x025                               ";
         623 : dbg_instr = "cobsEncode+0x026                               ";
         624 : dbg_instr = "cobsEncode+0x027                               ";
         625 : dbg_instr = "cobsEncode+0x028                               ";
         626 : dbg_instr = "cobsEncode+0x029                               ";
         627 : dbg_instr = "cobsEncode+0x02a                               ";
         628 : dbg_instr = "cobsEncode+0x02b                               ";
         629 : dbg_instr = "cobsEncode+0x02c                               ";
         630 : dbg_instr = "cobsEncode+0x02d                               ";
         631 : dbg_instr = "cobsEncode+0x02e                               ";
         632 : dbg_instr = "cobsEncode+0x02f                               ";
         633 : dbg_instr = "cobsEncode+0x030                               ";
         634 : dbg_instr = "cobsEncode+0x031                               ";
         635 : dbg_instr = "cobsEncode+0x032                               ";
         636 : dbg_instr = "cobsEncode+0x033                               ";
         637 : dbg_instr = "cobsEncode+0x034                               ";
         638 : dbg_instr = "cobsEncode+0x035                               ";
         639 : dbg_instr = "cobsEncode+0x036                               ";
         640 : dbg_instr = "cobsEncode+0x037                               ";
         641 : dbg_instr = "cobsEncode+0x038                               ";
         642 : dbg_instr = "cobsEncode+0x039                               ";
         643 : dbg_instr = "cobsEncode+0x03a                               ";
         644 : dbg_instr = "cobsEncode+0x03b                               ";
         645 : dbg_instr = "cobsEncode+0x03c                               ";
         646 : dbg_instr = "cobsEncode+0x03d                               ";
         647 : dbg_instr = "cobsEncode+0x03e                               ";
         648 : dbg_instr = "cobsEncode+0x03f                               ";
         649 : dbg_instr = "cobsEncode+0x040                               ";
         650 : dbg_instr = "cobsEncode+0x041                               ";
         651 : dbg_instr = "cobsEncode+0x042                               ";
         652 : dbg_instr = "cobsEncode+0x043                               ";
         653 : dbg_instr = "cobsEncode+0x044                               ";
         654 : dbg_instr = "cobsEncode+0x045                               ";
         655 : dbg_instr = "cobsEncode+0x046                               ";
         656 : dbg_instr = "cobsEncode+0x047                               ";
         657 : dbg_instr = "cobsEncode+0x048                               ";
         658 : dbg_instr = "cobsEncode+0x049                               ";
         659 : dbg_instr = "cobsEncode+0x04a                               ";
         660 : dbg_instr = "cobsEncode+0x04b                               ";
         661 : dbg_instr = "cobsEncode+0x04c                               ";
         662 : dbg_instr = "cobsEncode+0x04d                               ";
         663 : dbg_instr = "cobsEncode+0x04e                               ";
         664 : dbg_instr = "cobsEncode+0x04f                               ";
         665 : dbg_instr = "cobsEncode+0x050                               ";
         666 : dbg_instr = "cobsEncode+0x051                               ";
         667 : dbg_instr = "cobsEncode+0x052                               ";
         668 : dbg_instr = "cobsEncode+0x053                               ";
         669 : dbg_instr = "cobsEncode+0x054                               ";
         670 : dbg_instr = "cobsEncode+0x055                               ";
         671 : dbg_instr = "cobsEncode+0x056                               ";
         672 : dbg_instr = "cobsEncode+0x057                               ";
         673 : dbg_instr = "cobsEncode+0x058                               ";
         674 : dbg_instr = "cobsEncode+0x059                               ";
         675 : dbg_instr = "cobsEncode+0x05a                               ";
         676 : dbg_instr = "cobsEncode+0x05b                               ";
         677 : dbg_instr = "cobsEncode+0x05c                               ";
         678 : dbg_instr = "cobsEncode+0x05d                               ";
         679 : dbg_instr = "cobsEncode+0x05e                               ";
         680 : dbg_instr = "cobsEncode+0x05f                               ";
         681 : dbg_instr = "cobsEncode+0x060                               ";
         682 : dbg_instr = "cobsEncode+0x061                               ";
         683 : dbg_instr = "cobsEncode+0x062                               ";
         684 : dbg_instr = "cobsEncode+0x063                               ";
         685 : dbg_instr = "cobsEncode+0x064                               ";
         686 : dbg_instr = "cobsEncode+0x065                               ";
         687 : dbg_instr = "cobsEncode+0x066                               ";
         688 : dbg_instr = "cobsEncode+0x067                               ";
         689 : dbg_instr = "cobsEncode+0x068                               ";
         690 : dbg_instr = "cobsEncode+0x069                               ";
         691 : dbg_instr = "cobsEncode+0x06a                               ";
         692 : dbg_instr = "cobsEncode+0x06b                               ";
         693 : dbg_instr = "cobsEncode+0x06c                               ";
         694 : dbg_instr = "cobsEncode+0x06d                               ";
         695 : dbg_instr = "cobsEncode+0x06e                               ";
         696 : dbg_instr = "cobsEncode+0x06f                               ";
         697 : dbg_instr = "cobsEncode+0x070                               ";
         698 : dbg_instr = "cobsEncode+0x071                               ";
         699 : dbg_instr = "cobsEncode+0x072                               ";
         700 : dbg_instr = "cobsEncode+0x073                               ";
         701 : dbg_instr = "cobsEncode+0x074                               ";
         702 : dbg_instr = "cobsEncode+0x075                               ";
         703 : dbg_instr = "cobsEncode+0x076                               ";
         704 : dbg_instr = "cobsEncode+0x077                               ";
         705 : dbg_instr = "cobsEncode+0x078                               ";
         706 : dbg_instr = "cobsEncode+0x079                               ";
         707 : dbg_instr = "cobsEncode+0x07a                               ";
         708 : dbg_instr = "cobsEncode+0x07b                               ";
         709 : dbg_instr = "cobsEncode+0x07c                               ";
         710 : dbg_instr = "cobsEncode+0x07d                               ";
         711 : dbg_instr = "cobsEncode+0x07e                               ";
         712 : dbg_instr = "cobsEncode+0x07f                               ";
         713 : dbg_instr = "cobsEncode+0x080                               ";
         714 : dbg_instr = "cobsEncode+0x081                               ";
         715 : dbg_instr = "cobsEncode+0x082                               ";
         716 : dbg_instr = "cobsEncode+0x083                               ";
         717 : dbg_instr = "cobsEncode+0x084                               ";
         718 : dbg_instr = "cobsEncode+0x085                               ";
         719 : dbg_instr = "cobsEncode+0x086                               ";
         720 : dbg_instr = "cobsEncode+0x087                               ";
         721 : dbg_instr = "cobsEncode+0x088                               ";
         722 : dbg_instr = "cobsEncode+0x089                               ";
         723 : dbg_instr = "cobsEncode+0x08a                               ";
         724 : dbg_instr = "cobsEncode+0x08b                               ";
         725 : dbg_instr = "cobsEncode+0x08c                               ";
         726 : dbg_instr = "cobsEncode+0x08d                               ";
         727 : dbg_instr = "cobsEncode+0x08e                               ";
         728 : dbg_instr = "cobsEncode+0x08f                               ";
         729 : dbg_instr = "cobsEncode+0x090                               ";
         730 : dbg_instr = "cobsEncode+0x091                               ";
         731 : dbg_instr = "cobsEncode+0x092                               ";
         732 : dbg_instr = "cobsEncode+0x093                               ";
         733 : dbg_instr = "cobsEncode+0x094                               ";
         734 : dbg_instr = "cobsEncode+0x095                               ";
         735 : dbg_instr = "cobsEncode+0x096                               ";
         736 : dbg_instr = "cobsEncode+0x097                               ";
         737 : dbg_instr = "cobsEncode+0x098                               ";
         738 : dbg_instr = "cobsEncode+0x099                               ";
         739 : dbg_instr = "cobsEncode+0x09a                               ";
         740 : dbg_instr = "cobsEncode+0x09b                               ";
         741 : dbg_instr = "cobsEncode+0x09c                               ";
         742 : dbg_instr = "cobsEncode+0x09d                               ";
         743 : dbg_instr = "cobsEncode+0x09e                               ";
         744 : dbg_instr = "cobsEncode+0x09f                               ";
         745 : dbg_instr = "cobsEncode+0x0a0                               ";
         746 : dbg_instr = "cobsEncode+0x0a1                               ";
         747 : dbg_instr = "cobsEncode+0x0a2                               ";
         748 : dbg_instr = "cobsEncode+0x0a3                               ";
         749 : dbg_instr = "cobsEncode+0x0a4                               ";
         750 : dbg_instr = "cobsEncode+0x0a5                               ";
         751 : dbg_instr = "cobsEncode+0x0a6                               ";
         752 : dbg_instr = "cobsEncode+0x0a7                               ";
         753 : dbg_instr = "cobsEncode+0x0a8                               ";
         754 : dbg_instr = "cobsEncode+0x0a9                               ";
         755 : dbg_instr = "cobsEncode+0x0aa                               ";
         756 : dbg_instr = "cobsEncode+0x0ab                               ";
         757 : dbg_instr = "cobsEncode+0x0ac                               ";
         758 : dbg_instr = "cobsEncode+0x0ad                               ";
         759 : dbg_instr = "cobsEncode+0x0ae                               ";
         760 : dbg_instr = "cobsEncode+0x0af                               ";
         761 : dbg_instr = "cobsEncode+0x0b0                               ";
         762 : dbg_instr = "cobsEncode+0x0b1                               ";
         763 : dbg_instr = "cobsEncode+0x0b2                               ";
         764 : dbg_instr = "cobsEncode+0x0b3                               ";
         765 : dbg_instr = "cobsEncode+0x0b4                               ";
         766 : dbg_instr = "cobsEncode+0x0b5                               ";
         767 : dbg_instr = "cobsEncode+0x0b6                               ";
         768 : dbg_instr = "cobsEncode+0x0b7                               ";
         769 : dbg_instr = "cobsEncode+0x0b8                               ";
         770 : dbg_instr = "cobsEncode+0x0b9                               ";
         771 : dbg_instr = "cobsEncode+0x0ba                               ";
         772 : dbg_instr = "cobsEncode+0x0bb                               ";
         773 : dbg_instr = "cobsEncode+0x0bc                               ";
         774 : dbg_instr = "cobsEncode+0x0bd                               ";
         775 : dbg_instr = "cobsEncode+0x0be                               ";
         776 : dbg_instr = "cobsEncode+0x0bf                               ";
         777 : dbg_instr = "cobsEncode+0x0c0                               ";
         778 : dbg_instr = "cobsEncode+0x0c1                               ";
         779 : dbg_instr = "cobsEncode+0x0c2                               ";
         780 : dbg_instr = "cobsEncode+0x0c3                               ";
         781 : dbg_instr = "cobsEncode+0x0c4                               ";
         782 : dbg_instr = "cobsEncode+0x0c5                               ";
         783 : dbg_instr = "cobsEncode+0x0c6                               ";
         784 : dbg_instr = "cobsEncode+0x0c7                               ";
         785 : dbg_instr = "cobsEncode+0x0c8                               ";
         786 : dbg_instr = "cobsEncode+0x0c9                               ";
         787 : dbg_instr = "cobsEncode+0x0ca                               ";
         788 : dbg_instr = "cobsEncode+0x0cb                               ";
         789 : dbg_instr = "cobsEncode+0x0cc                               ";
         790 : dbg_instr = "cobsEncode+0x0cd                               ";
         791 : dbg_instr = "cobsEncode+0x0ce                               ";
         792 : dbg_instr = "cobsEncode+0x0cf                               ";
         793 : dbg_instr = "cobsEncode+0x0d0                               ";
         794 : dbg_instr = "cobsEncode+0x0d1                               ";
         795 : dbg_instr = "cobsEncode+0x0d2                               ";
         796 : dbg_instr = "cobsEncode+0x0d3                               ";
         797 : dbg_instr = "cobsEncode+0x0d4                               ";
         798 : dbg_instr = "cobsEncode+0x0d5                               ";
         799 : dbg_instr = "cobsEncode+0x0d6                               ";
         800 : dbg_instr = "cobsEncode+0x0d7                               ";
         801 : dbg_instr = "cobsEncode+0x0d8                               ";
         802 : dbg_instr = "cobsEncode+0x0d9                               ";
         803 : dbg_instr = "cobsEncode+0x0da                               ";
         804 : dbg_instr = "cobsEncode+0x0db                               ";
         805 : dbg_instr = "cobsEncode+0x0dc                               ";
         806 : dbg_instr = "cobsEncode+0x0dd                               ";
         807 : dbg_instr = "cobsEncode+0x0de                               ";
         808 : dbg_instr = "cobsEncode+0x0df                               ";
         809 : dbg_instr = "cobsEncode+0x0e0                               ";
         810 : dbg_instr = "cobsEncode+0x0e1                               ";
         811 : dbg_instr = "cobsEncode+0x0e2                               ";
         812 : dbg_instr = "cobsEncode+0x0e3                               ";
         813 : dbg_instr = "cobsEncode+0x0e4                               ";
         814 : dbg_instr = "cobsEncode+0x0e5                               ";
         815 : dbg_instr = "cobsEncode+0x0e6                               ";
         816 : dbg_instr = "cobsEncode+0x0e7                               ";
         817 : dbg_instr = "cobsEncode+0x0e8                               ";
         818 : dbg_instr = "cobsEncode+0x0e9                               ";
         819 : dbg_instr = "cobsEncode+0x0ea                               ";
         820 : dbg_instr = "cobsEncode+0x0eb                               ";
         821 : dbg_instr = "cobsEncode+0x0ec                               ";
         822 : dbg_instr = "cobsEncode+0x0ed                               ";
         823 : dbg_instr = "cobsEncode+0x0ee                               ";
         824 : dbg_instr = "cobsEncode+0x0ef                               ";
         825 : dbg_instr = "cobsEncode+0x0f0                               ";
         826 : dbg_instr = "cobsEncode+0x0f1                               ";
         827 : dbg_instr = "cobsEncode+0x0f2                               ";
         828 : dbg_instr = "cobsEncode+0x0f3                               ";
         829 : dbg_instr = "cobsEncode+0x0f4                               ";
         830 : dbg_instr = "cobsEncode+0x0f5                               ";
         831 : dbg_instr = "cobsEncode+0x0f6                               ";
         832 : dbg_instr = "cobsEncode+0x0f7                               ";
         833 : dbg_instr = "cobsEncode+0x0f8                               ";
         834 : dbg_instr = "cobsEncode+0x0f9                               ";
         835 : dbg_instr = "cobsEncode+0x0fa                               ";
         836 : dbg_instr = "cobsEncode+0x0fb                               ";
         837 : dbg_instr = "cobsEncode+0x0fc                               ";
         838 : dbg_instr = "cobsEncode+0x0fd                               ";
         839 : dbg_instr = "cobsEncode+0x0fe                               ";
         840 : dbg_instr = "cobsEncode+0x0ff                               ";
         841 : dbg_instr = "cobsEncode+0x100                               ";
         842 : dbg_instr = "cobsEncode+0x101                               ";
         843 : dbg_instr = "cobsEncode+0x102                               ";
         844 : dbg_instr = "cobsEncode+0x103                               ";
         845 : dbg_instr = "cobsEncode+0x104                               ";
         846 : dbg_instr = "cobsEncode+0x105                               ";
         847 : dbg_instr = "cobsEncode+0x106                               ";
         848 : dbg_instr = "cobsEncode+0x107                               ";
         849 : dbg_instr = "cobsEncode+0x108                               ";
         850 : dbg_instr = "cobsEncode+0x109                               ";
         851 : dbg_instr = "cobsEncode+0x10a                               ";
         852 : dbg_instr = "cobsEncode+0x10b                               ";
         853 : dbg_instr = "cobsEncode+0x10c                               ";
         854 : dbg_instr = "cobsEncode+0x10d                               ";
         855 : dbg_instr = "cobsEncode+0x10e                               ";
         856 : dbg_instr = "cobsEncode+0x10f                               ";
         857 : dbg_instr = "cobsEncode+0x110                               ";
         858 : dbg_instr = "cobsEncode+0x111                               ";
         859 : dbg_instr = "cobsEncode+0x112                               ";
         860 : dbg_instr = "cobsEncode+0x113                               ";
         861 : dbg_instr = "cobsEncode+0x114                               ";
         862 : dbg_instr = "cobsEncode+0x115                               ";
         863 : dbg_instr = "cobsEncode+0x116                               ";
         864 : dbg_instr = "cobsEncode+0x117                               ";
         865 : dbg_instr = "cobsEncode+0x118                               ";
         866 : dbg_instr = "cobsEncode+0x119                               ";
         867 : dbg_instr = "cobsEncode+0x11a                               ";
         868 : dbg_instr = "cobsEncode+0x11b                               ";
         869 : dbg_instr = "cobsEncode+0x11c                               ";
         870 : dbg_instr = "cobsEncode+0x11d                               ";
         871 : dbg_instr = "cobsEncode+0x11e                               ";
         872 : dbg_instr = "cobsEncode+0x11f                               ";
         873 : dbg_instr = "cobsEncode+0x120                               ";
         874 : dbg_instr = "cobsEncode+0x121                               ";
         875 : dbg_instr = "cobsEncode+0x122                               ";
         876 : dbg_instr = "cobsEncode+0x123                               ";
         877 : dbg_instr = "cobsEncode+0x124                               ";
         878 : dbg_instr = "cobsEncode+0x125                               ";
         879 : dbg_instr = "cobsEncode+0x126                               ";
         880 : dbg_instr = "cobsEncode+0x127                               ";
         881 : dbg_instr = "cobsEncode+0x128                               ";
         882 : dbg_instr = "cobsEncode+0x129                               ";
         883 : dbg_instr = "cobsEncode+0x12a                               ";
         884 : dbg_instr = "cobsEncode+0x12b                               ";
         885 : dbg_instr = "cobsEncode+0x12c                               ";
         886 : dbg_instr = "cobsEncode+0x12d                               ";
         887 : dbg_instr = "cobsEncode+0x12e                               ";
         888 : dbg_instr = "cobsEncode+0x12f                               ";
         889 : dbg_instr = "cobsEncode+0x130                               ";
         890 : dbg_instr = "cobsEncode+0x131                               ";
         891 : dbg_instr = "cobsEncode+0x132                               ";
         892 : dbg_instr = "cobsEncode+0x133                               ";
         893 : dbg_instr = "cobsEncode+0x134                               ";
         894 : dbg_instr = "cobsEncode+0x135                               ";
         895 : dbg_instr = "cobsEncode+0x136                               ";
         896 : dbg_instr = "cobsEncode+0x137                               ";
         897 : dbg_instr = "cobsEncode+0x138                               ";
         898 : dbg_instr = "cobsEncode+0x139                               ";
         899 : dbg_instr = "cobsEncode+0x13a                               ";
         900 : dbg_instr = "cobsEncode+0x13b                               ";
         901 : dbg_instr = "cobsEncode+0x13c                               ";
         902 : dbg_instr = "cobsEncode+0x13d                               ";
         903 : dbg_instr = "cobsEncode+0x13e                               ";
         904 : dbg_instr = "cobsEncode+0x13f                               ";
         905 : dbg_instr = "cobsEncode+0x140                               ";
         906 : dbg_instr = "cobsEncode+0x141                               ";
         907 : dbg_instr = "cobsEncode+0x142                               ";
         908 : dbg_instr = "cobsEncode+0x143                               ";
         909 : dbg_instr = "cobsEncode+0x144                               ";
         910 : dbg_instr = "cobsEncode+0x145                               ";
         911 : dbg_instr = "cobsEncode+0x146                               ";
         912 : dbg_instr = "cobsEncode+0x147                               ";
         913 : dbg_instr = "cobsEncode+0x148                               ";
         914 : dbg_instr = "cobsEncode+0x149                               ";
         915 : dbg_instr = "cobsEncode+0x14a                               ";
         916 : dbg_instr = "cobsEncode+0x14b                               ";
         917 : dbg_instr = "cobsEncode+0x14c                               ";
         918 : dbg_instr = "cobsEncode+0x14d                               ";
         919 : dbg_instr = "cobsEncode+0x14e                               ";
         920 : dbg_instr = "cobsEncode+0x14f                               ";
         921 : dbg_instr = "cobsEncode+0x150                               ";
         922 : dbg_instr = "cobsEncode+0x151                               ";
         923 : dbg_instr = "cobsEncode+0x152                               ";
         924 : dbg_instr = "cobsEncode+0x153                               ";
         925 : dbg_instr = "cobsEncode+0x154                               ";
         926 : dbg_instr = "cobsEncode+0x155                               ";
         927 : dbg_instr = "cobsEncode+0x156                               ";
         928 : dbg_instr = "cobsEncode+0x157                               ";
         929 : dbg_instr = "cobsEncode+0x158                               ";
         930 : dbg_instr = "cobsEncode+0x159                               ";
         931 : dbg_instr = "cobsEncode+0x15a                               ";
         932 : dbg_instr = "cobsEncode+0x15b                               ";
         933 : dbg_instr = "cobsEncode+0x15c                               ";
         934 : dbg_instr = "cobsEncode+0x15d                               ";
         935 : dbg_instr = "cobsEncode+0x15e                               ";
         936 : dbg_instr = "cobsEncode+0x15f                               ";
         937 : dbg_instr = "cobsEncode+0x160                               ";
         938 : dbg_instr = "cobsEncode+0x161                               ";
         939 : dbg_instr = "cobsEncode+0x162                               ";
         940 : dbg_instr = "cobsEncode+0x163                               ";
         941 : dbg_instr = "cobsEncode+0x164                               ";
         942 : dbg_instr = "cobsEncode+0x165                               ";
         943 : dbg_instr = "cobsEncode+0x166                               ";
         944 : dbg_instr = "cobsEncode+0x167                               ";
         945 : dbg_instr = "cobsEncode+0x168                               ";
         946 : dbg_instr = "cobsEncode+0x169                               ";
         947 : dbg_instr = "cobsEncode+0x16a                               ";
         948 : dbg_instr = "cobsEncode+0x16b                               ";
         949 : dbg_instr = "cobsEncode+0x16c                               ";
         950 : dbg_instr = "cobsEncode+0x16d                               ";
         951 : dbg_instr = "cobsEncode+0x16e                               ";
         952 : dbg_instr = "cobsEncode+0x16f                               ";
         953 : dbg_instr = "cobsEncode+0x170                               ";
         954 : dbg_instr = "cobsEncode+0x171                               ";
         955 : dbg_instr = "cobsEncode+0x172                               ";
         956 : dbg_instr = "cobsEncode+0x173                               ";
         957 : dbg_instr = "cobsEncode+0x174                               ";
         958 : dbg_instr = "cobsEncode+0x175                               ";
         959 : dbg_instr = "cobsEncode+0x176                               ";
         960 : dbg_instr = "cobsEncode+0x177                               ";
         961 : dbg_instr = "cobsEncode+0x178                               ";
         962 : dbg_instr = "cobsEncode+0x179                               ";
         963 : dbg_instr = "cobsEncode+0x17a                               ";
         964 : dbg_instr = "cobsEncode+0x17b                               ";
         965 : dbg_instr = "cobsEncode+0x17c                               ";
         966 : dbg_instr = "cobsEncode+0x17d                               ";
         967 : dbg_instr = "cobsEncode+0x17e                               ";
         968 : dbg_instr = "cobsEncode+0x17f                               ";
         969 : dbg_instr = "cobsEncode+0x180                               ";
         970 : dbg_instr = "cobsEncode+0x181                               ";
         971 : dbg_instr = "cobsEncode+0x182                               ";
         972 : dbg_instr = "cobsEncode+0x183                               ";
         973 : dbg_instr = "cobsEncode+0x184                               ";
         974 : dbg_instr = "cobsEncode+0x185                               ";
         975 : dbg_instr = "cobsEncode+0x186                               ";
         976 : dbg_instr = "cobsEncode+0x187                               ";
         977 : dbg_instr = "cobsEncode+0x188                               ";
         978 : dbg_instr = "cobsEncode+0x189                               ";
         979 : dbg_instr = "cobsEncode+0x18a                               ";
         980 : dbg_instr = "cobsEncode+0x18b                               ";
         981 : dbg_instr = "cobsEncode+0x18c                               ";
         982 : dbg_instr = "cobsEncode+0x18d                               ";
         983 : dbg_instr = "cobsEncode+0x18e                               ";
         984 : dbg_instr = "cobsEncode+0x18f                               ";
         985 : dbg_instr = "cobsEncode+0x190                               ";
         986 : dbg_instr = "cobsEncode+0x191                               ";
         987 : dbg_instr = "cobsEncode+0x192                               ";
         988 : dbg_instr = "cobsEncode+0x193                               ";
         989 : dbg_instr = "cobsEncode+0x194                               ";
         990 : dbg_instr = "cobsEncode+0x195                               ";
         991 : dbg_instr = "cobsEncode+0x196                               ";
         992 : dbg_instr = "cobsEncode+0x197                               ";
         993 : dbg_instr = "cobsEncode+0x198                               ";
         994 : dbg_instr = "cobsEncode+0x199                               ";
         995 : dbg_instr = "cobsEncode+0x19a                               ";
         996 : dbg_instr = "cobsEncode+0x19b                               ";
         997 : dbg_instr = "cobsEncode+0x19c                               ";
         998 : dbg_instr = "cobsEncode+0x19d                               ";
         999 : dbg_instr = "cobsEncode+0x19e                               ";
         1000 : dbg_instr = "cobsEncode+0x19f                               ";
         1001 : dbg_instr = "cobsEncode+0x1a0                               ";
         1002 : dbg_instr = "cobsEncode+0x1a1                               ";
         1003 : dbg_instr = "cobsEncode+0x1a2                               ";
         1004 : dbg_instr = "cobsEncode+0x1a3                               ";
         1005 : dbg_instr = "cobsEncode+0x1a4                               ";
         1006 : dbg_instr = "cobsEncode+0x1a5                               ";
         1007 : dbg_instr = "cobsEncode+0x1a6                               ";
         1008 : dbg_instr = "cobsEncode+0x1a7                               ";
         1009 : dbg_instr = "cobsEncode+0x1a8                               ";
         1010 : dbg_instr = "cobsEncode+0x1a9                               ";
         1011 : dbg_instr = "cobsEncode+0x1aa                               ";
         1012 : dbg_instr = "cobsEncode+0x1ab                               ";
         1013 : dbg_instr = "cobsEncode+0x1ac                               ";
         1014 : dbg_instr = "cobsEncode+0x1ad                               ";
         1015 : dbg_instr = "cobsEncode+0x1ae                               ";
         1016 : dbg_instr = "cobsEncode+0x1af                               ";
         1017 : dbg_instr = "cobsEncode+0x1b0                               ";
         1018 : dbg_instr = "cobsEncode+0x1b1                               ";
         1019 : dbg_instr = "cobsEncode+0x1b2                               ";
         1020 : dbg_instr = "cobsEncode+0x1b3                               ";
         1021 : dbg_instr = "cobsEncode+0x1b4                               ";
         1022 : dbg_instr = "cobsEncode+0x1b5                               ";
         1023 : dbg_instr = "cobsEncode+0x1b6                               ";
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
    .INIT_00(256'h9001700011002010D201920B900A70016EE02004005201040000000020040026),
    .INIT_01(256'h202590017000202590007000201DCED0DD0B7D036EE04ED011802020D202C010),
    .INIT_02(256'h70FFE02A40080202AA10110110801137B03FB80B90019001700031FFD1C01101),
    .INIT_03(256'hF2171200D21132FE92116034400E1101021AAA102038D00111380215F000307F),
    .INIT_04(256'h9F10110010011E0070001D011E001180B01B7001F210F212F214F2131200F216),
    .INIT_05(256'hB314B21360BFD200B21720A0D2042085D2032078D2022074D201B21050008001),
    .INIT_06(256'h1201207113041204606FD200B212F314F21343801280D000F314F213B3009201),
    .INIT_07(256'h142101EAF22100FFF220A2201234B21120EDC230B300B2125000F311F2101300),
    .INIT_08(256'h430600FAB21206704706B71116C002291621F22100FF5000F210120301E30206),
    .INIT_09(256'h5000F2101202F71120EDD7041701B711C4601601C560B520B421063043064306),
    .INIT_0A(256'h5608E0AB4700440046061710B620B521B42202291622F421149060BAD204B211),
    .INIT_0B(256'hB31820EDD2FC920FD2FD920E5000F2111205D6FBD5FAD4F9D7F8E0B04608450E),
    .INIT_0C(256'hA0D5D4201519141EF416F2184200F217B41712000229161F0620F32120D7D301),
    .INIT_0D(256'h96011501E360A350064015181218141F042020ED500020CE15019401E250A240),
    .INIT_0E(256'h60F1D200B2125000F4171400F416B417F4184400140001E3020601EA60DCC520),
    .INIT_0F(256'hB2125000E0FB420E130113FF5000D211720192115000F3101300F212420E1280),

    // Address 256 to 511
    .INIT_10(256'h948361BFC2F0928150008001D00B70036E00010C1000C0E05000A230133800FA),
    .INIT_11(256'hD2112141D210928261C3D5006115D183910105608610118401401500E1C1D43C),
    .INIT_12(256'h01C521B701C561C1D2002180D2C1216BD2C0212FD20F215DD21321ACD212214F),
    .INIT_13(256'h11890920D288B20C0920D287B20B0920D286B20A0920D285B209D984B908B053),
    .INIT_14(256'h01C521B4614AD5FE150601CA15C611860920D28592FDD98499FCB10301C521B4),
    .INIT_15(256'h99FAB10301C521B46158D5F8150401C915C011860920D28592F9D98499F8B1E3),
    .INIT_16(256'h92842176D200928301C521B46166D5FC150601CA15C411860920D28592FBD984),
    .INIT_17(256'h21B7B013B005B004217EBFF5B014217CD2809211D31153802175D200337F9311),
    .INIT_18(256'h151814840720F316F21721B7B005B004218BD300B317B013219AD200928301C5),
    .INIT_19(256'h21B7B004B00361A0D200B21621B7D285D78482706190920115011401E3508340),
    .INIT_1A(256'hD9841903B02301C521B461A4920111011401C3100930A340190011841418D283),
    .INIT_1B(256'h130C5000E2301201A230130901BB13080249C910190179FF1186D2850920B200),
    .INIT_1C(256'h110115010920C210825001CB01CA5000DF80D281928021BB130A21BB130B21BB),
    .INIT_1D(256'h920C01D1B02D01D1B01E50004308E1D7420012084300500001D501D501D55000),
    .INIT_1E(256'hB00D01D5B00E01D2B02DB01E500001D5B01E01D2B02D01D5B00E5000B00DD201),
    .INIT_1F(256'h4A0001DB1A01500001D101DBE1F2B00D01D1B02D01D1DB0E4B004A021B015000),

    // Address 512 to 767
    .INIT_20(256'hF5211423F42250006206D41F9401900001F1AA40500001E301F101EA5000E1FE),
    .INIT_21(256'h14D8020D1607151E14D4FA23221016051421F4211490500001E3020601EAF620),
    .INIT_22(256'hD621EA6001FD01F15A01BA2101EA0206142101EAF520F4215000020D1601158D),
    .INIT_23(256'h82701000C7600750500001E301D1622DD61F9601B00D01D1B02D01D1D20E4200),
    .INIT_24(256'h8250D708977F023C1685968315805000027017018750023C223D17011000D200),
    .INIT_25(256'h100010001000100010001000100010005000B008A24FC560D2080244D2001501),
    .INIT_26(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_27(256'h1000100010001000100010001000100010001000100010001000100010001000),
    .INIT_28(256'h1000100010001000100010001000100010001000100010001000100010001000),
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
    .INITP_00(256'h2A84C0A820D293A50D37774A00C0BAA288358C283610AAD5AEBC8432B3036A0A),
    .INITP_01(256'h2D4A0E24D28892AD58052A58D1A6092C288A2AB535402234A2D4981561422A8A),

    // Address 256 to 511
    .INITP_02(256'hAAAB08D034AD60622AD60622AD60622A18618622AB77777774DD510D34A82C86),
    .INITP_03(256'h62AEAA52AAAAAAA82AA746AA562AA2222908A4248AB56402AB4A9D5802AAD2D2),

    // Address 512 to 767
    .INITP_04(256'h00000000000000000000ADB52642169D34AB5AA96A0A2AA0202822AA8AD78AAB),
    .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000000),

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
