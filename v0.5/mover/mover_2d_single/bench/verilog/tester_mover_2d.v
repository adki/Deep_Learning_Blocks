//------------------------------------------------------------------------------
//  Copyright (c) 2021 by Ando Ki.
//  All right reserved.
//  http://www.future-ds.com
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//------------------------------------------------------------------------------
// tester_mover_2d.v
//------------------------------------------------------------------------------
// VERSION: 2013.02.03.
//------------------------------------------------------------------------------
//  [MACROS]
//    AMBA_AXI4       - AMBA AXI4
//    AMBA_AXI_CACHE  -
//    AMBA_AXI_PROT   -
//    AMBA_AXI_QOS    -
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tester_mover_2d
     #(parameter WIDTH_ID =4         // ID width in bits
               , WIDTH_AD =32        // address width
               , WIDTH_DA =32        // data width
               , WIDTH_DS =(WIDTH_DA/8) // data strobe width
               , WIDTH_DSB=$clog2(WIDTH_DS) // data strobe width
               , ADDR_BASE_MEM  =32'hA0000000
               , SIZE_MEM       =4*1024*1024
               , ADDR_BASE_MOVER=32'hC0000000
               , SIZE_MOVER     =1024 // num of bytes of mover_2d csr
               , DATA_WIDTH     =32 // bit-width of an item
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , DATA_BYTES     =(DATA_WIDTH/8)
               , DATA_TYPE      ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , EN       =1,
       parameter [3:0] COMMAND_NOP      = 'h0,
       parameter [3:0] COMMAND_FILL     = 'h1,
       parameter [3:0] COMMAND_COPY     = 'h2,
       parameter [3:0] COMMAND_RESIDUAL = 'h3,// point-to-point adder
       parameter [3:0] COMMAND_CONCAT0  = 'h4,
       parameter [3:0] COMMAND_CONCAT1  = 'h5,
       parameter [3:0] COMMAND_TRANSPOSE= 'h6,
       parameter [3:0] ACTIV_FUNC_BYPASS    =4'h0,
       parameter [3:0] ACTIV_FUNC_RELU      =4'h1,
       parameter [3:0] ACTIV_FUNC_LEAKY_RELU=4'h2,
       parameter [3:0] ACTIV_FUNC_SIGMOID   =4'h3, // not yet
       parameter [3:0] ACTIV_FUNC_TANH      =4'h4 // not yet
               )
(
       input  wire                 ARESETn
     , input  wire                 ACLK
     //-----------------------------------------------------------
     , output reg  [WIDTH_ID-1:0]  AWID
     , output reg  [WIDTH_AD-1:0]  AWADDR
     `ifdef AMBA_AXI4
     , output reg  [ 7:0]          AWLEN
     , output reg                  AWLOCK
     `else
     , output reg  [ 3:0]          AWLEN
     , output reg  [ 1:0]          AWLOCK
     `endif
     , output reg  [ 2:0]          AWSIZE
     , output reg  [ 1:0]          AWBURST
     `ifdef AMBA_AXI_CACHE
     , output reg  [ 3:0]          AWCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , output reg  [ 2:0]          AWPROT
     `endif
     , output reg                  AWVALID
     , input  wire                 AWREADY
     `ifdef AMBA_QOS
     , output reg  [ 3:0]          AWQOS
     , output reg  [ 3:0]          AWREGION
     `endif
     //-----------------------------------------------------------
     , output reg  [WIDTH_DA-1:0]  WDATA
     , output reg  [WIDTH_DS-1:0]  WSTRB
     , output reg                  WLAST
     , output reg                  WVALID
     , input  wire                 WREADY
     //-----------------------------------------------------------
     , input  wire [WIDTH_ID-1:0]  BID
     , input  wire [ 1:0]          BRESP
     , input  wire                 BVALID
     , output reg                  BREADY
     //-----------------------------------------------------------
     , output reg  [WIDTH_ID-1:0]  ARID
     , output reg  [WIDTH_AD-1:0]  ARADDR
     `ifdef AMBA_AXI4
     , output reg  [ 7:0]          ARLEN
     , output reg                  ARLOCK
     `else
     , output reg  [ 3:0]          ARLEN
     , output reg  [ 1:0]          ARLOCK
     `endif
     , output reg  [ 2:0]          ARSIZE
     , output reg  [ 1:0]          ARBURST
     `ifdef AMBA_AXI_CACHE
     , output reg  [ 3:0]          ARCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , output reg  [ 2:0]          ARPROT
     `endif
     , output reg                  ARVALID
     , input  wire                 ARREADY
     `ifdef AMBA_QOS
     , output reg  [ 3:0]          ARQOS
     , output reg  [ 3:0]          ARREGION
     `endif
     //-----------------------------------------------------------
     , input  wire [WIDTH_ID-1:0]  RID
     , input  wire [WIDTH_DA-1:0]  RDATA
     , input  wire [ 1:0]          RRESP
     , input  wire                 RLAST
     , input  wire                 RVALID
     , output reg                  RREADY
);
     //-----------------------------------------------------------
     `include "axi_tasks.v"
     `include "mover_2d_tasks.v"
     //-----------------------------------------------------------
     integer arg;
     reg     done=1'b0      ;
     reg  [3:0]          command= COMMAND_NOP;
     reg  [WIDTH_AD-1:0] srcA_addr  ;
     reg  [15:0]         srcA_width ;
     reg  [15:0]         srcA_height;
     reg  [ 8:0]         srcA_leng  ; // not AxLEN
     reg  [WIDTH_AD-1:0] srcB_addr  ;
     reg  [15:0]         srcB_width ;
     reg  [15:0]         srcB_height;
     reg  [ 8:0]         srcB_leng  ; // not AxLEN
     reg  [WIDTH_AD-1:0] dst_addr   ;
     reg  [15:0]         dst_width  ;
     reg  [15:0]         dst_height ;
     reg  [ 8:0]         dst_leng   ; // not AxLEN
     reg  [DATA_WIDTH-1:0] fill_value;
     reg  [31:0] data;
     integer offset, indx, indy, indz;
