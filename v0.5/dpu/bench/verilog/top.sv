//------------------------------------------------------------------------------
// Copyright (c) 2025 by Ando Ki
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//------------------------------------------------------------------------------
//                                 DPU
//                                +----------------------+
//    +--------+     +--------+   |  +-------+           |
//    | BFM    |<===>|M0    S1|<==|=>|AXI2APB|====\\     |
//    |        |     |        |   |  |       |    ||     |
//    +--------+     |        |   |  +-------+    ||     |
//    +--------+     |        |   |  +-------+    ||     |
//    | MEM    |<===>|M0    M1|<==|=>| CONV  |<===// S0  |
//    |        |     |      M2|   |  |       |    ||     |
//    +--------+     |      M3|   |  +-------+    ||     |
//                   |        |   |  +-------+    ||     |
//                   |      M4|<==|=>| POOL  |<===// S1  |
//                   |        |   |  |       |    ||     |
//                   |        |   |  +-------+    ||     |
//                   |        |   |  +-------+    ||     |
//                   |      M5|<==|=>| LINEAR|<===// S2  |
//                   |      M6|   |  |       |    ||     |
//                   |        |   |  +-------+    ||     |
//                   |        |   |  +-------+    ||     |
//                   |      M7|<==|=>| MOVER |<===// S3  |
//                   |        |   |  |       |           |
//                   +--------+   |  +-------+           |
//                                +----------------------+
//------------------------------------------------------------------------------
`timescale 1ns/1ps

`define AMBA_AXI4
`undef  AMBA_AXI_CACHE
`undef  AMBA_AXI_PROT
`undef  AMBA_QOS
`undef  AMBA_AXI_AWUSER
`undef  AMBA_AXI_WUSER
`undef  AMBA_AXI_BUSER
`undef  AMBA_AXI_ARUSER
`undef  AMBA_AXI_RUSER

`include "defines_system.v"
`include "amba_axi_m8s2.v"
`include "mem_axi_beh.v"
`include "tester_convolution_2d.v"

module top;
    //--------------------------------------------------------------------------
    localparam P_ADDR_BASE_MEM=`DPU_ADDR_BASE_MEM
             , P_SIZE_MEM     =`DPU_SIZE_MEM // num of bytes for memory
             , P_ADDR_BASE_DPU=`DPU_ADDR_BASE_DPU
             , P_SIZE_DPU     =`DPU_SIZE_DPU; // num of bytes for dpu

    localparam DATA_TYPE          = `DPU_DATA_TYPE
             , DATA_WIDTH         = `DPU_DATA_WIDTH
             `ifdef DPU_DATA_FIXED_POINT
             , DATA_WIDTH_Q       = `DPU_DATA_WIDTH_Q
             `endif
             ;

    //--------------------------------------------------------------------------
    reg  ACLK=1'b0; always  #10 ACLK <= ~ACLK;
    reg  ARESETn= 1'b0;
    initial begin repeat (10) @ (posedge ACLK); ARESETn=1'b1; end

    //--------------------------------------------------------------------------
    `include "top_axi.sv"
    `include "top_dpu.sv"
    `include "top_mem.sv"
    `include "top_tester.sv"
    
    //-------------------------------------------------------------------------
    initial begin
            $dumpfile("wave.vcd"); //$dumplimit(100000);
            $dumpvars(0,top);
            `ifndef COSIM_BFM
                wait(ARESETn==1'b0);
                wait(ARESETn==1'b1);
                repeat (10) @ (posedge ACLK);
                wait(u_tester.done==1'b1);
                repeat (10) @ (posedge ACLK);
                $finish(2);
            `endif
    end

endmodule
//-----------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Re-written by Ando Ki (adki@future-ds.com)
//-----------------------------------------------------------------------------
