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

`ifndef AXI_WIDTH_AD
`define AXI_WIDTH_AD 32
`endif
`ifndef AXI_WIDTH_DA
`define AXI_WIDTH_DA 32
`endif

module top;
   //---------------------------------------------------------------------------
   `ifndef DATA_WIDTH
    localparam P_N=32;
   `else
    localparam P_N=`DATA_WIDTH;
   `endif
   `ifdef DATA_FIXED_POINT
    localparam P_Q=`DATA_WIDTH/2;
   `endif
   `ifndef DATA_TYPE
    localparam P_DATA_TYPE = "INTEGER"; // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
   `else
    localparam P_DATA_TYPE = `DATA_TYPE;
   `endif

    localparam P_ADDR_BASE_MEM=32'hA0000000;
    localparam P_SIZE_MEM=4*1024*1024; // num of bytes for memory
    localparam P_ADDR_BASE_MOVER=32'hC0000000;
    localparam P_SIZE_MOVER=1024; // num of bytes for mover_2d csr

    localparam P_DELAY_WRITE_SETUP=0
             , P_DELAY_WRITE_BURST=0
             , P_DELAY_READ_SETUP =0
             , P_DELAY_READ_BURST =0;

    localparam NUM_CORES          = 1;
    localparam DATA_TYPE          = "INTEGER"
             , DATA_WIDTH         = P_N
             `ifdef DATA_FIXED_POINT
             , DATA_WIDTH_Q       = P_N/2
             `endif
             , SRC_FIFO_DEPTH     = 64
             , RESULT_FIFO_DEPTH  = 64;

    localparam COMMAND_NOP      = 'h0
             , COMMAND_FILL     = 'h1
             , COMMAND_COPY     = 'h2
             , COMMAND_RESIDUAL = 'h3 // point-to-point adder
             , COMMAND_CONCAT0  = 'h4
             , COMMAND_CONCAT1  = 'h5
             , COMMAND_TRANSPOSE= 'h6;

    localparam ACTIV_FUNC_BYPASS    =4'h0
             , ACTIV_FUNC_RELU      =4'h1
             , ACTIV_FUNC_LEAKY_RELU=4'h2
             , ACTIV_FUNC_SIGMOID   =4'h3
             , ACTIV_FUNC_TANH      =4'h4;
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
            `ifdef VCD
            $dumpfile("wave.vcd"); //$dumplimit(100000);
            $dumpvars(0);
            `endif
            wait(ARESETn==1'b0);
            wait(ARESETn==1'b1);
            repeat (10) @ (posedge ACLK);
            wait(u_tester.done==1'b1);
            repeat (10) @ (posedge ACLK);
            $finish(2);
    end

endmodule
//-----------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Re-written by Ando Ki (adki@future-ds.com)
//-----------------------------------------------------------------------------
