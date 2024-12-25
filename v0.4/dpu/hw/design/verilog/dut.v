//------------------------------------------------------------------------------
// Copyright (c) 2021 by Future Design Systems.
// All right reserved.
//------------------------------------------------------------------------------
// dut.v
//------------------------------------------------------------------------------
// VERSION: 2021.04.01.
//------------------------------------------------------------------------------
//      gpif2mast
//    +-----------+        +---------+        +----------+
//    |           |        |         |        |          |
//    |   CMD-FIFO+=======>|         |        |          |
//    |           |        |         |        |          |
//    |           |        |         |        |          |--->
//    |   U2F-FIFO+=======>| trx_axi |<======>| AMBA     |--->
//    |           |        |         |        |          |<---
//    |           |        |         |        |          |<---
//    |   F2U-FIFO|<=======+         |        |          |
//    |           |        |         |        |          |
//    +-----------+        +---------+        +----------+
//------------------------------------------------------------------------------
//    +--------+     +--------+     +-------+
//    | BFM    |<===>|M0    S1|<===>|AXI2APB|====\\
//    |        |     |        |     |       |    ||
//    +--------+     |        |     +-------+    ||
//    +--------+     |        |     +-------+    ||
//    | MEM    |<===>|S0    M1|<===>| CONV  |<===// S0
//    |        |     |      M2|     |       |    ||
//    +--------+     |      M3|     +-------+    ||
//                   |        |     +-------+    ||
//                   |      M4|<===>| POOL  |<===// S1
//                   |        |     |       |    ||
//                   |        |     +-------+    ||
//                   |        |     +-------+    ||
//                   |      M5|<===>| LINEAR|<===// S2
//                   |      M6|     |       |    ||
//                   |        |     +-------+    ||
//                   |        |     +-------+    ||
//                   |      M7|<===>| MOVER |<===// S3
//                   |        |     |       |
//                   +--------+     +-------+
//------------------------------------------------------------------------------
`include "amba_axi_m8s2.v"
`include "axi_to_apb_s5.v"
`include "dpu_configuration.v"

module dut
     #(parameter FPGA_FAMILY       ="ZYNQ7000"
               , P_DATA_TYPE       ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , P_DATA_WIDTH      = 32
               `ifdef DATA_FIXED_POINT
               , P_DATA_WIDTH_Q    = P_DATA_WIDTH/2
               `endif
               , P_AXI_WIDTH_AD    =32 // AMBA AXI address width
               , P_AXI_WIDTH_DA    =32 // AMBA AXI data width
               , P_ADDR_BASE_MEM   =32'h0000_0000, P_SIZE_MEM   =(16*1024)
               , P_ADDR_BASE_CONF  =32'hC000_0000, P_SIZE_CONF  =( 4*1024)
               , P_ADDR_BASE_CONV  =32'hC000_1000, P_SIZE_CONV  =( 4*1024)
               , P_ADDR_BASE_POOL  =32'hC000_2000, P_SIZE_POOL  =( 4*1024)
               , P_ADDR_BASE_LINEAR=32'hC000_3000, P_SIZE_LINEAR=( 4*1024)
               , P_ADDR_BASE_MOVER =32'hC000_4000, P_SIZE_MOVER =( 4*1024)
               , P_ADDR_BASE_DPU   =P_ADDR_BASE_CONF, P_SIZE_DPU=(P_ADDR_BASE_MOVER+P_SIZE_MOVER-P_ADDR_BASE_DPU)
               , P_CONV_KERNEL_MAX_SIZE    =7
               , P_CONV_KERNEL_FIFO_DEPTH  =(1<<$clog2(P_CONV_KERNEL_MAX_SIZE*P_CONV_KERNEL_MAX_SIZE))
               , P_CONV_FEATURE_FIFO_DEPTH =(1<<$clog2(P_CONV_KERNEL_MAX_SIZE*2))
               , P_CONV_CHANNEL_FIFO_DEPTH =(1<<$clog2(P_CONV_KERNEL_MAX_SIZE*2))
               , P_CONV_RESULT_FIFO_DEPTH  =(1<<$clog2(P_CONV_KERNEL_MAX_SIZE*2))
               , P_POOL_KERNEL_MAX_SIZE    =4
               , P_POOL_FEATURE_FIFO_DEPTH =(1<<$clog2(P_POOL_KERNEL_MAX_SIZE*2))
               , P_POOL_RESULT_FIFO_DEPTH  =(1<<$clog2(P_POOL_KERNEL_MAX_SIZE*2))
               , P_LINEAR_BLOCK_MAX_SIZE   =64 // max burst length
               , P_LINEAR_INPUT_FIFO_DEPTH =(1<<$clog2(P_LINEAR_BLOCK_MAX_SIZE*2))
               , P_LINEAR_WEIGHT_FIFO_DEPTH=P_LINEAR_INPUT_FIFO_DEPTH
               , P_LINEAR_RESULT_FIFO_DEPTH=16
               , P_MOVER_SRC_FIFO_DEPTH    =64
               , P_MOVER_RESULT_FIFO_DEPTH =32
               )
(
     input  wire                SYS_CLK_STABLE
   , input  wire                SYS_CLK   // master clock and goes to SL_PCLK
   , output wire                SYS_RST_N // by-pass of SL_RST_N
   `ifndef COSIM_BFM
   , input  wire                SL_RST_N
   , output wire                SL_CS_N
   , output wire                SL_PCLK   // by-pass of SYS_CLK after phase shift
   , output wire [ 1:0]         SL_AD
   , input  wire                SL_FLAGA // active-low empty (U2F)
   , input  wire                SL_FLAGB // active-low almost-empty
   , input  wire                SL_FLAGC // active-low full (F2U)
   , input  wire                SL_FLAGD // active-low almost-full
   , output wire                SL_RD_N
   , output wire                SL_WR_N
   , output wire                SL_OE_N // when low, let FX3 drive data through SL_DT_I
   , output wire                SL_PKTEND_N
   , inout  wire [31:0]         SL_DT
   , input  wire [ 1:0]         SL_MODE
   `endif
   , input  wire                USR_CLK
);
   //---------------------------------------------------------------------------
   wire interrupt_conv, interrupt_pool, interrupt_linear, interrupt_mover;
   //---------------------------------------------------------------------------
   `include "dut_axi.v"
   `include "dut_axi_to_apb.v"
   `ifdef COSIM_BFM
   `include "dut_bfm_cosim.v"
   `else
   `include "dut_bfm.v"
   `endif
   `include "dut_mem.v"
   `include "dut_dpu_configuration.v"
   `include "dut_convolution_2d.v"
   `include "dut_pooling_2d.v"
   `include "dut_linear_1d.v"
   `include "dut_mover_2d.v"
   //---------------------------------------------------------------------------
   // make sure axi_to_apb_sN.CLOCK_RATIO be 2'b00 when ACLK==PCLK.
   // make sure axi_to_apb_sN.CLOCK_RATIO be 2'b11 when ACLK!=PCLK.
   assign                   ARESETn=SYS_RST_N;
   assign                   ACLK   =USR_CLK;
   assign                   PRESETn=SYS_RST_N;
   assign                   PCLK   =USR_CLK;
   //---------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2021.04.01: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