localparam xWIDTHx =(5*WIDTH_DA)/(DATA_WIDTH);
localparam xHEIGHTx=(5*WIDTH_DA)/(DATA_WIDTH);
     //-----------------------------------------------------------
     initial begin
           AWID        = 0;
           AWADDR      = ~0;
           AWLEN       = 0;
           AWLOCK      ='h0;
           AWSIZE      = 0;
           AWBURST     = 0;
           AWVALID     = 0;
          `ifdef AMBA_AXI_CACHE
           AWCACHE      ='h0;
          `endif
          `ifdef AMBA_AXI_PROT
           AWPROT       ='h0;
          `endif
          `ifdef AMBA_QOS
           AWQOS        ='h0;
           AWREGION     ='h0;
          `endif
           WDATA       = ~0;
           WSTRB       = 0;
           WLAST       = 0;
           WVALID      = 0;
           BREADY      = 0;
           ARID        = 0;
           ARADDR      = ~0;
           ARLEN       = 0;
           ARLOCK      ='h0;
           ARSIZE      = 0;
           ARBURST     = 0;
           ARVALID     = 0;
          `ifdef AMBA_AXI_CACHE
           ARCACHE      ='h0;
          `endif
          `ifdef AMBA_AXI_PROT
           ARPROT       ='h0;
          `endif
          `ifdef AMBA_QOS
           ARQOS        ='h0;
           ARREGION     ='h0;
          `endif
           RREADY      = 0; 
           wait (ARESETn==1'b0);
           wait (ARESETn==1'b1);
           repeat (5) @ (posedge ACLK);
           //-----------------------------------------------------
           if ($value$plusargs("CSR_TEST=%d", arg) && arg) begin
               csr_test();
           end
           //-----------------------------------------------------
           if ($value$plusargs("MEM_TEST=%d", arg) && arg) begin
               $display("MEM_TEST=%0d", arg);
               test_raw(7, ADDR_BASE_MEM,            128, 4, 4);
               test_raw(7, ADDR_BASE_MEM+128*4,       64, 2, 8);
               test_raw(7, ADDR_BASE_MEM+128*4+64*2,  32, 1, 16);
               test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32,            128, 4, 4);
               test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32+128*4,      64,  2, 8);
               test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32+128*4+64*2, 32,  1, 16);
           end
           //-----------------------------------------------------
           srcA_addr = ADDR_BASE_MEM;
           srcB_addr = srcA_addr+(512*512*DATA_BYTES);
           dst_addr  = srcB_addr+(512*512*DATA_BYTES);
           if (srcB_addr>(ADDR_BASE_MEM+SIZE_MEM)) $display("%m ERROR address exceeds.");
           if (dst_addr >(ADDR_BASE_MEM+SIZE_MEM)) $display("%m ERROR address exceeds.");
           //===================================================================
           if ($value$plusargs("FILL_TEST_aligned=%d", arg) && arg) begin
               $display("FILL_TEST_aligned=%0d", arg);
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               dst_width = xWIDTHx; dst_height = xHEIGHTx; dst_leng = 9'h5;
               for (indx=0; indx<DATA_BYTES; indx=indx+1) begin
                    fill_value[indx*8+:8] = indx+1;
               end
               test_fill( dst_addr
                        , dst_width
                        , dst_height
                        , dst_leng
                        , fill_value
                        );
           end
           //-----------------------------------------------------
           if ($value$plusargs("FILL_TEST_misaligned=%d", arg) && arg) begin
               for (offset=1; offset<WIDTH_DS; offset=offset+1) begin
                   $display("FILL_TEST_misaligned=%0d", offset);
                   dst_addr [WIDTH_DSB-1:0] = offset;
                   dst_width = xWIDTHx; dst_height = xHEIGHTx; dst_leng = 9'h5;
                   for (indx=0; indx<DATA_BYTES; indx=indx+1) begin
                        fill_value[indx*8+:8] = ~(indx+1);
                   end
                   test_fill( dst_addr
                            , dst_width
                            , dst_height
                            , dst_leng
                            , fill_value
                            );
               end
           end
           //===================================================================
           if ($value$plusargs("COPY_TEST_aligned=%d", arg) && arg) begin
               $display("COPY_TEST_aligned=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               test_copy( srcA_addr
                        , srcA_width
                        , srcA_height
                        , srcA_leng
                        , dst_addr
                        );
           end
           //-----------------------------------------------------
           if ($value$plusargs("COPY_TEST_misaligned_src=%d", arg) && arg) begin
               for (offset=1; offset<WIDTH_DS; offset=offset+1) begin
                   $display("COPY_TEST_misaligned_src=%0d", offset);
                   srcA_addr[WIDTH_DSB-1:0] = offset;
                   dst_addr [WIDTH_DSB-1:0] = 'h0;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   test_copy( srcA_addr
                            , srcA_width
                            , srcA_height
                            , srcA_leng
                            , dst_addr
                            );
               end
           end
           //-----------------------------------------------------
           if ($value$plusargs("COPY_TEST_misaligned_dst=%d", arg) && arg) begin
               for (offset=1; offset<WIDTH_DS; offset=offset+1) begin
                   $display("COPY_TEST_misaligned_dst=%0d", offset);
                   srcA_addr[WIDTH_DSB-1:0] = 'h0;
                   dst_addr [WIDTH_DSB-1:0] = offset;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   test_copy( srcA_addr
                            , srcA_width
                            , srcA_height
                            , srcA_leng
                            , dst_addr
                            );
               end
           end
           //-----------------------------------------------------
           if ($value$plusargs("COPY_TEST_misaligned_src_dst=%d", arg) && arg) begin
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=1; indy<WIDTH_DS; indy=indy+1) begin
                   $display("COPY_TEST_misaligned_src_dst=%0d:%0d", indx, indy);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   dst_addr [WIDTH_DSB-1:0] = indy;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   test_copy( srcA_addr
                            , srcA_width
                            , srcA_height
                            , srcA_leng
                            , dst_addr
                            );
               end
               end
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=WIDTH_DS-1; indy>0; indy=indy-1) begin
                   $display("COPY_TEST_misaligned_src_dst=%0d:%0d", indx, indy);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   dst_addr [WIDTH_DSB-1:0] = indy;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   test_copy( srcA_addr
                            , srcA_width
                            , srcA_height
                            , srcA_leng
                            , dst_addr
                            );
               end
               end
           end
           //-----------------------------------------------------
           if ($value$plusargs("COPY_TEST_overwrite_aligned=%d", arg) && arg) begin
               $display("COPY_TEST_overwrite_aligned=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               test_copy( srcA_addr
                        , srcA_width
                        , srcA_height
                        , srcA_leng
                        , srcA_addr
                        );
           end
           //-----------------------------------------------------
           if ($value$plusargs("COPY_TEST_overwrite_misaligned=%d", arg) && arg) begin
               for (offset=1; offset<WIDTH_DS; offset=offset+1) begin
                   $display("COPY_TEST_overwrite_misaligned=%0d", offset);
                   srcA_addr[WIDTH_DSB-1:0] = offset;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   test_copy( srcA_addr
                            , srcA_width
                            , srcA_height
                            , srcA_leng
                            , srcA_addr
                            );
               end
           end
           //-----------------------------------------------------
           if ($value$plusargs("COPY_TEST_ACTIV_RELU_aligned=%d", arg) && arg) begin
               $display("COPY_TEST_ACTIV_RELU_aligned=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               test_copy_activation( srcA_addr
                                   , srcA_width
                                   , srcA_height
                                   , srcA_leng
                                   , dst_addr
                                   , ACTIV_FUNC_RELU // ReLU
                                   , 0 // param
                                   );
           end
           //-----------------------------------------------------
           if ($value$plusargs("COPY_TEST_ACTIV_LEAKY_RELU_aligned=%d", arg) && arg) begin
               $write("COPY_TEST_ACTIV_LEAKY_RELU_aligned=%0d ", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               $display("src=0x%08X dst=0x%08X W/H=%0d/%0d", srcA_addr, dst_addr, srcA_width, srcA_height);
               test_copy_activation( srcA_addr
                                   , srcA_width
                                   , srcA_height
                                   , srcA_leng
                                   , dst_addr
                                   , ACTIV_FUNC_LEAKY_RELU // ReLU
                                   , 1 // param
                                   );
           end
           //===================================================================
           if ($value$plusargs("CONCAT0_TEST_aligned=%d", arg) && arg) begin
               $write("CONCAT0_TEST_aligned=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               srcB_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
               $display("srcA=0x%08X srcB=0x%08X dst=0x%08X A.W/H=%0d/%0d B.W/H=%0d/%0d",
                         srcA_addr, srcB_addr, dst_addr, srcA_width, srcA_height, srcB_width, srcB_height);
               test_concat0( srcA_addr
                           , srcA_width
                           , srcA_height
                           , srcA_leng
                           , srcB_addr
                           , srcB_width // == srcA_width
                           , srcB_height
                           , srcB_leng
                           , dst_addr
                           );
           end
           //-----------------------------------------------------
           if ($value$plusargs("CONCAT0_TEST_asymmetric=%d", arg) && arg) begin
               // ASYMMETRIC: heights are differ
               $display("CONCAT0_TEST_asymmetric=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               srcB_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               srcB_width = xWIDTHx; srcB_height = xHEIGHTx+2; srcB_leng = 9'h5;
               test_concat0( srcA_addr
                           , srcA_width
                           , srcA_height
                           , srcA_leng
                           , srcB_addr
                           , srcB_width // == srcA_width
                           , srcB_height
                           , srcB_leng
                           , dst_addr
                           );
           end
           //-----------------------------------------------------
           if ($value$plusargs("CONCAT0_TEST_misaligned=%d", arg) && arg) begin
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=1; indy<WIDTH_DS; indy=indy+1) begin
               for (indz=1; indz<WIDTH_DS; indz=indz+1) begin
                   $display("CONCAT0_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_concat0( srcA_addr
                               , srcA_width
                               , srcA_height
                               , srcA_leng
                               , srcB_addr
                               , srcB_width // == srcA_width
                               , srcB_height
                               , srcB_leng
                               , dst_addr
                               );
               end
               end
               end
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=WIDTH_DS-1; indy>0; indy=indy-1) begin
               for (indz=1; indz<WIDTH_DS; indz=indz+1) begin
                   $display("CONCAT0_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_concat0( srcA_addr
                               , srcA_width
                               , srcA_height
                               , srcA_leng
                               , srcB_addr
                               , srcB_width // == srcA_width
                               , srcB_height
                               , srcB_leng
                               , dst_addr
                               );
               end
               end
               end
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=1; indy<WIDTH_DS; indy=indy+1) begin
               for (indz=WIDTH_DS-1; indz>0; indz=indz-1) begin
                   $display("CONCAT0_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_concat0( srcA_addr
                               , srcA_width
                               , srcA_height
                               , srcA_leng
                               , srcB_addr
                               , srcB_width // == srcA_width
                               , srcB_height
                               , srcB_leng
                               , dst_addr
                               );
               end
               end
               end
           end
           //===================================================================
           if ($value$plusargs("CONCAT1_TEST_aligned=%d", arg) && arg) begin
               $display("CONCAT1_TEST_aligned=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               srcB_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
               test_concat1( srcA_addr
                           , srcA_width
                           , srcA_height
                           , srcA_leng
                           , srcB_addr
                           , srcB_width // == srcA_width
                           , srcB_height
                           , srcB_leng
                           , dst_addr
                           );
           end
           //-----------------------------------------------------
           if ($value$plusargs("CONCAT1_TEST_asymmetric=%d", arg) && arg) begin
               // ASYMMETRIC: widths are differ
               $display("CONCAT1_TEST_asymmetric=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               srcB_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               srcB_width = xWIDTHx+7; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
               test_concat1( srcA_addr
                           , srcA_width
                           , srcA_height
                           , srcA_leng
                           , srcB_addr
                           , srcB_width // == srcA_width
                           , srcB_height
                           , srcB_leng
                           , dst_addr
                           );
           end
           //-----------------------------------------------------
           if ($value$plusargs("CONCAT1_TEST_misaligned=%d", arg) && arg) begin
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=1; indy<WIDTH_DS; indy=indy+1) begin
               for (indz=1; indz<WIDTH_DS; indz=indz+1) begin
                   $display("CONCAT1_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_concat1( srcA_addr
                               , srcA_width
                               , srcA_height
                               , srcA_leng
                               , srcB_addr
                               , srcB_width // == srcA_width
                               , srcB_height
                               , srcB_leng
                               , dst_addr
                               );
               end
               end
               end
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=WIDTH_DS-1; indy>0; indy=indy-1) begin
               for (indz=1; indz<WIDTH_DS; indz=indz+1) begin
                   $display("CONCAT1_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_concat1( srcA_addr
                               , srcA_width
                               , srcA_height
                               , srcA_leng
                               , srcB_addr
                               , srcB_width // == srcA_width
                               , srcB_height
                               , srcB_leng
                               , dst_addr
                               );
               end
               end
               end
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=1; indy<WIDTH_DS; indy=indy+1) begin
               for (indz=WIDTH_DS-1; indz>0; indz=indz-1) begin
                   $display("CONCAT1_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_concat1( srcA_addr
                               , srcA_width
                               , srcA_height
                               , srcA_leng
                               , srcB_addr
                               , srcB_width // == srcA_width
                               , srcB_height
                               , srcB_leng
                               , dst_addr
                               );
               end
               end
               end
           end
           //===================================================================
           if ($value$plusargs("RESIDUAL_TEST_aligned=%d", arg) && arg) begin
               $display("RESIDUAL_TEST_aligned=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               srcB_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
               test_residual( srcA_addr
                            , srcA_width
                            , srcA_height
                            , srcA_leng
                            , srcB_addr
                            , srcB_width // == srcA_width
                            , srcB_height
                            , srcB_leng
                            , dst_addr
                            );
           end
// need to check aligned-start/mis-aligned-end(num of data)
           //-----------------------------------------------------
           if ($value$plusargs("RESIDUAL_TEST_misaligned=%d", arg) && arg) begin
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=1; indy<WIDTH_DS; indy=indy+1) begin
               for (indz=1; indz<WIDTH_DS; indz=indz+1) begin
                   $display("RESIDUAL_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_residual( srcA_addr
                                , srcA_width
                                , srcA_height
                                , srcA_leng
                                , srcB_addr
                                , srcB_width // == srcA_width
                                , srcB_height
                                , srcB_leng
                                , dst_addr
                                );
               end
               end
               end
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=WIDTH_DS-1; indy>0; indy=indy-1) begin
               for (indz=1; indz<WIDTH_DS; indz=indz+1) begin
                   $display("RESIDUAL_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_residual( srcA_addr
                                , srcA_width
                                , srcA_height
                                , srcA_leng
                                , srcB_addr
                                , srcB_width // == srcA_width
                                , srcB_height
                                , srcB_leng
                                , dst_addr
                                );
               end
               end
               end
               for (indx=1; indx<WIDTH_DS; indx=indx+1) begin
               for (indy=1; indy<WIDTH_DS; indy=indy+1) begin
               for (indz=WIDTH_DS-1; indz>0; indz=indz-1) begin
                   $display("RESIDUAL_TEST_misaligned=%0d:%0d:%0d", indx, indy, indz);
                   srcA_addr[WIDTH_DSB-1:0] = indx;
                   srcB_addr[WIDTH_DSB-1:0] = indy;
                   dst_addr [WIDTH_DSB-1:0] = indz;
                   srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
                   srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
                   test_residual( srcA_addr
                                , srcA_width
                                , srcA_height
                                , srcA_leng
                                , srcB_addr
                                , srcB_width // == srcA_width
                                , srcB_height
                                , srcB_leng
                                , dst_addr
                                );
               end
               end
               end
           end
           //-----------------------------------------------------
           if ($value$plusargs("TRANSPOSE_TEST_aligned=%d", arg) && arg) begin
               $display("TRANSPOSE_TEST_aligned=%0d", arg);
               srcA_addr[WIDTH_DSB-1:0] = 'h0;
               dst_addr [WIDTH_DSB-1:0] = 'h0;
               srcA_width = xWIDTHx; srcA_height = xHEIGHTx; srcA_leng = 9'h5;
               srcB_width = xWIDTHx; srcB_height = xHEIGHTx; srcB_leng = 9'h5;
               test_transpose( srcA_addr
                             , srcA_width
                             , srcA_height
                             , srcA_leng
                             , dst_addr);
           end
           //-----------------------------------------------------
           repeat (10) @ (posedge ACLK);
           done = 1'b1;
     end
     //-----------------------------------------------------------
     task test_copy;
          input [WIDTH_AD-1:0] src_addr;
          input [15:0]         src_width;
          input [15:0]         src_height;
          input [ 8:0]         src_leng; // not AxLEN
          input [WIDTH_AD-1:0] dst_addr;
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
     begin
         mem_clear(src_addr, src_width, src_height+2); // make sure clear more space
         mem_clear(dst_addr, src_width, src_height+2); // make sure clear more space
         mem_fill (src_addr, src_width, src_height,1);

         mover_set_copy( dst_addr
                       , src_addr
                       , src_width
                       , src_height
                       , src_leng);

         profile_init;
         stamp_start = $realtime;
         mover_go_wait(1, 1); // ie, blocking
         stamp_end = $realtime;
         duration = stamp_end - stamp_start;
         @ (posedge ACLK); stamp_start = $realtime;
         @ (posedge ACLK); period = $realtime - stamp_start;
         num_cycles = duration/period;
         profile_put;

         mover_clear_interrupt;

         check_result_copy( dst_addr, srcA_addr, srcA_width, srcA_height);

         if ((top.u_mover.u_control.u_source.fifoA_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoA_full !=1'b0)||
             (top.u_mover.u_control.u_source.fifoB_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoB_full !=1'b0)||
             (top.u_mover.u_control.u_result.fifo_EMPTY !=1'b1)||
             (top.u_mover.u_control.u_result.fifo_FULL  !=1'b0))
             $display("%0t %m \033[0;31mERROR\033[0m FIFO not empty.", $time);
         else
             $display("%0t %m \033[0;33mOK\033[0m FIFO empty.", $time);
     end
     endtask
     //-----------------------------------------------------------
     task test_copy_activation;
          input [WIDTH_AD-1:0] src_addr;
          input [15:0]         src_width;
          input [15:0]         src_height;
          input [ 8:0]         src_leng; // not AxLEN
          input [WIDTH_AD-1:0] dst_addr;
          input integer        activ_func;
          input integer        activ_param;
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
     begin
         mem_clear(src_addr, src_width, src_height+2); // make sure clear more space
         mem_clear(dst_addr, src_width, src_height+2); // make sure clear more space
         mem_fill (src_addr, src_width, src_height,1);

         mover_set_copy( dst_addr
                       , src_addr
                       , src_width
                       , src_height
                       , src_leng);

         activation_set( activ_func, activ_param );

         profile_init;
         stamp_start = $realtime;
         mover_go_wait(1, 1); // ie, blocking
         stamp_end = $realtime;
         duration = stamp_end - stamp_start;
         @ (posedge ACLK); stamp_start = $realtime;
         @ (posedge ACLK); period = $realtime - stamp_start;
         num_cycles = duration/period;
         profile_put;

         mover_clear_interrupt;

         check_result_copy_activation( dst_addr, srcA_addr, srcA_width, srcA_height, activ_func, activ_param );

         if ((top.u_mover.u_control.u_source.fifoA_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoA_full !=1'b0)||
             (top.u_mover.u_control.u_source.fifoB_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoB_full !=1'b0)||
             (top.u_mover.u_control.u_result.fifo_EMPTY !=1'b1)||
             (top.u_mover.u_control.u_result.fifo_FULL  !=1'b0))
             $display("%0t %m \033[0;31mERROR\033[0m FIFO not empty.", $time);
         else
             $display("%0t %m \033[0;33mOK\033[0m FIFO empty.", $time);
     end
     endtask
     //-----------------------------------------------------------
     task test_fill;
          input [WIDTH_AD-1:0]   dst_addr;
          input [15:0]           dst_width;
          input [15:0]           dst_height;
          input [ 8:0]           dst_leng; // not AxLEN
          input [DATA_WIDTH-1:0] fvalue;
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
     begin
         mem_fill (dst_addr, dst_width, dst_height+1, 1);

         mover_set_fill( dst_addr
                       , fvalue
                       , dst_width*dst_height
                       , dst_leng);

         profile_init;
         stamp_start = $realtime;
         mover_go_wait(1, 1); // ie, blocking
         stamp_end = $realtime;
         duration = stamp_end - stamp_start;
         @ (posedge ACLK); stamp_start = $realtime;
         @ (posedge ACLK); period = $realtime - stamp_start;
         num_cycles = duration/period;
         profile_put;

         mover_clear_interrupt;

         check_result_fill( dst_addr, fvalue, dst_width*dst_height);

         if ((top.u_mover.u_control.u_source.fifoA_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoA_full !=1'b0)||
             (top.u_mover.u_control.u_source.fifoB_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoB_full !=1'b0)||
             (top.u_mover.u_control.u_result.fifo_EMPTY !=1'b1)||
             (top.u_mover.u_control.u_result.fifo_FULL  !=1'b0))
             $display("%0t %m \033[0;31mERROR\033[0m FIFO not empty.", $time);
         else
             $display("%0t %m \033[0;33mOK\033[0m FIFO empty.", $time);
     end
     endtask
     //-----------------------------------------------------------
     task test_concat0;
          input [WIDTH_AD-1:0] srcA_addr;
          input [15:0]         srcA_width;
          input [15:0]         srcA_height;
          input [ 8:0]         srcA_leng; // not AxLEN
          input [WIDTH_AD-1:0] srcB_addr;
          input [15:0]         srcB_width;
          input [15:0]         srcB_height;
          input [ 8:0]         srcB_leng; // not AxLEN
          input [WIDTH_AD-1:0] dst_addr;
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
     begin
         mem_clear(srcA_addr, srcA_width, srcA_height+1);
         mem_clear(srcB_addr, srcB_width, srcB_height+1);
         mem_clear(dst_addr, srcA_width, srcA_height+srcB_height+1);
         mem_fill (srcA_addr, srcA_width, srcA_height, 1);
         mem_fill (srcB_addr, srcB_width, srcB_height, 1);

         mover_set_concat0( dst_addr
                          , srcA_addr
                          , srcB_addr
                          , srcA_width
                          , srcA_height
                          , srcB_width
                          , srcB_height
                          , srcA_leng);

         profile_init;
         stamp_start = $realtime;
         mover_go_wait(1, 1); // ie, blocking
         stamp_end = $realtime;
         duration = stamp_end - stamp_start;
         @ (posedge ACLK); stamp_start = $realtime;
         @ (posedge ACLK); period = $realtime - stamp_start;
         num_cycles = duration/period;
         profile_put;

         mover_clear_interrupt;

         check_result_concat0( dst_addr
                             , srcA_addr
                             , srcB_addr
                             , srcA_width
                             , srcA_height
                             , srcB_width
                             , srcB_height);

         if ((top.u_mover.u_control.u_source.fifoA_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoA_full !=1'b0)||
             (top.u_mover.u_control.u_source.fifoB_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoB_full !=1'b0)||
             (top.u_mover.u_control.u_result.fifo_EMPTY !=1'b1)||
             (top.u_mover.u_control.u_result.fifo_FULL  !=1'b0))
             $display("%0t %m \033[0;31mERROR\033[0m FIFO not empty.", $time);
         else
             $display("%0t %m \033[0;33mOK\033[0m FIFO empty.", $time);
     end
     endtask
     //-----------------------------------------------------------
     task test_concat1;
          input [WIDTH_AD-1:0] srcA_addr;
          input [15:0]         srcA_width;
          input [15:0]         srcA_height;
          input [ 8:0]         srcA_leng; // not AxLEN
          input [WIDTH_AD-1:0] srcB_addr;
          input [15:0]         srcB_width;
          input [15:0]         srcB_height;
          input [ 8:0]         srcB_leng; // not AxLEN
          input [WIDTH_AD-1:0] dst_addr;
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
     begin
         mover_set_concat1( dst_addr
                          , srcA_addr
                          , srcB_addr
                          , srcA_width
                          , srcA_height
                          , srcB_width
                          , srcB_height
                          , srcA_leng);
         mem_fill(srcA_addr, srcA_width, srcA_height, 1);
         mem_fill(srcB_addr, srcB_width, srcB_height, 1);
         mem_clear(dst_addr,(srcA_width+srcB_width), srcA_height);

         profile_init;
         stamp_start = $realtime;
         mover_go_wait(1, 1); // ie, blocking
         stamp_end = $realtime;
         duration = stamp_end - stamp_start;
         @ (posedge ACLK); stamp_start = $realtime;
         @ (posedge ACLK); period = $realtime - stamp_start;
         num_cycles = duration/period;
         profile_put;

         mover_clear_interrupt;

         check_result_concat1( dst_addr
                             , srcA_addr
                             , srcB_addr
                             , srcA_width
                             , srcA_height
                             , srcB_width
                             , srcB_height);

         if ((top.u_mover.u_control.u_source.fifoA_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoA_full !=1'b0)||
             (top.u_mover.u_control.u_source.fifoB_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoB_full !=1'b0)||
             (top.u_mover.u_control.u_result.fifo_EMPTY !=1'b1)||
             (top.u_mover.u_control.u_result.fifo_FULL  !=1'b0))
             $display("%0t %m \033[0;31mERROR\033[0m FIFO not empty.", $time);
         else
             $display("%0t %m \033[0;33mOK\033[0m FIFO empty.", $time);
     end
     endtask
     //-----------------------------------------------------------
     task test_residual;
          input [WIDTH_AD-1:0] srcA_addr;
          input [15:0]         srcA_width;
          input [15:0]         srcA_height;
          input [ 8:0]         srcA_leng; // not AxLEN
          input [WIDTH_AD-1:0] srcB_addr;
          input [15:0]         srcB_width;
          input [15:0]         srcB_height;
          input [ 8:0]         srcB_leng; // not AxLEN
          input [WIDTH_AD-1:0] dst_addr;
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
     begin
         mover_set_residual( dst_addr
                           , srcA_addr
                           , srcB_addr
                           , srcA_width
                           , srcA_height
                           , srcA_leng);
         mem_fill(srcA_addr, srcA_width, srcA_height, 1);
         mem_fill(srcB_addr, srcB_width, srcB_height, 1);
         mem_clear(dst_addr,srcA_width, srcA_height+1);

         profile_init;
         stamp_start = $realtime;
         mover_go_wait(1, 1); // ie, blocking
         stamp_end = $realtime;
         duration = stamp_end - stamp_start;
         @ (posedge ACLK); stamp_start = $realtime;
         @ (posedge ACLK); period = $realtime - stamp_start;
         num_cycles = duration/period;
         profile_put;

         mover_clear_interrupt;

         check_result_residual( dst_addr
                              , srcA_addr
                              , srcB_addr
                              , srcA_width
                              , srcA_height);

         if ((top.u_mover.u_control.u_source.fifoA_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoA_full !=1'b0)||
             (top.u_mover.u_control.u_source.fifoB_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoB_full !=1'b0)||
             (top.u_mover.u_control.u_result.fifo_EMPTY !=1'b1)||
             (top.u_mover.u_control.u_result.fifo_FULL  !=1'b0))
             $display("%0t %m \033[0;31mERROR\033[0m FIFO not empty.", $time);
         else
             $display("%0t %m \033[0;33mOK\033[0m FIFO empty.", $time);
     end
     endtask
     //-----------------------------------------------------------
     task test_transpose;
          input [WIDTH_AD-1:0] src_addr;
          input [15:0]         src_width;
          input [15:0]         src_height;
          input [ 8:0]         src_leng; // not AxLEN
          input [WIDTH_AD-1:0] dst_addr;
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
     begin
         mover_set_transpose( dst_addr
                            , src_addr
                            , src_width
                            , src_height
                            , src_leng);
         check_result_transpose( dst_addr
                               , src_addr
                               , src_width
                               , src_height);

         if ((top.u_mover.u_control.u_source.fifoA_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoA_full !=1'b0)||
             (top.u_mover.u_control.u_source.fifoB_empty!=1'b1)||
             (top.u_mover.u_control.u_source.fifoB_full !=1'b0)||
             (top.u_mover.u_control.u_result.fifo_EMPTY !=1'b1)||
             (top.u_mover.u_control.u_result.fifo_FULL  !=1'b0))
             $display("%0t %m \033[0;31mERROR\033[0m FIFO not empty.", $time);
         else
             $display("%0t %m \033[0;33mOK\033[0m FIFO empty.", $time);
     end
     endtask
     //-------------------------------------------------------------------------
     task mem_fill;
         input [WIDTH_AD-1:0] addr;
         input [15:0]         width; // num of items
         input [15:0]         height; // num of items
         input integer        pattern; //0=fill_zero, 1=fill_
         integer Q, N, bytes;
         integer w, x;
         integer idx, idy, idz;
         reg [WIDTH_DA-1:0] dataW;
     begin
          mover_get_config(Q,N,w,x);
          if (Q!=0) $display("%0t %m ERROR Q %0d.", $time, Q);
          bytes = N/8;
          if (bytes!=DATA_BYTES) $display("%0t %m ERROR width mis-match.", $time);
          idz = 1;
          for (idx=0; idx<(width*height); idx=idx+1) begin
               for (idy=0; idy<DATA_BYTES; idy=idy+1) begin
                   dataW[idy*8+:8] = (pattern==0) ? 'h0 : idz<<Q; //(idx*WIDTH_DS+idy+1)<<Q;
                   idz = idz + 1;
               end
               top.u_mem.write(addr, dataW, bytes); // direct call task
                                                    // can deal with mis-aligned write
#1;
               addr   = addr+bytes;
          end
     end
     endtask
     //-------------------------------------------------------------------------
     task mem_clear;
         input [WIDTH_AD-1:0] addr;
         input [15:0]         width;
         input [15:0]         height;
     begin
         mem_fill(addr, width, height, 0);
     end
     endtask
     //-----------------------------------------------------------
endmodule
//----------------------------------------------------------------
// Revision History
//
// 2013.02.03: Started by Ando Ki (adki@future-ds.com)
//----------------------------------------------------------------
