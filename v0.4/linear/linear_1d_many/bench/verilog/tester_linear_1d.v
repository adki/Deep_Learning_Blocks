//------------------------------------------------------------------------------
//  Copyright (c) 2021 by Ando Ki.
//  All right reserved.
//  http://www.future-ds.com
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//------------------------------------------------------------------------------
// tester_linear_1d.v
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

module tester_linear_1d
     #(parameter WIDTH_ID =4         // ID width in bits
               , WIDTH_AD =32        // address width
               , WIDTH_DA =32        // data width
               , WIDTH_DS =(WIDTH_DA/8) // data strobe width
               , WIDTH_DSB=$clog2(WIDTH_DS) // data strobe width
               , ADDR_BASE_MEM =32'hA0000000
               , SIZE_MEM      =4*1024*1024
               , ADDR_BASE_LINEAR=32'hC0000000
               , SIZE_LINEAR     =1024 // num of bytes of convolution_2d csr
               , DATA_WIDTH      =32 // whole 
               , DATA_BYTES      =(DATA_WIDTH/8)
               , EN              =1
               , MAX_WEIGHT_WIDTH =320
               , MAX_WEIGHT_HEIGHT=320
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
    `include "linear_1d_tasks.v"
    //-----------------------------------------------------------
    integer arg;
    reg     done=1'b0    ;
    integer input_addr   ; // starting address
    integer input_size   ;
    integer input_leng   ;
    integer weight_addr  ; // starting address
    integer weight_width ;
    integer weight_height;
    integer weight_leng  ;
    integer bias_addr    ; // starting address
    integer bias_size    ;
    integer result_addr  ; // starting address
    integer result_size  ;
    integer result_leng  ;
    integer                activ_func;
    reg     [DATA_WIDTH-1:0] activ_param;
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
        ARLOCK      ='h0;
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
            $display("CSR_TEST"); $fflush();
            csr_test();
        end
        //-----------------------------------------------------
        if ($value$plusargs("MEM_TEST=%d", arg) && arg) begin
            $display("MEM_TEST"); $fflush();
            test_raw(7, ADDR_BASE_MEM,             128, 4, 4);
            test_raw(7, ADDR_BASE_MEM+128*4,       64,  2, 8);
            test_raw(7, ADDR_BASE_MEM+128*4+64*2, 32,  1, 16);
            test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32,            128, 4, 4);
            test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32+128*4,      64,  2, 8);
            test_raw_all(7, ADDR_BASE_MEM+128*4+64*2+32+128*4+64*2, 32,  1, 16);
        end
        //-----------------------------------------------------
        input_addr  = ADDR_BASE_MEM;
        weight_addr = input_addr+(MAX_WEIGHT_WIDTH*DATA_BYTES);
        bias_addr   = weight_addr+(MAX_WEIGHT_WIDTH*MAX_WEIGHT_HEIGHT*DATA_BYTES);
        result_addr = bias_addr+(MAX_WEIGHT_HEIGHT*DATA_BYTES);
        //-----------------------------------------------------
        if ($value$plusargs("LINEAR_TEST_NO_BIAS=%d", arg) && arg) begin
            $display("LINEAR_TEST_NO_BIAS"); $fflush();
            input_leng    = 16;
            input_size    = input_leng*4;
            weight_leng   = 16;
            weight_width  = input_size;
            weight_height = weight_leng*2;
            bias_size     = 0; // no-bias
            result_size   = weight_height;
            result_leng   = 16; // any bust length (will be adjusted not to exceed weight_height)
            activ_func    = 0;
            activ_param   = 0;
            linear_test( input_addr
                       , input_size
                       , input_leng
                       , weight_addr
                       , weight_width
                       , weight_height
                       , weight_leng
                       , bias_addr
                       , bias_size
                       , result_addr
                       , result_size
                       , result_leng
                       , activ_func
                       , activ_param
                       , 0); // use known value
        end
        //-----------------------------------------------------
        if ($value$plusargs("LINEAR_TEST_BIAS=%d", arg) && arg) begin
            $display("LINEAR_TEST_BIAS"); $fflush();
            input_leng    = 16;
            input_size    = input_leng*4;
            weight_leng   = 16;
            weight_width  = input_size;
            weight_height = weight_leng*2;
            bias_size     = weight_height;
            result_size   = weight_height;
            result_leng   = 16; // any bust length (will be adjusted not to exceed weight_height)
            activ_func    = 0;
            activ_param   = 0;
            linear_test( input_addr
                       , input_size
                       , input_leng
                       , weight_addr
                       , weight_width
                       , weight_height
                       , weight_leng
                       , bias_addr
                       , bias_size
                       , result_addr
                       , result_size
                       , result_leng
                       , activ_func
                       , activ_param
                       , 0); // use known value
        end
        //-----------------------------------------------------
        if ($value$plusargs("LINEAR_TEST_MISALIGNED_BLOCK=%d", arg) && arg) begin
            $display("LINEAR_TEST_MISALIGNED_BLOCK"); $fflush();
            input_leng    = 16;
            input_size    = input_leng*2+input_leng/2;
            weight_leng   = 16;
            weight_width  = input_size;
            weight_height = weight_leng*2+weight_leng/3;
            bias_size     = weight_height;
            result_size   = weight_height;
            result_leng   = 4; // any bust length (will be adjusted not to exceed weight_height)
            activ_func    = 0;
            activ_param   = 0;
            linear_test( input_addr
                       , input_size
                       , input_leng
                       , weight_addr
                       , weight_width
                       , weight_height
                       , weight_leng
                       , bias_addr
                       , bias_size
                       , result_addr
                       , result_size
                       , result_leng
                       , activ_func
                       , activ_param
                       , 0); // use known value
        end
        //-----------------------------------------------------
        if ($value$plusargs("LINEAR_TEST_BIAS_RELU=%d", arg) && arg) begin
            $display("LINEAR_TEST_BIAS_RELU"); $fflush();
            input_leng    = 16;
            input_size    = input_leng*4;
            weight_leng   = 16;
            weight_width  = input_size;
            weight_height = weight_leng*2;
            bias_size     = weight_height;
            result_size   = weight_height;
            result_leng   = 16; // any bust length (will be adjusted not to exceed weight_height)
            activ_func    = 1; // ReLU
            activ_param   = 0;
            linear_test( input_addr
                       , input_size
                       , input_leng
                       , weight_addr
                       , weight_width
                       , weight_height
                       , weight_leng
                       , bias_addr
                       , bias_size
                       , result_addr
                       , result_size
                       , result_leng
                       , activ_func
                       , activ_param
                       , 0); // use known value
        end
        //-----------------------------------------------------
        if ($value$plusargs("LINEAR_TEST_NO_BIAS_RANDOM=%d", arg) && arg) begin
            $display("LINEAR_TEST_NO_BIAS_RANDOM"); $fflush();
            input_leng    = 16;
            input_size    = input_leng;
            weight_leng   = 16;
            weight_width  = input_size;
            weight_height = weight_leng;
            bias_size     = 0;
            result_size   = weight_height;
            result_leng   = 4; // any bust length (will be adjusted not to exceed weight_height)
            activ_func    = 0;
            activ_param   = 0;
            linear_test( input_addr
                       , input_size
                       , input_leng
                       , weight_addr
                       , weight_width
                       , weight_height
                       , weight_leng
                       , bias_addr
                       , bias_size
                       , result_addr
                       , result_size
                       , result_leng
                       , activ_func
                       , activ_param
                       , 1);
        end
        //-----------------------------------------------------
        if ($value$plusargs("LINEAR_TEST_BIAS_RANDOM=%d", arg) && arg) begin
            $display("LINEAR_TEST_BIAS_RANDOM"); $fflush();
            input_leng    = 16;
            input_size    = input_leng;
            weight_leng   = 16;
            weight_width  = input_size;
            weight_height = weight_leng;
            bias_size     = weight_height;
            result_size   = weight_height;
            result_leng   = 4; // any bust length (will be adjusted not to exceed weight_height)
            activ_func    = 0;
            activ_param   = 0;
            linear_test( input_addr
                       , input_size
                       , input_leng
                       , weight_addr
                       , weight_width
                       , weight_height
                       , weight_leng
                       , bias_addr
                       , bias_size
                       , result_addr
                       , result_size
                       , result_leng
                       , activ_func
                       , activ_param
                       , 1);
        end
        //-----------------------------------------------------
        if ($value$plusargs("LINEAR_TEST_BIAS_RANDOM_MISALIGNED_BLOCK=%d", arg) && arg) begin
            $display("LINEAR_TEST_BIAS_RANDOM_MISALIGNED_BLOCK"); $fflush();
            input_leng    = 16;
            input_size    = input_leng*2+input_leng/3;
            weight_leng   = 16;
            weight_width  = input_size;
            weight_height = weight_leng*2+weight_leng/3;
            bias_size     = weight_height;
            result_size   = weight_height;
            result_leng   = 4; // any bust length (will be adjusted not to exceed weight_height)
            activ_func    = 0;
            activ_param   = 0;
            linear_test( input_addr
                       , input_size
                       , input_leng
                       , weight_addr
                       , weight_width
                       , weight_height
                       , weight_leng
                       , bias_addr
                       , bias_size
                       , result_addr
                       , result_size
                       , result_leng
                       , activ_func
                       , activ_param
                       , 1);
        end
        //-----------------------------------------------------
        repeat (10) @ (posedge ACLK);
        done = 1'b1;
    end
    //-----------------------------------------------------------
    task linear_test;
         input integer input_addr;
         input integer input_size;
         input integer input_leng;
         input integer weight_addr;
         input integer weight_width; // =input_size
         input integer weight_height;
         input integer weight_leng;
         input integer bias_addr;
         input integer bias_size; // set 0 for no-bias
         input integer result_addr; // =previous_addr
         input integer result_size; // =weight_height (not AxLENG format)
         input integer result_leng; // =bias_leng (not AxLENG format)
         input integer          activ_func;
         input [DATA_WIDTH-1:0] activ_param;
         input                  random;

         real stamp_start, stamp_end, duration;
         real period, num_cycles;

    begin
        linear_init;
        linear_set(input_addr    //input integer input_addr;
                  ,input_size    //input integer input_size;
                  ,input_leng
                  ,weight_addr   //input integer weight_addr;
                  ,weight_width  //input integer weight_width; // =input_size
                  ,weight_height //input integer weight_height;
                  ,weight_leng
                  ,bias_addr     //input integer bias_addr;
                  ,bias_size     //input integer bias_size; // set 0 for no-bias
                  ,result_addr   //input integer result_addr; // =previous_addr
                  ,result_size   //input integer result_size; // =weight_height (not AxLENG format)
                  ,result_leng   //input integer result_leng; // =bias_leng (not AxLENG format)
                  ,activ_func    //input integer          activ_func;
                  ,activ_param   //input [DATA_WIDTH-1:0] activ_param;
                  ,1 // fill
                  ,random
                  );

        profile_init;
        stamp_start = $realtime;
        linear_go_wait(1,1); // ie, blocking
        stamp_end = $realtime;
        duration = stamp_end - stamp_start;
        @ (posedge ACLK); stamp_start = $realtime;
        @ (posedge ACLK); period = $realtime - stamp_start;
        num_cycles = duration/period;
        profile_put;
        
        linear_clear_interrupt;
        
        check_result(input_addr    //input integer input_addr;
                    ,input_size    //input integer input_size;
                    ,weight_addr   //input integer weight_addr;
                    ,weight_width  //input integer weight_width; // =input_size
                    ,weight_height //input integer weight_height;
                    ,bias_addr     //input integer bias_addr;
                    ,bias_size     //input integer bias_size; // set 0 for no-bias
                    ,result_addr   //input integer result_addr; // =previous_addr
                    ,result_size   //input integer result_size; // =weight_height (not AxLENG format)
                    ,activ_func    //input integer          activ_func;
                    ,activ_param   //input [DATA_WIDTH-1:0] activ_param;
                    );
    end
    endtask
endmodule
//----------------------------------------------------------------
// Revision History
//
// 2021.07.10: Started by Ando Ki (adki@future-ds.com)
//----------------------------------------------------------------
