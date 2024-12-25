//------------------------------------------------------------------------------
// Copyright (c) 2021 by Future Design Systems
// All right reserved
// http://www.future-ds.com
//------------------------------------------------------------------------------
// fpga.v
//------------------------------------------------------------------------------
// VERSION: 2021.04.01.
//------------------------------------------------------------------------------
`include "clkmgra.v"
`include "dut.v"
`ifdef SIM
`timescale 1ns/1ps
`endif

//------------------------------------------------------------------------------
module fpga
     #(parameter SL_PCLK_FREQ   =80_000_000  // SL_PCLK and SYS_CLK
               , USR_CLK_FREQ   =`DPU_USR_CLK_FREQ  // USR_CLK for CMD/U2F/F2U-FIFO
               , P_DATA_TYPE    =`DPU_DATA_TYPE // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , P_DATA_WIDTH   =`DPU_DATA_WIDTH // 32, 16, 8
               `ifdef DATA_FIXED_POINT
               , P_DATA_WIDTH_Q =`DPU_DATA_WIDTH_Q // fractional for fixed point
               `endif
               , P_AXI_WIDTH_AD    =`AMBA_AXI_WIDTH_AD
               , P_AXI_WIDTH_DA    =`AMBA_AXI_WIDTH_DA
               , P_ADDR_BASE_MEM   =`DPU_ADDR_BASE_MEM   , P_SIZE_MEM   =`DPU_SIZE_MEM   
               , P_ADDR_BASE_DPU   =`DPU_ADDR_BASE_DPU   , P_SIZE_DPU   =`DPU_SIZE_DPU // all CONF,CONV,POOL,LINEAR,MOVER
               , P_ADDR_BASE_CONF  =`DPU_ADDR_BASE_CONF  , P_SIZE_CONF  =`DPU_SIZE_CONF
               , P_ADDR_BASE_CONV  =`DPU_ADDR_BASE_CONV  , P_SIZE_CONV  =`DPU_SIZE_CONV  
               , P_ADDR_BASE_POOL  =`DPU_ADDR_BASE_POOL  , P_SIZE_POOL  =`DPU_SIZE_POOL  
               , P_ADDR_BASE_LINEAR=`DPU_ADDR_BASE_LINEAR, P_SIZE_LINEAR=`DPU_SIZE_LINEAR
               , P_ADDR_BASE_MOVER =`DPU_ADDR_BASE_MOVER , P_SIZE_MOVER =`DPU_SIZE_MOVER 
               )
(
       (* mark_debug="true" *)input   wire          BOARD_RST_SW // synthesis xc_pulldown = 1
                                          // active-high reset (push-down makes high)
     , input   wire          BOARD_CLK_IN // reference clock input
     //-------------------------------------------------------------------------
     , output  wire  [ 1:0]  SET_VADJ // SET_VADJ[0]=AA13, SET_VADJ[1]=AB17 (LVCMOS25)
     , output  wire          VADJ_EN  // V14 (LVCMOS25)
     //-------------------------------------------------------------------------
     `ifndef COSIM_BFM
     , input   wire          SL_RST_N      // synthesis xc_pullup = 1
     , output  wire          SL_CS_N
     , output  wire          SL_PCLK
     , input   wire          SL_FLAGA      // synthesis xc_pulldown = 1
     , input   wire          SL_FLAGB      // synthesis xc_pulldown = 1
     , input   wire          SL_FLAGC      // synthesis xc_pulldown = 1
     , input   wire          SL_FLAGD      // synthesis xc_pulldown = 1
     , output  wire          SL_RD_N       // IF_RD
     , output  wire          SL_WR_N       // IF_WR
     , output  wire          SL_OE_N       // IF_OE
     , output  wire          SL_PKTEND_N   // IF_PKTEND
     , output  wire  [ 1:0]  SL_AD         // IF_ADDR[1:0]
     , inout   wire  [31:0]  SL_DT         // IF_DATA[31:0]
     , input   wire  [ 1:0]  SL_MODE
     `endif
);
    //--------------------------------------------------------------------------
    localparam BOARD_CLK_IN_FREQ=100_000_000;
    localparam FPGA_TYPE="z7"; // Zynq-7000
    localparam FPGA_FAMILY="ZYNQ7000"; // Zynq-7000
    //--------------------------------------------------------------------------
    wire SYS_CLK;
    (* mark_debug="true" *)wire SYS_CLK_STABLE;
    wire SYS_RST_N;
    wire USR_CLK;
    //--------------------------------------------------------------------------
    clkmgra #(.INPUT_CLOCK_FREQ(BOARD_CLK_IN_FREQ)
             ,.SYSCLK_FREQ     (SL_PCLK_FREQ)
             ,.CLKOUT1_FREQ    (USR_CLK_FREQ) // it does not affect for SPARTAN6
             ,.CLKOUT2_FREQ    ( 25_000_000)
             ,.CLKOUT3_FREQ    (150_000_000)
             ,.CLKOUT4_FREQ    (200_000_000)
             ,.FPGA_FAMILY     (FPGA_FAMILY))// ARTIX7, VIRTEX6, SPARTAN6
    u_clkmgr (
           .OSC_IN         ( BOARD_CLK_IN      )
         , .OSC_OUT        (  )
         , .SYS_CLK_OUT    ( SYS_CLK          )
         , .CLKOUT1        ( USR_CLK          )
         , .CLKOUT2        (  )
         , .CLKOUT3        (  )
         , .CLKOUT4        (  )
         , .SYS_CLK_LOCKED ( SYS_CLK_STABLE   )
    );
    //--------------------------------------------------------------------------
    // 2'b01(1.8V), 2'b10(2.5V), 2'b11(3.3V)
    cfg_vadj #(.P_SET_VALUE(2'b01))
    u_cfg_vadj (
          .RST     (~SYS_CLK_STABLE|BOARD_RST_SW ) //.RST     (~SYS_CLK_STABLE)
        , .CLK     ( BOARD_CLK_IN   )
        , .SET_VADJ( SET_VADJ       ) // SET_VADJ[0]=AA13, SET_VADJ[1]=AB17 (LVCMOS25)
        , .VADJ_EN ( VADJ_EN        )  // V14 (LVCMOS25)
    );
    //--------------------------------------------------------------------------
    dut #(.FPGA_FAMILY    ( FPGA_FAMILY  )// SPARTAN6, VIRTEX4
         ,.P_DATA_TYPE    ( P_DATA_TYPE    )
         ,.P_DATA_WIDTH   ( P_DATA_WIDTH   )
         `ifdef DATA_FIXED_POINT
         ,.P_DATA_WIDTH_Q ( P_DATA_WIDTH_Q )
         `endif
         ,.P_AXI_WIDTH_AD    (P_AXI_WIDTH_AD    )
         ,.P_AXI_WIDTH_DA    (P_AXI_WIDTH_DA    )
         ,.P_ADDR_BASE_MEM   (P_ADDR_BASE_MEM   ),.P_SIZE_MEM   (P_SIZE_MEM   )
         ,.P_ADDR_BASE_DPU   (P_ADDR_BASE_DPU   ),.P_SIZE_MEM   (P_SIZE_DPU   )
         ,.P_ADDR_BASE_CONF  (P_ADDR_BASE_CONF  ),.P_SIZE_MEM   (P_SIZE_CONF  )
         ,.P_ADDR_BASE_CONV  (P_ADDR_BASE_CONV  ),.P_SIZE_CONV  (P_SIZE_CONV  )
         ,.P_ADDR_BASE_POOL  (P_ADDR_BASE_POOL  ),.P_SIZE_POOL  (P_SIZE_POOL  )
         ,.P_ADDR_BASE_LINEAR(P_ADDR_BASE_LINEAR),.P_SIZE_LINEAR(P_SIZE_LINEAR)
         ,.P_ADDR_BASE_MOVER (P_ADDR_BASE_MOVER ),.P_SIZE_MOVER (P_SIZE_MOVER )
         )
    u_dut (
           .SYS_CLK_STABLE  ( SYS_CLK_STABLE )
         , .SYS_CLK         ( SYS_CLK        )
         , .SYS_RST_N       ( SYS_RST_N      ) // SL_RST_N&SYS_CLK_STABLE
         `ifndef COSIM_BFM
         , .SL_RST_N        ( SL_RST_N&~BOARD_RST_SW) //, .SL_RST_N        ( SL_RST_N)
         , .SL_CS_N         ( SL_CS_N        )
         , .SL_PCLK         ( SL_PCLK        )
         , .SL_AD           ( SL_AD          )
         , .SL_FLAGA        ( SL_FLAGA       )
         , .SL_FLAGB        ( SL_FLAGB       )
         , .SL_FLAGC        ( SL_FLAGC       )
         , .SL_FLAGD        ( SL_FLAGD       )
         , .SL_RD_N         ( SL_RD_N        )
         , .SL_WR_N         ( SL_WR_N        )
         , .SL_OE_N         ( SL_OE_N        )
         , .SL_PKTEND_N     ( SL_PKTEND_N    )
         , .SL_DT           ( SL_DT          )
         , .SL_MODE         ( SL_MODE        )
         `endif
         , .USR_CLK         ( USR_CLK        )
    );
    //--------------------------------------------------------------------------
    // synthesis translate_off
    real stamp_x, stamp_y;
    initial begin
         wait (SYS_RST_N==1'b0);
         wait (SYS_RST_N==1'b1);
         repeat (5) @ (posedge BOARD_CLK_IN);
         @ (posedge BOARD_CLK_IN); stamp_x = $realtime;
         @ (posedge BOARD_CLK_IN); stamp_y = $realtime;
         $display("%m BOARD_CLK_IN %.2f-nsec %.2f-MHz", stamp_y - stamp_x, 1000.0/(stamp_y-stamp_x));
         `ifndef COSIM_BFM
         @ (posedge SL_PCLK); stamp_x = $realtime;
         @ (posedge SL_PCLK); stamp_y = $realtime;
         $display("%m SL_PCLK %.2f-nsec %.2f-MHz", stamp_y - stamp_x, 1000.0/(stamp_y-stamp_x));
         `endif
         @ (posedge SYS_CLK); stamp_x = $realtime;
         @ (posedge SYS_CLK); stamp_y = $realtime;
         $display("%m SYS_CLK %.2f-nsec %.2f-MHz", stamp_y - stamp_x, 1000.0/(stamp_y-stamp_x));
         @ (posedge USR_CLK); stamp_x = $realtime;
         @ (posedge USR_CLK); stamp_y = $realtime;
         $display("%m USR_CLK %.2f-nsec %.2f-MHz", stamp_y - stamp_x, 1000.0/(stamp_y-stamp_x));
         $fflush();
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision history:
//
// 2021.04.01: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
