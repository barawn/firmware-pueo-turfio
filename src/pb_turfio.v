/*
 * == pblaze-cc ==
 * source : pb_turfio.c
 * create : Tue Jan 28 22:04:53 2025
 * modify : Tue Jan 28 22:04:53 2025
 */
`timescale 1 ps / 1ps

/* 
 * == pblaze-as ==
 * source : pb_turfio.s
 * create : Tue Jan 28 22:05:01 2025
 * modify : Tue Jan 28 22:05:01 2025
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
         390 : dbg_instr = "do_Enable+0x013                                ";
         391 : dbg_instr = "do_Enable+0x014                                ";
         392 : dbg_instr = "do_PMBus                                       ";
         393 : dbg_instr = "do_PMBus+0x001                                 ";
         394 : dbg_instr = "do_PMBus+0x002                                 ";
         395 : dbg_instr = "do_PMBus+0x003                                 ";
         396 : dbg_instr = "do_PMBus+0x004                                 ";
         397 : dbg_instr = "do_PMBus+0x005                                 ";
         398 : dbg_instr = "do_PMBus+0x006                                 ";
         399 : dbg_instr = "do_PMBus+0x007                                 ";
         400 : dbg_instr = "do_PMBus+0x008                                 ";
         401 : dbg_instr = "do_PMBus+0x009                                 ";
         402 : dbg_instr = "do_PMBus+0x00a                                 ";
         403 : dbg_instr = "PMBus_Write                                    ";
         404 : dbg_instr = "PMBus_Write+0x001                              ";
         405 : dbg_instr = "PMBus_Write+0x002                              ";
         406 : dbg_instr = "PMBus_Write+0x003                              ";
         407 : dbg_instr = "PMBus_Write+0x004                              ";
         408 : dbg_instr = "PMBus_Write+0x005                              ";
         409 : dbg_instr = "PMBus_Write+0x006                              ";
         410 : dbg_instr = "PMBus_Write+0x007                              ";
         411 : dbg_instr = "PMBus_Write+0x008                              ";
         412 : dbg_instr = "PMBus_Write+0x009                              ";
         413 : dbg_instr = "PMBus_Write+0x00a                              ";
         414 : dbg_instr = "PMBus_Write+0x00b                              ";
         415 : dbg_instr = "PMBus_Write+0x00c                              ";
         416 : dbg_instr = "PMBus_Write+0x00d                              ";
         417 : dbg_instr = "PMBus_Write+0x00e                              ";
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
         491 : dbg_instr = "I2C_stop                                       ";
         492 : dbg_instr = "I2C_stop+0x001                                 ";
         493 : dbg_instr = "I2C_stop+0x002                                 ";
         494 : dbg_instr = "I2C_stop+0x003                                 ";
         495 : dbg_instr = "I2C_stop+0x004                                 ";
         496 : dbg_instr = "I2C_stop+0x005                                 ";
         497 : dbg_instr = "I2C_stop+0x006                                 ";
         498 : dbg_instr = "I2C_start                                      ";
         499 : dbg_instr = "I2C_start+0x001                                ";
         500 : dbg_instr = "I2C_start+0x002                                ";
         501 : dbg_instr = "I2C_start+0x003                                ";
         502 : dbg_instr = "I2C_start+0x004                                ";
         503 : dbg_instr = "I2C_start+0x005                                ";
         504 : dbg_instr = "I2C_start+0x006                                ";
         505 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK                         ";
         506 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x001                   ";
         507 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x002                   ";
         508 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x003                   ";
         509 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x004                   ";
         510 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x005                   ";
         511 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x006                   ";
         512 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x007                   ";
         513 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x008                   ";
         514 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x009                   ";
         515 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00a                   ";
         516 : dbg_instr = "I2C_Tx_byte_and_Rx_ACK+0x00b                   ";
         517 : dbg_instr = "I2C_Rx_byte                                    ";
         518 : dbg_instr = "I2C_Rx_byte+0x001                              ";
         519 : dbg_instr = "I2C_Rx_byte+0x002                              ";
         520 : dbg_instr = "I2C_Rx_byte+0x003                              ";
         521 : dbg_instr = "I2C_Rx_byte+0x004                              ";
         522 : dbg_instr = "I2C_test                                       ";
         523 : dbg_instr = "I2C_test+0x001                                 ";
         524 : dbg_instr = "I2C_test+0x002                                 ";
         525 : dbg_instr = "I2C_test+0x003                                 ";
         526 : dbg_instr = "I2C_user_tx_process                            ";
         527 : dbg_instr = "I2C_user_tx_process+0x001                      ";
         528 : dbg_instr = "I2C_user_tx_process+0x002                      ";
         529 : dbg_instr = "I2C_user_tx_process+0x003                      ";
         530 : dbg_instr = "I2C_user_tx_process+0x004                      ";
         531 : dbg_instr = "I2C_user_tx_process+0x005                      ";
         532 : dbg_instr = "I2C_user_tx_process+0x006                      ";
         533 : dbg_instr = "I2C_send3                                      ";
         534 : dbg_instr = "I2C_send3+0x001                                ";
         535 : dbg_instr = "I2C_send3+0x002                                ";
         536 : dbg_instr = "I2C_send1_prcs                                 ";
         537 : dbg_instr = "I2C_send1_prcs+0x001                           ";
         538 : dbg_instr = "I2C_send1_prcs+0x002                           ";
         539 : dbg_instr = "I2C_send1_prcs+0x003                           ";
         540 : dbg_instr = "I2C_send1_prcs+0x004                           ";
         541 : dbg_instr = "I2C_turfio_initialize                          ";
         542 : dbg_instr = "I2C_turfio_initialize+0x001                    ";
         543 : dbg_instr = "I2C_turfio_initialize+0x002                    ";
         544 : dbg_instr = "I2C_turfio_initialize+0x003                    ";
         545 : dbg_instr = "I2C_turfio_initialize+0x004                    ";
         546 : dbg_instr = "I2C_surf_initialize                            ";
         547 : dbg_instr = "I2C_surf_initialize+0x001                      ";
         548 : dbg_instr = "I2C_surf_initialize+0x002                      ";
         549 : dbg_instr = "I2C_surf_initialize+0x003                      ";
         550 : dbg_instr = "I2C_surf_initialize+0x004                      ";
         551 : dbg_instr = "I2C_surf_initialize+0x005                      ";
         552 : dbg_instr = "I2C_surf_initialize+0x006                      ";
         553 : dbg_instr = "I2C_surf_initialize+0x007                      ";
         554 : dbg_instr = "I2C_surf_initialize+0x008                      ";
         555 : dbg_instr = "I2C_surf_initialize+0x009                      ";
         556 : dbg_instr = "I2C_read_register                              ";
         557 : dbg_instr = "I2C_read_register+0x001                        ";
         558 : dbg_instr = "I2C_read_register+0x002                        ";
         559 : dbg_instr = "I2C_read_register+0x003                        ";
         560 : dbg_instr = "I2C_read_register+0x004                        ";
         561 : dbg_instr = "I2C_read                                       ";
         562 : dbg_instr = "I2C_read+0x001                                 ";
         563 : dbg_instr = "I2C_read+0x002                                 ";
         564 : dbg_instr = "I2C_read+0x003                                 ";
         565 : dbg_instr = "I2C_read+0x004                                 ";
         566 : dbg_instr = "I2C_read+0x005                                 ";
         567 : dbg_instr = "I2C_read+0x006                                 ";
         568 : dbg_instr = "I2C_read+0x007                                 ";
         569 : dbg_instr = "I2C_read+0x008                                 ";
         570 : dbg_instr = "I2C_read+0x009                                 ";
         571 : dbg_instr = "I2C_read+0x00a                                 ";
         572 : dbg_instr = "I2C_read+0x00b                                 ";
         573 : dbg_instr = "I2C_read+0x00c                                 ";
         574 : dbg_instr = "I2C_read+0x00d                                 ";
         575 : dbg_instr = "I2C_read+0x00e                                 ";
         576 : dbg_instr = "I2C_read+0x00f                                 ";
         577 : dbg_instr = "I2C_read+0x010                                 ";
         578 : dbg_instr = "I2C_read+0x011                                 ";
         579 : dbg_instr = "I2C_read+0x012                                 ";
         580 : dbg_instr = "cobsFindZero                                   ";
         581 : dbg_instr = "cobsFindZero+0x001                             ";
         582 : dbg_instr = "cobsFindZero+0x002                             ";
         583 : dbg_instr = "cobsFindZero+0x003                             ";
         584 : dbg_instr = "cobsFindZero+0x004                             ";
         585 : dbg_instr = "cobsFindZero+0x005                             ";
         586 : dbg_instr = "cobsFindZero+0x006                             ";
         587 : dbg_instr = "cobsFindZero+0x007                             ";
         588 : dbg_instr = "cobsFixZero                                    ";
         589 : dbg_instr = "cobsFixZero+0x001                              ";
         590 : dbg_instr = "cobsFixZero+0x002                              ";
         591 : dbg_instr = "cobsFixZero+0x003                              ";
         592 : dbg_instr = "cobsFixZero+0x004                              ";
         593 : dbg_instr = "cobsEncode                                     ";
         594 : dbg_instr = "cobsEncode+0x001                               ";
         595 : dbg_instr = "cobsEncode+0x002                               ";
         596 : dbg_instr = "cobsEncode+0x003                               ";
         597 : dbg_instr = "cobsEncode+0x004                               ";
         598 : dbg_instr = "cobsEncode+0x005                               ";
         599 : dbg_instr = "cobsEncode+0x006                               ";
         600 : dbg_instr = "cobsEncode+0x007                               ";
         601 : dbg_instr = "cobsEncode+0x008                               ";
         602 : dbg_instr = "cobsEncode+0x009                               ";
         603 : dbg_instr = "cobsEncode+0x00a                               ";
         604 : dbg_instr = "cobsEncode+0x00b                               ";
         605 : dbg_instr = "cobsEncode+0x00c                               ";
         606 : dbg_instr = "cobsEncode+0x00d                               ";
         607 : dbg_instr = "cobsEncode+0x00e                               ";
         608 : dbg_instr = "icap_reboot                                    ";
         609 : dbg_instr = "icap_reboot+0x001                              ";
         610 : dbg_instr = "icap_reboot+0x002                              ";
         611 : dbg_instr = "icap_reboot+0x003                              ";
         612 : dbg_instr = "icap_reboot+0x004                              ";
         613 : dbg_instr = "icap_reboot+0x005                              ";
         614 : dbg_instr = "icap_reboot+0x006                              ";
         615 : dbg_instr = "icap_reboot+0x007                              ";
         616 : dbg_instr = "icap_reboot+0x008                              ";
         617 : dbg_instr = "icap_reboot+0x009                              ";
         618 : dbg_instr = "icap_reboot+0x00a                              ";
         619 : dbg_instr = "icap_reboot+0x00b                              ";
         620 : dbg_instr = "icap_reboot+0x00c                              ";
         621 : dbg_instr = "icap_reboot+0x00d                              ";
         622 : dbg_instr = "icap_reboot+0x00e                              ";
         623 : dbg_instr = "icap_reboot+0x00f                              ";
         624 : dbg_instr = "icap_reboot+0x010                              ";
         625 : dbg_instr = "icap_reboot+0x011                              ";
         626 : dbg_instr = "icap_reboot+0x012                              ";
         627 : dbg_instr = "icap_reboot+0x013                              ";
         628 : dbg_instr = "icap_reboot+0x014                              ";
         629 : dbg_instr = "icap_reboot+0x015                              ";
         630 : dbg_instr = "icap_reboot+0x016                              ";
         631 : dbg_instr = "icap_reboot+0x017                              ";
         632 : dbg_instr = "icap_reboot+0x018                              ";
         633 : dbg_instr = "icap_noop                                      ";
         634 : dbg_instr = "icap_3zero                                     ";
         635 : dbg_instr = "icap_3zero+0x001                               ";
         636 : dbg_instr = "icap_3zero+0x002                               ";
         637 : dbg_instr = "icap_3zero+0x003                               ";
         638 : dbg_instr = "icap_3zero+0x004                               ";
         639 : dbg_instr = "icap_3zero+0x005                               ";
         640 : dbg_instr = "icap_3zero+0x006                               ";
         641 : dbg_instr = "icap_3zero+0x007                               ";
         642 : dbg_instr = "icap_3zero+0x008                               ";
         643 : dbg_instr = "icap_3zero+0x009                               ";
         644 : dbg_instr = "icap_3zero+0x00a                               ";
         645 : dbg_instr = "icap_3zero+0x00b                               ";
         646 : dbg_instr = "icap_3zero+0x00c                               ";
         647 : dbg_instr = "icap_3zero+0x00d                               ";
         648 : dbg_instr = "icap_3zero+0x00e                               ";
         649 : dbg_instr = "icap_3zero+0x00f                               ";
         650 : dbg_instr = "icap_3zero+0x010                               ";
         651 : dbg_instr = "icap_3zero+0x011                               ";
         652 : dbg_instr = "icap_3zero+0x012                               ";
         653 : dbg_instr = "icap_3zero+0x013                               ";
         654 : dbg_instr = "icap_3zero+0x014                               ";
         655 : dbg_instr = "icap_3zero+0x015                               ";
         656 : dbg_instr = "icap_3zero+0x016                               ";
         657 : dbg_instr = "icap_3zero+0x017                               ";
         658 : dbg_instr = "icap_3zero+0x018                               ";
         659 : dbg_instr = "icap_3zero+0x019                               ";
         660 : dbg_instr = "icap_3zero+0x01a                               ";
         661 : dbg_instr = "icap_3zero+0x01b                               ";
         662 : dbg_instr = "icap_3zero+0x01c                               ";
         663 : dbg_instr = "icap_3zero+0x01d                               ";
         664 : dbg_instr = "icap_3zero+0x01e                               ";
         665 : dbg_instr = "icap_3zero+0x01f                               ";
         666 : dbg_instr = "icap_3zero+0x020                               ";
         667 : dbg_instr = "icap_3zero+0x021                               ";
         668 : dbg_instr = "icap_3zero+0x022                               ";
         669 : dbg_instr = "icap_3zero+0x023                               ";
         670 : dbg_instr = "icap_3zero+0x024                               ";
         671 : dbg_instr = "icap_3zero+0x025                               ";
         672 : dbg_instr = "icap_3zero+0x026                               ";
         673 : dbg_instr = "icap_3zero+0x027                               ";
         674 : dbg_instr = "icap_3zero+0x028                               ";
         675 : dbg_instr = "icap_3zero+0x029                               ";
         676 : dbg_instr = "icap_3zero+0x02a                               ";
         677 : dbg_instr = "icap_3zero+0x02b                               ";
         678 : dbg_instr = "icap_3zero+0x02c                               ";
         679 : dbg_instr = "icap_3zero+0x02d                               ";
         680 : dbg_instr = "icap_3zero+0x02e                               ";
         681 : dbg_instr = "icap_3zero+0x02f                               ";
         682 : dbg_instr = "icap_3zero+0x030                               ";
         683 : dbg_instr = "icap_3zero+0x031                               ";
         684 : dbg_instr = "icap_3zero+0x032                               ";
         685 : dbg_instr = "icap_3zero+0x033                               ";
         686 : dbg_instr = "icap_3zero+0x034                               ";
         687 : dbg_instr = "icap_3zero+0x035                               ";
         688 : dbg_instr = "icap_3zero+0x036                               ";
         689 : dbg_instr = "icap_3zero+0x037                               ";
         690 : dbg_instr = "icap_3zero+0x038                               ";
         691 : dbg_instr = "icap_3zero+0x039                               ";
         692 : dbg_instr = "icap_3zero+0x03a                               ";
         693 : dbg_instr = "icap_3zero+0x03b                               ";
         694 : dbg_instr = "icap_3zero+0x03c                               ";
         695 : dbg_instr = "icap_3zero+0x03d                               ";
         696 : dbg_instr = "icap_3zero+0x03e                               ";
         697 : dbg_instr = "icap_3zero+0x03f                               ";
         698 : dbg_instr = "icap_3zero+0x040                               ";
         699 : dbg_instr = "icap_3zero+0x041                               ";
         700 : dbg_instr = "icap_3zero+0x042                               ";
         701 : dbg_instr = "icap_3zero+0x043                               ";
         702 : dbg_instr = "icap_3zero+0x044                               ";
         703 : dbg_instr = "icap_3zero+0x045                               ";
         704 : dbg_instr = "icap_3zero+0x046                               ";
         705 : dbg_instr = "icap_3zero+0x047                               ";
         706 : dbg_instr = "icap_3zero+0x048                               ";
         707 : dbg_instr = "icap_3zero+0x049                               ";
         708 : dbg_instr = "icap_3zero+0x04a                               ";
         709 : dbg_instr = "icap_3zero+0x04b                               ";
         710 : dbg_instr = "icap_3zero+0x04c                               ";
         711 : dbg_instr = "icap_3zero+0x04d                               ";
         712 : dbg_instr = "icap_3zero+0x04e                               ";
         713 : dbg_instr = "icap_3zero+0x04f                               ";
         714 : dbg_instr = "icap_3zero+0x050                               ";
         715 : dbg_instr = "icap_3zero+0x051                               ";
         716 : dbg_instr = "icap_3zero+0x052                               ";
         717 : dbg_instr = "icap_3zero+0x053                               ";
         718 : dbg_instr = "icap_3zero+0x054                               ";
         719 : dbg_instr = "icap_3zero+0x055                               ";
         720 : dbg_instr = "icap_3zero+0x056                               ";
         721 : dbg_instr = "icap_3zero+0x057                               ";
         722 : dbg_instr = "icap_3zero+0x058                               ";
         723 : dbg_instr = "icap_3zero+0x059                               ";
         724 : dbg_instr = "icap_3zero+0x05a                               ";
         725 : dbg_instr = "icap_3zero+0x05b                               ";
         726 : dbg_instr = "icap_3zero+0x05c                               ";
         727 : dbg_instr = "icap_3zero+0x05d                               ";
         728 : dbg_instr = "icap_3zero+0x05e                               ";
         729 : dbg_instr = "icap_3zero+0x05f                               ";
         730 : dbg_instr = "icap_3zero+0x060                               ";
         731 : dbg_instr = "icap_3zero+0x061                               ";
         732 : dbg_instr = "icap_3zero+0x062                               ";
         733 : dbg_instr = "icap_3zero+0x063                               ";
         734 : dbg_instr = "icap_3zero+0x064                               ";
         735 : dbg_instr = "icap_3zero+0x065                               ";
         736 : dbg_instr = "icap_3zero+0x066                               ";
         737 : dbg_instr = "icap_3zero+0x067                               ";
         738 : dbg_instr = "icap_3zero+0x068                               ";
         739 : dbg_instr = "icap_3zero+0x069                               ";
         740 : dbg_instr = "icap_3zero+0x06a                               ";
         741 : dbg_instr = "icap_3zero+0x06b                               ";
         742 : dbg_instr = "icap_3zero+0x06c                               ";
         743 : dbg_instr = "icap_3zero+0x06d                               ";
         744 : dbg_instr = "icap_3zero+0x06e                               ";
         745 : dbg_instr = "icap_3zero+0x06f                               ";
         746 : dbg_instr = "icap_3zero+0x070                               ";
         747 : dbg_instr = "icap_3zero+0x071                               ";
         748 : dbg_instr = "icap_3zero+0x072                               ";
         749 : dbg_instr = "icap_3zero+0x073                               ";
         750 : dbg_instr = "icap_3zero+0x074                               ";
         751 : dbg_instr = "icap_3zero+0x075                               ";
         752 : dbg_instr = "icap_3zero+0x076                               ";
         753 : dbg_instr = "icap_3zero+0x077                               ";
         754 : dbg_instr = "icap_3zero+0x078                               ";
         755 : dbg_instr = "icap_3zero+0x079                               ";
         756 : dbg_instr = "icap_3zero+0x07a                               ";
         757 : dbg_instr = "icap_3zero+0x07b                               ";
         758 : dbg_instr = "icap_3zero+0x07c                               ";
         759 : dbg_instr = "icap_3zero+0x07d                               ";
         760 : dbg_instr = "icap_3zero+0x07e                               ";
         761 : dbg_instr = "icap_3zero+0x07f                               ";
         762 : dbg_instr = "icap_3zero+0x080                               ";
         763 : dbg_instr = "icap_3zero+0x081                               ";
         764 : dbg_instr = "icap_3zero+0x082                               ";
         765 : dbg_instr = "icap_3zero+0x083                               ";
         766 : dbg_instr = "icap_3zero+0x084                               ";
         767 : dbg_instr = "icap_3zero+0x085                               ";
         768 : dbg_instr = "icap_3zero+0x086                               ";
         769 : dbg_instr = "icap_3zero+0x087                               ";
         770 : dbg_instr = "icap_3zero+0x088                               ";
         771 : dbg_instr = "icap_3zero+0x089                               ";
         772 : dbg_instr = "icap_3zero+0x08a                               ";
         773 : dbg_instr = "icap_3zero+0x08b                               ";
         774 : dbg_instr = "icap_3zero+0x08c                               ";
         775 : dbg_instr = "icap_3zero+0x08d                               ";
         776 : dbg_instr = "icap_3zero+0x08e                               ";
         777 : dbg_instr = "icap_3zero+0x08f                               ";
         778 : dbg_instr = "icap_3zero+0x090                               ";
         779 : dbg_instr = "icap_3zero+0x091                               ";
         780 : dbg_instr = "icap_3zero+0x092                               ";
         781 : dbg_instr = "icap_3zero+0x093                               ";
         782 : dbg_instr = "icap_3zero+0x094                               ";
         783 : dbg_instr = "icap_3zero+0x095                               ";
         784 : dbg_instr = "icap_3zero+0x096                               ";
         785 : dbg_instr = "icap_3zero+0x097                               ";
         786 : dbg_instr = "icap_3zero+0x098                               ";
         787 : dbg_instr = "icap_3zero+0x099                               ";
         788 : dbg_instr = "icap_3zero+0x09a                               ";
         789 : dbg_instr = "icap_3zero+0x09b                               ";
         790 : dbg_instr = "icap_3zero+0x09c                               ";
         791 : dbg_instr = "icap_3zero+0x09d                               ";
         792 : dbg_instr = "icap_3zero+0x09e                               ";
         793 : dbg_instr = "icap_3zero+0x09f                               ";
         794 : dbg_instr = "icap_3zero+0x0a0                               ";
         795 : dbg_instr = "icap_3zero+0x0a1                               ";
         796 : dbg_instr = "icap_3zero+0x0a2                               ";
         797 : dbg_instr = "icap_3zero+0x0a3                               ";
         798 : dbg_instr = "icap_3zero+0x0a4                               ";
         799 : dbg_instr = "icap_3zero+0x0a5                               ";
         800 : dbg_instr = "icap_3zero+0x0a6                               ";
         801 : dbg_instr = "icap_3zero+0x0a7                               ";
         802 : dbg_instr = "icap_3zero+0x0a8                               ";
         803 : dbg_instr = "icap_3zero+0x0a9                               ";
         804 : dbg_instr = "icap_3zero+0x0aa                               ";
         805 : dbg_instr = "icap_3zero+0x0ab                               ";
         806 : dbg_instr = "icap_3zero+0x0ac                               ";
         807 : dbg_instr = "icap_3zero+0x0ad                               ";
         808 : dbg_instr = "icap_3zero+0x0ae                               ";
         809 : dbg_instr = "icap_3zero+0x0af                               ";
         810 : dbg_instr = "icap_3zero+0x0b0                               ";
         811 : dbg_instr = "icap_3zero+0x0b1                               ";
         812 : dbg_instr = "icap_3zero+0x0b2                               ";
         813 : dbg_instr = "icap_3zero+0x0b3                               ";
         814 : dbg_instr = "icap_3zero+0x0b4                               ";
         815 : dbg_instr = "icap_3zero+0x0b5                               ";
         816 : dbg_instr = "icap_3zero+0x0b6                               ";
         817 : dbg_instr = "icap_3zero+0x0b7                               ";
         818 : dbg_instr = "icap_3zero+0x0b8                               ";
         819 : dbg_instr = "icap_3zero+0x0b9                               ";
         820 : dbg_instr = "icap_3zero+0x0ba                               ";
         821 : dbg_instr = "icap_3zero+0x0bb                               ";
         822 : dbg_instr = "icap_3zero+0x0bc                               ";
         823 : dbg_instr = "icap_3zero+0x0bd                               ";
         824 : dbg_instr = "icap_3zero+0x0be                               ";
         825 : dbg_instr = "icap_3zero+0x0bf                               ";
         826 : dbg_instr = "icap_3zero+0x0c0                               ";
         827 : dbg_instr = "icap_3zero+0x0c1                               ";
         828 : dbg_instr = "icap_3zero+0x0c2                               ";
         829 : dbg_instr = "icap_3zero+0x0c3                               ";
         830 : dbg_instr = "icap_3zero+0x0c4                               ";
         831 : dbg_instr = "icap_3zero+0x0c5                               ";
         832 : dbg_instr = "icap_3zero+0x0c6                               ";
         833 : dbg_instr = "icap_3zero+0x0c7                               ";
         834 : dbg_instr = "icap_3zero+0x0c8                               ";
         835 : dbg_instr = "icap_3zero+0x0c9                               ";
         836 : dbg_instr = "icap_3zero+0x0ca                               ";
         837 : dbg_instr = "icap_3zero+0x0cb                               ";
         838 : dbg_instr = "icap_3zero+0x0cc                               ";
         839 : dbg_instr = "icap_3zero+0x0cd                               ";
         840 : dbg_instr = "icap_3zero+0x0ce                               ";
         841 : dbg_instr = "icap_3zero+0x0cf                               ";
         842 : dbg_instr = "icap_3zero+0x0d0                               ";
         843 : dbg_instr = "icap_3zero+0x0d1                               ";
         844 : dbg_instr = "icap_3zero+0x0d2                               ";
         845 : dbg_instr = "icap_3zero+0x0d3                               ";
         846 : dbg_instr = "icap_3zero+0x0d4                               ";
         847 : dbg_instr = "icap_3zero+0x0d5                               ";
         848 : dbg_instr = "icap_3zero+0x0d6                               ";
         849 : dbg_instr = "icap_3zero+0x0d7                               ";
         850 : dbg_instr = "icap_3zero+0x0d8                               ";
         851 : dbg_instr = "icap_3zero+0x0d9                               ";
         852 : dbg_instr = "icap_3zero+0x0da                               ";
         853 : dbg_instr = "icap_3zero+0x0db                               ";
         854 : dbg_instr = "icap_3zero+0x0dc                               ";
         855 : dbg_instr = "icap_3zero+0x0dd                               ";
         856 : dbg_instr = "icap_3zero+0x0de                               ";
         857 : dbg_instr = "icap_3zero+0x0df                               ";
         858 : dbg_instr = "icap_3zero+0x0e0                               ";
         859 : dbg_instr = "icap_3zero+0x0e1                               ";
         860 : dbg_instr = "icap_3zero+0x0e2                               ";
         861 : dbg_instr = "icap_3zero+0x0e3                               ";
         862 : dbg_instr = "icap_3zero+0x0e4                               ";
         863 : dbg_instr = "icap_3zero+0x0e5                               ";
         864 : dbg_instr = "icap_3zero+0x0e6                               ";
         865 : dbg_instr = "icap_3zero+0x0e7                               ";
         866 : dbg_instr = "icap_3zero+0x0e8                               ";
         867 : dbg_instr = "icap_3zero+0x0e9                               ";
         868 : dbg_instr = "icap_3zero+0x0ea                               ";
         869 : dbg_instr = "icap_3zero+0x0eb                               ";
         870 : dbg_instr = "icap_3zero+0x0ec                               ";
         871 : dbg_instr = "icap_3zero+0x0ed                               ";
         872 : dbg_instr = "icap_3zero+0x0ee                               ";
         873 : dbg_instr = "icap_3zero+0x0ef                               ";
         874 : dbg_instr = "icap_3zero+0x0f0                               ";
         875 : dbg_instr = "icap_3zero+0x0f1                               ";
         876 : dbg_instr = "icap_3zero+0x0f2                               ";
         877 : dbg_instr = "icap_3zero+0x0f3                               ";
         878 : dbg_instr = "icap_3zero+0x0f4                               ";
         879 : dbg_instr = "icap_3zero+0x0f5                               ";
         880 : dbg_instr = "icap_3zero+0x0f6                               ";
         881 : dbg_instr = "icap_3zero+0x0f7                               ";
         882 : dbg_instr = "icap_3zero+0x0f8                               ";
         883 : dbg_instr = "icap_3zero+0x0f9                               ";
         884 : dbg_instr = "icap_3zero+0x0fa                               ";
         885 : dbg_instr = "icap_3zero+0x0fb                               ";
         886 : dbg_instr = "icap_3zero+0x0fc                               ";
         887 : dbg_instr = "icap_3zero+0x0fd                               ";
         888 : dbg_instr = "icap_3zero+0x0fe                               ";
         889 : dbg_instr = "icap_3zero+0x0ff                               ";
         890 : dbg_instr = "icap_3zero+0x100                               ";
         891 : dbg_instr = "icap_3zero+0x101                               ";
         892 : dbg_instr = "icap_3zero+0x102                               ";
         893 : dbg_instr = "icap_3zero+0x103                               ";
         894 : dbg_instr = "icap_3zero+0x104                               ";
         895 : dbg_instr = "icap_3zero+0x105                               ";
         896 : dbg_instr = "icap_3zero+0x106                               ";
         897 : dbg_instr = "icap_3zero+0x107                               ";
         898 : dbg_instr = "icap_3zero+0x108                               ";
         899 : dbg_instr = "icap_3zero+0x109                               ";
         900 : dbg_instr = "icap_3zero+0x10a                               ";
         901 : dbg_instr = "icap_3zero+0x10b                               ";
         902 : dbg_instr = "icap_3zero+0x10c                               ";
         903 : dbg_instr = "icap_3zero+0x10d                               ";
         904 : dbg_instr = "icap_3zero+0x10e                               ";
         905 : dbg_instr = "icap_3zero+0x10f                               ";
         906 : dbg_instr = "icap_3zero+0x110                               ";
         907 : dbg_instr = "icap_3zero+0x111                               ";
         908 : dbg_instr = "icap_3zero+0x112                               ";
         909 : dbg_instr = "icap_3zero+0x113                               ";
         910 : dbg_instr = "icap_3zero+0x114                               ";
         911 : dbg_instr = "icap_3zero+0x115                               ";
         912 : dbg_instr = "icap_3zero+0x116                               ";
         913 : dbg_instr = "icap_3zero+0x117                               ";
         914 : dbg_instr = "icap_3zero+0x118                               ";
         915 : dbg_instr = "icap_3zero+0x119                               ";
         916 : dbg_instr = "icap_3zero+0x11a                               ";
         917 : dbg_instr = "icap_3zero+0x11b                               ";
         918 : dbg_instr = "icap_3zero+0x11c                               ";
         919 : dbg_instr = "icap_3zero+0x11d                               ";
         920 : dbg_instr = "icap_3zero+0x11e                               ";
         921 : dbg_instr = "icap_3zero+0x11f                               ";
         922 : dbg_instr = "icap_3zero+0x120                               ";
         923 : dbg_instr = "icap_3zero+0x121                               ";
         924 : dbg_instr = "icap_3zero+0x122                               ";
         925 : dbg_instr = "icap_3zero+0x123                               ";
         926 : dbg_instr = "icap_3zero+0x124                               ";
         927 : dbg_instr = "icap_3zero+0x125                               ";
         928 : dbg_instr = "icap_3zero+0x126                               ";
         929 : dbg_instr = "icap_3zero+0x127                               ";
         930 : dbg_instr = "icap_3zero+0x128                               ";
         931 : dbg_instr = "icap_3zero+0x129                               ";
         932 : dbg_instr = "icap_3zero+0x12a                               ";
         933 : dbg_instr = "icap_3zero+0x12b                               ";
         934 : dbg_instr = "icap_3zero+0x12c                               ";
         935 : dbg_instr = "icap_3zero+0x12d                               ";
         936 : dbg_instr = "icap_3zero+0x12e                               ";
         937 : dbg_instr = "icap_3zero+0x12f                               ";
         938 : dbg_instr = "icap_3zero+0x130                               ";
         939 : dbg_instr = "icap_3zero+0x131                               ";
         940 : dbg_instr = "icap_3zero+0x132                               ";
         941 : dbg_instr = "icap_3zero+0x133                               ";
         942 : dbg_instr = "icap_3zero+0x134                               ";
         943 : dbg_instr = "icap_3zero+0x135                               ";
         944 : dbg_instr = "icap_3zero+0x136                               ";
         945 : dbg_instr = "icap_3zero+0x137                               ";
         946 : dbg_instr = "icap_3zero+0x138                               ";
         947 : dbg_instr = "icap_3zero+0x139                               ";
         948 : dbg_instr = "icap_3zero+0x13a                               ";
         949 : dbg_instr = "icap_3zero+0x13b                               ";
         950 : dbg_instr = "icap_3zero+0x13c                               ";
         951 : dbg_instr = "icap_3zero+0x13d                               ";
         952 : dbg_instr = "icap_3zero+0x13e                               ";
         953 : dbg_instr = "icap_3zero+0x13f                               ";
         954 : dbg_instr = "icap_3zero+0x140                               ";
         955 : dbg_instr = "icap_3zero+0x141                               ";
         956 : dbg_instr = "icap_3zero+0x142                               ";
         957 : dbg_instr = "icap_3zero+0x143                               ";
         958 : dbg_instr = "icap_3zero+0x144                               ";
         959 : dbg_instr = "icap_3zero+0x145                               ";
         960 : dbg_instr = "icap_3zero+0x146                               ";
         961 : dbg_instr = "icap_3zero+0x147                               ";
         962 : dbg_instr = "icap_3zero+0x148                               ";
         963 : dbg_instr = "icap_3zero+0x149                               ";
         964 : dbg_instr = "icap_3zero+0x14a                               ";
         965 : dbg_instr = "icap_3zero+0x14b                               ";
         966 : dbg_instr = "icap_3zero+0x14c                               ";
         967 : dbg_instr = "icap_3zero+0x14d                               ";
         968 : dbg_instr = "icap_3zero+0x14e                               ";
         969 : dbg_instr = "icap_3zero+0x14f                               ";
         970 : dbg_instr = "icap_3zero+0x150                               ";
         971 : dbg_instr = "icap_3zero+0x151                               ";
         972 : dbg_instr = "icap_3zero+0x152                               ";
         973 : dbg_instr = "icap_3zero+0x153                               ";
         974 : dbg_instr = "icap_3zero+0x154                               ";
         975 : dbg_instr = "icap_3zero+0x155                               ";
         976 : dbg_instr = "icap_3zero+0x156                               ";
         977 : dbg_instr = "icap_3zero+0x157                               ";
         978 : dbg_instr = "icap_3zero+0x158                               ";
         979 : dbg_instr = "icap_3zero+0x159                               ";
         980 : dbg_instr = "icap_3zero+0x15a                               ";
         981 : dbg_instr = "icap_3zero+0x15b                               ";
         982 : dbg_instr = "icap_3zero+0x15c                               ";
         983 : dbg_instr = "icap_3zero+0x15d                               ";
         984 : dbg_instr = "icap_3zero+0x15e                               ";
         985 : dbg_instr = "icap_3zero+0x15f                               ";
         986 : dbg_instr = "icap_3zero+0x160                               ";
         987 : dbg_instr = "icap_3zero+0x161                               ";
         988 : dbg_instr = "icap_3zero+0x162                               ";
         989 : dbg_instr = "icap_3zero+0x163                               ";
         990 : dbg_instr = "icap_3zero+0x164                               ";
         991 : dbg_instr = "icap_3zero+0x165                               ";
         992 : dbg_instr = "icap_3zero+0x166                               ";
         993 : dbg_instr = "icap_3zero+0x167                               ";
         994 : dbg_instr = "icap_3zero+0x168                               ";
         995 : dbg_instr = "icap_3zero+0x169                               ";
         996 : dbg_instr = "icap_3zero+0x16a                               ";
         997 : dbg_instr = "icap_3zero+0x16b                               ";
         998 : dbg_instr = "icap_3zero+0x16c                               ";
         999 : dbg_instr = "icap_3zero+0x16d                               ";
         1000 : dbg_instr = "icap_3zero+0x16e                               ";
         1001 : dbg_instr = "icap_3zero+0x16f                               ";
         1002 : dbg_instr = "icap_3zero+0x170                               ";
         1003 : dbg_instr = "icap_3zero+0x171                               ";
         1004 : dbg_instr = "icap_3zero+0x172                               ";
         1005 : dbg_instr = "icap_3zero+0x173                               ";
         1006 : dbg_instr = "icap_3zero+0x174                               ";
         1007 : dbg_instr = "icap_3zero+0x175                               ";
         1008 : dbg_instr = "icap_3zero+0x176                               ";
         1009 : dbg_instr = "icap_3zero+0x177                               ";
         1010 : dbg_instr = "icap_3zero+0x178                               ";
         1011 : dbg_instr = "icap_3zero+0x179                               ";
         1012 : dbg_instr = "icap_3zero+0x17a                               ";
         1013 : dbg_instr = "icap_3zero+0x17b                               ";
         1014 : dbg_instr = "icap_3zero+0x17c                               ";
         1015 : dbg_instr = "icap_3zero+0x17d                               ";
         1016 : dbg_instr = "icap_3zero+0x17e                               ";
         1017 : dbg_instr = "icap_3zero+0x17f                               ";
         1018 : dbg_instr = "icap_3zero+0x180                               ";
         1019 : dbg_instr = "icap_3zero+0x181                               ";
         1020 : dbg_instr = "icap_3zero+0x182                               ";
         1021 : dbg_instr = "icap_3zero+0x183                               ";
         1022 : dbg_instr = "icap_3zero+0x184                               ";
         1023 : dbg_instr = "icap_3zero+0x185                               ";
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
    .INIT_02(256'h70FFE02A4008020AAA10110110801137B03FB80B90019001700031FFD1C01101),
    .INIT_03(256'hF2171200D21132FE92116034400E11010222AA102038D0011138021DF000307F),
    .INIT_04(256'h9F10110010011E0070001D011E001180B01B7001F210F212F214F2131200F216),
    .INIT_05(256'hB314B21360BFD200B21720A0D2042085D2032078D2022074D201B21050008001),
    .INIT_06(256'h1201207113041204606FD200B212F314F21343801280D000F314F213B3009201),
    .INIT_07(256'h142101F2F22100FFF220A2201234B21120EDC230B300B2125000F311F2101300),
    .INIT_08(256'h430600FAB21206704706B71116C002311621F22100FF5000F210120301EB020E),
    .INIT_09(256'h5000F2101202F71120EDD7041701B711C4601601C560B520B421063043064306),
    .INIT_0A(256'h5608E0AB4700440046061710B620B521B42202311622F421149060BAD204B211),
    .INIT_0B(256'hB31820EDD2FC920FD2FD920E5000F2111205D6FBD5FAD4F9D7F8E0B04608450E),
    .INIT_0C(256'hA0D5D4201519141EF416F2184200F217B41712000231161F0620F32120D7D301),
    .INIT_0D(256'h96011501E360A350064015181218141F042020ED500020CE15019401E250A240),
    .INIT_0E(256'h60F1D200B2125000F4171400F416B417F4184400140001EB020E01F260DCC520),
    .INIT_0F(256'hB2125000E0FB420E130113FF5000D211720192115000F3101300F212420E1280),

    // Address 256 to 511
    .INIT_10(256'h948361C7C2F0928150008001D00B70036E00010C1000C0E05000A230133800FA),
    .INIT_11(256'hD2112143D210928261CBD5006115D183910105608610118401401500E1C9D43C),
    .INIT_12(256'h01CD61C9D200216DD2C22188D2C12173D2C02131D20F215FD21321B4D2122151),
    .INIT_13(256'hD288B20C0920D287B20B0920D286B20A0920D285B209D984B908B05301CD21BF),
    .INIT_14(256'h614CD5FE150601D215C611860920D28592FDD98499FCB10301CD21BC11890920),
    .INIT_15(256'h01CD21BC615AD5F8150401D115C011860920D28592F9D98499F8B1E301CD21BC),
    .INIT_16(256'h96869585948421BC6168D5FC150601D215C411860920D28592FBD98499FAB103),
    .INIT_17(256'hD2809211D3115380217DD200337F93119284217ED200928301CD500002609787),
    .INIT_18(256'h2193D300B317B01321A2D200928301CD21BFB013B005B0042186BFF5B0142184),
    .INIT_19(256'hD78482706198920115011401E3508340151814840720F316F21721BFB005B004),
    .INIT_1A(256'h1401C3100930A340190011841418D28321BFB004B00361A8D200B21621BFD285),
    .INIT_1B(256'h0251C910190179FF1186D2850920B200D9841904B02301CD21BC61AC92011101),
    .INIT_1C(256'hDF80D281928021C3130A21C3130B21C3130C5000E2301201A230130901C31308),
    .INIT_1D(256'h420012084300500001DD01DD01DD5000110115010920C210825001D301D25000),
    .INIT_1E(256'hB01E01DAB02D01DDB00E5000B00DD201920C01D9B02D01D9B01E50004308E1DF),
    .INIT_1F(256'h01D9B02D01D9DB0E4B004A021B015000B00D01DDB00E01DAB02DB01E500001DD),

    // Address 512 to 767
    .INIT_20(256'h01F9AA40500001EB01F901F25000E2064A0001E31A01500001D901E3E1FAB00D),
    .INIT_21(256'h1421F4211490500001EB020E01F2F620F5211423F4225000620ED41F94019000),
    .INIT_22(256'h142101F2F520F421500002151601158D14D802151607151E14D4FA2322181605),
    .INIT_23(256'hD61F9601B00D01D9B02D01D9D20E4200D621EA60020501F95A01BA2101F2020E),
    .INIT_24(256'h0270170187500244224517011000D20082701000C7600750500001EB01D96235),
    .INIT_25(256'h5000B008A257C560D208024CD20015018250D708977F02441685968315805000),
    .INIT_26(256'hD400B010B000B020B3000279B660B550B990BAA0BFF0BFF0BFF0BFF0D2111280),
    .INIT_27(256'h100010005000B000B000B000B200B0F0027AB010B080B000B300D700D600D500),
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
    .INITP_02(256'h08D034A802D60622AD60622AD60622A18618622AB777777774DD510D34A82C86),
    .INITP_03(256'hAA52AAAAAAA82AA746AA562AA2222908A4248AB56402AB4A9D5802AAD2D2AAAB),

    // Address 512 to 767
    .INITP_04(256'h0AAAAAAAAAAAAAA8ADB52642169D34AB5AA96A0A2AA0202822AA8AD78AAB62AE),
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
