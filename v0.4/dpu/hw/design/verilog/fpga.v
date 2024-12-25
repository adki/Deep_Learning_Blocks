//------------------------------------------------------------------------------
// Copyright (c) 2021 by Future Design Systems Co., Ltd.
// All right reserved
// http://www.future-ds.com
//------------------------------------------------------------------------------
// fpga.v
//------------------------------------------------------------------------------
// VERSION: 2021.04.01.
//------------------------------------------------------------------------------
`ifdef BOARD_ZC706
`elsif BOARD_ZC702
`elsif BOARD_ZED
`include "fpga_zed.v"
`elsif BOARD_NEXYS_VIDEO
`include "fpga_nexys_video.v"
`elsif BOARD_VCU108
`include "fpga_vcu108.v"
`else
`endif

//------------------------------------------------------------------------------
// Revision history:
//
// 2021.04.01: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
