`ifndef DEFINES_SYSTEM_V
`define DEFINES_SYSTEM_V
//------------------------------------------------------------------------------
// Copyright (c) 2018 by Future Design Systems
// All right reserved
//
// http://www.future-ds.com
//------------------------------------------------------------------------------
// defines_system.v
//------------------------------------------------------------------------------
// VERSION: 2018.02.05.
//------------------------------------------------------------------------------
`ifndef DPU_USR_CLK_FREQ
`define DPU_USR_CLK_FREQ 100_000_000
`endif

`define AMBA_AXI4
`define AMBA_AXI_WIDTH_AD    32 //32
`define AMBA_AXI_WIDTH_DA    32 //32, 64, 128

`define DPU_DATA_TYPE        "INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
`define DPU_DATA_WIDTH       32 // 32, 16, 8
`ifdef  DPU_DATA_FIXED_POINT
`define DPU_DATA_WIDTH_Q     (`DPU_DATA_WIDTH/2) // fractional for fixed point
`endif

`define DPU_ADDR_BASE_MEM      'h10000000
`define DPU_ADDR_BASE_DPU      'hC0000000
`define DPU_ADDR_BASE_CONF      `DPU_ADDR_BASE_DPU // DPU configure
`define DPU_ADDR_BASE_CONV     (`DPU_ADDR_BASE_DPU+'h1000) // convolution
`define DPU_ADDR_BASE_POOL     (`DPU_ADDR_BASE_DPU+'h2000) // pooling
`define DPU_ADDR_BASE_LINEAR   (`DPU_ADDR_BASE_DPU+'h3000) // linear
`define DPU_ADDR_BASE_MOVER    (`DPU_ADDR_BASE_DPU+'h4000) // mover
`define DPU_SIZE_MEM           (4*1024*1024)
`define DPU_SIZE_CONF          (4*1024)
`define DPU_SIZE_CONV          (4*1024)
`define DPU_SIZE_POOL          (4*1024)
`define DPU_SIZE_LINEAR        (4*1024)
`define DPU_SIZE_MOVER         (4*1024)
`define DPU_SIZE_DPU           (`DPU_ADDR_BASE_MOVER+`DPU_SIZE_MOVER-`DPU_ADDR_BASE_DPU)

`define ACTIV_FUNC_BYPASS       'h0
`define ACTIV_FUNC_NOP          `ACTIV_FUNC_BYPASS
`define ACTIV_FUNC_RELU         'h1
`define ACTIV_FUNC_LEAKY_RELU   'h2
`define ACTIV_FUNC_SIGMOID      'h3
`define ACTIV_FUNC_TANH         'h4

`define POOLING_NOP             'h0
`define POOLING_MAX             'h1
`define POOLING_AVG             'h2

`define MOVER_COMMAND_NOP       'h0
`define MOVER_COMMAND_FILL      'h1
`define MOVER_COMMAND_COPY      'h2
`define MOVER_COMMAND_RESIDUAL  'h3
`define MOVER_COMMAND_CONCAT0   'h4
`define MOVER_COMMAND_CONCAT1   'h5
`define MOVER_COMMAND_TRANSPOSE 'h6

//------------------------------------------------------------------------------
// Revision history:
//
// 2018.02.05: Prepared by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
`endif
