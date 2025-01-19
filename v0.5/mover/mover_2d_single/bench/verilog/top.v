//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//------------------------------------------------------------------------------
//    +-------+     +--------+     +--------+     +---------+
//    |tester |     |  AXI   |     |axi2apb |     |   MOVER |
//    |       |<===>|M0    S1|<===>|        |<===>|S        |
//    |       |     |        |     +--------+     |         |
//    +-------+     |        |                    |         |
//                  |      M1|<===================|MW1      |
//    +-------+     |      M1|===================>|MR1      |
//    |mem    |     |        |                    |         |
//    |       |<===>|S0      |                    |         |
//    |       |     |        |                    |         |
//    +-------+     +--------+                    +---------+
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

module top;
    //--------------------------------------------------------------------------
    localparam P_ADDR_BASE_MEM=`DPU_ADDR_BASE_MEM
             , P_SIZE_MEM=`DPU_SIZE_MEM // num of bytes for memory
             , P_ADDR_BASE_MOVER=`DPU_ADDR_BASE_MOVER
             , P_SIZE_MOVER=`DPU_SIZE_MOVER; // num of bytes for mover_2d csr

    localparam P_DELAY_WRITE_SETUP=0
             , P_DELAY_WRITE_BURST=0
             , P_DELAY_READ_SETUP =0
             , P_DELAY_READ_BURST =0;

    localparam DATA_TYPE          = `DPU_DATA_TYPE
             , DATA_WIDTH         = `DPU_DATA_WIDTH
             `ifdef DPU_DATA_FIXED_POINT
             , DATA_WIDTH_Q       = `DPU_DATA_WIDTH_Q
             `endif
             , SRC_FIFO_DEPTH     = 64
             , RESULT_FIFO_DEPTH  = 64;
    //--------------------------------------------------------------------------
    reg  ACLK=1'b0; always  #10 ACLK <= ~ACLK;
    reg  ARESETn= 1'b0;
    initial begin repeat (10) @ (posedge ACLK); ARESETn=1'b1; end
    //--------------------------------------------------------------------------
    reg  PCLK=1'b0; always  #15 PCLK <= ~PCLK;
    reg  PRESETn= 1'b0;
    initial begin repeat (10) @ (posedge PCLK); PRESETn=1'b1; end

    //--------------------------------------------------------------------------
    wire interrupt;

    //--------------------------------------------------------------------------
    `include "top_bus.v"
    `include "top_axi_to_apb.v"
    `include "top_mover_2d.v"
    `include "top_mem.v"
    `include "top_tester.v"
    
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
