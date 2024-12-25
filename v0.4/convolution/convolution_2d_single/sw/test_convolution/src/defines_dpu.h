#ifdef __cplusplus
extern "C" {
#endif
#ifndef DEFINES_SYSTEM_V
#define DEFINES_SYSTEM_V
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
#ifndef DPU_USR_CLK_FREQ
#define DPU_USR_CLK_FREQ 100_000_000
#endif

#define AMBA_AXI4
#define AMBA_AXI_WIDTH_AD    32 //32
#define AMBA_AXI_WIDTH_DA    32 //32, 64, 128

#define DPU_DATA_TYPE        "FLOATING_POINT" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
#define DPU_DATA_WIDTH       32 // 32, 16, 8
#ifdef  DPU_DATA_FIXED_POINT
#define DPU_DATA_WIDTH_Q     (DPU_DATA_WIDTH/2) // fractional for fixed point
#endif

#define DPU_ADDR_BASE_MEM      0x10000000
#define DPU_ADDR_BASE_DPU      0xC0000000
#define DPU_ADDR_BASE_CONF      DPU_ADDR_BASE_DPU // DPU configure
#define DPU_ADDR_BASE_CONV     (DPU_ADDR_BASE_DPU+0x1000) // convolution
#define DPU_ADDR_BASE_POOL     (DPU_ADDR_BASE_DPU+0x2000) // pooling
#define DPU_ADDR_BASE_LINEAR   (DPU_ADDR_BASE_DPU+0x3000) // linear
#define DPU_ADDR_BASE_MOVER    (DPU_ADDR_BASE_DPU+0x4000) // mover
#define DPU_SIZE_MEM           (256*1024)
#define DPU_SIZE_CONF          (4*1024)
#define DPU_SIZE_CONV          (4*1024)
#define DPU_SIZE_POOL          (4*1024)
#define DPU_SIZE_LINEAR        (4*1024)
#define DPU_SIZE_MOVER         (4*1024)
#define DPU_SIZE_DPU           (DPU_ADDR_BASE_MOVER+DPU_SIZE_MOVER-DPU_ADDR_BASE_DPU)

#define ACTIV_FUNC_BYPASS       0x0
#define ACTIV_FUNC_NOP          ACTIV_FUNC_BYPASS
#define ACTIV_FUNC_RELU         0x1
#define ACTIV_FUNC_LEAKY_RELU   0x2
#define ACTIV_FUNC_SIGMOID      0x3
#define ACTIV_FUNC_TANH         0x4

#define POOLING_NOP             0x0
#define POOLING_MAX             0x1
#define POOLING_AVG             0x2

#define MOVER_COMMAND_NOP       0x0
#define MOVER_COMMAND_FILL      0x1
#define MOVER_COMMAND_COPY      0x2
#define MOVER_COMMAND_RESIDUAL  0x3
#define MOVER_COMMAND_CONCAT0   0x4
#define MOVER_COMMAND_CONCAT1   0x5
#define MOVER_COMMAND_TRANSPOSE 0x6

//------------------------------------------------------------------------------
// Revision history:
//
// 2018.02.05: Prepared by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
#endif
#ifdef __cplusplus
}
#endif
