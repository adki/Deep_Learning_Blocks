//------------------------------------------------------------------------------
//  Copyright (c) 2021 by Ando Ki.
//  All right reserved.
//  http://www.future-ds.com
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//------------------------------------------------------------------------------
// tester_convolution_2d.v
//------------------------------------------------------------------------------
// VERSION: 2021.07.10.
//------------------------------------------------------------------------------
//  [MACROS]
//    AMBA_AXI4       - AMBA AXI4
//    AMBA_AXI_CACHE  -
//    AMBA_AXI_PROT   -
//    AMBA_AXI_QOS    -
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tester_convolution_2d
     #(parameter WIDTH_ID =4         // ID width in bits
               , WIDTH_AD =32        // address width
               , WIDTH_DA =32        // data width
               , WIDTH_DS =(WIDTH_DA/8) // data strobe width
               , WIDTH_DSB=$clog2(WIDTH_DS) // data strobe width
               , ADDR_BASE_MEM =32'hA0000000
               , SIZE_MEM      =4*1024*1024
               , ADDR_BASE_CONV=32'hC0000000
               , SIZE_CONV     =1024 // num of bytes of convolution_2d csr
               , DATA_TYPE     ="INTEGER"
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
     , output reg  [ 3:0]          ARREGION='h0
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
     `include "convolution_2d_tasks.v"
     //-----------------------------------------------------------
     integer arg;
     reg     done=1'b0      ;
     integer kernel_addr    ; // starting address
     integer kernel_width   ;
     integer kernel_height  ;
     integer kernel_num     ;
     integer kernel_leng    ;
     integer feature_addr   ; // starting address
     integer feature_width  ;
     integer feature_height ;
     integer feature_stride ;
     integer feature_padding_pre;
     integer feature_padding_post;
     integer feature_leng   ;
     integer result_addr    ; // starting address
     integer channel_addr   ; // starting address
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
           AWPROT      ='h0;
           `endif
           `ifdef AMBA_QOS
           AWQOS       ='h0;
           AWREGION    ='h0;
           `endif
           WDATA       = ~0;
           WSTRB       = 0;
           WLAST       = 0;
           WVALID      = 0;
           BREADY      = 0;
           ARID        = 0;
           ARADDR      = ~0;
           ARLEN       = 0;
           ARSIZE      = 0;
           ARBURST     = 0;
           ARVALID     = 0;
           `ifdef AMBA_AXI_CACHE
           ARCACHE     ='h0;
           `endif
           `ifdef AMBA_AXI_PROT
           ARPROT      ='h0;
           `endif
           `ifdef AMBA_QOS
           ARQOS       ='h0;
           ARREGION    ='h0;
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
           if ($value$plusargs("KERNEL_TEST=%d", arg) && arg) begin
               conv_init;
               kernel_addr = ADDR_BASE_MEM;
               kernel_width = 3;
               kernel_height = kernel_width;
               kernel_leng=kernel_width; // not AxLENG format
               kernel_test(kernel_addr, kernel_width, kernel_height, 0, kernel_leng);
           end
           //-----------------------------------------------------
           if ($value$plusargs("FEATURE_TEST=%d", arg) && arg) begin
               conv_init;
               kernel_addr = ADDR_BASE_MEM;
               kernel_width = 3;
               kernel_height = kernel_width;
               kernel_leng = kernel_width;

               feature_addr = ADDR_BASE_MEM+(128*DATA_BYTES);
               feature_width = 8;
               feature_height = feature_width;
               feature_stride = 1;
               feature_padding_pre = 0;
               feature_padding_post = 0;
               feature_leng=kernel_width; // not AxLENG format

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
               kernel_test( kernel_addr
                          , kernel_width
                          , kernel_height
                          , kernel_num
                          , kernel_leng);

               feature_test( feature_addr
                           , feature_width
                           , feature_height
                           , feature_stride
                           , feature_padding_pre
                           , feature_padding_post
                           , feature_leng);
           end
           //-----------------------------------------------------
           kernel_addr  = ADDR_BASE_MEM;
           feature_addr = kernel_addr+(128*128*DATA_BYTES);
           result_addr  = feature_addr+(128*128*DATA_BYTES);
           channel_addr = result_addr+(128*128*DATA_BYTES);
           //-----------------------------------------------------
           if ($value$plusargs("MAC_TEST_NOPADDING=%d", arg) && arg) begin

               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 1;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , 0 // input integer feature_padding_pre;
                       , 0 // input integer feature_padding_post;
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 3; kernel_height = 3;
               feature_width = 8; feature_height = 8;
               feature_stride = 2;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , 0 // input integer feature_padding_pre;
                       , 0 // input integer feature_padding_post;
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 5; kernel_height = 5;
               feature_width = 10; feature_height = 10;
               feature_stride = 1;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , 0 // input integer feature_padding_pre;
                       , 0 // input integer feature_padding_post;
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 5; kernel_height = 5;
               feature_width = 10; feature_height = 10;
               feature_stride = 2;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , 0 // input integer feature_padding_pre;
                       , 0 // input integer feature_padding_post;
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 5; kernel_height = 5;
               feature_width = 10; feature_height = 10;
               feature_stride = 3;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , 0 // input integer feature_padding_pre;
                       , 0 // input integer feature_padding_post;
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
           end
           //-----------------------------------------------------
           if ($value$plusargs("MAC_TEST_PADDING=%d", arg) && arg) begin
if (1) begin
               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 1;
               feature_padding_pre = kernel_width/2;
               feature_padding_post = kernel_height/2;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , feature_padding_pre
                       , feature_padding_post
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 2;
               feature_padding_pre = kernel_width/2;
               feature_padding_post = kernel_height/2;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , feature_padding_pre
                       , feature_padding_post
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 3;
               feature_padding_pre = kernel_width/2;
               feature_padding_post = kernel_height/2;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , feature_padding_pre
                       , feature_padding_post
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
end
if (1) begin
               kernel_width = 5; kernel_height = 5;
               feature_width = 10; feature_height = 10;
               feature_stride = 1;
               feature_padding_pre = 1;
               feature_padding_post = 1;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , feature_padding_pre
                       , feature_padding_post
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 5; kernel_height = 5;
               feature_width = 10; feature_height = 10;
               feature_stride = 1;
               feature_padding_pre = 2;
               feature_padding_post = 2;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , feature_padding_pre
                       , feature_padding_post
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 5; kernel_height = 5;
               feature_width = 10; feature_height = 10;
               feature_stride = 2;
               feature_padding_pre = 2;
               feature_padding_post = 2;
               test_mac( kernel_addr
                       , 5 // input integer kernel_width;
                       , 5 // input integer kernel_height;
                       , feature_addr
                       , 10 // input integer feature_width;
                       , 10 // input integer feature_height;
                       , 2  // input integer feature_stride;
                       , 2  // input integer feature_padding_pre;
                       , 2 // input integer feature_padding_post;
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
end
           end
           //-----------------------------------------------------
           // testing one-element kernel case
           if ($value$plusargs("MAC_TEST_PADDING_ASYMMETRY=%d", arg) && arg) begin
               kernel_width = 3; kernel_height = 3;
               feature_width = 6; feature_height = 6;
               feature_stride = 1;
               feature_padding_pre = kernel_width/2;
               feature_padding_post = 0;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , feature_padding_pre
                       , feature_padding_post
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
               kernel_width = 5; kernel_height = 5;
               feature_width = 10; feature_height = 10;
               feature_stride = 1;
               feature_padding_pre = 0;
               feature_padding_post = 1;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , feature_padding_pre
                       , feature_padding_post
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , kernel_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
           end
           //-----------------------------------------------------
           // testing one-element kernel case
           if ($value$plusargs("MAC_TEST_SINGLE_KERNEL=%d", arg) && arg) begin
               kernel_width = 1; kernel_height = 1;
               feature_width = 6; feature_height = 6;
               feature_stride = 1;
               feature_padding_pre = 0;
               feature_padding_post = 0;
               test_mac( kernel_addr
                       , kernel_width
                       , kernel_height
                       , feature_addr
                       , feature_width
                       , feature_height
                       , feature_stride
                       , feature_padding_pre
                       , feature_padding_post
                       , result_addr
                       , channel_addr
                       , 0 // input [DATA_WIDTH-1:0] bias;
                       , 0 // input integer activ_func;
                       , 0 // input [DATA_WIDTH-1:0] activ_param;
                       , feature_width // input integer result_leng
                       , 0 // input integer channel_leng (0 for not used)
                       );
           end
           //-----------------------------------------------------
           repeat (10) @ (posedge ACLK);
           done = 1'b1;
     end
     //-----------------------------------------------------------
     task test_mac;
          input integer kernel_addr;
          input integer kernel_width;
          input integer kernel_height;
          input integer feature_addr;
          input integer feature_width;
          input integer feature_height;
          input integer feature_stride;
          input integer feature_padding_pre;
          input integer feature_padding_post;
          input integer result_addr;
          input integer channel_addr;
          input [DATA_WIDTH-1:0] bias;
          input integer activ_func;
          input [DATA_WIDTH-1:0] activ_param;
          input integer result_leng    ; // not AxLENG format
          input integer channel_leng   ; // not AxLENG format
          integer result_width   ; // num of items
          integer result_height  ; // num of items
          integer channel_width  ; // num of items
          integer channel_height ;
          integer mac_operations ; // num of operations
          real stamp_start, stamp_end, duration;
          real period, num_cycles;
          integer profile_mac_num;
          integer profile_mac_ovr;
          integer profile_chn_ovr;
          integer profile_bia_ovr;
          integer profile_act_ovr;
          integer profile_cnt_rd ;
          integer profile_cnt_wr ;
     begin
         conv_init;
         //kernel_addr = ADDR_BASE_MEM;
         kernel_leng = kernel_width; // not AxLENG format

         //feature_addr = kernel_addr+((kernel_width*kernel_height*DATA_BYTES+63)/64)*64;
         feature_leng = kernel_width; // not AxLENG format

         //result_addr = feature_addr+((feature_width*feature_height*DATA_BYTES+63)/64)*64;
         conv_set( kernel_addr
                 , kernel_width
                 , kernel_height
                 , kernel_leng
                 , feature_addr
                 , feature_width
                 , feature_height
                 , feature_stride
                 , feature_padding_pre
                 , feature_padding_post
                 , feature_leng
                 , channel_addr
                 , channel_leng
                 , result_addr
                 , result_leng);
         kernel_fill(kernel_addr, kernel_width, kernel_height);
         feature_fill(feature_addr, feature_width, feature_height);
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
         result_clear(result_addr, result_width, result_height);

         //channel_addr = result_addr+((result_width*result_height*DATA_BYTES+63)/64)*64;
         channel_width  = result_width ;
         channel_height = result_height;
         channel_clear(channel_addr, channel_width, channel_height);

         profile_init;
         stamp_start = $realtime;
         conv_go_wait(1,1); // ie, blocking
         stamp_end = $realtime;
         duration = stamp_end - stamp_start;
         @ (posedge ACLK); stamp_start = $realtime;
         @ (posedge ACLK); period = $realtime - stamp_start;
         num_cycles = duration/period;
         profile_put;

         conv_clear_interrupt;

         // Actual MAC operations
         // Each resultant entry requires kernel*kernel multiplications.
         // NOTE: TOPS = (num of MAC units)*(frequency)*2
         mac_operations = result_width*result_height*kernel_width*kernel_height;

         if (mac_operations!=profile_mac_num)
            $display("%0t %m profile mac number mis-match: %d %d", $time, mac_operations, profile_mac_num);

         $display("%m cycles/MAC_operation (%0d MAC_operations): %f.", mac_operations, num_cycles/mac_operations);
         // Note multiplication and accumulation run in parallel fashion.
         // Note small value is better.

         check_result( kernel_addr, kernel_width, kernel_height
                     , feature_addr, feature_width, feature_height
                     , feature_stride
                     , feature_padding_pre, feature_padding_post
                     , result_addr, result_width, result_height
                     , channel_addr, channel_width, channel_height
                     , bias
                     , activ_func
                     , activ_param);
     end
     endtask
     //-----------------------------------------------------------
endmodule
//----------------------------------------------------------------
// Revision History
//
// 2021.07.10: Started by Ando Ki (adki@future-ds.com)
//----------------------------------------------------------------
