//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//------------------------------------------------------------------------------
`timescale 1ns/1ps

`ifndef WIDTH_DATA
`define WIDTH_DATA 32
`endif

module top;
   //---------------------------------------------------------------------------
   localparam  N=`WIDTH_DATA
             , E=(N==32) ? 8 : (N==16) ? 5 : 0
             , F= N-(E+1);
    //--------------------------------------------------------------------------
    wire [N-1:0] MAX_POS={1'b0,{E{1'b1}},1'b1,{F-1{1'b0}}};
    wire [N-1:0] MAX_NEG={1'b1,{E{1'b1}},1'b1,{F-1{1'b0}}};
    //--------------------------------------------------------------------------
    reg  ACLK=1'b0; always  #10 ACLK <= ~ACLK;
    reg  ARESETn= 1'b0;
    initial begin repeat (10) @ (posedge ACLK); ARESETn=1'b1; end
    //--------------------------------------------------------------------------
    `ifdef __ICARUS__
    `define NET_DELAY 
    `else
    `define NET_DELAY  #(1)
    `endif
    //--------------------------------------------------------------------------
    wire                      RESET_N     =ARESETn;
    wire                      CLK=ACLK    ;
    wire                      INIT        =1'b0;
    wire          `NET_DELAY  READY       ;
    wire          `NET_DELAY  IN_READY_A  ;
    wire  [N-1:0] `NET_DELAY  IN_DATA_A   ;
    wire          `NET_DELAY  IN_VALID_A  ;
    wire          `NET_DELAY  IN_LAST_A   ;
    wire          `NET_DELAY  IN_READY_B  ;
    wire  [N-1:0] `NET_DELAY  IN_DATA_B   ;
    wire          `NET_DELAY  IN_VALID_B  ;
    wire          `NET_DELAY  IN_LAST_B   ;
    wire  [N-1:0] `NET_DELAY  OUT_MAC_DATA    ;
    wire          `NET_DELAY  OUT_MAC_VALID   ;
    wire          `NET_DELAY  OUT_MAC_READY   ;
    wire          `NET_DELAY  OUT_MAC_LAST    ;
    wire          `NET_DELAY  OUT_MAC_OVERFLOW;
    //--------------------------------------------------------------------------
    mac_core #(.WIDTH_DATA(N))
    u_mac (
          .RESET_N      ( RESET_N      )
        , .CLK          ( CLK          )
        , .INIT         ( INIT         )
        , .READY        ( READY        )
        , .IN_READY_A   ( IN_READY_A   )
        , .IN_DATA_A    ( IN_DATA_A    )
        , .IN_VALID_A   ( IN_VALID_A   )
        , .IN_LAST_A    ( IN_LAST_A    )
        , .IN_READY_B   ( IN_READY_B   )
        , .IN_DATA_B    ( IN_DATA_B    )
        , .IN_VALID_B   ( IN_VALID_B   )
        , .IN_LAST_B    ( IN_LAST_B    )
        , .OUT_DATA     ( OUT_MAC_DATA     )
        , .OUT_VALID    ( OUT_MAC_VALID    )
        , .OUT_READY    ( OUT_MAC_READY    )
        , .OUT_LAST     ( OUT_MAC_LAST     )
        , .OUT_OVERFLOW ( OUT_MAC_OVERFLOW )
    );
    //--------------------------------------------------------------------------
    tester #(.N(N))
    u_tester (
          .RESET_N      ( RESET_N      )
        , .CLK          ( CLK          )
        , .IN_READY_A   ( IN_READY_A   )
        , .IN_DATA_A    ( IN_DATA_A    )
        , .IN_VALID_A   ( IN_VALID_A   )
        , .IN_LAST_A    ( IN_LAST_A    )
        , .IN_READY_B   ( IN_READY_B   )
        , .IN_DATA_B    ( IN_DATA_B    )
        , .IN_VALID_B   ( IN_VALID_B   )
        , .IN_LAST_B    ( IN_LAST_B    )
        , .OUT_MAC_DATA     ( OUT_MAC_DATA     )
        , .OUT_MAC_VALID    ( OUT_MAC_VALID    )
        , .OUT_MAC_READY    ( OUT_MAC_READY    )
        , .OUT_MAC_LAST     ( OUT_MAC_LAST     )
        , .OUT_MAC_OVERFLOW ( OUT_MAC_OVERFLOW )
    );
    //-------------------------------------------------------------------------
    initial begin
            $dumpfile("wave.vcd"); //$dumplimit(100000);
            $dumpvars(0);
            wait(ARESETn==1'b0);
            wait(ARESETn==1'b1);
            repeat (10) @ (posedge ACLK);
            wait (u_tester.done);
            repeat (10) @ (posedge ACLK);
            $finish(2);
    end
    //-------------------------------------------------------------------------
endmodule
//-----------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Re-written by Ando Ki (adki@future-ds.com)
//-----------------------------------------------------------------------------
