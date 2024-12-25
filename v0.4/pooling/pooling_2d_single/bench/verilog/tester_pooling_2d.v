//------------------------------------------------------------------------------
//  Copyright (c) 2021 by Ando Ki.
//  All right reserved.
//  http://www.future-ds.com
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//------------------------------------------------------------------------------
// tester_pooling_2d.v
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

module tester_pooling_2d
     #(parameter WIDTH_ID =4         // ID width in bits
               , WIDTH_AD =32        // address width
               , WIDTH_DA =32        // data width
               , WIDTH_DS =(WIDTH_DA/8) // data strobe width
               , WIDTH_DSB=$clog2(WIDTH_DS) // data strobe width
               , ADDR_BASE_MEM =32'hA0000000
               , SIZE_MEM      =4*1024*1024
               , ADDR_BASE_POOL=32'hC0000000
               , SIZE_POOL     =1024 // num of bytes of pooling_2d csr
               , DATA_WIDTH    =32 // whole 
               , DATA_BYTES    =(DATA_WIDTH/8)
               , EN            =1
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
     `include "pooling_2d_tasks.v"
     //-----------------------------------------------------------
     integer arg;
     reg     done=1'b0      ;
     integer kernel_width   ;
     integer kernel_height  ;
     integer kernel_num     ;
     integer feature_addr   ; // starting address
     integer feature_width  ;
     integer feature_height ;
     integer feature_stride ;
     integer feature_padding_pre;
     integer feature_padding_post;
     integer feature_leng   ;
     integer feature_channel;
     integer result_addr    ; // starting address
     integer operations     ;
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
           AWCACHE     ='h0;
           `endif
           `ifdef AMBA_AXI_PROT
           AWPROT     ='h0;
           `endif
           `ifdef AMBA_QOS
           AWQOS      ='h0;
           AWREGION   ='h0;
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
           AWSIZE      = 0;
           ARSIZE      = 0;
           ARBURST     = 0;
           ARVALID     = 0;
           `ifdef AMBA_AXI_CACHE
           ARCACHE     ='h0;
           `endif
           `ifdef AMBA_AXI_PROT
           ARPROT     ='h0;
           `endif
           `ifdef AMBA_QOS
           ARQOS      ='h0;
           ARREGION   ='h0;
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
               test_raw(7, ADDR_BASE_MEM,             128, 4, 4);
               test_raw(7, ADDR_BASE_MEM+128*4,       64,  2, 8);
               test_raw(7, ADDR_BASE_MEM+128*4+64*2, 32,  1, 16);
               test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32,            128, 4, 4);
               test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32+128*4,      64,  2, 8);
               test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32+128*4+64*2, 32,  1, 16);
           end
           //-----------------------------------------------------
           if ($value$plusargs("POOL_FEATURE_TEST=%d", arg) && arg) begin
               pool_init;
               kernel_width = 3;
               kernel_height = kernel_width;
               kernel_set(kernel_width,kernel_height);

               feature_addr = ADDR_BASE_MEM+(128*DATA_BYTES);
               feature_width = 8;
               feature_height = feature_width;
               feature_stride = 1;
               feature_padding_pre = 0;
               feature_padding_post = 0;
               feature_leng=kernel_width; // not AxLENG format
               feature_channel=1;

               kernel_num = func_result_size(kernel_width
                                            ,feature_width
                                            ,feature_stride
                                            ,feature_padding_pre
                                            ,feature_padding_post)*
                            func_result_size(kernel_height
                                            ,feature_height
                                            ,feature_stride
                                            ,feature_padding_pre
                                            ,feature_padding_post);
               feature_test( feature_addr
                           , feature_width
                           , feature_height
                           , feature_stride
                           , feature_padding_pre
                           , feature_padding_post
                           , feature_leng
                           , feature_channel);
           end
           //-----------------------------------------------------
           feature_addr = ADDR_BASE_MEM;
           result_addr  = feature_addr+(128*128*DATA_BYTES);
           //-----------------------------------------------------
           if ($value$plusargs("POOL_TEST_NOPADDING=%d", arg) && arg) begin
