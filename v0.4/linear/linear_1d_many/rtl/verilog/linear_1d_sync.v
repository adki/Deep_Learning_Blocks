//------------------------------------------------------------------------------
// Copyright (c) by Ando Ki
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//------------------------------------------------------------------------------
// linear_1d_sync.v
//------------------------------------------------------------------------------
// Multi-flip-flop synchronizer
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// MACROS and PARAMETERS
module linear_1d_sync
     #(parameter ACTIVE_HIGH=1 // 1: high-input cause hihg-output
               , CYCLES=2)
(
       input  wire        reset_n
     , input  wire        clk
     , input  wire        sig_in
     , output wire        sig_out
);
   //---------------------------------------------------------------------------
   localparam INIT_VALUE=(ACTIVE_HIGH[0]==1'b1) ? 'b0 : 'b1;
   //---------------------------------------------------------------------------
   reg [CYCLES:0] sync={CYCLES+1{INIT_VALUE[0]}};
   //---------------------------------------------------------------------------
   integer idx;
   always @ (posedge clk or negedge reset_n) begin
   if (reset_n==1'b0) begin
       sync <= {CYCLES+1{INIT_VALUE[0]}};
   end else begin
       sync[0] <= sig_in;
       for (idx=1; idx<=CYCLES; idx=idx+1) begin
            sync[idx] <= sync[idx-1];
       end
   end // if
   end // always
   //---------------------------------------------------------------------------
   assign sig_out = sync[CYCLES];
   //---------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
