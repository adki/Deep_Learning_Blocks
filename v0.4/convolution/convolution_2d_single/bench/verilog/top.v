//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//------------------------------------------------------------------------------
//    +-------+     +--------+     +--------+     +---------+
//    |tester |     |  AXI   |     |axi2apb |     |   CONV  |
//    |or     |<===>|M0    S1|<===>|        |<===>|S        |
//    |BFM    |     |        |     +--------+     |         |
//    +-------+     |        |                    |         |
//                  |      M1|<===================|MW1      |
//    +-------+     |      M1|===================>|MR1      |
//    |mem    |     |        |                    |         |
//    |       |<===>|S0    M2|===================>|MR2      |
//    |       |     |      M3|===================>|MR3      |
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

`ifndef DATA_TYPE
`define DATA_TYPE  "FLOATING_POINT"
`endif
`ifndef DATA_WIDTH
`define DATA_WIDTH 32
`endif
`ifdef  DATA_FIXED_POINT
`ifndef DATA_WIDTH_Q
`define DATA_WIDTH_Q  (`DATA_WIDTH/2)
`endif
`endif

module top;
    //--------------------------------------------------------------------------
    localparam P_ADDR_BASE_MEM=`DPU_ADDR_BASE_MEM
             , P_SIZE_MEM=`DPU_SIZE_MEM // num of bytes for memory
             , P_ADDR_BASE_CONV=`DPU_ADDR_BASE_CONV
             , P_SIZE_CONV=`DPU_SIZE_CONV; // num of bytes for convolution_2d csr

    localparam P_DELAY_WRITE_SETUP=0
             , P_DELAY_WRITE_BURST=0
             , P_DELAY_READ_SETUP =0
             , P_DELAY_READ_BURST =0;

    localparam DATA_TYPE          = `DATA_TYPE
             , DATA_WIDTH         = `DATA_WIDTH
             `ifdef DATA_FIXED_POINT
             , DATA_WIDTH_Q       = `DATA_WIDTH_Q
             `endif
             , KERNEL_MAX_SIZE    = 7
             , KERNEL_FIFO_DEPTH  = 1<<$clog2(KERNEL_MAX_SIZE*KERNEL_MAX_SIZE)
             , FEATURE_FIFO_DEPTH = 32
             , CHANNEL_FIFO_DEPTH = 16
             , RESULT_FIFO_DEPTH  = 16;
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
    `include "top_convolution_2d.v"
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