if (1) begin
               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 1;
               for (feature_channel=1; feature_channel<4; feature_channel=feature_channel+1) begin
                   $display("POOL_TEST_NOPADDING feature=%0dx%0d kernel=%0dx%0d stride=%0d channel=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride, feature_channel); $fflush();
                   test_pool( kernel_width
                            , kernel_height
                            , feature_addr
                            , feature_width
                            , feature_height
                            , feature_stride
                            , 0 // input integer feature_padding_pre;
                            , 0 // input integer feature_padding_post;
                            , feature_channel
                            , result_addr
                            , kernel_width // input integer result_leng
                            );
               end // for
end
if (1) begin
               kernel_width = 3; kernel_height = 3;
               feature_width = 8; feature_height = 8;
               feature_stride = 2;
               for (feature_channel=1; feature_channel<4; feature_channel=feature_channel+1) begin
                   $display("POOL_TEST_NOPADDING feature=%0dx%0d kernel=%0dx%0d stride=%0d channel=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride, feature_channel); $fflush();
                   test_pool( kernel_width
                            , kernel_height
                            , feature_addr
                            , feature_width
                            , feature_height
                            , feature_stride
                            , 0 // input integer feature_padding_pre;
                            , 0 // input integer feature_padding_post;
                            , feature_channel
                            , result_addr
                            , kernel_width // input integer result_leng
                            );
               end
end
if (1) begin
               kernel_width = 2; kernel_height = 2;
               feature_width = 9; feature_height = 9;
               feature_stride = 2;
               for (feature_channel=1; feature_channel<4; feature_channel=feature_channel+1) begin
                   $display("POOL_TEST_NOPADDING feature=%0dx%0d kernel=%0dx%0d stride=%0d channel=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride, feature_channel); $fflush();
                   test_pool( kernel_width
                            , kernel_height
                            , feature_addr
                            , feature_width
                            , feature_height
                            , feature_stride
                            , 0 // input integer feature_padding_pre;
                            , 0 // input integer feature_padding_post;
                            , feature_channel
                            , result_addr
                            , kernel_width // input integer result_leng
                            );
               end
end
           end
           //-----------------------------------------------------
           if ($value$plusargs("POOL_TEST_PADDING=%d", arg) && arg) begin
if (1) begin
               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 1;
               feature_padding_pre = kernel_width/2;
               feature_padding_post = kernel_height/2;
               for (feature_channel=1; feature_channel<4; feature_channel=feature_channel+1) begin
                   $display("POOL_TEST_PADDING feature=%0dx%0d kernel=%0dx%0d stride=%0d padding=%0dx%0d channel=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride, feature_padding_pre, feature_padding_post, feature_channel); $fflush();
                   test_pool( kernel_width
                           , kernel_height
                           , feature_addr
                           , feature_width
                           , feature_height
                           , feature_stride
                           , feature_padding_pre
                           , feature_padding_post
                           , feature_channel
                           , result_addr
                           , kernel_width // input integer result_leng
                           );
               end
end
if (1) begin
               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 2;
               feature_padding_pre = kernel_width/2;
               feature_padding_post = kernel_height/2;
               for (feature_channel=1; feature_channel<4; feature_channel=feature_channel+1) begin
                   $display("POOL_TEST_PADDING feature=%0dx%0d kernel=%0dx%0d stride=%0d padding=%0dx%0d channel=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride, feature_padding_pre, feature_padding_post, feature_channel); $fflush();
                   test_pool( kernel_width
                            , kernel_height
                            , feature_addr
                            , feature_width
                            , feature_height
                            , feature_stride
                            , feature_padding_pre
                            , feature_padding_post
                            , feature_channel
                            , result_addr
                            , kernel_width // input integer result_leng
                            );
               end
end
if (1) begin
               kernel_width = 3; kernel_height = 3;
               feature_width = 10; feature_height = 10;
               feature_stride = 3;
               feature_padding_pre = kernel_width/2;
               feature_padding_post = kernel_height/2;
               for (feature_channel=1; feature_channel<4; feature_channel=feature_channel+1) begin
                   $display("POOL_TEST_PADDING feature=%0dx%0d kernel=%0dx%0d stride=%0d padding=%0dx%0d channel=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride, feature_padding_pre, feature_padding_post, feature_channel); $fflush();
                   test_pool( kernel_width
                            , kernel_height
                            , feature_addr
                            , feature_width
                            , feature_height
                            , feature_stride
                            , feature_padding_pre
                            , feature_padding_post
                            , feature_channel
                            , result_addr
                            , kernel_width // input integer result_leng
                            );
               end
end
           end
           //-----------------------------------------------------
           // testing one-element kernel case
           if ($value$plusargs("POOL_TEST_PADDING_ASYMMETRY=%d", arg) && arg) begin
if (1) begin
               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 1;
               feature_padding_pre = kernel_width/2;
               feature_padding_post = 0;
               for (feature_channel=1; feature_channel<4; feature_channel=feature_channel+1) begin
                   $display("POOL_TEST_PADDING_ASYMMETRY feature=%0dx%0d kernel=%0dx%0d stride=%0d padding=%0dx%0d channel=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride, feature_padding_pre, feature_padding_post, feature_channel); $fflush();
                   test_pool( kernel_width
                           , kernel_height
                           , feature_addr
                           , feature_width
                           , feature_height
                           , feature_stride
                           , feature_padding_pre
                           , feature_padding_post
                           , feature_channel
                           , result_addr
                           , kernel_width // input integer result_leng
                           );
               end
end
if (1) begin
               kernel_width = 2; kernel_height = 2;
               feature_width = 10; feature_height = 10;
               feature_stride = 2;
               feature_padding_pre = 0;
               feature_padding_post = 1;
               for (feature_channel=1; feature_channel<4; feature_channel=feature_channel+1) begin
                   $display("POOL_TEST_PADDING_ASYMMETRY feature=%0dx%0d kernel=%0dx%0d stride=%0d padding=%0dx%0d channel=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride, feature_padding_pre, feature_padding_post, feature_channel); $fflush();
                   test_pool( kernel_width
                           , kernel_height
                           , feature_addr
                           , feature_width
                           , feature_height
                           , feature_stride
                           , feature_padding_pre
                           , feature_padding_post
                           , feature_channel
                           , result_addr
                           , kernel_width // input integer result_leng
                           );
               end
end
           end
           //-----------------------------------------------------
           repeat (10) @ (posedge ACLK);
           done = 1'b1;
     end
     //-----------------------------------------------------------
     task test_pool;
          input integer kernel_width;
          input integer kernel_height;
          input integer feature_addr;
          input integer feature_width;
          input integer feature_height;
          input integer feature_stride;
          input integer feature_padding_pre;
          input integer feature_padding_post;
          input integer feature_channel;
          input integer result_addr;
          input integer result_leng    ; // not AxLENG format
          integer result_width   ; // num of items
          integer result_height  ; // num of items
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
     begin
         pool_init;
         feature_leng = kernel_width; // not AxLENG format
         pool_set( kernel_width
                 , kernel_height
                 , feature_addr
                 , feature_width
                 , feature_height
                 , feature_stride
                 , feature_padding_pre
                 , feature_padding_post
                 , feature_leng
                 , feature_channel
                 , result_addr
                 , result_leng);
         feature_fill(feature_addr, feature_width, feature_height, feature_channel);
         result_width = func_result_size(kernel_width
                                        ,feature_width
                                        ,feature_stride
                                        ,feature_padding_pre
                                        ,feature_padding_post);
         result_height = func_result_size(kernel_height
                                         ,feature_height
                                         ,feature_stride
                                         ,feature_padding_pre
                                         ,feature_padding_post);
         result_clear(result_addr, result_width, result_height, feature_channel);

         profile_init;
         stamp_start = $realtime;
         pool_go_wait(1, 1); // ie, blocking
         stamp_end = $realtime;
         duration = stamp_end - stamp_start;
         @ (posedge ACLK); stamp_start = $realtime;
         @ (posedge ACLK); period = $realtime - stamp_start;
         num_cycles = duration/period;
         profile_put;

         pool_clear_interrupt;

         // Actual MAC operations
         // Each resultant entry requires kernel*kernel multiplications.
         // NOTE: TOPS = (num of MAC units)*(frequency)*2
         operations = result_width*result_height*kernel_width*kernel_height;

         $display("%m cycles/operation (%0d operations): %f.", operations, num_cycles/operations);
         // Note multiplication and accumulation run in parallel fashion.
         // Note small value is better.

         check_result( kernel_width, kernel_height
                     , feature_addr, feature_width, feature_height
                     , feature_stride
                     , feature_padding_pre, feature_padding_post
                     , feature_channel
                     , result_addr, result_width, result_height);
     end
     endtask
     //-----------------------------------------------------------
endmodule
//----------------------------------------------------------------
// Revision History
//
// 2013.02.03: Started by Ando Ki (adki@future-ds.com)
//----------------------------------------------------------------
